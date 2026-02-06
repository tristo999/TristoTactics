# BattleInputHandler - Processes player mouse clicks during battle
# Decoupled from the tilemap: reads tile data, sends actions to GameManager.
extends Node

var game_manager: Node
var tilemap_node: Node2D


func _ready() -> void:
	# Deferred so sibling nodes (GameManager, tilemap) have finished _ready() first
	call_deferred("_cache_references")

func _cache_references() -> void:
	var scene = get_tree().get_current_scene()
	if scene:
		game_manager = scene.find_child("GameManager", true, false)
	tilemap_node = get_tree().get_first_node_in_group("tilemap")


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not game_manager or not tilemap_node:
		return

	var character = game_manager.current_character
	if not character or character.moving:
		return
	if game_manager.is_enemy_turn():
		return

	var tile := _get_tile_at_mouse()

	# Attack takes priority — can happen any time during the player's turn
	var target = tilemap_node.get_character_at_tile(tile)
	if target and character.can_attack_target(target):
		game_manager.request_attack(character, target)
		return

	# Movement (only if the tile is in the cached reachable set)
	if character.movement_left > 0 and tile in tilemap_node.cached_reachable_tiles:
		game_manager.request_move(character, tile)


func _get_tile_at_mouse() -> Vector2i:
	var base_layer: TileMapLayer = tilemap_node.base_layer
	var mouse_pos := base_layer.get_global_mouse_position()
	var local_mouse := base_layer.to_local(mouse_pos)
	return base_layer.local_to_map(local_mouse)
