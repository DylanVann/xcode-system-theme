#!/bin/bash
# Capture screenshots/zed-light.png and screenshots/zed-dark.png.
#
# Opens the repo and tools/Probe.swift in a new Zed window, closes any other editors the
# workspace restored, hides the agent panel if it sits in the dock, turns inline blame
# off for the run, sizes the window to 1440x900 at the top left, puts the cursor at
# line 1 column 1, and captures the window in both appearances. Captures are converted
# from the display profile to sRGB. Needs the Swift extension in Zed, and the terminal
# granted Screen Recording and Accessibility access.
set -e
cd "$(dirname "$0")/.."
S=$PWD
SE='tell application "System Events"'
CLI=/Applications/Zed.app/Contents/MacOS/cli
[ /tmp/winlist -nt tools/winlist.swift ] || swiftc -O tools/winlist.swift -o /tmp/winlist 2>/dev/null
[ /tmp/warpmouse -nt tools/warpmouse.swift ] || swiftc -O tools/warpmouse.swift -o /tmp/warpmouse 2>/dev/null
ZED_SETTINGS=$HOME/.config/zed/settings.json
if [ -f "$ZED_SETTINGS" ] && ! grep -q '"inline_blame"' "$ZED_SETTINGS"; then
  cp "$ZED_SETTINGS" /tmp/zedshot-settings.json
  python3 - "$ZED_SETTINGS" <<'PY'
import sys; p=sys.argv[1]; s=open(p).read(); i=s.index("{")
open(p,"w").write(s[:i+1]+'\n  "git": { "inline_blame": { "enabled": false } },'+s[i+1:])
PY
  trap 'cp /tmp/zedshot-settings.json "$ZED_SETTINGS"' EXIT
fi
# Close any existing windows on this repo first, so exactly one window is targeted.
osascript -e "$SE to tell process \"zed\" to click (first button whose subrole is \"AXCloseButton\") of (every window whose name contains \"xcode-system-theme\")" >/dev/null 2>&1 || true; sleep 1
$CLI --new "$S" >/dev/null 2>&1; sleep 6
win() { /tmp/winlist | awk -F'|' '$2 ~ /Zed/ && $3 ~ /xcode-system-theme/ && $5+0 == 0 {print; exit}'; }
osascript -e "$SE to set frontmost of process \"zed\" to true"; sleep 0.5
osascript -e "$SE to tell process \"zed\" to perform action \"AXRaise\" of (first window whose name contains \"xcode-system-theme\")" >/dev/null 2>&1 || true
# Close every restored editor. The title only names file items, so items such as a
# theme preview leave it bare; check the tab bar itself for anything drawn on it.
WID=$(win | cut -d'|' -f1 | tr -d ' ')
tabs_open() {
  screencapture -x -o -l"$WID" /tmp/zedshot-probe.png
  # Fraction of dark pixels across the tab bar, excluding the nav arrows and the right-hand buttons.
  local dark; dark=$(magick /tmp/zedshot-probe.png -crop 1600x40+500+65 +repage -colorspace gray -threshold 60% -format "%[fx:1-mean]" info: 2>/dev/null)
  python3 -c "import sys; sys.exit(0 if float('$dark') > 0.002 else 1)"
}
for i in $(seq 1 15); do
  [ -n "$(win)" ] || break
  tabs_open || break
  osascript -e "$SE to tell process \"zed\" to tell menu bar 1 to tell menu bar item \"File\" to tell menu 1 to click (first menu item whose name is \"Close Editor\")" >/dev/null; sleep 1
done
$CLI "$S/tools/Probe.swift:1:1" >/dev/null 2>&1; sleep 3
osascript -e "$SE to tell process \"zed\" to set position of (first window whose name contains \"xcode-system-theme\") to {0, 40}" -e "$SE to tell process \"zed\" to set size of (first window whose name contains \"xcode-system-theme\") to {1440, 900}"; sleep 1
WID=$(win | cut -d'|' -f1 | tr -d ' ')
# If the agent panel shares the left dock, the editor starts far to the right; toggle it off.
editor_x() { screencapture -x -o -l"$WID" /tmp/zedshot-probe.png; magick /tmp/zedshot-probe.png -crop 1800x1+0+800 +repage -depth 8 rgb:- 2>/dev/null | python3 -c "
import sys; d=sys.stdin.buffer.read(); px=[d[i:i+3] for i in range(0,len(d),3)]
run=0
for i,p in enumerate(px):
    run = run+1 if p in (b'\xff\xff\xff', b'\x26\x26\x26') else 0
    if run>200: print(i-200); break
else: print(len(px))"; }
if [ "$(editor_x)" -gt 600 ]; then
  osascript -e "$SE to tell process \"zed\" to tell menu bar 1 to tell menu bar item \"View\" to tell menu 1 to click menu item \"Agent Panel\"" >/dev/null; sleep 1.5
fi
/tmp/warpmouse 1450 500; sleep 0.5
mkdir -p screenshots
capture() {
  screencapture -x -o -l"$WID" /tmp/zed-$1-raw.png
  magick /tmp/zed-$1-raw.png -profile "/System/Library/ColorSync/Profiles/sRGB Profile.icc" -strip -define png:compression-level=9 screenshots/zed-$1.png
}
was_dark=$(osascript -e "$SE to tell appearance preferences to get dark mode")
osascript -e "$SE to tell appearance preferences to set dark mode to false"; sleep 3; capture light
osascript -e "$SE to tell appearance preferences to set dark mode to true"; sleep 3; capture dark
osascript -e "$SE to tell appearance preferences to set dark mode to $was_dark"
ls -la screenshots/zed-*.png
