// Draws the Mac app icon (same design as the Windows one: a white serif "S" on a blue tile with a green
// Focus Mode cursor) at 1024 px, sized and padded the way macOS icons are. Usage: swift make-icon.swift out.png
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// macOS icon grid: an 824 px rounded square centred in 1024, with a soft shadow.
let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
let path = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)
let shadow = NSShadow(); shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
shadow.shadowOffset = NSSize(width: 0, height: -12); shadow.shadowBlurRadius = 28
NSGraphicsContext.saveGraphicsState(); shadow.set()
NSColor(srgbRed: 30/255, green: 66/255, blue: 122/255, alpha: 1).setFill(); path.fill()
NSGraphicsContext.restoreGraphicsState()
NSGradient(starting: NSColor(srgbRed: 58/255, green: 108/255, blue: 182/255, alpha: 1),
           ending: NSColor(srgbRed: 30/255, green: 66/255, blue: 122/255, alpha: 1))!.draw(in: path, angle: -90)

// White serif S
let font = NSFont(name: "Georgia-Bold", size: 640) ?? NSFont.boldSystemFont(ofSize: 640)
let s = NSAttributedString(string: "S", attributes: [.font: font, .foregroundColor: NSColor.white])
let b = s.boundingRect(with: NSSize(width: size, height: size), options: [.usesLineFragmentOrigin])
let glyphBox = s.size()
s.draw(at: NSPoint(x: (size - glyphBox.width) / 2 - 10, y: (size - b.height) / 2 + 10))

// Green cursor, bottom right
NSColor(srgbRed: 51/255, green: 1, blue: 102/255, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 660, y: 215, width: 140, height: 52), xRadius: 6, yRadius: 6).fill()

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
