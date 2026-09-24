# Xcode System Theme

Xcode 27's default colors for [Ghostty](https://ghostty.org), [Zed](https://zed.dev), and [bat](https://github.com/sharkdp/bat), so your editor, terminal, and Xcode match each other and the rest of macOS.

[![Xcode, Zed, Finder, and Ghostty, light](screenshots/hero-light.png)](screenshots/hero-light@2x.png)

[![Xcode, Zed, Finder, and Ghostty, dark](screenshots/hero-dark.png)](screenshots/hero-dark@2x.png)

## Why

Xcode, Finder, your editor, and your terminal each pick a slightly different near-black, and side by side it shows. Out of the box, with Zed's and Ghostty's default themes:

[![Xcode, Zed, Ghostty, and Finder with their default dark themes](screenshots/before-dark.png)](screenshots/before-dark@2x.png)

With this theme, every window you code in reads as one surface:

[![The same windows with Xcode System](screenshots/cascade-dark.png)](screenshots/cascade-dark@2x.png)

The theme uses Xcode 27's exact background and syntax colors. Light mode gets the same treatment.

Other Xcode ports convert the `.xccolortheme` files Xcode has bundled since Xcode 11. Xcode 27 no longer draws those; its default is a procedural recipe whose resolved colors are not exported anywhere. This theme reads them out of Xcode's running editor instead.

## Install

### Zed

![Zed, light](screenshots/zed-light.png)

![Zed, dark](screenshots/zed-dark.png)

Until the extension is in the Zed store, install it as a dev extension: clone this repo, run `zed: extensions`, click **Install Dev Extension**, and pick the repo folder. Then run `theme selector: toggle`, or set both appearances in `settings.json`:

```json
"theme": {
  "mode": "system",
  "light": "Xcode System Light",
  "dark": "Xcode System Dark"
}
```

### Ghostty

![Ghostty, light](screenshots/ghostty-light.png)

![Ghostty, dark](screenshots/ghostty-dark.png)

```sh
mkdir -p ~/.config/ghostty/themes
cp ghostty/* ~/.config/ghostty/themes/
```

Then in `~/.config/ghostty/config`:

```ini
theme = light:Xcode System Light,dark:Xcode System Dark
```

### bat

bat's own themes use 24-bit color, so terminal themes never reach them. This one maps syntax roles to the terminal's palette instead.

```sh
mkdir -p "$(bat --config-dir)/themes"
cp "bat/Xcode System.tmTheme" "$(bat --config-dir)/themes/"
bat cache --build
```

Then in `$(bat --config-dir)/config`:

```
--theme="Xcode System"
```

## Notes

### Font

Xcode 27 uses SF Mono at 13 points, keywords in Semibold. The theme sets that weight, so a font with a bold face is needed.

```sh
brew install --cask font-sf-mono
```

Zed:

```json
"buffer_font_family": "SF Mono",
"buffer_font_size": 13,
"buffer_line_height": { "custom": 1.4 }
```

Ghostty:

```ini
font-family = SF Mono
font-size = 13
```

### Swift in Zed

Xcode colors Swift with compiler knowledge: system types, declarations, and attributes each differ. Zed's Swift extension can't tell them apart from the grammar alone. [zed-extensions/swift#85](https://github.com/zed-extensions/swift/pull/85) adds captures for them; until it's merged, install the fork as a dev extension:

```sh
git clone -b xcode-like-highlights https://github.com/DylanVann/swift.git
```

### Matching Finder

Turn off **System Settings > Appearance > Allow wallpaper tinting in windows**. Otherwise Finder's gray drifts with your wallpaper while Xcode's editor never does. With it off, Finder's sidebar and Xcode's editor share `#262626` in dark mode and white in light mode. Finder's file area stays darker on purpose; it uses Apple's fixed content background.

## Provenance

Syntax colors are read from Xcode's editor through the accessibility API, with `tools/axcolors.swift` and a probe file that exercises every syntax role. Surfaces are measured from screen captures converted to sRGB. Those are exact. Hover, active, and border shades have no Xcode equivalent and are chosen offsets from the measured surfaces. `tools/build.py` generates the theme files, and [MAPPING.md](MAPPING.md) traces every value to its source. The scripts in `tools/` regenerate all screenshots.

## License

MIT
