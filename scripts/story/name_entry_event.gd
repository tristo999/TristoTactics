# NameEntryEvent - Prompts the player to enter their name via NameEntryDisplay.
# Call early in the opening sequence before any event uses {player_name}.
# The name is saved to PlayerDataManager automatically on confirm.
class_name NameEntryEvent
extends StoryEvent

## The prompt text shown above the input field.
@export_multiline var prompt_text: String = "What is your name?"

func execute(scene_tree: SceneTree) -> void:
	var display := scene_tree.get_first_node_in_group("name_entry_display") as NameEntryDisplay
	if not display:
		push_warning("NameEntryEvent: no NameEntryDisplay found in group 'name_entry_display'")
		return
	await display.prompt(prompt_text)
