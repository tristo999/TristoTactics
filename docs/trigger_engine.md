# The Trigger Engine — declarative WHEN/THEN for levels

**Status:** v1 built + verified (2026-06-07). Core runtime + condition/action
vocabulary + self-test, **10/10 checks passing headless** (Godot 4.6.3). Not yet
wired into the live opening scenes (they still use bespoke directors); see
*Migration* below.

## Why

Every scripted beat so far is hand-wired: each level connects `EventBus` signals,
tracks its own state, and calls dialogue/flash/spawn by hand (see
`tutorial_spar.gd`, `camp_arrival_scene.gd`). That's *artisanal* — fine for one
cutscene, but we're about to author Beats 3–10. The engine turns scripting from
"write a director per scene" into "declare rules": **WHEN** a condition holds,
**THEN** run these actions. Every future mission trigger, story beat, mid-battle
defection, and coaching line becomes a few declared lines instead of bespoke code.

This is the multiplier: build it once, and the whole content phase gets cheaper.

## The pieces

| File | Role |
|---|---|
| `scripts/triggers/trigger_engine.gd` | `TriggerEngine` node — wires `EventBus`, holds regions/flags/triggers, evaluates + runs them |
| `scripts/triggers/trigger.gd` | `TriggerRule` — one rule (id, condition, actions, once/enabled). Named `TriggerRule`, not `Trigger`, to avoid colliding with the combo system's `FollowUp.Trigger` enum |
| `scripts/triggers/trigger_conditions.gd` | `TriggerCond` — the **WHEN** vocabulary (static factories) |
| `scripts/triggers/trigger_actions.gd` | `TriggerAct` — the **THEN** vocabulary (static factories) |
| `scripts/triggers/_trigger_selftest.gd` + `scenes/dev/trigger_selftest.tscn` | F6 self-test (PASS/FAIL per check) |

## Quick start

Add a `TriggerEngine` as a child of your level, declare regions + triggers in
`_ready`, and you're done — it self-wires to `EventBus`:

```gdscript
func _ready() -> void:
    var tr := TriggerEngine.new()
    add_child(tr)

    # Named regions are Rect2i areas in BaseGrid cell coords (one or many per name).
    tr.region("defensible_pad", Rect2i(16, 12, 8, 5))

    # WHEN a player unit steps onto the pad, THEN Borin coaches (one-shot).
    tr.add("borin_coach",
        TriggerCond.enters("defensible_pad", TriggerCond.is_player),
        [TriggerAct.say([["Borin", "Backs to the pad — let them come to us!"]])])

    # WHEN turn 3 starts, THEN flash + spawn the raid + remember it started.
    tr.add("raid_breaches",
        TriggerCond.turn_reached(3),
        [TriggerAct.flash(Color(1, 1, 1, 0.9)),
         TriggerAct.say([["Vael", "Insurgents — through the gate!"]]),
         TriggerAct.spawn(RAID_ROSTER),
         TriggerAct.set_flag("raid_started")])
```

## WHEN — `TriggerCond`

A condition is a `Callable(event, engine) -> bool`. Factories:

| Condition | Fires when |
|---|---|
| `on(type)` | the event's type matches (e.g. `"battle_started"`) |
| `enters(region, who?)` | a unit (matching `who`) moves to a tile inside `region` |
| `leaves(region, who?)` | a unit moves from inside `region` to outside it |
| `turn_start(who?)` | a unit matching `who` begins its turn |
| `turn_reached(n)` | the Nth turn (any unit) starts |
| `died(who?)` | a unit matching `who` dies |
| `attacked(who?)` | a unit matching `who` lands an attack |
| `hp_below(who, pct)` | a unit matching `who` drops to/below `pct` (0–1) of max HP |
| `battle_end(victory?)` | battle ends (`1`=win, `0`=loss, `-1`=either) |
| `flag(name, value?)` | (pure) the blackboard flag equals `value` (default `true`) |

**Unit filters** (`who`) are `Callable(node) -> bool`. Pass a preset *by reference*
or build one; omit to match any unit:
`TriggerCond.is_player`, `is_enemy`, `is_ally`, `team("enemy_team")`, `named("Elena")`.

**Combinators:** `all_([...])`, `any_([...])`, `not_(cond)`. Mix event conditions
with `flag(...)` predicates to gate on state:

```gdscript
TriggerCond.all_([
    TriggerCond.died(TriggerCond.is_ally),
    TriggerCond.flag("raid_started"),
])
```

## THEN — `TriggerAct`

An action is a `Callable(engine) -> void`, run in order; coroutine actions are
awaited so a dialogue beat blocks the next action.

