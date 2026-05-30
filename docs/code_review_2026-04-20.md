# TristoTactics — Code Review, Functional & Story Documentation, Next Steps

*Review date: 2026-04-20 · Branch: `IntroScene1` (1 commit ahead of remote) · Engine: Godot 4.6 Forward+ · Language: GDScript*

---

## 1. Snapshot

TristoTactics is a turn-based tactical RPG in the tradition of Fire Emblem and Final Fantasy Tactics, built in Godot 4.6 with pixel art (16×16 tiles, 80×80 character sprites) using the Sprout Lands tileset. The codebase is roughly 7,500 lines of GDScript across ~75 scripts, with an unusually thorough `ARCHITECTURE.md` (32k words) that reads almost as a design bible.

The project is at a mid-stage: the core battle loop works end-to-end (movement, attacks, AI, crits, terrain defense, victory/defeat), a free-roam "walking" mode exists for narrative beats, and a compositional story-event system (dialogue, fog, darkness, flashes, name entry, glitch text) drives a scripted opening cinematic. What's still missing is content — dialogue is authored for one beat, abilities are scaffolded with only one concrete implementation, and the roster has three live units out of a planned six-plus.

Current active work (as of the `IntroScene1` branch) is refinement of the opening corridor scene and the summoning room that follows it.

## 2. Tech Stack & Project Layout

Godot 4.6 Forward+, GDScript only, no external packages. Eight autoload singletons wire up cross-cutting concerns: `EventBus`, `Constants`, `TerrainRegistry`, `AudioManager`, `SettingsManager`, `GameSFXManager`, `AttackAnimationOverlay`, and `PlayerDataManager`. Main scene is `res://scenes/menus/SplashScreen.tscn`. The `addons/` folder contains the Sprout Lands tilemap pack, the Godot Git plugin, and GodotSteam (scaffolded but dormant — `steam_appid.txt` is 0 and no scene calls into it yet).

Scripts are organized by concern rather than by feature, which works well at this size: `scripts/core` for autoloads, `scripts/characters` for unit classes (split into `base/`, `enemies/`, `walking/`), `scripts/managers` for battle/data/steam/tutorial managers, `scripts/levels` for scene scripts including the tilemap (`tilemap.gd` holds the A*/BFS/highlight logic), `scripts/story` for story events and dialogue, `scripts/ui` for HUD and menus, `scripts/abilities` for the ability framework, and `scripts/tools` for editor-time helpers.

## 3. Architecture Review

The architecture is the strongest part of the project. Four patterns carry most of the weight and are applied consistently.

**EventBus.** `scripts/core/event_bus.gd` is a pure signal node — no logic, just ~16 signal declarations (`battle_started`, `turn_started`, `character_moved`, `character_attacked`, `character_died`, `tile_hovered`, `story_event_triggered`, and so on). Systems emit to the bus rather than hold references to each other, and the discipline is holding: I couldn't find a case of two subsystems reaching directly into each other's state. This is the single biggest reason the codebase still feels navigable at ~7,500 lines.

**GameManager state machine.** The battle flow is an explicit enum-driven state machine (`INACTIVE`, `PLAYER_IDLE`, `PLAYER_MOVING`, `PLAYER_ACTING`, `PLAYER_WAITING`, `ENEMY_TURN_START`, `ENEMY_SELECTING_MOVE`, …). Transitions are centralized, states are readable, and it would be straightforward to add new states (e.g. `ABILITY_TARGETING`) without ripple effects. The initiative tie-break is a nice touch:

```gdscript
func _compare_initiative(a: CharacterBase, b: CharacterBase) -> bool:
    if a.initiative != b.initiative:
        return a.initiative > b.initiative
    var a_is_player := a.team == Constants.TEAM_PLAYER
    var b_is_player := b.team == Constants.TEAM_ENEMY
    if a_is_player != b_is_player:
        return a_is_player
    return a.name < b.name
```

**Resource-driven data.** Characters and abilities are `.tres` files (`data/characters/hero.tres`, `data/abilities/heal.tres`). `CharacterBase._apply_character_data()` copies stats, duplicates ability instances so each unit gets its own use counters, and builds sprite frames from idle/walk textures. Adding a new character is a resource edit, not a code change — this will pay off heavily as the roster grows.

**Shared registry.** `TerrainRegistry` is the single source of truth for terrain data (defense bonus, move cost, classification). It's consumed by both gameplay (BFS, damage calc) and UI (`TileInfoPanel`), which prevents the classic drift where the hover tooltip says "+2 defense" but combat uses a different number.

The two supporting pieces worth calling out: the `MenuStack` (a tidy 116-line LIFO for menu navigation) and the story event pipeline, which composes narrative from small typed classes (`DialogueEvent`, `FlashEvent`, `FogEvent`, `GlitchTextEvent`, `CallbackEvent`, `WaitEvent`, `NameEntryEvent`) — this is the right pattern for an RPG and already paying off in the opening corridor.

## 4. Code Quality

