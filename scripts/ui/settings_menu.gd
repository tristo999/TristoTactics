extends Control

func _ready():
	$VBox/BackButton.connect("pressed", self._on_back_pressed)
	$VBox/VolumeSlider.connect("value_changed", self._on_volume_changed)

func _on_back_pressed():
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _on_volume_changed(value):
	AudioServer.set_bus_volume_db(0, linear_to_db(value / 100.0))

func linear_to_db(linear):
	if linear == 0:
		return -80
	return 20 * log(linear) / log(10)
