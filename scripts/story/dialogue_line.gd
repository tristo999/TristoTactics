# DialogueLine - One line of dialogue data.
class_name DialogueLine
extends Resource

@export var speaker: String = ""
@export var text: String = ""
@export var portrait: Texture2D ## Character headshot (leave null for no portrait)
## If true, each character flickers through glitch noise before resolving.
@export var glitched: bool = false
