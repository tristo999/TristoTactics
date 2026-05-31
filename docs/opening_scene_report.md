# Tristo Tactics — Opening Scene Report
*For writers and narrative collaborators*

---

## Overview

The opening scene is a purely atmospheric, linear sequence. There is no combat, no UI chrome, and no branching. The player walks forward through a void as a disembodied Guardian voice contacts them through four fragmented transmissions. The sequence ends with the player entering their name and being pulled into the game world by that same voice.

Total estimated runtime: **~2–3 minutes** depending on player walk speed.

---

## The World

The player exists in a pure black void. Beneath their feet, luminous gray tiles materialize one step at a time and fade out behind them as they walk — the path is fleeting, only existing where the player currently stands. A small circle of light surrounds the player; beyond it is complete darkness.

Far above, at the top of the screen, a soft green-white glow pulses — the **beacon**. It starts tiny and imperceptible, and grows slowly larger as the player advances, drawing them forward without instruction.

The player character is a small walking sprite. Movement is tile-based (grid-locked), very slow, and atmospheric. The player can move in any direction, but the path only opens northward.

---

## Phase Structure

### Phase 1 — The Void
*The player cannot move yet. The world is black.*

The scene opens in silence. After a brief pause (~1.5 seconds), the first Guardian transmission appears on screen as glitching text. Once it finishes displaying, the player fades into view and gains movement control.

**Guardian line:**
> *"Are you there?..."*

The darkness eases very slightly as the player materializes. The path begins forming under their feet.

---

### Phase 2 — The Call
*Movement is unlocked. The Guardian invites the player forward.*

Immediately after the player appears, the second transmission plays. The darkness circle around the player widens a touch — enough to see just a little further ahead.

**Guardian line:**
> *"...follow the path..."*

No further instruction is given. The path ahead materializes as the player walks into it.

---

### Phase 3 — The Assembly
*Triggered when the player reaches a mid-corridor marker.*

The beacon at the top of the screen becomes visible for the first time — a soft glow that will slowly grow as the player advances. The third Guardian transmission plays.

**Guardian line:**
> *"...stay with me..."*

The darkness continues to ease as the player progresses. The beacon grows slowly larger with each step forward.

---

### Phase 4 — The Connection
*Triggered when the player reaches a second mid-corridor marker.*

The fourth and final Guardian transmission plays as the player approaches the threshold.

**Guardian line:**
> *"...this world needs you..."*

---

### Phase 5 — The Threshold
*Triggered at the top of the corridor.*

The player is taken over by the game (forced walk continues automatically). The beacon bursts — it expands dramatically and then fades — as the darkness dissolves completely and a landscape image sweeps in from above, revealing the world beyond the void. The image materializes with a wave effect, spreading downward from the beacon's position.

The **game title** — *TRISTO TACTICS* — fades in centered on screen (displayed as a title image asset), holds, then fades out. The player walks in place while this plays.

*No dialogue in this phase.*

---

### Phase 6 — The Name
*Immediately after the title fades.*

The screen settles. The darkness is mostly gone. A text prompt appears asking the player for their name.

**Prompt:**
> *"Tell me your name."*

The player types their name and confirms. Then:

**1. The Welcome**

The Guardian echoes the name back in a warm, reverent tone — large glitching text on screen, slow type speed.

> *"{Player Name}... Welcome..."*

As soon as the text finishes, the screen **shakes** and a quick white flash fires.

---

**2. The Interruption**

A second voice — or a corrupted transmission — breaks in. The player's movement is locked. A sound effect plays (a sharp, tense tone).

> *"No... It's too late..."*

As soon as this text finishes, the screen **shakes harder** and a second white flash hits full brightness. At the peak of that flash:

- The landscape image disappears instantly
- The world goes completely black
- The path tiles begin fading away slowly

The flash then pulls back slightly, leaving the player in a black void as the path dissolves.

> **Canon note (not shown in-scene):** this interruption is the *Authority* intercepting the Guardian's summoning — jamming the connection and **capturing the Hero**, who wakes redirected to the Authority's camp (Act 1, Beat 1). The **Guardian itself is not captured**; it remains in the capital, cut off from the Hero it called. The player learns none of this here. See [`world_bible.md`](world_bible.md).

---

**3. The Final Call**

The last transmission plays. Simultaneously, the screen very slowly fills with white — drowning the text out as it types.

> *"{Player Name}... Find me..."*

The text types slowly. The white wash grows over it. By the time the text finishes, the screen is nearly fully white. The text is hidden. One final push completes the white-out.

**The scene changes.** The next scene fades in from white.

---

## Tone Notes for Writers

- The Guardian speaks in **fragments** — ellipses, incomplete thoughts, transmissions cutting in and out. Never full sentences.
- Lines should feel like they're reaching across a distance or through interference — not like dialogue spoken in the same room.
- Phase 1–4 lines are **reassuring but urgent**. The voice is guiding, not commanding.
- The interruption ("No... It's too late...") is a **tonal break** — it should feel like something going wrong, a signal corrupted or a second presence intruding.
- "Find me..." is the **hook** — the inciting promise that carries the player into the game. It should feel personal, desperate, and just slightly beyond reach.
- The player's name is used **twice** in Phase 6. This is intentional — it makes the Guardian feel like it knows them.

---

## Current Dialogue (All Lines)

| Phase | Speaker | Line |
|-------|---------|------|
| 1 | Guardian | "Are you there?..." |
| 2 | Guardian | "...follow the path..." |
| 3 | Guardian | "...stay with me..." |
| 4 | Guardian | "...this world needs you..." |
| 6 | Guardian | "{Player Name}... Welcome..." |
| 6 | Unknown / Corrupted | "No... It's too late..." |
| 6 | Guardian | "{Player Name}... Find me..." |

---

## Technical Notes (for context)

- Text is displayed via `GlitchTextDisplay` — a custom animated label with glitch effects. Speed and fade timings are set per-line.
- `{player_name}` is automatically substituted with the name entered during the prompt.
- The "Welcome" line types **fast** (speed `18.0`). The "Find me" line types **slow** (speed `6.5`).
- The name entry prompt and the final "Find me" sequence both use the saved player name from `PlayerDataManager`.
- The checkpoint is saved **before** the "Find me" line plays, so if the game crashes during the transition the player resumes at the next scene, not the opening.
