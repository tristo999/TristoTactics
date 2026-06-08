# Codebase Cleanup & Unification Analysis (2026-06-07)

Reviewed for **dedup, simplification, system unification, and scalability**.
Evidence is cited by file:line. Items are prioritized; the top two are executed in
this pass (see *Status*), the rest are a backlog with concrete actions.

---

## P1 — Cinematic/dialogue primitives are implemented THREE times ⭐ (executed)

The same small set of cutscene primitives — **flash, fade, wait, say, scene-change** —
exists in three parallel forms:

| Primitive | StoryEvent (resource) | Bespoke director | Trigger engine |
|---|---|---|---|
| dialogue | `DialogueEvent.execute` | `camp_arrival._say` (L155), `tutorial_spar._say` (L207) | `trigger_engine.say` (L180) |
| flash | `FlashEvent` → `ScreenOverlay.flash` | `tutorial_spar._flash` (L181) | `trigger_engine.flash` |
| fade | (via `ScreenOverlay`) | `camp_arrival._fade` (L143), `tutorial_spar._fade_black` (L195) | `trigger_engine.fade` |
| wait | `WaitEvent` | `camp_arrival._wait` (L132) | `trigger_engine.wait` |
| scene change | `SceneChangeEvent` | inline `change_scene_to_file` | `TriggerAct.change_scene` |

**Why it happened:** `StoryEvent` flash/fade depend on a `ScreenOverlay` node (group
`screen_overlay`) that only *walking* scenes have — so battle-side directors
(`tutorial_spar`) and the trigger engine each rolled their own `ColorRect`/`CanvasLayer`
versions. Three copies of the same tween logic, drifting independently.

**Action (done):** extracted **`CineFx`** (`scripts/story/cine_fx.gd`) — static
primitives (`say`, `lines`, `flash`, `fade`, `wait`) that build their overlay from a
passed `CanvasLayer`, so they work in **any** scene (battle or walking). Routed
`camp_arrival_scene`, `tutorial_spar`, and `TriggerEngine` through it. Behavior is
byte-for-byte identical (same durations, same `ColorRect`/`mouse_filter`/tween); the
three implementations collapse to one.

**Recommended follow-up (not done):** converge the `StoryEvent` flash/fade onto
`CineFx` as a fallback when no `ScreenOverlay` is present, so authored sequences and
trigger actions share one implementation everywhere. Bigger change; do when a walking
*and* battle scene need the same authored flash.

## P2 — Manhattan distance coded twice ⭐ (executed)

`FollowUp._dist` (`follow_up.gd:47`) and `CharacterBase._tile_distance`
(`character_base.gd:325`) are identical (`abs dx + abs dy`).

**Action (done):** added `Constants.tile_distance(a, b)`; both delegate to it. One
source of truth; the existing call sites (`enemy_character`, `character_base`,
follow-ups) are untouched in behavior.

## P3 — `DialogueLine` hand-built in 6+ places (MEDIUM)

Manual `DialogueLine.new(); .speaker=; .text=` appears in `tutorial_manager` (L50/54),
`walking_npc` (L38), `dev_sandbox_scene` (×6), `tutorial_battle` (L54), plus every
`_say` helper. **Action:** `CineFx.lines([[speaker, text], …])` now exists (used by
the routed `_say`s); migrate the remaining hand-builders to it opportunistically. Low
risk, do when touching those files.

## P4 — Two cutscene-trigger detection styles (MEDIUM, scalability)

Position-triggered beats are detected two ways:
- **Per-frame polling** of `current_tile`: `CinematicTrigger`, `opening_corridor_scene`,
  `camp_arrival_scene` (`ARCHITECTURE.md` itself flags this won't scale past a few).
- **EventBus** `character_moved`: `tutorial_spar`, `tutorial_manager`, `summoning_room`.

The **TriggerEngine** (regions + `EventBus`) is the scalable unification of exactly
this. **Action:** standardize *new* scripted scenes on `TriggerEngine`; migrate the
pollers opportunistically (Beat 3 first, then retrofit). Policy, not a tonight change.

## P5 — Tutorial gating is bespoke (MEDIUM, scalability)

`tutorial_spar` gates the action bar by reaching into the `action_bar` group and
toggling `.attack_button.disabled` etc. (L157–170); `TutorialManager` is hard-coded for
the corridor. There is no general "tutorial step" abstraction. **Action:** once the
engine drives scenes, express gating as a `TriggerAct` (e.g. `set_action_bar(enabled)`)
so tutorials are declared like everything else. Backlog.

## P6 — Parallel camera controllers (LOW)

`camera_control` (battle), `corridor_camera` (walking), and an ad-hoc tweened `CineCam`
(directors hand-tween a plain `Camera2D`: `camp_arrival._pan_to`). **Action:** a tiny
`CineCam` helper (`pan_to/snap_to/zoom`) would dedup director camera tweens; defer until
a second director needs it.

## P7 — Misc (LOW / notes)

- `GoblinCharacter` hard-codes stats in `_init` (`goblin_character.gd:6`), which
  `CharacterBase._apply_character_data` overwrites when `character_data` is set →
  dead-ish fallback. Prefer fully data-driven (`.tres`). Note.
- `ActiveStatsPanel` and `BottomActionBar` both connect `character_movement_finished →
  _on_character_updated` — parallel but legitimately separate panels; not worth merging.
- Repeated `get_first_node_in_group("tilemap"/"dialogue_box"/"BaseGrid")` lookups. A
  thin `Refs` accessor could centralize, but low value; skip until it bites.

---

## Status this pass

- **P1 executed** — `CineFx` extracted; `camp_arrival`, `tutorial_spar`, `TriggerEngine`
  routed through it. Verified: project parses clean headless; trigger self-test 10/10.
- **P2 executed** — `Constants.tile_distance`; `FollowUp._dist` + `CharacterBase._tile_distance`
  delegate.
- **P3–P7** — backlog above, each with a concrete action and trigger condition for *when*
  to do it (avoid speculative refactors).

**Guiding principle applied:** unify onto one implementation where consumers already
duplicate it (P1/P2), and standardize *new* work on the scalable system (P4/P5 →
TriggerEngine) rather than rewriting working scenes speculatively.
