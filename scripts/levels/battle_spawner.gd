## BattleSpawner - turns a TextMapTilemap's spawn slots + a roster dictionary into
## live characters. A fight = a .map file + a roster, both chat-editable.
##
## Roster format (keyed by the map's spawn char):
##   "1".."9" : named slot  -> player unit by default
##   "P"      : default for every plain `P` player spawn
##   "E"      : default for every plain `E` enemy spawn (auto-numbered)
## Each entry: { "data": <path|CharacterData>, "name": <String>, "team": <opt> }.
## "team" overrides the slot's default side: "player", "enemy", or "ally" (an
## AI-controlled green unit). Named slots default to player unless team is set.
class_name BattleSpawner
extends RefCounted

const PLAYER_SCENE := preload("res://scenes/characters/PlayerCharacter.tscn")
const ENEMY_SCENE := preload("res://scenes/characters/EnemyCharacter.tscn")

## Spawn every roster-matched slot onto `tilemap`. Parents by team; ally_parent
## defaults to player_parent if omitted. Returns the spawned CharacterBase nodes.
static func spawn(tilemap, roster: Dictionary, player_parent: Node, enemy_parent: Node,
		ally_parent: Node = null) -> Array:
	var spawned: Array = []
	if tilemap == null or not ("spawn_data" in tilemap):
		push_error("BattleSpawner: tilemap missing spawn_data.")
		return spawned
	if ally_parent == null:
		ally_parent = player_parent
	var data: Dictionary = tilemap.spawn_data
	var parents := {"player": player_parent, "enemy": enemy_parent, "ally": ally_parent}

	# Named slots (1-9) -> player by default, or whatever the entry's team says.
	for key in data.named.keys():
		if roster.has(key):
			var entry: Dictionary = roster[key]
			spawned.append(_make(tilemap, data.named[key], entry, "player", parents,
				entry.get("name", "Unit %s" % key)))

	# Generic player spawns (P).
	if roster.has("P"):
		var i := 1
		for tile in data.player_spawns:
			spawned.append(_make(tilemap, tile, roster["P"], "player", parents,
				"%s %d" % [roster["P"].get("name", "Ally"), i]))
			i += 1

	# Enemy spawns (E).
	if roster.has("E"):
		var i := 1
		for tile in data.enemy_spawns:
			spawned.append(_make(tilemap, tile, roster["E"], "enemy", parents,
				"%s %d" % [roster["E"].get("name", "Enemy"), i]))
			i += 1

	return spawned

static func _make(tilemap, tile: Vector2i, entry: Dictionary, default_team: String,
		parents: Dictionary, unit_name: String) -> CharacterBase:
	var team: String = entry.get("team", default_team)
	# Players use the player scene; enemies AND allies use the AI scene.
	var scene: PackedScene = PLAYER_SCENE if team == "player" else ENEMY_SCENE
	var unit := scene.instantiate() as CharacterBase
	if team == "ally":
		unit.team_override = Constants.TEAM_ALLY
	var cd = entry.get("data")
	if cd is String:
		cd = load(cd)
	unit.character_data = cd
	unit.name = unit_name
	parents.get(team, parents["player"]).add_child(unit)
	unit.global_position = tilemap.tile_to_global(tile)
	return unit
