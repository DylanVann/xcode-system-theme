# Notes for agents working on this repo

Hard-won facts about how these themes are built and verified. Read before touching colors, screenshots, or the Swift extension work.

## How the values are produced

- `tools/build.py` is the only place colors live. It writes `themes/xcode-system.json` and both `ghostty/` files. Never edit those outputs by hand; edit the components in `build.py`, run it, and copy the JSON to `~/.config/zed/themes/` if Zed should pick it up.
- Syntax colors are **extracted**, not measured. `tools/axcolors.swift` reads Xcode's editor through the accessibility API (`AXAttributedStringForRange`) and prints one line per color with the tokens it covers. Build it with `swiftc -O tools/axcolors.swift -o /tmp/axcolors`, then run `/tmp/axcolors <window title substring>` against a window that has `tools/Probe.swift` open.
- The AX colors come back labeled **Generic RGB, but their raw components are sRGB**. Multiply by 255 and round. Do not convert through `usingColorSpace(.sRGB)`; that produces wrong, lighter values.
- The same AX call reports fonts. Xcode 27's Standard preset is SF Mono 13 with keywords in SF Mono Semibold and doc comments in SF Pro 13. The classic plist says 12; that plist is not what Xcode 27 draws.
- Surfaces (backgrounds, selection, current line, line numbers, panels, toolbars) are **measured from screenshots**. Capture a window with `screencapture -x -o -l <window id>`, then convert with `magick in.png -profile "/System/Library/ColorSync/Profiles/sRGB Profile.icc"` before reading pixels. The PNG is tagged with the display profile, and saturated colors are off by up to 20 levels per channel without the conversion. Grays are unaffected.
- Screen pixels of text agree with extracted values to within one level. If they differ by more, the capture was not converted, or the wrong window was captured.

## Facts about Xcode 27 that contradict older assumptions

- Xcode 27 does not read `.xccolortheme` files while a workspace theme is in effect, and the Standard preset is in effect in both appearances by default. Switching the font-and-color theme changed nothing. `xcode/Default (Light).xccolortheme` is kept for the record only.
- `DVTWorkspaceThemeSettings` in `com.apple.dt.Xcode` shows the preset. `{"light": {"default": {}}}` means "unchanged from the default", which is Standard.
- Xcode's system-type color is applied by **name**, not by resolution. A project type whose name matches any SDK type, including nested ones such as SwiftUI's `Kind` or Foundation's `Category`, is painted purple even when the project's own declaration wins lookup. Sample code must avoid such names. `tools/hero/Landmarks` uses `Place` for this reason; `Kind` and `Category` both collide.
- Wait for "Preparing Editor Functionality" to clear from Xcode's title bar before extracting; earlier, references and system symbols carry syntactic rather than semantic colors.
- Xcode's canvas and inspector eat editor width. Hide them through the menu bar with System Events: View > Inspectors > "Hide Inspector", and Editor > "Canvas" when its `AXMenuItemMarkChar` is a check mark. Keyboard shortcuts for these have side effects.
- Never send keystrokes to Xcode. It runs in Vim mode on this machine and stray characters edit the file. Revert with `git checkout` if it happens.

## Driving Zed

