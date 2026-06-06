# SaveCheckpointEvent - Records a scene as the next checkpoint and writes the save file.
# Place before a SceneChangeEvent so that Continue from the main menu loads the
# destination scene rather than repeating the current one.
class_name SaveCheckpointEvent
extends StoryEvent

## The scene path to record as the checkpoint (typically the scene you're about to enter).
@export_file("*.tscn") var scene_path: String = ""

func execute(_scene_tree: SceneTree) -> void:
	if scene_path.is_empty():
		push_warning("SaveCheckpointEvent: scene_path is empty — skipping save.")
		return
	PlayerDataManager.set_checkpoint(scene_path)
	PlayerDataManager.save_player_data()
