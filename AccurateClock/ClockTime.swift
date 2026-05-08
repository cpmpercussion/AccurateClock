import Foundation

/// A snapshot of "now" decomposed into the values an analogue/digital clock face needs.
///
/// All angles are degrees clockwise from the 12-o'clock position, matching
/// SwiftUI's `.rotationEffect(.degrees(_:))` when a hand is drawn pointing up.
struct ClockTime: Equatable {
    /// Fractional hours on a 12-hour dial (0 ..< 12), including the partial hour from minutes/seconds.
    let hours: Double
    /// Fractional minutes within the hour (0 ..< 60), including the partial minute from seconds.
    let minutes: Double
    /// Fractional seconds within the minute (0 ..< 60), including sub-second precision.
    let seconds: Double

    init(date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        let h = Double(parts.hour ?? 0).truncatingRemainder(dividingBy: 12)
        let m = Double(parts.minute ?? 0)
        let s = Double(parts.second ?? 0) + Double(parts.nanosecond ?? 0) / 1_000_000_000
        self.hours = h + m / 60 + s / 3600
        self.minutes = m + s / 60
        self.seconds = s
    }

    /// Hour hand: 30° per hour, plus the fractional contribution from minutes and seconds.
    var hourAngle: Double { hours * 30 }
    /// Minute hand: 6° per minute, plus the fractional contribution from seconds.
    var minuteAngle: Double { minutes * 6 }
    /// Second hand sweeping continuously at 6° per second.
    var secondAngleSweep: Double { seconds * 6 }
    /// Second hand snapping to whole-second positions (quartz-style).
    var secondAngleTick: Double { floor(seconds) * 6 }
}
