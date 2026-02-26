# TristoTactics

A turn-based tactical strategy game built with Godot 4.5 (Forward+), inspired by classics like Fire Emblem and Final Fantasy Tactics. Command your units on an isometric tile-based battlefield, outmaneuver enemy AI, and claim victory.

---

## Current Features

### Core Gameplay
- **Turn-based battle system** — Characters act in initiative order (higher speed/initiative goes first, with player tie-breaking priority)
- **Initiative-based turn order** — Each character has an initiative stat that determines when they act each round
- **Move + Attack phases** — On their turn a character can move within their movement range and attack once; turns can be ended early with the Accept key
- **Manhattan-distance attack ranges** — Configurable min/max attack range per character (supports melee and ranged units)
- **Critical hit system** — Configurable per-character crit chance with 2× damage multiplier
- **Damage calculation** — `max(1, attack_power - target.defense)`, modified by crits
- **Healing support** — Characters can be healed, clamped to max HP

### Characters
- **Inheritance-based character system** — `CharacterBase` → `PlayerCharacter` / `EnemyCharacter` with shared stats, movement, and combat logic
- **CharacterData resource** — Data-driven character definitions with stats (HP, MP, attack, defense, magic attack/defense, speed, luck), movement properties (range, speed, fly/swim flags), combat params, ability slots, growth rates for leveling, and elemental resistances (fire, ice, lightning, poison)
- **Per-character SFX overrides** — `CharacterSFX` resource allows unique sounds per character for movement, attack, hit, crit, miss, death, heal, and turn start; falls back to global defaults
- **Player characters** — Player-controlled units that respond to mouse input
- **Enemy AI** — Enemies automatically find the nearest player, pathfind toward them, move into attack range, and attack; fully animated with configurable pause durations between AI actions
- **NPC scaffolding** — `scripts/characters/npcs/` directory ready for future NPC types

### Tilemap & Pathfinding
- **A\* grid pathfinding** — `AStarGrid2D`-based movement with cardinal-only (no diagonal) movement
- **Multi-layer tilemap** — Separate layers for base terrain (`BaseGrid`), walls, objects, movement highlights, and attack highlights
- **Large tile support** — Multi-cell tiles (e.g., 3×3 trees) are correctly marked as solid for pathfinding
- **Occupied tile tracking** — Characters block tiles for pathfinding; automatically refreshed on movement and turn changes
- **Reachable tile calculation** — BFS flood-fill from the active character's position, respecting solid and occupied tiles
- **Movement + attack range highlights** — Blue tiles for reachable movement, yellow tiles for attack range, shown simultaneously during a character's turn
- **Mouse hover highlighting** — Hovered walkable tiles are highlighted; previous highlight is restored on mouse-out
- **Tile info panel** — Hovering a tile displays terrain name, defense bonus, move cost, and terrain type (Grass, Forest, Road, Water, Wall, Sand, Mountain, etc.)
- **Terrain types** — 11 defined terrain types with defense modifiers and move cost values

### UI
- **Main menu** — Start Game, Settings, and Quit buttons with menu background music
- **Pause menu** — Resume, Settings, and Quit; pauses the game tree; opened/closed with Escape
- **Settings menu** — Music volume slider, SFX volume slider, fullscreen toggle, VSync toggle, FPS limit selector (Unlimited / 30 / 60 / 120 / 144)
- **Menu stack system** — `MenuStack` class manages layered menus with universal Escape-to-go-back navigation; menus push/pop with proper show/hide, CanvasLayer isolation, and `back_requested` signal support
- **Base menu class** — `BaseMenu` provides full-rect anchoring, input blocking, and a consistent back-request pattern for all menus
- **Turn label indicator** — Displays "Player Turn" or "Enemy Turn" on the HUD, updated via EventBus
- **Floating damage popups** — Animated numbers that float upward and fade out on hit; critical hits show larger yellow text with "!" suffix
- **Health bars** — Per-character progress bars with team-colored fills (green for player, red for enemy) that shift to yellow/orange at low HP
- **Victory / Defeat screen** — Animated overlay with tween fade-in, scale-up panel, result text, and a Return to Menu button; plays victory or defeat music

### Camera
- **WASD / Arrow key panning** — Smooth camera movement at configurable speed
- **Mouse scroll zoom** — Scroll wheel zoom in/out with configurable min (0.5×) and max (3×) zoom
- **Auto-focus on active character** — Camera smoothly lerps to the current turn's character; manual input cancels auto-focus
- **Snap-to-position** — Instant camera repositioning for scene transitions

