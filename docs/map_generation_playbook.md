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
| `T` | tree | 3×3 tree over grass (impassable cover; only the origin cell blocks A*) |
| `t` | cover | single-tile tree (walkable cover on Objects; forest variation) |
| `w` `C` | back | backdrop ground (outside the fight) |
| `1`–`9` | walk | named spawn slot (unit stands on grass) |
| `P` | walk | generic player spawn |
| `E` | back | enemy spawn |

**Fence interior rule:** the fence autotiler treats `g`/`o`/digits as "inside". Plain `.` grass is
*outside*. If you want the fence to wrap an area, fill that area with `g`, not `.` — otherwise corners
pick rail tiles instead of closing.

**Spawn overlay (spawns on any terrain):** a spawn char (`P`/`E`/`1`-`9`) placed in the terrain grid
*replaces* the tile (renders grass) — so it punches holes in a pad/road. To spawn a unit **on** a
specific tile, use the optional **spawn overlay**: a second grid after a *second* `---`, same
dimensions, where the spawn chars live and everything else is space/`.`. The terrain grid then keeps
its real tiles (solid pad, etc.) and spawns layer on top. Maps with no overlay still read spawns from
the terrain grid (legacy). Generators should emit terrain, `---`, then the overlay.

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

---

## 8. Level semantics (regions + triggers) — the authoring convention

A `.map` is geometry. A **level** is geometry + intent + scripting. We capture intent in a
short **level spec** (`docs/levels/<map>.md`) so the meaning persists between sessions and we
edit in named terms, not raw tiles. *(Full rationale: "Level Semantics" design proposal,
2026-06-06. The trigger engine that makes triggers *execute* is deferred — the spec is the
shared model and works today regardless.)*

**Every level gets a spec.** Worked example: `docs/levels/camp_v2.md`. Template:

```
# Level Spec — <Name>
- Map / Scene / Beat
Intent:        one line — what the level is about / teaches / its story place
Composition:   lanes, chokes, pockets (prose)
Regions:       table of region_name → rough tiles → meaning
Roster:        slot → unit → team → role
Triggers:      table of WHEN → THEN → status ([built] | [written])
Current vs intended:  what actually plays now vs the design
Open questions
```

**Vocabulary** (shared between human + agent; small on purpose, grows only on real need):
- **Region** = a named area: `raid_spawn_north`, `chokepoint_stairs`, `defensible_pad`. We name
  the *meaning*, not the shape. "Move the chokepoint two west" / "make the pad bigger" = edit a
  region, and the level's understanding survives the change.
- **Trigger** = `WHEN <condition> THEN <action>`, referencing regions by name. Conditions start
  with: `enters(region)`, `turn >= N`, `units_in(region, team) == 0`, `unit_hp(key) <= X%`,
  `defeated(key/group)`. Actions reuse existing systems: `story_event(id)` (the built StoryEvent
  types), `spawn_group(key, at=region)` (BattleSpawner), `flip_team(group, to=…)` (team_override),
  `set_objective/win/lose`, `set_music(key)`.
- **`[written]` vs `[built]`** = the backlog. `[written]` is designed intent; `[built]` actually
  fires. Promoting one to the other (one region + one trigger at a time) is how the engine grows —
  never speculatively. Substrate already present: `EventBus` emits `character_moved(from,to)`
  (→ `enters`), `turn_started`, `battle_ended`, `character_died`, `character_damaged`; and
  `story_event_triggered(StoryEvent)` drives the dialogue/glitch/fog/flash/… events.

**How we work the loop:** I hand back a level described in its regions + triggers (not a tile
dump); you adjust in intent; I edit the named regions/triggers and keep the spec current; the
load-bearing facts go in MEMORY so I retain the level across sessions.

*Written 2026-06-06 from the camp_v2 tutorial-battle build; §8 added from the Level Semantics proposal.*
