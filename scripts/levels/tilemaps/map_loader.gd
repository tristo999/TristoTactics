# MapLoader - turns a plain-text ".map" file into tilemap cells + spawn data.
# Maps are ASCII grids (see docs/text_map_system.md). v2 adds: neighbor-based
# fence autotiling (9-slice log palisade), 3x3 large trees, a drill-pad floor,
# camp/woods backdrop, and an inert Decor scatter layer.
#
# Atlas coords verified against the Solaria sheet (source id 2).
class_name MapLoader
extends RefCounted

const SRC := 2

# --- Tile atlas coords ---
const T_GRASS := Vector2i(5, 0)
const T_DIRT := Vector2i(5, 3)
const T_PAD := Vector2i(10, 6)    # stone drill pad
const T_BRICK := Vector2i(10, 3)  # building / hard wall
const T_TREE3 := Vector2i(7, 0)   # large 3x3 tree (multi-cell)
const T_CLIFF := Vector2i(1, 11)  # ledge cliff face (grass top, rock drop) - impassable
const T_STAIRS := Vector2i(4, 11) # ledge ramp/stairs (rock, matches the ledge) - walkable; dev_sandbox uses it in the ledge gap
const T_TREE := Vector2i(7, 3)    # single-tile tree = walkable cover (not the 3x3 blocker)
const FLOOR_ATLAS := T_GRASS

# Wooden-post fence 9-slice (cols 0-2, rows 12-14). Interior = the yard side.
const FENCE := {
	"tl": Vector2i(0, 12), "t": Vector2i(1, 12), "tr": Vector2i(2, 12),
	"l": Vector2i(0, 13), "c": Vector2i(1, 12), "r": Vector2i(2, 13),
	"bl": Vector2i(0, 14), "b": Vector2i(1, 12), "br": Vector2i(2, 14),
}
# Ledge / cliff-edge 9-slice (cols 0-2, rows 9-11) — the plateau's natural barrier.
# Interior = the plateau side; the rocky edge faces out (toward the void/bg).
const LEDGE := {
	"tl": Vector2i(0, 9), "t": Vector2i(1, 9), "tr": Vector2i(2, 9),
	"l": Vector2i(0, 10), "c": Vector2i(1, 11), "r": Vector2i(2, 10),
	"bl": Vector2i(0, 11), "b": Vector2i(1, 11), "br": Vector2i(2, 11),
}
# Inert decoration scatter (grass tufts / flowers).
const DECOR_TILES := [Vector2i(6, 0), Vector2i(6, 1)]

# char -> role. Terrain placement is handled in populate() by role.
#   walk:  walkable yard interior (counts as "interior" for fence autotiling)
#   block: impassable
#   back:  backdrop (outside the fight)
const ROLE := {
	".": "walk", ",": "walk", "o": "walk", "S": "stairs",
	"g": "walk",   # yard-interior grass (renders grass, but marks "inside the fence")
	"#": "fence", "L": "ledge", "B": "block", "T": "tree",
	"t": "cover",  # single-tile tree (walkable cover on Objects) -- forest variation
	"w": "back", "C": "back",
	"P": "walk", "E": "back",
}

