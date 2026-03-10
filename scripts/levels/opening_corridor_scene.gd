# OpeningCorridorScene - The opening sequence of Tristo Tactics.
# The player walks through a void toward an unseen light. The Guardian
# contacts them through fragmented transmissions. A path materializes
# under their feet and fades behind them as a distant beacon grows at
# the top of the screen. The sequence culminates in the game title, name
# entry, and a white flash into the next scene.
#
# == Visual Design ==
# Pure black background. Per-tile path materialization (CorridorPath) with
# per-tile sine-wave pulse. Camera sits ahead of the player (CorridorCamera).
# Darkness circle centered on the player grows as they walk. A soft green-white
# beacon at the top of the screen grows as the player advances.
# Phase 5 reveals a landscape image via a GPU wave shader (or tile sprites
# as fallback). The corridor is generated programmatically.
#
# == Phase Structure (position-triggered) ==
# Phase 1 — THE VOID:        Silence, then "Are you there?..." Player fades in.
# Phase 2 — THE CALL:        Movement unlocked. "...follow the path..."
# Phase 3 — THE ASSEMBLY:    Beacon appears. "...stay with me..."
# Phase 4 — THE CONNECTION:  "...this world needs you..."
# Phase 5 — THE THRESHOLD:   Forced walk, landscape reveal, title card.
# Phase 6 — THE NAME:        Name entry → "Welcome" → shake/flash → "No... It's
#                             too late..." → shake/flash/blackout → "Find me..."
#                             → white-out → scene change.
#
# == Full narrative dialogue ==
# Phase 1: "Are you there?..."
# Phase 2: "...follow the path..."
# Phase 3: "...stay with me..."
# Phase 4: "...this world needs you..."
# Phase 6: "{player_name}... Welcome..."   (Guardian, fast)
# Phase 6: "No... It's too late..."        (corrupted/unknown)
# Phase 6: "{player_name}... Find me..."   (Guardian, slow)
#
# See docs/opening_scene_report.md for the full writer-facing narrative breakdown.
#
# == Scene setup in editor ==
# Root: OpeningCorridorScene (this script)
# Children:
#   • Tilemap         — corridor TileMapLayer tree with tilemap.gd script
#   • WalkingPlayer   — scenes/characters/WalkingPlayer.tscn
#   • DialogueBox     — scenes/ui/DialogueBox.tscn
#   • CinematicTrigger × 5 — Phase2Trigger, Phase3Trigger, Phase4Trigger,
#                             Phase5Trigger, Phase6Trigger
#
# ScreenOverlay, NameEntryDisplay, CorridorPath,
# and TitleCard are added automatically by this script.
extends WalkingScene
class_name OpeningCorridorScene

## Seconds of total blackness before the hero can move (Phase 1 hold).
@export var void_hold_duration: float = 1.5
## Walk speed for the corridor (very slow, atmospheric).
@export var corridor_walk_speed: float = 2.5
## Animation speed scale for the corridor.
@export var corridor_anim_speed: float = 0.25
## Scene to load after the opening sequence completes.
@export_file("*.tscn") var next_scene_path: String = "res://scenes/levels/summoning_room_scene.tscn"
## Starting darkness light radius — small bubble around the player.
@export_range(0.0, 1.0) var start_light_radius: float = 0.07
## Starting darkness light softness.
@export_range(0.0, 0.5) var start_light_softness: float = 0.08
## How long the light bubble takes to appear.
@export var fade_in_duration: float = 3.5
## Maximum light radius (reached at end of corridor).
@export_range(0.0, 1.0) var max_light_radius: float = 0.45
## Maximum light softness (reached at end of corridor).
@export_range(0.0, 0.5) var max_light_softness: float = 0.20
## If true, Phase 5 bloom uses a single landscape image instead of tile sprites.
@export var use_landscape_image: bool = true
## Path to the landscape image used when use_landscape_image is true.
@export_file("*.png", "*.jpg", "*.jpeg") var landscape_image_path: String = "res://assets/a374993b-58e4-4b68-90a8-6d535be9f696.png"

## Corridor tile generation bounds.
const CORRIDOR_START_Y: int = 5
const CORRIDOR_END_Y: int = -160
const CORRIDOR_HALF_WIDTH: int = 2
## How far left/right the world fills visually — should cover full camera width.
const WORLD_HALF_WIDTH: int = 30
const TOP_LIGHT_CENTER := Vector2(0.5, 0.0)

var _player: WalkingPlayer = null
var _path: CorridorPath = null
var _title: TitleCard = null
var _overlay: ScreenOverlay = null
var _beacon_layer: CanvasLayer = null
var _beacon_glow: TextureRect = null
var _light_ready: bool = false
var _start_tile_y: int = 3
## Tracks the furthest-north row the player has reached (lowest Y value).
var _best_y: int = 999
## The last row we sealed off for backtracking.
var _last_sealed_y: int = 999
const BACKTRACK_LIMIT: int = 2
var _current_path_half_width: int = 0
var _pending_path_half_width: int = 0
var _top_light_active: bool = false
## When true, _update_guiding_light no longer controls darkness (handed off at Phase 3).
var _darkness_released: bool = false
## Heartbeat accumulator for the beacon glow pulse.
var _heartbeat_time: float = 0.0
## Step-pulse: set to 1.0 on each new tile, decays to 0 over ~0.4s.
var _step_pulse: float = 0.0
var _prev_player_y: int = 9999

