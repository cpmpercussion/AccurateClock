import Foundation

/// A city entry from the Casio AE-1200's World Time city table (Module 3198/3299).
/// The 48 cities span 31 time zones; UTC is provided as a separate non-city entry.
struct WorldTimeCity: Identifiable, Hashable {
    let code: String          // Casio 3-letter code, e.g. "SYD"
    let city: String          // Display name, e.g. "Sydney"
    let identifier: String    // IANA zone identifier, e.g. "Australia/Sydney"
    let baseOffsetMinutes: Int

    var id: String { identifier }

    /// Casio-style label for the zone's *base* offset (used for sectioning the picker).
    /// e.g. "UTC+10", "UTC+5:30", "UTC−3:30", "UTC".
    var utcOffsetLabel: String { WorldTime.formatUTCOffset(minutes: baseOffsetMinutes) }

    var timeZone: TimeZone? { TimeZone(identifier: identifier) }
}

enum WorldTime {
    /// The 48 cities + UTC, in the order Casio prints them on the AE-1200.
    static let cities: [WorldTimeCity] = [
        .init(code: "PPG", city: "Pago Pago", identifier: "Pacific/Pago_Pago", baseOffsetMinutes: -11 * 60),
        .init(code: "HNL", city: "Honolulu", identifier: "Pacific/Honolulu", baseOffsetMinutes: -10 * 60),
        .init(code: "ANC", city: "Anchorage", identifier: "America/Anchorage", baseOffsetMinutes: -9 * 60),
        .init(code: "YVR", city: "Vancouver", identifier: "America/Vancouver", baseOffsetMinutes: -8 * 60),
        .init(code: "LAX", city: "Los Angeles", identifier: "America/Los_Angeles", baseOffsetMinutes: -8 * 60),
        .init(code: "YEA", city: "Edmonton", identifier: "America/Edmonton", baseOffsetMinutes: -7 * 60),
        .init(code: "DEN", city: "Denver", identifier: "America/Denver", baseOffsetMinutes: -7 * 60),
        .init(code: "MEX", city: "Mexico City", identifier: "America/Mexico_City", baseOffsetMinutes: -6 * 60),
        .init(code: "CHI", city: "Chicago", identifier: "America/Chicago", baseOffsetMinutes: -6 * 60),
        .init(code: "NYC", city: "New York", identifier: "America/New_York", baseOffsetMinutes: -5 * 60),
        .init(code: "SCL", city: "Santiago", identifier: "America/Santiago", baseOffsetMinutes: -4 * 60),
        .init(code: "YHZ", city: "Halifax", identifier: "America/Halifax", baseOffsetMinutes: -4 * 60),
        .init(code: "YYT", city: "St. John's", identifier: "America/St_Johns", baseOffsetMinutes: -3 * 60 - 30),
        .init(code: "RIO", city: "Rio de Janeiro", identifier: "America/Sao_Paulo", baseOffsetMinutes: -3 * 60),
        .init(code: "FEN", city: "Fernando de Noronha", identifier: "America/Noronha", baseOffsetMinutes: -2 * 60),
        .init(code: "RAI", city: "Praia", identifier: "Atlantic/Cape_Verde", baseOffsetMinutes: -1 * 60),
        .init(code: "UTC", city: "UTC", identifier: "UTC", baseOffsetMinutes: 0),
        .init(code: "LIS", city: "Lisbon", identifier: "Europe/Lisbon", baseOffsetMinutes: 0),
        .init(code: "LON", city: "London", identifier: "Europe/London", baseOffsetMinutes: 0),
        .init(code: "MAD", city: "Madrid", identifier: "Europe/Madrid", baseOffsetMinutes: 1 * 60),
        .init(code: "PAR", city: "Paris", identifier: "Europe/Paris", baseOffsetMinutes: 1 * 60),
        .init(code: "ROM", city: "Rome", identifier: "Europe/Rome", baseOffsetMinutes: 1 * 60),
        .init(code: "BER", city: "Berlin", identifier: "Europe/Berlin", baseOffsetMinutes: 1 * 60),
        .init(code: "STO", city: "Stockholm", identifier: "Europe/Stockholm", baseOffsetMinutes: 1 * 60),
        .init(code: "ATH", city: "Athens", identifier: "Europe/Athens", baseOffsetMinutes: 2 * 60),
        .init(code: "CAI", city: "Cairo", identifier: "Africa/Cairo", baseOffsetMinutes: 2 * 60),
        .init(code: "JRS", city: "Jerusalem", identifier: "Asia/Jerusalem", baseOffsetMinutes: 2 * 60),
        .init(code: "MOW", city: "Moscow", identifier: "Europe/Moscow", baseOffsetMinutes: 3 * 60),
        .init(code: "JED", city: "Jeddah", identifier: "Asia/Riyadh", baseOffsetMinutes: 3 * 60),
        .init(code: "THR", city: "Tehran", identifier: "Asia/Tehran", baseOffsetMinutes: 3 * 60 + 30),
        .init(code: "DXB", city: "Dubai", identifier: "Asia/Dubai", baseOffsetMinutes: 4 * 60),
        .init(code: "KBL", city: "Kabul", identifier: "Asia/Kabul", baseOffsetMinutes: 4 * 60 + 30),
        .init(code: "KHI", city: "Karachi", identifier: "Asia/Karachi", baseOffsetMinutes: 5 * 60),
        .init(code: "DEL", city: "Delhi", identifier: "Asia/Kolkata", baseOffsetMinutes: 5 * 60 + 30),
        .init(code: "KTM", city: "Kathmandu", identifier: "Asia/Kathmandu", baseOffsetMinutes: 5 * 60 + 45),
        .init(code: "DAC", city: "Dhaka", identifier: "Asia/Dhaka", baseOffsetMinutes: 6 * 60),
        .init(code: "RGN", city: "Yangon", identifier: "Asia/Yangon", baseOffsetMinutes: 6 * 60 + 30),
        .init(code: "BKK", city: "Bangkok", identifier: "Asia/Bangkok", baseOffsetMinutes: 7 * 60),
        .init(code: "SIN", city: "Singapore", identifier: "Asia/Singapore", baseOffsetMinutes: 8 * 60),
        .init(code: "HKG", city: "Hong Kong", identifier: "Asia/Hong_Kong", baseOffsetMinutes: 8 * 60),
        .init(code: "BJS", city: "Beijing", identifier: "Asia/Shanghai", baseOffsetMinutes: 8 * 60),
        .init(code: "TPE", city: "Taipei", identifier: "Asia/Taipei", baseOffsetMinutes: 8 * 60),
        .init(code: "SEL", city: "Seoul", identifier: "Asia/Seoul", baseOffsetMinutes: 9 * 60),
        .init(code: "TYO", city: "Tokyo", identifier: "Asia/Tokyo", baseOffsetMinutes: 9 * 60),
        .init(code: "ADL", city: "Adelaide", identifier: "Australia/Adelaide", baseOffsetMinutes: 9 * 60 + 30),
        .init(code: "GUM", city: "Guam", identifier: "Pacific/Guam", baseOffsetMinutes: 10 * 60),
        .init(code: "SYD", city: "Sydney", identifier: "Australia/Sydney", baseOffsetMinutes: 10 * 60),
        .init(code: "NOU", city: "Noumea", identifier: "Pacific/Noumea", baseOffsetMinutes: 11 * 60),
        .init(code: "WLG", city: "Wellington", identifier: "Pacific/Auckland", baseOffsetMinutes: 12 * 60)
    ]

