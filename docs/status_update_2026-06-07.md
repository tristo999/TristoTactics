# TristoTactics — Status Update (for Product)

**Date:** 2026-06-07 · **Branch:** `tutorial-battle-and-level-semantics`

## Headline

**The Act 1 opening now plays start to finish.** You can sit down and play the first
chunk of the game as one connected experience, with no broken seams between scenes —
from the abstract void intro all the way through the first real tactical battle.

## What you can play right now

A continuous opening, every step genuine (no fake-outs, no camera tricks standing in for
real movement):

1. **The void** — the existing intro (Guardian's fragmented transmissions, name entry, "Find me").
2. **The summoning chamber** — wake in a cold, dark room; walk out the door.
3. **Arrival in the camp** — a fully scripted cutscene: the hero walks out into a war camp,
   Commander Vael is mid-orders to his soldiers, notices you, comes over with a warm (a little
   *too* warm) welcome, and leads you up to the training ground.
4. **The spar** — a guided tutorial: Vael coaches the core verbs (move, attack) and the
   **follow-up combo** — the signature tactical hook — and it's actually *demonstrated live*,
   not just explained.
5. **The hinge** — mid-drill, the camp is raided. Vael flips from coach to commander
   ("...this is no drill!"), and it cuts straight into —
6. **The raid** — your first real tactical battle, on the same yard you were just drilling in,
   now breached.

## Where the systems stand

The honest scope picture, corrected against the code (some of this was previously mis-tracked):

- **Core tactics combat** — done and proven (movement, attack, turn order, enemy AI).
- **Combos (the signature verb)** — **built** (reactive follow-ups for the archer, dwarf, and
  healer) *and* now taught in the tutorial. This is the thing that makes the combat *ours*.
- **Scripted-scene / cutscene toolkit** — built and proven by the arrival cutscene; reusable
  for every future scripted beat.
- **Tutorial system** — wired (the spar gates the player one verb at a time).
- **Still genuinely unbuilt** (for later beats): bonding/relationships, expressive player
  choices, and the time-as-resource "advancing line." These are the deeper identity systems.

## Process wins (beyond the playable build)

- **Level authoring in *intent*, not tiles** — every level now carries a short spec of named
  *regions* and *triggers* ("the raid breaches here," "Vael coaches you on the pad"), so we
  design and adjust levels in meaning, and the work survives between sessions.
- **The collision idea, proven small** — the spar and the raid are *sibling maps*: the same
  yard, where the raid literally breaches the wall you drilled behind. That's the "same place,
  read two ways" pillar working at micro scale.
- A **map-generation playbook** so new levels go faster and avoid the traps we already hit.

## Honest limitations (read before judging the look)

- **No art is coming soon, and we're not faking it.** Every character is the same placeholder
  sprite, color-tinted to tell people apart (that's the accepted approach until there are real
  sprites). Environments are placeholder tiles.
- **Principle we're holding:** an honest neutral placeholder beats an abstract stand-in — a
  loose shape "representing" a thing we lack art for reads *worse*, not better. (We cut a box
  that "was" the summoning room; now we just show the wall and imply the room beyond.)
- So judge this build for **flow, pacing, teaching, and feel** — not visual polish. The design
  is fully expressible at this layer; the art gap blocks the *look*, not the *design*.

## What's next (pick-one candidates)

- **Extend the slice** — the next campaign beats (a mission or two), where bonding and the first
  expressive choices get built.
- **Deepen the opening** — chamber atmosphere, the camp's life, tighter dialogue.
- **The collision payoff** — rough out the Act 2 reading of this same camp.

*Build is on `tutorial-battle-and-level-semantics`; runnable from `opening_corridor_scene.tscn`
(full) or `summoning_room_scene.tscn` (the camp chain).*
