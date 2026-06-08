# Tristo Tactics — Implementation Status

> **Purpose:** maps each story beat to the scene(s) that implement it and tracks build state. Read this before picking up narrative work.
> **Story source of truth:** [`overview.md`](overview.md) (north star) + the four-part bible ([`bible_01_world`](bible_01_world.md) / [`bible_02_cast`](bible_02_cast.md) / [`bible_03_act1`](bible_03_act1.md) / [`bible_04_act2`](bible_04_act2.md)) + [`collision_ledger.md`](collision_ledger.md).
> **Systems design:** [`systems_design.md`](systems_design.md) (mechanics: combat, death/stakes, relationships, combos, the advancing line, time powers)
> **Technical reference:** [`../ARCHITECTURE.md`](../ARCHITECTURE.md)
> **Last reviewed:** 2026-06-07 (the Act-1 OPENING now plays end to end as one chain: corridor → chamber → arrival cutscene → spar → raid; genuine walk-out, scripted spar that teaches the follow-up + the coach→commander raid hinge, sibling drill/raid arenas. Code-reviewed the orchestrators — no correctness bugs). Prior 2026-06-06 (combo system confirmed BUILT; Beat 2 battle scaffold; map-authoring tooling + level-spec convention).
>
> **Framework note:** the project is now designed around *collisions* (scenes that happen twice) rather than a linear 21-beat list — see the ledger. The MVP slice has grown to **Opening → camp → tutorial → a mission or two → the bridge face-off**, ending on the stare across the gap — see [`slice_spec.md`](slice_spec.md) for the authoritative build spec. The slice is also where the signature systems (combos, bonding, expressive choices) get built for the first time. The revised Act 1 ending (the hero opens the door / the legion / the true form) sits past the slice. B2–B5 carry a duty to plant retrieval cues (see ledger).

---

## Legend

| Symbol | Meaning |
|---|---|
| ✅ | Fully implemented, no known gaps |
| 🟡 | Scaffolded (scene exists, systems in place, content incomplete) |
| 🟥 | Stub only (file exists but effectively empty) |
| ⬜ | Not started (no scene/script yet) |

---

## Engine & Systems — Build State

| System | State | Location | Notes |
|---|---|---|---|
| Battle turn order + state machine | ✅ | `scripts/managers/battle/game_manager.gd` | Full `BattleState` FSM, initiative sorting, win/loss detection |
| Tile-based pathfinding (A* + BFS) | ✅ | `scripts/levels/tilemaps/tilemap.gd` | AStarGrid2D + cost-aware BFS, terrain-aware |
| Attack flow + cutscene | ✅ | `scripts/ui/attack_animation_overlay.gd` | Autoload, blocking, crit/damage overlay |
| Ability framework | ✅ | `scripts/abilities/`, `data/abilities/` | `HealAbility` (active) + tier-1 follow-ups concrete; `EventBus.ability_used` unconsumed |
| **Combo / follow-up system** | ✅ | `scripts/managers/battle/combo_system.gd`, `scripts/abilities/follow_up*.gd` | `ComboSystem` autoload, data-driven (`CharacterData.follow_ups`, no per-scene wiring). 3 triggers: ally-attacks-enemy chain (archer), ally-damaged mend (healer), pre-hit intercept (dwarf); once-per-round cap. **Open:** passives, duo combos, *teaching* it in the tutorial |
| Enemy AI (melee) | ✅ | `scripts/characters/enemies/enemy_character.gd` | Nearest-player heuristic, A*/BFS fallbacks |
| Walking scene base | ✅ | `scripts/levels/walking_scene.gd` | Tile-snapped movement, NPC interaction, triggers |
| Story event system | ✅ | `scripts/story/*.gd` | 15 event types: dialogue, glitch, fog, flash, overlay, wait, name, save, scene change, callback, title |
| Dialogue + glitch text | ✅ | `scripts/story/dialogue_box.gd`, `scripts/ui/glitch_text_display.gd` | Per-char typewriter SFX, auto-advance, glitched variant |
| Per-character SFX | ✅ | `scripts/characters/base/character_sfx.gd` | Resource-based overrides |
| Settings + persistence | ✅ | `scripts/core/settings_manager.gd` | `user://settings.cfg` |
| Save/load (checkpoint) | ✅ | `scripts/managers/player_data_manager.gd` | `user://player_data.json`; tracks name + current_scene |
| Pause menu | ✅ | `scripts/ui/pause_menu.gd`, `scripts/levels/pause_menu_handler.gd` | Works in both battle and walking |
| Tutorial prompts | ✅ | `scripts/managers/tutorial_manager.gd`, `scripts/ui/tutorial_prompt.gd` | Prompts exist; mission that uses them does not |
| **Trigger engine (WHEN/THEN)** | 🟡 | `scripts/triggers/` (`trigger_engine.gd`, `trigger_conditions.gd`, `trigger_actions.gd`, `trigger.gd`) | v1 built (2026-06-07): declarative per-level rules over `EventBus` — named regions, flags, `TriggerCond.*` conditions, `TriggerAct.*` actions (incl. `flip_team`/`spawn`/`play_event`). Self-test `scenes/dev/trigger_selftest.tscn` passes **10/10 headless** (4.6.3). Full guide: `docs/trigger_engine.md`. **Open:** wire into live scenes (Beat 3 first); retrofit spar/raid directors |
| Steam integration | 🟡 | `scripts/managers/steam_manager.gd` | Manager present; achievements TBD |
| VictoryDefeat screen | ✅ | `scripts/ui/victory_defeat_screen.gd` | Wired to `EventBus.battle_ended` |
| Speed toggle (2×) | ✅ | `scripts/ui/speed_toggle_button.gd` | Uses `Engine.time_scale` |

