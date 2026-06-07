# Generates the two SIBLING training-arena maps (same geometry, the collision
# idea at small scale):
#   - arena_drill.map : the SPAR. North fence INTACT; partners 5/6/7 vs squad
#     1/2/3 on the pad; no enemies. Used by the scripted tutorial scene.
#   - arena_raid.map  : the RAID. Same arena, north BREACHED (3 lanes aligned to
#     forest clearings); squad + allies defend, insurgents pour in. True battle.
# Matches the camp_grounds yard style (wide pen, 3 north breaches) for continuity
# with the arrival cutscene. Emits terrain + a SPAWN OVERLAY per map.
# Run: python scripts/tools/gen_training_arena.py
import random

W, H = 40, 30
LANES = [11, 20, 29]                 # north gates / forest clearings (map cols)
AX0, AY0, AX1, AY1 = 4, 6, 35, 22    # arena fence rect
PAD = (16, 12, 23, 16)               # stone spar pad

def build(breached: bool):
    rng = random.Random(5)
    g = [['.' for _ in range(W)] for _ in range(H)]
    s = [[' ' for _ in range(W)] for _ in range(H)]

    def rect(x0, y0, x1, y1, ch):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if 0 <= x < W and 0 <= y < H:
                    g[y][x] = ch

    # --- forest strip on top (organic; clearings kept open at the lanes) ---
    trees = []
    def ov(x, y): return any(abs(x - tx) < 3 and abs(y - ty) < 3 for tx, ty in trees)
    att = 0
    while att < 2500 and len(trees) < 30:
        att += 1
        x = rng.randint(0, W - 3); y = rng.randint(0, 3)
        if any(abs((x + 1) - c) <= 2 for c in LANES):
            continue
        if ov(x, y):
            continue
        trees.append((x, y)); g[y][x] = 'T'
    for _ in range(12):
        x = rng.randint(0, W - 1); y = rng.randint(0, 4)
        if not any(abs(x - c) <= 2 for c in LANES):
            g[y][x] = 't'

    # --- arena fence + interior ---
    for x in range(AX0, AX1 + 1): g[AY0][x] = '#'; g[AY1][x] = '#'
    for y in range(AY0, AY1 + 1): g[y][AX0] = '#'; g[y][AX1] = '#'
    rect(AX0 + 1, AY0 + 1, AX1 - 1, AY1 - 1, 'g')
    g[AY1][19] = 'g'; g[AY1][20] = 'g'           # south gate (toward the camp)
    if breached:                                  # north breaches (raid only)
        for cx in LANES:
            g[AY0][cx] = 'g'; g[AY0][cx + 1] = 'g'
    rect(PAD[0], PAD[1], PAD[2], PAD[3], 'o')     # spar pad
    for y in range(AY1 + 1, H):                   # dirt approach off the south
        g[y][19] = ','; g[y][20] = ','

    # --- spawns (overlay) ---
    if breached:
        s[19][12] = '1'; s[19][20] = '2'; s[19][28] = '3'   # squad on the wide front
        s[17][16] = '5'; s[17][20] = '6'; s[17][24] = '7'   # allies just behind
        for cx in LANES:
            s[2][cx] = 'E'; s[3][cx + 1] = 'E'              # raid from the clearings
    else:
        s[13][17] = '5'; s[13][19] = '6'; s[13][21] = '7'   # partners, north of the pad
        s[15][17] = '1'; s[15][19] = '2'; s[15][21] = '3'   # squad, south of the pad
    return g, s

def write(path: str, g, s, note: str):
    with open(path, "w", encoding="utf-8") as f:
        f.write("name:  Training Arena\n")
        f.write("theme: camp\n")
        f.write("notes: " + note + "\n")
        f.write("---\n")
        for r in g: f.write("".join(r) + "\n")
        f.write("---\n")
        for r in s: f.write("".join(r).rstrip() + "\n")

gd, sd = build(False)
write("data/maps/arena_drill.map", gd, sd,
      "SPAR (scripted tutorial). North fence intact; partners 5/6/7 vs squad 1/2/3 on the pad; no enemies. Sibling of arena_raid.")
gr, sr = build(True)
write("data/maps/arena_raid.map", gr, sr,
      "RAID (true battle). Same arena, north breached on 3 lanes; squad 1/2/3 + allies 5/6/7 defend; insurgents from the forest. Sibling of arena_drill.")
print("wrote data/maps/arena_drill.map and data/maps/arena_raid.map (%dx%d)" % (W, H))
