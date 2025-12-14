#!/usr/bin/env swift

import AppKit
import CoreGraphics

// Create app icon with Things-inspired design
// A star (Today symbol) inside a rounded square panel

func createIcon(size: CGSize) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let rect = CGRect(origin: .zero, size: size)

    // Background gradient (Things blue gradient)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        CGColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0),  // Things blue
        CGColor(red: 0.0, green: 0.4, blue: 0.9, alpha: 1.0)      // Darker blue
    ]

    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0])!

    // Draw rounded rectangle background
    let cornerRadius = size.width * 0.225  // 22.5% corner radius (Apple's standard)
    let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    backgroundPath.addClip()

    context.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: size.height),
                               end: CGPoint(x: 0, y: 0),
                               options: [])

    // Draw white star (Things Today star)
    context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))

    let starPath = createStarPath(in: rect)
    starPath.fill()

    image.unlockFocus()
    return image
}

func createStarPath(in rect: CGRect) -> NSBezierPath {
    // Create a 5-pointed star centered in the rect
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let outerRadius = min(rect.width, rect.height) * 0.35  // 35% of size
    let innerRadius = outerRadius * 0.4  // Inner radius is 40% of outer

    let path = NSBezierPath()
    let angleOffset = -CGFloat.pi / 2  // Start from top

    for i in 0..<10 {
        let angle = angleOffset + (CGFloat(i) * CGFloat.pi / 5.0)
        let radius = i % 2 == 0 ? outerRadius : innerRadius
        let x = center.x + radius * cos(angle)
        let y = center.y + radius * sin(angle)

        if i == 0 {
            path.move(to: CGPoint(x: x, y: y))
        } else {
            path.line(to: CGPoint(x: x, y: y))
        }
    }

    path.close()
    return path
}

// Generate all required icon sizes for macOS
let sizes: [(Int, String)] = [
    (16, "icon_16x16"),
    (32, "icon_16x16@2x"),
    (32, "icon_32x32"),
    (64, "icon_32x32@2x"),
    (128, "icon_128x128"),
    (256, "icon_128x128@2x"),
    (256, "icon_256x256"),
    (512, "icon_256x256@2x"),
    (512, "icon_512x512"),
    (1024, "icon_512x512@2x")
]

// Create output directory
let outputDir = FileManager.default.currentDirectoryPath + "/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

// Generate all sizes
for (size, name) in sizes {
    let iconSize = CGSize(width: size, height: size)
    let icon = createIcon(size: iconSize)

    if let tiff = icon.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let filePath = "\(outputDir)/\(name).png"
        try? png.write(to: URL(fileURLWithPath: filePath))
        print("✓ Generated \(name).png")
    }
}

print("\n✓ All icon sizes generated in AppIcon.iconset/")
print("Run: iconutil -c icns AppIcon.iconset -o AppIcon.icns")