Naming is consistent (`_private_vars`, `public_functions`, `CONSTANTS`) and most signatures are typed. Guard checks are in place at the usual failure points (`if not tilemap`, `if not character_data`, `if not _sprite`), and `push_warning()` is used for recoverable failures rather than bare exceptions. Docstrings appear on the complex functions that need them. There are no `TODO`/`FIXME`/`HACK` markers anywhere in the codebase, which can be read two ways: either the code is genuinely clean, or contributors skip marking incomplete work. I'd lean toward the former based on what I read, but it's worth establishing a convention so that known-incomplete areas are discoverable.

Error handling, duplication, and dead code are all in good shape. I didn't find commented-out functions, and common patterns (data application, terrain lookups, signal emission) are extracted rather than copy-pasted.

The real weaknesses are in three specific places.

**Large files.** `scripts/levels/opening_corridor_scene.gd` is 915 lines and handles phase logic, path generation, light management, beacon, title card, name entry, and every narrative sequence in the opening. The scene has clearly been iterated on heavily and it shows — the most recent commit message is *"Been struggling with the opening sequence that barely matters but it's the first thing people will see"*. This is the file most in need of decomposition: a phase/timeline resource, or extracting each phase into its own node, would make it tractable again. `dialogue_box.gd` (272 lines) and `attack_animation_overlay.gd` (249 lines) are borderline — acceptable for now, but `DialogueBox`'s typewriter logic is the obvious thing to pull out into its own helper when the next feature gets added.

**No tests.** There's no unit coverage for any of the logic that would genuinely benefit from it: A* with mixed terrain, BFS reachability over ally/enemy occupancy rules, the damage formula `max(1, attack - (defense + terrain_def))` with the 2× crit multiplier, initiative tie-breaking. These are all pure functions of their inputs and all exactly the kind of thing that breaks silently during refactors. Godot has GUT and WAT available; picking either and wiring up CI for these four systems would be a one-afternoon job with high leverage.

**Magic numbers in narrative timing.** The opening corridor has ~20 tunable durations (`fade_in_duration = 3.5`, `void_hold_duration = 1.5`, `start_light_radius = 0.07`, …). They're all `@export`, which is the right instinct for authoring flexibility, but at this volume they argue for a timeline/beat resource instead — something an editor or writer could tune without scrolling through 900 lines of scene script.

## 5. Functional Documentation

### Battle mode

Initiative-based turn order with player tie-break. A character takes one move (pathfinding over terrain-weighted A\*, with BFS-based reachability highlights that respect terrain costs, pass through allies but not enemies, and can't terminate on allied tiles) followed by one attack within range. Ranged units (Archer, 1–4 tiles) and melee units (Hero, Goblin, 1 tile) share the same combat pipeline. Damage is `max(1, attack - (defense + terrain_def))`, doubled on crits. Terrain defense comes from `TerrainRegistry` (grass +0, forest +2, mountain +3, water/walls impassable). Enemy AI pathfinds to the nearest player, positions within attack range, and attacks — no threat modeling, no ability use, no coordination yet. Attacks play through a full-screen `AttackAnimationOverlay` with lunge, shake, and a damage label; health bars animate with green→yellow→red gradients. Victory/defeat screens swap the music track and return to the menu.

### Walking / exploration mode

Free-roam tile-snapped movement on WASD, with input buffering so keystrokes aren't dropped during tweens and a first-step speed boost to hide perceived input lag. NPCs respond to Space or left-click. Tile-based `CinematicTrigger` nodes fire arrays of `StoryEvent` objects when the player steps on them, which drives the scripted opening. Screen effects available to story events include a darkness overlay with a soft light circle (`darkness_overlay.gdshader`), procedural FBM fog (`fog_overlay.gdshader`), glitch text overlays, flash events, and an in-scene name entry prompt. An Act-2 `bleed_overlay.gdshader` exists as a placeholder for a later desaturated palette.

### UI and systems

Main menu with splash screen, in-battle pause menu, settings (volume, fullscreen, VSync, FPS cap), character info panel (stats, move-left, attack-left), tile info panel (terrain/defense/move-cost on hover), victory/defeat screens, a 1×/2× speed toggle, and tutorial prompts. Audio is an 8-voice SFX pool with per-character overrides (move, attack, hit, crit, miss, death, heal, turn-start) plus a global fallback, and volumes are persisted in dB. Saves live in `user://player_data.json` and cover the player's chosen name, a checkpoint scene path for Continue, a story-flags dictionary, and a party array (skeleton, not yet populated). The ability framework has a base `Ability` class with per-instance use counters, one concrete subclass (`HealAbility`), and no in-battle ability menu yet.

### Content inventory

Three live units: Hero (HP 25, ATK 10, DEF 5, move 5, melee), Archer (HP 18, ATK 8, DEF 3, move 3, range 1–4, init 12), Goblin (HP 15, ATK 7, DEF 3, move 6, melee, 10% crit). A `healer.tres` exists in data but isn't placed in any scene. Scenes: `SplashScreen`, `MainMenu`, `OpeningCorridorScene` (active refinement), `SummoningRoomScene` (partial), a tutorial battle scene, and a victory/defeat flow.

## 6. Story & Narrative

The premise, pieced together from `docs/story_map.md` and the dialogue resources: a silent protagonist (player-named) is summoned into a kingdom being conquered by the Authority, an empire that's attempting to absorb the power of an interdimensional protector called the Guardian. The Guardian is being held by the Authority and can only speak to the hero through fragmented, glitched transmissions — no complete sentence is meant to land until late in Act 1. Over the course of the game the hero gathers six companions (Archer, Healer, Wizard, Tank, Knight, Rogue) from different regions of the Kingdom, each shaped in some way by the Authority's campaign. Much of the specific lore — companion names, regional detail, the Authority's leadership structure, the Guardian's true form — is still marked TBD in `story_map.md`.

The actual scripted content sits entirely at Beat 0. The opening corridor scene takes the player from a black void, through Guardian whispers (`dialogue/beat0/void_transmissions.tres`) and a corridor of light fragments, into a name-entry prompt (`dialogue/beat0/name_sequence.tres`), and out through a white flash into the Summoning Room. The Summoning Room has a fade-in and a door trigger wired up, but the transition to the tutorial battle and the camp flow beyond it is not yet connected. Beats 2+ exist only as outline prose in `story_map.md`.

Dialogue is authored as `DialogueSequence` resources — named arrays of `DialogueLine` objects with fields for speaker, text, portrait, glitched flag (per-character flicker), auto-advance delay, chars-per-second, and type-sfx key. The format is solid. The bottleneck is authoring volume — two sequences exist, and Act 1 will need roughly 20+ more to cover camp conversations, per-battle banter, and companion recruitment.

## 7. What's Incomplete

The opening corridor is the most visible in-progress work — the phase transitions, dialogue timing, light/darkness curves, and name-entry flow are being tuned on the current branch. The summoning room fades in and traps the player at a door, but what happens after the door isn't hooked up. The tutorial scene is a battle setup without actual tutorial teaching overlaid. Multi-wave encounters, bosses, difficulty scaling, and an XP/leveling system are all future work (the `party` array in PlayerDataManager is the hook for the latter). The ability system has the framework but needs 4–5 more concrete subclasses (Fireball, Buff, Debuff, AoE, Stun) and an in-battle ability-selection UI before it's usable. Enemy AI needs threat assessment, ally-healing behavior, ability usage, and coordination before boss fights will feel real. The Healer unit data exists but the unit isn't placed, and Wizard/Tank/Knight/Rogue are still narrative outline only. SFX beyond the music tracks are mostly placeholders (there's a `generate_placeholder_sfx.gd` tool), and there are no voice lines. The Steam integration is scaffolded but not active. Particle systems (`corridor_particles.gd`, `kingdom_fragment.gd`) are stubbed. Finally, `build/testbuild.exe` dates to November 2025 and should be rebuilt before any external sharing.

