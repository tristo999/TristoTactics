# Map Generation Playbook

The go-to reference for generating a new battle level. Follow this top-to-bottom and the
mistakes from the camp_v2 build won't repeat. Pairs with `docs/tutorial_battle_buildlog.md`
(the war stories) and `docs/map_design_process.md` (the design philosophy).

---

## 0. Design order (never skip)

1. **Composition** — bare walkable skeleton + lanes. Where can you walk; what blocks/funnels.
2. **Variation** — terrain that *constrains* movement: chokepoints, perches, pockets sized to
   maneuver/combo (tank plug, archer perch, healer slot).
3. **Decoration** — inert visual scatter, zero rules.

Function before feel. A big open box plays like a small box. Render each stage and get approval
before layering the next.

---

## 1. The `.map` format

```
name:  Display Name
theme: camp
notes: free text
---
<ascii grid starts after the --- line>
```

**Legend (chars → role, from `map_loader.gd`):**

| Char | Role | Renders |
|---|---|---|
| `.` | walk | grass (+ ~12% inert decor scatter) |
| `g` | walk | grass, but counts as *inside the fence* for autotiling |
| `,` | walk | dirt |
| `o` | walk | stone pad (sparring/drill floor) |
| `S` | walk | ledge ramp/stairs (the one gap down a cliff) |
| `#` | fence | 9-slice log fence over grass (impassable) |
| `L` | ledge | cliff face over grass (impassable barrier) |
| `B` | block | brick wall over grass (impassable) |
| `T` | tree | 3×3 tree over grass (impassable cover) |
| `w` `C` | back | backdrop ground (outside the fight) |
| `1`–`9` | walk | named spawn slot (unit stands on grass) |
| `P` | walk | generic player spawn |
| `E` | back | enemy spawn |

**Fence interior rule:** the fence autotiler treats `g`/`o`/digits as "inside". Plain `.` grass is
*outside*. If you want the fence to wrap an area, fill that area with `g`, not `.` — otherwise corners
pick rail tiles instead of closing.

---

## 2. Tile atlas coords (Solaria, source id 2)

Verified against the real tileset (`assets/tilesets/tileset.tres`, 16px, no margins).

```
GRASS  (5,0)    DIRT   (5,3)    PAD/stone (10,6)   BRICK/wall (10,3)
TREE3  (7,0)  ← 3×3 multi-cell (size_in_atlas (3,3); engine draws full tree from one cell)
CLIFF  (1,11) ← impassable ledge face          STAIRS (4,11) ← walkable ramp in a ledge gap
TREE   (7,3)  ← single-tile walkable cover (not the 3×3 blocker)
FENCE 9-slice: tl(0,12) t(1,12) tr(2,12) l(0,13) c(1,12) r(2,13) bl(0,14) b(1,12) br(2,14)
DECOR  (6,0),(6,1) ← inert grass tufts
```

Don't guess tiles. To learn what a reference scene (e.g. `dev_sandbox`) uses, **decode its
`tile_map_data`** or run `scripts/tools/dump_cells.gd`.

---

## 3. Scene scaffolding (required nodes + the gotchas that bite)

A runtime battle scene (`extends BaseLevel`) needs these — copy `tutorial_battle_scene.tscn`:

```
Root (BaseLevel script)
├── Background (CanvasLayer, layer = -100)
│   └── BG (ColorRect, full-rect, mouse_filter = 2 (IGNORE) ‼)   ← kills void; MUST ignore mouse
├── PauseMenuHandler
├── GameManager (instance)
├── BattleInputHandler
├── PlayerTeam / EnemyTeam / AllyTeam   (empty; spawner fills them)
├── Arena (TextMapTilemap, position = (3,0) ‼, map_file = "res://data/maps/<x>.map")
│   ├── BaseGrid / Decor(z1) / Objects(z2) / Walls(z3) / Water   (all TileMapLayer + tileset)
├── ActionCamera (instance; Camera2D, current=true, anchor_mode=1)
├── UILayer (CanvasLayer) → TileInfoPanel, BottomActionBar, ActiveStatsPanel, SpeedToggleButton
└── DialogueBox (instance)
```

**The two non-obvious must-dos:**
- **`BG` ColorRect `mouse_filter = 2`.** A full-screen Control defaults to STOP and will eat every
  gameplay click (units render fine, turn state is fine, but clicking a move tile does nothing).
