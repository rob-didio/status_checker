import SwiftUI

struct ComponentRowView: View {
    let component: Component

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(component.status.color)
                .frame(width: 10, height: 10)

            Text(component.name)
                .font(.body)

            Spacer()

            Text(component.status.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
