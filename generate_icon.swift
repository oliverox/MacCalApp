#!/usr/bin/env swift

import AppKit
import Foundation

func createCalendarIcon(pixelSize: Int) -> NSBitmapImageRep {
    let size = pixelSize

    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    let s = CGFloat(size)
    let cornerRadius = s * 0.18
    let headerHeight = s * 0.28
    let ringRadius = s * 0.04
    let ringInset = s * 0.22

    // Background with rounded corners
    let bgPath = NSBezierPath(roundedRect: bounds.insetBy(dx: s * 0.02, dy: s * 0.02),
                               xRadius: cornerRadius, yRadius: cornerRadius)
    NSColor.white.setFill()
    bgPath.fill()

    // Red header
    let headerRect = NSRect(x: s * 0.02, y: s - headerHeight - s * 0.02,
                            width: s * 0.96, height: headerHeight)
    let headerPath = NSBezierPath()
    headerPath.move(to: NSPoint(x: headerRect.minX + cornerRadius, y: headerRect.minY))
    headerPath.line(to: NSPoint(x: headerRect.maxX - cornerRadius, y: headerRect.minY))
    headerPath.line(to: NSPoint(x: headerRect.maxX, y: headerRect.minY))
    headerPath.line(to: NSPoint(x: headerRect.maxX, y: headerRect.maxY - cornerRadius))
    headerPath.appendArc(withCenter: NSPoint(x: headerRect.maxX - cornerRadius, y: headerRect.maxY - cornerRadius),
                         radius: cornerRadius, startAngle: 0, endAngle: 90)
    headerPath.line(to: NSPoint(x: headerRect.minX + cornerRadius, y: headerRect.maxY))
    headerPath.appendArc(withCenter: NSPoint(x: headerRect.minX + cornerRadius, y: headerRect.maxY - cornerRadius),
                         radius: cornerRadius, startAngle: 90, endAngle: 180)
    headerPath.close()

    NSColor(red: 0.92, green: 0.26, blue: 0.24, alpha: 1.0).setFill()
    headerPath.fill()

    // Calendar rings
    let ringColor = NSColor(white: 0.4, alpha: 1.0)
    ringColor.setFill()

    let ring1 = NSBezierPath(ovalIn: NSRect(x: ringInset - ringRadius,
                                             y: s - headerHeight - s * 0.02 - ringRadius,
                                             width: ringRadius * 2, height: ringRadius * 2.5))
    ring1.fill()

    let ring2 = NSBezierPath(ovalIn: NSRect(x: s - ringInset - ringRadius,
                                             y: s - headerHeight - s * 0.02 - ringRadius,
                                             width: ringRadius * 2, height: ringRadius * 2.5))
    ring2.fill()

    // Date number
    let day = Calendar.current.component(.day, from: Date())
    let dayString = "\(day)"

    let fontSize = s * 0.45
    let font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(white: 0.2, alpha: 1.0)
    ]

    let textSize = dayString.size(withAttributes: attributes)
    let textRect = NSRect(x: (s - textSize.width) / 2,
                          y: (s - headerHeight - textSize.height) / 2 - s * 0.04,
                          width: textSize.width,
                          height: textSize.height)
    dayString.draw(in: textRect, withAttributes: attributes)

    // Subtle border
    let borderPath = NSBezierPath(roundedRect: bounds.insetBy(dx: s * 0.02, dy: s * 0.02),
                                   xRadius: cornerRadius, yRadius: cornerRadius)
    NSColor(white: 0.8, alpha: 1.0).setStroke()
    borderPath.lineWidth = max(1, s * 0.01)
    borderPath.stroke()

    NSGraphicsContext.restoreGraphicsState()

    return rep
}

func saveIcon(pixelSize: Int, filename: String, to directory: String) {
    let rep = createCalendarIcon(pixelSize: pixelSize)

    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for \(filename)")
        return
    }

    let url = URL(fileURLWithPath: directory).appendingPathComponent(filename)

    do {
        try pngData.write(to: url)
        print("Created \(filename) (\(pixelSize)x\(pixelSize) pixels)")
    } catch {
        print("Failed to save \(filename): \(error)")
    }
}

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

// Generate all required sizes with correct pixel dimensions
// Format: (point size, scale, pixel size, filename)
let iconSpecs: [(Int, String)] = [
    (16, "icon_16x16.png"),       // 16pt @1x = 16px
    (32, "icon_16x16@2x.png"),    // 16pt @2x = 32px
    (32, "icon_32x32.png"),       // 32pt @1x = 32px
    (64, "icon_32x32@2x.png"),    // 32pt @2x = 64px
    (128, "icon_128x128.png"),    // 128pt @1x = 128px
    (256, "icon_128x128@2x.png"), // 128pt @2x = 256px
    (256, "icon_256x256.png"),    // 256pt @1x = 256px
    (512, "icon_256x256@2x.png"), // 256pt @2x = 512px
    (512, "icon_512x512.png"),    // 512pt @1x = 512px
    (1024, "icon_512x512@2x.png") // 512pt @2x = 1024px
]

for (pixelSize, filename) in iconSpecs {
    saveIcon(pixelSize: pixelSize, filename: filename, to: outputDir)
}

print("Icon generation complete!")
