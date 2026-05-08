import SwiftUI

enum SecondsStyle: String, CaseIterable, Identifiable {
    case sweep, tick
    var id: String { rawValue }
    var label: String { self == .sweep ? "Sweep" : "Tick" }
}

struct AnalogClockView: View {
    let time: ClockTime
    let secondsStyle: SecondsStyle

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2

            ZStack {
                Circle()
                    .stroke(Color.primary, lineWidth: max(1, size * 0.006))
                    .frame(width: size, height: size)

                ForEach(0..<60) { i in
                    let isMajor = i % 5 == 0
                    Rectangle()
                        .fill(Color.primary)
                        .frame(
                            width: isMajor ? size * 0.012 : size * 0.005,
                            height: isMajor ? size * 0.06 : size * 0.025
                        )
                        .offset(y: -radius + (isMajor ? size * 0.04 : size * 0.02))
                        .rotationEffect(.degrees(Double(i) * 6))
                }

                ForEach(1...12, id: \.self) { hour in
                    let angle = (Double(hour) * 30 - 90) * .pi / 180
                    Text("\(hour)")
                        .font(.system(size: size * 0.08, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .position(
                            x: size / 2 + cos(angle) * radius * 0.78,
                            y: size / 2 + sin(angle) * radius * 0.78
                        )
                }

                hand(length: radius * 0.50, thickness: size * 0.020, angle: time.hourAngle, color: .primary)
                hand(length: radius * 0.75, thickness: size * 0.014, angle: time.minuteAngle, color: .primary)
                hand(
                    length: radius * 0.88,
                    thickness: size * 0.006,
                    angle: secondsStyle == .sweep ? time.secondAngleSweep : time.secondAngleTick,
                    color: .red
                )

                Circle()
                    .fill(Color.red)
                    .frame(width: size * 0.04, height: size * 0.04)
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func hand(length: CGFloat, thickness: CGFloat, angle: Double, color: Color) -> some View {
        // Capsule's layout frame stays centered in the ZStack (its own center == dial center).
        // The .offset shifts only the rendered capsule upward so its bottom sits at the dial
        // center; rotation happens around the layout center, so the hand pivots from the dial center.
        Capsule()
            .fill(color)
            .frame(width: thickness, height: length)
            .offset(y: -length / 2)
            .rotationEffect(.degrees(angle))
    }
}

#Preview("10:10:30 sweep") {
    AnalogClockView(
        time: ClockTime(date: previewDate(h: 10, m: 10, s: 30, ms: 250)),
        secondsStyle: .sweep
    )
    .frame(width: 320, height: 320)
    .padding()
}

#Preview("3:45:15 tick") {
    AnalogClockView(
        time: ClockTime(date: previewDate(h: 3, m: 45, s: 15)),
        secondsStyle: .tick
    )
    .frame(width: 320, height: 320)
    .padding()
}

private func previewDate(h: Int, m: Int, s: Int, ms: Int = 0) -> Date {
    var components = DateComponents()
    components.year = 2026; components.month = 1; components.day = 1
    components.hour = h; components.minute = m; components.second = s
    components.nanosecond = ms * 1_000_000
    return Calendar.current.date(from: components) ?? Date()
}
