# Notes for the App Review team

Paste this verbatim into the **Review Notes** field on the App Information /
Version page in App Store Connect.

---

```
This app does one thing: it shows the current time with a clearly visible
seconds indicator (sweep or tick), so the user can set another clock — for
example a mechanical watch — precisely on the minute.

There are no accounts, no in-app purchases, no advertising, and no analytics.
No demo account is required.

How to test
1. Launch the app. The analogue and digital clocks should display immediately.
2. The footer reads "Synced just now" once the SNTP request to time.apple.com
   completes (UDP/123). Tap it to resync.
3. Tap the globe icon at the top right to open the time zone picker. Pick any
   city. The non-local indicator chip below the digital readout shows the
   selected city and its current UTC offset.
4. Toggle "Sweep" / "Tick" to change how the seconds hand moves.

Networking
The app makes one and only one network call: a single 48-byte SNTP v4 packet
to Apple's public NTP server time.apple.com (UDP, port 123). The reply is
used locally to estimate clock offset. Source for the SNTP code is in
AccurateClock/TimeSyncService.swift. There is no other network use; no
analytics SDK, no third-party services.

Permissions
None. The app does not request location, camera, microphone, contacts,
notifications, or any other permission.

Encryption
The app uses no non-exempt encryption. The Info.plist key
ITSAppUsesNonExemptEncryption is set to NO. SNTP is plaintext UDP and does
not use cryptographic algorithms.

Accessibility
The digital readout has a custom accessibility label that collapses the
fractional-seconds suffix so VoiceOver reads e.g. "10:08:42" rather than
"10:08:42.50". The world-time picker rows expose the IANA identifier as the
accessibility identifier (e.g. "Asia/Tokyo") so they are uniquely targetable.

Source
Open-source on GitHub: https://github.com/cpmpercussion/AccurateClock

Contact
cpm@charlesmartin.au
```

---

## Optional: a screenshot of the SNTP packet for the reviewer

If a reviewer pushes back on the network usage, you can point them at:

- `AccurateClock/TimeSyncService.swift` — the entire SNTP implementation
  (≈180 lines, no dependencies).
- `AccurateClockTests/AccurateClockTests.swift` → `SNTPMathTests` — the
  unit tests covering the offset math.

That's the entire surface area.
