// Generates Assets/AppIcon.icns and the README/site PNGs.
// Run: swift scripts/generate-icon.swift
import AppKit

func drawIcon(canvas: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: canvas, height: canvas))
    image.lockFocus()

    let inset = canvas * 0.10
    let rect = NSRect(x: inset, y: inset, width: canvas - inset * 2, height: canvas - inset * 2)
    let radius = rect.width * 0.2237
    let squircle = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    NSGradient(
        starting: NSColor(calibratedRed: 0.043, green: 0.165, blue: 0.290, alpha: 1),
        ending: NSColor(calibratedRed: 0.118, green: 0.435, blue: 0.851, alpha: 1)
    )!.draw(in: squircle, angle: 90)

    let barHeight = rect.height * 0.085
    let barRadius = barHeight / 2
    let barX = rect.minX + rect.width * 0.18
    let widths: [CGFloat] = [0.64, 0.48, 0.32]
    let startY = rect.minY + rect.height * 0.30

    NSColor.white.setFill()
    for (index, widthFactor) in widths.enumerated() {
        let y = startY + CGFloat(index) * rect.height * 0.17
        let bar = NSRect(x: barX, y: y, width: rect.width * widthFactor, height: barHeight)
        NSBezierPath(roundedRect: bar, xRadius: barRadius, yRadius: barRadius).fill()
    }

    let dotSide = rect.width * 0.13
    let dotRect = NSRect(
        x: rect.maxX - rect.width * 0.18 - dotSide,
        y: startY + 2 * rect.height * 0.17 - (dotSide - barHeight) / 2,
        width: dotSide, height: dotSide
    )
    NSColor(calibratedRed: 0.22, green: 0.82, blue: 0.44, alpha: 1).setFill()
    NSBezierPath(ovalIn: dotRect).fill()

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, side: Int, to path: String) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    image.draw(in: NSRect(x: 0, y: 0, width: side, height: side))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("Assets")
let docs = root.appendingPathComponent("docs")
try? FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)
try? FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)

let icon = drawIcon(canvas: 1024)
writePNG(icon, side: 1024, to: assets.appendingPathComponent("icon-1024.png").path)
writePNG(icon, side: 256, to: assets.appendingPathComponent("icon-256.png").path)
writePNG(icon, side: 256, to: docs.appendingPathComponent("icon-256.png").path)

// Build the .iconset and hand off to iconutil for the .icns.
let iconset = root.appendingPathComponent("Assets/AppIcon.iconset")
try? FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for (name, side) in [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
] {
    writePNG(icon, side: side, to: iconset.appendingPathComponent("\(name).png").path)
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", assets.appendingPathComponent("AppIcon.icns").path]
try! process.run()
process.waitUntilExit()
try? FileManager.default.removeItem(at: iconset)

print("wrote Assets/AppIcon.icns, Assets/icon-1024.png, Assets/icon-256.png, docs/icon-256.png")
