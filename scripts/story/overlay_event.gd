# OverlayEvent - Tweens the darkness or bleed intensity on the ScreenOverlay.
# Drop in an event sequence to ramp up or remove these effects over time.
class_name OverlayEvent
extends StoryEvent

enum Layer {DARKNESS, BLEED}

## Which overlay to affect.
@export var layer: Layer = Layer.DARKNESS
## Target intensity value (0.0 = off, 1.0 = full effect).
@export_range(0.0, 1.0) var target: float = 1.0
## How long the tween takes in seconds.
@export var duration: float = 1.0

func execute(scene_tree: SceneTree) -> void:
	var overlay := scene_tree.get_first_node_in_group("screen_overlay") as ScreenOverlay
	if not overlay:
		push_warning("OverlayEvent: no ScreenOverlay found in group 'screen_overlay'")
		return
	match layer:
		Layer.DARKNESS:
			await overlay.tween_darkness(target, duration)
		Layer.BLEED:
			await overlay.tween_bleed(target, duration)
