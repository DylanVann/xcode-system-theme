#!/bin/bash
# The "before" shot: the same four windows cascaded, with each app's own default dark
# look, to show the mismatch the theme fixes. Zed on One Dark, Ghostty on its built-in
# palette with bat's default theme, Xcode and Finder as they are. Written to
# screenshots/before-dark.png. Needs the windows from `hero.sh setup` open. Temporarily
# edits the Zed settings and Ghostty config and restores both.
set -e
source "$(dirname "$0")/hero.sh"
GHOSTTY_CONFIG=$HOME/.config/ghostty/config
cp "$ZED_SETTINGS" /tmp/before-zed-settings.json; cp "$GHOSTTY_CONFIG" /tmp/before-ghostty-config
restore() {
  cp /tmp/before-zed-settings.json "$ZED_SETTINGS"; cp /tmp/before-ghostty-config "$GHOSTTY_CONFIG"
  osascript -e "$SE to tell process \"ghostty\" to click menu item \"Reload Configuration\" of menu 1 of menu bar item \"Ghostty\" of menu bar 1" >/dev/null 2>&1 || true
}
trap restore EXIT
python3 - "$ZED_SETTINGS" <<'PY'
import sys,re; p=sys.argv[1]; s=open(p).read()
s=re.sub(r'"dark": "Xcode System Dark[^"]*"','"dark": "One Dark"',s); open(p,"w").write(s)
PY
sed -i '' 's/^theme = .*/theme = /' "$GHOSTTY_CONFIG"
osascript -e "$SE to tell process \"ghostty\" to click menu item \"Reload Configuration\" of menu 1 of menu bar item \"Ghostty\" of menu bar 1" >/dev/null
demo() {
  osascript -e "$SE to set frontmost of process \"ghostty\" to true"; sleep 0.5
  osascript -e "$SE to tell process \"ghostty\" to perform action \"AXRaise\" of (first window whose name contains \"Landmarks\")" >/dev/null; sleep 0.5
  case "$(osascript -e "$SE to tell process \"ghostty\" to get name of window 1")" in *Landmarks*) ;; *) echo "demo window is not frontmost, not typing"; exit 1;; esac
  osascript -e "$SE to keystroke \"clear; DEMO_BAT_THEME='$1' bash $S/tools/hero/demo.sh\"" -e "$SE to key code 36"; sleep 10
}
demo "Monokai Extended"
dotfiles_hide
sleep 3
XS=(444 620 268 796); YS=(287 393 181 499); PASTE_ORDER=(2 0 1 3); OUT_PREFIX=before
capture_mode dark true; wait
demo "Xcode System"
dotfiles_restore; sleep 2; finder_window
osascript -e "$SE to tell appearance preferences to set dark mode to false"
ls -la "$OUT"/before-*.png
