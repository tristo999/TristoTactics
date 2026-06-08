# TristoTactics — Feature Inventory (DONE / TODO)

A full inventory of what's **built** vs **unbuilt**, for priority-sorting.
Verified against code on 2026-06-07 (branch `tutorial-battle-and-level-semantics`).
Mark/re-order TODO items as you like — the `[ ]` boxes are yours to fill.

---

## ✅ DONE — built and working

### Engine & core systems
- [x] Tile-based battle grid + `AStarGrid2D` pathfinding
- [x] Terrain system (`TerrainRegistry`, walkable / impassable / cover, per-layer rules)
- [x] Text-map pipeline: ASCII `.map` → `MapLoader` → tile layers (`TextMapTilemap`, `@tool` bake buttons)
- [x] Spawn-overlay map format (spawns layer on terrain without erasing tiles)
- [x] Autoload singletons: Constants, EventBus, ComboSystem, TerrainRegistry, AudioManager, PlayerDataManager
- [x] Save / load (PlayerDataManager)
- [x] Pause menu
- [x] Audio manager (SFX, pitched SFX, dialogue type SFX)

### Tactics combat
- [x] Turn order / turn state machine
- [x] Unit movement (reachable-tile highlight, click-to-move)
- [x] Basic attack flow (range, target selection, damage)
- [x] Abilities (data-driven, `CharacterData.abilities`)
- [x] Enemy AI (seek nearest hostile, move + attack)
- [x] 3-team model (player / enemy / ally) via `Constants.is_hostile` + `team_override`
- [x] AI-controlled allies (green recruits) — same AI serves enemies and allies
- [x] Win / lose detection (enemies gone = win; player squad gone = lose; allies excluded)
- [x] Health bars (team-colored: player green, enemy red, ally cyan)
- [x] Victory screen

