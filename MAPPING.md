# Where every value comes from

Every color in `ghostty/` and `themes/` is one of three kinds:

- **Plist.** Read from Xcode's own theme file. Exact.
- **Measured.** Sampled from the screen. Exact for the surface it was sampled from, on the display and macOS build it was sampled on.
- **Chosen.** Picked by eye or by offset from a measured value, because Xcode has no equivalent surface or the value was not measured.

Anything marked chosen is fair game to improve with a measurement.

## Sources

### `xcode/Default (Light).xccolortheme`

Verbatim copy from Xcode 27.0 (build 27A266a), taken from:

```
/Applications/Xcode.app/Contents/SharedFrameworks/DVTUserInterfaceKit.framework/Versions/A/Resources/FontAndColorThemes/Default (Light).xccolortheme
```

Xcode 27 stores its workspace theme choice in `com.apple.dt.Xcode` under `DVTWorkspaceThemeSettings`. On the machine this theme was built on it decodes to:

```json
{"dark": {"preset": {"_0": "Standard"}}, "light": {"default": {}}}
```

Dark mode uses the built-in Standard preset, untouched. Light mode has no workspace theme, so the classic `Default (Light)` editor theme applies. That is what the two halves of this theme reproduce.

Plist colors are stored as `r g b a` floats in 0 to 1. The hex values below are those floats times 255, rounded.

### `xcode/Standard 2.xcworkspacecolortheme` and `xcode/Standard 3.xcworkspacecolortheme`

Xcode has no file for the Standard preset. These two recipes were exported from Xcode 27's Appearance panel on 2026-09-15 while experimenting with it, and they record the preset's palette:

| Recipe field | Value | Meaning |
|---|---|---|
| `primary.hue` | 359° at intensity 0.5 | the pink of keywords |
| `secondary.hue` | 242° at intensity 0 | neutral, so the background has no tint |
| `colorOverrides.string.hue` | 30° | the orange-red of strings |
| `colorOverrides.number.hue` and `preprocessor.hue` | 81° | the yellow of numbers |

`Standard 2` keeps the preset's `gradient` background. `Standard 3` pins the background to a neutral gray at OKLab lightness 0.2646 with zero chroma, which converts to `#252525` in sRGB, one level from the `#262626` measured on screen. The measurement wins, since the goal is what is on screen.

Neither recipe is the source of any value here. They are included so the preset's structure is on record, since the rendered colors depend on Xcode's private recipe-to-color conversion.

### Screen measurements

Taken 2026-09-24 on macOS 26 with **Allow wallpaper tinting in windows** turned off, by capturing a screen region with `screencapture` and taking the dominant pixel color with ImageMagick. Values are sRGB. The dark editor background was confirmed at `#262626` across several regions of the editor this way; the syntax colors were measured earlier by the same method and are not re-verified here.

## Light: editor and syntax

The `xcode.syntax.*` keys live under `DVTSourceTextSyntaxColors` in the plist.

