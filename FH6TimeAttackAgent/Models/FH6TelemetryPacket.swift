import Foundation

struct FH6TelemetryPacket: Equatable {
    static let byteCount = 324

    let isRaceOn: Int32
    let timestampMS: UInt32
    let engineMaxRpm: Float
    let engineIdleRpm: Float
    let currentEngineRpm: Float
    let accelerationX: Float
    let accelerationY: Float
    let accelerationZ: Float
    let velocityX: Float
    let velocityY: Float
    let velocityZ: Float
    let angularVelocityX: Float
    let angularVelocityY: Float
    let angularVelocityZ: Float
    let yaw: Float
    let pitch: Float
    let roll: Float
    let normalizedSuspensionTravelFrontLeft: Float
    let normalizedSuspensionTravelFrontRight: Float
    let normalizedSuspensionTravelRearLeft: Float
    let normalizedSuspensionTravelRearRight: Float
    let tireSlipRatioFrontLeft: Float
    let tireSlipRatioFrontRight: Float
    let tireSlipRatioRearLeft: Float
    let tireSlipRatioRearRight: Float
    let wheelRotationSpeedFrontLeft: Float
    let wheelRotationSpeedFrontRight: Float
    let wheelRotationSpeedRearLeft: Float
    let wheelRotationSpeedRearRight: Float
    let wheelOnRumbleStripFrontLeft: Int32
    let wheelOnRumbleStripFrontRight: Int32
    let wheelOnRumbleStripRearLeft: Int32
    let wheelOnRumbleStripRearRight: Int32
    let wheelInPuddleFrontLeft: Int32
    let wheelInPuddleFrontRight: Int32
    let wheelInPuddleRearLeft: Int32
    let wheelInPuddleRearRight: Int32
    let surfaceRumbleFrontLeft: Float
    let surfaceRumbleFrontRight: Float
    let surfaceRumbleRearLeft: Float
    let surfaceRumbleRearRight: Float
    let tireSlipAngleFrontLeft: Float
    let tireSlipAngleFrontRight: Float
    let tireSlipAngleRearLeft: Float
    let tireSlipAngleRearRight: Float
    let tireCombinedSlipFrontLeft: Float
    let tireCombinedSlipFrontRight: Float
    let tireCombinedSlipRearLeft: Float
    let tireCombinedSlipRearRight: Float
    let suspensionTravelMetersFrontLeft: Float
    let suspensionTravelMetersFrontRight: Float
    let suspensionTravelMetersRearLeft: Float
    let suspensionTravelMetersRearRight: Float
    let carOrdinal: Int32
    let carClass: Int32
    let carPerformanceIndex: Int32
    let drivetrainType: Int32
    let numCylinders: Int32
    let carGroup: UInt32
    let smashableVelDiff: Float
    let smashableMass: Float
    let positionX: Float
    let positionY: Float
    let positionZ: Float
    let speed: Float
    let power: Float
    let torque: Float
    let tireTempFrontLeft: Float
    let tireTempFrontRight: Float
    let tireTempRearLeft: Float
    let tireTempRearRight: Float
    let boost: Float
    let fuel: Float
    let distanceTraveled: Float
    let bestLap: Float
    let lastLap: Float
    let currentLap: Float
    let currentRaceTime: Float
    let lapNumber: UInt16
    let racePosition: UInt8
    let accel: UInt8
    let brake: UInt8
    let clutch: UInt8
    let handBrake: UInt8
    let gear: UInt8
    let steer: Int8
    let normalizedDrivingLine: Int8
    let normalizedAIBrakeDifference: Int8
    let reservedPadding: UInt8

    var raceActive: Bool { isRaceOn == 1 }
    var speedKPH: Float { speed * 3.6 }
    var powerHP: Float { power / 745.6999 }
    var brakePercent: Double { Double(brake) / 255 }
    var accelPercent: Double { Double(accel) / 255 }
    var lateralG: Float { accelerationX / 9.80665 }
    var longitudinalG: Float { accelerationZ / 9.80665 }
    var rpmRatio: Float {
        guard engineMaxRpm > engineIdleRpm else { return 0 }
        return min(max((currentEngineRpm - engineIdleRpm) / (engineMaxRpm - engineIdleRpm), 0), 1)
    }

