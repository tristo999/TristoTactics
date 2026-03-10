extends Control

@onready var settings_menu_scene := preload("res://scenes/ui/SettingsMenu.tscn")

var menu_stack: MenuStack
var _transition_rect: ColorRect

func _ready():
	$VBox/SettingsButton.pressed.connect(_on_settings_pressed)
	$VBox/QuitButton.pressed.connect(_on_quit_pressed)
	$VBox/NewGameButton.pressed.connect(_on_new_game_pressed)
	$VBox/ContinueButton.pressed.connect(_on_continue_game_pressed)
	# Dim Continue button if there is no save to load.
	$VBox/ContinueButton.disabled = not PlayerDataManager.has_save()
	
	# Create menu stack for sub-menus
	menu_stack = MenuStack.new()
	menu_stack.stack_emptied.connect(_on_stack_emptied)
	add_child(menu_stack)
	
	# Fade in from black when arriving from splash screen
	_transition_rect = ColorRect.new()
	_transition_rect.color = Color(0, 0, 0, 1)
	_transition_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_transition_rect)
	_transition_rect.move_to_front()

	modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(self , "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	fade_in.parallel().tween_property(_transition_rect, "color:a", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	# Start playing menu music
	AudioManager.play_music("menu")

func _on_stack_emptied():
	# Show main menu content when all sub-menus are closed
	$VBox.show()

func _on_settings_pressed():
	$VBox.hide()
	var settings_menu = settings_menu_scene.instantiate()
	menu_stack.push_menu(settings_menu)

func _on_quit_pressed():
	get_tree().quit()

func _on_new_game_pressed() -> void:
	PlayerDataManager.reset_player_data()
	AudioManager.play_sfx("select") # Placeholder dramatic sting until final asset exists.
	$VBox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in $VBox.get_children():
		if child is BaseButton:
			(child as BaseButton).disabled = true
	var fade_out := create_tween()
	fade_out.tween_property(_transition_rect, "color:a", 1.0, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	await fade_out.finished
	# Ensure no white frame flashes while the new scene loads.
	RenderingServer.set_default_clear_color(Color.BLACK)
	get_tree().change_scene_to_file("res://scenes/levels/opening_corridor_scene.tscn")

func _on_continue_game_pressed():
	if not PlayerDataManager.load_player_data():
		push_warning("[MainMenu] Failed to load save data — nothing to continue.")
		return
	var scene := PlayerDataManager.current_scene
	if scene.is_empty():
		# Save exists but no checkpoint reached yet — restart from the opening.
		scene = "res://scenes/levels/opening_corridor_scene.tscn"
	RenderingServer.set_default_clear_color(Color.BLACK)
	get_tree().change_scene_to_file(scene)
