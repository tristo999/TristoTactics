extends BaseLevel

const PORTRAIT_HERO := preload("res://assets/sprites/portraits/hero_portrait.tres")
const PORTRAIT_ELENA := preload("res://assets/sprites/portraits/elena_portrait.tres")

func _ready():
	music_key = "battle"
	_setup_intro_event()
	super._ready()

func _setup_intro_event() -> void:
	var gm = $GameManager
	if not gm:
		return
	_setup_victory_event(gm)

	var line1 := DialogueLine.new()
	line1.speaker = PlayerDataManager.get_player_name()
	line1.text = "There they are... goblins blocking the mountain pass. We need to clear them out."
	line1.portrait = PORTRAIT_HERO

	var line2 := DialogueLine.new()
	line2.speaker = "Elena"
	line2.text = "I count five of them. I'll hang back and pick them off from range."
	line2.portrait = PORTRAIT_ELENA

	var line3 := DialogueLine.new()
	line3.speaker = PlayerDataManager.get_player_name()
	line3.text = "Good plan. Let's move!"
	line3.portrait = PORTRAIT_HERO

	var event := DialogueEvent.new()
	event.lines = [line1, line2, line3]
	gm.intro_event = event

func _setup_victory_event(gm: Node) -> void:
	var v1 := DialogueLine.new()
	v1.speaker = PlayerDataManager.get_player_name()
	v1.text = "That's the last of them. The pass is clear."
	v1.portrait = PORTRAIT_HERO

	var v2 := DialogueLine.new()
	v2.speaker = "Elena"
	v2.text = "Good work, everyone. That wasn't easy, but we pulled through."
	v2.portrait = PORTRAIT_ELENA

	var v3 := DialogueLine.new()
	v3.speaker = PlayerDataManager.get_player_name()
	v3.text = "Let's keep moving. There's no telling what else lies ahead."
	v3.portrait = PORTRAIT_HERO

	var victory_dialogue := DialogueEvent.new()
	victory_dialogue.lines = [v1, v2, v3]
	gm.victory_event = victory_dialogue
