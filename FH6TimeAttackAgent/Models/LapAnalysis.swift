import Foundation

struct LapAnalysis: Codable, Equatable {
    var suggestions: [DrivingSuggestion] = []
    var brakingZones: [BrakingZone] = []
    var lineEvents: [LineEvent] = []
    var slipEvents: [SlipEvent] = []
}

struct DrivingSuggestion: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var category: SuggestionCategory
    var severity: SuggestionSeverity
    var title: String
    var detail: String
    var lapTime: Float?
    var speedKPH: Float?
}

enum SuggestionCategory: String, Codable, CaseIterable {
    case braking = "Braking"
    case line = "Line"
    case throttle = "Throttle"
    case stability = "Stability"
}

enum SuggestionSeverity: String, Codable, Comparable {
    case info = "Info"
    case medium = "Medium"
    case high = "High"

    static func < (lhs: SuggestionSeverity, rhs: SuggestionSeverity) -> Bool {
        let order: [SuggestionSeverity: Int] = [.info: 0, .medium: 1, .high: 2]
        return (order[lhs] ?? 0) < (order[rhs] ?? 0)
    }
}

struct BrakingZone: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var startLapTime: Float
    var endLapTime: Float
    var entrySpeedKPH: Float
    var minimumSpeedKPH: Float
    var peakBrake: Double
    var averageLineOffset: Double
    var aiBrakeDeltaAverage: Double
}

struct LineEvent: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var lapTime: Float
    var lineOffset: Int
    var speedKPH: Float
}

struct SlipEvent: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var lapTime: Float
    var peakSlip: Float
    var speedKPH: Float
}

enum LapAnalyzer {
    static func analyze(samples: [LapSample]) -> LapAnalysis {
        guard samples.count >= 4 else { return LapAnalysis() }

        let brakingZones = detectBrakingZones(samples: samples)
        let lineEvents = samples
            .filter { abs($0.drivingLineOffset) >= 55 && $0.speedKPH > 35 }
            .strideSampled(maxCount: 8)
            .map { LineEvent(lapTime: $0.lapTime, lineOffset: $0.drivingLineOffset, speedKPH: $0.speedKPH) }
        let slipEvents = samples
            .filter { $0.combinedSlipPeak >= 0.85 && $0.speedKPH > 45 }
            .strideSampled(maxCount: 8)
            .map { SlipEvent(lapTime: $0.lapTime, peakSlip: $0.combinedSlipPeak, speedKPH: $0.speedKPH) }

        var suggestions: [DrivingSuggestion] = []
        suggestions.append(contentsOf: brakingSuggestions(from: brakingZones))
        suggestions.append(contentsOf: lineSuggestions(from: lineEvents))
        suggestions.append(contentsOf: slipSuggestions(from: slipEvents))
        suggestions.append(contentsOf: throttleSuggestions(from: samples))

        if suggestions.isEmpty {
            suggestions.append(
                DrivingSuggestion(
                    category: .line,
                    severity: .info,
                    title: "ラインと入力は安定しています",
                    detail: "大きなライン逸脱や過度なスリップは検出されませんでした。次はブレーキ解除からアクセル開始までの間を短くする意識で比較してください。",
                    lapTime: nil,
                    speedKPH: nil
                )
            )
        }

        return LapAnalysis(
            suggestions: suggestions.sorted { $0.severity > $1.severity },
            brakingZones: brakingZones,
            lineEvents: lineEvents,
            slipEvents: slipEvents
        )
    }

    private static func detectBrakingZones(samples: [LapSample]) -> [BrakingZone] {
        var zones: [BrakingZone] = []
        var startIndex: Int?

        for index in samples.indices {
            let braking = samples[index].brake >= 0.18
            if braking, startIndex == nil {
                startIndex = index
            } else if !braking, let start = startIndex {
                appendZone(samples[start..<index], to: &zones)
                startIndex = nil
            }
        }

        if let startIndex {
            appendZone(samples[startIndex..<samples.count], to: &zones)
        }

        return zones
    }

    private static func appendZone(_ zone: ArraySlice<LapSample>, to zones: inout [BrakingZone]) {
        guard zone.count >= 2, let first = zone.first, let last = zone.last else { return }
        let entrySpeed = first.speedKPH
        let minimumSpeed = zone.map(\.speedKPH).min() ?? entrySpeed
        guard entrySpeed - minimumSpeed >= 8 || zone.map(\.brake).max() ?? 0 >= 0.45 else { return }

        zones.append(
            BrakingZone(
                startLapTime: first.lapTime,
                endLapTime: last.lapTime,
                entrySpeedKPH: entrySpeed,
                minimumSpeedKPH: minimumSpeed,
                peakBrake: zone.map(\.brake).max() ?? 0,
                averageLineOffset: zone.map { Double(abs($0.drivingLineOffset)) }.average,
                aiBrakeDeltaAverage: zone.map { Double($0.aiBrakeDifference) }.average
            )
        )
    }

