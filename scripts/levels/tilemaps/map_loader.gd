# MapLoader - turns a plain-text ".map" file into tilemap cells + spawn data.
# Maps are authored as ASCII grids (see docs/text_map_system.md) so they can be
# created and iterated in chat, version-controlled, and rendered back as text.
#
# Format: optional `key: value` front-matter, a `---` separator, then the grid.
# `;` begins a comment. Each grid char maps to a layer + tile via LEGEND.
class_name MapLoader
extends RefCounted

const SRC := 2  # Solaria Demo Tiles source id (see tileset.tres)

# char -> { layer: "base"|"walls", atlas: Vector2i, spawn: "player"|"enemy"|"named" }
# Atlas coords are real, pulled from dev_sandbox. Water arrives in v1.1.
# Atlas coords are real, verified against the Solaria sheet (source id 2). Tiles
# with an "overlay" place a grass base on BaseGrid + a decorative tile on the
# Objects layer (trees are transparent, so they need grass under them).
const LEGEND := {
	".": {"layer": "base", "atlas": Vector2i(5, 0)},                       # grass floor
	",": {"layer": "base", "atlas": Vector2i(5, 3)},                       # dirt road/path (def -1)
	"o": {"layer": "base", "atlas": Vector2i(10, 6)},                      # stone floor
	"T": {"layer": "base", "atlas": Vector2i(5, 0), "overlay": Vector2i(7, 3)},  # tree on grass (cover: def +2, cost 2)
	"#": {"layer": "walls", "atlas": Vector2i(10, 3)},                     # brick wall (impassable)
	"P": {"layer": "base", "atlas": Vector2i(5, 0), "spawn": "player"},
	"E": {"layer": "base", "atlas": Vector2i(5, 0), "spawn": "enemy"},
}
const FLOOR_ATLAS := Vector2i(5, 0)

## Parse text into a structured map. Returns:
## { meta:Dictionary, grid:Array[String], size:Vector2i,
##   player_spawns:Array[Vector2i], enemy_spawns:Array[Vector2i], named:Dictionary }
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
		# grid line: strip a trailing comment but keep interior spaces (void tiles)
		var c2 := l.find(";")
		if c2 != -1:
			l = l.substr(0, c2)
		raw_rows.append(l.rstrip(" \t\r"))

	# If there was no front-matter/separator, the whole thing is the grid.
	if raw_rows.is_empty():
		for line in text.split("\n", false):
			raw_rows.append(line.rstrip(" \t\r"))

	# Trim leading/trailing fully-blank rows.
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
		"meta": meta,
		"grid": grid,
		"size": Vector2i(width, grid.size()),
		"player_spawns": player_spawns,
		"enemy_spawns": enemy_spawns,
		"named": named,
	}

static func load_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("MapLoader: file not found: " + path)
		return {}
	return parse(FileAccess.get_file_as_string(path))

## Place the parsed grid onto the given tile layers. Spawns become floor.
## objects_layer receives decorative overlays (trees) over a grass base.
static func populate(parsed: Dictionary, base_layer: TileMapLayer, walls_layer: TileMapLayer, objects_layer: TileMapLayer = null) -> void:
	var grid: Array = parsed.get("grid", [])
	for y in grid.size():
		var row: String = grid[y]
		for x in row.length():
			var ch := row[x]
			if ch == " ":
				continue  # void: no tile
			var info: Dictionary = LEGEND.get(ch, {})
			var cell := Vector2i(x, y)
			if (ch >= "1" and ch <= "9") or info.is_empty():
				# named slots and unknown chars become plain floor
				base_layer.set_cell(cell, SRC, FLOOR_ATLAS)
				continue
			var layer := base_layer if info.get("layer", "base") == "base" else walls_layer
			layer.set_cell(cell, SRC, info["atlas"])
			if info.has("overlay") and objects_layer != null:
				objects_layer.set_cell(cell, SRC, info["overlay"])

## Render the grid back to text (for chat + self-verification).
static func render(parsed: Dictionary) -> String:
	var grid: Array = parsed.get("grid", [])
	return "\n".join(grid)
