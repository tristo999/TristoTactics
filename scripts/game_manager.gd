extends Node

var player_team_characters = []
var enemy_team_characters = []

@onready var action_camera: Camera2D = $"../ActionCamera"
@onready var timer: Timer = $TurnTimer

var current_character
var turn_order
var turn_in_progress = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
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

	timer.start()
	#Grab control of the camera
	#Begin Turns in Process
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(turn_in_progress):
		pass
	else:
		turn_in_progress = true


func _on_turn_timer_timeout() -> void:
	turn_in_progress = false
	timer.start()
	print("Next Turn!")
	current_character = get_next_character(current_character)
	action_camera.move_camera(current_character)
	
	
func get_next_character(current_character: Node2D) -> Node2D:
	var index = turn_order.find(current_character) # Get the index of the current character
	if index != -1:
		var next_index = (index + 1) % turn_order.size() # Wrap around if the index goes out of bounds
		return turn_order[next_index] # Return the next character (wrapped around if necessary)
	else:
		return null # Return an empty string if the character is not found
