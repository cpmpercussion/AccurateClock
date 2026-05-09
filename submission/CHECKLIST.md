# App Store submission checklist

Everything you need to submit Accurate Clock 1.0 to the App Store. Steps you
do in App Store Connect (browser) versus Xcode/CLI (this machine) are
separated.

---

## Pre-flight (already done by Claude on 2026-05-09)

- [x] Project builds clean in Release for iPhone + iPad simulators.
- [x] Unit tests pass.
- [x] Bundle ID set: `au.charlesmartin.AccurateClock`.
- [x] `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 1`.
- [x] Info.plist keys baked in via build settings:
    - `LSApplicationCategoryType = public.app-category.utilities`
    - `ITSAppUsesNonExemptEncryption = NO`
    - `NSHumanReadableCopyright = Copyright © 2026 Charles Martin. All rights reserved.`
    - `CFBundleDisplayName = Accurate Clock`
- [x] Xcode scheme shared in `xcshareddata/xcschemes/AccurateClock.xcscheme`.
- [x] Marketing screenshots generated for the iPhone 6.5″ slot (1284×2778,
      resized from a 17 Pro Max capture via ImageMagick) and the iPad 13″
      slot (2064×2752 native), in both light and dark appearance, at
      `submission/screenshots/<device>/<appearance>/`.
- [x] Local archive build succeeded — `build/AccurateClock.xcarchive`.
- [x] GitHub Pages enabled on the repo, sourcing from `docs/`. Privacy
      policy at `docs/privacy.html`.
- [x] App Review notes drafted: `submission/app_review_notes.md`.
- [x] App Privacy answers drafted: `submission/privacy_questionnaire.md`.

---

## You-still-need-to-do, in order

### 1. Commit and push the `docs/` folder so GitHub Pages serves the privacy URL

```sh
git add docs/ tools/screenshots.sh AccurateClock/ AccurateClock.xcodeproj/ AccurateClockUITests/MarketingScreenshots.swift submission/
git commit -m "Prepare for App Store submission"
git push
```

Wait ~1 minute for Pages to build, then verify:

```sh
curl -sI https://charlesmartin.au/AccurateClock/privacy.html | head -3
```

You should see `HTTP/2 200`. (It may take a couple of minutes for the cert
to provision; if `https` 404s, try `http://`.)

### 2. Create the App Store Connect record

Open <https://appstoreconnect.apple.com> → My Apps → **+** → New App.

