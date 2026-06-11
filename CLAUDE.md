# CLAUDE.md — agent routing guide

TristoTactics: a turn-based tactics RPG (Godot **4.6**, Forward+, GDScript; solo dev).
You fight a war twice — Act 1 under a lie, Act 2 from the other side.

**This file routes; it does not summarize.** Read the linked doc for the real content.
It is never canon (see *Story decisions*).

## Repo layout (for code-only tasks)

- `scripts/` — GDScript. `core/` (autoloads), `characters/` (`base/CharacterBase`,
  `enemies/`, `walking/`), `managers/battle/` (`game_manager.gd` FSM, `combo_system.gd`),
  `story/` (StoryEvents, `dialogue_box.gd`, `cine_fx.gd`), `triggers/` (`TriggerEngine`),
  `abilities/`, `levels/`, `ui/`, `menus/`.
- `scenes/` — `.tscn`. `levels/`, `characters/`, `ui/`, `menus/`, `dev/` (self-tests).
  Main scene: `scenes/menus/SplashScreen.tscn`.
- `data/` — `maps/*.map` (ASCII maps), `characters/*.tres`, `abilities/*.tres`.
- `dialogue/` — authored `DialogueSequence` `.tres`. `shaders/`, `tools/` — support.
- **Autoloads (9):** EventBus, Constants, TerrainRegistry, AudioManager, SettingsManager,
  GameSFXManager, AttackAnimationOverlay, PlayerDataManager, ComboSystem.
- **Architecture reference:** `ARCHITECTURE.md` (systems, patterns, decision ladders).
- **Verify headless:** run `scenes/dev/*_selftest.tscn` (trigger, cinefx, combat-anim,
  combo-reaction) against the Godot 4.6 binary; headless can't drive input-gated scenes.

## Doc routing (task → doc)

| Your task touches… | Read |
|---|---|
| Orientation / what is this / why it works | `docs/overview.md` |
| World, lore, magic, factions, the Throne/Guardian | `docs/bible_01_world.md` |
| The hero + companions / cast / character arcs | `docs/bible_02_cast.md` |
| Act 1 plot (the loyal blade) | `docs/bible_03_act1.md` |
| Act 2 plot + the open-threads Manifest | `docs/bible_04_act2.md` |
| A scene that happens twice (Act1↔Act2 "collisions") | `docs/collision_ledger.md` |
| Beat ordering / where a beat sits in sequence | `docs/story_beats_plan.md` |
| The opening sequence (writer/scene spec) | `docs/opening_scene_report.md` |
| Mechanics: combat, death/stakes, relationships, combos, time powers, advancing line | `docs/systems_design.md` |
| Vertical-slice build target (Opening→bridge) | `docs/slice_spec.md` |
| Authoring dialogue (lines, sequences, CineFx) | `docs/dialogue_system.md` |
| Triggers, cutscenes, scripted beats (WHEN/THEN) | `docs/trigger_engine.md` |
| Map `.map` text format | `docs/text_map_system.md` |
| Building a new battle map (legend, gotchas, checklist) | `docs/map_generation_playbook.md` |
| Map framing / void / boundaries | `docs/map_boundaries_framing.md` |
| Map design philosophy / iteration process | `docs/map_design_process.md` |
| A specific level's regions/triggers/intent | `docs/levels/<map>.md` |
| Build status — what's coded vs stubbed (per beat/system) | `docs/implementation_status.md` |
| DONE/TODO feature list (priority sorting) | `docs/feature_inventory.md` |
| Which docs are canon/working/archived | `TRIAGE_REPORT.md` (repo root) |

When in doubt, start at `docs/overview.md` (it carries the full document map).

## Do NOT read (stale / irrelevant)

- `docs/archive/` — historical snapshots (session logs, status updates, changelogs);
  superseded by git history + `implementation_status.md`.
- `.claude/worktrees/` — stale agent worktrees on old commits. Never a source of truth.
- `addons/`, `assets/` — third-party plugins, art, tilesets, license/readme files.
- `docs/levels/camp_v2.md` — superseded level spec (map replaced by `arena_drill`/`arena_raid`).

## Story decisions

Narrative decisions live in docs/bible_01 through bible_04. They are Tristan's decisions,
held at whatever firmness he holds them — not rules for agents to enforce or revise. If
your task touches story content in any way — even one line of dialogue — read the relevant
bible part first. Topics that are especially easy to get wrong: the hero's voice, the
summoning story, the Guardian's status, what the time loop can and can't change, the lost
companion's fate, and any scene appearing in both acts. If your task seems to require
deviating from the bible, ask — never invent or "fix" lore. This file is never canon; if
anything in it conflicts with the bible, the bible wins.
