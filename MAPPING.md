# Where every value comes from

Every color in `ghostty/` and `themes/` is one of three kinds:

- **Extracted.** Read out of Xcode's running editor through the accessibility API. Exact: these are the components Xcode itself assigns to each token.
- **Measured.** Sampled from the screen. Exact for the surface it was sampled from, on the display and macOS build it was sampled on.
- **Chosen.** Picked by eye or by offset from a measured value, because Xcode has no equivalent surface or the value was not measured.

Anything marked chosen is fair game to improve with a measurement.

`tools/build.py` generates `themes/xcode-system.json` and both `ghostty/` files from the values in this document. Edit the values there, not in the generated files. `bat/Xcode System.tmTheme` holds no colors at all: it maps TextMate scopes to palette slots with bat's `#RRGGBBAA` encoding, alpha `00` and the ANSI index in `RR`, following the same role-to-slot table as the Ghostty files.

## Sources

### Xcode's workspace themes

Xcode 27 stores its workspace theme choice in `com.apple.dt.Xcode` under `DVTWorkspaceThemeSettings`. On the machine this theme was built on it decodes to:

```json
{"dark": {"preset": {"_0": "Standard"}}, "light": {"default": {}}}
```

Both appearances use the built-in Standard preset: dark records it explicitly, and light's `default` means the preset was never changed from the default, which Xcode's Appearance panel shows as Standard in light mode too. The preset is a procedural recipe, and Xcode 27 does not read the classic `.xccolortheme` files while they are in effect: switching the font and color themes to `Material Lighter` and `Material Palenight` changed nothing in either mode, and the colors Xcode assigns in light mode differ from the bundled `Default (Light)` plist in hue, not just lightness. The plist's number is `#1c00cf`, a deep violet; Xcode 27 draws `#0078b8`.

### `xcode/Default (Light).xccolortheme`

Verbatim copy from Xcode 27.0 (build 27A266a), taken from `DVTUserInterfaceKit.framework/Resources/FontAndColorThemes/` inside Xcode.app. It is kept on record because earlier versions of this theme were built from it. No value here comes from it any more.

### `xcode/Standard 2.xcworkspacecolortheme` and `xcode/Standard 3.xcworkspacecolortheme`

Xcode has no file that holds a recipe's resolved colors. These two recipes were exported from Xcode 27's Appearance panel on 2026-09-15 while experimenting with it, and they record the Standard preset's palette:

| Recipe field | Value | Meaning |
|---|---|---|
| `primary.hue` | 359° at intensity 0.5 | the pink of keywords |
| `secondary.hue` | 242° at intensity 0 | neutral, so the background has no tint |
| `colorOverrides.string.hue` | 30° | the orange-red of strings |
| `colorOverrides.number.hue` and `preprocessor.hue` | 81° | the yellow of numbers and preprocessor lines |

The hues are OKLCH hue angles. The extracted colors land on them: keyword at 357°, string at 31°, number at 80°, plain text at 2°.

`Standard 2` keeps the preset's `gradient` background. `Standard 3` pins the background to a neutral gray at OKLab lightness 0.2646 with zero chroma, which converts to `#252525` in sRGB, one level from the `#262626` measured on screen. The measurement wins, since the goal is what is on screen.

Neither recipe is the source of any value here. They are included so the preset's structure is on record.

### Extraction

Xcode's source editor answers `AXAttributedStringForRange`, and the attributed string it returns carries a foreground color for every run. `tools/axcolors.swift` finds the editor in a named Xcode window, asks for the whole document, and prints each distinct color with the tokens it was applied to. The colors come back labeled Generic RGB, but their raw components are the sRGB values: multiplied by 255 they match screen pixels to within one level, in both modes, for every role.

To reproduce, with the terminal granted Accessibility access:

```
open -a Xcode tools/Probe.swift
swiftc -O tools/axcolors.swift -o /tmp/axcolors && /tmp/axcolors Probe.swift
```

`tools/Probe.swift` is a valid Swift file that exercises every syntax role. Wait for the title bar's "Preparing Editor Functionality" to clear before extracting, or references and system symbols come back with syntactic rather than semantic colors. Extracted 2026-09-24 from Xcode 27.0 with both font and color themes set to their bundled defaults.

