import SwiftUI

/// The panel that opens from the menu bar icon: an on/off switch, a large
/// counter with progress for timed sessions, and one row of durations where
/// a single click turns Awake on for that long.
struct MenuContentView: View {
    let controller: AwakeController
    let loginItem: LoginItem

    /// The espresso orange of the app icon and the "on" menu bar icon.
    static let accent = Color(nsColor: .systemOrange)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                header
                status
                durations

                if let error = controller.lastError {
                    errorText(error)
                }
            }
            .padding(14)

            Divider()

            HStack {
                Toggle("Open at Login", isOn: Binding(
                    get: { loginItem.isEnabled },
                    set: { loginItem.setEnabled($0) }
                ))
                .toggleStyle(.checkbox)
                .onAppear { loginItem.refresh() }

                Spacer()

                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .keyboardShortcut("q")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if let error = loginItem.lastError {
                errorText(error)
                    .padding([.horizontal, .bottom], 14)
            }
        }
        .frame(width: 290)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: controller.isActive ? "cup.and.heat.waves.fill" : "cup.and.saucer")
                .font(.system(size: 16))
                .foregroundStyle(controller.isActive ? Self.accent : .secondary)
                .frame(width: 22)
            Text("Awake")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Toggle("Keep your Mac awake", isOn: Binding(
                get: { controller.isActive },
                set: { $0 ? controller.turnOn() : controller.turnOff() }
            ))
            .toggleStyle(.switch)
            .tint(Self.accent)
            .labelsHidden()
        }
    }

    @ViewBuilder
    private var status: some View {
        if let start = controller.startDate {
            TimelineView(.periodic(from: start, by: 1)) { context in
                let now = context.date
                VStack(alignment: .leading, spacing: 5) {
                    if let end = controller.endDate {
                        Text(Self.clock(end.timeIntervalSince(now)))
                            .font(.system(size: 28, weight: .semibold))
                            .monospacedDigit()
                        Text("left · on for \(Self.clock(now.timeIntervalSince(start)))")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        ProgressView(value: controller.progress(at: now))
                            .progressViewStyle(.linear)
                            .tint(Self.accent)
                    } else {
                        Text(Self.clock(now.timeIntervalSince(start)))
                            .font(.system(size: 28, weight: .semibold))
                            .monospacedDigit()
                        Text("on · until turned off")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text("Off")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Your Mac sleeps as usual.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var durations: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(controller.isActive ? "Keep awake for" : "Turn on for")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            HStack(spacing: 2) {
                ForEach(AwakeController.presets, id: \.self) { preset in
                    segment(Self.presetLabel(preset), accessibility: Self.presetName(preset),
                            isSelected: controller.isActive && controller.duration == preset) {
                        controller.turnOn(for: preset)
                    }
                }
                segment("∞", accessibility: "Until turned off",
                        isSelected: controller.isActive && controller.duration == nil) {
                    controller.turnOn()
                }
            }
            .padding(2)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color.primary.opacity(0.06)))
        }
    }

    private func segment(_ title: String, accessibility: String, isSelected: Bool,
                         action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(SegmentButtonStyle(isSelected: isSelected))
            .accessibilityLabel(accessibility)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func errorText(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.red)
    }

    /// Formats a duration as H:MM:SS (or M:SS under an hour).
    static func clock(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.down)))
        let h = total / 3600, m = total / 60 % 60, s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }

    static func presetLabel(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        return minutes < 60 ? "\(minutes)m" : "\(minutes / 60)h"
    }

    static func presetName(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes < 60 { return "\(minutes) minutes" }
        let hours = minutes / 60
        return hours == 1 ? "1 hour" : "\(hours) hours"
    }
}

/// One cell of the duration row: orange when it is the running preset.
private struct SegmentButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isSelected
                          ? MenuContentView.accent
                          : Color.primary.opacity(configuration.isPressed ? 0.12 : 0))
            )
            .contentShape(Rectangle())
    }
}
