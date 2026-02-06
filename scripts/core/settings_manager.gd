# SettingsManager - Owns display settings and persists ALL user preferences
# Audio volume is forwarded to AudioManager; display changes apply immediately.
extends Node

const SETTINGS_PATH := "user://settings.cfg"

# --- Display ---
var _fullscreen: bool = false
var _vsync: bool = true
var _fps_limit: int = 0  # 0 = unlimited


func _ready() -> void:
	_load_settings()
	_apply_display_settings()

# =========================================================================
# PERSISTENCE
# =========================================================================

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return  # First launch — use defaults

	# Audio (apply through AudioManager)
	var music_db: float = config.get_value("audio", "music_volume_db", 0.0)
	var sfx_db: float = config.get_value("audio", "sfx_volume_db", -14.0)
	AudioManager.set_music_volume_db(music_db)
	AudioManager.set_sfx_volume_db(sfx_db)

	# Display
	_fullscreen = config.get_value("display", "fullscreen", false)
	_vsync = config.get_value("display", "vsync", true)
	_fps_limit = config.get_value("display", "fps_limit", 0)

func _save_settings() -> void:
	var config := ConfigFile.new()
	# Audio (read current values from AudioManager)
	config.set_value("audio", "music_volume_db", AudioManager.get_music_volume_db())
	config.set_value("audio", "sfx_volume_db", AudioManager.get_sfx_volume_db())
	# Display
	config.set_value("display", "fullscreen", _fullscreen)
	config.set_value("display", "vsync", _vsync)
	config.set_value("display", "fps_limit", _fps_limit)
	config.save(SETTINGS_PATH)

# =========================================================================
# AUDIO VOLUME (delegates to AudioManager, then persists)
# =========================================================================

## Set music volume on a 0-100 slider scale
func set_music_volume(value: float) -> void:
	# lerpf converts the 0-100 slider to -40..0 decibels (how audio volume works)
	var db: float = lerpf(-40.0, 0.0, value / 100.0)
	AudioManager.set_music_volume_db(db)
	_save_settings()

## Set SFX volume on a 0-100 slider scale
func set_sfx_volume(value: float) -> void:
	# lerpf converts the 0-100 slider to -40..0 decibels (how audio volume works)
	var db: float = lerpf(-40.0, 0.0, value / 100.0)
	AudioManager.set_sfx_volume_db(db)
	_save_settings()

## Get music volume in dB (for slider sync)
func get_music_volume_db() -> float:
	return AudioManager.get_music_volume_db()

## Get SFX volume in dB (for slider sync)
func get_sfx_volume_db() -> float:
	return AudioManager.get_sfx_volume_db()

# =========================================================================
# DISPLAY
# =========================================================================

func set_fullscreen(enabled: bool) -> void:
	_fullscreen = enabled
	_apply_display_settings()
	_save_settings()

func get_fullscreen() -> bool:
	return _fullscreen

func set_vsync(enabled: bool) -> void:
	_vsync = enabled
	_apply_display_settings()
	_save_settings()

func get_vsync() -> bool:
	return _vsync

func set_fps_limit(fps: int) -> void:
	_fps_limit = fps
	_apply_display_settings()
	_save_settings()

func get_fps_limit() -> int:
	return _fps_limit

func _apply_display_settings() -> void:
	if _fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	if _vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	Engine.max_fps = _fps_limit
