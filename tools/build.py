#!/usr/bin/env python3
"""Generate themes/xcode-system.json and ghostty/* from the values in MAPPING.md.

Syntax colors are the sRGB components Xcode reports for each token through the
accessibility API (see tools/axcolors.swift). Surfaces were measured from the
screen. Run from the repo root: python3 tools/build.py
"""
import json, os

def hx(r, g, b, a=None):
    s = "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))
    return s + ("%02x" % round(a * 255) if a is not None else "")

# Editor roles: sRGB components as reported by Xcode 27.0 through AXAttributedStringForRange.
LIGHT_ROLES = {
    "plain":      (0.1978, 0.1467, 0.1618),
    "comment":    (0.4149, 0.4402, 0.5188),
    "doc_code":   (0.2443, 0.2356, 0.2825),
    "link":       (0.0000, 0.2877, 0.7575),
    "preproc":    (0.5637, 0.4136, 0.0957),
    "number":     (0.0000, 0.4695, 0.7225),
    "string":     (0.7925, 0.1711, 0.1122),
    "keyword":    (0.7696, 0.1417, 0.4323),
    "decl":       (0.0000, 0.3827, 0.4751),
    "ref":        (0.0000, 0.4106, 0.3612),
    "type_decl":  (0.0000, 0.4934, 0.6185),
    "type_ref":   (0.0000, 0.5228, 0.4345),
    "sys_type":   (0.6158, 0.1916, 0.8126),
    "sys_func":   (0.5464, 0.0000, 0.5995),
}
DARK_ROLES = {
    "plain":      (0.9783, 0.9434, 0.9527),
    "comment":    (0.6689, 0.7020, 0.8041),
    "doc_code":   (0.7887, 0.7833, 0.8504),
    "link":       (0.3553, 0.5941, 0.9021),
    "preproc":    (0.9221, 0.6596, 0.0000),
    "number":     (0.9221, 0.6596, 0.0000),
    "string":     (1.0000, 0.5525, 0.4783),
    "keyword":    (1.0000, 0.5116, 0.7032),
    "decl":       (0.1494, 0.6520, 0.7559),
    "ref":        (0.1290, 0.6746, 0.6121),
    "type_decl":  (0.0000, 0.7908, 0.9816),
    "type_ref":   (0.0000, 0.8501, 0.6990),
    "sys_type":   (0.8462, 0.5877, 0.9967),
    "sys_func":   (0.8467, 0.3229, 0.9003),
}

# Surfaces, measured from the screen in sRGB (MAPPING.md, "Window chrome" and editor tables).
LIGHT_SURFACES = dict(
    editor="#ffffff", selection="#b3d7ff", current_line="#eeeeee", line_number="#b8b3b4",
    invisible="#cccccc", guide="#e1e1e1", panel="#ededed", selected_row="#d7d7d7",
    toolbar="#ffffff", popover="#ffffff",
    border="#d9d9d9", border_variant="#e4e4e4", hover="#e0e0e0", active="#d0d0d0",
    placeholder="#a0a0a0", ansi_black="#000000", ansi_bright_white="#ffffff",
    search_match="#fff28a", scrollbar="#000000", search_alpha=None,
)
DARK_SURFACES = dict(
    editor="#262626", selection="#3f638b", current_line="#353535", line_number="#6f6d6e",
    invisible="#4a4a4a", guide="#353535", panel="#292929", selected_row="#474747",
    toolbar="#2f2f2f", popover="#383838",
    border="#3f3f3f", border_variant="#353535", hover="#3f3f3f", active="#515151",
    placeholder="#7a7f8c", ansi_black="#353535", ansi_bright_white="#ffffff",
    search_match=None, scrollbar="#ffffff", search_alpha=0.4,
)

