import Foundation

/// Launch-argument-driven knobs for capturing marketing screenshots.
///
/// When `-screenshotTime "yyyy-MM-dd HH:mm:ss"` is passed, the clock faces freeze at
/// the given moment instead of tracking real time. When `-screenshotMockSync` is passed,
/// the SNTP sync footer shows a stable "synced just now" state without hitting the network.
@MainActor
enum ScreenshotMode {
    static var frozenDate: Date? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-screenshotTime"), i + 1 < args.count else {
            return nil
        }
        let raw = args[i + 1]
        return formatter(fractional: true).date(from: raw)
            ?? formatter(fractional: false).date(from: raw)
    }

    static var mockSync: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshotMockSync")
    }

    private static func formatter(fractional: Bool) -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = fractional ? "yyyy-MM-dd HH:mm:ss.SSS" : "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        return f
    }
}
