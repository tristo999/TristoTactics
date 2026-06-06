# FogEvent - Tweens the fog intensity on the ScreenOverlay.
# Drop in an event sequence to add or remove atmospheric fog over time.
class_name FogEvent
extends StoryEvent

## Target fog intensity (0.0 = clear, 1.0 = dense fog).
@export_range(0.0, 1.0) var target: float = 0.3
## How long the tween takes in seconds.
@export var duration: float = 2.0

func execute(scene_tree: SceneTree) -> void:
	var overlay := scene_tree.get_first_node_in_group("screen_overlay") as ScreenOverlay
	if not overlay:
		push_warning("FogEvent: no ScreenOverlay found in group 'screen_overlay'")
		return
	await overlay.tween_fog(target, duration)
