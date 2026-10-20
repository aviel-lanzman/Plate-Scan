"""Frames raw phone screenshots into 1080x1920 Play Store images with a Hebrew caption.
Usage: frame_shots.py <out_dir> <raw.png> <caption> [<raw.png> <caption> ...]"""
import pathlib
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

out = pathlib.Path(sys.argv[1])
out.mkdir(parents=True, exist_ok=True)
pairs = list(zip(sys.argv[2::2], sys.argv[3::2]))

W, H = 1080, 1920
TOP, BOTTOM = (24, 74, 214), (8, 30, 102)
FONT = '/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf'  # Hebrew + digits
STATUS_BAR = 110  # px cropped from the top of a 1080-wide screenshot


def background():
    small = Image.new('RGB', (2, 64))
    for y in range(64):
        t = y / 63
        small.putpixel((0, y), tuple(int(a + (b - a) * t) for a, b in zip(TOP, BOTTOM)))
        small.putpixel((1, y), small.getpixel((0, y)))
    return small.resize((W, H), Image.BICUBIC).convert('RGBA')


for i, (raw, caption) in enumerate(pairs, 1):
    canvas = background()
    d = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(FONT, 64)
    lines = caption.split('\\n')
    y = 90
    for line in lines:
        d.text((W / 2, y), line, font=font, fill='white', anchor='ma', direction='rtl')
        y += 84

    shot = Image.open(raw).convert('RGBA')
    shot = shot.crop((0, STATUS_BAR, shot.width, shot.height))
    target_w = 860
    target_h = int(shot.height * target_w / shot.width)
    max_h = H - (y + 60) + 40
    shot = shot.resize((target_w, target_h), Image.LANCZOS)
    shot = shot.crop((0, 0, target_w, min(target_h, max_h)))

    mask = Image.new('L', shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, shot.width - 1, shot.height + 60], radius=36, fill=255)
    x0, y0 = (W - shot.width) // 2, y + 60

    shadow = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [x0 - 6, y0 - 6, x0 + shot.width + 6, y0 + shot.height + 80], radius=42, fill=(0, 0, 0, 140))
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(18)))
    canvas.paste(shot, (x0, y0), mask)

    path = out / f'{i:02d}.png'
    canvas.convert('RGB').save(path, optimize=True)
    print('wrote', path)
