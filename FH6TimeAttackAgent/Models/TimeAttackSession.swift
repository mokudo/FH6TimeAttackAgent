import Foundation

struct TimeAttackSession: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var startedAt: Date
    var endedAt: Date?
    var laps: [TimeAttackLap] = []

    var sortedLaps: [TimeAttackLap] {
        laps.sorted { $0.duration < $1.duration }
    }

    var bestLap: TimeAttackLap? {
        sortedLaps.first
    }
}

struct TimeAttackLap: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var lapNumber: Int
    var duration: Float
    var completedAt: Date
    var samples: [LapSample]
    var analysis: LapAnalysis

    var minimumSpeedKPH: Float { samples.map(\.speedKPH).min() ?? 0 }
    var maximumSpeedKPH: Float { samples.map(\.speedKPH).max() ?? 0 }
    var averageSpeedKPH: Float {
        guard !samples.isEmpty else { return 0 }
        return samples.map(\.speedKPH).reduce(0, +) / Float(samples.count)
    }
}

struct LapSample: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var timestamp: TimeInterval
    var lapTime: Float
    var raceTime: Float
    var distanceTraveled: Float
    var x: Float
    var y: Float
    var z: Float
    var yaw: Float
    var speedKPH: Float
    var gear: UInt8
    var accel: Double
    var brake: Double
    var steer: Int
    var drivingLineOffset: Int
    var aiBrakeDifference: Int
    var tireCombinedSlipFrontLeft: Float
    var tireCombinedSlipFrontRight: Float
    var tireCombinedSlipRearLeft: Float
    var tireCombinedSlipRearRight: Float
    var lateralG: Float
    var longitudinalG: Float

    var combinedSlipPeak: Float {
        max(
            abs(tireCombinedSlipFrontLeft),
            abs(tireCombinedSlipFrontRight),
            abs(tireCombinedSlipRearLeft),
            abs(tireCombinedSlipRearRight)
        )
    }

    init(packet: FH6TelemetryPacket, timestamp: TimeInterval) {
        self.timestamp = timestamp
        lapTime = packet.currentLap
        raceTime = packet.currentRaceTime
        distanceTraveled = packet.distanceTraveled
        x = packet.positionX
        y = packet.positionY
        z = packet.positionZ
        yaw = packet.yaw
        speedKPH = packet.speedKPH
        gear = packet.gear
        accel = packet.accelPercent
        brake = packet.brakePercent
        steer = Int(packet.steer)
        drivingLineOffset = Int(packet.normalizedDrivingLine)
        aiBrakeDifference = Int(packet.normalizedAIBrakeDifference)
        tireCombinedSlipFrontLeft = packet.tireCombinedSlipFrontLeft
        tireCombinedSlipFrontRight = packet.tireCombinedSlipFrontRight
        tireCombinedSlipRearLeft = packet.tireCombinedSlipRearLeft
        tireCombinedSlipRearRight = packet.tireCombinedSlipRearRight
        lateralG = packet.lateralG
        longitudinalG = packet.longitudinalG
    }
}
