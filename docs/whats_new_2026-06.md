# What's New — June 2026 (branch `tutorial-battle-and-level-semantics`)

A summary of everything added/changed in this work block. Newest first.
Canonical detail lives in `ARCHITECTURE.md`, `implementation_status.md`, the level
specs under `docs/levels/`, and `map_generation_playbook.md`.

---

## 1. Beat 1 — the arrival cutscene

A fully **scripted cutscene** (no player input) for the hero arriving in the camp.

- **`scenes/levels/camp_arrival_scene.tscn`** + **`scripts/levels/camp_arrival_scene.gd`** —
  fade in at the summoning-room doorway → camera pans up to Vael → Vael walks down to
  greet the hero → warm welcome → Vael leads the hero up toward the training ground → fade.
- **`scripts/characters/walking/cinematic_actor.gd`** (`CinematicActor`, reusable) — a
  script-driven cutscene character. Builds directional idle/walk anims **in code** from the
  Chris sheets; `walk_to(tile, dur)` **steps the A* grid path** (square-to-square, no
  diagonal slide); `face`/`face_tile`; `tint` to recolor a placeholder (Vael = blue).
- `WalkingPlayer.face(dir)` added for cutscene facing.
- Pattern documented in `ARCHITECTURE.md` → *Scripted Cutscenes*. Vael + dialogue are
  placeholders; ending isn't wired to the tutorial yet (`next_scene_path`).

## 2. `camp_grounds` — the large camp POC

The full **Beat 1 → Beat 2 space** in one map (composition POC over placeholder tiles).

- **`data/maps/camp_grounds.map`** (52×52) + generator **`scripts/tools/gen_camp_grounds.py`**
  (parameterized — iterate there and re-run). Spec: **`docs/levels/camp_grounds.md`**.
- Layout: solid **south wall + doorway** (walk out of the summoning room) → a **camp**
  (gathering commons + fire pit, dirt **ring road**, encircling tents) → a **wide sparring
  arena** with **3 raid entrances on the north wall** aligned to **3 forest clearings**
  (three attack lanes) → deep **organic forest** (non-overlapping 3×3 trees) on top.

## 3. New `.map` format features (`MapLoader`)

- **Spawn overlay** — an optional 2nd grid after a 2nd `---`. Spawns (`P`/`E`/`1`-`9`) live
  there and **layer on top of terrain**, so a unit can spawn on the stone pad/road without
  the spawn cell erasing the tile. Legacy maps (no overlay) still work.
- **`t`** role — single-tile walkable tree (forest variation), on the Objects layer.
- Both documented in `map_generation_playbook.md` §1.

## 4. Level-authoring conventions

- **`docs/map_generation_playbook.md`** — the go-to reference for building a new battle map:
  `.map` legend, verified tile coords, required scene scaffolding + gotchas, the remote-verify
  workflow, camera defaults, a pre-flight checklist, and **§8 Level Semantics** (regions +
  triggers + the per-level spec template).
- **`docs/levels/<map>.md`** specs — durable, named model of a level (regions, roster,
  triggers tagged `[built]`/`[written]`, open questions). Examples: `camp_v2.md`, `camp_grounds.md`.
- **`docs/tutorial_battle_buildlog.md`** — retrospective + lessons from the camp_v2 build.

## 5. Tutorial battle (`camp_v2`) — fixed & playable

- **Can't click move tiles** → the full-screen background `ColorRect` was eating clicks; set
  `mouse_filter = IGNORE`.
- **Units off-center in tile** → tilemap node at `position (3,0)` (matches the offset convention).
- **Camera not centered on party** → `apply_map_limits` reordered to after units are placed.
- **Ledge** spans the full map width.

## 6. Build-state docs corrected

Verified docs against code (they were stale):
- **Combos / follow-ups are BUILT** (`ComboSystem` autoload; archer/dwarf/healer; 3 triggers).
  Corrected `implementation_status.md`, `slice_spec.md`, and documented `ComboSystem` in
  `ARCHITECTURE.md`.
- **Beat 2** repointed to the real `tutorial_battle_scene`/camp_v2 (was pointing at an old stub).
- **Standing rule:** update build-state docs *in the same change as the feature*, and verify
  claims against code before trusting a doc.

## 7. New dev tools

- `scripts/tools/gen_camp_grounds.py` — the camp generator.
- `scripts/tools/preview_camp.py` — PIL render of a `.map` (terrain section).
- `scripts/tools/dump_cells.gd` — prints the engine's placed atlas coords (verify tiles).
- Harness scenes: `_screenshot.tscn` (render any scene → PNG), `_bake_to_disk.tscn` (bake a
  `.map` into a scene), `_camp_grounds_preview.tscn`.
- **Verify maps remotely:** windowed `--rendering-driver opengl3` render (NOT headless — that's
  a dummy renderer) + PIL/cell-dump for placement. Headless can't test input or sample textures.

---

*Branch: `tutorial-battle-and-level-semantics`. Written 2026-06-06.*