func _ready() -> void:
	super._ready() # adds black backdrop

	# Stop any carry-over music
	AudioManager.stop_music()

	# --- Generate long corridor ---
	_generate_corridor()

	# --- Effect layers (added programmatically) ---
	_bloom_container = Node2D.new()
	_bloom_container.z_index = -1
	add_child(_bloom_container)

	_overlay = ScreenOverlay.new()
	add_child(_overlay)
	# Start fully dark — light circle reveals tiles around the player
	_overlay.set_darkness(1.0)
	_overlay.set_light_radius(0.0)
	_overlay.set_light_softness(0.0)
	_build_top_beacon()

	var name_entry := NameEntryDisplay.new()
	add_child(name_entry)

	_glitch_display = GlitchTextDisplay.new()
	add_child(_glitch_display)

	_path = CorridorPath.new()
	add_child(_path)
	_path.deactivate()
	_path.set_preview_enabled(false)
	_path.ahead_rows = 7
	_path.fade_in_duration = 0.6
	_path.fade_duration = 3.0

	_title = TitleCard.new()
	add_child(_title)

	_vision = _CorridorVision.new()
	add_child(_vision)

	# --- Player setup ---
	_player = get_tree().get_first_node_in_group("walking_player") as WalkingPlayer
	if _player:
		_player.walk_speed = corridor_walk_speed
		_player.first_step_boost = 1.0
		_player.sprite.speed_scale = corridor_anim_speed
		_player.lock_movement()
		_player.modulate.a = 0.0
	else:
		push_warning("[OpeningCorridorScene] WalkingPlayer not found")

	_overlay.set_darkness(1.0)
	_overlay.set_light_radius(0.03)
	_overlay.set_light_softness(0.02)
	_overlay.set_light_center(Vector2(0.5, 0.65))

	# Disable all CinematicTriggers, then run the whole sequence as one coroutine.
	call_deferred("_setup_triggers")
	call_deferred("_run_sequence")

# ---------------------------------------------------------------------------
# Corridor generation — procedural straight column of tiles.
# ---------------------------------------------------------------------------
func _generate_corridor() -> void:
	var tilemap_node := get_tree().get_first_node_in_group("tilemap")
	if not tilemap_node:
		push_warning("[OpeningCorridorScene] Tilemap not found — cannot generate corridor")
		return
	var bg := tilemap_node.get_node_or_null("BaseGrid") as TileMapLayer
	if not bg:
		push_warning("[OpeningCorridorScene] BaseGrid not found")
		return

	# Sample atlas info from an existing tile before clearing
	var source_id: int = 2
	var atlas_coords := Vector2i(14, 10)
	var existing := bg.get_used_cells()
	if existing.size() > 0:
		var sample := existing[0]
		source_id = bg.get_cell_source_id(sample)
		atlas_coords = bg.get_cell_atlas_coords(sample)

	# Clear and build a long narrow corridor
	bg.clear()
	for y in range(CORRIDOR_START_Y, CORRIDOR_END_Y - 1, -1):
		for x in range(-CORRIDOR_HALF_WIDTH, CORRIDOR_HALF_WIDTH + 1):
			bg.set_cell(Vector2i(x, y), source_id, atlas_coords)

	# Hide tiles visually — CorridorPath sprites are the visual ground
	bg.modulate.a = 0.0

	# Rebuild pathfinding with the new corridor extents
	if tilemap_node.has_method("setup_astar_grid"):
		tilemap_node.setup_astar_grid()
		tilemap_node.add_walkable_cells_from_tilemap()

	# Seal side columns so player starts on a single-tile path.
	# set_path_half_width() will unseal them as the path widens.
	var astar := tilemap_node.get("astar_grid") as AStarGrid2D
	if astar:
		for cell_y in range(CORRIDOR_END_Y - 1, CORRIDOR_START_Y + 1):
			for cell_x in range(-CORRIDOR_HALF_WIDTH, CORRIDOR_HALF_WIDTH + 1):
				if cell_x != 0:
					var cell := Vector2i(cell_x, cell_y)
					if astar.is_in_boundsv(cell):
						astar.set_point_solid(cell, true)

# ---------------------------------------------------------------------------
# Trigger setup — clear all CinematicTrigger event arrays and disable them.
# All phases are driven exclusively by _run_sequence().
# ---------------------------------------------------------------------------
func _setup_triggers() -> void:
	for trigger_name in ["Phase2Trigger", "Phase3Trigger", "Phase4Trigger", "Phase5Trigger", "Phase6Trigger"]:
		var t := get_node_or_null(trigger_name) as CinematicTrigger
		if t:
			t.events.clear()
			t.process_mode = Node.PROCESS_MODE_DISABLED
	print("[SEQUENCE] All CinematicTriggers disabled.")
	# Cache trigger Y values once — used every frame by _update_guiding_light().
	for tname in ["Phase3Trigger", "Phase4Trigger", "Phase5Trigger"]:
		_trigger_ys[tname] = _get_trigger_y(tname)

