#!/usr/bin/env bash
# Run the MarketingScreenshots UI test on each required device, then extract the
# screenshot attachments into submission/screenshots/<device>/ with their
# friendly names (01_sweep.png, 02_tick.png, 03_picker.png, 04_tokyo.png).
#
# Forces the simulator status bar to Apple's marketing-standard "9:41" with full
# signal/Wi-Fi/battery so the screenshots look intentional.
#
# Usage: ./tools/screenshots.sh

set -euo pipefail

cd "$(dirname "$0")/.."

DEVICES=(
  "iPhone 17 Pro Max:iPhone-17-Pro-Max"
  "iPad Pro 13-inch (M5):iPad-Pro-13"
)

mkdir -p build/screenshots submission/screenshots

for entry in "${DEVICES[@]}"; do
  sim_name="${entry%%:*}"
  out_name="${entry##*:}"
  result_bundle="build/screenshots/${out_name}.xcresult"
  raw_dir="build/screenshots/extracted/${out_name}"
  final_dir="submission/screenshots/${out_name}"

  echo "==> Capturing on ${sim_name}"
  rm -rf "$result_bundle" "$raw_dir" "$final_dir"
  mkdir -p "$final_dir"

  # Boot the simulator (no-op if already booted) and override the status bar.
  xcrun simctl boot "$sim_name" 2>/dev/null || true
  xcrun simctl bootstatus "$sim_name" -b >/dev/null
  xcrun simctl status_bar "$sim_name" override \
    --time "9:41" \
    --dataNetwork wifi \
    --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 \
    --batteryState charged --batteryLevel 100

  xcodebuild test \
    -project AccurateClock.xcodeproj \
    -scheme AccurateClock \
    -destination "platform=iOS Simulator,name=${sim_name}" \
    -only-testing:AccurateClockUITests/MarketingScreenshots \
    -resultBundlePath "$result_bundle" >/dev/null

  xcrun simctl status_bar "$sim_name" clear

  xcrun xcresulttool export attachments \
    --path "$result_bundle" \
    --output-path "$raw_dir" >/dev/null

  python3 - "$raw_dir" "$final_dir" <<'PY'
import json, os, shutil, sys

raw_dir, final_dir = sys.argv[1], sys.argv[2]
manifest = json.load(open(os.path.join(raw_dir, "manifest.json")))
for test in manifest:
    for att in test["attachments"]:
        # suggestedHumanReadableName looks like "01_sweep_0_<uuid>.png" — keep the
        # leading "NN_label" only.
        prefix = "_".join(att["suggestedHumanReadableName"].split("_")[:2])
        target = os.path.join(final_dir, prefix + ".png")
        shutil.copy(os.path.join(raw_dir, att["exportedFileName"]), target)
        print(f"  {target}")
PY
done

echo "Done. Screenshots in submission/screenshots/"
