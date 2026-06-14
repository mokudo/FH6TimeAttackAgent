import SwiftUI

struct TelemetryDashboardView: View {
    @ObservedObject var receiver: TelemetryReceiver
    @ObservedObject var timeAttackStore: TimeAttackStore

    private var packet: FH6TelemetryPacket {
        receiver.packet ?? .preview
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text("FH6 Time Attack Agent")
                    .font(.title2.weight(.semibold))
                ConnectionPanel(receiver: receiver)
                LiveRecommendationCard(suggestion: timeAttackStore.latestSuggestion)
                PacketHelpCard(port: receiver.port, address: receiver.localIPAddress)
                Spacer()
            }
            .frame(width: 340)
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    LiveTelemetryBoard(packet: packet, isPreview: receiver.packet == nil)
                    TimeAttackPanel(store: timeAttackStore)
                }
                .padding(20)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .onChange(of: receiver.packet) { _, newPacket in
            guard let newPacket else { return }
            timeAttackStore.record(packet: newPacket)
        }
    }
}

private struct ConnectionPanel: View {
    @ObservedObject var receiver: TelemetryReceiver

    private var portBinding: Binding<Int> {
        Binding(
            get: { Int(receiver.port) },
            set: { receiver.port = UInt16(min(max($0, 1), Int(UInt16.max))) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(receiver.stateTitle, systemImage: receiver.isListening ? "dot.radiowaves.left.and.right" : "pause.circle")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(receiver.lastPacketDate == nil ? .orange : .green)
                    .frame(width: 10, height: 10)
            }

            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 10) {
                GridRow {
                    Text("IP")
                        .foregroundStyle(.secondary)
                    Text(receiver.localIPAddress)
                        .font(.system(.body, design: .monospaced))
                }
                GridRow {
                    Text("UDP")
                        .foregroundStyle(.secondary)
                    TextField("Port", value: portBinding, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .disabled(receiver.isListening)
                }
                GridRow {
                    Text("Packets")
                        .foregroundStyle(.secondary)
                    Text("\(receiver.packetCount)")
                        .font(.system(.body, design: .monospaced))
                }
            }

            HStack {
                Button {
                    receiver.isListening ? receiver.stop() : receiver.start()
                } label: {
                    Label(receiver.isListening ? "Stop" : "Listen", systemImage: receiver.isListening ? "stop.fill" : "play.fill")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    receiver.refreshLocalIPAddress()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }

            if let errorMessage = receiver.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .panelStyle()
    }
}

private struct PacketHelpCard: View {
    let port: UInt16
    let address: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("FH6 Data Out", systemImage: "network")
                .font(.headline)

            Text("Settings > HUD and Gameplay")
                .font(.subheadline.weight(.semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Data Out: On")
                Text("IP Address: \(address)")
                Text("IP Port: \(port)")
            }
            .font(.system(.body, design: .monospaced))

            Text("公式仕様では 324 byte の固定 UDP パケットを、走行中のみゲームのフレームレートで送信します。ポート 5200-5300 は避ける必要があるため、このアプリの初期値は 5301 です。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .panelStyle()
    }
}

private struct LiveRecommendationCard: View {
    let suggestion: DrivingSuggestion?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Live Coach", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                .font(.headline)

            if let suggestion {
                Text(suggestion.title)
                    .font(.subheadline.weight(.semibold))
                Text(suggestion.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text(suggestion.category.rawValue)
                    if let lapTime = suggestion.lapTime {
                        Text(lapTime.lapTimeText)
                    }
                    if let speed = suggestion.speedKPH {
                        Text("\(speed.wholeText) km/h")
                    }
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            } else {
                Text("セッション記録中に、走行ライン・ブレーキ・スリップの傾向から提案を表示します。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .panelStyle()
    }
}

private struct LiveTelemetryBoard: View {
    let packet: FH6TelemetryPacket
    let isPreview: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(isPreview ? "Preview Telemetry" : "Live Telemetry", systemImage: "gauge.with.dots.needle.67percent")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text(packet.raceActive ? "Race On" : "Race Off")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(packet.raceActive ? .green.opacity(0.16) : .secondary.opacity(0.16), in: Capsule())
            }

            HStack(alignment: .top, spacing: 14) {
                PrimaryGauge(title: "Speed", value: packet.speedKPH.wholeText, unit: "km/h", tint: .cyan)
                PrimaryGauge(title: "Gear", value: packet.gear == 0 ? "R" : "\(packet.gear)", unit: "", tint: .yellow)
                PrimaryGauge(title: "RPM", value: packet.currentEngineRpm.wholeText, unit: "rpm", tint: .orange)
                PrimaryGauge(title: "Brake", value: packet.brakePercent.percentText, unit: "", tint: .red)
                PrimaryGauge(title: "Accel", value: packet.accelPercent.percentText, unit: "", tint: .green)
            }

            RPMBar(ratio: packet.rpmRatio)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
                MetricTile(title: "Current Lap", value: packet.currentLap.lapTimeText, systemImage: "timer")
                MetricTile(title: "Last Lap", value: packet.lastLap.lapTimeText, systemImage: "flag.checkered")
                MetricTile(title: "Best Lap", value: packet.bestLap.lapTimeText, systemImage: "rosette")
                MetricTile(title: "Line Offset", value: "\(packet.normalizedDrivingLine)", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                MetricTile(title: "AI Brake Diff", value: "\(packet.normalizedAIBrakeDifference)", systemImage: "brakesignal")
                MetricTile(title: "Slip Peak", value: max(abs(packet.tireCombinedSlipFrontLeft), abs(packet.tireCombinedSlipFrontRight), abs(packet.tireCombinedSlipRearLeft), abs(packet.tireCombinedSlipRearRight)).oneDecimal, systemImage: "exclamationmark.triangle")
                MetricTile(title: "Lateral G", value: packet.lateralG.oneDecimal, systemImage: "arrow.left.and.right")
                MetricTile(title: "Long. G", value: packet.longitudinalG.oneDecimal, systemImage: "arrow.up.and.down")
            }
        }
        .panelStyle()
    }
}

private struct PrimaryGauge: View {
    let title: String
    let value: String
    let unit: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct RPMBar: View {
    let ratio: Float

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.secondary.opacity(0.16))
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [.green, .yellow, .red], startPoint: .leading, endPoint: .trailing))
                    .frame(width: proxy.size.width * CGFloat(ratio))
            }
        }
        .frame(height: 18)
    }
}

private struct MetricTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .frame(width: 24)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
    }
}

extension View {
    func panelStyle() -> some View {
        padding(16)
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.15), lineWidth: 1))
    }
}
