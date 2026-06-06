## Data-driven tutorial battle: builds its arena from a .map file (the child
## TextMapTilemap) and spawns the roster onto the map's spawn slots. No hand-placed
## units — edit data/maps/tutorial.map and the ROSTER below, both in chat.
extends BaseLevel

## spawn-key -> roster entry. Named slots 1/2/3 are the squad; E = insurgents.
const ROSTER := {
	"1": {"data": "res://data/characters/archer.tres", "name": "Elena"},
	"2": {"data": "res://data/characters/dwarf.tres", "name": "Borin"},
	"3": {"data": "res://data/characters/healer.tres", "name": "Lyra"},
	"E": {"data": "res://data/characters/goblin.tres", "name": "Insurgent"},
}

func _ready() -> void:
	music_key = "battle"
	_spawn_roster()
	super._ready()

func _spawn_roster() -> void:
	var tilemap = get_tree().get_first_node_in_group("tilemap")
	if tilemap == null:
		push_error("TutorialBattle: no tilemap in scene.")
		return
	var units := BattleSpawner.spawn(tilemap, ROSTER, $PlayerTeam, $EnemyTeam)
	print("[TutorialBattle] spawned %d units onto %s" % [units.size(), tilemap.map_file])
