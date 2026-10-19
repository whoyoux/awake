import AppKit

/// Menu bar icons. Off is a monochrome template image like the other menu
/// bar items; on is a steaming cup in orange (the app icon's espresso
/// colour), so the state is visible at a glance. A coloured image has to be
/// a non-template NSImage, because the menu bar tints template images.
enum MenuBarIcon {
    static let off: NSImage = {
        let image = symbol("cup.and.saucer", description: "Awake: off")
        image.isTemplate = true
        return image
    }()

    static let on: NSImage = {
        let image = symbol("cup.and.heat.waves.fill", fallback: "cup.and.saucer.fill",
                           description: "Awake: on",
                           colors: [.systemOrange])
        image.isTemplate = false
        return image
    }()

    private static func symbol(_ name: String, fallback: String? = nil, description: String,
                               colors: [NSColor]? = nil) -> NSImage {
        var config = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        if let colors {
            config = config.applying(.init(paletteColors: colors))
        }
        let base = NSImage(systemSymbolName: name, accessibilityDescription: description)
            ?? fallback.flatMap { NSImage(systemSymbolName: $0, accessibilityDescription: description) }
            ?? NSImage()
        return base.withSymbolConfiguration(config) ?? base
    }
}
