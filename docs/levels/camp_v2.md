# Level Spec — Camp Sparring

- **Map:** `data/maps/camp_v2.map` (22×22)
- **Scene:** `scenes/levels/tutorial_battle_scene.tscn` (`tutorial_battle.gd`)
- **Beat:** Beat 2 — the tutorial battle. Tonal hinge of early game.

> This is the source-of-truth for what the level *means*. Talk about the level in
> these named terms. Triggers are tagged **[built]** (actually fires) or **[written]**
> (designed, not wired yet). Promoting a `[written]` trigger to `[built]` is the backlog.

---

## Intent

A sparring drill with the squad that gets interrupted, mid-way, by an insurgent raid —
the moment training becomes real stakes. Teaches movement → attack → the follow-up combo
during the "safe" spar, then forces it under pressure when the raid breaches.

## Composition

- **One descent:** the ledge across the north is a hard wall; the only way down from the
  woods is the **stairs gap**. The raid is funneled through it (and the fence gate).
- **The yard** is the fightable arena — fenced on all sides, gate to the north.
- **The pad** in the center is the spar floor and the natural hold point.
- **Fence** = the chokepoint the raid has to squeeze through; **trees** = cover/soft blocks
  inside the yard the squad can use.

## Regions

| Region | Rough tiles | Meaning |
|---|---|---|
| `raid_spawn_north` | woods, rows 0–4 (above the cliff) | where the insurgents enter the level |
| `chokepoint_stairs` | the `SS` gap, ~cols 10–11 row 5 | the only descent off the ledge |
| `gate_north` | fence gap, ~cols 10–11 row 7 | the breach point into the yard |
| `defensible_pad` | the `o` pad, ~cols 8–13 rows 12–14 | spar floor / hold point |
| `squad_start` | ~row 17, cols 6/11/16 | where the player squad begins |

## Roster

| Slot | Unit | Team | Role |
|---|---|---|---|
| 1 | Elena (archer) | player | squad |
| 2 | Borin (dwarf) | player | squad / the coach |
| 3 | Lyra (healer) | player | squad |
| 5,6,7 | recruits (hero.tres) | ally (AI) | spar partners → allies when the raid hits |
| E | insurgents (goblin.tres) | enemy | the raid |

## Triggers

| WHEN | THEN | Status |
|---|---|---|
| battle starts | intro dialogue (Borin/Elena/Lyra: "those aren't ours — the gate") | **[built]** as a start-of-battle event |
| all insurgents present at start | (current build spawns the whole roster up front) | **[built]** (simplification — see below) |
| all enemies defeated | victory dialogue ("that's the last of them") | **[built]** |
| player enters `defensible_pad` | Borin coaching line (teach the follow-up) | **[written]** |
| `turn >= 3`  OR  any unit enters `chokepoint_stairs` | **raid begins:** spawn insurgents @ `raid_spawn_north`; recruits flip spar→ally; tense music | **[written]** |

## Current build vs. intended design

- **Now:** everyone spawns at once; the intro dialogue *says* the raid already breached. It's
  a single-phase fight. Functional, but the spar→raid hinge isn't expressed in play.
- **Intended:** a **spar phase** first (squad + recruits only, drilling on the pad — the
  `defensible_pad` coaching trigger lives here), *then* the **raid trigger** spawns the
  insurgents from `raid_spawn_north` and flips the recruits from spar-partners to allies.
  This is the "training becomes real" beat and the reason the level exists.

## Open questions

- Raid fires on a **turn clock**, on **position** (someone reaching the stairs), or both?
- Do the recruits start as a *neutral* spar team and flip to `ally` on the raid (the R7 flip),
  or just start as allies (current)? The flip sells the tonal turn harder.
- Should the south edge (rows 20–21) become walkable retreat space, or stay a soft border?

---
*First level spec — the worked example for the regions/triggers authoring convention
(see `docs/map_generation_playbook.md` §8). Written 2026-06-06.*
