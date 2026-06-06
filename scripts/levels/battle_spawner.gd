## BattleSpawner - turns a TextMapTilemap's spawn slots + a roster dictionary into
## live characters. A fight = a .map file + a roster, both chat-editable.
##
## Roster format (keyed by the map's spawn char):
##   "1".."9" : named slot  -> player unit  { "data": <path>, "name": <String> }
##   "P"      : default for every plain `P` player spawn
##   "E"      : default for every plain `E` enemy spawn (auto-numbered)
## `data` is a path to a CharacterData .tres (or a CharacterData resource directly).
class_name BattleSpawner
extends RefCounted

const PLAYER_SCENE := preload("res://scenes/characters/PlayerCharacter.tscn")
const ENEMY_SCENE := preload("res://scenes/characters/EnemyCharacter.tscn")

## Spawn every roster-matched slot onto `tilemap`. Players parent to `player_parent`,
## enemies to `enemy_parent`. Returns the list of spawned CharacterBase nodes.
static func spawn(tilemap, roster: Dictionary, player_parent: Node, enemy_parent: Node) -> Array:
	var spawned: Array = []
	if tilemap == null or not ("spawn_data" in tilemap):
		push_error("BattleSpawner: tilemap missing spawn_data.")
		return spawned
	var data: Dictionary = tilemap.spawn_data

	# Named slots (1-9) -> player units.
	for key in data.named.keys():
		if roster.has(key):
			var entry: Dictionary = roster[key]
			spawned.append(_make(tilemap, data.named[key], entry, PLAYER_SCENE, player_parent,
				entry.get("name", "Unit %s" % key)))

	# Generic player spawns (P).
	if roster.has("P"):
		var i := 1
		for tile in data.player_spawns:
			spawned.append(_make(tilemap, tile, roster["P"], PLAYER_SCENE, player_parent,
				"%s %d" % [roster["P"].get("name", "Ally"), i]))
			i += 1

	# Enemy spawns (E).
	if roster.has("E"):
		var i := 1
		for tile in data.enemy_spawns:
			spawned.append(_make(tilemap, tile, roster["E"], ENEMY_SCENE, enemy_parent,
				"%s %d" % [roster["E"].get("name", "Enemy"), i]))
			i += 1

	return spawned

static func _make(tilemap, tile: Vector2i, entry: Dictionary, scene: PackedScene,
		parent: Node, unit_name: String) -> CharacterBase:
	var unit := scene.instantiate() as CharacterBase
	var cd = entry.get("data")
	if cd is String:
		cd = load(cd)
	unit.character_data = cd
	unit.name = unit_name
	parent.add_child(unit)
	unit.global_position = tilemap.tile_to_global(tile)
	return unit
