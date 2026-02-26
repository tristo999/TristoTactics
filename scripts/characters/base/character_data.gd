# CharacterData - Resource for character identity and audio overrides
# Stats live on CharacterBase as @export fields.
class_name CharacterData
extends Resource

@export var display_name: String = "Character"
@export var description: String = ""
@export var portrait: Texture2D

## Per-character sound effect overrides. Leave null to use global defaults.
@export var sfx: Resource # CharacterSFX