| Plist key | Hex | Ghostty | Zed |
|---|---|---|---|
| `DVTSourceTextBackground` | `#ffffff` | `background`, `cursor-text`, palette 15 | `editor.background`, `editor.gutter.background`, `terminal.background`, `elevated_surface.background`, `tab.active_background`, `toolbar.background` |
| `xcode.syntax.plain` | `#000000` at 0.85 alpha, `#262626` composited on white | `foreground`, `selection-foreground` | `editor.foreground`, `text`, `icon`, `terminal.foreground`, syntax `primary`, `variable`, `operator`, `punctuation.*`, `label`, `title`, `emphasis` |
| `DVTSourceTextSelectionColor` | `#a4cdff` | `selection-background` | `players[0].selection`, `panel.focused_border`, `pane.focused_border`, `border.focused`, `border.selected`, document highlights at reduced alpha |
| `DVTSourceTextCurrentLineHighlightColor` | `#e8f2ff` | | `editor.active_line.background`, `editor.highlighted_line.background`, `element.selected`, `ghost_element.selected` |
| `DVTSourceTextInvisiblesColor` | `#cccccc` | | `editor.invisible`, `editor.active_wrap_guide`, `editor.indent_guide_active`, `panel.indent_guide_hover` |
| `DVTMarkupTextBorderColor` | `#e1e1e1` | | `editor.wrap_guide`, `editor.indent_guide` |
| `DVTSourceTextBlockDimBackgroundColor` | `#6c6c6c` | palette 7 | `text.muted`, `icon.muted`, `terminal.dim_foreground` |
| `DVTMarkupTextLinkColor`, `xcode.syntax.url` | `#0e0eff` | | `link_text.hover`, syntax `link_text`, `link_uri`, `tag` |
| `xcode.syntax.string` | `#c41a16` | palette 1 and 9 | syntax `string`, `string.*`, `text.literal` |
| `xcode.syntax.identifier.function` | `#326d74` | palette 2 | syntax `function`, `constant`, `property`; `players[2]` |
| `xcode.syntax.identifier.class` | `#1c464a` | palette 10 | syntax `type`, `enum`, `constructor`, `variant` |
| `xcode.syntax.attribute` | `#815f03` | palette 3 | syntax `attribute` |
| `xcode.syntax.preprocessor` | `#643820` | palette 11 | syntax `preproc` |
| `xcode.syntax.declaration.other` | `#0f68a0` | palette 4 | `text.accent`, `icon.accent` |
| `xcode.syntax.declaration.type` | `#0b4f79` | palette 12 | |
| `xcode.syntax.keyword` | `#9b2393` | palette 5 | syntax `keyword`, `boolean`, `variable.special`, `punctuation.special`; `players[1]` |
| `xcode.syntax.markup.code` | `#aa0d91` | palette 13 | |
| `xcode.syntax.identifier.function.system` | `#6c36a9` | palette 6 | syntax `function.builtin`, `type.builtin` |
| `xcode.syntax.identifier.type.system` | `#3900a0` | palette 14 | |
| `xcode.syntax.comment` | `#5d6c79` | palette 8 | syntax `comment`, `comment.doc`, `hint`; `terminal.ansi.bright_black` |
| `xcode.syntax.number` | `#1c00cf` | | syntax `number` |

Notes on the light mapping:

- **The ANSI yellow slot goes to attribute, not number.** Xcode's number color is a saturated blue, which would be wrong in a terminal's yellow slot. Attribute's ochre reads as yellow. Zed gets the real number color because it has a dedicated key.
- **Palette 0 is `#000000`.** Plist plain text is black at 85% alpha. The terminal's black slot uses the un-composited black.
- **Cursor is `#000000`.** The plist has no cursor key. Xcode draws the insertion point in the plain text color, which is black.
- **Chosen:** `editor.line_number` `#a8a8a8`, `text.placeholder` and `text.disabled` `#a0a0a0`, `predictive` `#a0a0a0`. No plist equivalent.

## Dark: editor and syntax

The Standard preset stores hues and intensities, not colors, so every value here was measured from the rendered editor in sRGB. The recipe's hue overrides corroborate the roles: string at 30° is the orange-red, number and preprocessor at 81° are the yellow, and the 359° primary is the keyword pink.

| Role in Xcode | Hex | Ghostty | Zed |
|---|---|---|---|
| Editor background | `#262626` | `background`, `cursor-text` | `editor.background`, `editor.gutter.background`, `terminal.background`, `tab.active_background`, `toolbar.background` |
| Plain text, warm off-white | `#faf1f3` | `foreground`, `cursor-color`, `selection-foreground` | `editor.foreground`, `text`, `icon`, `terminal.foreground`, syntax `primary`, `variable`, `operator`, `punctuation.*`; `players[0]` |
| String | `#ff8d79` | palette 1 and 9 | syntax `string`, `string.*`, `text.literal` |
| Identifier, function | `#26a5bf` | palette 2 and 10 | syntax `function`, `constant`, `property`; `players[2]` |
| Number | `#eba800` | palette 3 and 11 | syntax `number` |
| Link | `#5a97e4` | palette 4 | `link_text.hover`, `text.accent`, `icon.accent`, focused and selected borders, syntax `link_text`, `link_uri`, `tag` |
| Type | `#03c8f9` | palette 12 | syntax `type`, `enum`, `constructor`, `variant` |
| Keyword | `#ff82b3` | palette 5 | syntax `keyword`, `boolean`, `variable.special`, `punctuation.special`; `players[1]` |
| Attribute, macro | `#d751e4` | palette 13 | syntax `attribute`, `preproc` |
| System type and function, lavender | `#d795fc` | palette 6 and 14 | syntax `function.builtin`, `type.builtin` |
| Comment | `#aab3cd` | palette 8 | syntax `comment`, `comment.doc`, `hint`, `text.muted`, `icon.muted`, `terminal.ansi.bright_black` |