- The process name is lowercase `zed`. `pgrep -x Zed` never matches, and scripts that rely on it will believe Zed is not running and skip the quit. Use `pgrep -x zed` and `killall zed`.
- Zed's quit is asynchronous and often hangs for a while, logging `timed out waiting on app_will_quit`. Wait for the process to disappear, fall back to `killall zed` after about 15 s, then sleep several seconds before `open -a Zed`, or the launch is swallowed by the shutdown.
- Zed reads a dev extension's query files at launch. Editing `highlights.scm` does nothing live, and the Rebuild button in the Extensions view is unreliable to click from a script. A clean restart of Zed is the dependable way to load query changes.
- Zed's file watcher on `~/.config/zed` drops events under load (log shows `fs_watcher ... user dropped`), so theme edits are sometimes not reloaded either. A restart fixes that too.
- `~/.config/zed` is a symlink into `~/Developer/dotfiles-dylan/config/zed`. Copying a theme there dirties the dotfiles repo.
- Avoid keystrokes when the user may be typing; they land wherever focus is, including this terminal. Menu items are clickable through System Events without focus: `tell process "zed" to tell menu bar 1 to tell menu bar item "File" to tell menu 1 to click menu item "Close Editor"`. The Zed app menu has "Extensions".
- To put the cursor somewhere without keystrokes, use the CLI: `/Applications/Zed.app/Contents/MacOS/cli "path/to/file.swift:1:1"`. Zed restores the last cursor position per file otherwise.
- `open -g -a Zed file` on an already-open file does not switch tabs. Close the active tab through the File menu first.
- Zed has no Swift support without the Swift extension, and tree-sitter alone cannot tell system types from project types or declarations from uses. The fork at `~/Developer/zed-extensions-swift`, branch `xcode-like-highlights`, adds those captures; PR is `DylanVann/swift#1`. Without it, the theme's `type.builtin`, `type.definition`, `function.macro`, `comment.mark`, and doc-comment Markdown scopes never fire for Swift.
- In tree-sitter queries, a capture on an alternation `[ (a) (b (c)) ] @x` attaches to the outer node of each branch. To match the inner identifier, put the capture inside each branch. Later patterns win over earlier ones for the same node.

## Fonts and weights

- Share Tech Mono has only a Regular face, so bold keywords, bold marks, and italics render as regular. SF Mono has all faces and is what Xcode uses; it ships inside `/System/Applications/Utilities/Terminal.app/Contents/Resources/Fonts/` and can be copied to `~/Library/Fonts` without sudo. The `font-sf-mono` Homebrew cask needs sudo.
- Zed settings that match Xcode: `"buffer_font_family": "SF Mono"`, `"buffer_font_size": 13`, `"buffer_line_height": { "custom": 1.4 }`. Xcode's 1.1 spacing multiplier on SF Mono 13 lands on about 18 pt per row, the same as Zed at 1.4.
- Scopes that should only change weight or style must not set a color, or they override the surrounding comment color inside doc comments. Zed does not inherit the outer color into an injected layer's captures.

## Screenshots

- Ghostty's standard preview is the iTerm2-Color-Schemes 600 by 300 palette table; `tools/ghostty_screenshot.py` reproduces it and needs Pillow.
- `tools/zed_screenshot.sh` captures the Zed window at a fixed size with the cursor at 1:1. `tools/winid.swift` finds window IDs by owner name.
- The old full-desktop approach needed desktop icons hidden (`defaults write com.apple.finder CreateDesktop -bool false; killall Finder`) and hidden files off, other apps hidden through System Events, and this session's own Ghostty window minimized by exclusion (`every window whose name does not contain "Landmarks"`), since its title changes with the active tab. Restore all of it afterward; unhiding with `set visible ... to true` fails for some apps, so fall back to `open -g -a <App>`.
- Creating a new Space does not help: activating an app switches to the Space holding its windows, and Zed reuses an existing window instead of opening one in the current Space. Mission Control's add-desktop button lives in the `WindowManager` process, not the Dock, if it is ever needed.
- System appearance can be toggled with `tell application "System Events" to tell appearance preferences to set dark mode to true`. Wait about 5 s for wallpaper and app transitions before capturing.
- Comparison images for the extension PR are built by `compose.sh` in the session scratchpad from `cmp_capture.sh` captures; they live on the `assets` branch of `DylanVann/swift` and are referenced by raw URL. GitHub's raw CDN caches for a few minutes after a push.

## bat theme

- `bat/Xcode System.tmTheme` colors through palette slots using bat's encoding: `#RRGGBBAA` with `AA` of `00` means ANSI index `RR`, and `#00000001` means the terminal default. Indices 8 to 15 work even though bat's own template only documents 0 to 7; they come out as `38;5;N`.
- bat's default themes emit 24-bit color, so without this theme the terminal palette never applies. `--theme=ansi` is bat's generic 16-color mapping and collapses comments and strings together.
- bat's Swift grammar is shallow. Declared type names, inherited types, constructor calls, parameters, and stdlib functions have no scope at all, so they stay plain whatever the theme says. Function names are scoped only at the `entity` family level, the `@` is `punctuation.definition.attribute`, attribute names are `storage.modifier`, `false` is `keyword.constant`, and `import` lines are wrapped in `meta.import`, which the theme uses to keep module names plain.
- To find scopes, install a probe theme that maps each candidate selector to a distinct index and read the codes back with `bat --color=always | cat -v`. Selector specificity, not rule order, decides which rule wins.
- After editing the theme: copy it to `$(bat --config-dir)/themes/` and run `bat cache --build`.

