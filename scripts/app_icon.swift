// Draws the 1024 × 1024 app icon: a gift outlined in white on black, like the app mark of the login screen.
// It is drawn by hand because SF Symbols can't be used in app icons.
//
// Usage: swift scripts/app_icon.swift SecretSatan/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let side = 1024
let lineWidth: CGFloat = 34

guard CommandLine.arguments.count == 2 else {
    print("Usage: swift app_icon.swift <output.png>")
    exit(1)
}

// No alpha channel: the App Store rejects icons with transparency.
guard let context = CGContext(
    data: nil,
    width: side,
    height: side,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    print("Could not create the drawing context.")
    exit(1)
}

// Top-left origin, as in a design tool.
context.translateBy(x: 0, y: CGFloat(side))
context.scaleBy(x: 1, y: -1)

context.setFillColor(CGColor(gray: 0, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: side, height: side))

// The gift spans y 258...800: move it up so it sits in the optical center.
context.translateBy(x: 0, y: -16)

context.setStrokeColor(CGColor(gray: 1, alpha: 1))
context.setLineWidth(lineWidth)
context.setLineCap(.round)
context.setLineJoin(.round)

let center: CGFloat = 512
let lid = CGRect(x: 272, y: 404, width: 480, height: 112)
let box = CGRect(x: 312, y: 516, width: 400, height: 268)

// Lid and box.
context.addPath(CGPath(roundedRect: lid, cornerWidth: 28, cornerHeight: 28, transform: nil))
context.addPath(CGPath(roundedRect: box, cornerWidth: 24, cornerHeight: 24, transform: nil))
context.strokePath()

// Ribbon down the middle.
context.move(to: CGPoint(x: center, y: lid.minY))
context.addLine(to: CGPoint(x: center, y: box.maxY))
context.strokePath()

// Bow: one loop on each side of the knot, on top of the lid.
let knot = CGPoint(x: center, y: lid.minY)
for direction: CGFloat in [-1, 1] {
    context.move(to: knot)
    context.addCurve(
        to: CGPoint(x: center + direction * 150, y: 300),
        control1: CGPoint(x: center + direction * 40, y: 300),
        control2: CGPoint(x: center + direction * 90, y: 236)
    )
    context.addCurve(
        to: knot,
        control1: CGPoint(x: center + direction * 196, y: 352),
        control2: CGPoint(x: center + direction * 120, y: 404)
    )
}
context.strokePath()

guard
    let image = context.makeImage(),
    let destination = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    )
else {
    print("Could not create the image.")
    exit(1)
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    print("Could not write the image.")
    exit(1)
}
print("Wrote \(CommandLine.arguments[1])")
