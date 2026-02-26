# TristoTactics

A turn-based tactics game inspired by Fire Emblem and Final Fantasy Tactics, built with **Godot 4.5** and pixel art.

<!-- TODO: Add a screenshot or GIF here -->

---

## Features

- **Initiative-based turns** — Characters act in speed order; players break ties
- **Move + Attack each turn** — Move within your range, then strike an enemy (or end turn early)
- **Ranged & melee units** — Archers attack from 1–4 tiles away; warriors fight up close
- **Critical hits** — Per-character crit chance with 2× damage
- **Attack cutscene** — Full-screen cinematic overlay with lunge, shake, and damage animations
- **Enemy AI** — Enemies pathfind toward the nearest player, position at attack range, and strike
- **Terrain variety** — Forests (+2 DEF), mountains (+3 DEF), roads (-1 DEF), water/walls (impassable), and more
- **Tile info on hover** — See terrain name, defense bonus, and move cost
- **Per-character SFX** — Give any unit custom sounds for attacks, hits, death, etc.
- **Settings** — Music/SFX volume, fullscreen, VSync, FPS limit — all saved automatically
- **2× speed mode** — Toggle button to double game speed
- **Victory & defeat screens** — Animated result overlay with music

---

## Controls

| Input | Action |
|---|---|
| **Left Click (tile)** | Move the selected character |
| **Left Click (enemy)** | Attack an enemy in range |
| **WASD / Arrow Keys** | Pan the camera |
| **Mouse Scroll** | Zoom in / out |
| **Space / Enter** | End your turn |
| **Escape** | Pause / navigate back |

---

## Getting Started

1. **Clone the repository:**
   ```
   git clone https://github.com/tristo999/TristoTactics.git
   ```
2. **Open in Godot 4.5** (Forward+ renderer) — import via `project.godot`
3. **Press F5** to play. The game starts at the Main Menu.

---

## Current Character Roster

| Unit | Team | HP | ATK | DEF | Move | Range | Special |
|---|---|---|---|---|---|---|---|
| Player (base) | Player | 25 | 10 | 5 | 5 | 1 | — |
| Archer | Player | 18 | 8 | 3 | 3 | 1–4 | High initiative, ranged |
| Goblin | Enemy | 15 | 7 | 3 | 6 | 1 | Fast, aggressive, 10% crit |

---

## Terrain Types

| Terrain | Defense | Move Cost | Notes |
|---|---|---|---|
| Grass | +0 | 1 | Default |
| Forest | +2 | 2 | Good cover |
| Mountain | +3 | 3 | Strong defense |
| Road / Dirt | -1 / +0 | 1 | Fast travel |
| Sand | -1 | 2 | Slow, exposed |
| Bridge | +0 | 1 | Crosses water |
| Water / Wall / Object | — | — | Impassable |

---

## Tech Stack

| | |
|---|---|
| **Engine** | Godot 4.5 (Forward+) |
| **Language** | GDScript |
| **Art style** | Pixel art (16×16 tiles, nearest-neighbor filtering) |
| **Addons** | Sprout Lands Tilemap, Godot Git Plugin |

---

## Project Structure (Overview)

```
scripts/
├── core/           # Autoload singletons (EventBus, Audio, Settings)
├── characters/     # CharacterBase hierarchy + AI
├── managers/       # GameManager, input handling, camera
├── levels/         # Level base class, tilemap + pathfinding
├── ui/             # HUD panels, menus, overlays
└── tools/          # Editor utilities (SFX generator)
```

For full technical documentation (architecture, signals, function signatures, file-by-file reference), see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## License

This project is licensed under the MIT License.
