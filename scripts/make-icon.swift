// Draws the Awake app icon with AppKit, so it can be regenerated without any
// design tool or third-party dependency.
//
//   swift scripts/make-icon.swift [variant]          writes Awake/AppIcon.icon (drawn cup)
//   swift scripts/make-icon.swift --artwork <png>    writes Awake/AppIcon.icon around
//                                                    artwork from generate-icon-artwork.mjs
//   swift scripts/make-icon.swift preview <png>      renders the drawn variants side by side
//   swift scripts/make-icon.swift preview <png> <artwork>...
//                                                    renders artwork candidates as icons
//
// AppIcon.icon is an Icon Composer bundle: a background fill plus the
// foreground as layers. Xcode turns it into the Liquid Glass icon on
// macOS 26+ and into plain icons for older systems.
import AppKit

struct Variant {
    var name: String
    var top: NSColor          // background gradient, top
    var bottom: NSColor       // background gradient, bottom
    var cup: NSColor
    var cupShade: NSColor
    var coffee: NSColor
    var steam: NSColor
}

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

let variants = [
    Variant(name: "espresso", top: rgb(0xF6A04D), bottom: rgb(0xB4441C),
            cup: rgb(0xFFF8EE), cupShade: rgb(0xEBD9C4), coffee: rgb(0x5A2E17), steam: rgb(0xFFFFFF, 0.9)),
    Variant(name: "night", top: rgb(0x3B3F9E), bottom: rgb(0x14163F),
            cup: rgb(0xFFC860), cupShade: rgb(0xF59A3A), coffee: rgb(0x6B3415), steam: rgb(0xFFFFFF, 0.85)),
    Variant(name: "mint", top: rgb(0x5EE0B5), bottom: rgb(0x14907A),
            cup: rgb(0xFFFFFF), cupShade: rgb(0xDDEFEA), coffee: rgb(0x4A2A1A), steam: rgb(0xFFFFFF, 0.9)),
]

// MARK: - Drawing (1024 × 1024 canvas, y up)

let cx: CGFloat = 470   // cup centre; the handle sits to the right
let dy: CGFloat = -50   // moves the whole drawing down to centre it optically

func shifted(_ draw: () -> Void) {
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.saveGState()
    ctx.translateBy(x: 0, y: dy)
    draw()
    ctx.restoreGState()
}

func drawCup(_ v: Variant) { shifted {
    // Saucer
    let saucer = NSBezierPath(ovalIn: NSRect(x: cx - 300 + 40, y: 238, width: 600, height: 104))
    v.cupShade.setFill()
    saucer.fill()
    let saucerTop = NSBezierPath(ovalIn: NSRect(x: cx - 280 + 40, y: 258, width: 560, height: 84))
    v.cup.setFill()
    saucerTop.fill()

    // Handle, behind the body
    let handle = NSBezierPath(ovalIn: NSRect(x: cx + 150, y: 400, width: 190, height: 200))
    handle.lineWidth = 52
    v.cupShade.setStroke()
    handle.stroke()

    // Body: wide rim, narrower rounded base
    let body = NSBezierPath()
    body.move(to: NSPoint(x: cx - 230, y: 650))
    body.curve(to: NSPoint(x: cx - 120, y: 318),
               controlPoint1: NSPoint(x: cx - 236, y: 470), controlPoint2: NSPoint(x: cx - 200, y: 330))
    body.line(to: NSPoint(x: cx + 120, y: 318))
    body.curve(to: NSPoint(x: cx + 230, y: 650),
               controlPoint1: NSPoint(x: cx + 200, y: 330), controlPoint2: NSPoint(x: cx + 236, y: 470))
    body.close()
    NSGradient(starting: v.cup, ending: v.cupShade)!.draw(in: body, angle: 0)

    // Rim and coffee
    let rim = NSBezierPath(ovalIn: NSRect(x: cx - 230, y: 610, width: 460, height: 80))
    v.cup.setFill()
    rim.fill()
    let coffee = NSBezierPath(ovalIn: NSRect(x: cx - 200, y: 622, width: 400, height: 58))
    v.coffee.setFill()
    coffee.fill()
} }

func drawSteam(_ v: Variant) { shifted {
    for (i, dx) in [CGFloat(-95), 0, 95].enumerated() {
        let x = cx + dx
        let base: CGFloat = i == 1 ? 730 : 712
        let height: CGFloat = i == 1 ? 190 : 150
        let s = NSBezierPath()
        s.move(to: NSPoint(x: x, y: base))
        s.curve(to: NSPoint(x: x, y: base + height),
                controlPoint1: NSPoint(x: x + 60, y: base + height * 0.35),
                controlPoint2: NSPoint(x: x - 60, y: base + height * 0.65))
        s.lineWidth = 36
        s.lineCapStyle = .round
        v.steam.setStroke()
        s.stroke()
    }
} }

func drawBackground(_ v: Variant, in rect: NSRect) {
    let tile = NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.225, yRadius: rect.width * 0.225)
    NSGradient(starting: v.top, ending: v.bottom)!.draw(in: tile, angle: -90)
}

