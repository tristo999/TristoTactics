extends Control

@onready var label: Label = $Panel/Label

func _ready() -> void:
	add_to_group("tutorial_prompt")
	hide()

func set_prompt_text(text: String) -> void:
	label.text = text
