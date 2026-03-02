"""
Recolor the Chris Walk sprite sheet to create archer_walk.png and goblin_walk.png
using the same hue-shift values as recolor_sprites.py.
"""
from PIL import Image
import colorsys
import os

def hue_shift(image, shift, sat_mult=1.0, val_mult=1.0):
    img = image.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            rn, gn, bn = r / 255.0, g / 255.0, b / 255.0
            h_val, s, v = colorsys.rgb_to_hsv(rn, gn, bn)
            h_val = (h_val + shift) % 1.0
            s = min(1.0, s * sat_mult)
            v = min(1.0, v * val_mult)
            rn, gn, bn = colorsys.hsv_to_rgb(h_val, s, v)
            pixels[x, y] = (int(rn * 255), int(gn * 255), int(bn * 255), a)
    return img

def main():
    src_path = os.path.join(
        os.path.dirname(__file__), "..",
        "assets", "test", "World of Solaria Demo Pack Update 04",
        "16x16", "Sprites", "New", "Chris Walk.png"
    )
    dst_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites", "characters")
    os.makedirs(dst_dir, exist_ok=True)
    src_img = Image.open(src_path)

    # Same shifts as recolor_sprites.py
    # Green Goblin: shift=0.30, sat_mult=1.3, val_mult=0.95
    green = hue_shift(src_img, shift=0.30, sat_mult=1.3, val_mult=0.95)
    green_path = os.path.join(dst_dir, "goblin_walk.png")
    green.save(green_path)
    print(f"Saved: {green_path}")

    # Red Archer: shift=0.95, sat_mult=1.4, val_mult=1.0
    red = hue_shift(src_img, shift=0.95, sat_mult=1.4, val_mult=1.0)
    red_path = os.path.join(dst_dir, "archer_walk.png")
    red.save(red_path)
    print(f"Saved: {red_path}")

if __name__ == "__main__":
    main()
