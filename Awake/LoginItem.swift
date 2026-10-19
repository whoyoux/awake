import Observation
import ServiceManagement

/// "Open at Login" via `SMAppService.mainApp`, which works inside the App
/// Sandbox. Off until the user turns it on: App Review requires consent
/// before an app launches itself at login.
@MainActor
@Observable
final class LoginItem {
    private(set) var isEnabled = SMAppService.mainApp.status == .enabled
    private(set) var lastError: String?

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