---

## Opening Sequence — Build State

| Beat | Scene | Script | State | Notes |
|---|---|---|---|---|
| Opening Phase 1 — The Void | `opening_corridor_scene.tscn` | `opening_corridor_scene.gd` | ✅ | Black, Guardian line, player fade-in |
| Opening Phase 2 — The Call | same | same | ✅ | Movement unlocked, darkness eases |
| Opening Phase 3 — The Assembly | same | same | 🟡 | Beacon reveal + darkness release done. **TODO L427–428:** companion-line and Act 2 vision line still placeholder |
| Opening Phase 4 — The Connection | same | same | ✅ | Final free transmission |
| Opening Phase 5 — The Threshold | same | same | 🟡 | Forced walk + landscape bloom + title card done. **TODO L389:** fullscreen swirl shader is a 2s black-wait placeholder; needs animated noise shader before shipping |
| Opening Phase 6 — The Name | same | same | ✅ | Name entry, welcome, interruption, final "Find me…", white fade |

**Remaining work for the opening to be shippable:**
1. Implement the swirl shader (replace `opening_corridor_scene.gd:389` wait with a proper effect)
2. Write the two placeholder dialogue lines (L427–428) — companion/Act 2 vision
3. Playtest end-to-end after shader lands; verify pacing still holds

Writer-facing reference: [`opening_scene_report.md`](opening_scene_report.md)

---

## Act 1 — THE LOYAL BLADE — Build State

Narrative canon is the four-part bible ([`bible_03_act1`](bible_03_act1.md) for this act); this table tracks *build state* per beat. Mission count per beat is TBD.

| Beat | Narrative | Planned Scene | Current Scene File | State | Next Work |
|---|---|---|---|---|---|
| 1 — ARRIVAL | Hero awakens, walks out, Vael greets | Summoning chamber + camp arrival (walking) | `summoning_room_scene` + `camp_arrival_scene` | 🟡 | Chamber walking stub exists (fade-in → door → next). **NEW 2026-06-06:** `camp_arrival_scene.tscn` on `camp_grounds.map` — a **fully scripted cutscene** (no player input): fade in at the doorway → cutscene camera pans up to Vael → he notices the hero and walks down → warm greeting → leads the hero up toward the training ground → fade. Uses a reusable `CinematicActor` (`scripts/characters/walking/cinematic_actor.gd`, code-built walk anims) for Vael + a dedicated `CineCam`. TODO: camp atmosphere/soldiers, Vael sprite+portrait, chamber dressing, wire chamber→arrival→tutorial. Spec: `levels/camp_grounds.md`. |
| 2 — TUTORIAL (spar) + TUTORIAL BATTLE (raid) | First tactical combat. Shape: a scripted **spar** that teaches the verbs + the follow-up combo, then a **raid** breaches and it becomes a true battle. **Two separate scenes on SIBLING maps** (collision-mirror at small scale — same yard, the raid breaches the wall you drilled behind). **Mirror:** Act 2 B2 is inside this camp during the raid. | Training arena — `data/maps/arena_drill.map` (spar) + `data/maps/arena_raid.map` (raid), siblings from `gen_training_arena.py` | **spar:** `tutorial_spar_scene.tscn` + `tutorial_spar.gd` · **raid:** `tutorial_battle_scene.tscn` + `tutorial_battle.gd` | 🟡 | **Both halves built & the chain is wired** (2026-06-07): arrival → spar → raid. **Spar** (scripted, `arena_drill`): squad vs nonlethal partners; a director gates the action bar step-by-step + prompts via `TutorialPrompt`, with Vael coaching intro → **move** → **attack** → follow-up narration → hands off to the raid. **Raid** (true battle, `arena_raid`): squad 1/2/3 + allies 5/6/7 vs E from the 3 north breaches; full combat/combos/camera. **Remaining:** precise combo detection/teach (currently narrated), the raid spawn *trigger/timing* (raid spawns at start, not mid-spar), Vael coach→commander tonal flip, camera framing tune, chamber→arrival wiring, real Vael/portrait. (`camp_v2.map` + old `tutorial_scene.tscn` superseded.) |
| 3 — EARLY CAMPAIGN | Missions against "insurgents", subtle anomalies begin | Kingdom outskirts (battle) | — | ⬜ | Not started |
| 4 — SHADOWED FIGURES (first appearance) | Cloaked figures appear, called saboteurs | TBD (battle) | — | ⬜ | Not started |
| 5 — BRIDGE INCIDENT | Bridge collapses mid-mission | Bridge map (battle, mirrored in Act 2 B3) | — | ⬜ | Not started. Map must be reusable with inverted objectives for Act 2. |
| 6 — TOWN MISSION | Operation with civilian casualties, rationalized by Vael | Civilian settlement | — | ⬜ | Not started |
| 7 — THE CHOICE | Two top-relationship companions fall, save one | Narrative beat | — | ⬜ | Blocks on companion identities being locked (Open Question 6) |
| 8 — THE CAPITAL / CORE TAKEN | March reaches the capital; the Authority discards the hero and takes the core, opening the door for the legion (revised canon — the hero opens the door; the Guardian is *not* captured) | Kingdom capital | — | ⬜ | Not started |
| 9 — THE REALIZATION | Guardian's first full sentence | Narrative beat | — | ⬜ | Not started |
| 10 — THE LAST STAND | Unwinnable battle, fragment sent forward, Unchosen Companion sent forward | Ritual site | — | ⬜ | Not started |

