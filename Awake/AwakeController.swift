import AppKit
import Observation

/// Owns the power assertion and the optional session timer.
@MainActor
@Observable
final class AwakeController {
    /// Preset durations offered in the menu, in seconds.
    static let presets: [TimeInterval] = [30 * 60, 60 * 60, 2 * 3600, 4 * 3600, 8 * 3600]

    private(set) var startDate: Date?
    /// End of a timed session; `nil` while on "until turned off".
    private(set) var endDate: Date?
    private(set) var lastError: String?

    var isActive: Bool { startDate != nil }

    @ObservationIgnored private var assertion: PowerAssertion?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var wakeObserver: NSObjectProtocol?

    init() {
        // Timers do not count time while the Mac is asleep (e.g. lid closed),
        // so re-check the end date whenever the system wakes up.
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkExpiry() }
        }

        #if DEBUG
        // Debug builds only: `-AwakeStartSeconds N` turns Awake on at launch
        // (N > 0 for a timed session, 0 for until turned off), so the
        // assertion and timer can be checked from the shell with
        // `pmset -g assertions` without clicking the menu bar.
        if let seconds = UserDefaults.standard.string(forKey: "AwakeStartSeconds").flatMap(Double.init) {
            turnOn(for: seconds > 0 ? seconds : nil)
        }
        #endif
    }

    /// Turns Awake on. `duration == nil` means until turned off.
    func turnOn(for duration: TimeInterval? = nil) {
        if assertion == nil {
            guard let newAssertion = PowerAssertion(reason: "Awake is keeping the display awake") else {
                lastError = "Could not create the power assertion."
                return
            }
            assertion = newAssertion
            startDate = Date()
        }
        lastError = nil
        timer?.invalidate()
        timer = nil

        if let duration {
            let end = Date().addingTimeInterval(duration)
            endDate = end
            let timer = Timer(fire: end, interval: 0, repeats: false) { [weak self] _ in
                MainActor.assumeIsolated { self?.checkExpiry() }
            }
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        } else {
            endDate = nil
        }
    }

    func turnOff() {
        timer?.invalidate()
        timer = nil
        assertion?.release()
        assertion = nil
        startDate = nil
        endDate = nil
    }

    func toggle() {
        isActive ? turnOff() : turnOn()
    }

    private func checkExpiry() {
        guard let endDate else { return }
        if Date() >= endDate {
            turnOff()
        }
    }
}
