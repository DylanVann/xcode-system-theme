#!/bin/bash
# Hero screenshots: Xcode, Zed, Finder, and Ghostty in a 2x2 grid over the wallpaper,
# light and dark, written to screenshots/hero-{light,dark}@2x.png at the display's native
# resolution and screenshots/hero-{light,dark}.png at half size for the README.
#
#   tools/hero/hero.sh setup       open and size the four windows on tools/hero/Landmarks
#   tools/hero/hero.sh capture     composite the shots from whatever is open (a few seconds)
#   tools/hero/hero.sh ghostty     reopen only the Ghostty demo window
#   tools/hero/hero.sh wallpaper   recapture tools/hero/wallpaper-{light,dark}.jpg; rarely needed
#   tools/hero/hero.sh             setup then capture
#
# Capture never reads the screen as a whole. Each app window is captured by id with its
# shadow and placed on the stored 2x wallpaper at a grid position, offset by the
# shadow margin measured from the capture's alpha. Where the windows sit on screen,
# what else is open, and the stacking order do not matter. Needs Screen Recording and
# Accessibility access, the theme installed in Zed and Ghostty, the Swift extension with
# Xcode-like highlights, SF Mono, the Xcode System bat theme, and wallpaper tinting off.
# Setup sends one command to a new Ghostty window, so do not type while it runs.
set -e
S=$(cd "$(dirname "$0")/../.." && pwd)
PKG=$S/tools/hero/Landmarks
FILE=$PKG/Sources/Landmarks/Landmark.swift
OUT=$S/screenshots
ASSETS=$S/tools/hero
SE='tell application "System Events"'
# Window size in points, and the grid in points on the canvas, which is the screen
# below the 39 pt menu bar. Screen bounds for setup are the canvas bounds plus 39.
W=992; H=609; X0=24; X1=1040; Y0=24; Y1=657
WL=/tmp/winlist
[ "$WL" -nt "$S/tools/winlist.swift" ] || swiftc -O "$S/tools/winlist.swift" -o "$WL" 2>/dev/null
WM=/tmp/warpmouse
[ "$WM" -nt "$S/tools/warpmouse.swift" ] || swiftc -O "$S/tools/warpmouse.swift" -o "$WM" 2>/dev/null
win() { $WL | awk -F'|' -v a="$1" -v p="$2" '$2 ~ a && $3 ~ p && $5+0 == 0 {print; exit}'; }
is_dark() { [ "$(osascript -e "$SE to tell appearance preferences to get dark mode")" = true ]; }

setup() {
  echo "[finder] hiding dotfiles for the shot"
  defaults write com.apple.finder AppleShowAllFiles -bool false; killall Finder; sleep 3
  echo "[xcode]"
  open -a Xcode "$PKG/Package.swift"; sleep 10; open -g -a Xcode "$FILE"; sleep 4
  osascript -e 'tell application "Xcode" to close (every window whose name is "Landmark.swift") saving no' >/dev/null 2>&1 || true
  osascript -e "tell application \"Xcode\" to set bounds of (first window whose name contains \"Landmarks\") to {$X0, $((Y0+39)), $((X0+W)), $((Y0+39+H))}"
  osascript -e "$SE to tell process \"Xcode\" to tell menu bar 1 to tell menu bar item \"View\" to tell menu 1 to tell menu item \"Inspectors\" to tell menu 1 to click menu item \"Hide Inspector\"" >/dev/null 2>&1 || true
  for try in 1 2 3; do
    mark=$(osascript -e "$SE to tell process \"Xcode\" to tell menu bar 1 to tell menu bar item \"Editor\" to tell menu 1 to get value of attribute \"AXMenuItemMarkChar\" of menu item \"Canvas\"" 2>/dev/null || true)
    case "$mark" in "missing value"|"") break;; esac
    osascript -e "$SE to tell process \"Xcode\" to tell menu bar 1 to tell menu bar item \"Editor\" to tell menu 1 to click menu item \"Canvas\"" >/dev/null; sleep 2
  done
  echo "[zed]"
  open -a Zed "$PKG"; sleep 8; open -g -a Zed "$FILE"; sleep 4
  for i in 1 2; do case "$(win Zed Landmarks)" in *Landmark.swift*) break;; esac; osascript -e "$SE to tell process \"zed\" to tell menu bar 1 to tell menu bar item \"File\" to tell menu 1 to click (first menu item whose name is \"Close Editor\")" >/dev/null 2>&1 || true; sleep 2; done
  /Applications/Zed.app/Contents/MacOS/cli "$FILE:1:1" >/dev/null 2>&1 || true; sleep 2
  osascript -e "$SE to tell process \"zed\" to set position of window 1 to {$X1, $((Y0+39))}" -e "$SE to tell process \"zed\" to set size of window 1 to {$W, $H}"
  ghostty_window
  echo "[finder]"; finder_window
}

