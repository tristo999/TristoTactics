# DialogueEvent - A story event that plays a sequence of dialogue lines.
class_name DialogueEvent
extends StoryEvent

@export var lines: Array[DialogueLine] = []

func execute(scene_tree: SceneTree) -> void:
	if lines.is_empty():
		return

	var dialogue_box = scene_tree.get_first_node_in_group("dialogue_box")
	if not dialogue_box:
		push_warning("DialogueEvent: No dialogue_box found in group 'dialogue_box'")
		return

	await dialogue_box.play_sequence(lines)