# ---------------------------------------------------------------------------
# State vars used across async gaps.
# ---------------------------------------------------------------------------
var _sequence_running: bool = false
const _CorridorVision = preload("res://scripts/levels/corridor_vision.gd")
var _vision: Node2D = null

func _exit_tree() -> void:
	_sequence_running = false

var _glitch_display: GlitchTextDisplay = null
var _world_bg: TileMapLayer = null
var _world_grass_tex: Texture2D = null
var _landscape_tex: Texture2D = null
var _landscape_layer: CanvasLayer = null
var _world_bloomed: bool = false
## Tile bloom driven from _process — avoids spawning thousands of tweens at once.
var _bloom_tiles: Array[Dictionary] = []
var _bloom_elapsed: float = 0.0
var _bloom_running: bool = false
const BLOOM_TILE_FADE: float = 0.45
var _grass_atlas_variants: Array[AtlasTexture] = []
## Container for bloom world tiles.
var _bloom_container: Node2D = null
## When true, bloom container tracks the player's movement so tiles appear static.
var _bloom_follow_player: bool = false
var _bloom_last_player_pos: Vector2 = Vector2.ZERO
## Cached tile-Y for each phase trigger — populated once after scene is ready.
var _trigger_ys: Dictionary = {}

# ---------------------------------------------------------------------------
# _process — per-frame visual tracking ONLY. No phase logic here.
# ---------------------------------------------------------------------------
func _process(_delta: float) -> void:
	if not _player:
		return

	# Shift bloom container to match player movement — keeps tiles static on screen.
	if _bloom_follow_player and _bloom_container:
		var delta_pos := _player.global_position - _bloom_last_player_pos
		_bloom_container.global_position += delta_pos
		_bloom_last_player_pos = _player.global_position

	var player_y := _player.current_tile.y

	# Keep darkness circle centred on the player
	if _overlay and not _overlay.is_darkness_hidden():
		_overlay.set_light_center(_get_player_screen_uv(_player))

	# Step pulse: fire on each new tile, decay over ~0.4s
	_step_pulse = maxf(0.0, _step_pulse - _delta * 2.5)
	if player_y != _prev_player_y:
		_prev_player_y = player_y
		_step_pulse = 1.0

	# Animate the guiding beacon based on player progress
	if _top_light_active:
		_heartbeat_time += _delta
		_update_guiding_light(_player.global_position.y)

	# Tile bloom alpha — process-driven to avoid per-tile tween allocation spike.
	if _bloom_running:
		_bloom_elapsed += _delta
		var all_done := true
		for item in _bloom_tiles:
			var spr: Sprite2D = item["spr"]
			if not is_instance_valid(spr):
				continue
			var a := clampf((_bloom_elapsed - float(item["at"])) / BLOOM_TILE_FADE, 0.0, 1.0)
			spr.modulate.a = a
			if a < 1.0:
				all_done = false
		if all_done:
			_bloom_running = false
			_bloom_tiles.clear()

	# Seal tiles more than BACKTRACK_LIMIT rows behind the player
	if player_y < _best_y:
		_best_y = player_y
		var seal_below: int = _best_y + BACKTRACK_LIMIT + 1
		if seal_below < _last_sealed_y:
			var tilemap_node := get_tree().get_first_node_in_group("tilemap")
			if tilemap_node:
				var astar := tilemap_node.get("astar_grid") as AStarGrid2D
				if astar:
					for row_y in range(seal_below, _last_sealed_y):
						for col_x in range(-CORRIDOR_HALF_WIDTH, CORRIDOR_HALF_WIDTH + 1):
							var cell := Vector2i(col_x, row_y)
							if astar.is_in_boundsv(cell):
								astar.set_point_solid(cell, true)
					_last_sealed_y = seal_below

# ---------------------------------------------------------------------------
# _await_player_y — suspend the sequence until player reaches target_y.
# ---------------------------------------------------------------------------
## Polls once per frame. Skips instantly if trigger Y is -9999 (node missing).
func _await_player_y(target_y: int) -> void:
	if target_y == -9999:
		push_warning("[SEQUENCE] _await_player_y: trigger not found — skipping wait.")
		return
	while is_instance_valid(_player) and _player.current_tile.y > target_y:
		await get_tree().process_frame
	if is_instance_valid(_player):
		print("[SEQUENCE] Player at Y=%d reached target Y=%d." % [_player.current_tile.y, target_y])

