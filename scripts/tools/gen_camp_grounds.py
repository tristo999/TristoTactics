# Generator for the larger camp map.
#   - south = the player emerges from the (off-map) summoning room, into a real
#     CAMP: a gathering commons with a central fire pit, a dirt RING ROAD around
#     it, and tents encircling it.
#   - a street north to a WIDE fenced sparring arena; all 3 raid entrances on the
#     NORTH wall, aligned to forest clearings (three attack lanes).
#   - deep, ragged forest on top. Big trees are clean 3x3 objects, NO overlap.
# Emits the role chars MapLoader understands; fence/tree autotiling is at load.
# Run: python scripts/tools/gen_camp_grounds.py
import math, random

W, H = 42, 52
OUT = "data/maps/camp_grounds.map"
rng = random.Random(7)
g = [['.' for _ in range(W)] for _ in range(H)]

def inb(x, y): return 0 <= x < W and 0 <= y < H
def setc(x, y, ch):
    if inb(x, y): g[y][x] = ch
def rect(x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            setc(x, y, ch)
def tree3(cx, cy):                      # 3x3 tree on a strict grid -> no overlap
    if 0 <= cx <= W - 3 and 0 <= cy <= H - 3: setc(cx, cy, 'T')

LANES = [11, 20, 29]                    # forest clearing == north-gate columns

# ---------------------------------------------------------------- FOREST (top)
MAXD = 14
def tdepth(cx): return 9 + 3 * math.sin(cx * 0.5) + 1.5 * math.sin(cx * 0.23)
# big trees on a strict 3-grid (origins 3 apart => footprints never overlap)
for cy in range(0, MAXD - 1, 3):
    for cx in range(0, W - 2, 3):
        if any(abs((cx + 1) - c) <= 3 for c in LANES) and cy >= 6:
            continue                    # keep the lower lanes open (raid funnels)
        if cy > tdepth(cx):
            continue
        if rng.random() < 0.9:
            tree3(cx, cy)
# single-tile trees soften the ragged southern edge + light scatter (walkable)
for x in range(W):
    if any(abs(x - c) <= 2 for c in LANES):
        continue
    y = int(tdepth(x)) + rng.randint(0, 3)
    if rng.random() < 0.5: setc(x, min(y, MAXD), 't')
for _ in range(16):
    setc(rng.randint(0, W - 1), rng.randint(0, MAXD - 1), 't')
for cx in LANES:                        # raid spawns, one cluster per lane
    setc(cx, 12, 'E'); setc(cx + 1, 13, 'E')

# ---------------------------------------------------- WIDE SPARRING ARENA (pen)
ax0, ay0, ax1, ay1 = 6, 16, 35, 30
for x in range(ax0, ax1 + 1): setc(x, ay0, '#'); setc(x, ay1, '#')
for y in range(ay0, ay1 + 1): setc(ax0, y, '#'); setc(ax1, y, '#')
rect(ax0 + 1, ay0 + 1, ax1 - 1, ay1 - 1, 'g')
for cx in LANES:                                        # 3 north breaches
    setc(cx, ay0, 'g'); setc(cx + 1, ay0, 'g')
for x in (20, 21): setc(x, ay1, 'g')                   # south street approach
rect(17, 21, 24, 25, 'o')                              # centered spar pad
g[22][18] = '5'; g[22][20] = '6'; g[22][22] = '7'
g[28][12] = '1'; g[28][20] = '2'; g[28][28] = '3'

# ------------------------------------------------------------- SOUTH CAMP -----
# street from the arena down into the camp
rect(20, 31, 21, 34, ',')
# RING ROAD (dirt loop) around the gathering commons
RN, RS, RW, RE = 34, 46, 9, 32
for x in range(RW, RE + 1): setc(x, RN, ','); setc(x, RS, ',')
for y in range(RN, RS + 1): setc(RW, y, ','); setc(RE, y, ',')
# central gathering commons: a worn dirt patch + stone fire pit
rect(19, 39, 22, 42, ',')
rect(20, 40, 21, 41, 'o')
# entry road south out of the ring to the map edge (where the player walks in)
rect(20, 46, 21, 51, ',')
rect(19, 50, 22, 51, ',')
g[51][20] = 'P'

def tent(x0, y0, w, h): rect(x0, y0, x0 + w - 1, y0 + h - 1, 'B')
# tents ringing the camp (outside the road), varied sizes, not mirrored
tent(1, 35, 6, 4); tent(1, 42, 5, 4); tent(2, 48, 5, 3)          # west flank
tent(34, 35, 6, 4); tent(35, 42, 5, 4); tent(33, 48, 6, 3)       # east flank
# supply crates (small) + a couple of trees for greenery inside the camp
for (cxx, cyy) in [(12, 36), (29, 44), (28, 36), (11, 43)]:
    rect(cxx, cyy, cxx + 1, cyy + 1, 'B')
for (tx, ty) in [(7, 37), (34, 40), (10, 49), (31, 50), (14, 44), (27, 38)]:
    setc(tx, ty, 't')

with open(OUT, "w", encoding="utf-8") as f:
    f.write("name:  Camp Grounds\n")
    f.write("theme: camp\n")
    f.write("notes: South = emerge from the (off-map) summoning room into a CAMP "
            "(gathering commons + fire pit, dirt ring road, encircling tents); street north "
            "to a WIDE sparring arena, all 3 raid entrances on the north wall (aligned to "
            "forest clearings = three lanes); deep ragged forest on top (non-overlapping 3x3 trees).\n")
    f.write("---\n")
    for row in g:
        f.write("".join(row) + "\n")
print("wrote", OUT, f"({W}x{H})")