## 8. Recommended Next Steps

**This sprint.** Close out the opening corridor work on `IntroScene1` — lock the phase transitions, test name-entry end-to-end, and commit the `dialogue/` directory and `dialogue_sequence.gd` that are currently untracked. Wire the Summoning Room door trigger to the tutorial battle scene, verifying that `PlayerDataManager.set_checkpoint()` actually round-trips through the Continue flow. Rebuild the executable.

**Next one to two weeks.** Add unit tests for the four high-leverage pure-logic systems: A* with terrain, BFS reachability with ally/enemy occupancy, damage calculation with crits and terrain defense, and initiative tie-breaking. Pick GUT or WAT and wire it into CI. In parallel, refactor `opening_corridor_scene.gd` — extract each phase into a child node or pull the narrative timing into a timeline resource so tuning doesn't require editing a 915-line file.

**Next month.** Content push. Author the Act 1 dialogue sequences (camp scenes, per-battle banter, companion recruitment, NPC interactions — roughly 20+ `.tres` files), implement the Healer's placement and recruitment flow, add 4–5 concrete abilities with an in-battle selection UI, and design two or three more battle maps beyond the tutorial. Expand enemy AI with threat assessment and ability use so the first boss fight has real texture. Record real SFX to replace placeholders.

**Technical debt to schedule, not ignore.** Decide on Steam — finish the integration (leaderboards, achievements, cloud saves) or remove the stub so it's not misleading. Establish a TODO/FIXME convention so known-incomplete work is discoverable via grep. Consider extracting the typewriter from `DialogueBox` next time that file needs to change. Move the opening corridor's `@export` timing constants into a timeline resource.

---

## Summary

The foundation is strong: clean signal-bus architecture, a readable battle state machine, resource-driven data, and a compositional story system that's already driving a scripted cinematic. Code quality is good — consistent naming, type hints, guard checks, thorough architecture docs, no visible rot. The gaps are the expected ones for a project at this stage: content volume (dialogue, abilities, enemies, companions), test coverage on the pure-logic systems, and decomposition of the one file (`opening_corridor_scene.gd`) that has absorbed most of the recent iteration. The shortest path to a playable Act 1 vertical slice is closing out the opening corridor, wiring the summoning-room-to-tutorial transition, authoring the camp dialogue, and shipping two or three more abilities with a selection UI.
