# DamagePopupManager - Spawns damage popups when characters are damaged
extends Node

const DamagePopupScene = preload("res://scenes/ui/DamagePopup.tscn")

func _ready() -> void:
	EventBus.show_damage_popup.connect(_on_show_damage_popup)

func _on_show_damage_popup(target: Node2D, amount: int, is_crit: bool) -> void:
	var popup = DamagePopupScene.instantiate()
	get_tree().current_scene.add_child(popup)
	# Position next to the character (small offset to the right and up)
	popup.global_position = target.global_position + Vector2(8, -8)
	popup.setup(amount, is_crit)
