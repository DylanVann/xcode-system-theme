# Xcode System Theme

Xcode 27's default colors for [Ghostty](https://ghostty.org) and [Zed](https://zed.dev), so your editor, terminal, and Xcode all agree with each other and with the rest of macOS.

## Why

In dark mode, Xcode, Finder, your editor, and your terminal each pick a slightly different near-black. Side by side, the mismatch is subtle and it looks bad. This theme gives Ghostty and Zed the exact background Xcode 27 uses, `#262626`, and the same syntax colors, so every window you code in reads as one surface. Light mode gets the same treatment with Xcode's white editor and `#262626` text.

Existing Xcode ports convert the classic `.xccolortheme` files that Xcode has bundled since Xcode 11. Xcode 27 no longer uses those in dark mode. Its dark default is the "Standard" workspace theme preset, a procedural recipe with no exportable file, which is why no other port has it.

## Themes

| Name | Appearance | Source |
|---|---|---|
| Xcode System Light | light | Xcode 27's `Default (Light).xccolortheme`, which Xcode 27 still uses in light mode |
| Xcode System Dark | dark | Xcode 27's "Standard" workspace theme preset, its default in dark mode |

Both are opaque. The point is a stable background that other windows can match.

## Install

### Zed

Until the extension is in the Zed store, install it as a dev extension:

1. Clone this repo.
2. In Zed, open the command palette and run `zed: extensions`.
3. Click **Install Dev Extension** and pick the repo folder.

Then in `settings.json`:

```json
"theme": {
  "mode": "system",
  "light": "Xcode System Light",
  "dark": "Xcode System Dark"
}
```

### Ghostty

Copy the two files from `ghostty/` into `~/.config/ghostty/themes/`, then add to your Ghostty config:

```
theme = light:Xcode System Light,dark:Xcode System Dark
```

Ghostty switches live when the system appearance changes.

## Matching Finder

Finder's window background is a translucent material, not a color. macOS blends a fixed gray tint with a blur of whatever sits behind the window, so Finder's exact value drifts with your wallpaper and with the windows behind it. Xcode's editor is opaque, so there is no way to make Xcode drift along with Finder.

The fix is to remove the drift. Set your desktop wallpaper to a solid `#262626`. With this theme, every possible backdrop is then the same gray: the desktop, Xcode, Zed, and Ghostty. Finder keeps its glass, but blurring a uniform gray gives a uniform result, so Finder reads one constant color wherever you put it.

That constant may sit a step or two off `#262626`, because the material's own tint pulls the blend slightly. It reads as a subtle inset rather than a mismatch. On macOS 26, System Settings > Appearance has a Liquid Glass style. "Tinted" weights the material's own color more and the backdrop less, which shrinks that gap further without turning transparency off.

## Provenance

**Light.** Background, foreground, and selection come straight from the `Default (Light).xccolortheme` bundled in Xcode.app (DVTUserInterfaceKit). The ANSI slots map Xcode's syntax roles: red is string, green is function, yellow is number and attribute, blue is declaration, magenta is keyword, cyan is system function, bright black is comment.

**Dark.** The Standard preset stores hues and intensities, not colors, so these values were measured from the rendered editor in sRGB: neutral `#262626` background, warm off-white text, and the tinted syntax colors. The ANSI slots map red to string, green to identifier, yellow to number, blue to link with bright blue as type, magenta to keyword with bright magenta as attribute and macro, cyan to system type and function, bright black to comment.

The Zed themes extend the same values to the window chrome, with panels, tabs, and borders picked to sit next to Xcode's navigator and inspector.

## License

MIT
