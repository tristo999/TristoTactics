extends Node

var player_team_characters = []
var enemy_team_characters = []

@onready var action_camera: Camera2D = $"../ActionCamera"

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
	#Grab control of the camera
	#Begin Turns in Process
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