| Field | Value |
|---|---|
| Platforms | iOS |
| Name | `Accurate Clock` (see metadata.md for fallbacks if taken) |
| Primary Language | English (Australia) |
| Bundle ID | `au.charlesmartin.AccurateClock — AccurateClock` (registered automatically when you submit your first archive; if it isn't yet, register it under Certificates, Identifiers & Profiles first) |
| SKU | `accurate-clock-1` (any unique string) |
| User Access | Full Access |

### 3. Fill in App Information

Side panel → **App Information**.

- **Subtitle**: from `submission/metadata.md`.
- **Privacy Policy URL**: `https://charlesmartin.au/AccurateClock/privacy.html`
- **Category**: Primary `Utilities`, Secondary blank (or `Productivity`).
- **Content Rights**: tick "Does Not Use Third-Party Content".

### 4. Fill in the App Privacy questionnaire

Side panel → **App Privacy** → Get Started.

Answer everything per `submission/privacy_questionnaire.md`. The whole form
collapses to "Data Not Collected".

### 5. Fill in the 1.0 version page

Side panel → **iOS App** → **1.0 Prepare for Submission**.

Paste from `submission/metadata.md`:

- Promotional Text
- Description
- Keywords
- Support URL: `https://charlesmartin.au/AccurateClock/`
- Marketing URL: `https://charlesmartin.au/AccurateClock/`
- Copyright: `2026 Charles Martin`
- Version: `1.0`
- What's New: leave blank for first version.
- App Review Notes: paste from `submission/app_review_notes.md`.

Upload screenshots — App Store Connect now offers light + dark appearance
slots per device. Drag the four PNGs in numeric order
(`01_sweep`, `02_tick`, `03_picker`, `04_tokyo`):

- **iPhone 6.5"** (1284×2778, required):
  - Light: `submission/screenshots/iPhone-6.5/light/`
  - Dark:  `submission/screenshots/iPhone-6.5/dark/`
- **iPad 13"** (2064×2752, required for iPad apps):
  - Light: `submission/screenshots/iPad-Pro-13/light/`
  - Dark:  `submission/screenshots/iPad-Pro-13/dark/`

If App Store Connect only shows a single screenshot slot per device
(some accounts haven't been migrated to the light/dark split yet), use the
`light/` set — it's the safer default for users who haven't customised.

### 6. Pricing

Side panel → **Pricing and Availability** → Free, all territories.

### 7. Age Rating

In the version page, click **Edit** next to Age Rating. Answer "None" for
every category. The result should be **4+**.

### 8. Encryption export compliance

Already declared in Info.plist (`ITSAppUsesNonExemptEncryption = NO`), so the
upload will skip this prompt automatically.

### 9. Upload the build

You have three options. Pick one.

#### 9a. Xcode Organizer (easiest, GUI)

```sh
open build/AccurateClock.xcarchive
```

…or in Xcode: **Product → Archive**, then in the Organizer that opens:
**Distribute App → App Store Connect → Upload**, accept defaults, sign in,
upload. Apple will email you when the build finishes processing (5–30 min).

#### 9b. CLI: archive + export + upload via `altool`

```sh
# 1. (Re)archive — already done, but if you change anything:
xcodebuild archive \
  -project AccurateClock.xcodeproj \
  -scheme AccurateClock \
  -destination "generic/platform=iOS" \
  -archivePath build/AccurateClock.xcarchive \
  -allowProvisioningUpdates

# 2. Export, signed for App Store distribution:
xcodebuild -exportArchive \
  -archivePath build/AccurateClock.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist submission/ExportOptions.plist \
  -allowProvisioningUpdates

# 3. Upload. Use either an app-specific password OR an App Store Connect API key.

# Option A — app-specific password (generate one at appleid.apple.com):
xcrun altool --upload-app \
  --type ios \
  --file build/export/AccurateClock.ipa \
  --username cpm@charlesmartin.au \
  --password @keychain:AC_PASSWORD   # store with: security add-generic-password -s AC_PASSWORD -a cpm@charlesmartin.au -w <app-specific-password>

# Option B — App Store Connect API key (preferred for repeated use):
# Generate in App Store Connect → Users and Access → Keys.
# Place the .p8 in ~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8
xcrun altool --upload-app \
  --type ios \
  --file build/export/AccurateClock.ipa \
  --apiKey <KEYID> \
  --apiIssuer <ISSUER-UUID>
```

#### 9c. Transporter.app

Drop `build/export/AccurateClock.ipa` into Transporter (Mac App Store), sign
in, click Deliver. Same backend as `altool`, GUI for it.

### 10. Submit for review

Once the build finishes processing in App Store Connect (you'll get an email):

1. On the version page, in the **Build** section, click **+** and pick the
   build that just finished processing.
2. Click **Save** at the top.
3. Click **Add for Review** → **Submit to App Review**.

Initial review usually takes 24–48 hours.

---

## Reference: regenerating screenshots

If you change the UI and need fresh screenshots:

```sh
./tools/screenshots.sh
```

Outputs go to `submission/screenshots/<device>/`.

## Reference: bumping the build number

App Store Connect requires `CFBundleVersion` (a.k.a. `CURRENT_PROJECT_VERSION`)
to monotonically increase across uploads. For 1.0.1 or rebuilds:

```sh
agvtool next-version -all     # bumps build number
# or set explicitly: agvtool new-version -all 2
```

(`MARKETING_VERSION` only changes when the user-visible version string changes.)

## Outstanding non-blockers

These can ship later or be skipped:

- visionOS submission (separate path; the project already builds for xrOS).
- macOS Catalyst (`SUPPORTED_PLATFORMS` includes macosx but no Mac icon
  variants; defer).
- Periodic NTP re-sync (currently one-shot on view appear).
- Real-device verification of the dark/tinted icon variants (the asset
  catalogue contains all three, but iOS 18's home-screen mode toggle isn't
  reachable from the simulator).
