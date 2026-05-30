# Dialogue System — Tristo Tactics

## Overview

Dialogue and cinematic moments are authored using a **StoryEvent** pipeline.
Events are `Resource` subclasses that expose an `execute(scene_tree)` coroutine.
They can be chained in editor-placed `CinematicTrigger` nodes or run directly
from scene scripts with `await event.execute(get_tree())`.

---

## Core Types

### StoryEvent (`scripts/story/story_event.gd`)
Base class. Override `execute(scene_tree: SceneTree) -> void`.
The caller `await`s each event in sequence — so events control their own
pacing by `await`-ing tweens, timers, or signals internally.

### DialogueLine (`scripts/story/dialogue_line.gd`)
One line of speech. Fields:

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `speaker` | String | `""` | Speaker name shown in box header |
| `text` | String | `""` | Body text |
| `portrait` | Texture2D | null | Character headshot (optional) |
| `glitched` | bool | false | Each character flickers before resolving |
| `auto_advance_delay` | float | -1.0 | Seconds before auto-advance. -1 = wait for input |
| `chars_per_second` | float | -1.0 | -1 uses DialogueBox default (30 cps) |
| `type_sfx_key` | String | `""` | SFX key per typed character. Blank = box default |

### DialogueSequence (`scripts/story/dialogue_sequence.gd`)
A named, reusable `Array[DialogueLine]` that can be saved as a `.tres` file.
Store authored sequences in `res://dialogue/`.

```
res://dialogue/
  beat0_corridor_guardian.tres   # Opening corridor: Guardian's whisper
  beat1_vael_arrival.tres        # Beat 1: Vael walks up
  ...
```

### DialogueEvent (`scripts/story/dialogue_event.gd`)
Plays an `Array[DialogueLine]` through the `DialogueBox`.

### CallbackEvent (`scripts/story/callback_event.gd`)
Calls any `Callable`. If the callable returns a `Signal`, `await`s it.
Use for camera moves, spawning effects, walking triggers — anything between
dialogue lines that doesn't need its own StoryEvent subclass.

### WaitEvent (`scripts/story/wait_event.gd`)
Pauses the sequence for `duration` seconds.

### FlashEvent (`scripts/story/flash_event.gd`)
Full-screen color flash via `ScreenOverlay`. Set `hold_and_cut = true` to
leave the screen white for a scene transition.

### Other events
- `GlitchTextEvent` — floating glitch text overlay
- `NameEntryEvent` — hero name input prompt
- `OverlayEvent` — generic overlay fade
- `SceneChangeEvent` — change scene
- `FogEvent` — fog/darkness effects
- `TitleEvent` — title card display
- `SaveCheckpointEvent` — save progress flag

---

## CinematicTrigger (`scripts/story/cinematic_trigger.gd`)

Place a `CinematicTrigger` node in a walking scene. It fires its `events`
array when the player steps on its tile (or matching Y row if `match_y_only`).

```
CinematicTrigger
  @export var events: Array[StoryEvent]
  @export var one_shot: bool = true        # fires once per session
  @export var lock_player: bool = true     # freeze input during events
  @export var match_y_only: bool = false   # corridor-friendly Y-only match
  @export var save_flag: String = ""       # persist "seen" across sessions
```

**Limitations**: custom Resource subclasses cannot be drag-dropped as
sub_resources into `.tscn` files. Populate `events` from the scene `_ready`
script instead, or save `DialogueEvent` instances as `.tres` resources.

---

## Authoring Patterns

### Pattern A — Pure code (opening sequence, scripted cutscenes)

Best for sequences tightly coupled to scene logic (phase timing, camera
moves between lines).

```gdscript
func _play_vael_arrival() -> void:
    var line1 := DialogueLine.new()
    line1.speaker = "Vael"
    line1.text = "You actually made it."

    var line2 := DialogueLine.new()
    line2.speaker = "Vael"
    line2.text = "I was starting to wonder."

    var ev := DialogueEvent.new()
    ev.lines = [line1, line2]
    await ev.execute(get_tree())

    # Walk Vael to the hero between dialogue bursts
    var walk_cb := CallbackEvent.new()
    walk_cb.callback = _vael_step_forward
    await walk_cb.execute(get_tree())

    var line3 := DialogueLine.new()
    line3.speaker = "Vael"
    line3.text = "You must be a little confused."
    var ev2 := DialogueEvent.new()
    ev2.lines = [line3]
    await ev2.execute(get_tree())
```

### Pattern B — .tres resource files (reusable / editor-editable)

Best for long scenes with no interleaved actions, or sequences shared
between scenes (tutorial tips, recurring NPC lines).

```gdscript
var seq := load("res://dialogue/beat1_vael_arrival.tres") as DialogueSequence
var ev := DialogueEvent.new()
ev.lines = seq.lines
await ev.execute(get_tree())
```

### Pattern C — CinematicTrigger in editor

Best for world-placed triggers (entering a room, stepping on a floor tile).
Populate `events` from `_ready` to mix DialogueEvents with CallbackEvents:

```gdscript
# In the trigger's parent scene script
func _ready() -> void:
    var trigger := $VaelTrigger as CinematicTrigger
    var ev := DialogueEvent.new()
    ev.lines = (load("res://dialogue/beat1_vael_arrival.tres") as DialogueSequence).lines
    trigger.events.append(ev)
```

---

## Long Cinematic Scenes with Interleaved Actions

For complex scenes (NPC walks, camera cuts, particle bursts between lines)
use a scene-level coroutine and alternate between `DialogueEvent` blocks and
`CallbackEvent` blocks:

```gdscript
func _run_beat1() -> void:
    await _flash_in()                            # FlashEvent or direct tween

    await _play_lines(["You actually made it.",  # helper builds DialogueEvent
                       "I was starting to wonder."], "Vael")

    await _move_vael_closer()                    # CallbackEvent or direct await

    await _play_lines(["You must be a little confused."], "Vael")

    await _unlock_player()
```

This is the **recommended approach for Beat 1 and beyond** — keeps scene
logic readable and doesn't require any new infrastructure.

---

## Battle Dialogue

Battle dialogue uses the same `DialogueEvent` / `CinematicTrigger` pipeline.
Place `CinematicTrigger` nodes in the battle scene, set `lock_player = false`
for lines that should play without pausing the fight, and use `save_flag` to
prevent replaying on retry.

---

## Dialogue Folder Convention

Name files by **narrative moment**, not by speaker, phase number, or technical system.
Use short, readable names a writer can understand without reading code.

```
res://dialogue/
  beat0/
    void_transmissions.tres     # Guardian's fragmented contact through the void
    name_sequence.tres          # Name echo → disruption → "Find me" climax
  beat1/
    vael_arrival.tres           # Vael walks up and addresses the hero
    vael_camp_tour.tres
  tutorial/
    combat_intro.tres
  npcs/
    [npc_name]_[context].tres
```

Create the folder when the first `.tres` file is ready to save.
