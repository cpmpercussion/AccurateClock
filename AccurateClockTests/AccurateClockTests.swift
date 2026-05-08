import Foundation
import Testing
@testable import AccurateClock

private let utc: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(secondsFromGMT: 0)!
    return c
}()

private func date(h: Int, m: Int, s: Int, ms: Int = 0) -> Date {
    var components = DateComponents()
    components.year = 2026; components.month = 1; components.day = 1
    components.hour = h; components.minute = m; components.second = s
    components.nanosecond = ms * 1_000_000
    return utc.date(from: components)!
}

private func clock(h: Int, m: Int, s: Int, ms: Int = 0) -> ClockTime {
    ClockTime(date: date(h: h, m: m, s: s, ms: ms), calendar: utc)
}

private func isClose(_ a: Double, _ b: Double, tolerance: Double = 1e-9) -> Bool {
    abs(a - b) < tolerance
}

struct ClockTimeTests {
    @Test func midnightZeroesEverything() {
        let c = clock(h: 0, m: 0, s: 0)
        #expect(c.hourAngle == 0)
        #expect(c.minuteAngle == 0)
        #expect(c.secondAngleSweep == 0)
        #expect(c.secondAngleTick == 0)
    }

    @Test func noonAlsoZeroesEverything() {
        let c = clock(h: 12, m: 0, s: 0)
        #expect(c.hourAngle == 0)
        #expect(c.minuteAngle == 0)
    }

    @Test func sixOClockPutsHourHandAtBottom() {
        let c = clock(h: 6, m: 0, s: 0)
        #expect(c.hourAngle == 180)
        #expect(c.minuteAngle == 0)
    }

    @Test func elevenPMReadsAsElevenOnA12HourDial() {
        let c = clock(h: 23, m: 0, s: 0)
        #expect(c.hourAngle == 330)
    }

    @Test func hourHandAdvancesWithMinutes() {
        // 3:30 — hour hand halfway between 3 and 4.
        let c = clock(h: 3, m: 30, s: 0)
        #expect(isClose(c.hourAngle, 105))
        #expect(c.minuteAngle == 180)
    }

    @Test func hourHandAdvancesWithSeconds() {
        // 9:15:30 — 9*30 + 15*0.5 + 30/120 = 277.75
        let c = clock(h: 9, m: 15, s: 30)
        #expect(isClose(c.hourAngle, 277.75))
    }

    @Test func minuteHandAdvancesWithSeconds() {
        // 0:00:30 — minute hand at 3°
        let c = clock(h: 0, m: 0, s: 30)
        #expect(isClose(c.minuteAngle, 3))
    }

    @Test func sweepingSecondHandUsesSubseconds() {
        let c = clock(h: 0, m: 0, s: 30, ms: 500)
        #expect(isClose(c.secondAngleSweep, 183))
    }

    @Test func tickingSecondHandIgnoresSubseconds() {
        let c = clock(h: 0, m: 0, s: 30, ms: 500)
        #expect(c.secondAngleTick == 180)
    }

    @Test func angleBoundariesStayBelow360() {
        let c = clock(h: 11, m: 59, s: 59, ms: 999)
        #expect(c.hourAngle < 360)
        #expect(c.minuteAngle < 360)
        #expect(c.secondAngleSweep < 360)
    }
}
