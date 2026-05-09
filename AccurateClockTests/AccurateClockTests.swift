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

struct SNTPMathTests {
    @Test func encodeDecodeRoundTrip() {
        let original: TimeInterval = 1_762_651_234.567_890_1
        let encoded = SNTP.encodeTimestamp(unixSeconds: original)
        let decoded = SNTP.decodeTimestamp(seconds: encoded.seconds, fraction: encoded.fraction)
        // 32-bit fraction has ~233ps resolution; we should round-trip well under 1µs.
        #expect(abs(decoded - original) < 1e-6)
    }

    @Test func ntpEpochOffsetIs70YearsBeforeUnixEpoch() {
        // 1900 → 1970 is 2208988800 seconds.
        #expect(SNTP.ntpEpochOffset == 2_208_988_800)
    }

    @Test func zeroOffsetWhenClocksAlignAndNoDelay() {
        let result = SNTP.computeOffset(t1: 0, t2: 0, t3: 0, t4: 0)
        #expect(result.offset == 0)
        #expect(result.delay == 0)
    }

    @Test func offsetReflectsServerAheadByFiveSecondsWithSymmetricDelay() {
        // Server clock is +5s; round-trip is 100ms (50ms each way).
        let result = SNTP.computeOffset(t1: 0, t2: 5.05, t3: 5.05, t4: 0.1)
        #expect(abs(result.offset - 5) < 1e-9)
        #expect(abs(result.delay - 0.1) < 1e-9)
    }

    @Test func offsetRecoveredEvenWithLargeRoundTripDelay() {
        // Server +1s; round-trip is 800ms (400ms each way).
        let result = SNTP.computeOffset(t1: 0, t2: 1.4, t3: 1.4, t4: 0.8)
        #expect(abs(result.offset - 1) < 1e-9)
        #expect(abs(result.delay - 0.8) < 1e-9)
    }
}

struct WorldTimeTests {
    @Test func tableHas48CitiesPlusUTC() {
        // Casio AE-1200: "World Time: 48 cities (31 time zones) and Coordinated Universal Time"
        #expect(WorldTime.cities.count == 49)
        #expect(WorldTime.cities.filter { $0.code == "UTC" }.count == 1)
    }

    @Test func everyIdentifierResolvesToATimeZone() {
        for city in WorldTime.cities {
            #expect(TimeZone(identifier: city.identifier) != nil, "Bad IANA identifier: \(city.identifier)")
        }
    }

    @Test func cityCodesAreUniqueThreeLetterStrings() {
        let codes = WorldTime.cities.map(\.code)
        #expect(Set(codes).count == codes.count)
        for code in codes {
            #expect(code.count == 3)
        }
    }

    @Test func groupedByOffsetProduces31Zones() {
        // The manual explicitly states "48 cities (31 time zones)".
        #expect(WorldTime.groupedByOffset.count == 31)
    }

    @Test func utcOffsetLabelFormatting() {
        let syd = WorldTime.city(for: "Australia/Sydney")!
        #expect(syd.utcOffsetLabel == "UTC+10")

        let del = WorldTime.city(for: "Asia/Kolkata")!
        #expect(del.utcOffsetLabel == "UTC+5:30")

        let ktm = WorldTime.city(for: "Asia/Kathmandu")!
        #expect(ktm.utcOffsetLabel == "UTC+5:45")

        let yyt = WorldTime.city(for: "America/St_Johns")!
        #expect(yyt.utcOffsetLabel == "UTC−3:30")

        let utc = WorldTime.city(for: "UTC")!
        #expect(utc.utcOffsetLabel == "UTC")
    }

    @Test func formatUTCOffsetCoversArbitraryLiveOffsets() {
        // Whole hours, both signs, including the zero case.
        #expect(WorldTime.formatUTCOffset(minutes: 0) == "UTC")
        #expect(WorldTime.formatUTCOffset(minutes: 60) == "UTC+1")
        #expect(WorldTime.formatUTCOffset(minutes: -60) == "UTC−1")
        // Live DST shift — Sydney during AEDT is +11 even though Casio prints +10.
        #expect(WorldTime.formatUTCOffset(minutes: 11 * 60) == "UTC+11")
        // Sub-hour offsets.
        #expect(WorldTime.formatUTCOffset(minutes: 5 * 60 + 45) == "UTC+5:45")
        #expect(WorldTime.formatUTCOffset(minutes: -(3 * 60 + 30)) == "UTC−3:30")
    }
}
