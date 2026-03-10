# PlayerDataManager - Autoload singleton.
# Tracks player name, current checkpoint scene, story flags, and party.
# Single save slot at user://player_data.json.
extends Node

var player_name: String = "HERO"
## Scene path to load when the player chooses Continue.
var current_scene: String = ""
## Story flags: keys are flag names, presence means the flag is set.
var story_flags: Dictionary = {}
var party: Array = [] # Array of character dicts: {id, resource, stats}

const SAVE_PATH := "user://player_data.json"

# ---------------------------------------------------------------------------
# Save / load
# ---------------------------------------------------------------------------

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_player_data() -> bool:
	var data := {
		"player_name": player_name,
		"current_scene": current_scene,
		"story_flags": story_flags,
		"party": party,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_warning("[PlayerDataManager] Failed to open save file for writing: %s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true

func load_player_data() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_warning("[PlayerDataManager] Failed to open save file for reading: %s" % SAVE_PATH)
		return false
	var content := file.get_as_text()
	file.close()
	var result = JSON.parse_string(content)
	if typeof(result) != TYPE_DICTIONARY:
		push_warning("[PlayerDataManager] Save file is corrupted or not valid JSON")
		return false
	player_name = result.get("player_name", "HERO")
	current_scene = result.get("current_scene", "")
	story_flags = result.get("story_flags", {})
	party = result.get("party", [])
	return true

func reset_player_data() -> void:
	player_name = "HERO"
	current_scene = ""
	story_flags = {}
	party = []
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

# ---------------------------------------------------------------------------
# Player name
# ---------------------------------------------------------------------------

func set_player_name(name: String) -> void:
	player_name = name

func get_player_name() -> String:
	return player_name

# ---------------------------------------------------------------------------
# Checkpoint
# ---------------------------------------------------------------------------

## Record which scene Continue should load.
func set_checkpoint(scene_path: String) -> void:
	current_scene = scene_path

# ---------------------------------------------------------------------------
# Story flags
# ---------------------------------------------------------------------------

## Mark a named story beat as having occurred.
func set_story_flag(flag: String) -> void:
	story_flags[flag] = true

## Returns true if the flag has been set.
func has_story_flag(flag: String) -> bool:
	return story_flags.get(flag, false)

# ---------------------------------------------------------------------------
# Party
# ---------------------------------------------------------------------------

func set_party(new_party: Array) -> void:
	party = new_party

func get_party() -> Array:
	return party
