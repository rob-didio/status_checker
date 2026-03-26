import SwiftUI

struct ComponentRowView: View {
    let component: Component
    let serviceId: UUID
    @ObservedObject var notificationManager: NotificationManager
    private var isDirectlySubscribed: Bool {
        notificationManager.isSubscribed(to: .component(serviceId: serviceId, componentId: component.id))
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(component.status.color)
                .frame(width: 10, height: 10)

            Text(component.name)
                .font(.body)

            Spacer()

            Button {
                Task {
                    await notificationManager.toggleSubscription(
                        to: .component(serviceId: serviceId, componentId: component.id)
                    )
                }
            } label: {
                Image(systemName: isDirectlySubscribed ? "bell.fill" : "bell")
                    .font(.caption2)
                    .foregroundStyle(isDirectlySubscribed ? .blue : .secondary)
            }
            .buttonStyle(.borderless)

            Text(component.status.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
