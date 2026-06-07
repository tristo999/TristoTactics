# Generator for the larger camp map (square ~52x52).
#   - south = a SOLID WALL (the summoning room's front); the player walks out a
#     doorway into the camp. The room itself is off-map behind the wall.
#   - a CAMP: gathering commons + fire pit, dirt RING ROAD, encircling tents.
#   - a street north to a WIDE sparring arena; 3 raid entrances on the NORTH wall
#     aligned to forest clearings (three lanes).
#   - deep forest on top; big 3x3 trees placed organically, no overlap.
# Emits TWO grids: terrain, then "---", then a SPAWN OVERLAY (so spawns layer on
# top of terrain -- a unit can spawn on the stone pad without erasing it).
# Run: python scripts/tools/gen_camp_grounds.py
import math, random

W, H = 52, 52
OUT = "data/maps/camp_grounds.map"
rng = random.Random(11)
g = [['.' for _ in range(W)] for _ in range(H)]   # terrain
s = [[' ' for _ in range(W)] for _ in range(H)]   # spawn overlay (space = none)

def inb(x, y): return 0 <= x < W and 0 <= y < H
def setc(x, y, ch):
    if inb(x, y): g[y][x] = ch
def seto(x, y, ch):
    if inb(x, y): s[y][x] = ch
def rect(x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            setc(x, y, ch)

LANES = [16, 26, 36]
MAXD = 15

# ------------------------------------------------------- FOREST (organic, top)
def tdepth(x): return 11 + 3 * math.sin(x * 0.42) + 2 * math.sin(x * 0.17)
trees = []
def overlaps(x, y):
    return any(abs(x - tx) < 3 and abs(y - ty) < 3 for (tx, ty) in trees)
attempts = 0
while attempts < 9000 and len(trees) < 90:
    attempts += 1
    x = rng.randint(0, W - 3); y = rng.randint(0, MAXD - 2)
    if y > tdepth(x): continue
    if any(abs((x + 1) - c) <= 2 for c in LANES) and y >= 6: continue
    if rng.random() > (1.0 - 0.35 * (y / MAXD)): continue
    if overlaps(x, y): continue
    trees.append((x, y)); setc(x, y, 'T')
for x in range(W):
    if any(abs(x - c) <= 2 for c in LANES): continue
    y = int(tdepth(x)) + rng.randint(0, 3)
    if rng.random() < 0.55: setc(x, min(y, MAXD), 't')
for _ in range(26):
    setc(rng.randint(0, W - 1), rng.randint(0, MAXD - 1), 't')
for cx in LANES:                                       # raid spawns (overlay)
    seto(cx, 12, 'E'); seto(cx + 1, 13, 'E')

# ---------------------------------------------------- WIDE SPARRING ARENA (pen)
ax0, ay0, ax1, ay1 = 8, 17, 43, 31
for x in range(ax0, ax1 + 1): setc(x, ay0, '#'); setc(x, ay1, '#')
for y in range(ay0, ay1 + 1): setc(ax0, y, '#'); setc(ax1, y, '#')
rect(ax0 + 1, ay0 + 1, ax1 - 1, ay1 - 1, 'g')
for cx in LANES:
    setc(cx, ay0, 'g'); setc(cx + 1, ay0, 'g')
for x in (25, 26): setc(x, ay1, 'g')
rect(22, 22, 29, 26, 'o')                              # solid spar pad (stays whole)
# spar formation ON the pad (overlay -> no holes): partners vs squad
seto(23, 23, '5'); seto(25, 23, '6'); seto(27, 23, '7')    # partners (allies)
seto(23, 25, '1'); seto(25, 25, '2'); seto(27, 25, '3')    # squad (players)

# ------------------------------------------------------------- SOUTH CAMP -----
rect(25, 32, 26, 34, ',')                              # street down from the arena
RN, RS, RW, RE = 35, 47, 14, 37                        # dirt RING ROAD loop
for x in range(RW, RE + 1): setc(x, RN, ','); setc(x, RS, ',')
for y in range(RN, RS + 1): setc(RW, y, ','); setc(RE, y, ',')
rect(24, 40, 27, 43, ',')                              # worn commons + fire pit
rect(25, 41, 26, 42, 'o')
rect(25, 48, 26, 49, ',')                              # path from the door to the ring

def tent(x0, y0, w, h): rect(x0, y0, x0 + w - 1, y0 + h - 1, 'B')
tent(2, 36, 6, 4); tent(2, 42, 5, 4); tent(9, 38, 4, 4); tent(7, 47, 5, 2)   # west
tent(44, 36, 6, 4); tent(45, 42, 5, 4); tent(40, 40, 3, 5); tent(40, 47, 5, 2)  # east
for (cxx, cyy) in [(17, 37), (34, 45), (33, 37), (16, 44)]:
    rect(cxx, cyy, cxx + 1, cyy + 1, 'B')              # supply crates
for (tx, ty) in [(11, 44), (40, 39), (19, 46), (32, 38), (21, 36), (31, 46)]:
    setc(tx, ty, 't')

# ---- SOUTH WALL: the camp's edge. Only the wall shows; the hero walks up
# through the doorway from OFF-SCREEN below (spawned off-map by the scene). ----
rect(0, 50, W - 1, 51, 'B')                            # solid wall across the south
rect(25, 50, 26, 51, ',')                              # doorway through the wall
seto(25, 50, 'P')                                      # spawn marker at the door

# ---------------------------------------------------------------- write it out
with open(OUT, "w", encoding="utf-8") as f:
    f.write("name:  Camp Grounds\n")
    f.write("theme: camp\n")
    f.write("notes: ~52x52. South EDGE is a solid wall (the summoning room's front); player "
            "walks out the doorway into a CAMP (commons + fire pit, dirt ring road, tents); "
            "street north to a WIDE sparring arena (3 raid lanes on the north wall); deep forest "
            "on top. TWO grids: terrain then '---' then a SPAWN OVERLAY (spawns layer on terrain).\n")
    f.write("---\n")
    for row in g:
        f.write("".join(row) + "\n")
    f.write("---\n")
    for row in s:
        f.write("".join(row).rstrip() + "\n")
print("wrote", OUT, f"({W}x{H}) trees={len(trees)}")
