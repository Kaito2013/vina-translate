#!/usr/bin/env swift
import AppKit
import CoreGraphics
import Foundation

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/AppIcon.iconset"
let fileManager = FileManager.default
try? fileManager.removeItem(atPath: outputDir)
try fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

func drawIcon(size: Int) -> NSBitmapImageRep {
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

    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context
    let cg = context.cgContext

    let s = CGFloat(size)
    let padding = s * 0.085
    let rect = CGRect(x: padding, y: padding, width: s - padding * 2, height: s - padding * 2)
    let cornerRadius = rect.width * 0.225

    // 1. Drop shadow + squircle base
    cg.saveGState()
    cg.setShadow(
        offset: CGSize(width: 0, height: -s * 0.02),
        blur: s * 0.045,
        color: NSColor(calibratedWhite: 0, alpha: 0.35).cgColor
    )
    let bgPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    NSColor(calibratedRed: 0.07, green: 0.36, blue: 0.85, alpha: 1.0).setFill()
    bgPath.fill()
    cg.restoreGState()

    // 2. Gradient fill inside squircle
    cg.saveGState()
    bgPath.addClip()
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradientColors = [
        NSColor(calibratedRed: 0.12, green: 0.58, blue: 0.98, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.08, green: 0.32, blue: 0.82, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.05, green: 0.18, blue: 0.56, alpha: 1.0).cgColor
    ] as CFArray
    let locations: [CGFloat] = [0.0, 0.55, 1.0]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: locations) {
        cg.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.minX, y: rect.maxY),
            end: CGPoint(x: rect.maxX, y: rect.minY),
            options: []
        )
    }

    // Subtle top highlight border
    let borderPath = NSBezierPath(roundedRect: rect.insetBy(dx: s * 0.006, dy: s * 0.006), xRadius: cornerRadius, yRadius: cornerRadius)
    borderPath.lineWidth = s * 0.012
    NSColor(calibratedWhite: 1.0, alpha: 0.22).setStroke()
    borderPath.stroke()

    // 3. Back bubble (Vietnamese "VI" / warm gold-amber card on bottom-right)
    let cardW = rect.width * 0.50
    let cardH = rect.height * 0.44
    let rightCardRect = CGRect(
        x: rect.midX - cardW * 0.12,
        y: rect.minY + rect.height * 0.13,
        width: cardW,
        height: cardH
    )
    cg.saveGState()
    cg.setShadow(
        offset: CGSize(width: 0, height: -s * 0.015),
        blur: s * 0.03,
        color: NSColor(calibratedWhite: 0, alpha: 0.28).cgColor
    )
    let rightCardPath = NSBezierPath(roundedRect: rightCardRect, xRadius: cardW * 0.22, yRadius: cardW * 0.22)
    NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.18, alpha: 0.96).setFill()
    rightCardPath.fill()
    cg.restoreGState()

    // Draw "VI" on right card
    let viParagraph = NSMutableParagraphStyle()
    viParagraph.alignment = .center
    let viFont = NSFont.systemFont(ofSize: s * 0.165, weight: .heavy)
    let viAttrs: [NSAttributedString.Key: Any] = [
        .font: viFont,
        .foregroundColor: NSColor(calibratedRed: 0.10, green: 0.16, blue: 0.34, alpha: 1.0),
        .paragraphStyle: viParagraph
    ]
    let viText = NSString(string: "VI")
    let viSize = viText.size(withAttributes: viAttrs)
    let viRect = CGRect(
        x: rightCardRect.midX - viSize.width / 2,
        y: rightCardRect.midY - viSize.height / 2,
        width: viSize.width,
        height: viSize.height
    )
    viText.draw(in: viRect, withAttributes: viAttrs)

    // 4. Front bubble (English "EN" / crisp white card on top-left)
    let leftCardRect = CGRect(
        x: rect.minX + rect.width * 0.12,
        y: rect.midY - cardH * 0.10,
        width: cardW,
        height: cardH
    )
    cg.saveGState()
    cg.setShadow(
        offset: CGSize(width: s * 0.008, height: -s * 0.018),
        blur: s * 0.035,
        color: NSColor(calibratedWhite: 0, alpha: 0.32).cgColor
    )
    let leftCardPath = NSBezierPath(roundedRect: leftCardRect, xRadius: cardW * 0.22, yRadius: cardW * 0.22)
    NSColor.white.setFill()
    leftCardPath.fill()
    cg.restoreGState()

    // Draw "EN" on left card
    let enAttrs: [NSAttributedString.Key: Any] = [
        .font: viFont,
        .foregroundColor: NSColor(calibratedRed: 0.07, green: 0.34, blue: 0.84, alpha: 1.0),
        .paragraphStyle: viParagraph
    ]
    let enText = NSString(string: "EN")
    let enSize = enText.size(withAttributes: enAttrs)
    let enRect = CGRect(
        x: leftCardRect.midX - enSize.width / 2,
        y: leftCardRect.midY - enSize.height / 2,
        width: enSize.width,
        height: enSize.height
    )
    enText.draw(in: enRect, withAttributes: enAttrs)

    // 5. Bidirectional badge in center intersection
    let badgeSize = s * 0.17
    let badgeRect = CGRect(
        x: rect.midX - badgeSize / 2,
        y: rect.midY - badgeSize / 2,
        width: badgeSize,
        height: badgeSize
    )
    cg.saveGState()
    cg.setShadow(
        offset: CGSize(width: 0, height: -s * 0.008),
        blur: s * 0.02,
        color: NSColor(calibratedWhite: 0, alpha: 0.30).cgColor
    )
    let badgePath = NSBezierPath(ovalIn: badgeRect)
    NSColor(calibratedRed: 0.09, green: 0.44, blue: 0.94, alpha: 1.0).setFill()
    badgePath.fill()
    badgePath.lineWidth = s * 0.01
    NSColor.white.setStroke()
    badgePath.stroke()
    cg.restoreGState()

    let arrowFont = NSFont.systemFont(ofSize: s * 0.095, weight: .bold)
    let arrowAttrs: [NSAttributedString.Key: Any] = [
        .font: arrowFont,
        .foregroundColor: NSColor.white,
        .paragraphStyle: viParagraph
    ]
    let arrowText = NSString(string: "⇄")
    let arrowSize = arrowText.size(withAttributes: arrowAttrs)
    let arrowRect = CGRect(
        x: badgeRect.midX - arrowSize.width / 2,
        y: badgeRect.midY - arrowSize.height / 2,
        width: arrowSize.width,
        height: arrowSize.height
    )
    arrowText.draw(in: arrowRect, withAttributes: arrowAttrs)

    cg.restoreGState()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let iconSpecs: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for spec in iconSpecs {
    let rep = drawIcon(size: spec.pixels)
    if let pngData = rep.representation(using: .png, properties: [:]) {
        let fileURL = URL(fileURLWithPath: outputDir).appendingPathComponent(spec.name)
        try pngData.write(to: fileURL)
    }
}

print("Generated iconset at \(outputDir)")
