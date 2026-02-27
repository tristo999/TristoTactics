extends BaseLevel

const PORTRAIT_MARCUS := preload("res://assets/sprites/portraits/marcus_portrait.tres")
const PORTRAIT_ELENA := preload("res://assets/sprites/portraits/elena_portrait.tres")

func _ready():
	music_key = "battle"
	_setup_intro_event()
	super._ready()

func _setup_intro_event() -> void:
	var gm = $GameManager
	if not gm:
		return

	var line1 := DialogueLine.new()
	line1.speaker = "Marcus"
	line1.text = "There they are... goblins blocking the mountain pass. We need to clear them out."
	line1.portrait = PORTRAIT_MARCUS

	var line2 := DialogueLine.new()
	line2.speaker = "Elena"
	line2.text = "I count five of them. I'll hang back and pick them off from range."
	line2.portrait = PORTRAIT_ELENA

	var line3 := DialogueLine.new()
	line3.speaker = "Marcus"
	line3.text = "Good plan. Let's move!"
	line3.portrait = PORTRAIT_MARCUS

	var event := DialogueEvent.new()
	event.lines = [line1, line2, line3]
	gm.intro_event = event
