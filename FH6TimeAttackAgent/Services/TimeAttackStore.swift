import Foundation

@MainActor
final class TimeAttackStore: ObservableObject {
    @Published private(set) var sessions: [TimeAttackSession] = []
    @Published private(set) var activeSession: TimeAttackSession?
    @Published private(set) var currentSamples: [LapSample] = []
    @Published private(set) var latestSuggestion: DrivingSuggestion?

    private let sessionsKey = "fh6.timeAttack.sessions"
    private let maxSessionCount = 80
    private let sampleInterval: TimeInterval = 0.12
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var activeLapNumber: UInt16?
    private var lastSampleDate: Date?
    private var canFinalizeLap = false

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        load()
    }

    var isRecording: Bool { activeSession != nil }
    var currentLapPointCount: Int { currentSamples.count }
    var bestLap: TimeAttackLap? { sessions.flatMap(\.laps).min { $0.duration < $1.duration } }

    func startSession(at date: Date = Date()) {
        activeSession = TimeAttackSession(startedAt: date)
        activeLapNumber = nil
        currentSamples = []
        latestSuggestion = nil
        lastSampleDate = nil
        canFinalizeLap = false
    }

    func endSession(at date: Date = Date()) {
        guard var session = activeSession else { return }
        session.endedAt = date

        if !session.laps.isEmpty {
            sessions.insert(session, at: 0)
            sessions = Array(sessions.prefix(maxSessionCount))
            persist()
        }

        activeSession = nil
        activeLapNumber = nil
        currentSamples = []
        lastSampleDate = nil
        canFinalizeLap = false
    }

    func record(packet: FH6TelemetryPacket, at date: Date = Date()) {
        guard activeSession != nil, packet.raceActive else { return }

        if activeLapNumber == nil {
            activeLapNumber = packet.lapNumber
            canFinalizeLap = true
        } else if packet.lapNumber != activeLapNumber {
            finalizeCurrentLap(duration: packet.lastLap, completedAt: date)
            activeLapNumber = packet.lapNumber
            currentSamples = []
            lastSampleDate = nil
            canFinalizeLap = true
        }

        appendSample(from: packet, at: date)
    }

    func deleteSession(_ session: TimeAttackSession) {
        sessions.removeAll { $0.id == session.id }
        persist()
    }

    func exportSession(_ session: TimeAttackSession) -> String {
        guard let data = try? encoder.encode(session),
              let text = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return text
    }

    private func appendSample(from packet: FH6TelemetryPacket, at date: Date) {
        if let lastSampleDate, date.timeIntervalSince(lastSampleDate) < sampleInterval {
            return
        }

        let timestamp = date.timeIntervalSince(activeSession?.startedAt ?? date)
        let sample = LapSample(packet: packet, timestamp: timestamp)
        currentSamples.append(sample)
        lastSampleDate = date

        let rolling = LapAnalyzer.analyze(samples: Array(currentSamples.suffix(28)))
        latestSuggestion = rolling.suggestions.first
    }

    private func finalizeCurrentLap(duration: Float, completedAt date: Date) {
        guard canFinalizeLap,
              var session = activeSession,
              let activeLapNumber,
              duration > 0,
              currentSamples.count >= 4 else {
            return
        }

        let lap = TimeAttackLap(
            lapNumber: Int(activeLapNumber),
            duration: duration,
            completedAt: date,
            samples: currentSamples,
            analysis: LapAnalyzer.analyze(samples: currentSamples)
        )
        latestSuggestion = lap.analysis.suggestions.first
        session.laps.append(lap)
        activeSession = session
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey),
              let decoded = try? decoder.decode([TimeAttackSession].self, from: data) else {
            return
        }
        sessions = Array(decoded.prefix(maxSessionCount))
    }

    private func persist() {
        guard let data = try? encoder.encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: sessionsKey)
    }
}
