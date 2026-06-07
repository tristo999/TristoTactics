# Generator for the larger camp map: summoning (S) -> main street -> sparring
# arena (N), forest band on top, open yards flanking the summoning. Emits a role
# grid (the chars MapLoader understands); the fence/tree autotiling happens at
# load. Run: python scripts/tools/gen_camp_grounds.py
W, H = 36, 32
OUT = "data/maps/camp_grounds.map"

g = [['.' for _ in range(W)] for _ in range(H)]

def rect_fill(x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < W and 0 <= y < H:
                g[y][x] = ch

def tree(x, y):          # 3x3 tree origin
    if 0 <= x < W - 2 and 0 <= y < H - 2:
        g[y][x] = 'T'

# --- FOREST band (rows 0-5): dense 3x3 trees on a 3-grid, a few clearings ---
clearings = {(15, 0), (24, 0), (15, 3), (6, 3)}   # gaps the raid emerges from
for r in (0, 3):
    for c in range(0, W - 2, 3):
        if (c, r) in clearings:
            continue
        tree(c, r)
# raid spawns in/below the clearings
for (cx, cy) in [(16, 2), (25, 2), (7, 5), (16, 5)]:
    g[cy][cx] = 'E'

# --- SPARRING ARENA (fenced yard, rows 6-16, cols 11-24) ---
ax0, ay0, ax1, ay1 = 11, 6, 24, 16
# fence border
for x in range(ax0, ax1 + 1):
    g[ay0][x] = '#'; g[ay1][x] = '#'
for y in range(ay0, ay1 + 1):
    g[y][ax0] = '#'; g[y][ax1] = '#'
# interior = 'g' so the fence corners close
rect_fill(ax0 + 1, ay0 + 1, ax1 - 1, ay1 - 1, 'g')
# gates: north breach (toward forest) + south (toward the street)
for x in (17, 18):
    g[ay0][x] = 'g'   # north breach gap
    g[ay1][x] = 'g'   # south gate gap
# stone pad (spar floor) center
rect_fill(15, 9, 20, 12, 'o')
# partners 5/6/7 on the pad, squad 1/2/3 forming up below
g[10][16] = '5'; g[10][18] = '6'; g[10][20] = '7'
g[14][14] = '1'; g[14][18] = '2'; g[14][21] = '3'

# --- MAIN THOROUGHFARE (rows 17-23): dirt path from the arena gate south ---
for y in range(17, 24):
    g[y][17] = ','; g[y][18] = ','
# camp tents/buildings flanking the street
for (bx, by) in [(7, 19), (9, 19), (27, 19), (29, 19), (7, 21), (28, 21)]:
    g[by][bx] = 'B'

# --- SUMMONING building (rows 25-30, cols 14-21), door opening north ---
sx0, sy0, sx1, sy1 = 14, 25, 21, 30
for x in range(sx0, sx1 + 1):
    g[sy0][x] = 'B'; g[sy1][x] = 'B'
for y in range(sy0, sy1 + 1):
    g[y][sx0] = 'B'; g[y][sx1] = 'B'
rect_fill(sx0 + 1, sy0 + 1, sx1 - 1, sy1 - 1, ',')   # interior floor
for x in (17, 18):
    g[sy0][x] = ','                                   # doorway (north)
# player enters here (just outside the door, in the plaza)
g[24][17] = 'P'

# --- a little flavor in the open flanks (single-tile walkable tree cover) ---
# (kept sparse so the yards stay open)

with open(OUT, "w", encoding="utf-8") as f:
    f.write("name:  Camp Grounds\n")
    f.write("theme: camp\n")
    f.write("notes: Larger camp. Summoning (S) -> main street -> sparring arena (N); "
            "forest band on top (raid source); open yards flanking the summoning.\n")
    f.write("---\n")
    for row in g:
        f.write("".join(row) + "\n")
print("wrote", OUT, f"({W}x{H})")