## Parse text into a structured map.
## Format: front-matter, "---", terrain grid, [optional "---", SPAWN OVERLAY].
## Spawns (P / E / 1-9) live in the overlay when present, so a unit can spawn on
## ANY terrain (e.g. the stone pad) without the spawn cell erasing the tile under
## it. With no overlay, spawns are read from the terrain grid (legacy maps).
static func parse(text: String) -> Dictionary:
	var meta := {}
	var terrain_rows: Array[String] = []
	var overlay_rows: Array[String] = []
	var section := 0  # 0 = front-matter, 1 = terrain grid, 2 = spawn overlay
	for line in text.split("\n", false):
		var l := line
		if section == 0:
			if l.strip_edges() == "---":
				section = 1
				continue
			var c := l.find(";")
			if c != -1:
				l = l.substr(0, c)
			var colon := l.find(":")
			if colon != -1:
				meta[l.substr(0, colon).strip_edges()] = l.substr(colon + 1).strip_edges()
			continue
		if l.strip_edges() == "---":
			section = 2  # second divider -> the rest is the spawn overlay
			continue
		var c2 := l.find(";")
		if c2 != -1:
			l = l.substr(0, c2)
		l = l.rstrip(" \t\r")
		if section == 1:
			terrain_rows.append(l)
		else:
			overlay_rows.append(l)
	if terrain_rows.is_empty() and overlay_rows.is_empty():
		for line in text.split("\n", false):
			terrain_rows.append(line.rstrip(" \t\r"))
	_trim_blank_edges(terrain_rows)
	# NB: do NOT trim the overlay — its blank top/bottom rows keep it row-aligned
	# with the terrain. Trimming leading blanks would shift every spawn upward.
	var width := 0
	for r in terrain_rows:
		width = maxi(width, r.length())
	for r in overlay_rows:
		width = maxi(width, r.length())
	var grid: Array[String] = []
	for r in terrain_rows:
		grid.append(r.rpad(width, " "))
	var overlay: Array[String] = []
	for r in overlay_rows:
		overlay.append(r.rpad(width, " "))

	# spawns come from the overlay if present, else the terrain grid (legacy)
	var spawn_grid: Array = overlay if overlay.size() > 0 else grid
	var player_spawns: Array[Vector2i] = []
	var enemy_spawns: Array[Vector2i] = []
	var named := {}
	for y in spawn_grid.size():
		var row: String = spawn_grid[y]
		for x in row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			if ch == "P":
				player_spawns.append(cell)
			elif ch == "E":
				enemy_spawns.append(cell)
			elif ch >= "1" and ch <= "9":
				named[ch] = cell
	return {
		"meta": meta, "grid": grid, "overlay": overlay, "size": Vector2i(width, grid.size()),
		"player_spawns": player_spawns, "enemy_spawns": enemy_spawns, "named": named,
	}

static func _trim_blank_edges(rows: Array) -> void:
	while rows.size() > 0 and rows[0].strip_edges() == "":
		rows.remove_at(0)
	while rows.size() > 0 and rows[rows.size() - 1].strip_edges() == "":
		rows.remove_at(rows.size() - 1)

static func load_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("MapLoader: file not found: " + path)
		return {}
	return parse(FileAccess.get_file_as_string(path))

static func _is_interior(grid: Array, x: int, y: int) -> bool:
	if y < 0 or y >= grid.size():
		return false
	var row: String = grid[y]
	if x < 0 or x >= row.length():
		return false
	var ch := row[x]
	# The fence's INSIDE: yard-interior grass ('g'), the stone pad ('o'), and
	# units (digits). Plain '.' grass is OUTSIDE the fence too, so it's excluded
	# -- counting it made corner cells pick rail tiles (the "corners" bug).
	return ch == "g" or ch == "o" or (ch >= "1" and ch <= "9")

static func _fence_piece(grid: Array, x: int, y: int) -> Vector2i:
	# Edges face interior orthogonally; corners face interior diagonally. Check
	# edges first, then corners.
	var iN := _is_interior(grid, x, y - 1)
	var iS := _is_interior(grid, x, y + 1)
	var iE := _is_interior(grid, x + 1, y)
	var iW := _is_interior(grid, x - 1, y)
	if iS: return FENCE["t"]   # interior below -> top edge
	if iN: return FENCE["b"]
	if iE: return FENCE["l"]
	if iW: return FENCE["r"]
	if _is_interior(grid, x + 1, y + 1): return FENCE["tl"]  # interior SE -> top-left corner
	if _is_interior(grid, x - 1, y + 1): return FENCE["tr"]
	if _is_interior(grid, x + 1, y - 1): return FENCE["bl"]
	if _is_interior(grid, x - 1, y - 1): return FENCE["br"]
	return FENCE["c"]

