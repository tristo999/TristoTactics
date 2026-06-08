## Data-driven tutorial battle: builds its arena from a .map file (the child
## TextMapTilemap) and spawns the roster onto the map's spawn slots. No hand-placed
## units — edit data/maps/tutorial.map and the ROSTER below, both in chat.
extends BaseLevel

const PORTRAIT_ELENA := preload("res://assets/sprites/portraits/elena_portrait.tres")

## spawn-key -> roster entry. Slots 1/2/3 = your squad; 5/6/7 = AI green allies
## (camp recruits) fighting alongside you; E = insurgents.
const ROSTER := {
	"1": {"data": "res://data/characters/archer.tres", "name": "Elena"},
	"2": {"data": "res://data/characters/dwarf.tres", "name": "Borin"},
	"3": {"data": "res://data/characters/healer.tres", "name": "Lyra"},
	"5": {"data": "res://data/characters/hero.tres", "name": "Recruit Sten", "team": "ally"},
	"6": {"data": "res://data/characters/hero.tres", "name": "Recruit Wynn", "team": "ally"},
	"7": {"data": "res://data/characters/hero.tres", "name": "Recruit Bram", "team": "ally"},
	"E": {"data": "res://data/characters/goblin.tres", "name": "Insurgent"},
}

func _ready() -> void:
	music_key = "battle"
	_spawn_roster()
	_setup_events()
	super._ready()

func _spawn_roster() -> void:
	var tilemap = get_tree().get_first_node_in_group("tilemap")
	if tilemap == null:
		push_error("TutorialBattle: no tilemap in scene.")
		return
	var units := BattleSpawner.spawn(tilemap, ROSTER, $PlayerTeam, $EnemyTeam, $AllyTeam)
	print("[TutorialBattle] spawned %d units onto %s" % [units.size(), tilemap.map_file])

func _setup_events() -> void:
	var gm = $GameManager
	if gm == null:
		return
	# Picks up the instant the spar cuts to black — the squad is already in it.
	gm.intro_event = _make_event([
		["Borin", "Backs to the pad! Let 'em break on us — Elena, Lyra, on me!"],
		["Elena", "...The lanes are mine. Nothing gets past.", PORTRAIT_ELENA],
		["Lyra", "Stay standing and I'll keep you that way. Go."],
	])
	gm.victory_event = _make_event([
		["Lyra", "That's the last of them. Everyone still on their feet?"],
		["Borin", "On my feet and then some. Fine shooting, Elena."],
		["Elena", "...I — yes. We held.", PORTRAIT_ELENA],
	])

## Build a DialogueEvent from [speaker, text, (optional portrait)] rows.
func _make_event(rows: Array) -> DialogueEvent:
	var event := DialogueEvent.new()
	event.lines = CineFx.lines(rows)
	return event
