# TristoTactics — Map Design Process (staged)

How test maps (and real maps) get built. **Design in stages, in this order.**
Do not skip ahead — feel (decoration) before function (composition) is how the
camp map became "a dressed-up open box." References: Wargroove (walls carve
rooms/chokes), Shining Force II (elevation + geography as constraint).

## Stage 1 — Composition (the walkable skeleton)
Just the bare walkable tiles + impassable terrain. Ask only: **where can you
walk, and what are the lanes?** Output is a black-and-white skeleton — walkable
vs not. No decoration, no cosmetic terrain. If the skeleton isn't interesting
here, no amount of art saves it.

## Stage 2 — Variation → lanes & chokepoints
Add terrain variety that *constrains* movement, not just colors it:
- **Chokepoints** — where forces must funnel (a gap, a bridge, a wall mouth).
- **Lanes** — distinct routes created by obstacles, so the map is several small
  situations, not one open field.
- **Pockets sized to play** — each open space should fit a real maneuver: room
  to plug with a tank, perch an archer, tuck a healer, set up a combo. Not so
  open that every tile is equivalent (repetitive), not so tight nothing moves.
- Cover/elevation placed to *guard a lane or make a perch*, never as filler.

Test: every region should pose a *different* tactical question.

## Stage 3 — Decoration (feel, zero rules)
Inert visual variance — flowers, pebbles, bones, tufts, cracks, debris — on the
**Decor layer**, which never affects movement or terrain lookup. Adds life and
breaks repetition without touching the fight. Also: the backdrop/framing margin
(see `map_boundaries_framing.md`).

## Layer model (keep tactical and cosmetic separate)
| Layer | Role | Movement |
|---|---|---|
| BaseGrid | terrain (grass/road/stone) | walkable, has terrain type |
| Walls / Water | barriers | impassable |
| Objects | cover & props (trees = cover) | trees walkable cover; props impassable |
| **Decor** (new) | pure visual scatter | **inert — never affects movement/terrain** |

Tiles must be chosen for **function first**: a road should *be* a lane
(bounded by non-walkable sides), not a stripe painted on an open field; a ring
should *be* a chokepoint, not a cosmetic outline. Cosmetic-only terrain belongs
on Decor.

## Working method (remote-friendly)
Render each stage as a PNG (PIL preview or in-engine screenshot → `docs/maps/`)
so the composition can be judged before the next stage is layered on.
