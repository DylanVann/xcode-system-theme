#!/bin/bash
# Capture screenshots/zed-light.png and screenshots/zed-dark.png.
#
# Opens the repo and tools/Probe.swift in Zed, sizes the window to 1440x900 at
# the top left, puts the cursor at line 1 column 1 (Vim mode: Escape, gg, 0),
# and captures the window in both appearances. Captures are converted from the
# display profile to sRGB. Needs the Swift extension installed in Zed, and the
# terminal granted Screen Recording and Accessibility access.
set -e
cd "$(dirname "$0")/.."
swiftc -O tools/winid.swift -o /tmp/winid 2>/dev/null
open -a Zed "$PWD"; sleep 8
open -a Zed "$PWD/tools/Probe.swift"; sleep 3
osascript -e 'tell application "System Events" to set frontmost of process "Zed" to true'; sleep 1
osascript -e 'tell application "System Events" to tell process "Zed" to set position of window 1 to {0, 40}' \
         -e 'tell application "System Events" to tell process "Zed" to set size of window 1 to {1440, 900}'
sleep 2
osascript -e 'tell application "System Events" to key code 53'; sleep 0.3
osascript -e 'tell application "System Events" to keystroke "gg0"'; sleep 1.5
WID=$(/tmp/winid Zed | head -1 | cut -d' ' -f1)
mkdir -p screenshots
capture() {
  screencapture -x -o -l"$WID" /tmp/zed-$1-raw.png
  magick /tmp/zed-$1-raw.png -profile "/System/Library/ColorSync/Profiles/sRGB Profile.icc" -strip -define png:compression-level=9 screenshots/zed-$1.png
}
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false'; sleep 4
capture light
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'; sleep 5
capture dark
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false'
ls -la screenshots
