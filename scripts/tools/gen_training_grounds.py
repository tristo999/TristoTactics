#!/usr/bin/env python3
"""Generate data/maps/training_grounds.map — the Beat 2 one-scene tutorial yard.

Design: docs/levels/training_grounds.md. An IRREGULAR working training yard:
- north fence with 3 breach gaps (W narrow / C wide / E narrow), forest beyond
- east side bounded by a natural rock OUTCROP (cliff) instead of fence
- THE PIT: sunken stone ring center, low rail, two gaps (N + SW) = chokepoints
- THE RANGE (west): earthen berm backstop + straw targets, long open lane
- STORAGE ROWS (east): crate blockers + tarped-stack COVER in staggered rows
- muster ground: worn dirt, open and fast; well+trough west-center
- footwork course by the south gate
Legend (map_loader): . grass(out)  g grass(yard)  , worn dirt  o stone  # fence
L cliff  B blocker  t cover  T big tree.  Fence-interior rule: the inside edge of
the fence is always 'g' (the autotiler counts g/o/digits as interior).
"""
import random

W, H = 44, 32
rng = random.Random(20260610)

grid = [["."] * W for _ in range(H)]
over = [[" "] * W for _ in range(H)]


def rect(x0, y0, x1, y1, ch, g=None):
    g = g if g is not None else grid
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < W and 0 <= y < H:
                g[y][x] = ch


def blob(cx, cy, r, ch, p=0.8):
    """Organic-ish blob: manhattan radius with random edge dropout."""
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            d = abs(x - cx) + abs(y - cy)
            if d <= r and 0 <= x < W and 0 <= y < H:
                if d < r or rng.random() < p:
                    grid[y][x] = ch


def wear(cx, cy, r, density=0.55):
    """WORN ground: speckled dirt mixed into grass (never a painted solid shape).
    Density falls off from the center, so heavy-use areas read browner."""
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            d = abs(x - cx) + abs(y - cy)
            if d <= r and 0 <= x < W and 0 <= y < H and grid[y][x] in ("g", "."):
                if rng.random() < density * (1.0 - d / (r + 1.0)) * 1.6:
                    grid[y][x] = ","


def wear_path(x0, y0, x1, y1, width=1, density=0.7):
    """A worn footpath: speckled dirt along a line (L-shaped: x first, then y)."""
    for x in range(min(x0, x1), max(x0, x1) + 1):
        for dy in range(-width, width + 1):
            if 0 <= y0 + dy < H and grid[y0 + dy][x] in ("g", ".") and rng.random() < density:
                grid[y0 + dy][x] = ","
    for y in range(min(y0, y1), max(y0, y1) + 1):
        for dx in range(-width, width + 1):
            if 0 <= x1 + dx < W and grid[y][x1 + dx] in ("g", ".") and rng.random() < density:
                grid[y][x1 + dx] = ","


# ---- the yard bounds (irregular) -------------------------------------------
FY0, FY1 = 5, 28          # north / south fence rows
FX0 = 3                   # west fence col
OUT_X = 39                # east outcrop starts here (cols 39-41, rows 8..20)

# interior fill: 'g' ring inside the fence, worn dirt deeper in (textured mix)
rect(FX0 + 1, FY0 + 1, OUT_X, FY1 - 1, "g")

# north fence with 3 breaches: W(8-9) C(21-24, wide) E(35-36)
for x in range(FX0, OUT_X + 2):
    if x in (8, 9) or 21 <= x <= 24 or x in (35, 36):
        grid[FY0][x] = "g"          # breach gap (fence missing; raiders' entry)
    else:
        grid[FY0][x] = "#"
# west fence
for y in range(FY0, FY1 + 1):
    grid[y][FX0] = "#"
# south fence with the gate (x 14-15, faces the camp)
for x in range(FX0, OUT_X + 2):
    grid[FY1][x] = "g" if x in (14, 15) else "#"
# east boundary: fence top+bottom stubs, natural rock outcrop between
for y in range(FY0, 8):
    grid[y][OUT_X + 1] = "#"
for y in range(21, FY1 + 1):
    grid[y][OUT_X + 1] = "#"
for y in range(8, 21):                      # the outcrop bulge (impassable rock)
    for x in range(OUT_X, OUT_X + 3):
        if x < W:
            grid[y][x] = "L"
    if rng.random() < 0.5 and OUT_X - 1 > 30:
        grid[y][OUT_X - 1] = "L"            # ragged inner edge

# ---- worn ground: SPECKLED wear, never painted solids ------------------------
wear(23, 10, 7, 0.75)                       # muster ground (heaviest use)
wear(23, 13, 4, 0.5)
for y in range(7, 22):                      # the range firing line (lane wear)
    for x in (10, 11, 12):
        if grid[y][x] == "g" and rng.random() < 0.6:
            grid[y][x] = ","
wear(35, 18, 4, 0.6)                        # dummy-lane apron
wear(13, 25, 3, 0.7)                        # footwork course
wear_path(15, 26, 22, 22, 1, 0.5)           # gate -> pit (daily traffic)
wear_path(24, 6, 23, 15, 1, 0.45)           # C breach gate -> muster (supply route)

