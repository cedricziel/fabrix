#!/usr/bin/env xcrun swift
// Renders the Fabrix mark into the iOS and macOS AppIcon sets.
// Usage: xcrun swift scripts/render-app-icons.swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let iosSet = root.appendingPathComponent("App/iOS/Assets.xcassets/AppIcon.appiconset")
let macSet = root.appendingPathComponent("App/macOS/Assets.xcassets/AppIcon.appiconset")
let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ hex: UInt32) -> CGColor {
    CGColor(
        colorSpace: srgb,
        components: [
            CGFloat((hex >> 16) & 0xFF) / 255, CGFloat((hex >> 8) & 0xFF) / 255, CGFloat(hex & 0xFF) / 255, 1,
        ]
    )!
}

// Keep in sync with Palette.swift.
let graphite = color(0x18181B)
let white = color(0xFFFFFF)
let signal = color(0xC2410C)

/// Draws the mark from the Foundations board (a 56-unit square) into `rect`.
/// The ground is a full square; callers clip it to the platform's shape.
func drawMark(in ctx: CGContext, rect: CGRect) {
    let unit = rect.width / 56
    ctx.saveGState()
    ctx.translateBy(x: rect.minX, y: rect.maxY)
    ctx.scaleBy(x: unit, y: -unit)

    ctx.setFillColor(graphite)
    ctx.fill(CGRect(x: 0, y: 0, width: 56, height: 56))

    // M20 38 V22 a6 6 0 0 1 12 0 v12 a3 3 0 0 0 6 0 V20
    let stroke = CGMutablePath()
    stroke.move(to: CGPoint(x: 20, y: 38))
    stroke.addLine(to: CGPoint(x: 20, y: 22))
    stroke.addArc(center: CGPoint(x: 26, y: 22), radius: 6, startAngle: .pi, endAngle: 0, clockwise: false)
    stroke.addLine(to: CGPoint(x: 32, y: 34))
    stroke.addArc(center: CGPoint(x: 35, y: 34), radius: 3, startAngle: .pi, endAngle: 0, clockwise: true)
    stroke.addLine(to: CGPoint(x: 38, y: 20))
    ctx.addPath(stroke)
    ctx.setStrokeColor(white)
    ctx.setLineWidth(3.5)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.strokePath()

    ctx.setFillColor(signal)
    ctx.fillEllipse(in: CGRect(x: 38 - 3.5, y: 16 - 3.5, width: 7, height: 7))
    ctx.restoreGState()
}

func write(_ image: CGImage, to url: URL) {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    precondition(CGImageDestinationFinalize(dest), "failed to write \(url.path)")
}

/// iOS: full-bleed, opaque. The system applies the corner mask.
func renderIOS() {
    let size = 1024
    let ctx = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: srgb,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!
    drawMark(in: ctx, rect: CGRect(x: 0, y: 0, width: size, height: size))
    write(ctx.makeImage()!, to: iosSet.appendingPathComponent("AppIcon-1024.png"))
}

/// macOS: the shape sits on the 1024 grid at 824 with a soft drop shadow,
/// per Apple's macOS icon template.
func renderMac(pixels: Int) -> CGImage {
    let ctx = CGContext(
        data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0, space: srgb,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    let scale = CGFloat(pixels) / 1024
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
        .applying(CGAffineTransform(scaleX: scale, y: scale))
    ctx.setShadow(offset: CGSize(width: 0, height: -10 * scale), blur: 20 * scale, color: color(0x000000).copy(alpha: 0.3))
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    let squircle = CGPath(roundedRect: body, cornerWidth: 185.4 * scale, cornerHeight: 185.4 * scale, transform: nil)
    ctx.addPath(squircle)
    ctx.clip()
    drawMark(in: ctx, rect: body)
    ctx.endTransparencyLayer()
    return ctx.makeImage()!
}

renderIOS()

var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = points * scale
        let name = "AppIcon-\(points)@\(scale)x.png"
        write(renderMac(pixels: pixels), to: macSet.appendingPathComponent(name))
        images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
    }
}

func writeContents(_ images: [[String: String]], to set: URL) throws {
    let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
    try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
        .write(to: set.appendingPathComponent("Contents.json"))
}

try writeContents(images, to: macSet)
try writeContents(
    [["idiom": "universal", "platform": "ios", "size": "1024x1024", "filename": "AppIcon-1024.png"]], to: iosSet)
print("Rendered app icons.")
