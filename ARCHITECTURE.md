# TristoTactics — Technical Architecture Reference

> **Audience:** AI coding agents, contributors needing full codebase context.
> For the human-readable overview, see [README.md](README.md).

---

## Table of Contents

- [Project Setup](#project-setup)
- [Architecture Overview](#architecture-overview)
- [Autoload Singletons](#autoload-singletons)
- [Core Systems](#core-systems)
  - [EventBus](#eventbus)
  - [Constants](#constants)
  - [Terrain Registry](#terrain-registry)
  - [Audio Pipeline](#audio-pipeline)
  - [Settings Manager](#settings-manager)
  - [PlayerDataManager](#playerdatamanager)
- [Character System](#character-system)
  - [CharacterBase](#characterbase)
  - [Player Characters](#player-characters)
  - [Enemy Characters](#enemy-characters)
  - [Character Data & SFX Resources](#character-data--sfx-resources)
- [Battle System](#battle-system)
  - [GameManager](#gamemanager)
  - [BattleInputHandler](#battleinputhandler)
  - [Turn Flow](#turn-flow)
  - [Attack Flow](#attack-flow)
  - [Ability Framework](#ability-framework)
- [Tilemap & Pathfinding](#tilemap--pathfinding)
  - [Tilemap Manager](#tilemap-manager)
  - [AStarGrid2D Pathfinding](#astargrid2d-pathfinding)
  - [BFS Reachability](#bfs-reachability)
  - [HighlightRenderer](#highlightrenderer)
  - [Tile Layers](#tile-layers)
- [Walking Scene System](#walking-scene-system)
  - [WalkingScene](#walkingscene)
  - [WalkingPlayer](#walkingplayer)
  - [WalkingNPC](#walkingnpc)
  - [CinematicTrigger](#cinematictrigger)
  - [OpeningCorridorScene](#openingcorridorscene)
- [Screen Effects](#screen-effects)
  - [ScreenOverlay](#screenoverlay)
  - [Darkness Shader](#darkness-shader)
  - [Fog Shader](#fog-shader)
  - [Bleed Shader](#bleed-shader)
  - [CanvasLayer Ordering](#canvaslayer-ordering)
- [Story Events](#story-events)
  - [StoryEvent](#storyevent)
  - [DialogueEvent](#dialogueevent)
  - [DialogueBox](#dialoguebox)
  - [DialogueLine](#dialogueline)
  - [WaitEvent](#waitevent)
  - [FlashEvent](#flashevent)
  - [OverlayEvent](#overlayevent)
  - [FogEvent](#fogevent)
  - [GlitchTextEvent](#glitchtextevent)
  - [NameEntryEvent](#nameentryevent)
  - [SceneChangeEvent](#scenechangeevent)
- [UI Systems](#ui-systems)
  - [Attack Animation Overlay](#attack-animation-overlay)
  - [Character Info Panel](#character-info-panel)
  - [Tile Info Panel](#tile-info-panel)
  - [Health Bars](#health-bars)
  - [Speed Toggle Button](#speed-toggle-button)
  - [Victory/Defeat Screen](#victorydefeat-screen)
  - [GlitchTextDisplay](#glitchtextdisplay)
  - [NameEntryDisplay](#nameentrydisplay)
- [Menu System](#menu-system)
  - [MenuStack](#menustack)
  - [Main Menu](#main-menu)
  - [Pause Menu](#pause-menu)
  - [Settings Menu](#settings-menu)
- [Camera System](#camera-system)
- [Level System](#level-system)
- [Scene Flow](#scene-flow)
- [Developer Tools](#developer-tools)
- [File Structure](#file-structure)
- [Input Mapping](#input-mapping)
- [Signal Reference](#signal-reference)
- [How to Add Content](#how-to-add-content)

---

## Project Setup

| Setting | Value |
|---|---|
| Engine | Godot 4.6, Forward+ renderer |
| Language | GDScript |
| Main Scene | `res://scenes/menus/SplashScreen.tscn` |
| Texture Filter | Nearest (pixel art) |
| Window Stretch | Mode: `canvas_items`, Aspect: `expand` |
| Tile Size | 16×16 pixels |
| Character Sprites | 80×80 pixels, `AnimatedSprite2D` |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AUTOLOAD SINGLETONS                         │
│  EventBus · Constants · TerrainRegistry · AudioManager              │
│  SettingsManager · GameSFXManager · AttackAnimationOverlay          │
│  PlayerDataManager                                                  │
└─────────────────────────────────────────────────────────────────────┘
         │ signals                            │ direct calls
         ▼                                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌──────────────────────┐
│  GameManager    │  │ BattleInput     │  │  Tilemap Manager     │
│  (turn order,   │  │ Handler         │  │  (A*, BFS, highlights│
│   battle flow)  │  │ (mouse clicks)  │  │   tile layers)       │
└────────┬────────┘  └────────┬────────┘  └──────────┬───────────┘
         │                    │                       │
         ▼                    ▼                       ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  BATTLE CHARACTER HIERARCHY                          │
│  CharacterBase → PlayerCharacter → ArcherCharacter                  │
│  CharacterBase → EnemyCharacter  → GoblinCharacter                  │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    WALKING SCENE SYSTEM                              │
│  WalkingScene → OpeningCorridorScene                                │
│  WalkingPlayer (tile movement) + WalkingNPC (dialogue)              │
│  CinematicTrigger → StoryEvent chain (dialogue, fog, flash, etc.)   │
│  ScreenOverlay (darkness / fog / bleed / flash shaders)             │
└─────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────┐
│                           UI LAYER                                  │
│  CharacterInfoPanel · TileInfoPanel · HealthBar                     │
│  AttackAnimationOverlay · VictoryDefeatScreen · SpeedToggleButton   │
│  DialogueBox · GlitchTextDisplay · NameEntryDisplay                 │
└─────────────────────────────────────────────────────────────────────┘
```

**Key patterns:**
- **Signal Bus** — All cross-system communication flows through `EventBus`. Systems never reference each other directly when possible.
- **State-machine battle flow** — `GameManager` uses an explicit `BattleState` enum to control phases (`INACTIVE → PLAYER_IDLE → PLAYER_MOVING → PLAYER_ATTACKING → ENEMY_TURN`). Delegates to `BattleInputHandler` for player input and `EnemyCharacter` for AI.
- **Shared terrain registry** — `TerrainRegistry` autoload is the single source of truth for terrain data. Both the UI (`TileInfoPanel`) and gameplay systems (BFS move cost, combat defense bonus) read from it.
- **Resource-based data** — Character identity and stats (`CharacterData`) and SFX overrides (`CharacterSFX`) are `Resource` files. When `CharacterData.override_stats` is enabled, all stats are loaded from the resource; otherwise, script-level `_init()` / `@export` defaults are used.
- **Reusable menu stack** — `MenuStack` is a LIFO container used by both the main menu and in-game pause.

---

## Autoload Singletons

Registered in `project.godot`, available globally:

| Singleton | Script | Purpose |
|---|---|---|
| `EventBus` | `scripts/core/event_bus.gd` | Global signal bus — all cross-system events |
| `Constants` | `scripts/core/constants.gd` | Shared constants (team names, groups, tile offset) |
| `TerrainRegistry` | `scripts/core/terrain_registry.gd` | Terrain data: defense bonuses, move costs, tile classification |
| `AudioManager` | `scripts/core/audio_manager.gd` | Music + SFX playback engine (pool of 8 players) |
| `SettingsManager` | `scripts/core/settings_manager.gd` | Persists user preferences to `user://settings.cfg` |
| `GameSFXManager` | `scripts/core/game_sfx_manager.gd` | Bridges game events → SFX with per-character overrides |
| `AttackAnimationOverlay` | `scripts/ui/attack_animation_overlay.gd` | Blocking attack cutscene overlay (CanvasLayer 100) |
| `PlayerDataManager` | `scripts/managers/player_data_manager.gd` | Player name + party persistence (`user://player_data.json`) |

---

## Core Systems

### EventBus

**Script:** `scripts/core/event_bus.gd` | **Extends:** `Node`

Pure signal declaration node — no logic. Every signal passes through here so systems stay decoupled.

**Signals:**

| Signal | Parameters | Emitted By | Consumed By |
|---|---|---|---|
| `battle_started` | — | GameManager | — |
| `battle_ended` | `victory: bool` | GameManager | BaseLevel, GameSFXManager |
| `turn_started` | `character: CharacterBase` | GameManager | CharacterInfoPanel, GameSFXManager, Tilemap |
| `turn_ended` | `character: CharacterBase` | GameManager | — |
| `character_moved` | `character: Node2D, from_tile: Vector2i, to_tile: Vector2i` | CharacterBase | Tilemap (refresh occupied) |
| `character_movement_started` | `character: Node2D` | CharacterBase | GameSFXManager |
| `character_movement_finished` | `character: Node2D` | CharacterBase | GameManager, CharacterInfoPanel |
| `character_attacked` | `attacker: Node2D, target: Node2D, damage: int, is_crit: bool` | AttackAnimationOverlay | GameSFXManager, CharacterInfoPanel |
| `ability_used` | `caster: Node2D, target: Node2D, ability: Ability` | GameManager | — (unconsumed; wire SFX/UI here) |
| `character_damaged` | `character: Node2D, amount: int, source: Node2D` | CharacterBase | GameSFXManager |
| `character_healed` | `character: Node2D, amount: int, source: Node2D` | CharacterBase | GameSFXManager |
| `character_died` | `character: Node2D` | CharacterBase | GameManager, GameSFXManager |
| `tile_hovered` | `tile_pos: Vector2i` | Tilemap | TileInfoPanel |
| `update_turn_indicator` | `character: Node2D, is_enemy: bool` | GameManager | UI turn label |
| `story_event_triggered` | `event: StoryEvent` | Any script | GameManager |

### Constants

**Script:** `scripts/core/constants.gd` | **Extends:** `Node`

```gdscript
TILE_CENTER_OFFSET = Vector2(3, -2)    # Pixel offset to center sprites on tiles
TEAM_PLAYER = "player_team"
TEAM_ENEMY = "enemy_team"
GROUP_PLAYER_CHARACTERS = "player_characters"
GROUP_ENEMY_CHARACTERS = "enemy_characters"
GROUP_ALL_CHARACTERS = "all_characters"
CARDINAL_DIRECTIONS = [Vector2i(0,-1), Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0)]
```

### Terrain Registry

**Script:** `scripts/core/terrain_registry.gd` | **Extends:** `Node` (Autoload)

Single source of truth for terrain data. Both the UI (`TileInfoPanel`) and gameplay systems (BFS pathfinding, combat defense) read from this singleton.

**Terrain types:**

| Terrain | Defense Bonus | Move Cost | Color |
|---|---|---|---|
| Grass | 0 | 1 | `#4a8c3f` |
| Tall Grass | 0 | 1 | `#5a9c4f` |
| Flowers | 0 | 1 | `#e8a0d4` |
| Water | 3 | 99 (impassable) | `#3a7ecf` |
| Sand | 0 | 1 | `#e8d898` |
| Dirt Path | 0 | 1 | `#b89868` |
| Stone Path | 0 | 1 | `#a0a0a0` |
| Bridge | 0 | 1 | `#c8a870` |
| Fence | 2 | 99 (impassable) | `#8b6c42` |
| House | 3 | 99 (impassable) | `#7c614a` |
| Tree | 1 | 2 | `#2d6b30` |

**Public functions:**

| Function | Signature | Description |
|---|---|---|
| `get_terrain_at` | `(tile_pos: Vector2i, tilemap: TileMapLayer) → Dictionary` | Returns `{name, color, defense_bonus, move_cost}` for a tile |
| `get_defense_bonus` | `(tile_pos: Vector2i, tilemap: TileMapLayer) → int` | Shorthand for defense bonus at a tile |
| `get_move_cost` | `(tile_pos: Vector2i, tilemap: TileMapLayer) → int` | Shorthand for movement cost at a tile |

**Tile classification** uses atlas coordinates on the ground layer and checks sibling layers (trees, fences, houses, water) for multi-cell features via `_is_tile_covered_by_layer()`.

### Audio Pipeline

Three-layer audio architecture:

1. **AudioManager** (`scripts/core/audio_manager.gd`) — Low-level playback engine. Maintains a pool of 8 `AudioStreamPlayer` nodes for overlapping SFX. Registry maps string keys to file paths.

   **Public functions:**

   | Function | Description |
   |---|---|
   | `play_music(music_key: String)` | Play music by registry key; no-op if already playing that key |
   | `stop_music()` | Stop current music |
   | `get_current_music() → String` | Return current music key |
   | `play_sfx(sfx_key: String)` | Play SFX by registry key |
   | `play_sfx_from_path(path: String)` | Play SFX directly from file path (per-character overrides) |
   | `set_music_volume_db(db: float)` | Set music volume in dB |
   | `set_sfx_volume_db(db: float)` | Set SFX volume in dB |
   | `get_music_volume_db() → float` | Get current music volume |
   | `get_sfx_volume_db() → float` | Get current SFX volume |

   **Music tracks registered:** `menu`, `battle`, `victory`, `defeat`
   **SFX keys registered:** `button_click`, `select`, `move`, `attack`, `hit`, `crit`, `miss`, `death`, `heal`, `turn_start`, `enemy_turn`

2. **SettingsManager** (`scripts/core/settings_manager.gd`) — Owns volume persistence. Converts 0–100 slider values to dB, forwards to AudioManager, saves to `user://settings.cfg`.

   **Public functions:**

   | Function | Description |
   |---|---|
   | `set_music_volume(value: float)` | Convert 0–100 → dB, apply, save |
   | `set_sfx_volume(value: float)` | Convert 0–100 → dB, apply, save |
   | `get_music_volume_db() → float` | Current music volume in dB |
   | `get_sfx_volume_db() → float` | Current SFX volume in dB |
   | `set_fullscreen(enabled: bool)` | Toggle fullscreen, save |
   | `get_fullscreen() → bool` | Current fullscreen state |
   | `set_vsync(enabled: bool)` | Toggle VSync, save |
   | `get_vsync() → bool` | Current VSync state |
   | `set_fps_limit(fps: int)` | Set FPS cap (0=unlimited), save |
   | `get_fps_limit() → int` | Current FPS limit |

   **Persists to:** `user://settings.cfg` via `ConfigFile`

3. **GameSFXManager** (`scripts/core/game_sfx_manager.gd`) — Event-to-sound bridge. Listens to EventBus signals and triggers appropriate SFX. Checks per-character `CharacterSFX` overrides before falling back to global defaults.

   **Signals connected to (from EventBus):**
   - `character_attacked` → attack/crit/miss SFX
   - `character_damaged` → hit SFX
   - `character_died` → death SFX
   - `character_healed` → heal SFX
   - `character_movement_started` → move SFX
   - `turn_started` → turn_start / enemy_turn SFX (team-based)
   - `battle_ended` → (future use)

### Settings Manager

Persists to `user://settings.cfg` using Godot's `ConfigFile`:
- Music volume (0–100)
- SFX volume (0–100)
- Fullscreen (bool)
- VSync (bool)
- FPS limit (0 = unlimited, 30, 60, 120, 144)

Settings auto-load on startup and apply immediately.

### PlayerDataManager

**Script:** `scripts/managers/player_data_manager.gd` | **Extends:** `Node` (Autoload)

Holds player identity and party data for the current session. Persists to `user://player_data.json`.

**Runtime state:** `player_name: String = "HERO"`, `party: Array = []`

**Public functions:**

| Function | Signature | Description |
|---|---|---|
| `set_player_name` | `(name: String) → void` | Set the player's name (in-memory) |
| `get_player_name` | `() → String` | Get the current player name |
| `set_party` | `(new_party: Array) → void` | Set the party array |
| `get_party` | `() → Array` | Get the current party |
| `save_player_data` | `() → bool` | Serialize name + party to JSON on disk; returns false on failure |
| `load_player_data` | `() → bool` | Load name + party from JSON on disk; returns false on failure |
| `reset_player_data` | `() → void` | Reset to defaults and delete save file |

**Persistence:** `ConfigFile`-style JSON at `user://player_data.json`. The main menu calls `save_player_data()` / `load_player_data()` during Start / Continue flows. In-scene name entry (via `NameEntryDisplay`) sets the name in-memory only — the game saves to disk at the appropriate narrative checkpoint.

---

## Character System

### CharacterBase

**Script:** `scripts/characters/base/character_base.gd`
**Extends:** `Node2D` | **class_name:** `CharacterBase`

The root class for all characters. Handles stats, movement, combat, health bars, and death.

**Signals defined:**
- `movement_finished` — emitted when tile-to-tile movement completes
- `died` — emitted on death

**Exported stats (editable per-instance in Inspector):**

| Stat | Type | Default | Description |
|---|---|---|---|
| `character_data` | CharacterData | null | Optional identity/SFX resource |
| `max_hp` | int | 25 | Maximum hit points |
| `attack_power` | int | 10 | Base attack damage |
| `defense` | int | 5 | Damage reduction |
| `initiative` | int | 10 | Turn order priority (higher = first) |
| `crit_chance` | float | 0.05 | Critical hit probability (0.0–1.0) |
| `move_speed` | float | 100.0 | Pixels/second movement speed |
| `move_range` | int | 5 | Max tiles per turn |
| `attack_range_min` | int | 1 | Minimum attack distance (Manhattan) |
| `attack_range_max` | int | 1 | Maximum attack distance (Manhattan) |

**Runtime state:** `current_hp: int`, `current_tile: Vector2i`, `base_layer: TileMapLayer`, `movement_left: int`, `has_attacked: bool`, `move_path: Array`, `move_target: Vector2`, `moving: bool`, `is_alive: bool` (getter), `team: String`, `health_bar: HealthBar`

**Public functions:**

| Function | Signature | Description |
|---|---|---|
| `set_base_layer` | `(layer: TileMapLayer) → void` | Set tilemap reference |
| `move_to_tile` | `(grid_pos: Vector2i) → void` | A*-based tile movement with per-frame interpolation |
| `attack_target` | `(target: CharacterBase) → Dictionary` | Async. Calculates damage (crit + terrain defense), plays blocking cutscene overlay, applies damage. Returns `{success: bool, damage: int, is_crit: bool}` or `{success: false, reason: String}` |
| `can_attack_target` | `(target: CharacterBase) → bool` | Range + team + alive checks |
| `get_targets_in_range` | `() → Array` | All valid enemy targets currently in range |
| `take_damage` | `(amount: int, source: Node2D) → void` | Apply damage, update health bar, emit signals, trigger death at 0 HP |
| `heal` | `(amount: int, _source: Node2D) → void` | Heal (clamped to max_hp) and emit signal |
| `get_sfx` | `(action: String) → String` | Per-character SFX override lookup via `character_data.sfx`; `""` = global default |
| `on_turn_started` | `() → void` | Virtual — override in subclasses |
| `on_turn_ended` | `() → void` | Virtual — override in subclasses |
| `_apply_character_data` | `() → void` | Called in `_ready()`. When `character_data.override_stats` is true, loads all stats from the resource |

**Signals emitted (via EventBus):** `character_movement_started`, `character_movement_finished`, `character_moved`, `character_damaged`, `character_died`, `character_healed`

**Death behavior:** Removes from all groups immediately (`GROUP_ALL_CHARACTERS`, `GROUP_PLAYER_CHARACTERS`, `GROUP_ENEMY_CHARACTERS`), plays fade-out tween (0.5s), then `queue_free()`.

**Movement system:** `_process(delta)` interpolates position along `move_path` at `move_speed` pixels/sec. Path comes from tilemap's A* grid.

### Player Characters

| Class | Script | Inherits | Stat Overrides |
|---|---|---|---|
| `PlayerCharacter` | `scripts/characters/base/player_character.gd` | `CharacterBase` | Sets `team = Constants.TEAM_PLAYER` in `_ready()`. No stat changes. |
| `ArcherCharacter` | `scripts/characters/base/archer_character.gd` | `PlayerCharacter` | Stats set in `_init()`: `max_hp=18, attack_power=8, defense=3, initiative=12, crit_chance=0.08, move_speed=90, move_range=3, attack_range_min=1, attack_range_max=4` |

### Enemy Characters

| Class | Script | Inherits | Stat Overrides |
|---|---|---|---|
| `EnemyCharacter` | `scripts/characters/enemies/enemy_character.gd` | `CharacterBase` | Sets `team = Constants.TEAM_ENEMY`. Has full AI system. |
| `GoblinCharacter` | `scripts/characters/enemies/goblin_character.gd` | `EnemyCharacter` | Stats set in `_init()`: `max_hp=15, attack_power=7, defense=3, initiative=15, crit_chance=0.10, move_speed=130, move_range=6, attack_range_min=1, attack_range_max=1, ai_pause_duration=0.8` |

**EnemyCharacter signals defined:** `ai_turn_completed`

**EnemyCharacter @export:** `ai_pause_duration: float = 2.0`

**EnemyCharacter public functions:**

| Function | Signature | Description |
|---|---|---|
| `execute_ai_turn` | `() → void` | Full AI coroutine: wait → find target → move → attack → signal completion |

**AI algorithm (`execute_ai_turn`):**
1. Wait `ai_pause_duration` seconds (visual pacing)
2. `_find_nearest_player()` — nearest alive player by Manhattan distance
3. `_get_best_tile_toward(target)` — stay if already in attack range, else follow A* path to attack range, else `_get_closest_reachable_tile_toward()` (BFS fallback)
4. Move to target tile (if different from current)
5. Attack if target is in range after movement
6. Emit `ai_turn_completed`

### Character Data & SFX Resources

**CharacterData** (`scripts/characters/base/character_data.gd`)
- **Extends:** `Resource` | **class_name:** `CharacterData`
- **Identity @exports:** `display_name: String`, `description: String`, `portrait: Texture2D`, `sfx: CharacterSFX`
- **`override_stats: bool = false`** — when true, `CharacterBase._apply_character_data()` loads all stats from this resource instead of using script defaults
- **Stat @exports (used when `override_stats` is true):** `max_hp`, `attack_power`, `defense`, `initiative`, `crit_chance`, `move_speed`, `move_range`, `attack_range_min`, `attack_range_max`, `ai_pause_duration`

**CharacterSFX** (`scripts/characters/base/character_sfx.gd`)
- **Extends:** `Resource` | **class_name:** `CharacterSFX`
- **@export fields (all `@export_file("*.wav","*.ogg","*.mp3")`):** `move`, `attack`, `hit`, `crit`, `miss`, `death`, `heal`, `turn_start` (all `String = ""`)
- **Public function:** `get_sfx(action: String) → String` — returns override path or `""` for global default

---

## Battle System

### GameManager

**Script:** `scripts/managers/battle/game_manager.gd` | **Extends:** `Node`

Orchestrates the entire battle: turn order, turn execution, win/loss detection, and highlight management. Added to group `"game_manager"` for global lookup.

**State machine (`enum BattleState`):**

| State | Description |
|---|---|
| `INACTIVE` | No battle running |
| `PLAYER_IDLE` | Player's turn — menu active, awaiting input |
| `PLAYER_MOVING` | Character is animating along a path |
| `PLAYER_ACTING` | Attack / ability animation is playing |
| `PLAYER_WAITING` | Story event / tutorial lock — all input blocked |
| `ENEMY_TURN_START` | Camera focused, brief pause before action |
| `ENEMY_SELECTING_MOVE` | Movement range shown — AI "thinking" |
| `ENEMY_MOVING` | Enemy character animating along a path |
| `ENEMY_SELECTING_ATTACK` | Attack range shown — AI picking target |
| `ENEMY_ATTACKING` | Enemy attack animation playing |

**@export variables:**
- `tilemap_node: Node2D`
- `action_camera: Camera2D`
- `intro_event: StoryEvent` — optional event played before the first turn (dialogue, cutscene, etc.)

**Runtime state:**
- `state: BattleState = BattleState.INACTIVE`
- `turn_order: Array[CharacterBase]`
- `current_character: CharacterBase`

**Public functions:**

| Function | Signature | Description |
|---|---|---|
| `request_move` | `(character: CharacterBase, target_tile: Vector2i) → bool` | Validates tile reachability, transitions `PLAYER_IDLE → PLAYER_MOVING` |
| `request_attack` | `(character: CharacterBase, target: CharacterBase) → bool` | Validates target is enemy and alive, transitions `PLAYER_IDLE → PLAYER_ACTING`; blocking `await` |
| `request_ability` | `(character: CharacterBase, ability: Ability, target: CharacterBase) → bool` | Validates ability usability, transitions `PLAYER_IDLE → PLAYER_ACTING` |
| `play_event` | `(event: StoryEvent) → void` | Awaitable — pauses gameplay (`PLAYER_WAITING`), runs event, restores state |
| `is_enemy_turn` | `() → bool` | Checks enemy-related states |

**State transitions:**
```
INACTIVE → PLAYER_WAITING (intro_event, if set)
PLAYER_WAITING → restored state (event finishes)
INACTIVE/PLAYER_WAITING → PLAYER_IDLE (first turn / return to idle)
PLAYER_IDLE → PLAYER_MOVING (request_move)
PLAYER_IDLE → PLAYER_ACTING (request_attack / request_ability)
PLAYER_MOVING → PLAYER_IDLE (character_movement_finished) or auto-end turn
PLAYER_ACTING → PLAYER_IDLE (attack/ability complete) or auto-end turn
Any state → PLAYER_WAITING (play_event) → restored state
PLAYER_IDLE → ENEMY_TURN_START (advance to enemy)
ENEMY_TURN_START → ENEMY_SELECTING_MOVE → ENEMY_MOVING → ENEMY_SELECTING_ATTACK → ENEMY_ATTACKING
ENEMY_ATTACKING → PLAYER_IDLE (advance to player)
```

**Signals connected to:**
- `EventBus.character_died` → `_on_character_died`
- `EventBus.character_movement_finished` → `_on_character_movement_finished`
- `EventBus.story_event_triggered` → `_on_story_event_triggered` (plays event via `play_event()`)

**Signals emitted:**
- `EventBus.battle_started`, `EventBus.turn_started`, `EventBus.turn_ended`, `EventBus.battle_ended`, `EventBus.update_turn_indicator`

**Initiative sort:** Descending by `initiative`; tie-break: players first, then alphabetical by `name`.

**Key implementation detail:** `_initialize_battle()` is `call_deferred` and also `await get_tree().process_frame` to ensure all sibling nodes have completed `_ready()` and joined their groups. Dead character turn-end: `_on_character_died` now calls `_end_character_turn()` for the dying character before advancing.

### BattleInputHandler

**Script:** `scripts/managers/battle/battle_input_handler.gd` | **Extends:** `Node`

Processes left mouse clicks and keyboard input during player turns:
1. **Guard:** Ignores all input unless `game_manager.state == BattleState.PLAYER_IDLE`
2. **Attack priority:** If clicking an enemy character in attack range → `game_manager.request_attack()`
3. **Ability targeting:** If in ABILITY mode and clicking a valid target → `game_manager.request_ability()`
4. **Movement:** If clicking a tile in `tilemap.cached_reachable_tiles` → `game_manager.request_move()`
5. **End turn:** Space/Enter with double-tap confirmation (1.5s window)

Uses group lookup (`get_first_node_in_group("game_manager")`) with `find_child` fallback to cache `game_manager` and `tilemap` references.

### Turn Flow

```
_initialize_battle()
  ├─ Wait one frame (all nodes ready)
  ├─ _find_node_references() — tilemap, camera, turn_label
  ├─ _build_turn_order() — all characters sorted by initiative
  │   └─ Tie-breaker: players go first, then alphabetical
  ├─ _setup_characters() — snap to grid, set base_layer
  └─ _start_battle()
       └─ Loop: _start_character_turn(character)
            ├─ Reset movement_left = move_range, has_attacked = false
            ├─ _show_movement_range() — highlights via tilemap
            ├─ character.on_turn_started()
            ├─ EventBus.turn_started.emit(character)
            ├─ If enemy: _execute_enemy_turn(enemy)
            │   ├─ enemy.ai_turn_completed.connect(one_shot)
            │   └─ enemy.execute_ai_turn()
            └─ If player: wait for _process() to detect ui_accept
                 └─ _advance_turn() → _end_character_turn() → _start_character_turn(next)
```

**Turn ending:** Player can manually end turn via `ui_accept` (Space/Enter). Turns also auto-end when both movement and action are spent.

**Win/loss:** `_on_character_died` removes from `turn_order`, checks if all enemies or all players are gone → `_end_battle(victory)`.

### Attack Flow

```
character.attack_target(target) [async]
  ├─ Guard: has_attacked → {success: false, reason: "already_attacked"}
  ├─ Guard: distance check → {success: false, reason: "out_of_range"}
  ├─ is_crit = randf() < crit_chance
  ├─ terrain_def = TerrainRegistry.get_defense_bonus(target.current_tile, tilemap)
  ├─ base_damage = max(1, attack_power - (target.defense + terrain_def))
  ├─ final_damage = base_damage * 2 if is_crit else base_damage
  ├─ has_attacked = true
  ├─ await AttackAnimationOverlay.play_attack_animation(self, target, final_damage, is_crit)
  │   ├─ Clone attacker + defender AnimatedSprite2D
  │   ├─ _root.modulate.a = 0 → fade in (0.15s)
  │   ├─ Hold 0.15s
  │   ├─ Lunge attacker toward defender (0.12s, TRANS_BACK)
  │   ├─ EventBus.character_attacked.emit() — triggers SFX
  │   ├─ Show damage label + _shake_node defender (0.3s, 6px intensity)
  │   ├─ Lunge attacker back (0.1s, TRANS_QUAD)
  │   ├─ Hold 0.3s
  │   ├─ Float damage label up + fade (0.3s)
  │   ├─ Fade out overlay (0.15s)
  │   └─ _cleanup() — free clones, hide overlay
  ├─ target.take_damage(final_damage, self)
  └─ Return {success: true, damage: final_damage, is_crit: is_crit}
```

### Ability Framework

Abilities are `Resource` subclasses assigned per-character. Each concrete ability (heal, fireball, buff, etc.) subclasses `Ability` and overrides `execute()`. Instances are duplicated at battle start so use counters are per-character.

**Ability** (`scripts/abilities/ability.gd`) | **class_name:** `Ability` | **Extends:** `Resource`

**Enum:** `TargetType { ALLY, ENEMY, SELF, TILE, ALL_ALLIES, ALL_ENEMIES }`

**@export fields:**

| Field | Type | Default | Description |
|---|---|---|---|
| `ability_name` | String | "Ability" | Display name |
| `description` | String | "" | Tooltip text |
| `icon` | Texture2D | null | Icon for the action bar button |
| `target_type` | TargetType | ENEMY | Targeting behavior |
| `range_min` | int | 1 | Minimum Manhattan distance |
| `range_max` | int | 1 | Maximum Manhattan distance |
| `max_uses` | int | 0 | Per-battle use limit (0 = unlimited) |

**Runtime state:** `uses_left: int`

**Public functions:**

| Function | Signature | Description |
|---|---|---|
| `reset_uses` | `() → void` | Restore `uses_left = max_uses`; called at battle start |
| `can_use` | `() → bool` | `true` if unlimited or `uses_left > 0` |
| `consume_use` | `() → void` | Decrement `uses_left` (only if `max_uses > 0`) |
| `get_target_tiles` | `(origin: Vector2i, tilemap: Node2D) → Array` | Returns all tiles within `[range_min, range_max]` Manhattan distance that are inside the A* grid bounds |
| `execute` | `(caster, target) → Dictionary` | **Virtual.** Override in subclass. Returns result dict (shape is ability-specific, but `{success: bool}` is required). |

**HealAbility** (`scripts/abilities/heal_ability.gd`) — concrete example, `target_type = ALLY`, `range_max = 3`, heals `heal_amount` HP clamped to `max_hp`. Returns `{success: bool, healed: int, target: String}` on success or `{success: false, reason: String}` on failure (`"no_uses_left"`, `"invalid_target"`).

**Character integration** (in `CharacterBase`):
- `abilities: Array[Ability]` — populated from `character_data.abilities` at `_ready()` via `.duplicate()` (per-instance state)
- `get_usable_abilities() → Array[Ability]` — filters by `can_use()`
- `has_abilities() → bool`
- `get_ability_targets(ability: Ability) → Array` — valid targets in range for the BattleInputHandler to click-validate

**GameManager integration:**
- `selected_ability: Ability` — active ability during `PLAYER_SELECTING_ABILITY` targeting mode
- `enter_ability_selection(ability: Ability)` — fired by the `BottomActionBar` ability button; shows ability range highlights via `_show_ability_range()`
- `request_ability(character, ability, target) → bool` — validates `has_used_action` and `ability.can_use()`, awaits `ability.execute()`, emits `EventBus.ability_used`, transitions to `PLAYER_IDLE`

**Input flow** (in `BattleInputHandler`):
1. User presses ability button in `BottomActionBar` → `game_manager.enter_ability_selection(ability)`
2. Range highlights shown; clicking a tile invokes `_handle_selecting_ability()`
3. Target validated against `character.get_ability_targets(ability)` → `game_manager.request_ability()`

**Signal:** `EventBus.ability_used(caster: Node2D, target: Node2D, ability: Ability)` — currently unconsumed; wire SFX/UI here.

**Adding a new ability:** subclass `Ability`, set defaults in `_init()`, override `execute()`. Create a `.tres` in `data/abilities/`, then reference it from a `CharacterData.abilities` array.

### Combo / Follow-up System (`ComboSystem`)

Autoload (`scripts/managers/battle/combo_system.gd`) that dispatches battle events to characters' tier-1 **follow-ups** — reactive abilities that fire automatically off another unit's action. **Data-driven:** drop a `FollowUp` resource on `CharacterData.follow_ups` and it works with no per-scene wiring.

**Follow-up base** (`scripts/abilities/follow_up.gd`) defines a `Trigger` enum and the contract subclasses override: `reacts_to() → Trigger`, `is_eligible(owner, ctx) → bool`, `rolls() → bool` (chance gate), `resolve(owner, ctx)`.

**Concrete types & the live triggers:**

| Type | Trigger | Behavior | Built for |
|---|---|---|---|
| `FollowUpAttack` | `ALLY_ATTACKED_ENEMY` | chain a strike when an ally hits an enemy | archer (`archer_followup.tres`) |
| `FollowUpHeal` | `ALLY_DAMAGED` | mend a little when an ally takes damage | healer (`healer_followup.tres`) |
| `FollowUpIntercept` | pre-hit (`get_interceptor`) | take an incoming hit meant for an ally | dwarf (`dwarf_followup.tres`) |

**Dispatch wiring:** `_ready()` connects `EventBus.turn_started` (resets each character's `follow_up_used_this_turn` budget — **once per round**, refreshed on the character's *own* turn) and `EventBus.character_damaged` (→ `ALLY_DAMAGED`). `GameManager.request_attack` calls `await ComboSystem.on_attack(attacker, target)` (→ `ALLY_ATTACKED_ENEMY`). Pre-damage, `attack_target` calls `ComboSystem.get_interceptor(attacker, victim)` synchronously to redirect the hit.

**Open:** passives, *duo* abilities, and teaching the follow-up in the Beat 2 tutorial. **Build state:** see `docs/implementation_status.md`.

---

## Tilemap & Pathfinding

### Tilemap Manager

**Script:** `scripts/levels/tilemaps/tilemap.gd` | **Extends:** `Node2D`

Central tilemap controller. Added to group `"tilemap"` for global lookup.

**Constants:** `INVALID_TILE = Vector2i(-9999, -9999)`

**@onready references:**
- `base_layer: TileMapLayer` (`$BaseGrid`)
- `wall_tilemap: TileMapLayer` (`$Walls`)
- `objects_layer: TileMapLayer` (optional `$Objects`)
- `water_layer: TileMapLayer` (optional `$Water`)

**Runtime state:** `highlight_renderer: HighlightRenderer`, `astar_grid: AStarGrid2D`, `last_hovered_tile: Vector2i`, `game_manager: Node`, `cached_occupied_tiles: Dictionary`, `cached_reachable_tiles: Array`

**Public functions:**

| Function | Signature | Description |
|---|---|---|
| `setup_astar_grid` | `() → void` | Initialize `AStarGrid2D` from base layer bounds |
| `add_walkable_cells_from_tilemap` | `() → void` | Mark walkable/solid cells; handles multi-cell tiles |
| `get_astar_path` | `(start: Vector2i, end: Vector2i) → Array` | A* path; temporarily blocks occupied tiles |
| `highlight_reachable_tiles` | `(start: Vector2i, max_range: int, character: CharacterBase) → void` | BFS reachable + attack range overlay |
| `clear_highlights` | `() → void` | Clear all tile highlights |
| `highlight_attack_range` | `(start: Vector2i, min_range: int, max_range: int) → void` | Attack-only highlight (used during enemy AI) |
| `get_reachable_tiles` | `(start: Vector2i, max_range: int) → Array` | Public BFS without highlighting |
| `get_character_at_tile` | `(tile: Vector2i) → Node2D` | Query occupied tile cache |

**Signals connected to:** `EventBus.character_moved`, `EventBus.turn_started` (both refresh occupied tiles)

**Signals emitted:** `EventBus.tile_hovered` (mouse hover tracking)

### AStarGrid2D Pathfinding

- Grid initialized from `BaseGrid` TileMapLayer bounds
- `diagonal_mode = DIAGONAL_MODE_NEVER` (cardinal only)
- `_mark_layer_cells_solid()` called for Walls, Objects, Water layers
- Multi-cell tiles (e.g., 3×3 trees) — iterates `get_used_cells()`, checks `TileSetAtlasSource.get_tile_size_in_atlas()`, marks all covered cells as solid
- Occupied tiles temporarily set solid during `get_astar_path()`, then restored

### BFS Reachability

`_calculate_reachable_tiles(start, max_range, character) → Array[Vector2i]`:
1. **Cost-aware BFS** flood fill from start tile using a queue with `[tile, cost_so_far]` pairs
2. Each step adds `TerrainRegistry.get_move_cost(neighbor, tilemap)` — terrain with cost 99 (water, fences, houses) is effectively impassable
3. Tracks `visited` as `{tile: best_cost}` — revisits a tile if a cheaper path is found
4. Skips solid cells (`astar_grid.is_point_solid()`)
5. Skips tiles occupied by enemies (can't pass through)
6. Allows tiles occupied by allies (can pass through but not stop on — excluded from final result)
7. Returns list of reachable tiles the character can **stop on**

`highlight_reachable_tiles` combines BFS movement tiles + attack range tiles (union of all tiles within attack range of any reachable tile, excluding solid/friendly-occupied) into a single `HighlightRenderer` call.

### HighlightRenderer

**Script:** `scripts/levels/tilemaps/highlight_renderer.gd` | **class_name:** `HighlightRenderer`

Custom `_draw()` based renderer — no extra TileMapLayer overlays. Uses `queue_redraw()` on state changes.

**Style constants:**

| Constant | Color | Usage |
|---|---|---|
| `COLOR_CURRENT_CHAR` | `Color(0.1, 0.9, 0.2, 0.75)` | Green hollow square for active character |
| `COLOR_MOVEMENT` | `Color(0.05, 0.08, 0.18, 0.65)` | Dark filled squares for movement range |
| `COLOR_ATTACK` | `Color(0.95, 0.15, 0.1, 0.65)` | Red inset hollow squares for attack range |
| `COLOR_HOVER` | `Color(1.0, 1.0, 1.0, 0.35)` | Light outline for mouse hover |

**Public functions:**

| Function | Signature | Description |
|---|---|---|
| `setup` | `(layer: TileMapLayer) → void` | Set the base tilemap layer reference |
| `set_current_character` | `(tile: Vector2i) → void` | Set the active character tile |
| `set_movement_tiles` | `(tiles: Array) → void` | Set movement range tiles |
| `set_attack_tiles` | `(tiles: Array) → void` | Set attack range tiles |
| `set_hover` | `(tile: Vector2i) → void` | Set hover tile |
| `clear_hover` | `() → void` | Clear hover highlight |
| `clear_range_highlights` | `() → void` | Clear movement + attack |
| `clear_all` | `() → void` | Clear everything |

**Draw order:** Movement fill → attack inset → character outline → hover outline

### Tile Layers

| Layer Node | Purpose | Pathfinding Effect |
|---|---|---|
| `BaseGrid` | Ground terrain (grass, dirt, stone, sand) | Walkable base layer |
| `Walls` | Buildings, walls, fences | `_mark_layer_cells_solid()` — impassable |
| `Objects` | Trees, rocks, decorations | `_mark_layer_cells_solid()` — impassable |
| `Water` | Water, coast tiles | `_mark_layer_cells_solid()` — impassable |

---

## Walking Scene System

Free-roam exploration mode — no turns, no battle manager. The player moves tile-by-tile with WASD, interacts with NPCs, and walks through cinematic triggers that fire story events.

Walking scenes share the same `AStarGrid2D` and tilemap infrastructure as battles (the tilemap node is in group `"tilemap"`), but replace `GameManager` / `BattleInputHandler` with `WalkingPlayer` for direct movement control.

### WalkingScene

**Script:** `scripts/levels/walking_scene.gd` | **Extends:** `Node2D` | **class_name:** `WalkingScene`

Base class for all walking scenes. Handles two things every walking scene needs:

1. **Black backdrop** — Forward Plus renderer ignores `environment/default_clear_color`, so a solid black `ColorRect` on `CanvasLayer -10` prevents gray outside the tilemap.
2. **Optional music** — plays `music_key` via `AudioManager` on `_ready()`.

**@export:** `music_key: String = ""`

### WalkingPlayer

**Script:** `scripts/characters/walking/walking_player.gd` | **Extends:** `Node2D` | **class_name:** `WalkingPlayer`

Tile-snapped free-roam controller. Added to group `"walking_player"`.

**@export variables:**

| Variable | Type | Default | Description |
|---|---|---|---|
| `walk_speed` | float | 10.0 | Tiles per second during continuous walking |
| `first_step_boost` | float | 1.5 | Speed multiplier for the first step from rest or direction change |

**Movement system:**
- `_process()` reads WASD/arrow input every frame
- While a tween is in flight, input is buffered in `_queued_dir` and applied the instant the tween finishes — no dropped keystrokes
- Diagonal movement requires both the target tile and both adjacent cardinal tiles to be walkable (prevents corner-cutting through walls)
- Diagonal steps scale duration by √2 to maintain consistent visual speed
- `_is_tile_walkable()` checks: tile exists on `BaseGrid`, tile is not A* solid (walls, objects, water, NPCs)

**NPC interaction:**
- `_unhandled_input()` handles Space/Enter (talk to faced tile) and left-click (talk to clicked adjacent tile)
- Reuses `lock_movement()` / `unlock_movement()` to freeze the player during dialogue

**Cinematic integration:**
- `lock_movement()` — freezes all input, clears buffers, plays idle animation. Called by `CinematicTrigger` and the opening corridor fade.
- `unlock_movement()` — releases the lock.

**Public functions:**

| Function | Signature | Description |
|---|---|---|
| `lock_movement` | `() → void` | Freeze player (cinematic, dialogue, triggers) |
| `unlock_movement` | `() → void` | Release movement lock |

### WalkingNPC

**Script:** `scripts/characters/walking/walking_npc.gd` | **Extends:** `Node2D` | **class_name:** `WalkingNPC`

Stationary NPC that snaps to the nearest tile at runtime and blocks it in the A* grid. Added to group `"walking_npc"`.

**@export variables:**

| Variable | Type | Default | Description |
|---|---|---|---|
| `npc_name` | String | `"Villager"` | Speaker name shown in dialogue |
| `dialogue_lines` | Array[String] | `["Hello there, traveller!"]` | One entry per line of spoken text |

**Public function:** `get_dialogue() → Array[DialogueLine]` — builds typed `DialogueLine` objects from the exported string array.

### CinematicTrigger

**Script:** `scripts/story/cinematic_trigger.gd` | **Extends:** `Node2D` | **class_name:** `CinematicTrigger`

The primary tool for authoring story beats in walking scenes. Place a `CinematicTrigger` node on a tile; when the player walks onto it, the trigger fires its event sequence. Added to group `"cinematic_trigger"`.

**@export variables:**

| Variable | Type | Default | Description |
|---|---|---|---|
| `events` | Array[StoryEvent] | `[]` | Ordered list of events to execute |
| `one_shot` | bool | `true` | If true, fires once then disables |
| `lock_player` | bool | `true` | Freeze `WalkingPlayer` during execution |

**Important:** Custom `Resource` subclasses (all `StoryEvent` types) **cannot** be embedded as `sub_resource` in `.tscn` files due to a Godot ClassDB limitation. Events must be authored in code — typically in the scene script's `_setup_triggers()` method (see `OpeningCorridorScene`).

**Workflow:**
1. Add a `CinematicTrigger` `Node2D` to the scene in the editor
2. Position it on the target tile
3. Populate `events` from the scene script (e.g., `_setup_triggers()`)
4. Toggle `lock_player` and `one_shot` as needed

**Public function:** `reset() → void` — re-enable a one-shot trigger (for editor testing).

**Detection:** `_process()` compares `_player.current_tile == our_tile` every frame. For scenes with few triggers this is fine; a signal-based approach would scale better for dozens of triggers.

### OpeningCorridorScene

**Script:** `scripts/levels/opening_corridor_scene.gd` | **Extends:** `WalkingScene` | **class_name:** `OpeningCorridorScene`

The first playable scene. The player wakes in a dark corridor and walks upward toward a light while the Guardian makes contact through corrupted dialogue.

**Phase structure (position-triggered):**
1. **Phase 1 — VOID:** Hero appears in total darkness, player locked. Darkness fades uniformly over 3.5s, then floating glitch text "…walk forward." appears and player unlocks.
2. **Phase 2 — THE CALL:** Movement begins. Fragment spawning activates (max 2 clusters).
3. **Phase 3 — THE ASSEMBLY:** Path widens to 3 tiles. Floating text "…don't be afraid." More fragments (max 4 clusters).
4. **Phase 4 — THE CONNECTION:** Path widens to 5 tiles. Floating text "I've waited… a long time…" Unlimited fragment clusters.
5. **Phase 5 — TITLE:** Fragment spawning stops. World bloom — radial tile wave fills the screen. "TRISTOTACTICS" title card.
6. **Phase 6 — THE NAME:** Clean dialogue "What is your name?", name entry, Guardian echo, save checkpoint, white flash, scene change.

**Programmatically added children:** `ScreenOverlay`, `NameEntryDisplay`, `GlitchTextDisplay`, `CorridorPath`, `TitleCard`

**@export variables:**

| Variable | Type | Default | Description |
|---|---|---|---|
| `void_hold_duration` | float | 1.5 | Seconds of black before fade begins |
| `corridor_walk_speed` | float | 2.5 | Slow atmospheric walk speed |
| `corridor_anim_speed` | float | 0.25 | Animation speed scale |
| `start_light_radius` | float | 0.07 | Initial light bubble size |
| `start_light_softness` | float | 0.08 | Initial edge softness |
| `fade_in_duration` | float | 3.5 | How long the darkness fade takes |
| `max_light_radius` | float | 0.45 | Maximum light radius |
| `max_light_softness` | float | 0.20 | Maximum light softness |

**Key systems:**
- **CorridorPath** — Materializes path tiles under the hero's feet, fades a trail behind. Widens from 1 to 3 to 5 tiles across phases.
- **KingdomFragment** — Ghostly terrain sprites that breathe (sine wave), appear ahead of the player, and dissolve. Phase-aware cluster sizes and opacity.
- **Backtrack prevention** — Rows behind the player are sealed in the A* grid to enforce forward-only movement.

---

## Screen Effects

### ScreenOverlay

**Script:** `scripts/ui/screen_overlay.gd` | **Extends:** `CanvasLayer` | **class_name:** `ScreenOverlay`

Manages all full-screen visual effects for walking scenes. Added to group `"screen_overlay"` (layer 100). Built programmatically — four `ColorRect` children with shader materials.

**Render order (bottom → top):** Fog → Darkness → Bleed → Flash. Fog renders first so it's only visible inside the darkness light circle.

**Darkness API:**

| Function | Signature | Description |
|---|---|---|
| `set_darkness` | `(value: float) → void` | Set vignette intensity (0=off, 1=full black except circle) |
| `tween_darkness` | `(to: float, duration: float) → void` | Smooth tween (awaitable) |
| `set_light_center` | `(normalized_pos: Vector2) → void` | Light circle center in screen UV space (default `(0.5, 0.5)`) |
| `set_light_radius` | `(r: float) → void` | Radius of the lit area |
| `set_light_softness` | `(s: float) → void` | Edge softness of the light circle |

**Fog API:**

| Function | Signature | Description |
|---|---|---|
| `set_fog` | `(value: float) → void` | Set fog intensity (0=clear, 1=dense) |
| `tween_fog` | `(to: float, duration: float) → void` | Smooth tween (awaitable) |
| `set_fog_speed` | `(s: float) → void` | Drift speed |
| `set_fog_scale` | `(s: float) → void` | Noise scale (smaller = larger cloud shapes) |

**Bleed API:**

| Function | Signature | Description |
|---|---|---|
| `set_bleed` | `(value: float) → void` | Set Act-2 tint intensity |
| `tween_bleed` | `(to: float, duration: float) → void` | Smooth tween (awaitable) |

**Flash API:**

| Function | Signature | Description |
|---|---|---|
| `flash` | `(color, fade_in, hold, fade_out) → void` | Full flash cycle (awaitable) |
| `flash_hold` | `(color, fade_in) → void` | Flash to full and stay (for scene transitions; awaitable) |

### Darkness Shader

**File:** `shaders/darkness_overlay.gdshader`

Darkens everything except a soft circle around the player. Uses `smoothstep(radius, radius + softness, dist)` to create a smooth falloff from the center.

**Uniforms:**

| Uniform | Type | Default | Description |
|---|---|---|---|
| `light_center` | vec2 | `(0.5, 0.5)` | Screen-space center of the light |
| `radius` | float | 0.12 | Lit circle radius |
| `softness` | float | 0.06 | Edge falloff width |
| `darkness` | float | 1.0 | Global darkness multiplier |

**Gotcha:** When `radius=0` and `softness=0`, `smoothstep(0, 0, dist) = 1.0` everywhere → fully black. This is how the opening corridor starts with zero light leak.

### Fog Shader

**File:** `shaders/fog_overlay.gdshader`

Animated procedural mist using Fractal Brownian Motion (5-octave gradient noise). Two fog layers drift in different directions for parallax depth.

**Uniforms:**

| Uniform | Type | Default | Description |
|---|---|---|---|
| `intensity` | float | 0.0 | Overall fog visibility (0=invisible) |
| `fog_color` | vec4 | `(0.55, 0.58, 0.65, 1.0)` | Tint color of the fog |
| `speed` | float | 0.12 | Drift speed |
| `scale` | float | 3.5 | Noise scale (smaller = larger clouds) |
| `density` | float | 1.8 | Power curve for edge sharpness |

**Algorithm:** `fbm(uv + time_offset_1) + fbm(uv * 1.4 + time_offset_2)` → remap to 0–1 → `pow(fog, density)` → multiply by `intensity` for final alpha.

### Bleed Shader

**File:** `shaders/bleed_overlay.gdshader`

Simple color tint overlay for the Act-2 "Bleed" palette (desaturated, earthy ruin). Placeholder — will be refined when real art assets arrive.

**Uniforms:**

| Uniform | Type | Default | Description |
|---|---|---|---|
| `bleed_color` | vec4 | `(0.18, 0.22, 0.12, 1.0)` | Tint color |
| `intensity` | float | 0.0 | 0=invisible, 1=full tint |

### CanvasLayer Ordering

All layers across the game, from back to front:

| Layer | Node | Purpose |
|---|---|---|
| -10 | WalkingScene black backdrop | Solid black behind everything (prevents gray outside tiles) |
| 0 | *(default)* | Game world, tilemaps, characters |
| 100 | ScreenOverlay / AttackAnimationOverlay | Full-screen effects (fog/darkness/bleed/flash) / battle cutscene |
| 110 | DialogueBox | Dialogue bar (above effects so text is always readable) |
| 115 | GlitchTextDisplay | Cinematic centered text (above dialogue) |
| 116 | NameEntryDisplay | Name entry UI (topmost interactive layer) |

---

## UI Systems

### Attack Animation Overlay

**Script:** `scripts/ui/attack_animation_overlay.gd` | **Extends:** `CanvasLayer` | **layer:** 100

Full-screen blocking combat cutscene. Called with `await` from `CharacterBase.attack_target()`.

**Animation constants:**

| Constant | Value |
|---|---|
| `FADE_DURATION` | 0.15s |
| `LUNGE_DURATION` | 0.12s |
| `LUNGE_RETURN_DURATION` | 0.1s |
| `SHAKE_DURATION` | 0.3s |
| `SHAKE_INTENSITY` | 6.0 px |
| `HOLD_DURATION` | 0.3s |
| `LUNGE_DISTANCE` | 40.0 px |
| `BOX_WIDTH_FRAC` | 0.55 (55% of viewport) |
| `BOX_HEIGHT_FRAC` | 0.35 (35% of viewport) |
| `ATTACKER_X_FRAC` | 0.35 |
| `DEFENDER_X_FRAC` | 0.65 |
| `CHARACTER_Y_FRAC` | 0.55 |
| `CHARACTER_SCALE` | Vector2(3, 3) |

**UI structure (built programmatically in `_build_ui()`):**
- `_root: Control` — fadeable container (CanvasLayer has no `modulate`)
- `_backdrop: ColorRect` — full-screen, `Color(0, 0, 0, 0.75)`
- `_box: PanelContainer` — centered, dark rounded `StyleBoxFlat` (bg `0.08, 0.08, 0.12, 0.95`, border `0.6, 0.6, 0.7, 0.6`, radius 8)
- `_box_content: Control` — sprite/label container
- `_damage_label: Label` — z_index 10, 32pt (42pt for crit)

**Public function:**
- `play_attack_animation(attacker: CharacterBase, defender: CharacterBase, damage: int, is_crit: bool) → void` — `await`-able

**Sprite cloning:** `_clone_sprite()` finds the first `AnimatedSprite2D` child on the character, creates a new `AnimatedSprite2D` with the same `sprite_frames` and current animation.

### Character Info Panel

**Script:** `scripts/ui/character_info_panel.gd` | **Extends:** `PanelContainer`

Top-left HUD panel. `var current_character: CharacterBase`.

**Displays:** Character name, Movement (remaining/total), Attacks left (0 or 1), Attack range (single or min–max)

**Signals connected to:** `EventBus.turn_started`, `EventBus.character_movement_finished`, `EventBus.character_attacked`

### Tile Info Panel

**Script:** `scripts/ui/tile_info_panel.gd` | **Extends:** `PanelContainer`

Delegates all terrain data to `TerrainRegistry`. Displays terrain name, defense bonus, move cost, and colored terrain label on hover.

**Signal connected to:** `EventBus.tile_hovered` → calls `TerrainRegistry.get_terrain_at(tile_pos, tilemap)` and updates labels.

### Health Bars

**Script:** `scripts/ui/health_bar.gd` | **Extends:** `ProgressBar` | **class_name:** `HealthBar`

**Constants:** `BAR_SIZE = Vector2(16, 3)`, `BAR_OFFSET = Vector2(-8, -12)`, `CORNER_RADIUS = 1`

**Public functions:**
- `setup(max_hp_value: int, current_hp_value: int, team: String) → void`
- `update_hp(current_hp_value: int, max_hp_value: int, team: String) → void`

**Color logic:** Player=green, Enemy=red above 50%. Both shift to yellow at 25–50%, orange-red below 25%.

Auto-created by `CharacterBase._create_health_bar()` in `_ready()`.

### Speed Toggle Button

**Script:** `scripts/ui/speed_toggle_button.gd` | **Extends:** `Button`

**Constants:** `SPEED_NORMAL = 1.0`, `SPEED_FAST = 2.0`

Sets `Engine.time_scale` between 1× and 2×. `focus_mode = Control.FOCUS_NONE` to prevent Space key. Resets to `SPEED_NORMAL` on `_exit_tree()`.

### Victory/Defeat Screen

**Script:** `scripts/ui/victory_defeat_screen.gd` | **Extends:** `CanvasLayer` (layer 100)

**Public function:** `show_result(victory: bool) → void`

Victory: gold text + `"victory"` music. Defeat: red text + `"defeat"` music. Animated tween fade-in + scale. "Return to Menu" button → `get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")`.

### GlitchTextDisplay

**Script:** `scripts/ui/glitch_text_display.gd` | **Extends:** `CanvasLayer` | **class_name:** `GlitchTextDisplay`

Raw cinematic text overlay — centered on screen with a dark veil behind it (no portrait, no dialogue bar). Layer 115. Added to group `"glitch_text_display"`.

Used for Guardian transmissions, system messages, lore reveals. Driven by `GlitchTextEvent`.

**Layout:** Dark background `ColorRect` (55% opacity) + centered `VBoxContainer` (640px wide) with speaker label (accent green), body `RichTextLabel`, and advance prompt.

**Public functions:**

| Function | Signature | Description |
|---|---|---|
| `play_line` | `(text, speaker, glitched, wait_input) → void` | Awaitable — show one line with optional glitch typewriter |
| `hide_now` | `() → void` | Immediately hide |

**Typewriter:** Own implementation separate from `DialogueBox`. Glitch mode flickers 0–4 random glyphs per character at 0.045s intervals. Currently not skippable mid-typewriter (future enhancement). Supports `{player_name}` substitution.

**Constants:** `CHARS_PER_SECOND = 18.0` (slower than DialogueBox for dramatic effect).

### NameEntryDisplay

**Script:** `scripts/ui/name_entry_display.gd` | **Extends:** `CanvasLayer` | **class_name:** `NameEntryDisplay`

In-scene name entry UI with prompt, text field, and confirm button. Layer 116 (topmost). Added to group `"name_entry_display"`.

**Layout:** Dark background `ColorRect` (65% opacity, `MOUSE_FILTER_STOP` to block interaction below) + centered `VBoxContainer` with prompt label (green), `LineEdit` (max 24 chars), and "CONFIRM" button.

**Signal:** `name_confirmed(entered_name: String)`

**Public function:** `prompt(prompt_text: String) → String` — awaitable. Shows the UI, waits for Enter or button click, saves to `PlayerDataManager`, returns the entered name. Defaults to `"Hero"` if submitted empty.

---

## Menu System

### MenuStack

**Script:** `scripts/core/menu_stack.gd` | **class_name:** `MenuStack`

**@export:** `handle_escape_input: bool = true`

**Signals defined:** `stack_emptied`, `menu_pushed(menu: Control)`, `menu_popped(menu: Control)`

**Public functions:**

| Function | Signature | Description |
|---|---|---|
| `push_menu` | `(menu: Control, use_canvas_layer: bool = true)` | Push, optionally wrap in CanvasLayer |
| `pop_menu` | `() → Control` | Pop and free top menu |
| `go_back` | `()` | Alias for `pop_menu()` |
| `clear_all` | `()` | Pop all |
| `has_menus` | `() → bool` | Stack non-empty |
| `get_current_menu` | `() → Control` | Top menu |
| `get_stack_size` | `() → int` | Stack depth |

Auto-connects to `back_requested` signal on pushed menus. `process_mode = ALWAYS`.

### Main Menu

**Script:** `scripts/menus/main_menu.gd` | **Extends:** `Control`

Creates its own `MenuStack`. Buttons:
- **New Game** → `PlayerDataManager.reset_player_data()`, fade to black, then `change_scene_to_file("res://scenes/levels/opening_corridor_scene.tscn")`
- **Continue** (disabled if no save) → `PlayerDataManager.load_player_data()` then loads `current_scene` checkpoint (falls back to opening corridor)
- **Settings** → hides main VBox, pushes `SettingsMenu` onto its `MenuStack`
- **Quit** → `get_tree().quit()`

Plays `"menu"` music on `_ready()`. Fades in from black when arriving from `SplashScreen`.

### Pause Menu

**Script:** `scripts/ui/pause_menu.gd` | **Extends:** `BaseMenu`

**Signal defined:** `settings_requested`

Opened by `PauseMenuHandler` (`scripts/levels/pause_menu_handler.gd`) which creates a `MenuStack`, handles Escape, pauses/unpauses scene tree. Resume → `request_back()`. Settings → emits `settings_requested`. Quit → `get_tree().quit()`.

### Settings Menu

**Script:** `scripts/ui/settings_menu.gd` | **Extends:** `BaseMenu`

| Control | Range | Backed By |
|---|---|---|
| Music Volume slider | 0–100 | `SettingsManager.set_music_volume()` |
| SFX Volume slider | 0–100 | `SettingsManager.set_sfx_volume()` |
| Fullscreen checkbox | bool | `SettingsManager.set_fullscreen()` |
| VSync checkbox | bool | `SettingsManager.set_vsync()` |
| FPS Limit dropdown | Unlimited/30/60/120/144 | `SettingsManager.set_fps_limit()` |

`show_menu()` syncs controls from saved settings with `_ignore_callbacks` guard. Back → `request_back()`.

**BaseMenu** (`scripts/ui/base_menu.gd` | `class_name: BaseMenu`):
- Signal: `back_requested`
- Functions: `request_back()`, `show_menu()`, `hide_menu()`, `_setup_menu()` (virtual)
- Applies `PRESET_FULL_RECT` and `MOUSE_FILTER_STOP`

---

## Camera System

**Script:** `scripts/managers/battle/camera_control.gd` | **Extends:** `Camera2D`

**@export variables:**

| Variable | Type | Default |
|---|---|---|
| `move_speed` | float | 500.0 |
| `zoom_speed` | float | 0.1 |
| `min_zoom` | float | 0.5 |
| `max_zoom` | float | 3.0 |
| `focus_lerp_speed` | float | 5.0 |
| `use_smooth_focus` | bool | true |

**Public functions:**
- `move_camera(character: Node2D) → void` — smooth lerp focus on character
- `snap_to(pos: Vector2) → void` — instant reposition

Added to group `"action_camera"`. WASD/arrow input cancels auto-focus. Mouse wheel zoom with clamping.

---

## Level System

**BaseLevel** (`scripts/levels/base_level.gd`) | **Extends:** `Node2D` | **class_name:** `BaseLevel`

**@export:** `music_key: String = ""`

**Preloads:** `VictoryDefeatScreenScene = preload("res://scenes/ui/VictoryDefeatScreen.tscn")`

**Behavior:** Plays `music_key` via AudioManager on `_ready()`. Connects to `EventBus.battle_ended` → waits 0.8s → instantiates VictoryDefeatScreen.

**DevSandboxScene** (`scripts/levels/dev_sandbox_scene.gd`) | **Extends:** `BaseLevel` — sets `music_key = "battle"`. Creates a `DialogueEvent` with intro dialogue lines and assigns it to `GameManager.intro_event`. Dev-only battle playground (Hero/Archer/Healer vs goblins at mountain pass); not on the story critical path — retained as a reference sandbox for exercising the battle system end-to-end.

**PauseMenuHandler** (`scripts/levels/pause_menu_handler.gd`) | **Extends:** `Node` — creates `MenuStack`, handles Escape key, pauses/unpauses.

**OpeningCorridorScene** (`scripts/levels/opening_corridor_scene.gd`) | **Extends:** `WalkingScene` — the game's opening sequence. See the Walking Scene System section.

**SummoningRoomScene** (`scripts/levels/summoning_room_scene.gd`) | **Extends:** `Node2D` — walking scene with a `DoorTrigger` node. On interact: locks the player, saves a checkpoint to `next_scene_path`, fades to black, changes scene. Default `next_scene_path` is the tutorial scene. (Act 1 Beat 1 target — currently atmosphere only; Vael + dialogue not yet implemented.)

**TutorialScene** (`scripts/levels/tutorial_scene.gd`) | **Extends:** `BaseLevel` — 7-line stub, sets `music_key = "menu"` and calls `super._ready()`. (Act 1 Beat 2 target — content not yet implemented.)

---

## Scene Flow

Entry point is configured in `project.godot` as `res://scenes/menus/SplashScreen.tscn`. The full main path:

```
SplashScreen ──► MainMenu ──► [New Game]
                   │              │
                   │              ▼
                   │         OpeningCorridorScene ──► SummoningRoomScene ──► TutorialScene
                   │         (6 phases,                   (door trigger,       (stub, music only)
                   │          name entry)                  saves checkpoint)
                   │
                   └─ [Continue] ──► PlayerDataManager.current_scene (last saved checkpoint)
                                     Falls back to OpeningCorridorScene if empty.

DevSandboxScene (standalone) ──► dev-only battle playground; not reachable from main flow (reference sandbox)
```

**Transitions — authoritative list** (grep `change_scene_to_file`):

| From | Trigger | To |
|---|---|---|
| `SplashScreen` | logo fade-out timer | `MainMenu.tscn` |
| `MainMenu` → New Game | button press | `opening_corridor_scene.tscn` |
| `MainMenu` → Continue | button press | `PlayerDataManager.current_scene` (checkpoint) |
| `OpeningCorridorScene` | Phase 6 final fade | `next_scene_path` (default `summoning_room_scene.tscn`) |
| `SummoningRoomScene` | `DoorTrigger` interact | `next_scene_path` (default `tutorial_scene.tscn`) |
| `PauseMenu` → Quit to Main Menu | button press | `MainMenu.tscn` |
| `VictoryDefeatScreen` → Main Menu | button press | `MainMenu.tscn` |
| Any | `SceneChangeEvent` in a story event chain | configured `scene_path` |

**Checkpoints:** `PlayerDataManager.set_checkpoint(scene_path)` is called:
- In `OpeningCorridorScene` before the final "Find me" sequence (`next_scene_path`)
- In `SummoningRoomScene._on_door_triggered()` (`next_scene_path`)
- In `PauseMenu._on_quit_pressed()` (current scene path)
- Via `SaveCheckpointEvent` in story event chains

**Scene → Script reference table:**

| Scene | Script | class_name |
|---|---|---|
| `scenes/menus/SplashScreen.tscn` | `scripts/menus/splash_screen.gd` | — |
| `scenes/ui/MainMenu.tscn` | `scripts/menus/main_menu.gd` | — |
| `scenes/levels/opening_corridor_scene.tscn` | `scripts/levels/opening_corridor_scene.gd` | `OpeningCorridorScene` |
| `scenes/levels/summoning_room_scene.tscn` | `scripts/levels/summoning_room_scene.gd` | `SummoningRoomScene` |
| `scenes/levels/tutorial_scene.tscn` | `scripts/levels/tutorial_scene.gd` | — |
| `scenes/levels/dev_sandbox_scene.tscn` | `scripts/levels/dev_sandbox_scene.gd` | — |

> **Implementation status by story beat:** see [`docs/implementation_status.md`](docs/implementation_status.md).

---

## Story Events

General-purpose system for events that pause gameplay — dialogue, cutscenes, environment changes, etc. Any script can trigger events at any time via `GameManager.play_event()` or the decoupled `EventBus.story_event_triggered` signal. Walking scenes use `CinematicTrigger` nodes instead.

**Trigger patterns:**
```gdscript
# Battle — via GameManager:
await game_manager.play_event(my_event)

# Battle — decoupled (GameManager listens automatically):
EventBus.story_event_triggered.emit(my_event)
await my_event.completed

# Walking scene — via CinematicTrigger (fires when player steps on tile):
trigger.events = [event1, event2, event3]
```

### StoryEvent

**Script:** `scripts/story/story_event.gd` | **class_name:** `StoryEvent` | **Extends:** `Resource`

Base class for all gameplay-pausing events. Subclass and override `execute()`.

**Signal:** `completed` — emitted by `GameManager.play_event()` after `execute()` returns.

**Virtual method:** `execute(scene_tree: SceneTree) -> void` — override with event logic. Use `await` for async operations.

### DialogueEvent

**Script:** `scripts/story/dialogue_event.gd` | **class_name:** `DialogueEvent` | **Extends:** `StoryEvent`

Plays a sequence of dialogue lines through the `DialogueBox`.

**@export:** `lines: Array[DialogueLine]`

**execute():** Finds `dialogue_box` via group lookup, calls `await dialogue_box.play_sequence(lines)`.

### DialogueBox

**Script:** `scripts/story/dialogue_box.gd` | **Extends:** `CanvasLayer`

Full-width bottom bar for dialogue sequences. Added to group `"dialogue_box"`. Layer 110, programmatic UI build.

**Layout:** `PanelContainer` (anchored bottom, full width, 140px tall) → `HBoxContainer` → portrait panel (80×80 `TextureRect`) + `VBoxContainer` (speaker `Label` in gold, `RichTextLabel` body, advance indicator `"▼"`).

**Typewriter modes:**
1. **Normal** — `_process()` reveals characters at `CHARS_PER_SECOND` (30). Click/Space: first press instant-fills, second press advances.
2. **Glitch** — async coroutine `_play_glitch_typewriter()`. Each character flickers through `GLITCH_CHARS` ("█▓▒░▄▀■□▪◆●○▸▹") at 0.04s intervals before resolving. Click/Space: skips to full text.

**Glitch coroutine safety — generation counter pattern:**
- `_glitch_generation: int` incremented on each new line and on `_close()`
- `_play_glitch_typewriter(text, gen)` checks `gen != _glitch_generation` at three points: loop start, after inner glitch loop, and after each character delay
- This ensures stale coroutines from previous lines exit cleanly without corrupting the current line's text

**Text substitution:** `{player_name}` in line text is replaced with `PlayerDataManager.get_player_name()` at display time.

**Signal:** `sequence_finished` — emitted after all lines are advanced through. Has a 0.15s debounce in `_close()` to prevent the closing click from leaking into the next event.

**Constants:**

| Constant | Value |
|---|---|
| `CHARS_PER_SECOND` | 30.0 |
| `GLITCH_CHARS` | `"█▓▒░▄▀■□▪◆●○▸▹"` |
| `GLITCH_CHAR_DELAY` | 0.04 |

### DialogueLine

**Script:** `scripts/story/dialogue_line.gd` | **class_name:** `DialogueLine` | **Extends:** `Resource`

Data resource for one line of dialogue.

**@export fields:**

| Field | Type | Default | Description |
|---|---|---|---|
| `speaker` | String | `""` | Speaker name (empty = no label shown) |
| `text` | String | `""` | Dialogue text (supports `{player_name}` substitution) |
| `portrait` | Texture2D | null | Character headshot (optional) |
| `glitched` | bool | `false` | If true, characters flicker with noise before resolving |

### WaitEvent

**Script:** `scripts/story/wait_event.gd` | **class_name:** `WaitEvent` | **Extends:** `StoryEvent`

Pauses the event sequence for a fixed duration. Useful as a breathing moment between cinematic beats.

**@export:** `duration: float = 1.0`

### FlashEvent

**Script:** `scripts/story/flash_event.gd` | **class_name:** `FlashEvent` | **Extends:** `StoryEvent`

Full-screen color flash via `ScreenOverlay`. For warp moments, waking up, boss hits, etc.

**@export fields:**

| Field | Type | Default | Description |
|---|---|---|---|
| `color` | Color | `WHITE` | Flash color |
| `fade_in` | float | 0.12 | Fade-to-color duration |
| `hold` | float | 0.35 | Hold at full intensity |
| `fade_out` | float | 0.55 | Fade-back duration |
| `hold_and_cut` | bool | `false` | If true, flash to full and stay (for scene transitions) |

### OverlayEvent

**Script:** `scripts/story/overlay_event.gd` | **class_name:** `OverlayEvent` | **Extends:** `StoryEvent`

Tweens darkness or bleed intensity on the `ScreenOverlay`.

**@export fields:**

| Field | Type | Default | Description |
|---|---|---|---|
| `layer` | Layer enum | `DARKNESS` | Which overlay to affect (`DARKNESS` or `BLEED`) |
| `target` | float | 1.0 | Target intensity |
| `duration` | float | 1.0 | Tween duration |

### FogEvent

**Script:** `scripts/story/fog_event.gd` | **class_name:** `FogEvent` | **Extends:** `StoryEvent`

Tweens fog intensity on the `ScreenOverlay`.

**@export fields:**

| Field | Type | Default | Description |
|---|---|---|---|
| `target` | float | 0.3 | Target fog intensity |
| `duration` | float | 2.0 | Tween duration |

### GlitchTextEvent

**Script:** `scripts/story/glitch_text_event.gd` | **class_name:** `GlitchTextEvent` | **Extends:** `StoryEvent`

Displays cinematic text via `GlitchTextDisplay` — raw centered screen text (not the dialogue bar). For Guardian transmissions, system messages, lore reveals.

**@export fields:**

| Field | Type | Default | Description |
|---|---|---|---|
| `text` | String | `""` | Text to display (supports `{player_name}`) |
| `speaker` | String | `""` | Optional speaker label above text |
| `glitched` | bool | `true` | Characters flicker with noise before resolving |
| `wait_for_input` | bool | `true` | If true, waits for click/Space to advance |

### NameEntryEvent

**Script:** `scripts/story/name_entry_event.gd` | **class_name:** `NameEntryEvent` | **Extends:** `StoryEvent`

Prompts the player for their name via `NameEntryDisplay`. Saves to `PlayerDataManager` on confirm.

**@export:** `prompt_text: String = "What is your name?"`

### SceneChangeEvent

**Script:** `scripts/story/scene_change_event.gd` | **class_name:** `SceneChangeEvent` | **Extends:** `StoryEvent`

Transitions to a new scene. Pair with `FlashEvent(hold_and_cut=true)` immediately before for a seamless cut.

**@export:** `scene_path: String = ""` (file filter: `*.tscn`)

### CallbackEvent

**Script:** `scripts/story/callback_event.gd` | **class_name:** `CallbackEvent` | **Extends:** `StoryEvent`

Calls an arbitrary `Callable` during an event sequence. For one-off effects that don't warrant their own StoryEvent subclass (toggling fragments, starting particles, etc.).

**Property:** `callback: Callable` — set in code, not exportable. If the callback returns a `Signal`, it is awaited.

### SaveCheckpointEvent

**Script:** `scripts/story/save_checkpoint_event.gd` | **class_name:** `SaveCheckpointEvent` | **Extends:** `StoryEvent`

Saves the current game state to disk via `PlayerDataManager`.

**@export:** `scene_path: String = ""` — the scene path to record as the checkpoint.

### TitleEvent

**Script:** `scripts/story/title_event.gd` | **class_name:** `TitleEvent` | **Extends:** `StoryEvent`

Displays a cinematic title card via `TitleCard`. Fire-and-forget — does not block the event sequence.

**@export fields:**

| Field | Type | Default | Description |
|---|---|---|---|
| `text` | String | `""` | Title text to display |
| `fade_in` | float | 1.0 | Fade-in duration |
| `hold` | float | 3.0 | Hold duration at full opacity |
| `fade_out` | float | 1.5 | Fade-out duration |

---

## Developer Tools

### Placeholder SFX Generator

**Script:** `scripts/tools/generate_placeholder_sfx.gd` | `@tool` | **Extends:** `EditorScript`

Run from Godot Editor: **Script → File → Run**

Generates 11 procedural WAV files (8-bit, 22050 Hz) in `res://assets/audio/sfx/`:
`button_click`, `select`, `move`, `attack`, `hit`, `crit`, `miss`, `death`, `heal`, `turn_start`, `enemy_turn`

Each uses sine wave synthesis with unique frequency/envelope profiles.

---

## File Structure

```
scripts/
├── core/
│   ├── event_bus.gd          # Global signal bus (autoload)
│   ├── constants.gd          # Shared constants (autoload)
│   ├── terrain_registry.gd   # Terrain data: costs, defense, classification (autoload)
│   ├── audio_manager.gd      # Music + SFX engine (autoload)
│   ├── settings_manager.gd   # User preferences persistence (autoload)
│   ├── game_sfx_manager.gd   # Event→SFX bridge (autoload)
│   └── menu_stack.gd         # Reusable LIFO menu manager
├── characters/
│   ├── base/
│   │   ├── character_base.gd     # Root character class (CharacterBase)
│   │   ├── character_data.gd     # Identity resource (CharacterData)
│   │   ├── character_sfx.gd      # SFX override resource (CharacterSFX)
│   │   ├── player_character.gd   # Player team base (PlayerCharacter)
│   │   └── archer_character.gd   # Ranged player unit (ArcherCharacter)
│   ├── enemies/
│   │   ├── enemy_character.gd    # Enemy base with AI (EnemyCharacter)
│   │   └── goblin_character.gd   # Fast melee enemy (GoblinCharacter)
│   └── walking/
│       ├── walking_player.gd     # Free-roam tile-snapped player (WalkingPlayer)
│       ├── walking_npc.gd        # Stationary NPC with dialogue (WalkingNPC)
│       └── corridor_camera.gd    # Smooth-follow camera for corridor scenes
├── managers/
│   ├── player_data_manager.gd    # Player name + party persistence (autoload)
│   ├── steam_manager.gd          # Steam integration (achievements, stats)
│   ├── tutorial_manager.gd       # Tutorial flow and prompts
│   └── battle/
│       ├── game_manager.gd        # Battle orchestrator
│       ├── battle_input_handler.gd # Player mouse click handling
│       └── camera_control.gd      # Camera follow + zoom
├── levels/
│   ├── base_level.gd                # Base battle level class
│   ├── walking_scene.gd             # Base walking scene (WalkingScene)
│   ├── opening_corridor_scene.gd    # Opening corridor (OpeningCorridorScene)
│   ├── summoning_room_scene.gd     # Post-corridor summoning chamber
│   ├── corridor_path.gd            # Materializing path under the hero (CorridorPath)
│   ├── corridor_particles.gd       # Ambient particle effects for corridor
│   ├── corridor_vision.gd          # Kingdom/companion vision sprites
│   ├── kingdom_fragment.gd         # Ghostly terrain fragment sprite (KingdomFragment)
│   ├── tutorial_scene.gd            # Tutorial level (Act 1 Beat 2 — stub)
│   ├── dev_sandbox_scene.gd         # Dev-only battle playground (goblins/mountain pass; reference sandbox)
│   ├── walking_door.gd              # Interactable door trigger
│   ├── pause_menu_handler.gd        # In-game pause system
│   └── tilemaps/
│       ├── tilemap.gd               # Tilemap manager (A*, BFS, highlights)
│       ├── highlight_renderer.gd    # Custom _draw() tile highlights
│       └── tutorial_tilemap.gd      # Tutorial-specific tilemap generation
├── menus/
│   ├── splash_screen.gd             # Studio splash (entry scene)
│   └── main_menu.gd                 # Main menu screen
├── abilities/
│   ├── ability.gd                   # Base ability resource (Ability)
│   └── heal_ability.gd              # Restore HP to an ally (HealAbility)
├── story/
│   ├── story_event.gd          # Base event class (StoryEvent)
│   ├── dialogue_event.gd       # Dialogue sequence (DialogueEvent)
│   ├── dialogue_box.gd         # Full-width dialogue UI with glitch mode
│   ├── dialogue_line.gd        # Single dialogue line resource (DialogueLine)
│   ├── cinematic_trigger.gd    # Tile-based event trigger (CinematicTrigger)
│   ├── wait_event.gd           # Timed pause (WaitEvent)
│   ├── flash_event.gd          # Screen flash (FlashEvent)
│   ├── overlay_event.gd        # Darkness/bleed tween (OverlayEvent)
│   ├── fog_event.gd            # Fog tween (FogEvent)
│   ├── glitch_text_event.gd    # Cinematic centered text (GlitchTextEvent)
│   ├── name_entry_event.gd     # Name prompt (NameEntryEvent)
│   ├── scene_change_event.gd   # Scene transition (SceneChangeEvent)
│   ├── callback_event.gd       # Arbitrary Callable execution (CallbackEvent)
│   ├── save_checkpoint_event.gd # Save checkpoint to PlayerDataManager (SaveCheckpointEvent)
│   └── title_event.gd          # Display title card (TitleEvent)
├── ui/
│   ├── attack_animation_overlay.gd  # Blocking attack cutscene (autoload)
│   ├── screen_overlay.gd            # Fog/darkness/bleed/flash effects (ScreenOverlay)
│   ├── glitch_text_display.gd       # Centered cinematic text (GlitchTextDisplay)
│   ├── name_entry_display.gd        # In-scene name entry (NameEntryDisplay)
│   ├── base_menu.gd                 # Base menu class (BaseMenu)
│   ├── pause_menu.gd                # Pause menu
│   ├── settings_menu.gd             # Settings menu
│   ├── health_bar.gd                # Per-character HP bar (HealthBar)
│   ├── character_info_panel.gd      # Current character stats HUD
│   ├── tile_info_panel.gd           # Tile hover tooltip
│   ├── speed_toggle_button.gd       # 1×/2× speed toggle
│   ├── victory_defeat_screen.gd     # End-of-battle screen
│   └── title_card.gd               # Cinematic title display (TitleCard)
└── tools/
    └── generate_placeholder_sfx.gd  # Procedural SFX generator (@tool)

shaders/
├── darkness_overlay.gdshader    # Light-circle vignette (smoothstep)
├── fog_overlay.gdshader         # Animated FBM noise mist
└── bleed_overlay.gdshader       # Act-2 color tint overlay

scenes/
├── characters/     # Character .tscn scene files
├── levels/         # Level .tscn scene files
├── managers/       # Manager .tscn scene files
├── menus/          # Menu .tscn scene files
└── ui/             # UI element .tscn scene files

assets/
├── audio/
│   ├── music/      # Music tracks
│   └── sfx/        # Sound effects (.wav)
├── fonts/          # Custom fonts
├── sprites/        # Character and UI sprites
└── tilesets/       # Tileset resources
```

---

## Input Mapping

| Action | Keys | Context |
|---|---|---|
| `ui_left` | Arrow Left, A, DPad Left | Camera pan (battle) / move left (walking) / menu navigation |
| `ui_right` | Arrow Right, D, DPad Right | Camera pan (battle) / move right (walking) / menu navigation |
| `ui_up` | Arrow Up, W, DPad Up | Camera pan (battle) / move up (walking) / menu navigation |
| `ui_down` | Arrow Down, S, DPad Down | Camera pan (battle) / move down (walking) / menu navigation |
| `ui_accept` | Space, Enter | End turn (battle) / talk to NPC (walking) / advance dialogue |
| `ui_cancel` | Escape | Open pause menu / go back |
| `ui_zoom_in` | Mouse Wheel Up | Camera zoom in (battle) |
| `ui_zoom_out` | Mouse Wheel Down | Camera zoom out (battle) |
| Left Click | Mouse Button 1 | Select tile / attack (battle) / talk to NPC (walking) / advance dialogue |

---

## Signal Reference

Complete list of all EventBus signals with their full lifecycle:

```gdscript
# Battle Flow
signal battle_started                                                    # GameManager → (unused currently)
signal battle_ended(victory: bool)                                      # GameManager → BaseLevel, GameSFXManager
signal turn_started(character: CharacterBase)                           # GameManager → InfoPanel, GameSFXManager, Tilemap
signal turn_ended(character: CharacterBase)                             # GameManager → (future use)

# Character Events
signal character_moved(character: Node2D, from_tile: Vector2i, to_tile: Vector2i)  # CharacterBase → Tilemap
signal character_movement_started(character: Node2D)                    # CharacterBase → GameSFXManager
signal character_movement_finished(character: Node2D)                   # CharacterBase → GameManager, InfoPanel
signal character_attacked(attacker: Node2D, target: Node2D, damage: int, is_crit: bool)  # Overlay → GameSFXManager, InfoPanel
signal ability_used(caster: Node2D, target: Node2D, ability: Ability)  # GameManager → (unconsumed — wire SFX/UI here)
signal character_damaged(character: Node2D, amount: int, source: Node2D)  # CharacterBase → GameSFXManager
signal character_healed(character: Node2D, amount: int, source: Node2D)   # CharacterBase → GameSFXManager
signal character_died(character: Node2D)                                # CharacterBase → GameManager, GameSFXManager

# Tile Events
signal tile_hovered(tile_pos: Vector2i)                                # Tilemap → TileInfoPanel

# UI Events
signal update_turn_indicator(character: Node2D, is_enemy: bool)        # GameManager → UI turn label
```

---

## How to Add Content

### Adding a New Player Character

1. Create a new script extending `PlayerCharacter`:
   ```gdscript
   extends PlayerCharacter
   class_name MageCharacter

   func _init():
       max_hp = 20
       attack_power = 12
       defense = 2
       initiative = 8
       move_range = 4
       attack_range_min = 2
       attack_range_max = 3
   ```
2. Create a `.tscn` scene with a `Node2D` root, attach the script, add an `AnimatedSprite2D` child with the character's sprite frames.
3. Place the scene in a level.
4. **Alternative:** Instead of setting stats in `_init()`, create a `CharacterData` resource (`.tres`) with `override_stats = true` and all stat fields filled in. Assign it to the character's `character_data` @export.

1. Create a new script extending `EnemyCharacter`:
   ```gdscript
   extends EnemyCharacter
   class_name OrcCharacter

   func _init():
       max_hp = 30
       attack_power = 12
       defense = 6
       initiative = 5
       move_range = 3
       ai_pause_duration = 1.0
   ```
2. The AI system from `EnemyCharacter` (`execute_ai_turn`) is inherited automatically.
3. Override `execute_ai_turn()` for custom AI behavior.

### Adding a New Level

1. Create a new `.tscn` scene with: Tilemap (BaseGrid + Walls + Objects + Water layers), GameManager, BattleInputHandler, Camera, UI nodes.
2. Create a script extending `BaseLevel`:
   ```gdscript
   extends BaseLevel

   func _ready():
       music_key = "battle"
       super._ready()
   ```
3. Place character scenes on the map.

### Adding a Walking Scene

1. Create a new `.tscn` scene with: Tilemap (BaseGrid + collision layers), `WalkingPlayer.tscn`, `DialogueBox.tscn`.
2. Create a script extending `WalkingScene`:
   ```gdscript
   extends WalkingScene
   class_name MyScene

   func _ready() -> void:
       super._ready()
       # Add ScreenOverlay if you need fog/darkness/flash effects:
       var overlay := ScreenOverlay.new()
       add_child(overlay)
       # Set up triggers:
       call_deferred("_setup_triggers")

   func _setup_triggers() -> void:
       var trigger := get_node_or_null("MyTrigger") as CinematicTrigger
       if not trigger: return
       var e := DialogueEvent.new()
       var l := DialogueLine.new()
       l.speaker = "NPC"
       l.text = "Hello!"
       e.lines.append(l)
       trigger.events.append(e)
   ```
3. Add `CinematicTrigger` `Node2D` children in the editor, positioned on trigger tiles.
4. Populate their `events` arrays from the scene script (not the Inspector — custom Resources don't embed in `.tscn`).

### Adding a New StoryEvent

1. Create a script extending `StoryEvent`:
   ```gdscript
   class_name ScreenShakeEvent
   extends StoryEvent

   @export var intensity: float = 5.0
   @export var duration: float = 0.3

   func execute(scene_tree: SceneTree) -> void:
       # Find your target node via group
       var camera := scene_tree.get_first_node_in_group("action_camera")
       if not camera: return
       # ... implement the effect ...
       await scene_tree.create_timer(duration).timeout
   ```
2. The event is immediately usable in any `CinematicTrigger.events` array or `GameManager.play_event()` call.

### Adding Per-Character SFX

1. Create a `CharacterSFX` resource (`.tres`) with custom audio file paths per action.
2. Create a `CharacterData` resource (`.tres`) referencing that SFX resource.
3. Assign the `CharacterData` to the character's `character_data` @export in the Inspector.

### Adding New Terrain Types

1. Add the terrain to `TERRAIN_TYPES` dictionary in `scripts/core/terrain_registry.gd`.
2. Update `_classify_tile()` atlas coordinate ranges in the same file.
3. Both the UI (TileInfoPanel) and gameplay systems (BFS pathfinding, combat defense) will automatically pick up the new terrain.
4. For impassable terrain: add a new `TileMapLayer` node and call `_mark_layer_cells_solid()` for it in `tilemap.gd`.