# ---------------------------------------------------------------------------
# _run_sequence — the entire opening sequence as one linear coroutine.
# Runs end-to-end. Debug prints mark every milestone.
# ---------------------------------------------------------------------------
func _run_sequence() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	var player := _player
	if not player:
		push_error("[SEQUENCE] WalkingPlayer not found — aborting.")
		return
	if not _glitch_display or not _overlay:
		push_error("[SEQUENCE] GlitchTextDisplay or ScreenOverlay missing — aborting.")
		return

	print("[SEQUENCE] ========== SEQUENCE START ==========")
	_sequence_running = true
	add_to_group("pause_blocked") # cinematic — no pausing until player has free control

	# -------------------------------------------------------------------
	# PHASE 1 — Void: silent blackness, then first Guardian transmission.
	# -------------------------------------------------------------------
	print("[SEQUENCE] Phase 1 — void hold (%.1fs)." % void_hold_duration)
	_overlay.set_light_center(_get_player_screen_uv(player))
	await get_tree().create_timer(void_hold_duration).timeout
	if not _sequence_running: return

	# Guardian searching in the void — two lines before the hero appears.
	_glitch_display.play_floating("...Hero...")
	await _glitch_display.floating_text_done
	if not _sequence_running: return
	await get_tree().create_timer(0.8).timeout
	if not _sequence_running: return
	_glitch_display.play_floating("...can you hear me?...")
	await _glitch_display.floating_text_done
	if not _sequence_running: return
	await get_tree().create_timer(0.6).timeout
	if not _sequence_running: return
	print("[SEQUENCE] Phase 1 — contact made. Fading player in.")

	# Player materialises — still locked, the summoning is taking hold.
	var summon_tween := create_tween()
	summon_tween.tween_property(player, "modulate:a", 1.0, 1.1)
	summon_tween.parallel().tween_method(_overlay.set_darkness, 1.0, 0.76, 1.1)
	summon_tween.parallel().tween_method(_overlay.set_light_radius, 0.03, 0.12, 1.1)
	summon_tween.parallel().tween_method(_overlay.set_light_softness, 0.02, 0.08, 1.1)
	await summon_tween.finished
	if not _sequence_running: return

	_glitch_display.play_floating("...the summoning is taking hold...")
	await _glitch_display.floating_text_done
	if not _sequence_running: return

	# TODO [VFX PLACEHOLDER]: fullscreen swirl shader fires here — vast, mostly
	# transparent, churning across the screen behind everything (~2s duration).
	# Replace with a proper animated noise shader before shipping.
	await get_tree().create_timer(2.0).timeout
	if not _sequence_running: return

	# Path materialises beneath the player's feet.
	_path.activate(false)
	_path.set_path_half_width(1)
	_path.pre_build_ahead(player.current_tile, _path.ahead_rows)
	await get_tree().create_timer(0.5).timeout
	if not _sequence_running: return

	# -------------------------------------------------------------------
	# PHASE 2 — The Call: invite the player to walk forward.
	# -------------------------------------------------------------------
	print("[SEQUENCE] Phase 2 — unlocking player.")
	remove_from_group("pause_blocked") # player has free control — allow pausing
	player.unlock_movement()
	_glitch_display.play_floating("...follow the path...")

	var shift_tween := create_tween()
	shift_tween.tween_method(_overlay.set_light_radius, 0.12, 0.18, 1.6)
	shift_tween.parallel().tween_method(_overlay.set_light_softness, 0.08, 0.12, 1.6)
	shift_tween.parallel().tween_method(_overlay.set_darkness, 0.76, 0.62, 1.6)
	await shift_tween.finished
	if not _sequence_running: return

	# -------------------------------------------------------------------
	# PHASE 3 — The Assembly: side lanes open; guiding beacon appears.
	# -------------------------------------------------------------------
	var p3_y := _get_trigger_y("Phase3Trigger")
	print("[SEQUENCE] Phase 3 — waiting for player to reach Y=%d." % p3_y)
	await _await_player_y(p3_y)
	if not _sequence_running: return
	print("[SEQUENCE] Phase 3 — triggered.")
	_reveal_guiding_light()
	_glitch_display.play_floating("...echoes of what awaits...")
	# TODO [PLACEHOLDER]: add a line specific to the companions when they appear.
	# TODO [PLACEHOLDER]: add an ominous line when the Act 2 character is glimpsed in the visions.
	# Darkness has served its purpose — the player is fully in the world now.
	_darkness_released = true
	var dark_out := create_tween()
	dark_out.tween_method(_overlay.set_darkness, 0.62, 0.0, 2.0)
	dark_out.tween_callback(_overlay.hide_darkness)
	# Companions appear to the left of the corridor — spawn at 1/4 from top of screen.
	if _vision:
		var spawn_pos := _world_pos_at_screen_uv(Vector2(0.0, 0.25))
		# Cluster center: rightmost figure (offset +96) must clear corridor edge (-32px).
		# -32 - 48 (half sprite) - 32 (2-tile gap) - 96 (offset) = -208
		spawn_pos.x = -208.0
		_vision.show_cluster(spawn_pos, CorridorVision.ClusterType.COMPANIONS)

	# -------------------------------------------------------------------
	# PHASE 4 — The Connection: corridor widens further.
	# -------------------------------------------------------------------
	var p4_y := _get_trigger_y("Phase4Trigger")
	print("[SEQUENCE] Phase 4 — waiting for player to reach Y=%d." % p4_y)
	await _await_player_y(p4_y)
	if not _sequence_running: return
	print("[SEQUENCE] Phase 4 — triggered.")
	_glitch_display.play_floating("...this world needs you...")
	# Kingdom flanks the corridor — architecture glimpsed either side as they walk through.
	if _vision:
		var t4 := get_node_or_null("Phase4Trigger")
		if t4:
			var side := 56.0
			_vision.show_cluster(t4.global_position + Vector2(-side, 0), CorridorVision.ClusterType.KINGDOM)
			_vision.show_cluster(t4.global_position + Vector2(side, 0), CorridorVision.ClusterType.KINGDOM)

	# -------------------------------------------------------------------
	# PHASE 5 — The Threshold: arrival text, world bloom, camera freeze, title.
	# -------------------------------------------------------------------
	var p5_y := _get_trigger_y("Phase5Trigger")
	print("[SEQUENCE] Phase 5 — waiting for player to reach Y=%d." % p5_y)
	await _await_player_y(p5_y)
	if not _sequence_running: return
	print("[SEQUENCE] Phase 5 — triggered. Forced walk north, bloom, title.")
	add_to_group("pause_blocked") # back in cinematic — block pause for the rest of the sequence

	player.start_forced_walk(Vector2i(0, -1))
	var cam := _player.get_node_or_null("Camera2D") as CorridorCamera
	if cam:
		cam.lock_to_idle()
	_bloom_phase5()

	# Wait for the landscape reveal to fully finish (3.5s) plus a short pause.
	await get_tree().create_timer(4.2).timeout
	if not _sequence_running: return

	print("[SEQUENCE] Phase 5 — showing title.")
	await _show_title_text("TRISTO TACTICS", 2.0, 4.0, 2.0)
	if not _sequence_running: return
	print("[SEQUENCE] Phase 5 — title done.")

	# -------------------------------------------------------------------
	# PHASE 6 — The Name: prompt, echo, interruption, flash, scene change.
	# -------------------------------------------------------------------
	print("[SEQUENCE] Phase 6 — settling effects.")
	_settle_corridor_effects()

	# Guardian asks for the hero's name — music has settled to quiet by now.
	print("[SEQUENCE] Phase 6 — showing name entry prompt.")
	var name_display := get_tree().get_first_node_in_group("name_entry_display") as NameEntryDisplay
	if name_display:
		await name_display.prompt("Hero... Tell me your name.")
	else:
		push_error("[SEQUENCE] Phase 6 — NameEntryDisplay not found in group 'name_entry_display'!")
	if not _sequence_running: return
	print("[SEQUENCE] Phase 6 — name confirmed: '%s'." % PlayerDataManager.get_player_name())

	var _dialogue_box := get_tree().get_first_node_in_group("dialogue_box")

	# --- Guardian echoes the name — connection complete. ---
	if _dialogue_box:
		var echo_line := DialogueLine.new()
		echo_line.text = "{player_name}..."
		echo_line.glitched = true
		echo_line.chars_per_second = 8.0
		echo_line.auto_advance_delay = 0.8
		var echo_seq: Array[DialogueLine] = [echo_line]
		await _dialogue_box.play_sequence(echo_seq)
	if not _sequence_running: return
	print("[SEQUENCE] Phase 6 — name echo done.")

	# --- Flash 1: player stops walking. ---
	_bloom_follow_player = false
	player.lock_movement()
	_shake_camera(8.0, 0.45)
	if _overlay:
		await _overlay.flash(Color.WHITE, 0.08, 0.12, 0.4)
	if not _sequence_running: return
	print("[SEQUENCE] Phase 6 — flash 1 done. Player stopped.")

	# --- "...something's wrong..." ---
	if _dialogue_box:
		var wrong_line := DialogueLine.new()
		wrong_line.text = "...something's wrong..."
		wrong_line.glitched = true
		wrong_line.chars_per_second = 10.0
		wrong_line.auto_advance_delay = 1.0
		var wrong_seq: Array[DialogueLine] = [wrong_line]
		await _dialogue_box.play_sequence(wrong_seq)
	if not _sequence_running: return

	# --- Flash 2: landscape tears apart. ---
	_shake_camera(10.0, 0.5)
	if _overlay:
		_overlay.set_flash_color(Color.WHITE)
		var flash2_in := create_tween()
		flash2_in.tween_method(_overlay.set_flash_alpha, 0.0, 1.0, 0.10)
		await flash2_in.finished
	if not _sequence_running: return
	if _landscape_layer:
		_landscape_layer.visible = false
	if _bloom_container:
		_bloom_container.visible = false
	if _overlay:
		var flash2_out := create_tween()
		flash2_out.tween_method(_overlay.set_flash_alpha, 1.0, 0.0, 0.40)
		await flash2_out.finished
	if not _sequence_running: return
	print("[SEQUENCE] Phase 6 — flash 2 done. Landscape gone.")

	# --- "...it's too late..." ---
	if _dialogue_box:
		var late_line := DialogueLine.new()
		late_line.text = "...it's too late..."
		late_line.glitched = true
		late_line.chars_per_second = 10.0
		late_line.auto_advance_delay = 1.0
		var late_seq: Array[DialogueLine] = [late_line]
		await _dialogue_box.play_sequence(late_seq)
	if not _sequence_running: return

	# --- Flash 3: contained in-and-out, path disappears during it. ---
	_shake_camera(12.0, 0.5)
	if _overlay:
		_overlay.set_flash_color(Color.WHITE)
		var flash3_in := create_tween()
		flash3_in.tween_method(_overlay.set_flash_alpha, 0.0, 1.0, 0.10)
		await flash3_in.finished
	if not _sequence_running: return
	# Path scatters/dissolves at the flash peak.
	_path.fade_all_tiles(0.8)
	if _overlay:
		_overlay.set_darkness(1.0)
		_overlay.set_light_radius(0.0)
	if _overlay:
		var flash3_out := create_tween()
		flash3_out.tween_method(_overlay.set_flash_alpha, 1.0, 0.0, 0.40)
		await flash3_out.finished
	if not _sequence_running: return
	print("[SEQUENCE] Phase 6 — flash 3 done. Path gone.")

	# Save checkpoint before final line.
	PlayerDataManager.set_checkpoint(next_scene_path)
	PlayerDataManager.save_player_data()

	# --- "{name}... Find me..." — white fade rises slowly, scene change. ---
	print("[SEQUENCE] Phase 6 — playing Find me.")
	var top_cl := CanvasLayer.new()
	top_cl.layer = 120
	add_child(top_cl)
	var top_white := ColorRect.new()
	top_white.color = Color(1, 1, 1, 0)
	top_white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_cl.add_child(top_white)
	# Size must be set after adding to tree so the viewport rect is available.
	top_white.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var fade_tween := create_tween()
	fade_tween.tween_property(top_white, "color:a", 1.0, 4.0)

	if _dialogue_box:
		var find_me_line := DialogueLine.new()
		find_me_line.text = "{player_name}... Find me..."
		find_me_line.glitched = true
		find_me_line.chars_per_second = 7.0
		find_me_line.auto_advance_delay = 0.5
		var find_me_seq: Array[DialogueLine] = [find_me_line]
		await _dialogue_box.play_sequence(find_me_seq)
	if not _sequence_running: return
	print("[SEQUENCE] Phase 6 — Find me done. Awaiting white-out.")

	# Wait for the white fade to finish (same 4s as the tween duration).
	# Using a timer here rather than await tween.finished to avoid tween deadlocks.
	await get_tree().create_timer(4.0).timeout
	if not _sequence_running: return
	print("[SEQUENCE] Changing scene to %s." % next_scene_path)
	get_tree().change_scene_to_file(next_scene_path)

