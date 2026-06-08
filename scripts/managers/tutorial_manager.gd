## TutorialManager - Controls tutorial step progression, input locking, and trigger events.
extends Node
class_name TutorialManager

## The tile position the hero must reach to trigger the next event.
@export var trigger_tile: Vector2i = Vector2i(0, 3)

var _action_bar: Node = null
var _prompt: Control = null
var _triggered: bool = false

func _ready() -> void:
	add_to_group("tutorial_manager")
	call_deferred("_setup")

func _setup() -> void:
	await get_tree().process_frame
	_action_bar = get_tree().get_first_node_in_group("action_bar")
	_prompt = get_tree().get_first_node_in_group("tutorial_prompt")

	EventBus.turn_started.connect(_on_turn_started)
	EventBus.character_moved.connect(_on_character_moved)

	_show_prompt("Use the Move button, then select a highlighted tile to move forward.")

## Called each time a player turn starts — re-lock buttons so they stay locked after refreshes.
func _on_turn_started(_character: CharacterBase) -> void:
	if _triggered:
		return
	# Wait one frame so BottomActionBar finishes its own refresh first.
	await get_tree().process_frame
	_lock_buttons()

func _lock_buttons() -> void:
	if not _action_bar:
		return
	_action_bar.attack_button.disabled = true
	_action_bar.ability_button.disabled = true
	_action_bar.end_turn_button.disabled = true

func _on_character_moved(_character: Node2D, _from: Vector2i, to_tile: Vector2i) -> void:
	if _triggered:
		return
	if to_tile == trigger_tile:
		_triggered = true
		_hide_prompt()
		_fire_trigger_event()

func _fire_trigger_event() -> void:
	var event := DialogueEvent.new()
	event.lines = CineFx.lines([
		["???", "Hey! Over here! Don't just stand there!"],
		[PlayerDataManager.get_player_name(), "Who's there...?"],
	])
	EventBus.story_event_triggered.emit(event)

func _show_prompt(text: String) -> void:
	if _prompt:
		_prompt.set_prompt_text(text)
		_prompt.show()

func _hide_prompt() -> void:
	if _prompt:
		_prompt.hide()
