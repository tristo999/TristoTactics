# StoryEvent - Base class for events that pause gameplay.
# Subclass and override execute() for dialogue, cutscenes, env changes, etc.
class_name StoryEvent
extends Resource

## Emitted after the event finishes executing (fired by GameManager.play_event).
signal completed

## Override in subclasses with event-specific logic.
## Awaitable — gameplay stays paused until this returns.
func execute(_scene_tree: SceneTree) -> void:
	pass