## Fades "TRISTO TACTICS" in over the landscape, holds, then fades out.
## fade_in, hold, fade_out are all in seconds.
func _show_title_text(title: String, fade_in: float, hold: float, fade_out: float) -> void:
	var cl := CanvasLayer.new()
	cl.layer = 110
	add_child(cl)
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.modulate.a = 0.0
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.anchor_top = 0.33
	label.anchor_bottom = 0.33
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(label)
	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 1.0, fade_in)
	tw.tween_interval(hold)
	tw.tween_property(label, "modulate:a", 0.0, fade_out)
	await tw.finished
	cl.queue_free()

func _shake_camera(amplitude: float, duration: float) -> void:
	var cam := _player.get_node_or_null("Camera2D") as CorridorCamera
	if not cam:
		return
	var steps := int(duration / 0.05)
	var tween := create_tween()
	for i in range(steps):
		var t := float(i) / float(steps)
		var a := amplitude * (1.0 - t)
		tween.tween_property(cam, "offset", Vector2(randf_range(-a, a), randf_range(-a, a)), 0.05)
	tween.tween_property(cam, "offset", Vector2.ZERO, 0.05)

func _world_pos_at_screen_uv(uv: Vector2) -> Vector2:
	var viewport := get_viewport()
	if not viewport:
		return Vector2.ZERO
	var screen_pos := uv * viewport.get_visible_rect().size
	return viewport.get_canvas_transform().affine_inverse() * screen_pos