static func _is_plateau(grid: Array, x: int, y: int) -> bool:
	# Any tile that's part of the map (not a ledge edge, not off-map void).
	if y < 0 or y >= grid.size():
		return false
	var row: String = grid[y]
	if x < 0 or x >= row.length():
		return false
	var ch := row[x]
	return ch != "L" and ch != " "

static func _ledge_piece(grid: Array, x: int, y: int) -> Vector2i:
	# Edge faces the void; interior is the plateau. Same orientation as the fence.
	if _is_plateau(grid, x, y + 1): return LEDGE["t"]
	if _is_plateau(grid, x, y - 1): return LEDGE["b"]
	if _is_plateau(grid, x + 1, y): return LEDGE["l"]
	if _is_plateau(grid, x - 1, y): return LEDGE["r"]
	if _is_plateau(grid, x + 1, y + 1): return LEDGE["tl"]
	if _is_plateau(grid, x - 1, y + 1): return LEDGE["tr"]
	if _is_plateau(grid, x + 1, y - 1): return LEDGE["bl"]
	if _is_plateau(grid, x - 1, y - 1): return LEDGE["br"]
	return LEDGE["c"]

## Place the parsed grid onto the layers.
## base = ground, walls = impassable, objects = (reserved), decor = inert scatter.
static func populate(parsed: Dictionary, base_layer: TileMapLayer, walls_layer: TileMapLayer,
		objects_layer: TileMapLayer = null, decor_layer: TileMapLayer = null) -> void:
	var grid: Array = parsed.get("grid", [])
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for y in grid.size():
		var row: String = grid[y]
		for x in row.length():
			var ch := row[x]
			if ch == " ":
				continue
			var cell := Vector2i(x, y)
			var role: String = ROLE.get(ch, "walk")
			match role:
				"fence":
					# Fence posts are transparent -> need grass under them, not void.
					base_layer.set_cell(cell, SRC, T_GRASS)
					walls_layer.set_cell(cell, SRC, _fence_piece(grid, x, y))
				"ledge":
					# Cliff face: impassable drop. Upper area = grass on top, rock below.
					base_layer.set_cell(cell, SRC, T_GRASS)
					walls_layer.set_cell(cell, SRC, T_CLIFF)
				"stairs":
					# The one walkable break in the cliff (down into the ring).
					base_layer.set_cell(cell, SRC, T_STAIRS)
				"block":
					base_layer.set_cell(cell, SRC, T_GRASS)
					walls_layer.set_cell(cell, SRC, T_BRICK)
				"tree":
					# Big 3x3 tree (thematic). Blocks movement, so the map must space
					# them out and keep enemy spawns/lanes clear of them.
					base_layer.set_cell(cell, SRC, T_GRASS)
					walls_layer.set_cell(cell, SRC, T_TREE3)
				"cover":
					# Single-tile tree = walkable cover on Objects (forest variation,
					# scattered brush). Does NOT block movement.
					base_layer.set_cell(cell, SRC, T_GRASS)
					if objects_layer:
						objects_layer.set_cell(cell, SRC, T_TREE)
				_:  # walk / back -> ground tile
					var atlas := T_GRASS
					if ch == ",":
						atlas = T_DIRT
					elif ch == "o":
						atlas = T_PAD
					base_layer.set_cell(cell, SRC, atlas)
					# inert decor scatter on plain yard grass only
					if decor_layer and ch == "." and rng.randf() < 0.12:
						decor_layer.set_cell(cell, SRC, DECOR_TILES[rng.randi() % DECOR_TILES.size()])

## Render the grid back to text.
static func render(parsed: Dictionary) -> String:
	var grid: Array = parsed.get("grid", [])
	return "\n".join(grid)