# ---- THE PIT (stone ring, rail, two gaps) -----------------------------------
PX0, PY0, PX1, PY1 = 20, 16, 27, 21         # outer rail rect
rect(PX0 + 1, PY0 + 1, PX1 - 1, PY1 - 1, "o")   # sunken stone floor
for x in range(PX0, PX1 + 1):               # rail top/bottom
    grid[PY0][x] = "#"
    grid[PY1][x] = "#"
for y in range(PY0, PY1 + 1):               # rail sides
    grid[y][PX0] = "#"
    grid[y][PX1] = "#"
grid[PY0][23] = "o"; grid[PY0][24] = "o"    # NORTH GAP (the bell post beside it)
grid[PY1][PX0] = "o"                        # SW gap (corner entry)
grid[PY1 - 1][PX0] = "o"
grid[PY0 - 1][22] = "B"                     # the cracked signal-bell post (Row 5 cue)

# ---- THE RANGE (west): berm + targets ---------------------------------------
for y in range(7, 20):                      # earthen berm (backstop, impassable, solid 2-wide)
    grid[y][5] = "L"
    grid[y][6] = "L"
for y in (8, 11, 14, 17):                   # straw targets against the berm
    grid[y][8] = "B"

# ---- THE WELL + trough (west-center) ----------------------------------------
rect(13, 13, 14, 14, "B")
grid[15][13] = "x"                          # water barrel by the well

# ---- STORAGE ROWS (east): barrels + crates + tarped-stack cover, staggered ---
for i, y in enumerate((7, 9, 11, 13)):
    x0 = 31 + (2 if i % 2 else 0)
    for x in range(x0, min(x0 + 6, OUT_X - 1)):
        if rng.random() < 0.78:
            r = rng.random()
            grid[y][x] = "x" if r < 0.5 else ("t" if r < 0.8 else "B")
# dummy lane (Borin's): a row of practice dummies
for x in (33, 35, 37):
    grid[18][x] = "B"

# ---- footwork course posts ---------------------------------------------------
grid[24][10] = "B"
grid[26][12] = "B"

# ---- forest outside (north band + scattered) ---------------------------------
for x in range(0, W):
    for y in range(0, FY0 - 1):
        pass
TREES = []
def far_enough(x, y):
    return all(abs(x - tx) >= 3 or abs(y - ty) >= 3 for tx, ty in TREES)
for _ in range(220):
    x, y = rng.randrange(0, W - 2), rng.randrange(0, 4)
    lane = any(abs(x - bx) <= 1 for bx in (8, 9, 21, 22, 23, 24, 35, 36))
    if not lane and far_enough(x, y):
        grid[y][x] = "T"; TREES.append((x, y))
for _ in range(60):                          # single-tile brush filler
    x, y = rng.randrange(0, W), rng.randrange(0, FY0 - 1)
    if grid[y][x] == ".":
        if rng.random() < 0.3:
            grid[y][x] = "t"
# a few trees outside south/west too (the camp side stays open at the gate)
for (x, y) in ((1, 12), (1, 22), (42, 24), (42, 28), (2, 30), (40, 30)):
    if grid[y][x] == ".":
        grid[y][x] = "T" if far_enough(x, y) else "t"
        TREES.append((x, y))

# ---- spawn overlay -----------------------------------------------------------
# hero at the gate; squad at their stations; recruits at the muster ground.
over[27][14] = "1"                          # HERO — just inside the south gate
over[12][10] = "2"                          # Elena — the range lane
over[17][34] = "3"                          # Borin — dummy lane
over[26][16] = "4"                          # Lyra — near the gate (arrives late, fiction)
over[9][22] = "5"; over[9][24] = "6"; over[10][23] = "7"   # recruits drilling
# raid groups: markers just OUTSIDE each breach (spawned mid-scene by trigger)
for x, n in ((8, 1), (9, 1), (8, 0)):
    pass
over[3][8] = "E"; over[3][9] = "E"; over[2][8] = "E"                    # W ×3
over[3][21] = "E"; over[3][22] = "E"; over[3][23] = "E"; over[3][24] = "E"; over[2][22] = "E"  # C ×5
over[3][35] = "E"; over[3][36] = "E"; over[2][36] = "E"                 # E ×3

# ---- write -------------------------------------------------------------------
lines = [
    "name:  Training Grounds",
    "theme: camp",
    "notes: Beat 2 ONE-SCENE tutorial yard (drill -> breach -> raid). Design: docs/levels/training_grounds.md. Breaches N x3 (8-9 / 21-24 / 35-36); pit ring center; range W; storage rows E; outcrop east; gate S(14-15).",
    "---",
]
lines += ["".join(r) for r in grid]
lines.append("---")
lines += ["".join(r) for r in over]
with open("data/maps/training_grounds.map", "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")
print("wrote data/maps/training_grounds.map (%dx%d, %d trees)" % (W, H, len(TREES)))
