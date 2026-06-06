# CallbackEvent - A StoryEvent that calls an arbitrary Callable.
# Use for one-off effects within a CinematicTrigger sequence that don't
# warrant their own StoryEvent subclass (e.g. toggling fragment colors,
# starting particles, etc.)
#
# Usage:
#   var cb := CallbackEvent.new()
#   cb.callback = _bleed_fragments
#   trigger.events.append(cb)
class_name CallbackEvent
extends StoryEvent

## The function to call when this event executes.
## Set this in code — it cannot be exported.
var callback: Callable = Callable()

func execute(_scene_tree: SceneTree) -> void:
	if callback.is_valid():
		var result = callback.call()
		# If the callback returns something awaitable, await it
		if result is Signal:
			await result
