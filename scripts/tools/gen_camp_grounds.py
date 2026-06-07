# Generator for the larger camp map (square ~52x52).
#   - south = the player emerges from the (off-map) summoning room into a CAMP:
#     a gathering commons + fire pit, a dirt RING ROAD around it, tents encircling.
#   - a street north to a WIDE fenced sparring arena; all 3 raid entrances on the
#     NORTH wall, aligned to forest clearings (three attack lanes).
#   - deep forest on top. Big trees are 3x3 objects placed ORGANICALLY (random +
#     no-overlap rejection) so they cluster and vary instead of gridding.
# Run: python scripts/tools/gen_camp_grounds.py
import math, random

W, H = 52, 52
OUT = "data/maps/camp_grounds.map"
rng = random.Random(11)
g = [['.' for _ in range(W)] for _ in range(H)]

def inb(x, y): return 0 <= x < W and 0 <= y < H
def setc(x, y, ch):
    if inb(x, y): g[y][x] = ch
def rect(x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            setc(x, y, ch)

LANES = [16, 26, 36]                    # forest clearing == north-gate columns
MAXD = 15

# ------------------------------------------------------- FOREST (organic, top)
def tdepth(x): return 11 + 3 * math.sin(x * 0.42) + 2 * math.sin(x * 0.17)
trees = []
def overlaps(x, y):                     # 3x3 footprints overlap iff both gaps < 3
    return any(abs(x - tx) < 3 and abs(y - ty) < 3 for (tx, ty) in trees)
attempts = 0
while attempts < 9000 and len(trees) < 90:
    attempts += 1
    x = rng.randint(0, W - 3); y = rng.randint(0, MAXD - 2)
    if y > tdepth(x):                                   # ragged southern edge
        continue
    if any(abs((x + 1) - c) <= 2 for c in LANES) and y >= 6:
        continue                                        # keep the lower lanes open
    # dense up top, thinning toward the ragged edge
    if rng.random() > (1.0 - 0.35 * (y / MAXD)):
        continue
    if overlaps(x, y):
        continue
    trees.append((x, y)); setc(x, y, 'T')
# single-tile trees soften the edge + fill gaps (walkable)
for x in range(W):
    if any(abs(x - c) <= 2 for c in LANES):
        continue
    y = int(tdepth(x)) + rng.randint(0, 3)
    if rng.random() < 0.55: setc(x, min(y, MAXD), 't')
for _ in range(26):
    setc(rng.randint(0, W - 1), rng.randint(0, MAXD - 1), 't')
for cx in LANES:
    setc(cx, 12, 'E'); setc(cx + 1, 13, 'E')

# ---------------------------------------------------- WIDE SPARRING ARENA (pen)
ax0, ay0, ax1, ay1 = 8, 17, 43, 31
for x in range(ax0, ax1 + 1): setc(x, ay0, '#'); setc(x, ay1, '#')
for y in range(ay0, ay1 + 1): setc(ax0, y, '#'); setc(ax1, y, '#')
rect(ax0 + 1, ay0 + 1, ax1 - 1, ay1 - 1, 'g')
for cx in LANES:                                        # 3 north breaches
    setc(cx, ay0, 'g'); setc(cx + 1, ay0, 'g')
for x in (25, 26): setc(x, ay1, 'g')                   # south street approach
rect(22, 22, 29, 26, 'o')                              # centered spar pad
g[23][23] = '5'; g[23][25] = '6'; g[23][27] = '7'
g[29][16] = '1'; g[29][26] = '2'; g[29][36] = '3'

# ------------------------------------------------------------- SOUTH CAMP -----
rect(25, 32, 26, 35, ',')                              # street down from the arena
RN, RS, RW, RE = 35, 47, 14, 37                        # dirt RING ROAD loop
for x in range(RW, RE + 1): setc(x, RN, ','); setc(x, RS, ',')
for y in range(RN, RS + 1): setc(RW, y, ','); setc(RE, y, ',')
rect(24, 40, 27, 43, ',')                              # worn commons + fire pit
rect(25, 41, 26, 42, 'o')
rect(25, 47, 26, 52, ',')                              # entry road south to the edge
rect(24, 51, 27, 51, ',')
g[51][25] = 'P'

def tent(x0, y0, w, h): rect(x0, y0, x0 + w - 1, y0 + h - 1, 'B')
# tents ringing the camp (outside the road), varied, not mirrored
tent(2, 36, 6, 4); tent(3, 43, 5, 5); tent(2, 49, 6, 3); tent(9, 39, 4, 4)
tent(44, 36, 6, 4); tent(45, 43, 5, 4); tent(43, 49, 6, 3); tent(40, 40, 3, 5)
# supply crates + a few trees inside the camp
for (cxx, cyy) in [(17, 37), (34, 45), (33, 37), (16, 44), (20, 49), (31, 49)]:
    rect(cxx, cyy, cxx + 1, cyy + 1, 'B')
for (tx, ty) in [(11, 38), (40, 39), (15, 50), (36, 50), (19, 45), (32, 38), (28, 48)]:
    setc(tx, ty, 't')

with open(OUT, "w", encoding="utf-8") as f:
    f.write("name:  Camp Grounds\n")
    f.write("theme: camp\n")
    f.write("notes: ~52x52. South = emerge from the (off-map) summoning room into a CAMP "
            "(commons + fire pit, dirt ring road, encircling tents); street north to a WIDE "
            "sparring arena, all 3 raid entrances on the north wall (forest-clearing lanes); "
            "deep forest on top, organic non-overlapping 3x3 trees.\n")
    f.write("---\n")
    for row in g:
        f.write("".join(row) + "\n")
print("wrote", OUT, f"({W}x{H}) trees={len(trees)}")
