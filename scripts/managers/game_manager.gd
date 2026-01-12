extends Node

var player_team_characters = []
var enemy_team_characters = []


@onready var action_camera: Camera2D = $"../ActionCamera"
@onready var timer: Timer = $TurnTimer
@onready var tilemap = get_node("/root/TestScene/Node2D")
# Reference to the TurnLabel UI
@onready var turn_label = get_node("../TurnLabelCanvas/TurnLabel")

var current_character
var turn_order
var turn_in_progress = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Debug: print children of the scene root to verify UI node
	print("TestScene children:", get_tree().current_scene.get_children())
	#Get All Players and Enemies into their own arrays
	var player_team = get_node("/root/TestScene/PlayerTeam")
	
	for child in player_team.get_children():
		player_team_characters.append(child)
		
	print("Player Characters:", player_team_characters)
	
	var enemy_team = get_node("/root/TestScene/EnemyTeam")
	
	for child in enemy_team.get_children():
		enemy_team_characters.append(child)
		
	print("Enemy Characters:", enemy_team_characters)
	#Create a turn order for players and enemies
	
	for player in player_team_characters:
		print(player.speed)
		
	turn_order = []
	turn_order.append_array(player_team_characters)
	turn_order.append_array(enemy_team_characters)
	
	#turn_order.sort((a,b) -> a.speed < b.speed)
	turn_order.sort_custom(func(a,b): return a.speed > b.speed)

	print("Turn Order:", turn_order)
	
	
	current_character = turn_order.front()
	action_camera.move_camera(current_character)
	# Set the turn label at game start
	if enemy_team_characters.has(current_character):
		turn_label.text = "Enemy Turn"
	else:
		turn_label.text = "Player Turn"
	# Use call_deferred to ensure all _ready() calls have finished before starting the turn
	current_character.call_deferred("start_turn", tilemap)
	timer.start()
	#Grab control of the camera
	#Begin Turns in Process
	var base_layer = tilemap.get_node("BaseGrid")
	for character in turn_order:
		if character.has_method("set_base_layer"):
			character.set_base_layer(base_layer)
			character.update_current_tile()


# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(delta: float) -> void:
	if not turn_in_progress and not enemy_team_characters.has(current_character):
		if Input.is_action_just_pressed("ui_accept"):
			_on_turn_timer_timeout()


func _on_turn_timer_timeout() -> void:
	current_character.end_turn(tilemap)
	turn_in_progress = false
	print("Next Turn!")
	current_character = get_next_character(current_character)
	print("Turn: ", current_character.name)
	# Update the turn label text
	if enemy_team_characters.has(current_character):
		turn_label.text = "Enemy Turn"
	else:
		turn_label.text = "Player Turn"
	action_camera.move_camera(current_character)
	if enemy_team_characters.has(current_character):
		timer.start()
	current_character.start_turn(tilemap)
	
	
func get_next_character(current_character: Node2D) -> Node2D:
	var index = turn_order.find(current_character) # Get the index of the current character
	if index != -1:
		var next_index = (index + 1) % turn_order.size() # Wrap around if the index goes out of bounds
		return turn_order[next_index] # Return the next character (wrapped around if necessary)
	else:
		return null # Return an empty string if the character is not found
