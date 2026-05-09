// Renders the AccurateClock app icon to a 1024×1024 PNG.
//
//   swift tools/MakeIcon.swift AccurateClock/Assets.xcassets/AppIcon.appiconset/AppIcon.png
//
// The hand is parked at 1 o'clock with a fading angular sweep trail behind it.

import SwiftUI
import AppKit

private let bgLight    = Color(red: 122/255, green:  97/255, blue:  91/255)  // #7A615B (slight lift on the base)
private let bgDark     = Color(red:  90/255, green:  73/255, blue:  69/255)  // #5A4945 (slight shade)
private let face       = Color(red: 242/255, green: 210/255, blue: 172/255)  // #F2D2AC
private let faceStroke = Color(red: 170/255, green: 131/255, blue:  92/255)  // #AA835C
private let hand       = Color(red: 192/255, green:  60/255, blue:  14/255)  // #C03C0E

private let iconSize: CGFloat = 1024
private let faceDiameter: CGFloat = 760
private let handLength: CGFloat = 320
private let handThickness: CGFloat = 20
private let pinDiameter: CGFloat = 44

// Hand parked at 1 o'clock: 30° clockwise from the 12 o'clock position.
private let handAngleFromTwelve: Double = 30
// SwiftUI angles measure from 3 o'clock (positive x), so subtract 90° to convert.
private let handAngleSwiftUI: Double = handAngleFromTwelve - 90
private let trailSpan: Double = 100  // degrees of fade behind the hand

struct AppIcon: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [bgLight, bgDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(face)
                .frame(width: faceDiameter, height: faceDiameter)
                .overlay(
                    Circle().stroke(faceStroke.opacity(0.35), lineWidth: 4)
                )

            sweepTrail
                .frame(width: faceDiameter, height: faceDiameter)
                .clipShape(Circle())

            Capsule()
                .fill(hand)
                .frame(width: handThickness, height: handLength)
                .offset(y: -handLength / 2)
                .rotationEffect(.degrees(handAngleFromTwelve))

            Circle()
                .fill(hand)
                .frame(width: pinDiameter, height: pinDiameter)
        }
        .frame(width: iconSize, height: iconSize)
    }

    private var sweepTrail: some View {
        let trailStart = handAngleSwiftUI - trailSpan
        return TrailWedge(startAngle: trailStart, endAngle: handAngleSwiftUI)
            .fill(
                AngularGradient(
                    gradient: Gradient(stops: [
                        .init(color: hand.opacity(0.0), location: 0.0),
                        .init(color: hand.opacity(0.55), location: 1.0)
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
    let outputPath = CommandLine.arguments.dropFirst().first ?? "icon.png"
    let renderer = ImageRenderer(content: AppIcon())
    renderer.scale = 1

    guard let cgImage = renderer.cgImage else {
        FileHandle.standardError.write(Data("Failed to render image\n".utf8))
        exit(1)
    }
    let rep = NSBitmapImageRep(cgImage: cgImage)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write(Data("Failed to encode PNG\n".utf8))
        exit(1)
    }
    do {
        try data.write(to: URL(fileURLWithPath: outputPath))
        print("Wrote \(outputPath) (\(cgImage.width)×\(cgImage.height))")
    } catch {
        FileHandle.standardError.write(Data("Write failed: \(error)\n".utf8))
        exit(1)
    }
}