is_dark() { [ "$(osascript -e "$SE to tell appearance preferences to get dark mode")" = true ]; }

ghostty_window() {
  echo "[ghostty]"
  osascript -e "$SE to tell process \"ghostty\" to click (first button whose subrole is \"AXCloseButton\") of (every window whose name contains \"Landmarks\")" >/dev/null 2>&1 || true; sleep 1
  osascript -e "$SE to tell process \"ghostty\" to tell menu bar 1 to tell menu bar item \"File\" to tell menu 1 to click menu item \"New Window\"" >/dev/null; sleep 2
  osascript -e "$SE to set frontmost of process \"ghostty\" to true"; sleep 0.8
  front=$(osascript -e "$SE to get name of first process whose frontmost is true"); [ "$front" = ghostty ] || { echo "Ghostty is not frontmost, not typing"; exit 1; }
  case "$(osascript -e "$SE to tell process \"ghostty\" to get name of window 1")" in *Landmarks*|*"~"*|*/*) ;; *) echo "unexpected Ghostty window, not typing"; exit 1;; esac
  osascript -e "$SE to keystroke \"cd $PKG; clear; bash ../demo.sh\"" -e "$SE to key code 36"; sleep 12
  osascript -e "$SE to tell process \"ghostty\" to set position of window 1 to {$X1, $((Y1+39))}" -e "$SE to tell process \"ghostty\" to set size of window 1 to {$W, $H}"
  rm -rf "$PKG/.build"
}

