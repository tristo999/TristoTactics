# Tutorial Battle — Build Log & Lessons (camp_v2)

A retrospective of building the first data-driven tutorial battle map (`data/maps/camp_v2.map`
→ `scenes/levels/tutorial_battle_scene.tscn`). Captures what we built, every bug we hit,
and the rules that should make the *next* map go faster.

---

## What we accomplished

**A playable, data-driven tactics battle built entirely from a text map + a roster.**

- **Text-map pipeline.** ASCII `.map` files → `MapLoader` → tile layers. A fight is now just
  *a `.map` file + a roster dictionary*, both editable in chat. (`scripts/levels/tilemaps/map_loader.gd`,
  `battle_spawner.gd`, `tutorial_battle.gd`.)
- **Editor bake workflow.** `TextMapTilemap` (`@tool`) bakes a `.map` into real, hand-editable
  tiles + `Marker2D` spawn nodes via inspector buttons. Runtime falls back to building from the
  `.map` if unbaked. Harness scenes added: `_bake_to_disk.tscn`, `_screenshot.tscn`, `_move_diag.tscn`.
- **Neighbor-based 9-slice autotiling** for the log fence (corners via diagonal-neighbor checks,
  no terrain sets needed) and 3×3 multi-cell trees.
- **camp_v2 layout** (22×22): woods on a ledge → a single stairs gap down the cliff → an open
  fenced grass yard with a central stone sparring pad → squad + AI ally recruits, insurgents up top.
- **The void fix:** a screen-space background `CanvasLayer` (ColorRect) that fills the viewport at
  any zoom/pan — the only thing that reliably kills Godot's gray void (extending the tilemap can't).
- **Readable tactics camera:** zoom to a target tile-count (~18 wide), follow the party, start
  centered on the squad, bounded to the map.
- **Three-team model in play:** player squad + AI green allies + insurgent enemies, all from one
  roster, AI-driven via `EnemyCharacter` + `team_override`.

By the end: walking, clicking-to-move, party-centered framing, edge-to-edge ledge, and units
sitting correctly in their tiles — all verified.

---

## Bugs we hit and what actually fixed them

| Symptom | Real cause | Fix |
|---|---|---|
| Forest rendered as buildings, stone invisible | Wrong atlas coords | Rendered the Solaria atlas with PIL to read true coords (grass 5,0; dirt 5,3; pad 10,6; wall 10,3) |
| Trees/fence floating over void | Transparent overlay tiles need a ground tile under them | Always lay `T_GRASS` on BaseGrid under fence/ledge/tree cells |
| Gray void at any zoom | Extending the tilemap can't cover a zoomed-out camera | Screen-space background `CanvasLayer` ColorRect (always fills viewport) |
| "Doesn't look like a game" (tiny units) | Camera was fitting the whole map | Zoom to a readable tile-count and follow units instead |
| Fence corners not closing | `_is_interior` counted *all* grass, but grass is on both sides of the ring | Interior = ring floor only (pad `o`, yard `g`, unit digits) — not plain `.` |
| Wrong stairs/ledge tiles | Guessed tiles | Decoded `dev_sandbox`'s `tile_map_data` to read the exact tiles it uses (stairs = (4,11), cliff = (1,11)) |
| Trees overlapping + blocking enemies | 3×3 impassable trees placed carelessly | Keep 3×3 trees (thematic) but space them and keep enemy spawns/lanes clear |
| Ledge didn't reach map edge | Cliff row spanned cols 1..W-2 | Span the full width, cols 0..W-1, with the stairs gap |
| **Player couldn't click move tiles** | The full-screen background **ColorRect ate every click** (`mouse_filter` defaults to STOP) | Set the BG ColorRect `mouse_filter = IGNORE` |
| Camera not centered on party | `apply_map_limits` ran before units were snapped to tiles | Reorder: center the camera *after* `_setup_characters()` |
| **Units sat ~3px right of their tile** | `TILE_CENTER_OFFSET=(3,-2)` + `map_to_local` (local) assigned to `global_position`; only cancels when the tilemap node is at x=3 | Put the Arena tilemap node at `position=(3,0)` — the convention the working maps already use |

---

## The biggest lesson: how to verify maps *remotely* (and what lies)

We burned a lot of cycles trusting the wrong tools. The reliable loop:

1. **`--headless` renders are GARBAGE.** Headless uses the **DummyTexture renderer** — it cannot
   sample real textures, so screenshots come out as meaningless cobblestone/void. (Tell: `DummyTexture
   leaked` at exit.) It also can't test mouse input. *Two of our hardest bugs (can't-click, off-center)
   are structurally invisible to headless.*
2. **For a real frame, render windowed with `--rendering-driver opengl3`** through
   `scenes/levels/_screenshot.tscn`, then PIL-crop the area of interest. This is how we finally *saw*
   the click-eating background and the unit offset.
3. **For tile identity / placement, don't eyeball — dump data.** `scripts/tools/dump_cells.gd`
   populates layers with the real tileset and prints `get_cell_atlas_coords`. `preview_camp.py` PIL-
   composites the real atlas deterministically. (Note: PIL shows only 1/9 of a 3×3 tile — that's
   expected, not a bug; the engine expands multi-cell tiles.)
4. **`-s` SceneTree scripts don't initialize autoloads** → `TerrainRegistry not found` → character
   scripts fail to compile → `instantiate()` returns null. Run diagnostics as a **Node-based scene**
   (a `.tscn` harness), not `-s`, so autoloads load.
5. **The user's screenshot is worth a thousand of my headless runs.** When I could measure the logic
   was "healthy" but the user still couldn't move, the missing layer was always the GUI/render side
   that headless can't see. Ask for the editor's Output/Debugger panel early.

---

## Map-design process (reaffirmed)

Design in order, never skip (see `docs/map_design_process.md`):
1. **Composition** — bare walkable skeleton + lanes (what blocks/funnels movement).
2. **Variation** — terrain that *constrains* movement: chokepoints, pockets sized to maneuver/combo.
3. **Decoration** — inert visual scatter, zero rules.

Function before feel. A big open box plays like a small box. Analyze lanes/chokes/intent *first*,
camera/backdrop/decoration last.

---

## Rules for the next map (so we don't repeat ourselves)

- Lay `T_GRASS` (or some ground tile) on BaseGrid **under** every transparent overlay (fence/ledge/tree).
- Ledge/cliff barriers span **edge to edge** (cols 0..W-1) with explicit walkable gaps.
- Any full-screen `ColorRect`/`Control` used as backdrop or overlay **must be `mouse_filter = IGNORE`**,
  or it eats gameplay clicks.
- Put the tilemap node at **`position = (3, 0)`** so units/highlights align (until the `TILE_CENTER_OFFSET`
  hack is refactored out).
- Confirm tile identity by **dumping atlas coords**, and confirm *look* with a **windowed opengl3 render**
  — never a headless screenshot.
- 3×3 trees are fine and thematic — just space them and keep enemy spawns/lanes clear of their footprints.
- Keep player units out of headless smoke-tests (a player turn waits for input forever); null
  `gm.intro_event`/`victory_event` in test harnesses.

*Built 2026-06-06. Map: `data/maps/camp_v2.map`. Scene: `scenes/levels/tutorial_battle_scene.tscn`.*
