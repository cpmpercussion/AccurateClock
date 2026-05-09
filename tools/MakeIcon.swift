// Renders the AccurateClock app icon (and its iOS 18 dark/tinted variants) to PNGs.
//
// Usage:
//   swift tools/MakeIcon.swift AccurateClock/Assets.xcassets/AppIcon.appiconset
//
// Produces:
//   <out>/AppIcon.png         — light/default 1024×1024 with the brown background
//   <out>/AppIconDark.png     — transparent bg, full-colour foreground for dark mode
//   <out>/AppIconTinted.png   — transparent bg, monochrome for the user-tinted home screen

import SwiftUI
import AppKit

private let bgLight    = Color(red: 122/255, green:  97/255, blue:  91/255)
private let bgDark     = Color(red:  90/255, green:  73/255, blue:  69/255)
private let face       = Color(red: 242/255, green: 210/255, blue: 172/255)
private let faceStroke = Color(red: 170/255, green: 131/255, blue:  92/255)
private let hand       = Color(red: 192/255, green:  60/255, blue:  14/255)

private let iconSize: CGFloat = 1024
private let faceDiameter: CGFloat = 760
private let handLength: CGFloat = 320
private let handThickness: CGFloat = 20
private let pinDiameter: CGFloat = 44

// Hand parked at 1 o'clock: 30° clockwise from the 12 o'clock position.
private let handAngleFromTwelve: Double = 30
private let handAngleSwiftUI: Double = handAngleFromTwelve - 90
private let trailSpan: Double = 100

enum IconVariant { case light, dark, tinted }

struct AppIcon: View {
    let variant: IconVariant

    var body: some View {
        ZStack {
            background

            Circle()
                .fill(faceFill)
                .frame(width: faceDiameter, height: faceDiameter)
                .overlay(
                    Circle().stroke(faceStrokeColor, lineWidth: 4)
                )

            sweepTrail
                .frame(width: faceDiameter, height: faceDiameter)
                .clipShape(Circle())

            Capsule()
                .fill(handFill)
                .frame(width: handThickness, height: handLength)
                .offset(y: -handLength / 2)
                .rotationEffect(.degrees(handAngleFromTwelve))

            Circle()
                .fill(handFill)
                .frame(width: pinDiameter, height: pinDiameter)
        }
        .frame(width: iconSize, height: iconSize)
    }

    @ViewBuilder
    private var background: some View {
        switch variant {
        case .light:
            LinearGradient(colors: [bgLight, bgDark], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dark, .tinted:
            Color.clear
        }
    }

    private var faceFill: Color {
        switch variant {
        case .light, .dark: return face
        case .tinted: return Color.white.opacity(0.55)
        }
    }

    private var faceStrokeColor: Color {
        switch variant {
        case .light, .dark: return faceStroke.opacity(0.35)
        case .tinted: return Color.white.opacity(0.25)
        }
    }

    private var handFill: Color {
        switch variant {
        case .light, .dark: return hand
        case .tinted: return Color.white
        }
    }

    private var trailColor: Color {
        switch variant {
        case .light, .dark: return hand
        case .tinted: return Color.white
        }
    }

    private var sweepTrail: some View {
        let trailStart = handAngleSwiftUI - trailSpan
        return TrailWedge(startAngle: trailStart, endAngle: handAngleSwiftUI)
            .fill(
                AngularGradient(
                    gradient: Gradient(stops: [
                        .init(color: trailColor.opacity(0.0), location: 0.0),
                        .init(color: trailColor.opacity(0.55), location: 1.0)
                    ]),
                    center: .center,
                    startAngle: .degrees(trailStart),
                    endAngle: .degrees(handAngleSwiftUI)
                )
            )
    }
}

private struct TrailWedge: Shape {
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var p = Path()
        p.move(to: center)
        p.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        p.closeSubpath()
        return p
    }
}

MainActor.assumeIsolated {
    let outputDir = CommandLine.arguments.dropFirst().first ?? "."

    let targets: [(IconVariant, String)] = [
        (.light, "AppIcon.png"),
        (.dark, "AppIconDark.png"),
        (.tinted, "AppIconTinted.png")
    ]

    for (variant, filename) in targets {
        let renderer = ImageRenderer(content: AppIcon(variant: variant))
        renderer.scale = 1
        renderer.isOpaque = (variant == .light)

        guard let cgImage = renderer.cgImage else {
            FileHandle.standardError.write(Data("Failed to render \(variant)\n".utf8))
            exit(1)
        }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            FileHandle.standardError.write(Data("Failed to encode \(variant)\n".utf8))
            exit(1)
        }
        let path = "\(outputDir)/\(filename)"
        do {
            try data.write(to: URL(fileURLWithPath: path))
            print("Wrote \(path) (\(cgImage.width)×\(cgImage.height))")
        } catch {
            FileHandle.standardError.write(Data("Write failed for \(filename): \(error)\n".utf8))
            exit(1)
        }
    }
}
