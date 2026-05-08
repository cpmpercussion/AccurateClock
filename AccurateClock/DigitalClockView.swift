import SwiftUI

struct DigitalClockView: View {
    let date: Date
    var calendar: Calendar = .current
    var showSubseconds: Bool = true

    var body: some View {
        let parts = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        let h = parts.hour ?? 0
        let m = parts.minute ?? 0
        let s = parts.second ?? 0
        let hundredths = (parts.nanosecond ?? 0) / 10_000_000

        let mainText = String(format: "%02d:%02d:%02d", h, m, s)

        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text(mainText)
                .font(.system(size: 64, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)
            if showSubseconds {
                Text(String(format: ".%02d", hundredths))
                    .font(.system(size: 32, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("digital-clock")
        .accessibilityLabel(Text(mainText))
    }
}

#Preview("with subseconds") {
    DigitalClockView(date: previewDate(h: 10, m: 10, s: 30, ms: 425))
        .padding()
}

#Preview("without subseconds") {
    DigitalClockView(date: previewDate(h: 23, m: 59, s: 59), showSubseconds: false)
        .padding()
}

private func previewDate(h: Int, m: Int, s: Int, ms: Int = 0) -> Date {
    var components = DateComponents()
    components.year = 2026; components.month = 1; components.day = 1
    components.hour = h; components.minute = m; components.second = s
    components.nanosecond = ms * 1_000_000
    return Calendar.current.date(from: components) ?? Date()
}
