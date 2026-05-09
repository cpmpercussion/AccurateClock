#!/usr/bin/env bash
# Run the MarketingScreenshots UI test on each required device, in light AND
# dark appearance, then extract the screenshots into:
#
#   submission/screenshots/<device>/<appearance>/{01_sweep,02_tick,03_picker,04_tokyo}.png
#
# iPhone screenshots are captured on iPhone 17 Pro Max (1320×2868) and resized
# to the 6.5" App Store slot's 1284×2778 with ImageMagick. iPad keeps the native
# 13" 2064×2752 size (Apple's iPad 13" slot).
#
# The simulator status bar is forced to Apple's marketing-standard "9:41" with
# full signal/Wi-Fi and a charged battery so the screenshots look intentional.
#
# Usage: ./tools/screenshots.sh

set -euo pipefail

cd "$(dirname "$0")/.."

# device-name : output-folder : magick-resize-target (empty = keep native size)
DEVICES=(
  "iPhone 17 Pro Max:iPhone-6.5:1284x2778"
  "iPad Pro 13-inch (M5):iPad-Pro-13:"
)
APPEARANCES=(light dark)

# Resolve the first matching simulator UDID — `simctl ui` and `status_bar`
# reject ambiguous names when multiple devices share one.
resolve_udid() {
  local name="$1"
  xcrun simctl list devices available --json | python3 -c "
import json, sys
target = '''$name'''
data = json.load(sys.stdin)
for runtime, devs in data['devices'].items():
    for d in devs:
        if d['name'] == target:
            print(d['udid']); sys.exit(0)
sys.exit(1)
"
}

mkdir -p build/screenshots submission/screenshots

for entry in "${DEVICES[@]}"; do
  IFS=':' read -r sim_name out_name resize_target <<<"$entry"
  udid=$(resolve_udid "$sim_name")

  # Wipe per-device output so old layouts (e.g. iPhone-17-Pro-Max) don't linger.
  rm -rf "submission/screenshots/${out_name}"

  for appearance in "${APPEARANCES[@]}"; do
    tag="${out_name}-${appearance}"
    result_bundle="build/screenshots/${tag}.xcresult"
    raw_dir="build/screenshots/extracted/${tag}"
    final_dir="submission/screenshots/${out_name}/${appearance}"

    echo "==> ${sim_name} / ${appearance}"
    rm -rf "$result_bundle" "$raw_dir"
    mkdir -p "$final_dir"

    xcrun simctl boot "$udid" 2>/dev/null || true
    xcrun simctl bootstatus "$udid" -b >/dev/null
    xcrun simctl ui "$udid" appearance "$appearance"
    xcrun simctl status_bar "$udid" override \
      --time "9:41" \
      --dataNetwork wifi \
      --wifiMode active --wifiBars 3 \
      --cellularMode active --cellularBars 4 \
      --batteryState charged --batteryLevel 100

    xcodebuild test \
      -project AccurateClock.xcodeproj \
      -scheme AccurateClock \
      -destination "platform=iOS Simulator,id=${udid}" \
      -only-testing:AccurateClockUITests/MarketingScreenshots \
      -resultBundlePath "$result_bundle" >/dev/null

    xcrun simctl status_bar "$udid" clear

    xcrun xcresulttool export attachments \
      --path "$result_bundle" \
      --output-path "$raw_dir" >/dev/null

    python3 - "$raw_dir" "$final_dir" <<'PY'
import json, os, shutil, sys

raw_dir, final_dir = sys.argv[1], sys.argv[2]
manifest = json.load(open(os.path.join(raw_dir, "manifest.json")))
for test in manifest:
    for att in test["attachments"]:
        # suggestedHumanReadableName is "01_sweep_0_<uuid>.png" — keep "01_sweep".
        prefix = "_".join(att["suggestedHumanReadableName"].split("_")[:2])
        target = os.path.join(final_dir, prefix + ".png")
        shutil.copy(os.path.join(raw_dir, att["exportedFileName"]), target)
        print(f"  {target}")
PY

    if [[ -n "$resize_target" ]]; then
      for f in "$final_dir"/*.png; do
        magick "$f" -resize "${resize_target}!" "$f"
      done
      echo "  resized → ${resize_target}"
    fi
  done

  xcrun simctl ui "$udid" appearance light 2>/dev/null || true
done

echo "Done. Screenshots in submission/screenshots/"