**Dev-only scene (not on the story critical path):**

| Scene | Script | Purpose | State |
|---|---|---|---|
| `dev_sandbox_scene.tscn` | `dev_sandbox_scene.gd` | Goblins + Elena at mountain pass. Ad-hoc battle arena used to exercise the battle system end-to-end. Hardcoded dialogue does not align with current canon. | Playable, retained as a reference sandbox for battle-system work. Not on the story critical path. |

---

## Act 2 — THE FRACTURED BLADE — Build State

All Act 2 beats unbuilt. Scene names below are suggestions pending Act 1 implementation.

| Beat | Narrative | State |
|---|---|---|
| 1 — ARRIVAL (pre-war) | Hero/party arrive before summoning circle active | ⬜ |
| 2 — OPERATING IN THE MARGINS | Sabotage + key infiltration. Sends loyalist distraction; slips into emptied camp; **overhears Vael unguarded** (contempt for the kingdom defense + misfits aside; dialogue TBD); **summoning fires mid-sentence** — party watches it happen, cannot stop it, watches Vael's performance switch back on as he leaves to greet the Hero; summoning is the exit signal. Retrieves item (TBD). Vael frustration builds. | ⬜ |
| 3 — BRIDGE EVENT | Party destroys bridge; closes the loop with Act 1 B5 | ⬜ |
| 4 — LOVED NPC RESCUE | Rescue the Act 1 casualty | ⬜ (blocks on Open Question 3) |
| 5 — UNCHOSEN COMPANION first appearance | Pursuit/escape | ⬜ |
| 6 — VAEL UNMASKED | Observed cruelty, possibly stealth | ⬜ |
| 7 — VAEL'S FINAL CONFRONTATION | Boss battle, Vael dies | ⬜ |
| 8 — THE REVELATION MOMENT | Unchosen witnesses Authority's transformation | ⬜ |
| 9 — FINAL BATTLE PREPARATION | Setup mission | ⬜ |
| 10 — FINAL BATTLE | Three-front tactical battle, largest in game | ⬜ |
| 11 — SILENT RECONCILIATION | Hero + Unchosen post-battle | ⬜ |

---

## Open Decisions Blocking Production

Ordered by urgency (what must be decided to unblock active work).

1. **Companion identities** (names, origins, wounds). See the world bible's open questions. Blocks Beats 2–10 dialogue and Beat 7 "The Choice" mechanic. Cores designed: Archer, Healer, Tank/dwarf, plus the barely-planned Warlock (distinct from the undesigned Wizard); Wizard, Knight, Rogue and the roster count/composition are open.
2. **Guardian fragment power semantics** — the finale keystone (the world bible's #1 open question). Blocks the save-one-companion mechanic (Beat 7) and the Act 2 arrival (Beat 1).
3. **Kingdom name and cultural identity** (world bible open question). Unblocks all Act 1+2 dialogue that references the place.
4. **Mission count per beat.** Required before level design can begin on Beats 3–6.
> **Resolved 2026-04-20:** `test_scene` kept as a reference sandbox and renamed to `dev_sandbox_scene`. It's dev-only and not on the story critical path; Beat 2 will be built fresh rather than repurposing it.
>
> **Resolved 2026-05-13:** Beat 2's combat shape is **sparring interrupted by insurgents**. Phase 1 is a controlled sparring match (Authority soldiers or fellow recruits, nonlethal, teaches the core verbs); Phase 2 starts when "insurgents" crash the training ground and the engagement becomes lethal. The interruption beat is the tonal hinge — Vael frames it as unprovoked aggression, and it doubles as the first lethal combat. Sets up an Act 2 reframe (those "insurgents" were the Guardian's loyalists).

