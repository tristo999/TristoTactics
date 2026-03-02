"""
Recolor the Chris Idle and Chris Walk sprite sheets to create blue Lyra variants.
Uses the same hue-shift approach as recolor_sprites.py / recolor_walk.py.
"""
from PIL import Image
import colorsys
import os

# Blue hue shift: ~0.55 from base, boost saturation slightly
LYRA_HUE_SHIFT = 0.55
LYRA_SAT_MULT = 1.3
LYRA_VAL_MULT = 1.0

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
    base_dir = os.path.join(os.path.dirname(__file__), "..")
    sprite_src = os.path.join(
        base_dir, "assets", "test",
        "World of Solaria Demo Pack Update 04",
        "16x16", "Sprites", "New"
    )
    dst_dir = os.path.join(base_dir, "assets", "sprites", "characters")
    os.makedirs(dst_dir, exist_ok=True)

    # Idle sheet
    idle_src = os.path.join(sprite_src, "Chris Idle.png")
    idle_img = Image.open(idle_src)
    lyra_idle = hue_shift(idle_img, LYRA_HUE_SHIFT, LYRA_SAT_MULT, LYRA_VAL_MULT)
    idle_path = os.path.join(dst_dir, "lyra_idle.png")
    lyra_idle.save(idle_path)
    print(f"Saved: {idle_path}")

    # Walk sheet
    walk_src = os.path.join(sprite_src, "Chris Walk.png")
    walk_img = Image.open(walk_src)
    lyra_walk = hue_shift(walk_img, LYRA_HUE_SHIFT, LYRA_SAT_MULT, LYRA_VAL_MULT)
    walk_path = os.path.join(dst_dir, "lyra_walk.png")
    lyra_walk.save(walk_path)
    print(f"Saved: {walk_path}")

if __name__ == "__main__":
    main()
