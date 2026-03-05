extends Node

# Player Data Manager Singleton
# Handles saving/loading player name, party, and character stats

var player_name: String = "HERO"
var party: Array = [] # Array of character dicts: {id, resource, stats}

const SAVE_PATH := "user://player_data.json"

func set_player_name(name: String) -> void:
	player_name = name

func get_player_name() -> String:
	return player_name

func set_party(new_party: Array) -> void:
	party = new_party

func get_party() -> Array:
	return party

func save_player_data() -> void:
	var data = {
		"player_name": player_name,
		"party": party
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_player_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var result = JSON.parse_string(content)
		if typeof(result) == TYPE_DICTIONARY:
			player_name = result.get("player_name", "HERO")
			party = result.get("party", [])
		file.close()

func reset_player_data() -> void:
	player_name = "HERO"
	party = []
	# Optionally delete save file
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