- **Arena `position = (3, 0)`.** Units are placed at `map_to_local(tile) + TILE_CENTER_OFFSET(3,-2)`;
  the `+3` only lands centered when the tilemap node is at x=3. Skip this and every unit sits 3px
  right of its tile/selection box. (Until the offset hack is refactored, every map needs (3,0).)

`tutorial_battle_scene` builds at **runtime** (no baked tiles) → `.map` edits apply immediately.
A baked preview scene (`text_map_test`) must be **re-baked** after `.map` edits.

---

## 4. Roster (who spawns where)

`tutorial_battle.gd` ROSTER maps spawn-char → entry:
```gdscript
"1": {"data": "res://data/characters/archer.tres", "name": "Elena"},          # player squad
"5": {"data": ".../hero.tres", "name": "Recruit", "team": "ally"},            # AI green ally
"E": {"data": ".../goblin.tres", "name": "Insurgent"},                        # enemy (auto-numbered)
```
- Named slots `1`–`9` default to **player**; `"team": "ally"/"enemy"` overrides.
- Allies/enemies are `EnemyCharacter` (AI-driven); players use `PlayerCharacter`.
- Keep enemy spawn cells clear of 3×3 tree footprints and walls, or they spawn boxed in.

---

## 5. Verify remotely — what to trust, what lies

- ❌ **Never trust `--headless` screenshots.** Headless = DummyTexture renderer (can't sample
  textures → garbage image) and **can't test mouse input**. Click bugs and off-center bugs are
  *invisible* to it.
- ✅ **Real frame:** windowed render through `scenes/levels/_screenshot.tscn`:
  ```
  <godot> --path . --rendering-driver opengl3 --resolution 1280x720 \
    res://scenes/levels/_screenshot.tscn -- res://scenes/levels/<scene>.tscn docs/maps/out.png
  ```
  Then PIL-crop the area of interest (e.g. the active unit + its selection box) and zoom NEAREST.
- ✅ **Tile placement / identity:** `scripts/tools/dump_cells.gd` (prints `get_cell_atlas_coords`),
  `scripts/tools/preview_camp.py` (PIL composite of the real atlas — shows only 1/9 of a 3×3 tile,
  that's expected).
- ✅ **Turn/move logic:** run a quick **Node-based scene harness** — a 4-line `.tscn` whose root Node
  script instantiates the battle scene, nulls `intro_event`, waits a beat, then prints `gm.state` /
  `current_character` / `cached_reachable_tiles`. Never a `-s` SceneTree script — `-s` skips autoloads
  → `TerrainRegistry not found` → characters fail to instantiate.
- Headless smoke-test of AI only works **without player units** (a player turn waits for input
  forever). Null `gm.intro_event`/`victory_event` in harnesses or the DialogueEvent blocks too.
- When in doubt, **ask the user for a screenshot + the editor Output/Debugger panel** — it beats any
  amount of headless guessing.

---

## 6. Camera defaults (`camera_control.gd`)

- `apply_map_limits(tilemap)` — call **after** units are placed (`_setup_characters`), so it centers
  on final party positions. Sets map limits, zoom-to-tile-count, centers on the player centroid.
- `TARGET_TILES_WIDE ≈ 18` (Shining-Force-II-ish, slightly loose). `max_zoom = 12` so the target is
  honored at 2560px width (it needs ~9.4 — don't cap below that).
- Background CanvasLayer guarantees no void, so the clamp is loose (view may roam ½ screen past edges).

---

## 7. Pre-flight checklist for a new map

- [ ] Composition designed first (lanes/chokes/pockets), rendered + approved.
- [ ] Ground tile under every transparent overlay (fence/ledge/tree).
- [ ] Ledge/cliff spans edge to edge (cols 0..W-1) with explicit walkable gaps.
- [ ] Fence-wrapped areas filled with `g` (not `.`) so corners close.
- [ ] Enemy/ally spawns clear of tree footprints and walls.
- [ ] Scene: BG ColorRect `mouse_filter = IGNORE`; Arena `position = (3,0)`.
- [ ] Verified with a **windowed opengl3 render** (not headless) + a cell dump.
- [ ] Walk, click-to-move, party-centered framing, and unit-in-tile alignment all confirmed.

*Written 2026-06-06 from the camp_v2 tutorial-battle build.*