def theme(name, appearance, roles, S):
    c = {k: hx(*v) for k, v in roles.items()}
    def alpha(h, a): return h + "%02x" % round(a * 255)
    guide_active = S["invisible"] if appearance == "light" else "#474747"
    sel = S["selection"]
    search = S["search_match"] or alpha(c["number"], S["search_alpha"])
    style = {
        "background.appearance": "opaque",
        "background": S["panel"], "surface.background": S["panel"],
        "elevated_surface.background": S["popover"],
        "panel.background": S["panel"], "panel.focused_border": sel,
        "panel.indent_guide": S["border"], "panel.indent_guide_hover": guide_active if appearance == "light" else S["active"],
        "panel.indent_guide_active": guide_active if appearance == "light" else S["active"],
        "pane.focused_border": sel, "pane_group.border": "#00000000",
        "tab_bar.background": S["panel"], "tab.active_background": S["editor"], "tab.inactive_background": S["panel"],
        "title_bar.background": S["panel"], "title_bar.inactive_background": S["panel"],
        "status_bar.background": S["panel"], "toolbar.background": S["editor"],
        "border": "#00000000", "border.variant": "#00000000", "border.focused": sel, "border.selected": sel,
        "border.transparent": "#00000000", "border.disabled": "#00000000",
        "text": c["plain"], "text.muted": c["comment"], "text.placeholder": S["placeholder"], "text.disabled": S["placeholder"], "text.accent": c["link"],
        "icon": c["plain"], "icon.muted": c["comment"], "icon.placeholder": S["placeholder"], "icon.disabled": S["placeholder"], "icon.accent": c["link"],
        "element.background": S["panel"], "element.hover": S["hover"], "element.active": S["active"], "element.selected": S["selected_row"], "element.disabled": S["panel"],
        "ghost_element.background": "#00000000", "ghost_element.hover": S["hover"], "ghost_element.active": S["active"], "ghost_element.selected": S["selected_row"], "ghost_element.disabled": "#00000000",
        "drop_target.background": alpha(sel, 0.4),
        "link_text.hover": c["link"],
        "editor.background": S["editor"], "editor.foreground": c["plain"], "editor.gutter.background": S["editor"], "editor.subheader.background": S["panel"],
        "editor.active_line.background": S["current_line"], "editor.highlighted_line.background": S["current_line"],
        "editor.line_number": S["line_number"], "editor.active_line_number": c["plain"],
        "editor.invisible": S["invisible"], "editor.wrap_guide": S["guide"], "editor.active_wrap_guide": guide_active,
        "editor.indent_guide": S["guide"], "editor.indent_guide_active": guide_active,
        "editor.document_highlight.read_background": alpha(sel, 0.4), "editor.document_highlight.write_background": alpha(sel, 0.6), "editor.document_highlight.bracket_background": alpha(sel, 0.6),
        "scrollbar.thumb.background": alpha(S["scrollbar"], 0.2), "scrollbar.thumb.hover_background": alpha(S["scrollbar"], 0.333), "scrollbar.thumb.border": "#00000000",
        "scrollbar.track.background": "#00000000", "scrollbar.track.border": "#00000000",
        "search.match_background": search,
        "terminal.background": S["editor"], "terminal.foreground": c["plain"], "terminal.bright_foreground": c["plain"], "terminal.dim_foreground": c["comment"],
        "terminal.ansi.background": S["editor"],
    }
    palette = ansi_palette(c, S)
    names = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
    for i, n in enumerate(names):
        style["terminal.ansi." + n] = palette[i]
        style["terminal.ansi.bright_" + n] = palette[i + 8]
        style["terminal.ansi.dim_" + n] = palette[i]
    style["players"] = [{"cursor": col, "background": col, "selection": sel if i == 0 else alpha(col, 0.24)}
                        for i, col in enumerate([c["plain"], c["keyword"], c["ref"], c["number"], c["string"], c["link"], c["sys_type"], c["type_ref"]])]
    style["accents"] = [c["link"], c["keyword"], c["ref"], c["number"], c["string"], c["sys_type"]]
    for key, col in [("error", c["string"]), ("warning", c["preproc"]), ("info", c["link"]), ("success", c["ref"]), ("hint", c["comment"]),
                     ("predictive", S["placeholder"]), ("created", c["ref"]), ("deleted", c["string"]), ("modified", c["number"]),
                     ("renamed", c["link"]), ("conflict", c["string"]), ("ignored", S["placeholder"]), ("hidden", S["placeholder"]), ("unreachable", S["placeholder"])]:
        style[key] = col; style[key + ".background"] = alpha(col, 0.15); style[key + ".border"] = alpha(col, 0.15)
    syn = {
        "attribute": c["keyword"], "boolean": c["keyword"], "comment": c["comment"], "comment.doc": c["comment"], "comment.documentation": c["comment"],
        "constant": c["ref"], "constructor": c["keyword"], "embedded": c["plain"], "enum": c["type_ref"], "function": c["ref"],
        "function.builtin": c["sys_func"], "function.definition": c["decl"], "function.macro": c["sys_func"], "function.method": c["ref"],
        "keyword": c["keyword"], "label": c["plain"], "link_text": c["link"], "link_uri": c["link"], "number": c["number"], "operator": c["plain"],
        "preproc": c["preproc"], "primary": c["plain"], "property": c["ref"], "punctuation": c["plain"], "punctuation.bracket": c["plain"],
        "punctuation.delimiter": c["plain"], "punctuation.list_marker": c["plain"], "punctuation.special": c["plain"], "string": c["string"],
        "string.escape": c["string"], "string.regex": c["string"], "string.special": c["string"], "string.special.symbol": c["string"],
        "tag": c["link"], "text.literal": c["doc_code"], "type": c["type_ref"], "type.builtin": c["sys_type"], "type.definition": c["type_decl"], "variable": c["plain"],
        "variable.builtin": c["keyword"], "variable.parameter": c["decl"], "variable.special": c["keyword"], "variant": c["ref"],
    }
    style["syntax"] = {k: {"color": v} for k, v in sorted(syn.items())}
    style["syntax"]["emphasis"] = {"font_style": "italic"}
    style["syntax"]["emphasis.strong"] = {"font_weight": 700}
    style["syntax"]["hint"] = {"color": c["comment"], "font_weight": 700}
    style["syntax"]["comment.mark"] = {"color": c["comment"], "font_weight": 700}
    style["syntax"]["predictive"] = {"color": S["placeholder"], "font_style": "italic"}
    style["syntax"]["title"] = {"color": c["plain"], "font_weight": 700}
    for k in ("keyword", "boolean", "constructor", "variable.builtin", "variable.special"):
        style["syntax"][k] = {"color": c["keyword"], "font_weight": 600}
    style["syntax"] = dict(sorted(style["syntax"].items()))
    return {"name": name, "appearance": appearance, "style": style}

