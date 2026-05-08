import SwiftUI

struct ContentView: View {
    @AppStorage("secondsStyle") private var secondsStyle: SecondsStyle = .sweep

    var body: some View {
        VStack(spacing: 32) {
            TimelineView(.animation) { context in
                let now = context.date
                VStack(spacing: 32) {
                    AnalogClockView(
                        time: ClockTime(date: now),
                        secondsStyle: secondsStyle
                    )
                    .padding(.horizontal, 24)

                    DigitalClockView(date: now)
                }
            }

            Picker("Seconds hand", selection: $secondsStyle) {
                ForEach(SecondsStyle.allCases) { style in
                    Text(style.label).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

#Preview {
    ContentView()
}
