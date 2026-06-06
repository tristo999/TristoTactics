extends BaseLevel

const PORTRAIT_HERO := preload("res://assets/sprites/portraits/hero_portrait.tres")

func _ready() -> void:
	music_key = "menu"
	super._ready()
