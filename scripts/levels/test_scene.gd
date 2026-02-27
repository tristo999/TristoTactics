extends BaseLevel

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

	var line2 := DialogueLine.new()
	line2.speaker = "Elena"
	line2.text = "I count five of them. I'll hang back and pick them off from range."

	var line3 := DialogueLine.new()
	line3.speaker = "Marcus"
	line3.text = "Good plan. Let's move!"

	var event := DialogueEvent.new()
	event.lines = [line1, line2, line3]
	gm.intro_event = event
