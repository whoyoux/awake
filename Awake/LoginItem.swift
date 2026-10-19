import Foundation
import Observation
import ServiceManagement

/// "Open at Login" via `SMAppService.mainApp`, which works inside the App
/// Sandbox. Turned on once, on the first launch from /Applications, so Awake
/// is in the menu bar after every restart; macOS tells the user it added a
/// login item, and the checkbox in the panel turns it off again.
@MainActor
@Observable
final class LoginItem {
    private(set) var isEnabled = SMAppService.mainApp.status == .enabled
    private(set) var lastError: String?

    private static let didSetUpKey = "LoginItemDidSetUp"

    init() {
        // Only for the installed copy: a build run from Xcode's DerivedData
        // must not become the login item.
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.didSetUpKey),
              Bundle.main.bundlePath.hasPrefix("/Applications/") else { return }
        defaults.set(true, forKey: Self.didSetUpKey)
        if SMAppService.mainApp.status != .enabled {
            setEnabled(true)
        }
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
    }

    /// The user can also change this in System Settings > General > Login Items.
    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
