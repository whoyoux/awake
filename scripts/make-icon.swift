// Draws the app icon PNGs into Awake/Assets.xcassets/AppIcon.appiconset.
// Usage: swift scripts/make-icon.swift
// Uses only AppKit, so the icon can be regenerated without any extra tools.
import AppKit

let outDir = URL(fileURLWithPath: "Awake/Assets.xcassets/AppIcon.appiconset")

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(pixels)

    // macOS icon grid: 824/1024 rounded square, centred, with a soft shadow.
    let inset = s * 100 / 1024
    let tile = NSRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let path = NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.225, yRadius: tile.width * 0.225)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.01)
    shadow.shadowBlurRadius = s * 0.02
    shadow.set()
    NSColor.black.setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()

    let gradient = NSGradient(
        starting: NSColor(calibratedRed: 1.00, green: 0.72, blue: 0.30, alpha: 1),
        ending: NSColor(calibratedRed: 0.86, green: 0.36, blue: 0.16, alpha: 1))!
    gradient.draw(in: path, angle: -90)

    let config = NSImage.SymbolConfiguration(pointSize: s * 0.42, weight: .semibold)
        .applying(.init(paletteColors: [.white]))
    if let symbol = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let size = symbol.size
        let rect = NSRect(x: (s - size.width) / 2, y: (s - size.height) / 2 - s * 0.01,
                          width: size.width, height: size.height)
        symbol.draw(in: rect)
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try! render(pixels: size * scale).write(to: outDir.appendingPathComponent(name))
        print("wrote \(name)")
    }
}
