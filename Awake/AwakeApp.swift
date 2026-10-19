import SwiftUI

@main
struct AwakeApp: App {
    @State private var controller = AwakeController()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(controller: controller)
        } label: {
            // SF Symbols render as template images in the menu bar, so the
            // icon follows light and dark mode automatically.
            Image(systemName: controller.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                .accessibilityLabel(controller.isActive ? "Awake: on" : "Awake: off")
        }
        // A window-style panel (rather than a plain menu) lets the elapsed and
        // remaining time update live while it is open.
        .menuBarExtraStyle(.window)
    }
}
