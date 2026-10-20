"""Generates PlateScan icon and Play Store graphics. Usage: make_icons.py <project_root>"""
import pathlib
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

root = pathlib.Path(sys.argv[1])
icon_dir = root / 'assets/icon'
store_dir = root / 'store'
icon_dir.mkdir(parents=True, exist_ok=True)
store_dir.mkdir(parents=True, exist_ok=True)

SS = 4  # supersampling factor
BLUE_TOP = (24, 74, 214)
BLUE_BOTTOM = (8, 30, 102)
IL_BLUE = (0, 56, 184)
YELLOW = (255, 204, 0)
INK = (17, 17, 17)
RED = (255, 59, 48)
BOLD = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
HEB_BOLD = '/usr/share/fonts/truetype/noto/NotoSansHebrew-Bold.ttf'
HEB = '/usr/share/fonts/truetype/noto/NotoSansHebrew-Regular.ttf'


def gradient(w, h):
    img = Image.new('RGB', (w, h))
    px = img.load()
    for y in range(h):
        for x in range(w):
            t = (x / w * 0.35 + y / h * 0.65)
            px[x, y] = tuple(int(a + (b - a) * t) for a, b in zip(BLUE_TOP, BLUE_BOTTOM))
    return img


def gradient_fast(w, h):
    # Build at low resolution and upscale; the gradient is smooth anyway.
    return gradient(max(w // 16, 2), max(h // 16, 2)).resize((w, h), Image.BICUBIC)


def draw_mark(size, scale, mono=False):
    """Plate inside scan brackets on a transparent canvas of `size` (supersampled)."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = size / 2
    u = size / 1024 * scale  # 1 design unit

    white = (255, 255, 255, 255)
    clear = (0, 0, 0, 0)

    # Scan brackets around a 760x440 box.
    bw, bh, arm, stroke = 760 * u, 440 * u, 130 * u, 36 * u
    x0, y0, x1, y1 = c - bw / 2, c - bh / 2, c + bw / 2, c + bh / 2
    for (cx, cy, dx, dy) in [(x0, y0, 1, 1), (x1, y0, -1, 1), (x0, y1, 1, -1), (x1, y1, -1, -1)]:
        d.line([(cx, cy + dy * arm), (cx, cy), (cx + dx * arm, cy)], fill=white, width=int(stroke), joint='curve')
        for px, py in [(cx, cy + dy * arm), (cx + dx * arm, cy)]:
            r = stroke / 2
            d.ellipse([px - r, py - r, px + r, py + r], fill=white)
        r = stroke / 2
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=white)

    # Plate.
    pw, ph, rad, border = 600 * u, 210 * u, 30 * u, 14 * u
    px0, py0, px1, py1 = c - pw / 2, c - ph / 2, c + pw / 2, c + ph / 2
    strip = 118 * u
    if mono:
        d.rounded_rectangle([px0, py0, px1, py1], radius=rad, fill=white)
        d.rounded_rectangle([px0 + border, py0 + border, px0 + strip, py1 - border],
                            radius=rad * 0.5, fill=clear)
    else:
        d.rounded_rectangle([px0, py0, px1, py1], radius=rad, fill=INK)
        d.rounded_rectangle([px0 + border, py0 + border, px1 - border, py1 - border],
                            radius=rad * 0.6, fill=YELLOW)
        d.rounded_rectangle([px0 + border, py0 + border, px0 + strip, py1 - border],
                            radius=rad * 0.6, fill=IL_BLUE)
        d.rectangle([px0 + strip - rad, py0 + border, px0 + strip, py1 - border], fill=IL_BLUE)
        f = ImageFont.truetype(BOLD, int(54 * u))
        d.text(((px0 + border + px0 + strip) / 2, c), 'IL', font=f, fill=white, anchor='mm')

    # Plate digits.
    f = ImageFont.truetype(BOLD, int(118 * u))
    digits_cx = (px0 + strip + px1) / 2 - 4 * u
    d.text((digits_cx, c + 4 * u), '12·345', font=f, fill=clear if mono else INK, anchor='mm')

    # Scan line.
    if not mono:
        glow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        ly = c + 62 * u
        gd.rounded_rectangle([x0 + 40 * u, ly - 16 * u, x1 - 40 * u, ly + 16 * u], radius=16 * u, fill=RED + (150,))
        glow = glow.filter(ImageFilter.GaussianBlur(14 * u))
        img = Image.alpha_composite(img, glow)
        d = ImageDraw.Draw(img)
        d.rounded_rectangle([x0 + 40 * u, ly - 6 * u, x1 - 40 * u, ly + 6 * u], radius=6 * u, fill=RED + (255,))
    return img


def full_icon(px):
    big = px * SS
    bg = gradient_fast(big, big).convert('RGBA')
    icon = Image.alpha_composite(bg, draw_mark(big, 0.92))
    return icon.resize((px, px), Image.LANCZOS)


def save(img, path):
    img.save(path, optimize=True)
    print('wrote', path, img.size)


# App icon sources (flutter_launcher_icons input).
save(full_icon(1024).convert('RGB'), icon_dir / 'icon.png')
# Adaptive foreground: keep the mark inside the central 66/108 safe zone.
fg = draw_mark(1024 * SS, 0.70).resize((1024, 1024), Image.LANCZOS)
save(fg, icon_dir / 'icon_foreground.png')
save(gradient_fast(1024, 1024), icon_dir / 'icon_background.png')
mono = draw_mark(1024 * SS, 0.70, mono=True).resize((1024, 1024), Image.LANCZOS)
save(mono, icon_dir / 'icon_monochrome.png')

# Play Store icon: 512x512, full-bleed square (Play applies the mask).
save(full_icon(512).convert('RGB'), store_dir / 'play_icon_512.png')

# Feature graphic: 1024x500.
W, H = 1024, 500
fg_img = gradient_fast(W * SS, H * SS).convert('RGBA')
mark = draw_mark(int(H * SS * 1.25), 0.8)
fg_img.alpha_composite(mark, (int(250 * SS - mark.width / 2), int((H * SS - mark.height) / 2)))
d = ImageDraw.Draw(fg_img)
right = (W - 56) * SS
title = ImageFont.truetype(HEB_BOLD, 80 * SS)
sub = ImageFont.truetype(HEB, 38 * SS)
small = ImageFont.truetype(HEB, 28 * SS)
d.text((right, 150 * SS), 'סורק לוחיות', font=title, fill='white', anchor='ra', direction='rtl')
d.text((right, 275 * SS), 'בודק אם רכב ירד מהכביש', font=sub, fill='white', anchor='ra', direction='rtl')
d.text((right, 325 * SS), 'או דווח כגנוב', font=sub, fill='white', anchor='ra', direction='rtl')
# Noto Sans Hebrew has no bullet/bar glyphs, so draw the separators as dots.
x = right
gold = (255, 214, 64)
for i, phrase in enumerate(['חינם', 'בלי פרסומות', 'הזיהוי במכשיר']):
    if i:
        r = 4 * SS
        cy = 413 * SS
        d.ellipse([x - 18 * SS - r, cy - r, x - 18 * SS + r, cy + r], fill=gold)
        x -= 36 * SS
    d.text((x, 395 * SS), phrase, font=small, fill=gold, anchor='ra', direction='rtl')
    x -= d.textlength(phrase, font=small, direction='rtl')
save(fg_img.resize((W, H), Image.LANCZOS).convert('RGB'), store_dir / 'feature_graphic_1024x500.png')
