extends Node

## Music tracks registry - levels can reference these by key
var music_tracks := {
	"menu": "res://assets/audio/music/medieval-fantasy-music-462199.mp3",
	"battle": "res://assets/audio/music/fantasy-craft-loop-431346.mp3",
	"victory": "res://assets/audio/music/victory.mp3",
	"defeat": "res://assets/audio/music/defeat.mp3",
	# Add more tracks as needed: "level_1": "res://...", etc.
}

## Sound effects registry - actions can reference these by key
var sound_effects := {
	# UI
	"button_click": "res://assets/audio/sfx/button_click.wav",
	"select": "res://assets/audio/sfx/select.wav",
	# Movement
	"move": "res://assets/audio/sfx/move.wav",
	# Combat
	"attack": "res://assets/audio/sfx/attack.wav",
	"hit": "res://assets/audio/sfx/hit.wav",
	"crit": "res://assets/audio/sfx/crit.wav",
	"miss": "res://assets/audio/sfx/miss.wav",
	# Status
	"death": "res://assets/audio/sfx/death.wav",
	"heal": "res://assets/audio/sfx/heal.wav",
	# Turn flow
	"turn_start": "res://assets/audio/sfx/turn_start.wav",
	"enemy_turn": "res://assets/audio/sfx/enemy_turn.wav",
}

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _current_music_key: String = ""
var _music_volume_db: float = 0
var _sfx_volume_db: float = -14.0

# Display settings
var _fullscreen: bool = false
var _vsync: bool = true
var _fps_limit: int = 0  # 0 = unlimited

const SETTINGS_PATH := "user://settings.cfg"
const MAX_SFX_PLAYERS := 8  # Pool size for simultaneous sound effects

func _ready():
	# Create music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.autoplay = false
	add_child(_music_player)
	
	# Create SFX player pool
	for i in MAX_SFX_PLAYERS:
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.bus = "SFX"
		sfx_player.autoplay = false
		add_child(sfx_player)
		_sfx_players.append(sfx_player)
	
	# Load saved settings from config file
	_load_settings()
	_music_player.volume_db = _music_volume_db
	for player in _sfx_players:
		player.volume_db = _sfx_volume_db
	
	# Apply display settings
	_apply_display_settings()

func _load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	if err == OK:
		# Audio settings
		_music_volume_db = config.get_value("audio", "music_volume_db", 0.0)
		_sfx_volume_db = config.get_value("audio", "sfx_volume_db", 0.0)
		# Display settings
		_fullscreen = config.get_value("display", "fullscreen", false)
		_vsync = config.get_value("display", "vsync", true)
		_fps_limit = config.get_value("display", "fps_limit", 0)

func _save_settings():
	var config = ConfigFile.new()
	# Audio settings
	config.set_value("audio", "music_volume_db", _music_volume_db)
	config.set_value("audio", "sfx_volume_db", _sfx_volume_db)
	# Display settings
	config.set_value("display", "fullscreen", _fullscreen)
	config.set_value("display", "vsync", _vsync)
	config.set_value("display", "fps_limit", _fps_limit)
	config.save(SETTINGS_PATH)

func _apply_display_settings():
	# Fullscreen
	if _fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# VSync
	if _vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	# FPS Limit
	Engine.max_fps = _fps_limit

## Play music by key (e.g., "menu", "battle", "level_1")
func play_music(music_key: String):
	if _current_music_key == music_key and _music_player.playing:
		return  # Already playing this track
	
	if not music_tracks.has(music_key):
		push_error("MusicManager: Music key '%s' not found in registry" % music_key)
		return
	
	var music_path = music_tracks[music_key]
	var stream = load(music_path)
	if stream:
		_music_player.stop()
		_music_player.stream = stream
		_music_player.play()
		_current_music_key = music_key
	else:
		push_error("MusicManager: Failed to load music from '%s'" % music_path)

## Stop currently playing music
func stop_music():
	_music_player.stop()
	_current_music_key = ""

## Play a sound effect by key (e.g., "button_click", "attack")
func play_sfx(sfx_key: String):
	if not sound_effects.has(sfx_key):
		push_warning("MusicManager: SFX key '%s' not found in registry" % sfx_key)
		return
	
	var sfx_path = sound_effects[sfx_key]
	if not ResourceLoader.exists(sfx_path):
		return  # Silently skip missing SFX files
	var stream = load(sfx_path)
	if not stream:
		push_warning("MusicManager: Failed to load SFX from '%s'" % sfx_path)
		return
	
	# Find available player
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	
	# All players busy, use the first one (interrupts existing sound)
	_sfx_players[0].stream = stream
	_sfx_players[0].play()

## Play a sound effect directly from a file path (used for per-character overrides)
func play_sfx_from_path(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var stream = load(path)
	if not stream:
		return
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	_sfx_players[0].stream = stream
	_sfx_players[0].play()

## Set music volume (0-100 scale)
func set_music_volume(value: float):
	var db = lerp(-40.0, 0.0, value / 100.0)
	_music_volume_db = db
	_music_player.volume_db = db
	_save_settings()

## Set sound effects volume (0-100 scale)
func set_sfx_volume(value: float):
	var db = lerp(-40.0, 0.0, value / 100.0)
	_sfx_volume_db = db
	for player in _sfx_players:
		player.volume_db = db
	_save_settings()

## Get current music volume in dB
func get_music_volume_db() -> float:
	return _music_volume_db

## Get current SFX volume in dB
func get_sfx_volume_db() -> float:
	return _sfx_volume_db

## Get current music key being played
func get_current_music() -> String:
	return _current_music_key
## Set fullscreen mode
func set_fullscreen(enabled: bool):
	_fullscreen = enabled
	_apply_display_settings()
	_save_settings()

## Get fullscreen state
func get_fullscreen() -> bool:
	return _fullscreen

## Set VSync
func set_vsync(enabled: bool):
	_vsync = enabled
	_apply_display_settings()
	_save_settings()

## Get VSync state
func get_vsync() -> bool:
	return _vsync

## Set FPS limit (0 = unlimited, common values: 30, 60, 120, 144)
func set_fps_limit(fps: int):
	_fps_limit = fps
	_apply_display_settings()
	_save_settings()

## Get FPS limit
func get_fps_limit() -> int:
	return _fps_limit