Chosen, not measured: palette 0 and `terminal.ansi.black` `#353535`, selection `#474747`, `editor.active_line.background` `#2f2f2f`, `editor.line_number` `#6a6a6a`, `editor.invisible` `#4a4a4a`, `text.placeholder` `#7a7f8c`, palette 15 `#ffffff`. Measuring Xcode's dark selection and current-line colors would turn the first three into measured values.

## Window chrome

Measured on 2026-09-24. Zed's chrome follows Xcode's navigator and inspector, since those are the surfaces that sit next to the editor.

| Surface | Dark | Light |
|---|---|---|
| Xcode editor | `#262626` | `#ffffff` |
| Xcode navigator and inspector | `#292929` | `#ededed` |
| Xcode bottom console area | `#252525` | `#ffffff` |
| Finder sidebar | `#262626` | `#ededed` |
| Finder toolbar and status bar | `#2a2a2a` | `#ffffff` |
| Finder file area, icon and column view | `#1e1e1e` | `#ffffff` |
| Finder list view rows, alternating | `#1e1e1e` and `#292929` | `#ffffff` and `#f4f5f5` |

### Light chrome

| Zed keys | Value | Kind | Note |
|---|---|---|---|
| `background`, `surface.background`, `panel.background`, `tab_bar.background`, `tab.inactive_background`, `title_bar.*`, `status_bar.background`, `element.background`, `element.disabled`, `editor.subheader.background` | `#ededed` | measured | Xcode's navigator. Was `#f5f5f5`, which came from the plist's `DVTMarkupTextBackgroundColor`, the documentation popover background, and sat 8 levels lighter than Xcode's panels. |
| `border`, `pane_group.border`, `panel.indent_guide` | `#d9d9d9` | chosen | `#e1e1e1` from the plist, moved down 8 to keep contrast on the darker panel. |
| `border.variant`, `border.disabled`, `scrollbar.track.border` | `#e4e4e4` | chosen | `#ececec` moved down 8. |
| `element.hover`, `ghost_element.hover` | `#e0e0e0` | chosen | `#e8e8e8` moved down 8. |
| `element.active`, `ghost_element.active` | `#d0d0d0` | chosen | `#d8d8d8` moved down 8. |

### Dark chrome

| Zed keys | Value | Kind | Note |
|---|---|---|---|
| `background`, `surface.background`, `panel.background`, `tab_bar.background`, `tab.inactive_background`, `title_bar.*`, `status_bar.background`, `element.background`, `element.disabled`, `editor.subheader.background` | `#292929` | measured | Xcode's navigator. Was `#1f1f1f`, a chosen value darker than the editor. Xcode's panels are lighter than its editor, so the relationship flipped. |
| `elevated_surface.background` | `#383838` | chosen | Popovers. `#2e2e2e` moved up 10. |
| `border`, `pane_group.border`, `panel.indent_guide`, `element.hover`, `ghost_element.hover` | `#3f3f3f` | chosen | `#353535` moved up 10. |
| `border.variant`, `border.disabled`, `scrollbar.track.border` | `#353535` | chosen | `#2b2b2b` moved up 10. It would have been 2 levels from the new panel. |
| `element.active`, `ghost_element.active`, `panel.indent_guide_hover`, `panel.indent_guide_active` | `#515151` | chosen | `#474747` moved up 10. |
| `element.selected`, `ghost_element.selected` | `#444444` | chosen | `#3a3a3a` moved up 10. |

Editor-side values such as wrap guides, indent guides, document highlights, and the terminal's ANSI black were not shifted, because they sit on the editor's `#262626`, not on the panel.

## Known gaps

- The chrome borders, hover, active, and selected states are offsets from the old values, not measurements of Xcode's separators and hover states.
- Xcode's light panel gray was measured with wallpaper tinting off. With tinting on it drifts with the wallpaper, and so does Finder.
- The dark selection, current line, line number, and invisibles colors have not been measured against Xcode.
