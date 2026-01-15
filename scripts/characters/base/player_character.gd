# PlayerCharacter - Player-controlled character
extends CharacterBase

@export var distance: int = 5:
	set(value):
		override_move_range = value
	get:
		return override_move_range if override_move_range > 0 else 5

func _ready() -> void:
	team = Constants.TEAM_PLAYER
	super._ready()
