## TutorialTilemap - Procedurally generates the tutorial corridor at runtime.
## Extends the base tilemap so pathfinding initializes correctly after tile placement.
extends "res://scripts/levels/tilemaps/tilemap.gd"

## How many tiles wide each side of the corridor is (total width = side*2 + 1).
const CORRIDOR_HALF_WIDTH := 1
## How many tile rows the corridor extends downward from the hero's start.
const CORRIDOR_LENGTH := 10

## Source ID 2 = Solaria Demo Tiles (as registered in tileset.tres).
const SOURCE_FLOOR := 2
## A plain ground tile atlas coord from the Solaria sheet.
const ATLAS_FLOOR := Vector2i(5, 0)

func _ready() -> void:
	_generate_corridor()
	super._ready()

func _generate_corridor() -> void:
	# base_layer is @onready in the parent so isn't populated yet — get it directly.
	var floor_layer := $BaseGrid as TileMapLayer
	if not floor_layer:
		push_error("TutorialTilemap: BaseGrid not found.")
		return
	for row in range(CORRIDOR_LENGTH):
		for col in range(-CORRIDOR_HALF_WIDTH, CORRIDOR_HALF_WIDTH + 1):
			floor_layer.set_cell(Vector2i(col, row), SOURCE_FLOOR, ATLAS_FLOOR)
