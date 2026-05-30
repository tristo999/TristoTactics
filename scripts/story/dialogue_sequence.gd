# DialogueSequence - A named, reusable array of DialogueLine resources.
# Save as a .tres file in res://dialogue/ and load it from scene code or
# the editor to keep authored dialogue out of GDScript.
#
# Usage (code):
#   var seq := load("res://dialogue/beat1_vael_arrival.tres") as DialogueSequence
#   var ev := DialogueEvent.new()
#   ev.lines = seq.lines
#   await ev.execute(get_tree())
#
# Usage (CinematicTrigger in editor):
#   Create a DialogueEvent, set its lines array by dragging the .tres in
#   — or write a small loader CallbackEvent that does the load() above.
class_name DialogueSequence
extends Resource

## Human-readable label for editor/debugging purposes.
@export var sequence_id: String = ""

## The ordered list of dialogue lines in this sequence.
@export var lines: Array[DialogueLine] = []