finder_window() {
  osascript -e "tell application \"Finder\" to close every Finder window" >/dev/null 2>&1 || true
  osascript -e "tell application \"Finder\"
    set w to make new Finder window to (POSIX file \"$PKG\" as alias)
    set current view of w to list view
    set toolbar visible of w to true
    set bounds of w to {$X0, $((Y1+39)), $((X0+W)), $((Y1+39+H))}
  end tell" >/dev/null
  sleep 1
}

wait_for_appearance() {
  # Apps re-render within about 1.5 s. Sample one window until two readings agree.
  local id prev="" cur i; id=$(win Zed Landmarks | cut -d'|' -f1 | tr -d ' ')
  sleep 1
  for i in $(seq 1 10); do
    screencapture -x -o -l"$id" /tmp/hero-probe.png; cur=$(magick /tmp/hero-probe.png -resize 5% -format "%[fx:mean]" info: 2>/dev/null)
    [ -n "$prev" ] && [ "$cur" = "$prev" ] && break
    prev=$cur; sleep 0.4
  done
}

capture_mode() {
  local mode=$1 dark=$2 T; T=$(mktemp -d)
  if [ "$(osascript -e "$SE to tell appearance preferences to get dark mode")" != "$dark" ]; then
    osascript -e "$SE to tell appearance preferences to set dark mode to $dark"; wait_for_appearance
  fi
  # Each window is raised before its capture. A window that is behind another has no
  # rendered backdrop for its glass toolbar, and captures with dither noise in its place.
  local apps=(Xcode Zed Finder Ghostty) procs=(Xcode zed Finder ghostty) xs=($X0 $X1 $X0 $X1) ys=($Y0 $Y0 $Y1 $Y1) k line id
  # Park the pointer in the gap between the windows, or a hover effect ends up in the shot.
  $WM $(( X1 - 8 )) $(( Y1 + 39 - 24 )); sleep 0.5
  local front; front=$(osascript -e "$SE to get name of first process whose frontmost is true")
  for k in 0 1 2 3; do
    line=$(win "${apps[$k]}" Landmarks); [ -n "$line" ] || { echo "no ${apps[$k]} window named Landmarks"; exit 1; }
    id=$(echo "$line" | cut -d'|' -f1 | tr -d ' ')
    osascript -e "$SE to set frontmost of process \"${procs[$k]}\" to true"; sleep 0.4
    screencapture -x -l"$id" "$T/w$k.png"
  done
  osascript -e "$SE to set frontmost of process \"$front\" to true" 2>/dev/null || true
  # The shadow is wider for the active window than for an inactive one (112 by 76 px
  # versus 46 by 32 at 2x), so measure each capture's opaque box instead of assuming.
  local args=() box ox oy
  for k in 0 1 2 3; do
    box=$(magick "$T/w$k.png" -alpha extract -threshold 99% -format "%@" info: 2>/dev/null)
    ox=$(echo "$box" | sed -E 's/.*\+([0-9]+)\+([0-9]+)$/\1/'); oy=$(echo "$box" | sed -E 's/.*\+([0-9]+)\+([0-9]+)$/\2/')
    args+=( "$T/w$k.png" -geometry "+$(( xs[k] * 2 - ox ))+$(( ys[k] * 2 - oy ))" -composite )
  done
  ( magick "$ASSETS/wallpaper-$mode.jpg" "${args[@]}" -profile "/System/Library/ColorSync/Profiles/sRGB Profile.icc" -strip -define png:compression-level=9 "$OUT/hero-$mode@2x.png" 2>/dev/null
    sips -s dpiWidth 144 -s dpiHeight 144 "$OUT/hero-$mode@2x.png" >/dev/null
    magick "$OUT/hero-$mode@2x.png" -resize 50% -define png:compression-level=9 "$OUT/hero-$mode.png" 2>/dev/null
    rm -rf "$T"; echo "wrote $OUT/hero-$mode@2x.png and $OUT/hero-$mode.png" ) &
}

ZED_SETTINGS=$HOME/.config/zed/settings.json
blame_off() {
  # Zed ignores git.inline_blame in project settings, so switch it off in the user's
  # settings for the duration of the capture. Zed applies the change live.
  [ -f "$ZED_SETTINGS" ] && ! grep -q '"inline_blame"' "$ZED_SETTINGS" || return 0
  cp "$ZED_SETTINGS" /tmp/hero-zed-settings.json
  python3 - "$ZED_SETTINGS" <<'PY'
import sys; p=sys.argv[1]; s=open(p).read(); i=s.index("{")
open(p,"w").write(s[:i+1]+'\n  "git": { "inline_blame": { "enabled": false } },'+s[i+1:])
PY
  trap 'cp /tmp/hero-zed-settings.json "$ZED_SETTINGS"' EXIT
  sleep 3
}

capture() {
  mkdir -p "$OUT"
  blame_off
  local show_all; show_all=$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || echo 0)
  if [ "$show_all" = 1 ] || [ "$show_all" = true ]; then
    defaults write com.apple.finder AppleShowAllFiles -bool false; killall Finder; sleep 2; finder_window
  fi
  local was_dark=false; is_dark && was_dark=true
  if [ "$was_dark" = true ]; then capture_mode dark true; capture_mode light false; else capture_mode light false; capture_mode dark true; fi
  osascript -e "$SE to tell appearance preferences to set dark mode to $was_dark"
  wait
  if [ "$show_all" = 1 ] || [ "$show_all" = true ]; then defaults write com.apple.finder AppleShowAllFiles -bool true; killall Finder; fi
}

wallpaper() {
  # The wallpaper is a window of its own, owned by WindowManager, so capturing it by id
  # excludes desktop icons and everything else. Its crossfade takes about 4 s.
  local wp mode; wp=$($WL | awk -F'|' '$2 ~ /WindowManager/ && $3 ~ /Wallpaper/ {print $1+0; exit}')
  local was_dark=false; is_dark && was_dark=true
  for mode in light dark; do
    osascript -e "$SE to tell appearance preferences to set dark mode to $([ $mode = dark ] && echo true || echo false)"; sleep 6
    screencapture -x -l"$wp" /tmp/hero-wp.png
    magick /tmp/hero-wp.png -crop 4112x2580+0+78 +repage -profile "/System/Library/ColorSync/Profiles/sRGB Profile.icc" -strip -quality 92 "$ASSETS/wallpaper-$mode.jpg" 2>/dev/null
    echo "wrote $ASSETS/wallpaper-$mode.jpg"
  done
  osascript -e "$SE to tell appearance preferences to set dark mode to $was_dark"
}

case "${1:-all}" in
  setup) setup ;;
  capture) capture ;;
  ghostty) ghostty_window ;;
  wallpaper) wallpaper ;;
  all) setup; capture; defaults write com.apple.finder AppleShowAllFiles -bool true; killall Finder ;;
  *) echo "usage: $0 [setup|capture|ghostty|wallpaper]"; exit 1 ;;
esac