    init(data: Data) throws {
        guard data.count == Self.byteCount else {
            throw FH6PacketError.unexpectedLength(expected: Self.byteCount, actual: data.count)
        }

        var reader = FH6PacketReader(data: data)
        isRaceOn = try reader.int32()
        timestampMS = try reader.uint32()
        engineMaxRpm = try reader.float32()
        engineIdleRpm = try reader.float32()
        currentEngineRpm = try reader.float32()
        accelerationX = try reader.float32()
        accelerationY = try reader.float32()
        accelerationZ = try reader.float32()
        velocityX = try reader.float32()
        velocityY = try reader.float32()
        velocityZ = try reader.float32()
        angularVelocityX = try reader.float32()
        angularVelocityY = try reader.float32()
        angularVelocityZ = try reader.float32()
        yaw = try reader.float32()
        pitch = try reader.float32()
        roll = try reader.float32()
        normalizedSuspensionTravelFrontLeft = try reader.float32()
        normalizedSuspensionTravelFrontRight = try reader.float32()
        normalizedSuspensionTravelRearLeft = try reader.float32()
        normalizedSuspensionTravelRearRight = try reader.float32()
        tireSlipRatioFrontLeft = try reader.float32()
        tireSlipRatioFrontRight = try reader.float32()
        tireSlipRatioRearLeft = try reader.float32()
        tireSlipRatioRearRight = try reader.float32()
        wheelRotationSpeedFrontLeft = try reader.float32()
        wheelRotationSpeedFrontRight = try reader.float32()
        wheelRotationSpeedRearLeft = try reader.float32()
        wheelRotationSpeedRearRight = try reader.float32()
        wheelOnRumbleStripFrontLeft = try reader.int32()
        wheelOnRumbleStripFrontRight = try reader.int32()
        wheelOnRumbleStripRearLeft = try reader.int32()
        wheelOnRumbleStripRearRight = try reader.int32()
        wheelInPuddleFrontLeft = try reader.int32()
        wheelInPuddleFrontRight = try reader.int32()
        wheelInPuddleRearLeft = try reader.int32()
        wheelInPuddleRearRight = try reader.int32()
        surfaceRumbleFrontLeft = try reader.float32()
        surfaceRumbleFrontRight = try reader.float32()
        surfaceRumbleRearLeft = try reader.float32()
        surfaceRumbleRearRight = try reader.float32()
        tireSlipAngleFrontLeft = try reader.float32()
        tireSlipAngleFrontRight = try reader.float32()
        tireSlipAngleRearLeft = try reader.float32()
        tireSlipAngleRearRight = try reader.float32()
        tireCombinedSlipFrontLeft = try reader.float32()
        tireCombinedSlipFrontRight = try reader.float32()
        tireCombinedSlipRearLeft = try reader.float32()
        tireCombinedSlipRearRight = try reader.float32()
        suspensionTravelMetersFrontLeft = try reader.float32()
        suspensionTravelMetersFrontRight = try reader.float32()
        suspensionTravelMetersRearLeft = try reader.float32()
        suspensionTravelMetersRearRight = try reader.float32()
        carOrdinal = try reader.int32()
        carClass = try reader.int32()
        carPerformanceIndex = try reader.int32()
        drivetrainType = try reader.int32()
        numCylinders = try reader.int32()
        carGroup = try reader.uint32()
        smashableVelDiff = try reader.float32()
        smashableMass = try reader.float32()
        positionX = try reader.float32()
        positionY = try reader.float32()
        positionZ = try reader.float32()
        speed = try reader.float32()
        power = try reader.float32()
        torque = try reader.float32()
        tireTempFrontLeft = try reader.float32()
        tireTempFrontRight = try reader.float32()
        tireTempRearLeft = try reader.float32()
        tireTempRearRight = try reader.float32()
        boost = try reader.float32()
        fuel = try reader.float32()
        distanceTraveled = try reader.float32()
        bestLap = try reader.float32()
        lastLap = try reader.float32()
        currentLap = try reader.float32()
        currentRaceTime = try reader.float32()
        lapNumber = try reader.uint16()
        racePosition = try reader.uint8()
        accel = try reader.uint8()
        brake = try reader.uint8()
        clutch = try reader.uint8()
        handBrake = try reader.uint8()
        gear = try reader.uint8()
        steer = try reader.int8()
        normalizedDrivingLine = try reader.int8()
        normalizedAIBrakeDifference = try reader.int8()
        reservedPadding = try reader.uint8()
    }
}

