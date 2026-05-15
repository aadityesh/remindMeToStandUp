#!/usr/bin/swift
import AppKit

let _ = NSApplication.shared

func renderIcon(size: Int) -> Data? {
    let s = CGFloat(size)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil,
        width: size, height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    ) else { return nil }

    // Wrap CGContext so AppKit drawing calls work
    let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = nsCtx

    let rect = NSRect(x: 0, y: 0, width: s, height: s)

    // Rounded-rect clip
    let corner = s * 0.22
    NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner).addClip()

    // Google Blue gradient
    NSGradient(
        starting: NSColor(srgbRed: 0.102, green: 0.451, blue: 0.910, alpha: 1),
        ending:   NSColor(srgbRed: 0.083, green: 0.341, blue: 0.690, alpha: 1)
    )?.draw(in: rect, angle: -135)

    // Translucent circle backdrop
    let circleD = s * 0.62
    let circleR = NSRect(x: (s - circleD)/2, y: (s - circleD)/2, width: circleD, height: circleD)
    NSColor.white.withAlphaComponent(0.18).setFill()
    NSBezierPath(ovalIn: circleR).fill()

    // Draw stick figure in white using pure NSBezierPath (works headlessly)
    let lw  = max(s * 0.045, 1.5)
    NSColor.white.withAlphaComponent(0.95).setStroke()
    NSColor.white.withAlphaComponent(0.95).setFill()

    // --- Single centred figure ---
    let cx  = s / 2
    let cy  = s * 0.48        // vertical centre of figure

    // Head
    let hr  = s * 0.10
    let headY = cy + s * 0.19
    let head = NSBezierPath(ovalIn: NSRect(x: cx - hr, y: headY - hr, width: hr*2, height: hr*2))
    head.lineWidth = lw * 0.8
    head.stroke()

    // Body
    let shoulderY = headY - hr - s * 0.02
    let hipY      = cy - s * 0.05
    let body = NSBezierPath()
    body.move(to: NSPoint(x: cx, y: shoulderY))
    body.line(to: NSPoint(x: cx, y: hipY))
    body.lineWidth = lw
    body.stroke()

    // Arms
    let armW   = s * 0.18
    let armY   = shoulderY - s * 0.07
    let arms = NSBezierPath()
    arms.move(to: NSPoint(x: cx - armW, y: armY - s * 0.04))
    arms.line(to: NSPoint(x: cx, y: armY + s * 0.04))
    arms.line(to: NSPoint(x: cx + armW, y: armY - s * 0.04))
    arms.lineWidth = lw
    arms.stroke()

    // Legs
    let legW = s * 0.14
    let legY = cy - s * 0.22
    let legs = NSBezierPath()
    legs.move(to: NSPoint(x: cx - legW, y: legY))
    legs.line(to: NSPoint(x: cx,        y: hipY))
    legs.line(to: NSPoint(x: cx + legW, y: legY))
    legs.lineWidth = lw
    legs.stroke()

    NSGraphicsContext.restoreGraphicsState()

    guard let cgImage = ctx.makeImage() else { return nil }
    let rep = NSBitmapImageRep(cgImage: cgImage)
    return rep.representation(using: .png, properties: [:])
}

// --- Build iconset and convert to ICNS ---
let fm = FileManager.default
let iconset = "AppIcon.iconset"
try? fm.createDirectory(atPath: iconset, withIntermediateDirectories: true)

let entries: [(Int, String)] = [
    (16,   "icon_16x16.png"),
    (32,   "icon_16x16@2x.png"),
    (32,   "icon_32x32.png"),
    (64,   "icon_32x32@2x.png"),
    (128,  "icon_128x128.png"),
    (256,  "icon_128x128@2x.png"),
    (256,  "icon_256x256.png"),
    (512,  "icon_256x256@2x.png"),
    (512,  "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

for (size, name) in entries {
    if let data = renderIcon(size: size) {
        try? data.write(to: URL(fileURLWithPath: "\(iconset)/\(name)"))
    }
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset, "-o", "AppIcon.icns"]
try! task.run()
task.waitUntilExit()
try? fm.removeItem(atPath: iconset)

print(task.terminationStatus == 0 ? "AppIcon.icns created" : "iconutil failed")