---

## Recommended Next Sprint

Pick ONE of the following; they're roughly independent.

### Sprint A — Ship the opening
Goal: remove all placeholders from the opening sequence so it's fully polished.
- Implement the swirl shader (`opening_corridor_scene.gd:389`)
- Write + integrate the two placeholder dialogue lines (L427–428)
- Playtest full opening + first transition into `summoning_room_scene`

**Why it matters:** the opening is the first thing any player sees. The user's latest commits show ongoing investment here.

### Sprint B — Build Act 1 Beat 1 (ARRIVAL)
Goal: turn `summoning_room_scene` into a real cinematic introduction.
- Populate the scene: Vael sprite + soldiers, torchlight lighting, summoning-circle effect
- Write the Vael arrival dialogue (warm, righteous framing)
- Add a `CinematicTrigger` chain for the arrival sequence
- Ensure the existing `DoorTrigger` still fires the correct transition

**Why it matters:** this is the first gameplay the player sees after the opening. Currently it's just a walking scene with a door.

### Sprint C — Build Act 1 Beat 2 (TUTORIAL)
Goal: turn the tutorial battle into the real two-phase beat. Shape: **sparring interrupted by insurgents** (resolved 2026-05-13).

> **Progress 2026-06-06:** the battle scaffold is **built and plays** — `tutorial_battle_scene.tscn` on `camp_v2.map`, data-driven roster, combat + combos working. What remains is the *sequencing*: the spar→raid two-phase split, Vael's coach→commander dialogue, the raid spawn trigger, and TutorialManager teaching of the follow-up. Author it via the level spec `docs/levels/camp_v2.md` and the regions/triggers convention (`map_generation_playbook.md` §8). This is now content/sequence wiring, not a from-scratch build.

**Phase 1 — Sparring (tutorial phase):**
- Battle scaffold exists (`tutorial_battle_scene.tscn`); `dev_sandbox_scene.tscn` retained as a battle-wiring reference but is narratively off-canon
- Opponents: Authority soldiers or fellow recruits (nonlethal — damage reads as stamina/yields, no death animations)
- Hook `TutorialManager` prompts to teach the core verbs in order: move → basic attack → end turn → ability
- Vael narrates as drill instructor via `DialogueEvent` ("show me what you've got", praise on each correct action)

**Phase 2 — Interruption (real-stakes phase):**
- Trigger: end of sparring round (or specific turn/HP threshold) — `CinematicTrigger` or a `BattleEvent` flips state
- Insurgents enter the map (spawn at map edge, scripted approach)
- Tonal shift: dialogue + music change; Vael's framing turns from coach to commander ("they came for you — defend yourselves")
- Combat is now lethal; sparring partners may join the player's side
- Win condition: defeat the insurgents → triggers Beat 2 outro and transition
- **Mirror note:** While this battle plays out, the Act 2 party is inside the camp — the loyalist attack is a small distraction force they sent to pull the Act 1 party outside. Same place, same moment, camp walls between them. The Act 2 party is on a clock: retrieve the item and leave before the fight ends. The reframe lands in Act 2 Beat 2 when the player is the one who sent the distraction.

**Cross-cutting work:**
- Decide insurgent visual identity (faction-neutral so the Act 2 reframe lands)
- Wire `EventBus.battle_ended` outro → transition to Beat 3 scene (TBD)
- Tutorial prompts must NOT fire during Phase 2 (suppress `TutorialManager` after the trigger)

**Why it matters:** first tactical combat — where players learn the game AND get their first taste of "real" stakes + Authority framing. The interruption beat is the tonal hinge of the early game.

### Sprint D — Companion lock-in
Goal: resolve Open Question 6 so narrative work on Beats 2–7 can begin.
- Not a coding sprint — a writing/design session with the creative director.
- Deliverable: update [`bible_02_cast.md`](bible_02_cast.md) with companion names/origins/wounds.

---

## How to Update This Doc

When you complete work on a beat or system, update the **State** column and the **Notes**. When new blockers emerge, add them to **Open Decisions Blocking Production**. Keep the "Last reviewed" date at the top current.

Prefer updating in the same PR as the feature work — stale status is worse than no status.
