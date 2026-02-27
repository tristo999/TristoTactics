"""
Recolor a sprite sheet by shifting its hue while preserving transparency.
Creates green (Goblin) and red (Archer) variants of the source sprite.
"""
from PIL import Image
import colorsys
import os
import argparse

def parse_args():
    parser = argparse.ArgumentParser(description="Recolor a sprite sheet by hue-shifting.")
    parser.add_argument("src", help="Path to the source sprite PNG file")
    parser.add_argument(
        "--dst-dir",
        default=os.path.join(os.path.dirname(__file__), "..", "assets", "sprites", "characters"),
        help="Destination directory for recolored sprites (default: assets/sprites/characters relative to project root)",
    )
    return parser.parse_args()

def hue_shift(image: Image.Image, shift: float, sat_mult: float = 1.0, val_mult: float = 1.0) -> Image.Image:
    """
    Shift the hue of every non-transparent pixel by `shift` (0.0–1.0).
    Optionally scale saturation and value.
    """
    img = image.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            # Normalize to 0-1
            rn, gn, bn = r / 255.0, g / 255.0, b / 255.0
            h_val, s, v = colorsys.rgb_to_hsv(rn, gn, bn)
            # Shift hue, scale sat/val
            h_val = (h_val + shift) % 1.0
            s = min(1.0, s * sat_mult)
            v = min(1.0, v * val_mult)
            rn, gn, bn = colorsys.hsv_to_rgb(h_val, s, v)
            pixels[x, y] = (int(rn * 255), int(gn * 255), int(bn * 255), a)
    return img

def main():
    args = parse_args()
    src = args.src
    dst_dir = os.path.abspath(args.dst_dir)
    os.makedirs(dst_dir, exist_ok=True)
    src_img = Image.open(src)

    # Green Goblin: shift hue toward green (~+0.30), boost saturation slightly
    green = hue_shift(src_img, shift=0.30, sat_mult=1.3, val_mult=0.95)
    green_path = os.path.join(dst_dir, "goblin_idle.png")
    green.save(green_path)
    print(f"Saved green sprite: {green_path}")

    # Red Archer: shift hue toward red (~-0.05 / +0.95), boost saturation
    red = hue_shift(src_img, shift=0.95, sat_mult=1.4, val_mult=1.0)
    red_path = os.path.join(dst_dir, "archer_idle.png")
    red.save(red_path)
    print(f"Saved red sprite: {red_path}")

if __name__ == "__main__":
    main()
