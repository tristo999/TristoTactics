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
- [Tilemap & Pathfinding](#tilemap--pathfinding)
  - [Tilemap Manager](#tilemap-manager)
  - [AStarGrid2D Pathfinding](#astargrid2d-pathfinding)
  - [BFS Reachability](#bfs-reachability)
  - [HighlightRenderer](#highlightrenderer)
  - [Tile Layers](#tile-layers)
- [UI Systems](#ui-systems)
  - [Attack Animation Overlay](#attack-animation-overlay)
  - [Character Info Panel](#character-info-panel)
  - [Tile Info Panel](#tile-info-panel)
  - [Health Bars](#health-bars)
  - [Speed Toggle Button](#speed-toggle-button)
  - [Victory/Defeat Screen](#victorydefeat-screen)
- [Menu System](#menu-system)
  - [MenuStack](#menustack)
  - [Main Menu](#main-menu)
  - [Pause Menu](#pause-menu)
  - [Settings Menu](#settings-menu)
- [Camera System](#camera-system)
- [Story Events](#story-events)
  - [StoryEvent](#storyevent)
  - [DialogueEvent](#dialogueevent)
  - [DialogueBox](#dialoguebox)
  - [DialogueLine](#dialogueline)
- [Level System](#level-system)
- [Developer Tools](#developer-tools)
- [File Structure](#file-structure)
- [Input Mapping](#input-mapping)
- [Signal Reference](#signal-reference)
- [How to Add Content](#how-to-add-content)

---

## Project Setup

| Setting | Value |
|---|---|
| Engine | Godot 4.5, Forward+ renderer |
| Language | GDScript |
| Main Scene | `res://scenes/ui/MainMenu.tscn` |
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
│                     CHARACTER HIERARCHY                              │
│  CharacterBase → PlayerCharacter → ArcherCharacter                  │
│  CharacterBase → EnemyCharacter  → GoblinCharacter                  │
└─────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────┐
│                           UI LAYER                                  │
│  CharacterInfoPanel · TileInfoPanel · HealthBar                     │
│  AttackAnimationOverlay · VictoryDefeatScreen · SpeedToggleButton   │
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
| `PLAYER_SELECTING_MOVE` | Movement tiles highlighted — click destination or use menu |
| `PLAYER_MOVING` | Character is animating along a path |
| `PLAYER_SELECTING_ATTACK` | Attack range highlighted — click target or use menu |
| `PLAYER_ATTACKING` | Attack animation is playing |
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
| `request_move` | `(character: CharacterBase, target_tile: Vector2i) → bool` | Transitions `PLAYER_SELECTING_MOVE → PLAYER_MOVING` |
| `request_attack` | `(character: CharacterBase, target: CharacterBase) → bool` | Transitions `PLAYER_SELECTING_ATTACK → PLAYER_ATTACKING`; blocking `await` |
| `play_event` | `(event: StoryEvent) → void` | Awaitable — pauses gameplay (`PLAYER_WAITING`), runs event, restores state |
| `is_enemy_turn` | `() → bool` | Checks enemy-related states |

**State transitions:**
```
INACTIVE → PLAYER_WAITING (intro_event, if set)
PLAYER_WAITING → restored state (event finishes)
INACTIVE/PLAYER_WAITING → PLAYER_SELECTING_MOVE (first turn / best state)
PLAYER_SELECTING_MOVE → PLAYER_MOVING (request_move)
PLAYER_SELECTING_MOVE → PLAYER_SELECTING_ATTACK (enter_attack_selection)
PLAYER_SELECTING_ATTACK → PLAYER_SELECTING_MOVE (cancel_action)
PLAYER_MOVING → best state (character_movement_finished)
PLAYER_ATTACKING → best state (attack complete)
Any state → PLAYER_WAITING (play_event) → restored state
PLAYER_SELECTING_* → ENEMY_TURN_START (advance to enemy)
ENEMY_TURN_START → ENEMY_SELECTING_MOVE → ENEMY_MOVING → ENEMY_SELECTING_ATTACK → ENEMY_ATTACKING
ENEMY_ATTACKING → PLAYER_SELECTING_MOVE (advance to player)
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

Processes left mouse clicks during player turns:
1. **Guard:** Ignores all input unless `game_manager.state == BattleState.PLAYER_IDLE`
2. **Attack priority:** If clicking an enemy character in attack range → `game_manager.request_attack()`
3. **Movement:** If clicking a tile in `tilemap.cached_reachable_tiles` → `game_manager.request_move()`

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

**Turn ending:** Player turns end ONLY when `ui_accept` is pressed. No auto-end after moving or attacking.

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

**Script:** `scripts/levels/menus/main_menu.gd` | **Extends:** `Control`

Creates its own `MenuStack`. Start → `change_scene_to_file("res://scenes/levels/test_scene.tscn")`. Settings hides main VBox, pushes `SettingsMenu`. Quit → `get_tree().quit()`. Plays `"menu"` music.

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

**TestScene** (`scripts/levels/test_scene.gd`) | **Extends:** `BaseLevel` — sets `music_key = "battle"`. Creates a `DialogueEvent` with intro dialogue lines and assigns it to `GameManager.intro_event`.

**PauseMenuHandler** (`scripts/levels/pause_menu_handler.gd`) | **Extends:** `Node` — creates `MenuStack`, handles Escape key, pauses/unpauses.

---

## Story Events

General-purpose system for events that pause gameplay — dialogue, cutscenes, environment changes, etc. Any script can trigger events at any time via `GameManager.play_event()` or the decoupled `EventBus.story_event_triggered` signal.

**Trigger patterns:**
```gdscript
# Direct (when you have a GameManager reference):
await game_manager.play_event(my_event)

# Decoupled (from anywhere — GameManager listens automatically):
EventBus.story_event_triggered.emit(my_event)
await my_event.completed  # optional — wait for it to finish
```

### StoryEvent

**Script:** `scripts/story/story_event.gd` | **class_name:** `StoryEvent` | **Extends:** `Resource`

Base class for all gameplay-pausing events. Subclass and override `execute()`.

**Signal:** `completed` — emitted by `GameManager.play_event()` after `execute()` returns.

**Virtual method:** `execute(scene_tree: SceneTree) -> void` — override with event logic. Use `await` for async operations (dialogue playback, tweens, timers).

### DialogueEvent

**Script:** `scripts/story/dialogue_event.gd` | **class_name:** `DialogueEvent` | **Extends:** `StoryEvent`

Plays a sequence of dialogue lines through the `DialogueBox`.

**@export:** `lines: Array[DialogueLine]`

**execute():** Finds `dialogue_box` via group lookup, calls `await dialogue_box.play_sequence(lines)`.

### DialogueBox

**Script:** `scripts/story/dialogue_box.gd` | **Extends:** `CanvasLayer`

Full-width bottom bar UI for dialogue sequences. Added to group `"dialogue_box"`. Layer 90, programmatic UI build.

**Layout:** `PanelContainer` (anchored bottom, full width, 140px tall) → `HBoxContainer` → portrait panel (80×80 `TextureRect` placeholder for character headshot) + `VBoxContainer` (speaker `Label` in gold, `RichTextLabel` body, advance indicator).

**Typewriter effect:** 30 chars/sec via `_process()`. Click / Space / Enter: first press instant-fills current line, second press advances to next line.

**Signal:** `sequence_finished` — emitted when all lines have been advanced through.

**Key method:** `play_sequence(lines: Array[DialogueLine]) -> void` — awaitable. Shows the box with a fade-in tween, plays all lines, waits for player to advance through each.

### DialogueLine

**Script:** `scripts/story/dialogue_line.gd` | **class_name:** `DialogueLine` | **Extends:** `Resource`

Data resource for one line of dialogue.

**@export:** `speaker: String`, `text: String`, `portrait: Texture2D` (optional character headshot).

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
│   └── enemies/
│       ├── enemy_character.gd    # Enemy base with AI (EnemyCharacter)
│       └── goblin_character.gd   # Fast melee enemy (GoblinCharacter)
├── managers/
│   └── battle/
│       ├── game_manager.gd        # Battle orchestrator
│       ├── battle_input_handler.gd # Player mouse click handling
│       └── camera_control.gd      # Camera follow + zoom
├── levels/
│   ├── base_level.gd           # Base level class
│   ├── test_scene.gd           # Test battle level
│   ├── pause_menu_handler.gd   # In-game pause system
│   ├── menus/
│   │   └── main_menu.gd        # Main menu screen
│   └── tilemaps/
│       ├── tilemap.gd          # Tilemap manager (A*, BFS, highlights)
│       └── highlight_renderer.gd # Custom _draw() tile highlights
├── ui/
│   ├── attack_animation_overlay.gd # Blocking attack cutscene (autoload)
│   ├── base_menu.gd               # Base menu class (BaseMenu)
│   ├── pause_menu.gd              # Pause menu
│   ├── settings_menu.gd           # Settings menu
│   ├── health_bar.gd              # Per-character HP bar (HealthBar)
│   ├── character_info_panel.gd    # Current character stats HUD
│   ├── tile_info_panel.gd         # Tile hover tooltip
│   ├── speed_toggle_button.gd     # 1×/2× speed toggle
│   └── victory_defeat_screen.gd   # End-of-battle screen
├── story/
│   ├── story_event.gd          # Base gameplay-pausing event (StoryEvent)
│   ├── dialogue_event.gd       # Dialogue sequence event (DialogueEvent)
│   ├── dialogue_box.gd         # Full-width dialogue UI (CanvasLayer)
│   └── dialogue_line.gd        # Single dialogue line resource (DialogueLine)
└── tools/
    └── generate_placeholder_sfx.gd # Procedural SFX generator (@tool)

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
| `ui_left` | Arrow Left, A, DPad Left | Camera pan / menu navigation |
| `ui_right` | Arrow Right, D, DPad Right | Camera pan / menu navigation |
| `ui_up` | Arrow Up, W, DPad Up | Camera pan / menu navigation |
| `ui_down` | Arrow Down, S, DPad Down | Camera pan / menu navigation |
| `ui_accept` | Space, Enter | End player turn |
| `ui_cancel` | Escape | Open pause menu / go back |
| `ui_zoom_in` | Mouse Wheel Up | Camera zoom in |
| `ui_zoom_out` | Mouse Wheel Down | Camera zoom out |
| Left Click | Mouse Button 1 | Select tile / attack target / move |

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

### Adding Per-Character SFX

1. Create a `CharacterSFX` resource (`.tres`) with custom audio file paths per action.
2. Create a `CharacterData` resource (`.tres`) referencing that SFX resource.
3. Assign the `CharacterData` to the character's `character_data` @export in the Inspector.

### Adding New Terrain Types

1. Add the terrain to `TERRAIN_TYPES` dictionary in `scripts/core/terrain_registry.gd`.
2. Update `_classify_tile()` atlas coordinate ranges in the same file.
3. Both the UI (TileInfoPanel) and gameplay systems (BFS pathfinding, combat defense) will automatically pick up the new terrain.
4. For impassable terrain: add a new `TileMapLayer` node and call `_mark_layer_cells_solid()` for it in `tilemap.gd`.
