# WaitEvent - Pauses the event sequence for a fixed duration.
# Useful as a breathing moment between cinematic beats.
class_name WaitEvent
extends StoryEvent

@export var duration: float = 1.0

func execute(scene_tree: SceneTree) -> void:
	await scene_tree.create_timer(duration).timeout
