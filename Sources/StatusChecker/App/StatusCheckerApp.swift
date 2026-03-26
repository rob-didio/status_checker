import SwiftUI

@main
struct StatusCheckerApp: App {
    @StateObject private var monitor = StatusMonitor()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            StatusContentView(monitor: monitor)
        } label: {
            MenuBarIcon(overallStatus: monitor.overallStatus)
        }
        .menuBarExtraStyle(.window)
    }
}