    static func city(for identifier: String) -> WorldTimeCity? {
        cities.first { $0.identifier == identifier }
    }

    /// Formats a UTC offset given as minutes east of UTC into a Casio-style label.
    static func formatUTCOffset(minutes: Int) -> String {
        if minutes == 0 { return "UTC" }
        let sign = minutes >= 0 ? "+" : "−"
        let magnitude = abs(minutes)
        let hours = magnitude / 60
        let mins = magnitude % 60
        if mins == 0 {
            return "UTC\(sign)\(hours)"
        }
        return "UTC\(sign)\(hours):\(String(format: "%02d", mins))"
    }

    /// Cities grouped by their Casio-printed base UTC offset, preserving the table's order.
    /// 31 groups in total, matching the manual's "48 cities (31 time zones)" count.
    static var groupedByOffset: [(offsetLabel: String, offsetMinutes: Int, cities: [WorldTimeCity])] {
        var seen: [Int] = []
        var groups: [(String, Int, [WorldTimeCity])] = []
        for city in cities {
            if let index = seen.firstIndex(of: city.baseOffsetMinutes) {
                groups[index].2.append(city)
            } else {
                seen.append(city.baseOffsetMinutes)
                groups.append((city.utcOffsetLabel, city.baseOffsetMinutes, [city]))
            }
        }
        return groups.map { (offsetLabel: $0.0, offsetMinutes: $0.1, cities: $0.2) }
    }
}
