# HighlightRenderer - Custom draw-based tile highlight system.
extends Node2D
class_name HighlightRenderer

var base_layer: TileMapLayer

# --- Highlight State ---

var current_char_tile: Vector2i = Constants.INVALID_TILE
var movement_tiles: Array = []
var attack_tiles: Array = []
var ability_tiles: Array = []
var hover_tile: Vector2i = Constants.INVALID_TILE

# --- Style Constants ---

# Current character: bright green hollow square
const COLOR_CURRENT_CHAR := Color(0.1, 0.9, 0.2, 0.75)
const CURRENT_CHAR_LINE_WIDTH := 2.0

# Movement range: dark semi-transparent filled squares
# Dark dim-fill over reachable tiles (deliberate style — reads great on textured
# ground; Tristan ruled to keep it, 2026-06-10). KNOWN CAVEAT: on FLAT solid-color
# ground tiles it reads as featureless dark blobs, indistinguishable from missing
# tiles in stills (see docs/maps/highlight_evidence.png) — so battle maps should
# use textured/varied ground, not the flat grass tile, under playable areas.
const COLOR_MOVEMENT := Color(0.05, 0.08, 0.18, 0.65)

# Attack range: red smaller hollow squares overlaid on movement
const COLOR_ATTACK := Color(0.95, 0.15, 0.1, 0.65)
const ATTACK_LINE_WIDTH := 1.5
const ATTACK_INSET := 3.0

# Ability range: cyan/blue smaller hollow squares
const COLOR_ABILITY := Color(0.2, 0.7, 1.0, 0.65)
const ABILITY_LINE_WIDTH := 1.5
const ABILITY_INSET := 3.0

# Mouse hover: light outline
const COLOR_HOVER := Color(1.0, 1.0, 1.0, 0.35)
const HOVER_LINE_WIDTH := 1.0

# --- Setup ---

func setup(layer: TileMapLayer) -> void:
	base_layer = layer

# --- Public API ---

func set_current_character(tile: Vector2i) -> void:
	current_char_tile = tile
	queue_redraw()

func set_movement_tiles(tiles: Array) -> void:
	movement_tiles = tiles
	queue_redraw()

func set_attack_tiles(tiles: Array) -> void:
	attack_tiles = tiles
	queue_redraw()

func set_ability_tiles(tiles: Array) -> void:
	ability_tiles = tiles
	queue_redraw()

func set_hover(tile: Vector2i) -> void:
	if tile == hover_tile:
		return
	hover_tile = tile
	queue_redraw()

func clear_hover() -> void:
	if hover_tile == Constants.INVALID_TILE:
		return
	hover_tile = Constants.INVALID_TILE
	queue_redraw()

## Clears movement + attack ranges but keeps current character indicator & hover
func clear_range_highlights() -> void:
	movement_tiles = []
	attack_tiles = []
	ability_tiles = []
	queue_redraw()

func clear_all() -> void:
	current_char_tile = Constants.INVALID_TILE
	movement_tiles = []
	attack_tiles = []
	ability_tiles = []
	hover_tile = Constants.INVALID_TILE
	queue_redraw()

# --- Draw ---

func _draw() -> void:
	if not base_layer:
		return

	var tile_size := Vector2(base_layer.tile_set.tile_size)
	var half := tile_size / 2.0

	# 1. Movement range — dark filled squares
	for tile in movement_tiles:
		var center := base_layer.map_to_local(tile)
		draw_rect(Rect2(center - half, tile_size), COLOR_MOVEMENT, true)

	# 2. Attack range — smaller red hollow squares (overlaid on movement)
	var inset_vec := Vector2(ATTACK_INSET, ATTACK_INSET)
	for tile in attack_tiles:
		var center := base_layer.map_to_local(tile)
		draw_rect(
			Rect2(center - half + inset_vec, tile_size - inset_vec * 2),
			COLOR_ATTACK, false, ATTACK_LINE_WIDTH
		)

	# 2b. Ability range — cyan/blue hollow squares
	var ability_inset_vec := Vector2(ABILITY_INSET, ABILITY_INSET)
	for tile in ability_tiles:
		var center := base_layer.map_to_local(tile)
		draw_rect(
			Rect2(center - half + ability_inset_vec, tile_size - ability_inset_vec * 2),
			COLOR_ABILITY, false, ABILITY_LINE_WIDTH
		)

	# 3. Current character — green hollow square (full tile size)
	if current_char_tile != Constants.INVALID_TILE:
		var center := base_layer.map_to_local(current_char_tile)
		draw_rect(Rect2(center - half, tile_size), COLOR_CURRENT_CHAR, false, CURRENT_CHAR_LINE_WIDTH)

	# 4. Mouse hover — light outline
	if hover_tile != Constants.INVALID_TILE:
		var center := base_layer.map_to_local(hover_tile)
		draw_rect(Rect2(center - half, tile_size), COLOR_HOVER, false, HOVER_LINE_WIDTH)
