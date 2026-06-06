extends Node

# SteamManager — handles Steam initialization and core Steam API access.
# Uses App ID 480 (Valve's SpaceWar test app) until a real App ID is registered.

var is_steam_enabled: bool = false

func _ready() -> void:
	if not _try_init():
		push_warning("SteamManager: Steam is not running or not available. Steam features disabled.")

func _try_init() -> bool:
	if not ClassDB.class_exists("Steam"):
		push_warning("SteamManager: GodotSteam extension not loaded.")
		return false

	var init_result = Steam.steamInitEx(false)
	if init_result["status"] != Steam.STEAM_API_INIT_RESULT_OK:
		push_warning("SteamManager: Steam init failed — %s" % init_result["verbal"])
		return false

	is_steam_enabled = true
	print("SteamManager: Steam initialized. App ID: %d" % Steam.getAppID())
	return true

func _process(_delta: float) -> void:
	if is_steam_enabled:
		Steam.run_callbacks()

# --- Achievements ---
func unlock_achievement(api_name: String) -> void:
	if not is_steam_enabled:
		return
	Steam.setAchievement(api_name)
	Steam.storeStats()

func clear_achievement(api_name: String) -> void:
	if not is_steam_enabled:
		return
	Steam.clearAchievement(api_name)
	Steam.storeStats()

func has_achievement(api_name: String) -> bool:
	if not is_steam_enabled:
		return false
	return Steam.getAchievement(api_name)["achieved"]
