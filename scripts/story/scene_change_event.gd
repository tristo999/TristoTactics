# SceneChangeEvent - Transitions to a new scene at the end of an event sequence.
# Pair with a FlashEvent(hold_and_cut=true) immediately before this so the screen
# is already white/black when the scene swap happens — seamless cut.
class_name SceneChangeEvent
extends StoryEvent

## Path to the target scene file.
@export_file("*.tscn") var scene_path: String = ""

func execute(scene_tree: SceneTree) -> void:
	if scene_path.is_empty():
		push_warning("SceneChangeEvent: scene_path is empty — nothing to do.")
		return
	scene_tree.change_scene_to_file(scene_path)
