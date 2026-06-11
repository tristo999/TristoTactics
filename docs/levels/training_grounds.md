# Level Spec — Training Grounds (the ONE tutorial scene, PROPOSAL)

- **Map:** `data/maps/training_grounds.map` (to generate — successor to `arena_drill`/`arena_raid`)
- **Scene:** one continuous scene: drill → breach → raid, **no cut** (ruled 2026-06-10)
- **Status:** SCOPE PROPOSAL — regions/triggers below for Tristan's reaction before the gen script.
- **Beat:** Beat 2 (both halves). Player controls ONLY the hero; everyone else scripted (ruled).

> Rulings folded in (2026-06-10): keep the yard BIG ("10×10 run-up-and-hit is the only
> strategy" — rejected); **3 distinct skill areas + a main sparring pit in the middle**;
> **3 enemy groups attack from the north**; more enemies + balancing pass. Camp walk =
> player-walked with trigger stops; same model continues inside the yard (walk between
> lesson areas).

---

## Intent

One big living training ground where the whole tutorial happens as movement through
*places*: each lesson has its own area, the drill converges on the central pit, and the
raid breaks in through the north fence — three lanes, three groups — turning the ground
you just learned on into the ground you defend. The yard must read at battle zoom:
stations, pit, and fence visible in frame wherever the camera sits.

## Composition (inside one big fence ring, forest north)

- **North:** forest band outside the fence; **3 breach points** in the north wall,
  spaced wide (west/center/east lanes) — aligned with forest clearings.
- **Center:** the **main sparring pit** — a sunken/ringed stone pad, the drill's finale
  and the raid's natural hold point (chokepoint geometry, defensible).
- **Three skill areas** around the pit (the lessons live here, and they are the squad's
  stations — the camp-walk characters have *workplaces*):
  - **West — the range:** straw targets along the fence (Elena's station). Teaches
    *positioning/follow-up* later; visual identity: targets + arrow racks.
  - **East — the dummy lane:** training dummies + weapon racks (Borin's station).
    Teaches *attack*; identity: dummies in a row.
  - **South — the footwork course:** agility posts / marked tiles near the gate.
    Teaches *movement*; identity: posts + chalk-marked ground.
- **South gate:** the way in from the camp (the arrival hands off here with matched
  framing). Recruits drill near the pit in the background.
- Scatter: decor on yard grass (extend the playbook's `.`-only scatter to `g`), some
  terrain variety so the interior isn't one flat texture at battle zoom.

## Regions (for the TriggerEngine)

| Region | Where | Meaning |
|---|---|---|
| `south_gate` | gate tiles | entry; matched-framing handoff from the camp |
| `footwork_course` | S area | MOVE lesson (step on the marked tile) |
| `dummy_lane` | E area | STRIKE lesson (Borin waits here) |
| `range_west` | W area | Elena's station; follow-up positioning flavor |
| `sparring_pit` | center | TOGETHER lesson + raid hold point |
| `breach_w/c/e` | 3 north wall gaps | raid entry lanes |
| `lane_w/c/e` | breach → pit approaches | enemy group paths; ally defense slots |

## The flow (one scene)

1. Enter at `south_gate` (camera matched to arrival's last frame; WALK 2.0 → ease to
   BATTLE 4.0 with HUD fade at first control).
2. **MOVE** at the footwork course → **STRIKE** at the dummy lane (Borin) → **TOGETHER**
   in the pit (Elena chains live). Player *walks between areas* (battle-move between
   lesson regions; or free-walk mode — open question below).
3. **The breach:** horn → north fence splinters at 3 points (engine `spawn` ×3 groups)
   → battle music starts → recruits + Elena/Borin (+ Lyra arriving) form up (`flip_team`
   where needed) → the raid plays out on the same ground. Hold the pit / clear the lanes.
4. Victory → Vael's coda → camp checkpoint.

## Roster (raid phase)

Hero (player) + Elena/Borin/Lyra + 3 recruits (all AI allies) vs **3 groups from the
north** — first balancing guess: 3/3/3 goblins (9 total), tuned in playtest so lanes
matter (the yard is big enough that picking which lane to reinforce is a real choice).
`[open]` exact counts/comp per group; mixed enemy types later.

## Open questions

- Lesson travel: battle-grid moves between areas, or free-walk (WalkingPlayer) until the
  breach flips it to battle? (Free-walk = warmer, more "camp life"; battle-move = teaches
  the grid the whole time.) **Lean: battle-move** — it IS the movement tutorial.
- Does the camp walk (Vael + station intros) happen on `camp_grounds` then hand off at
  the gate (current plan), or should this map extend south to include part of the camp?
- The signal-bell (Row 5 cue) — over the south gate or the pit? Lock before gen.
- Balancing pass criteria: raid should be winnable with hero + AI doing their jobs, and
  *lost* if the player feeds the hero alone into a lane.

---
*Proposed 2026-06-10 from Tristan's yard rulings. Next: gen script → render → react.*
