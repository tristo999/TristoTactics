# PlayerCharacter - Player-controlled character
extends CharacterBase
class_name PlayerCharacter

func _ready() -> void:
	team = Constants.TEAM_PLAYER
	super._ready()
