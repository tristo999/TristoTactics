# GlitchTextEvent - Displays a line of cinematic text via GlitchTextDisplay.
# Use for Guardian transmissions, system messages, lore reveals.
# NOT the dialogue bar — raw centered screen text.
# Supports {player_name} substitution (resolved at execute time).
class_name GlitchTextEvent
extends StoryEvent

## Text to display. Use {player_name} to substitute the player's name.
@export_multiline var text: String = ""
## Optional speaker label shown above the text (e.g. "GUARDIAN"). Leave empty to hide.
@export var speaker: String = ""
## If true, characters flicker with noise before resolving to the real glyph.
@export var glitched: bool = true
## If true, the player must press ui_accept or click to advance.
@export var wait_for_input: bool = true

func execute(scene_tree: SceneTree) -> void:
	var display := scene_tree.get_first_node_in_group("glitch_text_display") as GlitchTextDisplay
	if not display:
		push_warning("GlitchTextEvent: no GlitchTextDisplay found in group 'glitch_text_display'")
		return
	await display.play_line(text, speaker, glitched, wait_for_input)
