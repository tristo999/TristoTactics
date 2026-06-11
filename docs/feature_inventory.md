# TristoTactics — Feature Inventory (DONE / TODO)

A full inventory of what's **built** vs **unbuilt**, plus the agreed roadmap.
Verified against code on 2026-06-07; roadmap added 2026-06-10
(branch `tutorial-battle-and-level-semantics`).

---

## 🗺️ ROADMAP (priority-sorted 2026-06; ruling: maximize unlocks/proofs, art-blocked track quarantined)

The frame: **everything ahead = finish the vertical slice** (`slice_spec.md`) — the slice
is where every remaining identity system gets built.

| Phase | What | Why / proves |
|---|---|---|
| ~~0~~ | ~~Trigger engine~~ | ✅ DONE (the multiplier) |
| **1** | **Beat 3 mission + Bonding v1** — `docs/levels/outskirts_road.md` (awaiting keep/kills) | engine's first real content; bonding born in use, not in the abstract |
| 2 | Combat depth riding Beat 3: **downed consequences** (lose follow-ups + bond setback) · **first duo ability** (bond-threshold gated; Elena+Borin) + 1–2 follow-ups · **team-flip live** | bonding matters both directions; first bond *spend*; spine item #4 |
| 3 | **Beat 4: Shadowed Figures** — the Row 2 plant (garbled-line cue) | content on the engine; glitch/tint systems already exist |
| 4 | **Expressive choices v1 + the CAMP HUB** — the persistent mobile camp (settled 2026-06-10: one camp, re-pitched along the march, the between-missions social home; Act 2 mirrors it) — companion talks, bond bumps, ≥1 complicity beat | the third identity system, in its permanent venue (one scene serves the whole act). GATE: choice form (wordless vs worded) |
| 5 | **Beat 5: THE BRIDGE** — territory-boundary map, built Act-2-reusable | the slice capstone — ends on the stare across the gap |
| 6 | **Slice assembly + pacing pass** (chain, difficulty, swirl shader, checkpoints) | a showable vision build → recruits an artist → unblocks the art track |

**Parallel/deferred:** advancing line = *taste only* (real clock parked on the Act-1
mechanics question) · story-brain track (Row 4, cast keep/kills, Beat 7) anytime ·
tech debt when it bites · **art quarantined**.

**Decision gates (Tristan's):** ① Beat 3 keep/kills (now) · ② expressive-choice form
(before Phase 4) · ③ Row 4 / kingdom name (whenever).

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
