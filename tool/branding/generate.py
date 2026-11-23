#!/usr/bin/env python3
"""Generate all HP-CPR branding rasters from assets/branding/source.png.

The source is a white artwork on a red gradient rounded square with black
corners. The white artwork is extracted as an alpha mask (alpha derived from
min(R, G, B), which is high for white and near zero for red/black) and then
recomposited on the flat brand red. Red areas inside the artwork (lightning
bolts, heart interior) therefore stay "negative space".

Run from anywhere (see assets/branding/README.md):
    nix shell --impure --expr 'with import <nixpkgs> {}; python3.withPackages (p: [p.pillow p.numpy])' \
      --command python3 tool/branding/generate.py
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
BRANDING = ROOT / "assets" / "branding"
RES = ROOT / "android" / "app" / "src" / "main" / "res"
WEB = ROOT / "web"

BRAND_RED = (0xB0, 0x02, 0x05)
WHITE = (255, 255, 255)

# Whiteness levels mapped to alpha 0..1. Red gradient pixels have min(R,G,B)
# below ~35; the paddles are slightly off-white (~245).
LOW, HIGH = 35.0, 245.0

SS = 4  # supersampling factor for geometric masks


def load_artwork():
    rgb = np.asarray(Image.open(BRANDING / "source.png").convert("RGB"))
    whiteness = rgb.min(axis=2).astype(np.float32)
    alpha = np.clip((whiteness - LOW) / (HIGH - LOW), 0.0, 1.0)
    ys, xs = np.nonzero(alpha > 0.05)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    alpha = alpha[y0:y1, x0:x1]
    h, w = alpha.shape
    # Farthest visible pixel from the bounding-box centre drives radial fits.
    yy, xx = np.nonzero(alpha > 0.1)
    radius = float(np.hypot(xx - (w - 1) / 2, yy - (h - 1) / 2).max())
    img = Image.fromarray((alpha * 255).round().astype(np.uint8), "L")
    return img, radius


ART, ART_RADIUS = load_artwork()


def art_mask(size, radius_frac):
    """White-artwork alpha on a size x size canvas.

    The farthest artwork pixel from the canvas centre sits at
    radius_frac * size, so the artwork fits a circle of that radius.
    """
    k = radius_frac * size / ART_RADIUS
    w, h = ART.size
    scaled = ART.resize((max(1, round(w * k)), max(1, round(h * k))), Image.LANCZOS)
    canvas = Image.new("L", (size, size), 0)
    canvas.paste(scaled, ((size - scaled.width) // 2, (size - scaled.height) // 2))
    return canvas


def shape_mask(size, shape):
    big = size * SS
    m = Image.new("L", (big, big), 0)
    d = ImageDraw.Draw(m)
    if shape == "circle":
        d.ellipse((0, 0, big - 1, big - 1), fill=255)
    elif shape == "rounded":
        d.rounded_rectangle((0, 0, big - 1, big - 1), radius=round(big * 0.22), fill=255)
    else:
        raise ValueError(shape)
    return m.resize((size, size), Image.LANCZOS)


def flat(size, color):
    return Image.new("RGB", (size, size), color)


def opaque(size, radius_frac):
    """Full-bleed red square with white artwork."""
    return Image.composite(flat(size, WHITE), flat(size, BRAND_RED), art_mask(size, radius_frac))


def shaped(size, radius_frac, shape, inset=1.0):
    """Red shape (circle/rounded square) with white artwork, transparent outside."""
    base = opaque(size, radius_frac).convert("RGBA")
    mask = shape_mask(size, shape)
    if inset != 1.0:
        inner = round(size * inset)
        small = shape_mask(inner, shape)
        mask = Image.new("L", (size, size), 0)
        mask.paste(small, ((size - inner) // 2, (size - inner) // 2))
        base = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        art = opaque(inner, radius_frac / inset).convert("RGBA")
        base.paste(art, ((size - inner) // 2, (size - inner) // 2))
    base.putalpha(mask)
    return base


def transparent_art(size, radius_frac, color):
    img = Image.new("RGBA", (size, size), color + (0,))
    img.putalpha(art_mask(size, radius_frac))
    return img


def save(img, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)
    print("wrote", path.relative_to(ROOT), img.size, img.mode)


# Fractions of the canvas, measured to the farthest artwork pixel.
FULL = 0.45  # full-bleed square: fits inside a circular mask touching the edges
ROUND = 0.40
LEGACY = 0.42
SAFE_ADAPTIVE = 33 / 108  # Android adaptive icon safe zone (66dp circle in 108dp)
SAFE_MASKABLE = 0.40  # W3C maskable safe zone (circle with 80% diameter)
SPLASH_CIRCLE = 2 / 3  # Android 12 splash icon: visible circle is 2/3 of the canvas

# 1. Master assets in assets/branding
save(opaque(1024, FULL), BRANDING / "app_icon.png")
save(transparent_art(1024, SAFE_ADAPTIVE, WHITE), BRANDING / "app_icon_foreground.png")
save(transparent_art(1024, SAFE_ADAPTIVE, (0, 0, 0)), BRANDING / "app_icon_monochrome.png")
save(shaped(1024, ROUND, "circle"), BRANDING / "app_icon_round.png")
splash = shaped(1152, SPLASH_CIRCLE * 0.44, "circle", inset=SPLASH_CIRCLE)
save(splash, BRANDING / "splash_icon.png")
save(opaque(512, FULL).convert("RGBA"), BRANDING / "play-store-icon-512.png")

# 2. Android legacy launcher icons (pre API 26)
for density, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
    save(shaped(px, LEGACY, "rounded"), RES / f"mipmap-{density}" / "ic_launcher.png")
    save(shaped(px, ROUND, "circle"), RES / f"mipmap-{density}" / "ic_launcher_round.png")

# 3. Android adaptive layers (108dp)
for density, px in {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}.items():
    save(transparent_art(px, SAFE_ADAPTIVE, WHITE), RES / f"mipmap-{density}" / "ic_launcher_foreground.png")
    save(transparent_art(px, SAFE_ADAPTIVE, (0, 0, 0)), RES / f"mipmap-{density}" / "ic_launcher_monochrome.png")

# 4. Android splash icons (288dp canvas)
for density, px in {"mdpi": 288, "hdpi": 432, "xhdpi": 576, "xxhdpi": 864, "xxxhdpi": 1152}.items():
    save(shaped(px, SPLASH_CIRCLE * 0.44, "circle", inset=SPLASH_CIRCLE), RES / f"drawable-{density}" / "splash_icon.png")

# 5. Web icons
save(shaped(64, LEGACY, "rounded"), WEB / "favicon.png")
save(opaque(192, FULL), WEB / "icons" / "Icon-192.png")
save(opaque(512, FULL), WEB / "icons" / "Icon-512.png")
save(opaque(192, SAFE_MASKABLE), WEB / "icons" / "Icon-maskable-192.png")
save(opaque(512, SAFE_MASKABLE), WEB / "icons" / "Icon-maskable-512.png")
save(shaped(256, ROUND, "circle"), WEB / "icons" / "splash-icon.png")
