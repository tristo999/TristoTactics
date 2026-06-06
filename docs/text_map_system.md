# TristoTactics — Text Map System

Maps are **plain-text files** authored and iterated in chat, then read by the
engine to build the real tilemap. No tile editor, version-controlled, diff-able,
and renderable back as text so a human and an AI collaborator look at the same
thing. A map is *data*, not a hand-painted scene.

Status: **v1 (core)** — parse + spawns + render + tile placement (floor / road /
stone / forest / wall). Water and prettier autotiled walls are v1.1.

## File format
One file per map in `data/maps/<name>.map`: optional `key: value` front-matter,
a `---` separator, then the ASCII grid. `;` begins a comment.

```
name:  Sample Arena
theme: camp
---
##########
#P..TT..E#
#P..,,..E#
#1..,,..2#
#...TT...#
##########
```
Rows may be ragged (padded to the widest). Spaces are *void* (no tile). If there
is no `---`, the whole file is treated as the grid.

## Legend (char → layer + terrain)
Tile atlas coords are real, pulled from `dev_sandbox` (source id 2 = Solaria).

| Char | Meaning | Layer | Terrain effect |
|---|---|---|---|
| `.` | grass floor | BaseGrid | walkable |
| `,` | road/path | BaseGrid | walkable, def −1 |
| `o` | stone floor | BaseGrid | walkable |
| `T` | forest | BaseGrid | walkable, **def +2, cost 2** (cover) |
| `#` | wall | Walls | **impassable** |
| `P` | player spawn | floor + spawn | — |
| `E` | enemy spawn | floor + spawn | — |
| `1`–`9` | named slot | floor + named spawn | precise unit placement |
| (space) | void | none | off-map |
| `~` | water | Water | **v1.1** (impassable) |

The char→tile table lives in `MapLoader.LEGEND`, so maps stay terse and tiles can
be re-skinned globally (the `theme:` field is reserved for palette swaps).

## API — `MapLoader` (`scripts/levels/tilemaps/map_loader.gd`)
- `parse(text) -> Dictionary` → `{ meta, grid, size, player_spawns, enemy_spawns, named }`
- `load_file(path) -> Dictionary`
- `populate(parsed, base_layer, walls_layer)` → sets cells on the layers
- `render(parsed) -> String` → grid back to text (chat + self-verify)

Walkability is automatic: after `populate`, the tilemap's existing
`setup_astar_grid()` + `add_walkable_cells_from_tilemap()` build A*/BFS from the
placed cells (BaseGrid = walkable, Walls = solid, terrain cost/defense via
`TerrainRegistry`).

## Bake into the editor (text → hand-editable tiles)
A `.map` builds at runtime by default, but you can **bake** it into real,
hand-editable tiles. On a `TextMapTilemap` node (with `BaseGrid`/`Walls` child
layers and `map_file` set), the inspector shows two buttons:

- **Bake from .map** — writes the grid into the tile layers and drops editable
  `Marker2D` spawn nodes under a `Spawns` child (named `Slot_1`, `E1`, `P1`…,
  each carrying `spawn_team`/`spawn_key` metadata). **Save the scene (Ctrl+S)**
  to keep it.
- **Clear baked tiles** — wipes the layers + `Spawns` so you can re-bake.

After baking, paint over the tiles and drag the spawn markers freely — it's a
normal scene now. At runtime the node detects the `Spawns` child and reads spawn
positions from the markers (using the already-placed tiles); if a scene was
*not* baked but has a `map_file`, it falls back to building at runtime. So the
flow is: **draft in chat → bake → hand-polish in the editor.**

## The chat iteration loop
1. You: *"wider, forest chokepoint mid-map, water down the left."*
2. I edit the `.map` text.
3. **Self-check:** `scripts/tools/map_check.gd` parses it headless and prints the
   render + spawn coords, so I confirm it built right (stray char, off-by-one,
   isolated spawn).
4. I paste the rendered grid back → we both see it → repeat.

`scripts/tools/inspect_tiles.gd` is the companion tool that dumps the real
(source : atlas) coords a scene uses, for extending the legend.

## Roadmap
- **v1.1:** water tile + autotiled/edge walls (grab the atlas coords); maybe a
  `theme:` palette swap.
- **Battle integration:** a `TextMapTilemap` (extends `tilemap.gd`) that builds
  from a `map_file`, plus a data-driven battle that spawns a roster onto the
  named/team spawns — so a fight = *a map file + a roster*, both chat-editable.
- **Reserved:** named regions (`[name]` rectangles) for triggers/objectives;
  reachability validation; a mirror helper for the Act-1/Act-2 collision maps.

## Honest limits
The loader places tiles and verifies they parse + are reachable; it can't tell
you a map is *fun* — that's a playtest. v1 walls render as a single wall tile
(not autotiled edges) until v1.1.
