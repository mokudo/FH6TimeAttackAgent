import SwiftUI

@main
struct FH6TimeAttackAgentApp: App {
    @StateObject private var receiver = TelemetryReceiver()
    @StateObject private var timeAttackStore = TimeAttackStore()

    var body: some Scene {
        WindowGroup {
            TelemetryDashboardView(receiver: receiver, timeAttackStore: timeAttackStore)
                .frame(minWidth: 1100, minHeight: 720)
        }
    }
}
