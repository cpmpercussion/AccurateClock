# App Store metadata

Field-by-field text to paste into App Store Connect → My Apps → AccurateClock.
Character limits are Apple's, not mine.

---

## App Name (≤30 chars)

**Primary choice:** `Accurate Clock` (14 chars)

If taken, fall back to one of:

- `Accurate Clock — Seconds` (24)
- `Watch Setter` (12)
- `Set My Watch` (12)
- `Hack — Accurate Clock` (21)

> Search the App Store from a logged-out browser before committing — names are
> globally unique. The bundle ID `au.charlesmartin.AccurateClock` is reserved
> regardless.

## Subtitle (≤30 chars)

`A clock that shows seconds.` (27)

Alternatives:

- `Set your watch precisely.` (25)
- `Sweep, tick, sync.` (18)
- `Precision time, second hand.` (28)

## Promotional Text (≤170 chars, editable without resubmission)

A clock that does the one thing iOS won't: shows the seconds, clearly. Sweep or tick. Synced to time.apple.com. Built for setting watches that hack.

(160 chars)

## Description (≤4000 chars)

```
Accurate Clock is a focused little app for setting other clocks precisely.

Why does this exist? iOS's stock Clock app deliberately doesn't show seconds,
which makes it useless for the one task you really need a clock for: setting
another clock right on the minute. Mechanical watches that "hack" — meaning
the seconds hand stops when you pull the crown — are particularly painful to
set without a visible second hand to wait on. Accurate Clock fills that gap.

WHAT YOU GET

• A clean analogue face with a clearly visible second hand. Toggle between
  smooth sweep and one-second tick.
• A digital readout showing HH:MM:SS plus a smaller two-digit hundredths
  counter, so you can see exactly when the minute starts.
• Time synchronised against Apple's public NTP server (time.apple.com) once
  per launch. The footer shows when it last synced and the round-trip
  uncertainty so you know how much to trust the displayed time.
• A world time picker covering 48 cities across 31 zones — the same set as
  Casio's classic AE-1200 — with sectioned UTC offsets and live DST awareness.
• System-aware light and dark modes. No accounts. No ads. No tracking. No
  data collected.

WHEN YOU WOULD USE IT

• Setting a mechanical watch precisely on the minute.
• Setting a quartz watch or wall clock and being annoyed that you can't see
  the seconds.
• Checking the time in another zone while you set a clock for a trip.
• Just enjoying watching a second hand sweep.

WHAT IT IS NOT

This isn't a stopwatch, an alarm, a world-clock complication, or an analytics
playground. There are no settings beyond sweep/tick and timezone. It is
deliberately small.
```

(approx 1500 chars — well under the limit)

## Keywords (≤100 chars total, comma-separated, no spaces after commas)

`clock,seconds,watch,sntp,ntp,sync,sweep,tick,analog,timezone,world time,casio,horology,utility`

(98 chars)

## Support URL

`https://charlesmartin.au/AccurateClock/`

(GitHub Pages serves this from `docs/index.html` on the public repo; that
landing page links to your contact email and the project page.)

## Marketing URL (optional)

`https://charlesmartin.au/AccurateClock/`

## Privacy Policy URL (required)

`https://charlesmartin.au/AccurateClock/privacy.html`

(See `docs/privacy.html`. The page declares "no data collected" — exactly
matching the App Privacy questionnaire answers in `privacy_questionnaire.md`.)

## Copyright

`2026 Charles Martin`

(App Store Connect prepends "©" automatically)

## Primary Category

`Utilities`

## Secondary Category (optional)

`Productivity` — defensible, not strictly required.

## Age Rating

All categories: **None / No Objectionable Content**.

App Store Connect will compute the rating from your answers; for an app like
this it should resolve to **4+**.

## Pricing

Free, no in-app purchases.

## Availability

All territories.

## App Review Information

- First name / Last name: `Charles` / `Martin`
- Phone: as registered with Apple Developer
- Email: `cpm@charlesmartin.au`
- Demo account: **None required** (no login)
- Notes: see `app_review_notes.md`.

## Build version

- `MARKETING_VERSION = 1.0`
- `CURRENT_PROJECT_VERSION = 1` (build number; Apple requires it to monotonically increase across uploads, so future TestFlight uploads will need to bump it)

## What's New in This Version

For the first 1.0 release, leave blank or write:

```
Initial release.
```
