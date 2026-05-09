# App Privacy questionnaire — answers

App Store Connect → AccurateClock → App Privacy. Click each section and answer
exactly as below. The whole questionnaire collapses to "Data Not Collected"
because the app collects nothing.

---

## "Do you or your third-party partners collect data from this app?"

> **No, we do not collect data from this app.**

Confirm. App Store Connect will then ask you to confirm two specific carve-outs:

> "I confirm that I do not collect any data from any of the data types listed
> in the App Privacy questionnaire from this app, including data collected
> from third-party SDKs and from cookies and similar tracking technologies."

→ **Confirm.**

> "I confirm that I do not collect any data from this app, even data that is
> linked to user identity or used for tracking purposes."

→ **Confirm.**

That's the entire form.

---

## Why this is the correct answer

Apple's "data collection" definition (from the App Privacy questionnaire):

> Data is collected when it is transmitted off the device in a way that
> allows you or your third-party partners to access it for a period longer
> than what is necessary to service the transmitted request in real time.

The app's only network call is an SNTP request to Apple's public NTP server
`time.apple.com` on UDP port 123. The request contains:

- An NTP version 4 client packet header (one byte: `0x23`).
- A 64-bit transmit timestamp (the device's current clock).
- 40 bytes of zeros.

It contains no device identifier, no user identifier, no location data, no
content of any kind beyond the timestamp the protocol requires. Apple
operates the server. We never see the response — it's consumed locally to
compute a clock offset. Nothing is logged or persisted off-device.

The two `@AppStorage` preferences (`secondsStyle`, `timezoneIdentifier`) live
in `UserDefaults` on the device only.

If a reviewer asks: this app contains no analytics frameworks, no crash
reporters, no advertising SDKs, and no third-party services of any kind. The
binary is statically verifiable — see `AccurateClock/TimeSyncService.swift`.

---

## Data Types — for the record

| Data Type | Collected? |
|---|---|
| Contact Info (name, email, phone, address, other contact info) | No |
| Health & Fitness | No |
| Financial Info | No |
| Location (precise / coarse) | No |
| Sensitive Info | No |
| Contacts | No |
| User Content (photos, audio, video, gameplay, customer support, other) | No |
| Browsing / Search History | No |
| Identifiers (User ID, Device ID) | No |
| Purchases | No |
| Usage Data (product interaction, advertising data, other) | No |
| Diagnostics (crash data, performance, other) | No |
| Other Data | No |

## Tracking

> "Does this app track users?"

→ **No.**

The app does not call `ATTrackingManager.requestTrackingAuthorization` because
it has nothing to track. It does not access the IDFA. It has no SDKs that do
either.
