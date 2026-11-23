# Branding assets

`source.png` is the supplied artwork (white heart/ECG/defibrillator paddles on a
red gradient rounded square with black corners). Everything else here and the
launcher/splash/web icons are generated from it by `tool/branding/generate.py`.

Brand red: `#B00205` (flat; the source gradient is dropped).

## Method

1. The white artwork becomes an alpha mask from `min(R, G, B)` (levels 35..245).
   Red and black map to transparent, so the red inside the lightning bolts and
   the heart stays negative space.
2. The mask is composited on flat brand red (opaque icons, splash circle) or kept
   transparent (adaptive foreground and monochrome layers).
3. Artwork is scaled so its farthest pixel stays inside the relevant safe zone:
   Android adaptive 66 dp circle of 108 dp, maskable PWA 80 % circle, Android 12
   splash 2/3 circle.

## Files

- `app_icon.png`: 1024 px, opaque red, white artwork. Also used in-app (see #109).
- `app_icon_foreground.png`: transparent white artwork, adaptive-icon safe zone.
- `app_icon_monochrome.png`: black alpha mask for Android 13 themed icons.
- `app_icon_round.png`: red circle with artwork.
- `splash_icon.png`: red circle (2/3 of canvas) with artwork, transparent canvas.
- `play-store-icon-512.png`: 512 px RGBA, full-bleed red, no pre-rounded corners.

Also written: Android `mipmap-*` and `drawable-*dpi/splash_icon.png`,
`web/favicon.png`, `web/icons/*`. The XML resources (`ic_launcher*.xml`,
`colors.xml`, `styles.xml`, `launch_background.xml`) and `web/index.html` are
hand-written. Splash backgrounds: light `#FFF8F6`, dark `#1C1B1F`.

## Regenerate

There is no Python in the dev shell; use an ad-hoc Nix shell from the repo root:

```bash
nix shell --impure --expr 'with import <nixpkgs> {}; python3.withPackages (p: [p.pillow p.numpy])' \
  --command python3 tool/branding/generate.py
```

If the brand red changes, also update `ic_launcher_background` in
`android/app/src/main/res/values/colors.xml` and the web `theme_color`.
