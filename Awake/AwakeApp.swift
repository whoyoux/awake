import SwiftUI

@main
struct AwakeApp: App {
    @State private var controller = AwakeController()
    @State private var loginItem = LoginItem()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(controller: controller, loginItem: loginItem)
        } label: {
            Image(nsImage: controller.isActive ? MenuBarIcon.on : MenuBarIcon.off)
                .accessibilityLabel(controller.isActive ? "Awake: on" : "Awake: off")
        }
        // A window-style panel (rather than a plain menu) lets the elapsed and
        // remaining time update live while it is open.
        .menuBarExtraStyle(.window)
    }
}