enum FH6PacketError: Error, Equatable {
    case unexpectedLength(expected: Int, actual: Int)
}

private struct FH6PacketReader {
    let data: Data
    private(set) var offset = 0

    mutating func int32() throws -> Int32 { Int32(bitPattern: try uint32()) }
    mutating func uint32() throws -> UInt32 { UInt32(littleEndian: try readInteger(UInt32.self)) }
    mutating func uint16() throws -> UInt16 { UInt16(littleEndian: try readInteger(UInt16.self)) }
    mutating func uint8() throws -> UInt8 { try readInteger(UInt8.self) }
    mutating func int8() throws -> Int8 { Int8(bitPattern: try uint8()) }
    mutating func float32() throws -> Float { Float(bitPattern: try uint32()) }

    private mutating func readInteger<T: FixedWidthInteger>(_ type: T.Type) throws -> T {
        let byteCount = MemoryLayout<T>.size
        guard offset + byteCount <= data.count else {
            throw FH6PacketError.unexpectedLength(expected: FH6TelemetryPacket.byteCount, actual: data.count)
        }

        let value = data.withUnsafeBytes { rawBuffer in
            rawBuffer.loadUnaligned(fromByteOffset: offset, as: T.self)
        }
        offset += byteCount
        return value
    }
}

extension FH6TelemetryPacket {
    static let preview: FH6TelemetryPacket = {
        var bytes = [UInt8](repeating: 0, count: byteCount)

        func writeInt32(_ value: Int32, at offset: Int) {
            var value = UInt32(bitPattern: value).littleEndian
            withUnsafeBytes(of: &value) { bytes.replaceSubrange(offset..<(offset + 4), with: $0) }
        }

        func writeUInt16(_ value: UInt16, at offset: Int) {
            var value = value.littleEndian
            withUnsafeBytes(of: &value) { bytes.replaceSubrange(offset..<(offset + 2), with: $0) }
        }

        func writeUInt8(_ value: UInt8, at offset: Int) {
            bytes[offset] = value
        }

        func writeInt8(_ value: Int8, at offset: Int) {
            bytes[offset] = UInt8(bitPattern: value)
        }

        func writeFloat(_ value: Float, at offset: Int) {
            var value = value.bitPattern.littleEndian
            withUnsafeBytes(of: &value) { bytes.replaceSubrange(offset..<(offset + 4), with: $0) }
        }

        writeInt32(1, at: 0)
        writeFloat(7200, at: 8)
        writeFloat(900, at: 12)
        writeFloat(5850, at: 16)
        writeFloat(-4.2, at: 20)
        writeFloat(-7.4, at: 28)
        writeFloat(6.4, at: 188)
        writeFloat(11.3, at: 196)
        writeFloat(-285.4, at: 204)
        writeFloat(57.8, at: 256)
        writeFloat(238000, at: 260)
        writeFloat(520, at: 264)
        writeFloat(0.58, at: 284)
        writeFloat(41.328, at: 296)
        writeFloat(64.913, at: 300)
        writeFloat(18.2, at: 304)
        writeUInt16(3, at: 312)
        writeUInt8(2, at: 314)
        writeUInt8(184, at: 315)
        writeUInt8(96, at: 316)
        writeUInt8(5, at: 319)
        writeInt8(-18, at: 320)
        writeInt8(42, at: 321)
        writeInt8(-31, at: 322)

        return try! FH6TelemetryPacket(data: Data(bytes))
    }()
}
