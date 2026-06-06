# DialogueLine - One line of dialogue data.
class_name DialogueLine
extends Resource

@export var speaker: String = ""
@export var text: String = ""
@export var portrait: Texture2D ## Character headshot (leave null for no portrait)
## If true, each character flickers through glitch noise before resolving.
@export var glitched: bool = false
## Seconds to wait after typing finishes before auto-advancing. -1 = require player input.
@export var auto_advance_delay: float = -1.0
## Characters per second for this line. -1 uses the DialogueBox default (30).
@export var chars_per_second: float = -1.0
## SFX key played per resolved character. Blank uses the box default.
@export var type_sfx_key: String = ""
