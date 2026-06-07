# Generator for the larger camp map.
#   - south EDGE = where the player emerges from the (off-map) summoning room
#   - main street north to a big fenced sparring arena (3 enemy entrances)
#   - DEEP, ragged, varied forest across the top (raid source)
#   - big tent footprints (placeholder) + open yards flanking
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
def tree3(x, y):                      # 3x3 tree origin
    if 0 <= x < W - 2 and 0 <= y < H - 2: setc(x, y, 'T')

# ---------------------------------------------------------------- FOREST (top)
# Deep band with a RAGGED southern treeline (noise-driven depth per column) and
# a mix of 3x3 trees (T) + single-tile cover (t). Two clearings the raid uses.
MAXD = 14                              # forest never reaches the arena (row 16)
clearings = [13, 29]                   # column centers where the woods open
def treeline(x):                       # ragged depth at column x
    d = 9 + 3 * math.sin(x * 0.55) + 2 * math.sin(x * 0.21)
    return int(d) + rng.randint(-1, 2)
# 3x3 trees on a jittered 3-grid, gated by the per-column treeline
for cy in range(0, MAXD, 3):
    for cx in range(0, W - 1, 3):
        if any(abs(cx - c) <= 3 for c in clearings) and cy >= 5:
            continue                   # keep clearings open lower down
        if cy > treeline(cx):
            continue
        if rng.random() < 0.88:
            tree3(min(cx + rng.randint(-1, 1), W - 3), max(cy + rng.randint(-1, 1), 0))
# single-tree fringe softening the ragged edge + scatter inside
for x in range(W):
    if any(abs(x - c) <= 2 for c in clearings):
        continue
    for _ in range(2):
        y = treeline(x) + rng.randint(-1, 3)
        if rng.random() < 0.5: setc(x, min(y, MAXD + 1), 't')
for _ in range(22):
    setc(rng.randint(0, W - 1), rng.randint(0, MAXD), 't')
# raid spawns in/below the clearings
for (ex, ey) in [(13, 12), (29, 12), (13, 14), (29, 14)]:
    setc(ex, ey, 'E')

# --------------------------------------------------------- SPARRING ARENA (big)
ax0, ay0, ax1, ay1 = 11, 16, 30, 30
for x in range(ax0, ax1 + 1): setc(x, ay0, '#'); setc(x, ay1, '#')
for y in range(ay0, ay1 + 1): setc(ax0, y, '#'); setc(ax1, y, '#')
rect(ax0 + 1, ay0 + 1, ax1 - 1, ay1 - 1, 'g')      # interior closes the fence
# three ENEMY entrances (N breach + W + E flanks) + the S street approach
for x in (20, 21): setc(x, ay0, 'g')               # N breach (from forest)
for x in (20, 21): setc(x, ay1, 'g')               # S approach (street/player)
for y in (22, 23): setc(ax0, y, 'g'); setc(ax1, y, 'g')   # W + E flank gates
rect(18, 21, 23, 24, 'o')                          # stone spar pad
g[22][19] = '5'; g[22][21] = '6'; g[22][23] = '7'  # partners on the pad
g[27][15] = '1'; g[27][20] = '2'; g[27][25] = '3'  # squad forming up

# ----------------------------------------------------------- MAIN STREET + camp
for y in range(31, 38):                            # dirt street south from S gate
    g[y][20] = ','; g[y][21] = ','

def tent(x0, y0, w, h):                             # big placeholder object (>tree)
    rect(x0, y0, x0 + w - 1, y0 + h - 1, 'B')
# tents bigger than the 3x3 trees, in the yards + flanking the street
tent(3, 21, 6, 5)
tent(33, 21, 6, 5)
tent(4, 32, 5, 4)
tent(33, 33, 6, 4)
tent(13, 33, 5, 4)
tent(25, 33, 5, 4)

# ----------------------------------------------------- SOUTH ENTRY (no building)
# The summoning room is the PREVIOUS scene; the player walks in from the edge.
rect(19, 38, 22, 39, ',')                          # threshold / packed earth
g[38][20] = 'P'

with open(OUT, "w", encoding="utf-8") as f:
    f.write("name:  Camp Grounds\n")
    f.write("theme: camp\n")
    f.write("notes: Larger camp. South edge = emerge from the (off-map) summoning room; "
            "main street -> big fenced sparring arena (3 enemy entrances N/E/W + S approach); "
            "deep ragged forest on top (raid source); big tent placeholders + open yards.\n")
    f.write("---\n")
    for row in g:
        f.write("".join(row) + "\n")
print("wrote", OUT, f"({W}x{H})")
