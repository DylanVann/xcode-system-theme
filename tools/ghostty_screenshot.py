#!/usr/bin/env python3
"""Render the standard palette screenshot for each Ghostty theme.

This is the same 600x300 image that iTerm2-Color-Schemes generates for every
scheme it ships, including Ghostty's bundled themes. The renderer and the pixel
font are taken from that project's tools/screenshot_gen (MIT, Mark Badolato and
contributors). Requires Pillow. Run from the repo root:

    python3 tools/ghostty_screenshot.py
"""
import os, re, string
from PIL import Image, ImageDraw

FONT_CHARSET = ";" + string.digits + string.ascii_letters


class PixFont:
    def __init__(self, font_img):
        self.char_width, rem = divmod(font_img.width, len(FONT_CHARSET))
        assert not rem
        self.char_height = font_img.height
        self.chars = {c: font_img.crop((i * self.char_width, 0, (i + 1) * self.char_width, self.char_height))
                      for i, c in enumerate(FONT_CHARSET)}

    def draw(self, img, coords, text, color):
        cx, cy = coords
        for i, c in enumerate(text):
            if not c.isspace():
                img.paste(color, (cx + i * self.char_width, cy), mask=self.chars[c])


class ConsoleScreenshotRenderer:
    stripe_w, stripe_x0 = 7, 9

    def __init__(self, font, colors):
        self.font, self.c = font, colors
        self.img = Image.new("RGB", self._xc(80, 19))
        self.draw = ImageDraw.Draw(self.img)

    def _xc(self, cx, cy): return cx * self.font.char_width, cy * self.font.char_height
    def _rect(self, x0, y0, x1, y1, fill): self.draw.rectangle([self._xc(x0, y0), self._xc(x1, y1)], fill=fill)

    def render(self):
        c, f = self.c, self.font
        self.img.paste(c["background"], (0, 0, self.img.width, self.img.height))
        for i in range(9):
            color = i - 1
            x = self.stripe_x0 + i * (self.stripe_w + 1)
            f.draw(self.img, self._xc(x, 0), (f"{40 + color}m" if i else "def").center(self.stripe_w), c["foreground"])
            if color >= 0:
                self._rect(x, 1, x + self.stripe_w, 19, c["ansi"][color])
        for i in range(9):
            color = i - 1
            for bright in (0, 1):
                y = 1 + i * 2 + bright
                desc = ("1;" if bright else "") + (f"{30 + color}m" if color >= 0 else "m")
                f.draw(self.img, self._xc(1, y), desc.rjust(6), c["foreground"])
                fg = c["foreground"] if color < 0 else c["ansi"][color + 8 * bright]
                for bg in range(9):
                    f.draw(self.img, self._xc(self.stripe_x0 + bg * (self.stripe_w + 1), y), "qYw".center(self.stripe_w), fg)
        self._rect(0, 0, 3, 1, c["cursor"]); f.draw(self.img, self._xc(0, 0), "Cur", c["cursor_text"])
        self._rect(4, 0, 7, 1, c["selection"]); f.draw(self.img, self._xc(4, 0), "Sel", c["selection_text"])
        return self.img


def read_ghostty(path):
    hexes, ansi = {}, {}
    for line in open(path):
        line = line.strip()
        if not line or line.startswith("#"): continue
        key, _, value = line.partition(" = ")
        if key == "palette":
            n, _, h = value.partition("="); ansi[int(n)] = h
        else:
            hexes[key] = value
    rgb = lambda h: tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))
    return {"ansi": [rgb(ansi[i]) for i in range(16)], "background": rgb(hexes["background"]), "foreground": rgb(hexes["foreground"]),
            "cursor": rgb(hexes["cursor-color"]), "cursor_text": rgb(hexes["cursor-text"]),
            "selection": rgb(hexes["selection-background"]), "selection_text": rgb(hexes["selection-foreground"])}


if __name__ == "__main__":
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    font = PixFont(Image.open(os.path.join(root, "tools/screenshot_font.png")).convert("L"))
    for name in ("Light", "Dark"):
        img = ConsoleScreenshotRenderer(font, read_ghostty(os.path.join(root, f"ghostty/Xcode System {name}"))).render()
        img = img.resize((600, 300), resample=Image.Resampling.BOX).convert("RGB").quantize(colors=256, method=2)
        out = os.path.join(root, f"screenshots/ghostty-{name.lower()}.png")
        img.save(out, optimize=True, compress_level=9); print("wrote", out)