func image(size: Int, _ draw: () -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    ctx.cgContext.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func png(_ rep: NSBitmapImageRep) -> Data { rep.representation(using: .png, properties: [:])! }

func hexString(_ c: NSColor) -> String {
    let c = c.usingColorSpace(.sRGB)!
    return String(format: "srgb:%.5f,%.5f,%.5f,1.00000", c.redComponent, c.greenComponent, c.blueComponent)
}

// MARK: - Outputs

/// Scale of an artwork layer inside the icon, matching the preview.
let artworkScale: CGFloat = 0.88

func writeArtworkIconBundle(_ v: Variant, artwork: URL, to dir: URL) throws {
    let fm = FileManager.default
    try? fm.removeItem(at: dir)
    try fm.createDirectory(at: dir.appendingPathComponent("Assets"), withIntermediateDirectories: true)
    try fm.copyItem(at: artwork, to: dir.appendingPathComponent("Assets/artwork.png"))
    let json = """
    {
      "fill" : {
        "linear-gradient" : [
          "\(hexString(v.top))",
          "\(hexString(v.bottom))"
        ]
      },
      "groups" : [
        {
          "layers" : [
            {
              "image-name" : "artwork.png",
              "name" : "artwork",
              "position" : { "scale" : \(artworkScale), "translation-in-points" : [ 0, 0 ] }
            }
          ],
          "shadow" : { "kind" : "neutral", "opacity" : 0.5 },
          "translucency" : { "enabled" : false, "value" : 0 }
        }
      ],
      "supported-platforms" : {
        "squares" : "shared"
      }
    }

    """
    try json.write(to: dir.appendingPathComponent("icon.json"), atomically: true, encoding: .utf8)
}

func writeIconBundle(_ v: Variant, to dir: URL) throws {
    let fm = FileManager.default
    try? fm.removeItem(at: dir)
    try fm.createDirectory(at: dir.appendingPathComponent("Assets"), withIntermediateDirectories: true)
    try png(image(size: 1024) { drawCup(v) }).write(to: dir.appendingPathComponent("Assets/cup.png"))
    try png(image(size: 1024) { drawSteam(v) }).write(to: dir.appendingPathComponent("Assets/steam.png"))
    let json = """
    {
      "fill" : {
        "linear-gradient" : [
          "\(hexString(v.top))",
          "\(hexString(v.bottom))"
        ]
      },
      "groups" : [
        {
          "layers" : [
            { "image-name" : "steam.png", "name" : "steam" }
          ],
          "shadow" : { "kind" : "neutral", "opacity" : 0.3 },
          "translucency" : { "enabled" : true, "value" : 0.4 }
        },
        {
          "layers" : [
            { "image-name" : "cup.png", "name" : "cup" }
          ],
          "shadow" : { "kind" : "neutral", "opacity" : 0.5 },
          "translucency" : { "enabled" : false, "value" : 0 }
        }
      ],
      "supported-platforms" : {
        "squares" : "shared"
      }
    }

    """
    try json.write(to: dir.appendingPathComponent("icon.json"), atomically: true, encoding: .utf8)
}

func writePreview(to url: URL, artworks: [URL] = []) throws {
    let espresso = variants[0]
    let artImages = artworks.map { NSImage(contentsOf: $0)! }
    let count = artworks.isEmpty ? variants.count : artworks.count
    let tile = 512, gap = 48
    let width = count * tile + (count + 1) * gap
    let height = tile + 2 * gap + 60
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    rgb(0xECECEF).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    for i in 0..<count {
        let v = artworks.isEmpty ? variants[i] : espresso
        let x = CGFloat(gap + i * (tile + gap)), y = CGFloat(gap + 60)
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.saveGState()
        ctx.translateBy(x: x, y: y)
        ctx.scaleBy(x: CGFloat(tile) / 1024, y: CGFloat(tile) / 1024)
        drawBackground(v, in: NSRect(x: 100, y: 100, width: 824, height: 824))
        // Content scaled into the tile the way Icon Composer places layers.
        ctx.translateBy(x: 512, y: 512)
        ctx.scaleBy(x: 0.8, y: 0.8)
        ctx.translateBy(x: -512, y: -512)
        if artworks.isEmpty {
            drawCup(v)
            drawSteam(v)
        } else {
            let inset = 1024 * (1 - artworkScale) / 2
            artImages[i].draw(in: NSRect(x: inset, y: inset, width: 1024 - 2 * inset, height: 1024 - 2 * inset))
        }
        ctx.restoreGState()
        let label = (artworks.isEmpty ? "\(i + 1). \(v.name)" : "\(i + 1)") as NSString
        label.draw(at: NSPoint(x: x + CGFloat(tile) / 2 - 60, y: 30),
                   withAttributes: [.font: NSFont.systemFont(ofSize: 34, weight: .semibold),
                                    .foregroundColor: NSColor.darkGray])
    }
    NSGraphicsContext.restoreGraphicsState()
    try png(rep).write(to: url)
}

let args = CommandLine.arguments.dropFirst()
if args.first == "preview", let out = args.dropFirst().first {
    try writePreview(to: URL(fileURLWithPath: out),
                     artworks: args.dropFirst(2).map { URL(fileURLWithPath: $0) })
    print("wrote \(out)")
} else if args.first == "--artwork", let artwork = args.dropFirst().first {
    try writeArtworkIconBundle(variants[0], artwork: URL(fileURLWithPath: artwork),
                               to: URL(fileURLWithPath: "Awake/AppIcon.icon"))
    print("wrote Awake/AppIcon.icon (artwork \(artwork))")
} else {
    let name = args.first ?? "espresso"
    guard let v = variants.first(where: { $0.name == name }) else {
        fatalError("unknown variant \(name); one of \(variants.map(\.name))")
    }
    try writeIconBundle(v, to: URL(fileURLWithPath: "Awake/AppIcon.icon"))
    print("wrote Awake/AppIcon.icon (\(name))")
}
