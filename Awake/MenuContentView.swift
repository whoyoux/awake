import SwiftUI

struct MenuContentView: View {
    let controller: AwakeController

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            status

            Divider()

            if controller.isActive {
                Button("Turn Off") { controller.turnOff() }
                    .keyboardShortcut(.defaultAction)
            } else {
                Button("Turn On") { controller.turnOn() }
                    .keyboardShortcut(.defaultAction)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(controller.isActive ? "Change to:" : "Turn on for:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    ForEach(AwakeController.presets, id: \.self) { preset in
                        Button(Self.presetLabel(preset)) { controller.turnOn(for: preset) }
                    }
                }
                if controller.isActive && controller.endDate != nil {
                    Button("Until turned off") { controller.turnOn() }
                }
            }

            if let error = controller.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Divider()

            Button("Quit Awake") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
        .controlSize(.regular)
        .padding(12)
        .frame(width: 300, alignment: .leading)
    }

    @ViewBuilder
    private var status: some View {
        if let start = controller.startDate {
            TimelineView(.periodic(from: start, by: 1)) { context in
                VStack(alignment: .leading, spacing: 2) {
                    Label("Keeping your Mac awake", systemImage: "cup.and.saucer.fill")
                        .font(.headline)
                    Text("On for \(Self.clock(context.date.timeIntervalSince(start)))")
                        .monospacedDigit()
                    if let end = controller.endDate {
                        Text("\(Self.clock(end.timeIntervalSince(context.date))) left")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Until turned off")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Label("Off", systemImage: "cup.and.saucer")
                    .font(.headline)
                Text("Your Mac sleeps as usual.")
                    .foregroundStyle(.secondary)
            }
        }
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
        return minutes < 60 ? "\(minutes) min" : "\(minutes / 60) h"
    }
}