### Screen measurements

Taken 2026-09-24 on macOS 27.0 (build 26A428) with **Allow wallpaper tinting in windows** turned off, on a built-in Liquid Retina XDR display. Each surface is captured with `screencapture -l <window id>` and read with ImageMagick as the dominant pixel color of a region.

The PNG that `screencapture` writes is tagged with the display's own profile, not sRGB. It is converted to sRGB with `magick in.png -profile "/System/Library/ColorSync/Profiles/sRGB Profile.icc"` before pixels are read. Neutral grays come out the same either way; saturated colors do not, by up to 20 levels per channel. With that conversion, screen pixels of text agree with the extracted values to within one level.

## Editor roles

Extracted. Components are in `tools/build.py`; the hex here is those components times 255, rounded.

| Role in Xcode | Light | Dark | Tokens it covers | Ghostty | Zed |
|---|---|---|---|---|---|
| Plain text | `#322529` | `#f9f1f3` | punctuation, operators, local variables and their uses, module names, argument labels of project calls | `foreground`, `cursor-color`, `selection-foreground`, palette 7 | `text`, `icon`, `editor.foreground`, `editor.active_line_number`, `terminal.foreground`, `terminal.ansi.white`; syntax `primary`, `variable`, `operator`, `punctuation.*`, `label`, `embedded`, `title`; `players[0]`. `emphasis` and `emphasis.strong` set only the font style, so doc-comment markup keeps the comment color as in Xcode |
| Comment | `#6a7084` | `#abb3cd` | `//` and `///` comments, `MARK:`, `TODO:`, `FIXME:`, doc markup text. The `///` marker is drawn at 35% alpha in light and 45% in dark; doc markup punctuation at 50% and 60%. | palette 8 | `text.muted`, `icon.muted`, `terminal.dim_foreground`, `terminal.ansi.bright_black`, `hint`; syntax `comment`, `comment.doc`, `comment.documentation`, `hint`; `comment.mark` in bold for `MARK:`, `TODO:`, and `FIXME:` lines, as Xcode draws them |
| Doc comment code | `#3e3c48` | `#c9c8d9` | inline code and parameter names inside `///` comments | | syntax `text.literal`, which Zed's Markdown gives to code spans, including inside Swift doc comments with the improved Swift extension |
| Link | `#0049c1` | `#5b97e6` | URLs in comments | palette 4 | `text.accent`, `icon.accent`, `link_text.hover`, `info`, `renamed`, `accents[0]`, `players[5]`; syntax `link_text`, `link_uri`, `tag` |
| Preprocessor | `#906918` | `#eba800` | `#if`, `#endif`, `#warning(...)` | palette 3 and 11 | `warning`; syntax `preproc` |
| Number | `#0078b8` | `#eba800` | integer and float literals. Dark shares the preprocessor color. | dark only: palette 3 and 11 | `modified`, `players[3]`, `accents[3]`; syntax `number`; dark `search.match_background` at 40% |
| String | `#ca2c1d` | `#ff8d7a` | string, multi-line string, and character literals, including interpolation delimiters | palette 1 and 9 | `error`, `deleted`, `conflict`, `players[4]`, `accents[4]`; syntax `string`, `string.*` |
| Keyword | `#c4246e` | `#ff82b3` | keywords, `init`, `true`, `nil`, `some`, and attributes such as `@available`, `@objc`, `@inlinable`, `@propertyWrapper`. Xcode sets keywords in SF Mono Semibold, so the keyword scopes carry weight 600; attributes stay regular. | palette 5 | `players[1]`, `accents[1]`; syntax `keyword`, `attribute`, `boolean`, `constructor`, `variable.builtin`, `variable.special` |
| Declaration | `#006279` | `#26a6c1` | names being declared: functions, methods, parameters, global variables and constants, properties, enum cases, `_` | palette 2 | syntax `function.definition`, `variable.parameter` |
| Reference | `#00695c` | `#21ac9c` | uses of project functions, methods, global variables, properties, enum cases | palette 10 | `success`, `created`, `players[2]`, `accents[2]`; syntax `function`, `function.method`, `constant`, `property`, `variant` |
| Type declaration | `#007e9e` | `#00cafa` | names of structs, classes, enums, protocols, typealiases being declared | palette 12 | |
| Type reference | `#00856f` | `#00d9b2` | uses of project types, including as property wrappers | | `players[7]`; syntax `type`, `enum` |
| System type | `#9d31cf` | `#d896fe` | `String`, `Int`, `Date`, `URL`, `NSObject`, `View`, argument labels of system calls, type-based attributes such as `@MainActor` and `@ViewBuilder` | palette 6 and 14 | `players[6]`, `accents[5]`; syntax `type.builtin` |
| System function and macro | `#8b0099` | `#d852e6` | `print`, `max`, `abs`, `.count`, `.uppercased()`, `Int.max`, `Double.pi`, `.default`, `#Preview`, `@Observable`, `@State` | palette 13 | syntax `function.builtin`, `function.macro` |

