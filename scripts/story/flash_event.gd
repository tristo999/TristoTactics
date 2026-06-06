# FlashEvent - Plays a full-screen color flash via the ScreenOverlay in the scene.
# For warp moments, waking up, boss hits, etc.
# Set hold_and_cut = true to flash to full color and leave it (for scene transitions).
class_name FlashEvent
extends StoryEvent

@export var color: Color = Color.WHITE
@export var fade_in: float = 0.12
@export var hold: float = 0.35
@export var fade_out: float = 0.55
## If true: flash to full color and STOP there (scene switches while white).
## Caller is responsible for changing scenes while screen is held.
@export var hold_and_cut: bool = false

func execute(scene_tree: SceneTree) -> void:
	var overlay := scene_tree.get_first_node_in_group("screen_overlay") as ScreenOverlay
	if not overlay:
		push_warning("FlashEvent: no ScreenOverlay found in group 'screen_overlay'")
		return
	if hold_and_cut:
		await overlay.flash_hold(color, fade_in)
	else:
		await overlay.flash(color, fade_in, hold, fade_out)