    private static func brakingSuggestions(from zones: [BrakingZone]) -> [DrivingSuggestion] {
        zones.compactMap { zone in
            if zone.aiBrakeDeltaAverage < -22 {
                return DrivingSuggestion(
                    category: .braking,
                    severity: .high,
                    title: "ブレーキが早めです",
                    detail: "AI ブレーキ差が平均 \(zone.aiBrakeDeltaAverage.roundedText) と早めに出ています。次周は同じ進入速度でブレーキ開始をわずかに奥へ移し、ピークブレーキ後の解除を滑らかにしてください。",
                    lapTime: zone.startLapTime,
                    speedKPH: zone.entrySpeedKPH
                )
            }

            if zone.aiBrakeDeltaAverage > 22 || zone.peakBrake > 0.92 && zone.entrySpeedKPH - zone.minimumSpeedKPH > 45 {
                return DrivingSuggestion(
                    category: .braking,
                    severity: .medium,
                    title: "突っ込みすぎの可能性",
                    detail: "強いブレーキで速度を大きく落としています。進入で少し手前から減速を始め、ターンイン時の残しブレーキ量を一定にすると出口速度が安定します。",
                    lapTime: zone.startLapTime,
                    speedKPH: zone.entrySpeedKPH
                )
            }

            if zone.averageLineOffset > 48 {
                return DrivingSuggestion(
                    category: .line,
                    severity: .medium,
                    title: "ブレーキング中のラインずれ",
                    detail: "減速区間で推奨ラインから平均 \(zone.averageLineOffset.roundedText) ずれています。ブレーキ前に車を外側へ置き、直線的に減速できる角度を作ると姿勢が落ち着きます。",
                    lapTime: zone.startLapTime,
                    speedKPH: zone.entrySpeedKPH
                )
            }

            return nil
        }
    }

    private static func lineSuggestions(from events: [LineEvent]) -> [DrivingSuggestion] {
        events.prefix(4).map { event in
            DrivingSuggestion(
                category: .line,
                severity: abs(event.lineOffset) > 85 ? .high : .medium,
                title: event.lineOffset > 0 ? "ラインが外へ膨らんでいます" : "ラインが内側に寄りすぎています",
                detail: "NormalizedDrivingLine が \(event.lineOffset) です。入口でステアを急に入れず、クリップまでの弧を浅くして出口でアクセルを早く開けられる形を狙ってください。",
                lapTime: event.lapTime,
                speedKPH: event.speedKPH
            )
        }
    }

    private static func slipSuggestions(from events: [SlipEvent]) -> [DrivingSuggestion] {
        events.prefix(3).map { event in
            DrivingSuggestion(
                category: .stability,
                severity: event.peakSlip > 1.2 ? .high : .medium,
                title: "タイヤのスリップが大きいです",
                detail: "Combined slip が \(event.peakSlip.oneDecimal) まで上がっています。旋回中はブレーキまたはアクセルを少し戻し、縦横のグリップを分けて使うとライン修正が減ります。",
                lapTime: event.lapTime,
                speedKPH: event.speedKPH
            )
        }
    }

    private static func throttleSuggestions(from samples: [LapSample]) -> [DrivingSuggestion] {
        var suggestions: [DrivingSuggestion] = []

        for index in samples.indices.dropFirst() {
            let previous = samples[index - 1]
            let current = samples[index]
            let brakeReleased = previous.brake > 0.25 && current.brake < 0.08
            if brakeReleased {
                let lookahead = samples[index..<min(samples.count, index + 8)]
                let delayedThrottle = lookahead.allSatisfy { $0.accel < 0.35 }
                if delayedThrottle {
                    suggestions.append(
                        DrivingSuggestion(
                            category: .throttle,
                            severity: .medium,
                            title: "アクセル復帰が遅れています",
                            detail: "ブレーキ解除後しばらくアクセルが低いままです。車が出口へ向いた瞬間に 30-50% から踏み始め、ステアを戻しながら全開へつなげてください。",
                            lapTime: current.lapTime,
                            speedKPH: current.speedKPH
                        )
                    )
                }
            }
        }

        return Array(suggestions.prefix(3))
    }
}

private extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}

private extension Array {
    func strideSampled(maxCount: Int) -> [Element] {
        guard count > maxCount, maxCount > 0 else { return self }
        let step = Swift.max(1, count / maxCount)
        return enumerated().compactMap { index, element in index % step == 0 ? element : nil }.prefix(maxCount).map(\.self)
    }
}

extension Float {
    var lapTimeText: String {
        guard self > 0 else { return "--:--.---" }
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        let milliseconds = Int((self - floor(self)) * 1000)
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }

    var wholeText: String { String(format: "%.0f", self) }
    var oneDecimal: String { String(format: "%.1f", self) }
}

extension Double {
    var percentText: String { String(format: "%.0f%%", self * 100) }
    var roundedText: String { String(format: "%.0f", self) }
}
