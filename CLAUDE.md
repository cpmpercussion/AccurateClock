# AccurateClock

A SwiftUI iOS clock app whose distinguishing feature is a clearly visible second indicator (sweeping or ticking), used to set other clocks — particularly mechanical watches that hack — precisely on the minute. iOS's stock Clock app deliberately doesn't display seconds; this app fills that gap.

## What's in the box

| File | Role |
|---|---|
| `AccurateClock/AccurateClockApp.swift` | `@main` entry; untouched template. |
| `AccurateClock/ClockTime.swift` | Pure value type. Decomposes a `Date` (in a given `Calendar`) into hour/minute/second-hand angles in degrees clockwise from 12 o'clock. Hour respects fractional minutes; minute respects fractional seconds; sub-second precision feeds the sweeping seconds hand. Tested in `ClockTimeTests`. |
| `AccurateClock/AnalogClockView.swift` | Dial, 60 tick marks, 1–12 numerals, three rotated hands. Defines `enum SecondsStyle { sweep, tick }`. |
| `AccurateClock/DigitalClockView.swift` | Large monospaced HH:MM:SS readout with a smaller `.ff` (Casio-style two-digit hundredths) suffix. Subseconds are hidden from VoiceOver; the accessibility label collapses to plain HH:MM:SS. |
| `AccurateClock/TimeSyncService.swift` | `@Observable @MainActor` SNTP client. Hand-rolled NTP v4 over `Network.framework`'s `NWConnection` UDP — no third-party dependency. Pure helpers (timestamp encode/decode, Cristian offset arithmetic) live in the `SNTP` enum and are unit-tested in `SNTPMathTests`. One sync on view appear, manual re-sync via tap. No persistence across launches. |
| `AccurateClock/WorldTime.swift` | Casio AE-1200 World Time city table — 48 cities + UTC, transcribed verbatim from Module 3198/3299. `WorldTime.cities`, `groupedByOffset`, `city(for:)`, `formatUTCOffset(minutes:)`. |
| `AccurateClock/TimezonePickerView.swift` | Sheet picker. "System" row at top, then 31 sectioned offset groups. Each row carries `accessibilityIdentifier(city.identifier)` so UI tests can target it deterministically. |
| `AccurateClock/ContentView.swift` | Wires everything together. `NavigationStack` with a toolbar globe button opening the timezone sheet; two `TimelineView`s (60 Hz for the faces, 1 Hz for the sync footer); a segmented sweep/tick `Picker`; the non-local indicator chip. |
| `tools/MakeIcon.swift` | Self-contained Swift script using `SwiftUI` + `ImageRenderer` to produce all three iOS 18 icon variants (light/dark/tinted) at 1024×1024. |

State lives in two `@AppStorage` keys — `secondsStyle` (sweep/tick) and `timezoneIdentifier` (empty string = system zone). `Calendar(timeZone:)` built from the timezone selection is the single mechanism for swapping the displayed zone; both `ClockTime` and `DigitalClockView` accept a `Calendar` parameter.

## Build & test

The project uses **synchronised file groups**, so dropping a Swift file into `AccurateClock/` (or the test directories) is enough — no `pbxproj` editing needed.

```sh
# Build for iOS simulator
xcodebuild build -project AccurateClock.xcodeproj -scheme AccurateClock \
  -destination "platform=iOS Simulator,name=iPhone 17"

# Unit tests only (fast)
xcodebuild test -project AccurateClock.xcodeproj -scheme AccurateClock \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -only-testing:AccurateClockTests

# Full suite (unit + UI tests)
xcodebuild test -project AccurateClock.xcodeproj -scheme AccurateClock \
  -destination "platform=iOS Simulator,name=iPhone 17"

# Regenerate icons
swift tools/MakeIcon.swift AccurateClock/Assets.xcassets/AppIcon.appiconset
```

The scheme also supports `platform=macOS` / `My Mac`, useful if the iOS simulator runtime isn't installed — the unit tests are pure-Foundation and run identically there. UI tests obviously need the iOS simulator.

## Things that look weird but are correct

- **SourceKit ghost diagnostics.** Adding a brand-new Swift file usually triggers stale "Cannot find type 'X' in scope" errors in the IDE indexer for any files that reference it. `xcodebuild build` is the source of truth; the diagnostics resolve themselves once Xcode re-indexes. Don't chase them.
- **Hand pivots from the dial centre even though `.offset` was applied.** See the comment in `AnalogClockView.hand(...)`: the `Capsule`'s layout frame stays centred in the parent ZStack; `.offset(y: -length/2)` only shifts the rendered pixels upward; `.rotationEffect` then rotates around the still-centred layout frame, so the hand visually pivots from the dial centre.
- **Two `TimelineView`s in `ContentView`.** Intentional. The faces want display-refresh cadence (`.animation`); the sync footer is `.periodic(by: 1)` so the "ago" text only re-renders when it could have changed.
- **`UTC−10` not `UTC-10`** in the offset label. Real Unicode minus (U+2212), produced by `WorldTime.formatUTCOffset(minutes:)`. UI tests assert with `"\u{2212}"`.
- **Picker section headers use Casio's *base* offset; the live indicator chip uses the IANA zone's *current* offset.** This is deliberate — keeps the AE-1200 ordering stable year-round, while the indicator is DST-aware so it tells the truth.
- **No simulator path for icon variants.** `simctl ui appearance dark` only flips system appearance; the iOS 18 home-screen icon mode (Light / Dark / Tinted) lives under Wallpaper → Customise and isn't reachable via `simctl`. `assetutil --info AccurateClock.app/Assets.car` confirms all three variants are bundled; visual verification needs a real device.

## Conventions

- Colours are semantic (`.primary`, `.secondary`, `.red`, system tints) — no explicit `.preferredColorScheme(...)`. The app already follows the system colour scheme.
- Tests use Swift Testing for unit tests (`import Testing`, `@Test`, `#expect`). UI tests still use XCTest because XCUITest hasn't moved.
- Commit messages: short subject, imperative mood, then a paragraph describing intent and any non-obvious choices. Trailer: `Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>`.

## Outstanding

The next significant task is **App Store submission prep**. A non-exhaustive list:

- Bundle ID is `au.charlesmartin.AccurateClock`. Needs `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` set on the target, plus an App Store Connect record.
- App Privacy declaration: the *only* network call is the SNTP UDP exchange to `time.apple.com`. No analytics, no tracking, no user data collected — answers to the questionnaire should reflect that.
- Marketing screenshots for required iPhone sizes (6.9", 6.7", 6.5", 5.5"). The existing UI test screenshot infrastructure could be extended.
- App description, keywords, support URL, marketing URL, category, age rating.
- Real-device verification of dark and tinted icon variants under iOS 18's home-screen mode toggle.
- Archive + upload via Xcode (or `xcodebuild archive` + Transporter).

Lower-priority follow-ups:

- Periodic NTP re-sync (currently one-shot on view appear).
- macOS icon sizes in `AppIcon.appiconset/Contents.json` are still empty; only matters if a Mac build is ever shipped.