### Combo / follow-up system (the signature verb) — BUILT
- [x] `ComboSystem` autoload, event-driven, data-driven (drop a FollowUp on `CharacterData.follow_ups`)
- [x] Archer chain strike (trigger: ALLY_ATTACKED_ENEMY)
- [x] Healer mend (trigger: ALLY_DAMAGED)
- [x] Dwarf intercept (pre-hit intercept)
- [x] Once-per-round reaction budget (resets on the char's own turn)

### Walking / exploration scenes
- [x] `WalkingPlayer` — tile-snapped free-roam controller (input buffering, first-step boost)
- [x] Walking NPCs + interactables (space / click to interact)
- [x] Walk-through door triggers (`EventBus.character_moved`)
- [x] Forced walk / cinematic walk (`start_forced_walk`, `cinematic_walk_north`)

### Story / dialogue / cutscene toolkit
- [x] DialogueBox (typed sequences, glitch text, auto-advance, per-char SFX, ellipsis pause)
- [x] GlitchTextDisplay (floating + blocking lines)
- [x] StoryEvent system (~12–15 built event types)
- [x] `CinematicActor` — script-driven cutscene character (code-built directional anims, A*-stepped `walk_to`, `face`/`face_tile`, tint)
- [x] Scripted-cutscene pattern (lock player, disable its camera, drive a `CineCam` with tweens, parallel actor walks)
- [x] TutorialManager + TutorialPrompt (gate action bar one verb at a time)

### Camera
- [x] Battle camera: party-centered start, readable zoom-to-target-width, soft edge clamp
- [x] Screen-space background CanvasLayer (kills the gray void at any zoom/pan)

### Opening content (Beat 1 → Beat 2), end to end
- [x] Void corridor intro (Guardian transmissions, name entry, "Find me")
- [x] Summoning chamber (wake, walk out the door)
- [x] Arrival cutscene (`camp_arrival_scene`) — hero walks out of the wall, meets Vael, led to the yard
- [x] Spar tutorial (`tutorial_spar`) — Vael coaches move → attack → live follow-up, raid interrupts
- [x] Raid battle (`tutorial_battle_scene` on `arena_raid`) — first real battle, off the spar cliffhanger
- [x] Sibling collision maps: `arena_drill` ↔ `arena_raid` (same yard, only the north wall differs)

### Maps & tooling
- [x] `camp_v2.map` (wired tutorial battle map)
- [x] `camp_grounds.map` (52×52 large camp POC) + parametric generator
- [x] `arena_drill.map` / `arena_raid.map` + generator
- [x] Map generators (`gen_camp_grounds.py`, `gen_training_arena.py`)
- [x] PIL preview tools (`preview_camp.py`, `preview_map.py`)
- [x] In-engine render + cell-dump verify workflow (`_screenshot.tscn`, `dump_cells.gd`)

### Process / docs
- [x] Level-authoring in **regions + triggers** (per-level spec at `docs/levels/<map>.md`)
- [x] `map_generation_playbook.md` (legend, tile coords, scaffolding, gotchas, §8 Level Semantics)
- [x] Build-state docs corrected & kept current (ARCHITECTURE, implementation_status, slice_spec)

---

## ⬜ TODO — unbuilt (priority-sort these)

### Identity / depth systems (the "makes it ours" layer)
- [ ] Bonding / relationships system (none built)
- [ ] Expressive player choices (none built)
- [ ] The advancing line — time-as-resource pressure mechanic
- [ ] Authored downed/injury consequences (lose combos/duo abilities + relationship setback)

### Combat extensions
- [ ] Combo passives
- [ ] Duo abilities (two-character combined abilities)
- [ ] More follow-ups beyond archer/dwarf/healer
- [ ] Status effects / buffs / debuffs (verify scope — may be partial)
- [ ] Terrain tactical effects (cover bonus, high ground, hazards)

### Trigger engine
- [x] **The WHEN/THEN trigger ENGINE — v1 BUILT (2026-06-07).** `TriggerEngine` node +
      `TriggerCond`/`TriggerAct` vocabulary + regions/flags + self-test. See `docs/trigger_engine.md`.
      Not yet wired into the live opening scenes (bespoke directors still work; migrate opportunistically).
- [x] `CharacterBase.set_team()` + `TriggerAct.flip_team` — mid-battle team flip is now a one-line action
      (the spar-partners-defect case). Needs a combined drill→raid scene (Beat 3) to use live.
- [ ] Retrofit the spar/raid bespoke directors onto the engine (after Beat 3 proves it)

### Content — Act 1 (Beats 3–10)
- [ ] Campaign mission/level after the raid
- [ ] First bonding moments / companion side-quest hooks
- [ ] Companion roster build-out (Wizard, Knight, Rogue still proposals)
- [ ] Warlock arc (dark-god-pact weapon, break-the-pact outcome)
- [ ] The Choice at the capital (Guardian breaks through)

### Content — Act 2
- [ ] Act 2 framing (starts AT the Guardian, connection un-jammed)
- [ ] Collision payoff — the Act 2 reading of the camp (same place, other side)

### Polish & atmosphere
- [ ] Summoning chamber atmosphere (currently bare)
- [ ] Camp life / ambient NPCs & activity
- [ ] Tighter / final dialogue (current opening dialogue is draft)
- [ ] Global map-framing system (backdrop margin + reusable camera-limit + vignette)

### Art & assets (none coming soon — tints are the accepted stand-in)
- [ ] Real character sprites (every character is the same placeholder, color-tinted)
- [ ] Real environment tiles / themed tilesets
- [ ] UI art pass
- [ ] Music / fuller SFX

### Tech debt / refactors
- [ ] De-duplicate cutscene helper code across scene scripts
- [ ] Move the `TILE_CENTER_OFFSET` +3 hack out (tilemaps at (3,0) is a workaround)
- [ ] Replace hardcoded map coordinates in scripted scenes with named regions
- [ ] Spar enemy-turn wrinkle (auto-end-turn flow is bespoke)
