# Constants - Global game constants
extends Node

# Tile
const TILE_CENTER_OFFSET = Vector2(3, -2)
const INVALID_TILE = Vector2i(-9999, -9999)

# Teams
const TEAM_PLAYER = "player_team"
const TEAM_ENEMY = "enemy_team"
const TEAM_ALLY = "ally_team"   # AI-controlled "green" units; friendly to the player

# Groups
const GROUP_PLAYER_CHARACTERS = "player_characters"
const GROUP_ENEMY_CHARACTERS = "enemy_characters"
const GROUP_ALLY_CHARACTERS = "ally_characters"
const GROUP_ALL_CHARACTERS = "all_characters"

## Hostility model for 3 teams. Same team = friendly. The enemy team is hostile
## to everyone else; player and ally are friendly to each other.
func is_hostile(team_a: String, team_b: String) -> bool:
	if team_a == team_b:
		return false
	return team_a == TEAM_ENEMY or team_b == TEAM_ENEMY

# Directions
const CARDINAL_DIRECTIONS = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
