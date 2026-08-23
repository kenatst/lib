#!/usr/bin/env bash
# Captures EMBER screens on the booted simulator via debug launch arguments.
# Usage: tools/capture_screens.sh [udid]
set -euo pipefail

UDID="${1:-08C4DFC2-94A0-4132-B257-99C41D7C05DD}"
BUNDLE="com.kenatst.ember"
OUT="$(dirname "$0")/../shots"
mkdir -p "$OUT"
APP=$(find "$HOME/Library/Developer/Xcode/DerivedData/Ember-bdwzxdoufcygekgkeilrwlnulmrt/Build/Products/Debug-iphonesimulator" -name "Ember.app" -maxdepth 1 | head -1)

shot() { # name, then launch args...
  local name="$1"; shift
  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
  sleep 0.4
  xcrun simctl install "$UDID" "$APP"
  xcrun simctl launch "$UDID" "$BUNDLE" "$@" >/dev/null
  sleep 2.6   # let entrance animations settle
  xcrun simctl io "$UDID" screenshot "$OUT/$name.png" >/dev/null
  echo "captured $name"
}

shot 01-welcome
shot 02-selection -ember-route selection
shot 03-onboarding-my -ember-intention myDesire -ember-route onboarding
shot 04-profile-my -ember-intention myDesire -ember-completed 3 -ember-route profile
shot 05-home-day1 -ember-intention myDesire -ember-route home
shot 06-home-progress -ember-intention theirDesire -ember-completed 9 -ember-route home
shot 07-day-discover -ember-intention myDesire -ember-completed 4 -ember-day 5 -ember-route day
shot 08-evening-return -ember-intention myDesire -ember-completed 5 -ember-day 5 -ember-route return
shot 09-progress -ember-intention myDesire -ember-completed 9 -ember-route progress
shot 10-couple-setup -ember-intention ourDesire -ember-route coupleSetup
shot 11-couple-space -ember-intention ourDesire -ember-role one -ember-handoff "I kept thinking about Thursday." -ember-route coupleSpace
shot 12-settings -ember-intention myDesire -ember-completed 2 -ember-route settings
shot 13-welcome-fr -AppleLanguages "(fr)" -AppleLocale fr_FR
shot 14-selection-fr -AppleLanguages "(fr)" -AppleLocale fr_FR -ember-route selection
shot 15-day-fr -AppleLanguages "(fr)" -AppleLocale fr_FR -ember-intention ourDesire -ember-completed 8 -ember-day 9 -ember-route day
shot 16-profile-fr -AppleLanguages "(fr)" -AppleLocale fr_FR -ember-intention theirDesire -ember-route profile

echo "all captures in $OUT"
