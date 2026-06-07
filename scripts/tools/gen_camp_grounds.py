# Generator for the larger camp map.
#   - south EDGE = where the player emerges from the (off-map) summoning room
#   - main street north to a WIDE fenced sparring arena
#   - all 3 raid entrances on the NORTH wall, aligned to forest clearings
#     (three attack lanes: forest clearing -> breach -> into the pen)
#   - deep, ragged, varied forest across the top; camp/tents south of the pen
# Emits the role chars MapLoader understands; fence/tree autotiling is at load.
# Run: python scripts/tools/gen_camp_grounds.py
import math, random

W, H = 42, 40
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
def tree3(x, y):
    if 0 <= x < W - 2 and 0 <= y < H - 2: setc(x, y, 'T')

# the three raid lanes — clearing columns == north-gate columns
LANES = [11, 20, 29]

# ---------------------------------------------------------------- FOREST (top)
MAXD = 14
def treeline(x):
    d = 9 + 3 * math.sin(x * 0.55) + 2 * math.sin(x * 0.21)
    return int(d) + rng.randint(-1, 2)
for cy in range(0, MAXD, 3):
    for cx in range(0, W - 1, 3):
        if any(abs(cx - c) <= 3 for c in LANES) and cy >= 5:
            continue                       # keep the lanes open lower down
        if cy > treeline(cx):
            continue
        if rng.random() < 0.88:
            tree3(min(cx + rng.randint(-1, 1), W - 3), max(cy + rng.randint(-1, 1), 0))
for x in range(W):
    if any(abs(x - c) <= 2 for c in LANES):
        continue
    for _ in range(2):
        y = treeline(x) + rng.randint(-1, 3)
        if rng.random() < 0.5: setc(x, min(y, MAXD + 1), 't')
for _ in range(22):
    setc(rng.randint(0, W - 1), rng.randint(0, MAXD), 't')
# raid spawns sit in the clearings, one per lane
for cx in LANES:
    setc(cx, 12, 'E'); setc(cx, 14, 'E')

# ---------------------------------------------------- WIDE SPARRING ARENA (pen)
ax0, ay0, ax1, ay1 = 6, 16, 35, 30
for x in range(ax0, ax1 + 1): setc(x, ay0, '#'); setc(x, ay1, '#')
for y in range(ay0, ay1 + 1): setc(ax0, y, '#'); setc(ax1, y, '#')
rect(ax0 + 1, ay0 + 1, ax1 - 1, ay1 - 1, 'g')          # interior closes the fence
# THREE north entrances (raid), aligned to the lanes; + the south street approach
for cx in LANES:
    setc(cx, ay0, 'g'); setc(cx + 1, ay0, 'g')          # 2-tile breach per lane
for x in (20, 21): setc(x, ay1, 'g')                    # south street approach
rect(17, 21, 24, 25, 'o')                               # centered stone spar pad
g[22][18] = '5'; g[22][20] = '6'; g[22][22] = '7'       # partners on the pad
g[28][12] = '1'; g[28][20] = '2'; g[28][28] = '3'       # squad spread on the wide front

# ----------------------------------------------------- MAIN STREET + south camp
for y in range(31, 38):                                 # dirt street south from S gate
    g[y][20] = ','; g[y][21] = ','

def tent(x0, y0, w, h): rect(x0, y0, x0 + w - 1, y0 + h - 1, 'B')
# camp south of the pen, flanking the street — varied sizes, not mirrored
tent(3, 32, 6, 4)
tent(11, 33, 4, 5)
tent(2, 37, 5, 2)
tent(25, 32, 5, 5)
tent(31, 33, 7, 3)
tent(34, 37, 4, 2)
tent(15, 36, 3, 3)

# ----------------------------------------------------- SOUTH ENTRY (no building)
rect(19, 38, 22, 39, ',')                               # threshold / packed earth
g[38][20] = 'P'

with open(OUT, "w", encoding="utf-8") as f:
    f.write("name:  Camp Grounds\n")
    f.write("theme: camp\n")
    f.write("notes: Larger camp. South edge = emerge from the (off-map) summoning room; "
            "main street -> WIDE fenced sparring arena with all 3 raid entrances on the "
            "north wall (aligned to forest clearings = three attack lanes) + a south street "
            "approach; deep ragged forest on top; camp/tents south of the pen.\n")
    f.write("---\n")
    for row in g:
        f.write("".join(row) + "\n")
print("wrote", OUT, f"({W}x{H})")
