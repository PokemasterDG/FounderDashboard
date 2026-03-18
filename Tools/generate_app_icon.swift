import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct IconSize {
    let filename: String
    let idiom: String
    let points: CGFloat
    let scale: CGFloat
    let role: String?

    var pixels: CGFloat { points * scale }
    var sizeString: String { "\(Int(points))x\(Int(points))" }
    var scaleString: String { "\(Int(scale))x" }
}

let scriptDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let projectRootDirectory = scriptDirectory.deletingLastPathComponent()
let outputDirectory = projectRootDirectory
    .appendingPathComponent("Resources", isDirectory: true)
    .appendingPathComponent("Assets.xcassets", isDirectory: true)
    .appendingPathComponent("AppIcon.appiconset", isDirectory: true)

let iconSizes = [
    IconSize(filename: "icon_16x16.png", idiom: "mac", points: 16, scale: 1, role: nil),
    IconSize(filename: "icon_16x16@2x.png", idiom: "mac", points: 16, scale: 2, role: nil),
    IconSize(filename: "icon_32x32.png", idiom: "mac", points: 32, scale: 1, role: nil),
    IconSize(filename: "icon_32x32@2x.png", idiom: "mac", points: 32, scale: 2, role: nil),
    IconSize(filename: "icon_128x128.png", idiom: "mac", points: 128, scale: 1, role: nil),
    IconSize(filename: "icon_128x128@2x.png", idiom: "mac", points: 128, scale: 2, role: nil),
    IconSize(filename: "icon_256x256.png", idiom: "mac", points: 256, scale: 1, role: nil),
    IconSize(filename: "icon_256x256@2x.png", idiom: "mac", points: 256, scale: 2, role: nil),
    IconSize(filename: "icon_512x512.png", idiom: "mac", points: 512, scale: 1, role: nil),
    IconSize(filename: "icon_512x512@2x.png", idiom: "mac", points: 512, scale: 2, role: nil),
    IconSize(filename: "icon_20x20@2x.png", idiom: "iphone", points: 20, scale: 2, role: nil),
    IconSize(filename: "icon_20x20@3x.png", idiom: "iphone", points: 20, scale: 3, role: nil),
    IconSize(filename: "icon_29x29@2x.png", idiom: "iphone", points: 29, scale: 2, role: nil),
    IconSize(filename: "icon_29x29@3x.png", idiom: "iphone", points: 29, scale: 3, role: nil),
    IconSize(filename: "icon_40x40@2x.png", idiom: "iphone", points: 40, scale: 2, role: nil),
    IconSize(filename: "icon_40x40@3x.png", idiom: "iphone", points: 40, scale: 3, role: nil),
    IconSize(filename: "icon_60x60@2x.png", idiom: "iphone", points: 60, scale: 2, role: nil),
    IconSize(filename: "icon_60x60@3x.png", idiom: "iphone", points: 60, scale: 3, role: nil),
    IconSize(filename: "icon_1024x1024.png", idiom: "ios-marketing", points: 1024, scale: 1, role: nil),
]

func starPath(in rect: CGRect) -> CGPath {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let outerRadius = min(rect.width, rect.height) * 0.5
    let innerRadius = outerRadius * 0.42
    let path = CGMutablePath()

    for index in 0..<10 {
        let angle = (-CGFloat.pi / 2) + (CGFloat(index) * .pi / 5)
        let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
        let point = CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y - sin(angle) * radius
        )

        if index == 0 {
            path.move(to: point)
        } else {
            path.addLine(to: point)
        }
    }

    path.closeSubpath()
    return path
}

func pngData(for side: CGFloat) -> Data? {
    let width = Int(side.rounded())
    let height = Int(side.rounded())
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return nil
    }

    let canvasRect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
    context.clear(canvasRect)
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high

    let outerDiameter = canvasRect.width * 0.9
    let outerRect = CGRect(
        x: (canvasRect.width - outerDiameter) * 0.5,
        y: (canvasRect.height - outerDiameter) * 0.5,
        width: outerDiameter,
        height: outerDiameter
    )
    let outerStrokeWidth = max(canvasRect.width * 0.0085, 2)

    context.setFillColor(NSColor.white.cgColor)
    context.fillEllipse(in: outerRect)
    context.setStrokeColor(NSColor.black.cgColor)
    context.setLineWidth(outerStrokeWidth)
    context.strokeEllipse(in: outerRect)

    let innerDiameter = outerDiameter * 0.14
    let innerRect = CGRect(
        x: outerRect.midX - innerDiameter * 0.5,
        y: outerRect.midY - innerDiameter * 0.5,
        width: innerDiameter,
        height: innerDiameter
    )
    context.setFillColor(NSColor.white.cgColor)
    context.fillEllipse(in: innerRect)
    context.setStrokeColor(NSColor.black.cgColor)
    context.setLineWidth(max(outerStrokeWidth * 0.95, 1.5))
    context.strokeEllipse(in: innerRect)

    let starInset = innerDiameter * 0.17
    let starRect = innerRect.insetBy(dx: starInset, dy: starInset)
    context.setFillColor(NSColor.black.cgColor)
    context.addPath(starPath(in: starRect))
    context.fillPath()

    guard let image = context.makeImage(),
          let data = CFDataCreateMutable(nil, 0),
          let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
          ) else {
        return nil
    }

    CGImageDestinationAddImage(destination, image, nil)

    guard CGImageDestinationFinalize(destination) else {
        return nil
    }

    return data as Data
}

for icon in iconSizes {
    let destination = outputDirectory.appendingPathComponent(icon.filename)

    guard let data = pngData(for: icon.pixels) else {
        fputs("Failed to generate \(icon.filename)\n", stderr)
        exit(1)
    }

    do {
        try data.write(to: destination)
        print("Wrote \(destination.path)")
    } catch {
        fputs("Failed to write \(destination.path): \(error)\n", stderr)
        exit(1)
    }
}

let contents = [
    "images": iconSizes.map { icon in
        var imageEntry: [String: String] = [
            "filename": icon.filename,
            "idiom": icon.idiom,
            "scale": icon.scaleString,
            "size": icon.sizeString,
        ]

        if let role = icon.role {
            imageEntry["role"] = role
        }

        return imageEntry
    },
    "info": [
        "author": "xcode",
        "version": 1,
    ],
] as [String: Any]

let contentsURL = outputDirectory.appendingPathComponent("Contents.json")

do {
    let contentsData = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    try contentsData.write(to: contentsURL)
    print("Wrote \(contentsURL.path)")
} catch {
    fputs("Failed to write \(contentsURL.path): \(error)\n", stderr)
    exit(1)
}
