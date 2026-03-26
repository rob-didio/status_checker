import SwiftUI
import StatusCheckerLib

@main
struct StatusCheckerApp: App {
    @StateObject private var monitor = StatusMonitor()
    @StateObject private var notificationManager = NotificationManager()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            StatusContentView(monitor: monitor, notificationManager: notificationManager)
                .onAppear { monitor.notificationManager = notificationManager }
        } label: {
            MenuBarIcon(overallStatus: monitor.overallStatus)
        }
        .menuBarExtraStyle(.window)
    }
}