def ansi_palette(c, S):
    return [S["ansi_black"], c["string"], c["decl"], c["preproc"], c["link"], c["keyword"], c["sys_type"], c["plain"],
            c["comment"], c["string"], c["ref"], c["preproc"], c["type_decl"], c["sys_func"], c["sys_type"], S["ansi_bright_white"]]

def ghostty(header, roles, S, cursor):
    c = {k: hx(*v) for k, v in roles.items()}
    lines = [header]
    for i, col in enumerate(ansi_palette(c, S)): lines.append(f"palette = {i}={col}")
    lines += [f"background = {S['editor']}", f"foreground = {c['plain']}", f"cursor-color = {cursor}", f"cursor-text = {S['editor']}",
              f"selection-background = {S['selection']}", f"selection-foreground = {c['plain']}"]
    return "\n".join(lines) + "\n"

LIGHT_HEADER = """# Xcode 27 light appearance: the Standard workspace theme preset, Xcode 27's
# default in light mode as in dark. The preset is a procedural recipe (hues and
# intensities, not stored colors), so syntax colors are the sRGB values Xcode
# reports for each token through the accessibility API; background, selection,
# and chrome were measured on screen. ANSI slots: red=string, green=declaration (bright: reference),
# yellow=preprocessor, blue=link (bright: type declaration), magenta=keyword and
# attribute (bright: system function and macro), cyan=system type, bright
# black=comment. Xcode's number color is a saturated blue and has no slot."""
DARK_HEADER = """# Xcode 27 dark appearance: the Standard workspace theme preset, Xcode 27's
# default in dark mode. The preset is a procedural recipe (hues and intensities,
# not stored colors), so syntax colors are the sRGB values Xcode reports for each
# token through the accessibility API; background, selection, and chrome were
# measured on screen. ANSI slots: red=string, green=declaration (bright:
# reference), yellow=number and preprocessor, blue=link (bright: type
# declaration), magenta=keyword and attribute (bright: system function and
# macro), cyan=system type, bright black=comment."""

if __name__ == "__main__":
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    doc = {"$schema": "https://zed.dev/schema/themes/v0.2.0.json", "name": "Xcode System", "author": "Dylan Vann",
           "themes": [theme("Xcode System Light", "light", LIGHT_ROLES, LIGHT_SURFACES), theme("Xcode System Dark", "dark", DARK_ROLES, DARK_SURFACES)]}
    with open(os.path.join(root, "themes/xcode-system.json"), "w") as f: json.dump(doc, f, indent=2); f.write("\n")
    with open(os.path.join(root, "ghostty/Xcode System Light"), "w") as f: f.write(ghostty(LIGHT_HEADER, LIGHT_ROLES, LIGHT_SURFACES, hx(*LIGHT_ROLES["plain"])))
    with open(os.path.join(root, "ghostty/Xcode System Dark"), "w") as f: f.write(ghostty(DARK_HEADER, DARK_ROLES, DARK_SURFACES, hx(*DARK_ROLES["plain"])))
    for mode, roles in (("light", LIGHT_ROLES), ("dark", DARK_ROLES)):
        print(mode, {k: hx(*v) for k, v in roles.items()})
