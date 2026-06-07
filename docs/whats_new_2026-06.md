# What's New — June 2026 (branch `tutorial-battle-and-level-semantics`)

A summary of everything added/changed in this work block. Newest first.
Canonical detail lives in `ARCHITECTURE.md`, `implementation_status.md`, the level
specs under `docs/levels/`, and `map_generation_playbook.md`.

---

## 1. The opening, end to end (Beat 1 → Beat 2)

The whole Act-1 opening now plays as one connected chain, all genuine movement:
**void corridor → summoning chamber → arrival cutscene → spar → (drill breaks) → raid battle.**
Run it from `opening_corridor_scene.tscn` or jump in at `summoning_room_scene.tscn`.

- **Chamber → arrival** (`summoning_room_scene.gd`): walk-through door (walk up to the
  doorway to leave; Space still works) → `camp_arrival_scene`.
- **Arrival cutscene** (`camp_arrival_scene.gd`, scripted, no input): the hero is spawned
  **off-map below the south wall** and **walks up through the doorway onto the screen** (the
  wall is the bottom edge, void hidden — no fake "room") → Vael (giving orders to two soldiers,
  who disperse) notices him, walks down, welcomes him → leads him up to the arena → fade to
  the spar. Driven by a dedicated `CineCam` + `CinematicActor`s.
- **`CinematicActor`** (`scripts/characters/walking/cinematic_actor.gd`, reusable): code-built
  directional idle/walk anims from the Chris sheets; `walk_to` steps the A* path
  (square-to-square); `face`/`face_tile`; `tint` to distinguish placeholders (we're not getting
  sprites soon — tints are the accepted way to tell characters apart). `WalkingPlayer.face()`
  + a `cinematic_walk_north` idle-on-finish fix added.
- **Spar** (`tutorial_spar_scene` + `tutorial_spar.gd`, scripted, `arena_drill`): a "spar
  director" gates the action bar step-by-step + prompts via `TutorialPrompt` — Vael's intro →
  **move** → **attack** (auto-ends the first unit's turn so the strike falls to a squadmate and
  the archer chains a **real** follow-up; credited only if one actually fired) → the **raid
  interrupts** (flash, Vael flips coach→commander) → hands off to the raid.
- **Raid** (`tutorial_battle_scene` on `arena_raid`): the true battle; intro picks up off the
  spar's cliffhanger. `arena_drill`/`arena_raid` are sibling maps (only the north wall differs).
- Pattern documented in `ARCHITECTURE.md` → *Scripted Cutscenes*. Placeholders: Vael/soldiers
  are tinted Chris (no sprites coming); chamber is bare; dialogue is draft.

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
