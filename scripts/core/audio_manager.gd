# AudioManager - Handles all audio playback (music and SFX)
# Pure audio engine: no display settings, no persistence.
extends Node

## Music tracks registry — levels reference these by key
var music_tracks := {
	"menu": "res://assets/audio/music/medieval-fantasy-music-462199.mp3",
	"battle": "res://assets/audio/music/fantasy-craft-loop-431346.mp3",
	"victory": "res://assets/audio/music/victory.mp3",
	"defeat": "res://assets/audio/music/defeat.mp3",
}

## Sound effects registry — actions reference these by key
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

const MAX_SFX_PLAYERS := 8

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _current_music_key: String = ""
var _music_volume_db: float = 0.0
var _sfx_volume_db: float = -14.0


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.autoplay = false
	add_child(_music_player)

	# Pre-create a pool of players so multiple sounds can overlap (e.g. hit + crit)
	for i in MAX_SFX_PLAYERS:
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.bus = "SFX"
		sfx_player.autoplay = false
		add_child(sfx_player)
		_sfx_players.append(sfx_player)

# =========================================================================
# MUSIC
# =========================================================================

## Play music by key (e.g., "menu", "battle")
func play_music(music_key: String) -> void:
	if _current_music_key == music_key and _music_player.playing:
		return
	if not music_tracks.has(music_key):
		push_error("AudioManager: Music key '%s' not found" % music_key)
		return

	var stream = load(music_tracks[music_key])
	if stream:
		_music_player.stop()
		_music_player.stream = stream
		_music_player.play()
		_current_music_key = music_key
	else:
		push_error("AudioManager: Failed to load music '%s'" % music_tracks[music_key])

## Stop currently playing music
func stop_music() -> void:
	_music_player.stop()
	_current_music_key = ""

## Get current music key being played
func get_current_music() -> String:
	return _current_music_key

# =========================================================================
# SFX
# =========================================================================

## Play a sound effect by key (e.g., "attack", "hit")
func play_sfx(sfx_key: String) -> void:
	if not sound_effects.has(sfx_key):
		push_warning("AudioManager: SFX key '%s' not found" % sfx_key)
		return

	var sfx_path: String = sound_effects[sfx_key]
	if not ResourceLoader.exists(sfx_path):
		return  # Silently skip missing placeholder files

	var stream = load(sfx_path)
	if not stream:
		push_warning("AudioManager: Failed to load SFX '%s'" % sfx_path)
		return

	_play_stream(stream)

## Play a sound effect directly from a file path (per-character overrides)
func play_sfx_from_path(path: String) -> void:
	if not ResourceLoader.exists(path):
		return

	var stream = load(path)
	if stream:
		_play_stream(stream)

## Internal: route a stream through the SFX player pool
func _play_stream(stream: AudioStream) -> void:
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	# All busy — interrupt the first player
	_sfx_players[0].stream = stream
	_sfx_players[0].play()

# =========================================================================
# VOLUME
# =========================================================================

## Set music volume in dB (called by SettingsManager)
func set_music_volume_db(db: float) -> void:
	_music_volume_db = db
	_music_player.volume_db = db

## Set SFX volume in dB (called by SettingsManager)
func set_sfx_volume_db(db: float) -> void:
	_sfx_volume_db = db
	for player in _sfx_players:
		player.volume_db = db

## Get current music volume in dB
func get_music_volume_db() -> float:
	return _music_volume_db

## Get current SFX volume in dB
func get_sfx_volume_db() -> float:
	return _sfx_volume_db
