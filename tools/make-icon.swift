// Draws the Writer icon: a white serif "W" on a blue tile, with a green cursor for Focus Mode.
//   swift tools/make-icon.swift --mac out.png       1024 px PNG on the macOS icon grid (build-mac.sh turns it into .icns)
//   swift tools/make-icon.swift --ico assets/icon.ico   Windows icon with every size from 16 to 256 px
// Each size is drawn on its own rather than scaled down, so small sizes stay crisp.
import AppKit

let blueTop = NSColor(srgbRed: 58/255, green: 108/255, blue: 182/255, alpha: 1)
let blueBottom = NSColor(srgbRed: 30/255, green: 66/255, blue: 122/255, alpha: 1)
let green = NSColor(srgbRed: 51/255, green: 1, blue: 102/255, alpha: 1)

// mac: an 824/1024 tile with a shadow, as macOS icons are drawn. Windows: a full-bleed tile (1..31 on a 32 grid).
func draw(size px: Int, mac: Bool) -> Data {
    let size = CGFloat(px)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current!.imageInterpolation = .high

    let tile = mac ? NSRect(x: size * 100/1024, y: size * 100/1024, width: size * 824/1024, height: size * 824/1024)
                   : NSRect(x: size / 32, y: size / 32, width: size * 30/32, height: size * 30/32)
    let radius = tile.width * (mac ? 0.2245 : 0.2)
    let path = NSBezierPath(roundedRect: tile, xRadius: radius, yRadius: radius)
    if mac {
        let shadow = NSShadow(); shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.shadowOffset = NSSize(width: 0, height: -size * 12/1024); shadow.shadowBlurRadius = size * 28/1024
        NSGraphicsContext.saveGraphicsState(); shadow.set(); blueBottom.setFill(); path.fill(); NSGraphicsContext.restoreGraphicsState()
    }
    NSGradient(starting: blueTop, ending: blueBottom)!.draw(in: path, angle: -90)

    // White serif W, sized to about 70% of the tile's width and set a little above centre to leave room for the cursor.
    let base = NSFont(name: "Georgia-Bold", size: 100) ?? NSFont.boldSystemFont(ofSize: 100)
    let probe = NSAttributedString(string: "W", attributes: [.font: base])
    let fontSize = 100 * (tile.width * 0.70) / probe.size().width
    let font = NSFont(name: base.fontName, size: fontSize)!
    let w = NSAttributedString(string: "W", attributes: [.font: font, .foregroundColor: NSColor.white])
    let glyphW = w.size().width
    let capH = font.capHeight
    let x = tile.midX - glyphW / 2
    let baseline = tile.midY - capH / 2 + tile.height * 0.035
    w.draw(at: NSPoint(x: x, y: baseline + font.descender))

    // Green cursor, bottom right
    let cw = tile.width * 0.17, ch = max(1, tile.height * 0.063)
    green.setFill()
    NSBezierPath(roundedRect: NSRect(x: tile.maxX - tile.width * 0.08 - cw, y: tile.minY + tile.height * 0.10, width: cw, height: ch),
                 xRadius: ch * 0.12, yRadius: ch * 0.12).fill()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

// An .ico file holding PNG images (supported by Windows Vista and later).
func ico(_ images: [(Int, Data)]) -> Data {
    var d = Data()
    func u16(_ v: Int) { var x = UInt16(v).littleEndian; d.append(Data(bytes: &x, count: 2)) }
    func u32(_ v: Int) { var x = UInt32(v).littleEndian; d.append(Data(bytes: &x, count: 4)) }
    u16(0); u16(1); u16(images.count)
    var offset = 6 + 16 * images.count
    for (s, png) in images {
        d.append(UInt8(s >= 256 ? 0 : s)); d.append(UInt8(s >= 256 ? 0 : s)); d.append(0); d.append(0)
        u16(1); u16(32); u32(png.count); u32(offset); offset += png.count
    }
    images.forEach { d.append($0.1) }
    return d
}

let args = CommandLine.arguments
guard args.count == 3, ["--mac", "--ico"].contains(args[1]) else {
    print("usage: swift make-icon.swift --mac out.png | --ico out.ico"); exit(2)
}
let out = URL(fileURLWithPath: args[2])
if args[1] == "--mac" { try! draw(size: 1024, mac: true).write(to: out) }
else { try! ico([16, 20, 24, 32, 40, 48, 64, 96, 128, 256].map { ($0, draw(size: $0, mac: false)) }).write(to: out) }