| Action | Effect |
|---|---|
| `say([[speaker, text], …])` | play a dialogue sequence (blocks) |
| `play_event(StoryEvent)` | run any of the 15 built `StoryEvent` types as an action |
| `emit_story(StoryEvent)` | emit it on `EventBus.story_event_triggered` |
| `wait(seconds)` | pause before the next action |
| `flash(color?, up?, down?)` | full-screen flash (default = white jolt) |
| `fade_out(dur?, keep?)` / `fade_in(dur?)` | fade to/from black |
| `change_scene(path)` | switch scenes (after a `fade_out`) |
| `set_flag(name, value?)` | set a blackboard flag (gates other triggers) |
| `flip_team(who, new_team)` | defect every matching live unit to `new_team` |
| `spawn(roster, …)` | spawn a roster via `BattleSpawner` (parents found by name) |
| `call_fn(callable)` | escape hatch — run arbitrary scene logic |
| `enable(id)` / `disable(id)` | arm/disarm another trigger by id |

## Semantics

- **Regions** are named `Rect2i` lists in BaseGrid cell coords. `region()` can be
  called repeatedly to add rects (a region can be several rectangles).
- **Flags** are a `String -> Variant` blackboard. Setting a flag re-evaluates
  flag-gated triggers immediately (no event needed), so you can chain rules.
- **`once`** (default `true`) disables the trigger the instant it fires. Pass
  `false` for standing rules ("every time an ally falls…"). Toggle any trigger at
  runtime with `enable(id)`/`disable(id)`.
- **Serialized execution:** actions run one trigger at a time. Events that match
  while a trigger is mid-`await` are queued and run in order — two dialogue beats
  never overlap.
- **Self-wiring:** the engine connects all 10 `EventBus` gameplay signals in
  `_ready` and normalizes each into a small event Dictionary (see the header of
  `trigger_engine.gd` for the exact shape).

## Worked example — the spar, as triggers (before / after)

Today `tutorial_spar.gd` hand-wires three `EventBus` connections, a `Step` enum,
and bespoke gating. The tonal hinge — *the raid interrupts the drill* — is this
bespoke method:

```gdscript
# BEFORE (bespoke, in tutorial_spar.gd)
func _raid_interrupt() -> void:
    await _flash(Color(1,1,1,0.9), 0.06, 0.5)
    await get_tree().create_timer(0.35).timeout
    await _say([["Vael", "...Those aren't ours."], …])
    await _fade_black(0.8)
    get_tree().change_scene_to_file(next_scene_path)
```

The same beat, declared:

```gdscript
# AFTER (declared on a TriggerEngine)
tr.add("raid_interrupt",
    TriggerCond.flag("drill_taught"),       # set once the combo lesson lands
    [TriggerAct.flash(Color(1,1,1,0.9)),
     TriggerAct.wait(0.35),
     TriggerAct.say([["Vael", "...Those aren't ours."],
                     ["Vael", "Insurgents — they're through the gate! Blades out — this is no drill!"]]),
     TriggerAct.fade_out(0.8),
     TriggerAct.change_scene(NEXT_SCENE)])
```

## Item #4 — mid-battle team flip (the validation case)

The collision pillar in miniature: spar partners fight *against* you, then defect
to fight *beside* you when the raid hits. With the engine that's one action — no
new code, no scene change required:

```gdscript
# WHEN the raid breaches, THEN the sparring partners join your side.
tr.add("partners_defect",
    TriggerCond.flag("raid_started"),
    [TriggerAct.say([["Vael", "Recruits — you stand WITH them now! MOVE!"]]),
     TriggerAct.flip_team(TriggerCond.team(Constants.TEAM_ENEMY), Constants.TEAM_ALLY)])
```

`flip_team` re-files group membership and recolors health bars via the new
`CharacterBase.set_team()`. AI enemies flipped to `TEAM_ALLY` stay AI-controlled
but friendly, and win/lose ignores allies — so the defection "just works" inside a
single live battle. This proves the engine handles the hard case (state change
mid-fight), and is what a future combined drill→raid scene (Beat 3-style) will use.

## Migration plan (not done yet — deliberately)

The live opening scenes still use their bespoke directors and **keep working**.
We don't rip them out tonight. Convert opportunistically:

1. **Validate** — run `scenes/dev/trigger_selftest.tscn` (F6, or headless:
   `Godot --headless --path . res://scenes/dev/trigger_selftest.tscn`) → expect
   `[TriggerSelfTest] 10/10 checks passed — ALL PASS`. (Already green.)
2. **First real use** — author Beat 3 (the first post-raid mission) *on the engine
   from the start*, rather than retrofitting. That's the cleanest proof and is the
   next item on the build spine.
3. **Retrofit the spar/raid** later, beat by beat, once the engine has earned trust
   in Beat 3. The team-flip above is the natural first retrofit (it removes a
   scene-change hack and delivers the collision moment in one battle).

## Extending the vocabulary

Add a `static func` to `TriggerCond` (returns a condition Callable) or `TriggerAct`
(returns an action Callable). Don't build speculative verbs — grow the vocabulary
when a real beat needs one (the same rule as the level-spec triggers).
