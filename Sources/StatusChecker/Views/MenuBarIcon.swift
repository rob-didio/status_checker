import SwiftUI
import AppKit

public struct MenuBarIcon: View {
    public let overallStatus: OverallStatusLevel

    public init(overallStatus: OverallStatusLevel) {
        self.overallStatus = overallStatus
    }

    public var body: some View {
        Image(nsImage: makeCircle())
    }

    private func makeCircle() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let circle = NSBezierPath(ovalIn: rect.insetBy(dx: 3, dy: 3))
            NSColor(overallStatus.color).setFill()
            circle.fill()
            return true
        }
        image.isTemplate = false
        return image
    }
}