Notes:

- **Zed's `type` takes the reference color, not the declaration color.** Zed applies `type` to every type identifier, and uses outnumber declarations. Same for `function`. Zed's `function.definition` and `variable.parameter` get the declaration color where a grammar emits them.
- **Light has no ANSI slot for number.** It is a saturated blue that would be wrong in the yellow slot, so the yellow slots both carry the preprocessor ochre.
- **Palette 0 is chosen:** `#000000` light, `#353535` dark. Palette 15 is `#ffffff` in both.
- **Cursor** is the plain text color, chosen. Xcode's insertion point was not measured; the machine this was built on runs Xcode's Vim mode, whose block cursor hides it.
- The earlier dark values, measured from screenshots before the extraction existed, differ from the extracted ones by at most three levels per channel: plain `#faf1f3`, comment `#aab3cd`, string `#ff8d79`, function `#26a5bf`, type `#03c8f9`, lavender `#d795fc`, link `#5a97e4`, and `#d751e4` for what turned out to be the system function and macro color.

## Editor surfaces

Measured unless marked chosen.

| Surface | Light | Dark | Ghostty | Zed |
|---|---|---|---|---|
| Editor background | `#ffffff` | `#262626` | `background`, `cursor-text` | `editor.background`, `editor.gutter.background`, `terminal.background`, `tab.active_background`, `toolbar.background` |
| Text selection, the system selection color | `#b3d7ff` | `#3f638b` | `selection-background` | `players[0].selection`, `panel.focused_border`, `pane.focused_border`, `border.focused`, `border.selected`; document highlights and `drop_target.background` at reduced alpha |
| Current line | `#eeeeee` | `#353535` | | `editor.active_line.background`, `editor.highlighted_line.background` |
| Line numbers | `#b8b3b4` | `#6f6d6e` | | `editor.line_number` |
| Invisibles, chosen | `#cccccc` | `#4a4a4a` | | `editor.invisible`; light also `editor.active_wrap_guide`, `editor.indent_guide_active`, `panel.indent_guide_hover`, `panel.indent_guide_active` |
| Guides, chosen | `#e1e1e1` | `#353535` | | `editor.wrap_guide`, `editor.indent_guide` |
| Active guides in dark, chosen | | `#474747` | | `editor.active_wrap_guide`, `editor.indent_guide_active` |
| Placeholder text, chosen | `#a0a0a0` | `#7a7f8c` | | `text.placeholder`, `text.disabled`, `icon.placeholder`, `icon.disabled`, `predictive`, `ignored`, `hidden`, `unreachable` |
| Search match, chosen | `#fff28a` | number at 40% | | `search.match_background` |
| Scrollbar thumb, chosen | black at 20% and 33% | white at 20% and 33% | | `scrollbar.thumb.*` |

Light `#eeeeee` and `#b3d7ff` replace the plist's `#e8f2ff` and `#a4cdff`, which Xcode 27 does not draw. The light selection is AppKit's `selectedTextBackgroundColor`; the dark one matches AppKit's dark value exactly.

## Window chrome

Measured on 2026-09-24 from a project window with the navigator, inspector, and debug area open.