## Hero shot specifics

- `tools/hero/hero.sh` is the working procedure: `setup` opens and sizes the windows, `capture` composites. It relies on everything above and on `tools/hero/demo.sh` for the terminal pane, which renders the file with `bat` and the Xcode System bat theme.
- Capture by compositing, never by a full-screen grab. `screencapture -l <id>` without `-o` returns the window with its shadow as alpha. The shadow is a constant of macOS, 46 px left and right, 32 above, 60 below at 2x, the same for every window and size, so the placement on the canvas is grid position minus 23 and 16, times two for the 2x canvas, with no measuring. The composite is written at 2x as `hero-{mode}@2x.png` and halved for the README's `hero-{mode}.png`, which links to the 2x file. GitHub strips `target` attributes, so the link cannot force a new tab.
- The 2x files carry 144 dpi metadata so Preview and Quick Look show them at one image pixel per device pixel; at the default 72 dpi they display at twice their size and look soft. Browsers ignore the metadata and scale images to fit, and the display itself runs a 4112 px buffer downsampled to a 3456 px panel, so no viewer shows the file sharper than at 50% zoom. A window capture matches the composite pixel for pixel, verified with `magick compare -metric AE`; if a shot looks blurry, it is the viewer. Windows can sit anywhere on screen; only their size matters.
- The wallpapers are stored in the repo as `tools/hero/wallpaper-{light,dark}.jpg` at the display's native 2x resolution, captured once from the wallpaper window (owner `WindowManager`, titled `Wallpaper`, which excludes desktop icons). `hero.sh wallpaper` recaptures them; the wallpaper crossfade takes about 4 s, which is why they are not captured per run. `tools/winlist.swift` lists windows at every layer with bounds.
- Park the mouse pointer in the gap between windows before capturing (`tools/warpmouse.swift`). The pointer itself is never captured, but hover effects are: a pointer left over Zed's editor produced a documentation popup in the shot once Zed was raised.
- Raise each window immediately before capturing it. macOS 27 glass toolbars, Xcode's especially, are backdrops the compositor only renders while the window is unobscured; a window captured from behind another comes back with dither-noise blocks where its toolbar items sit. Frontmost-then-capture costs about 0.4 s per window and makes every window look active.
- After switching appearance, apps re-render in about 1.5 s. Poll one window's mean brightness until two samples agree rather than sleeping; capture whichever appearance is current first so only one switch is needed, and restore the original appearance at the end. `capture` takes about 7 s for both appearances, most of it the switch and Finder's hidden-files toggle.
- Never delete `.swiftpm` while Xcode has the package open; Xcode raises a modal about the vanished workspace file. Deleting `.build` is fine.
- `tools/hero/Landmarks/.zed/settings.json` excludes `.build`, `.swiftpm`, and `.zed` from Zed's tree, since sourcekit-lsp keeps recreating an index build there.
- Xcode's canvas state is restored per window, so check the Canvas menu item's mark and click until it reads `missing value`.
- Sample output must not show git history or `ls -l` owner columns; both leak the account name. The Finder sidebar still shows the home folder name.
- `screencapture` omits the mouse pointer unless `-C` is passed, so the shots never include it. Do not add `-C`.
- Close leftover demo windows first: Ghostty via the AX close button on windows whose name contains "Landmarks", Finder via `close every Finder window`.

## Things that cannot be matched and are documented as such

- `#Preview` and other macro expressions have no grammar node in tree-sitter-swift.
- DocC symbol links (double backticks) are code spans to Markdown; coloring them like links needs a pattern in Zed's own markdown-inline query.
- Bare URLs in comments are not recognized by Markdown.
- Enum case declarations get the reference color; Zed has one `variant` scope.
- Doc comments in a proportional font.
- Xcode's name-based system-type coloring of colliding project types.