func _get_player_screen_uv(player: WalkingPlayer) -> Vector2:
	var viewport := get_viewport()
	if not viewport:
		return Vector2(0.5, 0.65)
	var canvas_xform := viewport.get_canvas_transform()
	var screen_pos: Vector2 = canvas_xform * player.global_position
	var vp_size := viewport.get_visible_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return Vector2(0.5, 0.65)
	return screen_pos / vp_size

func _update_guiding_light(player_world_y: float) -> void:
	if not _beacon_glow:
		return
	# Convert cached tile Y values to world Y (tile_size = 16) for float precision.
	var phase3_world_y: float = float(_trigger_ys.get("Phase3Trigger", -9999)) * 16.0
	var phase5_world_y: float = float(_trigger_ys.get("Phase5Trigger", -9999)) * 16.0
	var t := clampf(
		(phase3_world_y - player_world_y) / (phase3_world_y - phase5_world_y),
		0.0, 1.0)
	# Step pulse adds a brief radius burst on each tile stepped
	var pulse_bonus := _step_pulse * 0.028
	if _overlay and not _overlay.is_darkness_hidden():
		_overlay.set_light_radius(lerpf(0.18, 0.44, t) + pulse_bonus)
		_overlay.set_light_softness(lerpf(0.12, 0.22, t))
	if _overlay and not _darkness_released and not _overlay.is_darkness_hidden():
		_overlay.set_darkness(lerpf(0.62, 0.10, t))
	# Beacon heartbeat: two overlapping sine waves for an organic irregular rhythm
	var heartbeat := sin(_heartbeat_time * 1.1) * 0.018 + sin(_heartbeat_time * 2.9) * 0.009
	var beacon_alpha := clampf(lerpf(0.03, 0.98, t) + heartbeat, 0.0, 1.0)
	_beacon_glow.modulate = Color(0.72, 1.0, 0.80, beacon_alpha)
	var target_scale := lerpf(0.3, 4.5, t)
	_beacon_glow.scale = Vector2(target_scale, target_scale)

