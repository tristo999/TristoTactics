extends "res://scripts/ui/base_menu.gd"

var _ignore_callbacks := false

func _setup_menu():
	# Audio
	$Panel/VBox/BackButton.pressed.connect(_on_back_pressed)
	$Panel/VBox/VolumeSlider.value_changed.connect(_on_volume_slider_changed)
	
	# Display
	$Panel/VBox/FullscreenCheck.toggled.connect(_on_fullscreen_toggled)
	$Panel/VBox/VsyncCheck.toggled.connect(_on_vsync_toggled)
	
	# FPS options
	var fps_option = $Panel/VBox/FpsContainer/FpsOption
	fps_option.add_item("Unlimited", 0)
	fps_option.add_item("30", 30)
	fps_option.add_item("60", 60)
	fps_option.add_item("120", 120)
	fps_option.add_item("144", 144)
	fps_option.item_selected.connect(_on_fps_selected)

func _ready():
	super._ready()

# Called when the volume slider value changes
func _on_volume_slider_changed(value):
	if _ignore_callbacks:
		return
	MusicManager.set_music_volume(value)

func _on_fullscreen_toggled(enabled):
	if _ignore_callbacks:
		return
	MusicManager.set_fullscreen(enabled)

func _on_vsync_toggled(enabled):
	if _ignore_callbacks:
		return
	MusicManager.set_vsync(enabled)

func _on_fps_selected(index):
	if _ignore_callbacks:
		return
	var fps_option = $Panel/VBox/FpsContainer/FpsOption
	var fps = fps_option.get_item_id(index)
	MusicManager.set_fps_limit(fps)

func _on_back_pressed():
	request_back()

# Aliases for compatibility
func show_settings():
	show_menu()

# Override show_menu to sync all controls with saved settings
func show_menu():
	_ignore_callbacks = true
	
	# Sync volume slider
	var db = MusicManager.get_music_volume_db()
	var volume_value = int(clamp(inverse_lerp(-40, 0, db) * 100, 0, 100))
	$Panel/VBox/VolumeSlider.value = volume_value
	
	# Sync display settings
	$Panel/VBox/FullscreenCheck.button_pressed = MusicManager.get_fullscreen()
	$Panel/VBox/VsyncCheck.button_pressed = MusicManager.get_vsync()
	
	# Sync FPS option
	var fps_option = $Panel/VBox/FpsContainer/FpsOption
	var current_fps = MusicManager.get_fps_limit()
	for i in fps_option.item_count:
		if fps_option.get_item_id(i) == current_fps:
			fps_option.select(i)
			break
	
	_ignore_callbacks = false
	super.show_menu()

func hide_settings():
	hide_menu()
