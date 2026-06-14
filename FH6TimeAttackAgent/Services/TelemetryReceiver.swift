import Darwin
import Foundation
import Network

private let defaultPort: UInt16 = 5301
private let portKey = "fh6.telemetry.port"

@MainActor
final class TelemetryReceiver: ObservableObject {
    @Published private(set) var packet: FH6TelemetryPacket?
    @Published private(set) var isListening = false
    @Published private(set) var packetCount = 0
    @Published private(set) var lastPacketDate: Date?
    @Published private(set) var localIPAddress = "127.0.0.1"
    @Published var errorMessage: String?
    @Published var port: UInt16 = defaultPort {
        didSet { UserDefaults.standard.set(Int(port), forKey: portKey) }
    }

    private var listener: NWListener?

    init() {
        let savedPort = UserDefaults.standard.integer(forKey: portKey)
        if savedPort > 0, savedPort <= Int(UInt16.max) {
            port = UInt16(savedPort)
        }
        refreshLocalIPAddress()
    }

    var stateTitle: String {
        if isListening, lastPacketDate != nil { return "Receiving" }
        if isListening { return "Listening" }
        return "Stopped"
    }

    func start() {
        stop()
        refreshLocalIPAddress()

        guard let endpointPort = NWEndpoint.Port(rawValue: port) else {
            errorMessage = "Invalid UDP port."
            return
        }

        do {
            let parameters = NWParameters.udp
            parameters.allowLocalEndpointReuse = true
            let listener = try NWListener(using: parameters, on: endpointPort)
            self.listener = listener

            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in self?.handle(state: state) }
            }

            listener.newConnectionHandler = { [weak self] connection in
                connection.start(queue: .global(qos: .userInitiated))
                self?.receive(on: connection)
            }

            listener.start(queue: .global(qos: .userInitiated))
        } catch {
            errorMessage = "UDP \(port) を開けませんでした: \(error.localizedDescription)"
            isListening = false
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        isListening = false
    }

    func refreshLocalIPAddress() {
        localIPAddress = Self.currentIPv4Address() ?? "127.0.0.1"
    }

    private func handle(state: NWListener.State) {
        switch state {
        case .ready:
            isListening = true
            errorMessage = nil
        case .failed(let error):
            errorMessage = "UDP listener failed: \(error.localizedDescription)"
            isListening = false
            listener?.cancel()
            listener = nil
        case .cancelled:
            isListening = false
        default:
            break
        }
    }

    private nonisolated func receive(on connection: NWConnection) {
        connection.receiveMessage { [weak self] data, _, isComplete, error in
            if let data, isComplete {
                Task { @MainActor in self?.handle(data: data) }
            }

            if let error {
                Task { @MainActor in self?.errorMessage = "UDP receive failed: \(error.localizedDescription)" }
                return
            }

            self?.receive(on: connection)
        }
    }

    private func handle(data: Data) {
        do {
            let parsed = try FH6TelemetryPacket(data: data)
            packet = parsed
            packetCount += 1
            lastPacketDate = Date()
            errorMessage = nil
        } catch {
            errorMessage = "\(data.count) byte packet ignored. FH6 Data Out is \(FH6TelemetryPacket.byteCount) bytes."
        }
    }

    private nonisolated static func currentIPv4Address() -> String? {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0, let firstInterface = interfaces else { return nil }
        defer { freeifaddrs(interfaces) }

        var fallbackAddress: String?
        var pointer: UnsafeMutablePointer<ifaddrs>? = firstInterface

        while let interface = pointer {
            defer { pointer = interface.pointee.ifa_next }
            let flags = Int32(interface.pointee.ifa_flags)
            guard (flags & IFF_UP) == IFF_UP, (flags & IFF_LOOPBACK) != IFF_LOOPBACK else { continue }
            guard let addressPointer = interface.pointee.ifa_addr else { continue }
            guard addressPointer.pointee.sa_family == UInt8(AF_INET) else { continue }

            let name = String(cString: interface.pointee.ifa_name)
            let address = addressPointer.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { socketAddress in
                String(cString: inet_ntoa(socketAddress.pointee.sin_addr))
            }

            if name == "en0" { return address }
            fallbackAddress = fallbackAddress ?? address
        }

        return fallbackAddress
    }
}