func _reveal_guiding_light() -> void:
	if _light_ready or not _beacon_glow:
		return
	_light_ready = true
	_top_light_active = true
	_beacon_glow.modulate.a = 0.0
	_beacon_glow.scale = Vector2(0.3, 0.3)

func _settle_corridor_effects() -> void:
	if _overlay and not _overlay.is_darkness_hidden():
		_overlay.set_darkness(0.18)
		_overlay.set_light_radius(0.9)
		_overlay.set_light_softness(0.28)
	if _beacon_glow:
		_beacon_glow.modulate.a = 0.12

func _hint_and_widen_path(new_half_width: int, delay: float) -> void:
	if new_half_width <= _current_path_half_width or new_half_width <= _pending_path_half_width:
		return
	_pending_path_half_width = new_half_width
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func() -> void:
		if _path:
			_path.set_path_half_width(new_half_width)
		_current_path_half_width = new_half_width
		_pending_path_half_width = 0
	)

func _inverse_lerp_i(from_value: int, to_value: int, current_value: int) -> float:
	if from_value == to_value:
		return 1.0
	return clampf(
		(float(from_value - current_value) / float(from_value - to_value)),
		0.0,
		1.0
	)

# ---------------------------------------------------------------------------
# World resources used by the Phase 5 bloom.
# ---------------------------------------------------------------------------

func _ensure_world_resources() -> bool:
	if not _world_bg:
		var tm := get_tree().get_first_node_in_group("tilemap")
		if tm:
			_world_bg = tm.get_node_or_null("BaseGrid") as TileMapLayer
	if not _world_grass_tex and _world_bg:
		_world_grass_tex = load("res://addons/sprout_lands_tilemap/assets/Tilesets/Grass.png") as Texture2D
		if _world_grass_tex and _grass_atlas_variants.is_empty():
			for i in 6:
				var a := AtlasTexture.new()
				a.atlas = _world_grass_tex
				a.region = Rect2(i * 16.0, 0.0, 16.0, 16.0)
				_grass_atlas_variants.append(a)
	if not _landscape_tex and use_landscape_image and landscape_image_path != "":
		_landscape_tex = load(landscape_image_path) as Texture2D
		if not _landscape_tex:
			push_error("[Scene] Failed to preload landscape image: " + landscape_image_path)
	return _world_bg != null and _world_grass_tex != null

# ---------------------------------------------------------------------------
# Phase 5 — World bloom: tile wave from the top light downward.
# ---------------------------------------------------------------------------

func _bloom_phase5() -> void:
	if _world_bloomed:
		return
	_world_bloomed = true
	_top_light_active = false

	# Start the bloom from the top-center beacon area so it cascades downward
	# into the corridor rather than rising from the player.
	var origin := Vector2i(0, CORRIDOR_END_Y - 4)

	if not _ensure_world_resources():
		return

	if _overlay and not _overlay.is_darkness_hidden():
		var light_tween := create_tween()
		light_tween.tween_method(_overlay.set_light_radius, 0.34, 1.15, 1.2)
		light_tween.parallel().tween_method(_overlay.set_light_softness, 0.18, 0.30, 1.2)
		light_tween.parallel().tween_method(_overlay.set_darkness, 0.22, 0.0, 1.2)
		light_tween.tween_callback(func() -> void:
			_overlay.hide_darkness()
		)
	if _beacon_glow:
		var beacon_tween := create_tween()
		beacon_tween.tween_property(_beacon_glow, "modulate:a", 1.0, 0.2)
		beacon_tween.parallel().tween_property(_beacon_glow, "scale", Vector2(5.0, 5.0), 0.5)
		beacon_tween.tween_property(_beacon_glow, "modulate:a", 0.0, 0.25)

	if use_landscape_image:
		_bloom_landscape_image(origin)
		return

	# Directional bloom: tiles descend from the top light as a wave front.
	# Driven from _process rather than per-tile tweens to avoid a mass allocation
	# spike and to allow longer fades / more jitter without performance cost.
	_bloom_elapsed = 0.0
	_bloom_running = true
	for row_y in range(CORRIDOR_END_Y, CORRIDOR_START_Y + 1):
		for col_x in range(-WORLD_HALF_WIDTH, WORLD_HALF_WIDTH + 1):
			var tile_pos := Vector2i(col_x, row_y)
			var vertical_travel: float = float(tile_pos.y - origin.y)
			var lateral_spread: float = abs(float(tile_pos.x - origin.x))
			# More jitter and a longer fade overlap = softer wave front.
			var reveal_at: float = vertical_travel * 0.038 + lateral_spread * 0.010 + randf() * 0.09
			var spr := _spawn_world_tile_instant(tile_pos)
			if spr:
				_bloom_tiles.append({"spr": spr, "at": reveal_at})

