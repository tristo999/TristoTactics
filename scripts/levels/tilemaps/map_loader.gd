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
const FLOOR_ATLAS := T_GRASS

# Wooden-post fence 9-slice (cols 0-2, rows 12-14). Interior = the yard side.
# (Rows 9-11 are the LEDGE set, not the fence.)
const FENCE := {
	"tl": Vector2i(0, 12), "t": Vector2i(1, 12), "tr": Vector2i(2, 12),
	"l": Vector2i(0, 13), "c": Vector2i(1, 12), "r": Vector2i(2, 13),
	"bl": Vector2i(0, 14), "b": Vector2i(1, 12), "br": Vector2i(2, 14),
}
# Inert decoration scatter (grass tufts / flowers).
const DECOR_TILES := [Vector2i(6, 0), Vector2i(6, 1)]

# char -> role. Terrain placement is handled in populate() by role.
#   walk:  walkable yard interior (counts as "interior" for fence autotiling)
#   block: impassable
#   back:  backdrop (outside the fight)
const ROLE := {
	".": "walk", ",": "walk", "o": "walk",
	"#": "fence", "B": "block", "T": "tree",
	"w": "back", "C": "back",
	"P": "walk", "E": "back",
}

## Parse text into a structured map.
static func parse(text: String) -> Dictionary:
	var meta := {}
	var raw_rows: Array[String] = []
	var in_grid := false
	for line in text.split("\n", false):
		var l := line
		if not in_grid:
			if l.strip_edges() == "---":
				in_grid = true
				continue
			var c := l.find(";")
			if c != -1:
				l = l.substr(0, c)
			var colon := l.find(":")
			if colon != -1:
				meta[l.substr(0, colon).strip_edges()] = l.substr(colon + 1).strip_edges()
			continue
		var c2 := l.find(";")
		if c2 != -1:
			l = l.substr(0, c2)
		raw_rows.append(l.rstrip(" \t\r"))
	if raw_rows.is_empty():
		for line in text.split("\n", false):
			raw_rows.append(line.rstrip(" \t\r"))
	while raw_rows.size() > 0 and raw_rows[0].strip_edges() == "":
		raw_rows.remove_at(0)
	while raw_rows.size() > 0 and raw_rows[raw_rows.size() - 1].strip_edges() == "":
		raw_rows.remove_at(raw_rows.size() - 1)
	var width := 0
	for r in raw_rows:
		width = maxi(width, r.length())
	var grid: Array[String] = []
	for r in raw_rows:
		grid.append(r.rpad(width, " "))

	var player_spawns: Array[Vector2i] = []
	var enemy_spawns: Array[Vector2i] = []
	var named := {}
	for y in grid.size():
		var row := grid[y]
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
		"meta": meta, "grid": grid, "size": Vector2i(width, grid.size()),
		"player_spawns": player_spawns, "enemy_spawns": enemy_spawns, "named": named,
	}

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
	# Yard-interior walkables (spawn digits count too).
	return ch in ".,oP" or (ch >= "1" and ch <= "9")

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
				"block":
					base_layer.set_cell(cell, SRC, T_GRASS)
					walls_layer.set_cell(cell, SRC, T_BRICK)
				"tree":
					# 3x3 large tree on the walls layer (blocks via size_in_atlas).
					base_layer.set_cell(cell, SRC, T_GRASS)
					walls_layer.set_cell(cell, SRC, T_TREE3)
				_:  # walk / back -> ground tile
					var atlas := T_GRASS
					if ch == ",":
						atlas = T_DIRT
					elif ch == "o":
						atlas = T_PAD
					elif ch == "C":
						atlas = T_DIRT   # camp = packed earth, distinct from the grass battlefield
					base_layer.set_cell(cell, SRC, atlas)
					# inert decor scatter on plain yard grass only
					if decor_layer and ch == "." and rng.randf() < 0.12:
						decor_layer.set_cell(cell, SRC, DECOR_TILES[rng.randi() % DECOR_TILES.size()])

## Render the grid back to text.
static func render(parsed: Dictionary) -> String:
	var grid: Array = parsed.get("grid", [])
	return "\n".join(grid)
