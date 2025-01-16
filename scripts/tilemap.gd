extends Node

@onready var tilemap: TileMapLayer = $BaseGrid
@export var grid_size: Vector2i = Vector2i(16, 16) # Set to match your tile size

var astar = AStarGrid2D.new()

func _ready():
	astar.region = tilemap.get_used_rect()
	astar.cell_size = grid_size
	astar.update()
	