func _bloom_landscape_image(_origin: Vector2i) -> void:
	if not _landscape_tex:
		push_error("[BLOOM] Landscape texture not loaded.")
		return

	# CanvasLayer behind the world (layer -1) so the player and path tiles
	# render in front, but the image sits above the pure black clear color.
	var cl := CanvasLayer.new()
	_landscape_layer = cl
	cl.layer = -1
	add_child(cl)

	var rect := TextureRect.new()
	rect.texture = _landscape_tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.offset_left = 0.0
	rect.offset_top = 0.0
	rect.offset_right = 0.0
	rect.offset_bottom = 0.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# GPU reveal shader — sweeps top→bottom with center-outward spread,
	# matching the original tile bloom wave. Zero GDScript per-frame cost.
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float reveal : hint_range(0.0, 1.5) = 0.0;
uniform float edge_softness : hint_range(0.01, 0.3) = 0.10;
void fragment() {
	float x_delay = abs(UV.x - 0.5) * 0.30;
	float noise   = sin(UV.x * 13.7 + UV.y * 8.3) * 0.04;
	float threshold = reveal - x_delay + noise;
	float alpha = 1.0 - smoothstep(threshold - edge_softness, threshold, UV.y);
	COLOR = texture(TEXTURE, UV);
	COLOR.a *= clamp(alpha, 0.0, 1.0);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("reveal", 0.0)
	rect.material = mat
	cl.add_child(rect)

	# Sweep reveal from 0 → 1.45 over ~3.5s — matches the original tile wave duration
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		mat.set_shader_parameter("reveal", v)
	, 0.0, 1.45, 3.5)

func _build_top_beacon() -> void:
	_beacon_layer = CanvasLayer.new()
	_beacon_layer.layer = -2
	add_child(_beacon_layer)

	_beacon_glow = TextureRect.new()
	_beacon_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beacon_glow.anchor_left = TOP_LIGHT_CENTER.x
	_beacon_glow.anchor_right = TOP_LIGHT_CENTER.x
	_beacon_glow.anchor_top = TOP_LIGHT_CENTER.y
	_beacon_glow.anchor_bottom = TOP_LIGHT_CENTER.y
	_beacon_glow.offset_left = -220
	_beacon_glow.offset_right = 220
	_beacon_glow.offset_top = -92
	_beacon_glow.offset_bottom = 92
	_beacon_glow.pivot_offset = Vector2(220.0, 92.0)
	_beacon_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_beacon_glow.stretch_mode = TextureRect.STRETCH_SCALE
	_beacon_glow.texture = _create_beacon_texture()
	_beacon_glow.modulate = Color(0.72, 1.0, 0.80, 0.0)
	_beacon_glow.scale = Vector2.ONE
	_beacon_layer.add_child(_beacon_glow)

func _create_beacon_texture() -> ImageTexture:
	var img := Image.create(440, 184, false, Image.FORMAT_RGBA8)
	var glow_center := Vector2(220.0, 92.0)
	for x in range(440):
		for y in range(184):
			var dx := (float(x) - glow_center.x) / 168.0
			var dy := (float(y) - glow_center.y) / 78.0
			var alpha := clampf(1.0 - sqrt(dx * dx + dy * dy), 0.0, 1.0)
			alpha = pow(alpha, 2.4)
			img.set_pixel(x, y, Color(0.82, 1.0, 0.88, alpha))
	return ImageTexture.create_from_image(img)

func _spawn_world_tile(tile: Vector2i, delay: float) -> void:
	if not _world_bg or not _world_grass_tex:
		return
	var spr := Sprite2D.new()
	spr.texture = _grass_atlas_variants[randi() % _grass_atlas_variants.size()]
	spr.modulate.a = 0.0
	_bloom_container.add_child(spr)
	spr.global_position = _world_bg.to_global(_world_bg.map_to_local(tile))
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(spr, "modulate:a", 1.0, 0.25)

## Spawn a world tile at alpha 0 with no tween — alpha is driven by _process bloom loop.
func _spawn_world_tile_instant(tile: Vector2i) -> Sprite2D:
	if not _world_bg or not _world_grass_tex:
		return null
	var spr := Sprite2D.new()
	spr.texture = _grass_atlas_variants[randi() % _grass_atlas_variants.size()]
	spr.modulate.a = 0.0
	_bloom_container.add_child(spr)
	spr.global_position = _world_bg.to_global(_world_bg.map_to_local(tile))
	return spr

func _get_trigger_y(node_name: String) -> int:
	var trigger := get_node_or_null(node_name)
	if trigger:
		# Trigger positions are in world coords; convert to tile Y
		var base_layer = get_tree().get_first_node_in_group("tilemap")
		if base_layer:
			var bg := base_layer.get_node_or_null("BaseGrid") as TileMapLayer
			if bg:
				return bg.local_to_map(bg.to_local(trigger.global_position)).y
	return -9999
