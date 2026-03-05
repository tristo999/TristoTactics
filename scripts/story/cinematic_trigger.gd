# CinematicTrigger - Place anywhere in a walking scene to fire a sequence of StoryEvents
# when the player steps onto this node's tile.
#
# This is the primary tool for authoring all story beats in walking scenes:
# Guardian contact, Bleed activation, name entry, scene transitions, NPC cutscenes, etc.
#
# Workflow:
#   1. Add a CinematicTrigger Node2D to the scene in the editor.
#   2. Position it on the tile you want to trigger on.
#   3. Populate the `events` array from the scene script (custom Resource subclasses
#      cannot be embedded as sub_resources in .tscn files).
#   4. Toggle lock_player if the player should freeze while events play.
#   5. one_shot = true (default) means it fires only once per session.
extends Node2D
class_name CinematicTrigger

## The ordered list of events to execute when triggered.
@export var events: Array[StoryEvent] = []
## If true, fires only once — then disables itself.
@export var one_shot: bool = true
## Lock WalkingPlayer movement for the duration of the event sequence.
@export var lock_player: bool = true

var _fired: bool = false
var _player: WalkingPlayer = null
var _base_layer: TileMapLayer = null

func _ready() -> void:
	add_to_group("cinematic_trigger")
	# Resolve tilemap reference deferred so scene is fully ready
	call_deferred("_resolve_tilemap")

func _resolve_tilemap() -> void:
	var tilemap := get_tree().get_first_node_in_group("tilemap")
	if tilemap:
		_base_layer = tilemap.get_node_or_null("BaseGrid") as TileMapLayer
	else:
		push_warning("[CinematicTrigger] " + name + " could not find 'tilemap' group node")

func _process(_delta: float) -> void:
	if _fired and one_shot:
		return

	if not _player:
		_player = get_tree().get_first_node_in_group("walking_player") as WalkingPlayer
		if not _player:
			return

	if not _base_layer:
		return

	var our_tile := _base_layer.local_to_map(_base_layer.to_local(global_position))
	# Uncomment next line to spam tile positions while walking:
	# print("[CinematicTrigger] ", name, " player_tile=", _player.current_tile, " our_tile=", our_tile)
	if _player.current_tile == our_tile:
		_fire()

func _fire() -> void:
	if one_shot:
		_fired = true
		set_process(false)

	if lock_player and _player:
		_player.lock_movement()

	for event in events:
		await event.execute(get_tree())

	if lock_player and _player:
		_player.unlock_movement()

## Reset so the trigger can fire again (call this to replay a non-one-shot event in editor tests).
func reset() -> void:
	_fired = false
	set_process(true)