| Surface | Dark | Light |
|---|---|---|
| Xcode editor | `#262626` | `#ffffff` |
| Xcode navigator and inspector | `#292929`, measuring between `#282828` and `#292929` | `#ededed` |
| Xcode navigator selected row, navigator not focused | `#474747` | `#d7d7d7` |
| Xcode title bar and toolbar | `#2f2f2f` | `#ffffff` |
| Xcode jump bar and debug area bar | `#2e2e2e` | `#ffffff` |
| Xcode status bar | `#2d2d2d` | `#ffffff` |
| Xcode bottom console area | `#252525` | `#ffffff` |
| Finder sidebar | `#262626` | `#ededed` |
| Finder toolbar and status bar | `#272727` to `#2a2a2a`, a material over the file list | `#ffffff` |
| Finder file area, icon and column view | `#1e1e1e` | `#ffffff` |
| Finder list view rows, alternating | `#1e1e1e` and `#292929` | `#ffffff` and `#f4f5f5` |

Finder's file area and rows are AppKit's `controlBackgroundColor` and `alternatingContentBackgroundColors`, which resolve to exactly these values. Xcode's dark navigator selected row is within one level of `unemphasizedSelectedContentBackgroundColor`, `#464646`.

There is no visible separator line between Xcode's navigator and editor in either mode; the panels meet edge to edge. The `border` values below are therefore chosen.

### Zed chrome, both modes

| Zed keys | Light | Dark | Kind | Note |
|---|---|---|---|---|
| `background`, `surface.background`, `panel.background`, `tab_bar.background`, `tab.inactive_background`, `element.background`, `element.disabled`, `editor.subheader.background` | `#ededed` | `#292929` | measured | Xcode's navigator. |
| `title_bar.background`, `title_bar.inactive_background`, `status_bar.background` | `#ededed` | `#292929` | measured | The panel gray, so the sidebar, title bar, and status bar form one surface around the editor, as Xcode's navigator and toolbar area does around its editor. Xcode's own toolbar measures `#ffffff` and `#2f2f2f`; using it gave Zed a distinct band across the top that read as clutter. |
| `element.selected`, `ghost_element.selected` | `#d7d7d7` | `#474747` | measured | Xcode's navigator selected row. |
| `elevated_surface.background` | `#ffffff` | `#383838` | chosen | Popovers. Light uses the editor white; dark is the old `#2e2e2e` moved up 10. |
| `border`, `pane_group.border`, `panel.indent_guide` | `#d9d9d9` | `#3f3f3f` | chosen | The sidebar edge, title bar line, and split dividers, kept so the window reads like Zed's own themes. Light: the old plist border `#e1e1e1` moved down 8. Dark: `#353535` moved up 10. Dark also uses this for `element.hover` and `ghost_element.hover`. |
| `border.variant`, `border.disabled`, `scrollbar.track.border` | transparent | transparent | chosen | The hairlines under the tab bar and the breadcrumb bar, dropped so the editor chrome reads as one block. Xcode has no lines there either. |
| `element.hover`, `ghost_element.hover` | `#e0e0e0` | `#3f3f3f` | chosen | Light: `#e8e8e8` moved down 8. |
| `element.active`, `ghost_element.active` | `#d0d0d0` | `#515151` | chosen | Light: `#d8d8d8` moved down 8. Dark: `#474747` moved up 10, also used for `panel.indent_guide_hover` and `panel.indent_guide_active`. |

## Known gaps

- Zed's Swift extension has no node for macro expressions such as `#Preview`, so they render as plain text where Xcode uses the macro color. Bare URLs inside doc comments are not recognized by Markdown either.
- Xcode colors DocC symbol links in doc comments, the double-backtick form such as ``` ``LandmarkRow`` ```, in the link color. Zed's Markdown treats them as ordinary code spans, so they take the doc-code color. Telling them apart needs a pattern in Zed's own markdown-inline query, not the theme or the Swift extension.

- The chrome borders, hover, and active states are offsets from older values, not measurements of Xcode's separators and hover states. Xcode has no visible separator between its panels.
- The cursor colors are chosen. Vim mode's block cursor hid the insertion point.
- Xcode's Standard preset draws a subtle `gradient` background by recipe. The editor measured `#262626` across several regions, so the theme is flat.
