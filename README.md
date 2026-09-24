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

## Matching Finder and the rest of macOS

By default, macOS tints window backgrounds with a blur of your wallpaper, so Finder's gray drifts with the desktop and with whatever window sits behind it. Xcode's editor is opaque and never drifts, so the two can only agree by accident.

Turn off **System Settings > Appearance > Allow wallpaper tinting in windows**. This is separate from Reduce transparency: the Dock, menu bar, and sidebars keep their glass, but window surfaces settle on fixed grays that no longer follow the wallpaper. With that off, in dark mode on macOS 26, the surfaces measure like this in sRGB:

| Surface | Color |
|---|---|
| Xcode editor, and this theme | `#262626` |
| Finder sidebar | `#262626` |
| Xcode navigator and inspector | `#292929` |
| Finder toolbar and status bar | `#2a2a2a` |
| Finder file area (icon, column, and list view) | `#1e1e1e` |

So the theme lands on the same gray as Xcode's editor and Finder's sidebar, and the surrounding chrome in both apps sits within a few levels of each other.

Finder's file area is darker on purpose. It uses Apple's dark-mode content background color, a fixed semantic color rather than a material, so no wallpaper or appearance setting moves it. This theme follows the window gray instead, because that is what Xcode's editor uses and what you look at all day. The gap between a Finder window's file list and an editor next to it is a consistent 8 levels, which reads as a normal inset rather than a mismatch.

## Provenance

**Light.** Background, foreground, and selection come straight from the `Default (Light).xccolortheme` bundled in Xcode.app (DVTUserInterfaceKit). The ANSI slots map Xcode's syntax roles: red is string, green is function, yellow is number and attribute, blue is declaration, magenta is keyword, cyan is system function, bright black is comment.

**Dark.** The Standard preset stores hues and intensities, not colors, so these values were measured from the rendered editor in sRGB: neutral `#262626` background, warm off-white text, and the tinted syntax colors. The ANSI slots map red to string, green to identifier, yellow to number, blue to link with bright blue as type, magenta to keyword with bright magenta as attribute and macro, cyan to system type and function, bright black to comment.

The Zed themes extend the same values to the window chrome, with panels, tabs, and borders picked to sit next to Xcode's navigator and inspector.

## License

MIT
