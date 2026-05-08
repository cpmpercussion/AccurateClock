import SwiftUI

struct ContentView: View {
    @AppStorage("secondsStyle") private var secondsStyle: SecondsStyle = .sweep
    @State private var timeSync = TimeSyncService()

    var body: some View {
        VStack(spacing: 24) {
            TimelineView(.animation) { context in
                let now = context.date.addingTimeInterval(timeSync.offset)
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

            TimelineView(.periodic(from: .now, by: 1)) { _ in
                SyncStatusRow(timeSync: timeSync)
            }
        }
        .padding(.vertical)
        .task {
            await timeSync.sync()
        }
    }
}

private struct SyncStatusRow: View {
    let timeSync: TimeSyncService

    var body: some View {
        Button {
            Task { await timeSync.sync() }
        } label: {
            HStack(spacing: 8) {
                if timeSync.isSyncing {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                Text(statusText)
                    .font(.callout)
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(timeSync.isSyncing)
        .accessibilityIdentifier("sync-status")
    }

    private var statusText: String {
        if timeSync.isSyncing {
            return "Syncing with time.apple.com…"
        }
        if let synced = timeSync.lastSyncedAt {
            let agoText = formatAgo(Date().timeIntervalSince(synced))
            if let delay = timeSync.roundTripDelay {
                let halfMs = max(0, Int((delay / 2) * 1000))
                return "Synced \(agoText) • ±\(halfMs)ms — tap to resync"
            }
            return "Synced \(agoText) — tap to resync"
        }
        if let error = timeSync.lastError {
            return "Sync failed (\(error)) — tap to retry"
        }
        return "Using device time — tap to sync"
    }

    private func formatAgo(_ interval: TimeInterval) -> String {
        if interval < 1 { return "just now" }
        if interval < 60 { return "\(Int(interval))s ago" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        return "\(Int(interval / 3600))h ago"
    }
}

#Preview {
    ContentView()
}