### Audio
- **Music system** — Keyed music track registry (menu, battle, victory, defeat) with play/stop controls and same-track deduplication
- **SFX system** — Keyed sound effect registry with pooled `AudioStreamPlayer` nodes (8 simultaneous sounds) for overlap support
- **Per-character SFX** — `GameSFXManager` listens to EventBus signals and routes each action through character-specific overrides before falling back to global defaults
- **Separate Music and SFX buses** — Independent volume control via audio bus layout
- **Persistent settings** — Volume, display, and all preferences saved to `user://settings.cfg` and restored on launch

### Architecture
- **EventBus (autoload)** — Global signal bus for decoupled communication: battle flow, character events (moved, attacked, damaged, healed, died), tile hover, UI popups, and turn indicators
- **Constants (autoload)** — Centralized tile offsets, highlight atlas coords, team names, group names, and cardinal directions
- **AudioManager (autoload)** — Pure audio engine handling music playback and SFX pooling
- **SettingsManager (autoload)** — Owns display settings and persists all user preferences; delegates audio volume to AudioManager
- **GameSFXManager (autoload)** — Bridges game events to sound effects via EventBus signals
- **DamagePopupManager (autoload)** — Spawns floating damage popups in response to EventBus signals
- **GameManager** — Battle flow controller managing turn order, character setup, phase transitions (move → attack → done), AI execution, win/loss detection, and camera focusing
- **BattleInputHandler** — Decoupled mouse click processor that reads tile data and routes move/attack requests to GameManager
- **Sprout Lands tilemap addon** — Integrated tileset plugin for tile art assets

### Project Structure
```
scenes/
├── characters/          # PlayerCharacter.tscn, EnemyCharacter.tscn
├── levels/              # ActionCamera.tscn, test_scene.tscn
├── managers/            # GameManager.tscn
└── ui/                  # MainMenu, PauseMenu, SettingsMenu, DamagePopup,
                         # TileInfoPanel, TurnLabelCanvas, VictoryDefeatScreen

scripts/
├── characters/
│   ├── base/            # CharacterBase, CharacterData, CharacterSFX, PlayerCharacter
│   ├── enemies/         # EnemyCharacter (AI logic)
│   └── npcs/            # (placeholder for future NPCs)
├── core/                # EventBus, Constants, AudioManager, SettingsManager,
│                        # GameSFXManager, MusicManager, MenuStack
├── levels/
│   ├── menus/           # MainMenu script
│   └── tilemaps/        # Tilemap pathfinding & highlighting
├── managers/
│   ├── battle/          # GameManager, BattleInputHandler, CameraControl
│   └── casual/          # (placeholder for non-battle modes)
├── tools/               # generate_placeholder_sfx utility
└── ui/                  # BaseMenu, PauseMenu, SettingsMenu, DamagePopup,
                         # DamagePopupManager, HealthBar, TileInfoPanel,
                         # VictoryDefeatScreen

assets/
├── audio/
│   ├── music/           # Menu, battle, victory, defeat tracks
│   └── sfx/             # UI, movement, combat, status sound effects
├── fonts/
├── sprites/
└── tilesets/
```

## Getting Started

1. **Clone the repository:**
   ```
   git clone https://github.com/tristo999/TristoTactics.git
   ```
2. **Open in Godot 4.5:**
   - Launch Godot 4.5 (Forward+ renderer).
   - Import the project by selecting the `project.godot` file.
3. **Run the game:**
   - Press **F5** or click the Play button.
   - The game starts at the **Main Menu**.

## Controls

| Input | Action |
|---|---|
| **WASD / Arrow Keys** | Pan the camera |
| **Mouse Scroll** | Zoom in / out |
| **Left Click (tile)** | Move the selected character |
| **Left Click (enemy)** | Attack an enemy in range |
| **Enter / Space** | End turn early |
| **Escape** | Open / close pause menu; navigate back in menus |

## Tech Stack

- **Engine:** Godot 4.5 (Forward+)
- **Language:** GDScript
- **Renderer:** Forward+ with pixel-art texture filtering (nearest neighbor)
- **Addons:** Sprout Lands Tilemap, Godot Git Plugin
- **Resolution:** Canvas-items stretch mode with expand aspect ratio

## Contributing

Pull requests and suggestions are welcome! Please open an issue or PR for discussion.

## License

This project is licensed under the MIT License.
