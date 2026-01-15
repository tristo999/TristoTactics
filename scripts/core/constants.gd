# Constants - Global game constants
extends Node

# Tile
const TILE_CENTER_OFFSET = Vector2(3, -2)
const TILE_SOURCE_ID = 2
const HIGHLIGHT_MOUSE_OVER = Vector2i(8, 4)
const HIGHLIGHT_REACHABLE = Vector2i(27, 3)
const HIGHLIGHT_ATTACK_RANGE = Vector2i(28, 3)

# Teams
const TEAM_PLAYER = "player_team"
const TEAM_ENEMY = "enemy_team"

# Groups
const GROUP_PLAYER_CHARACTERS = "player_characters"
const GROUP_ENEMY_CHARACTERS = "enemy_characters"
const GROUP_ALL_CHARACTERS = "all_characters"

# Directions
const CARDINAL_DIRECTIONS = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
