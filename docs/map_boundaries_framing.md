# TristoTactics — Map Boundaries & Framing (Design Writeup)

A working document capturing the map-boundary discussion: what the problem
actually is, the options on the table, their trade-offs, and a recommendation.
Reference points: **Wargroove** (loved the scale + the framed backdrop),
**Fire Emblem Three Houses** (terrain-dense maps), **Shining Force** (battles as
located set pieces). This is a **decisions-pending** doc, not locked canon.
Draft date: 2026-06-05.

> **Status / relation to current build (2026-06-06):** This concerns map *framing*
> (void + boundary + camera), which is downstream of the composition work. We've
> since built: the text-map system, a baked editable camp map
> (`docs/maps/camp_training_grounds.png`), and walkable tree cover. The current
> camp map's perimeter is a plain wall rectangle on raw background — i.e. it has
> exactly the "boundary floating in void" problem this doc addresses. Nothing here
> is implemented yet. (Minor data note: separate research estimated FE3H maps
> larger than ~12×12 — closer to ~25–35 per side, with a denser playable core;
> the "terrain-dense" point stands regardless.)

## The actual problem (restated)
The early camp map felt small and "floating in gray void." Diagnosis: that feeling
was **not** primarily a size or camera bug. It was a stack of three separate issues
we kept blurring together:

1. **Composition** — the map was a box: ~90% open floor, one lane (forward), no
   chokepoints, no meaningful cover, edges in void. A big box plays the same as a
   small box — repetitive — because every tile is equivalent. **This is the
   disease; the void was a symptom.**
2. **The void** — past the playable area was raw engine gray, because the small
   map fully fit on screen with room to spare (PC-first, high resolution).
3. **The boundary** — a hard fence rectangle floating in that gray, which
   announces "small box, nothing beyond."

A good tactics map is defined by **constraints on movement** (chokepoints, lanes,
cover, elevation, asymmetry, objectives), not by size. Big is good if it means
**more distinct regions and routes** — a landscape of small tactical situations
strung together — not more empty floor.

*This doc is only about #2 and #3 (void + boundary). Composition (#1) is its own work.*

## "Boundary" is really three separate decisions
We kept saying "the boundary" to mean three different things. Each needs its own answer.

### Decision A — What stops the units (the gameplay edge)
- **Invisible hard edge:** the grid simply ends; tiles beyond don't exist. (What Wargroove appears to do mechanically.)
- **Impassable terrain:** the perimeter is a terrain type units can't path into (water, cliff, dense forest, wall).
- **Flagged out-of-bounds:** tiles exist visually but are marked non-walkable.

### Decision B — What the camera does at the edge (the view boundary)
- **Hard-limited** (`Camera2D.limit_*`): camera stops so the playable edge sits at the screen edge; player never sees past the world.
- **Slight over-scroll:** camera reveals a deliberate margin (a framed border or a band of non-walkable world) before stopping.
- *Settled in discussion:* camera must be limited somewhere. Where it stops depends entirely on Decision C.

### Decision C — What's visually past the playable area (the backdrop) — THE BIG ONE
This is the question everything else defers to.

**Option A — Framed border (the Wargroove "tan parchment" look).** Past the grid is
a deliberate decorative frame; camera over-scrolls slightly to show it as intentional margin.
- *Pros:* cheapest to build; instantly kills the void; maximum readability (clean rectangle); liked on sight.
- *Cons:* announces "this is a game board / a map" — breaks immersion slightly; tonally suits Wargroove's bright boardgame feel, potentially at odds with TristoTactics' darker, immersive tone.

**Option B — Diegetic world continues, hard-cut at camera limit (the Fire Emblem look).**
World keeps going visually (denser woods, far bank, camp sprawl) for a margin, then the camera hard-limits.
- *Pros:* fully immersive — feels like a real place; the boundary *means* something (cliff/forest/river).
- *Cons:* most authoring effort (paint convincing non-walkable world past every edge); camera limit must land on a composed vista; readability risk (impassable-edge vs tactical terrain — the Wargroove reef-vs-decoration trap).

**Option C — World continues, then a vignette/soft frame (the blend).**
World sprawls past the grid; a subtle darkening/vignette at the outer margin reads the edge as deliberate without a hard frame.
- *Pros:* immersive and void-proof; vignette is cheap and tone-appropriate (darkened edges suit a darker game); Wargroove fullness without the boardgame-ness.
- *Cons:* more setup than A (still need some off-grid world + a vignette pass); softer than a crisp frame.

## Terrain boundary vs. invisible hard edge (the core tension)
Stated preference: **terrain-as-boundary is more elegant, just harder.** Both halves are true.
- **Why elegant:** the edge means something; and one system does three jobs — the same terrain that bounds the map also shapes the fight (chokepoints/lanes/cover) and fills the void.
- **Why harder:** must author convincing non-walkable world past the playable area everywhere; camera stop must land on a composed vista; boundary terrain must be visually distinct from tactical terrain (the reef-vs-rock cautionary tale).

### The hybrid (likely the real sweet spot)
**Terrain that visually bounds the world + an invisible hard edge doing the mechanical
stop underneath.** Very likely what Wargroove actually does: the visible boundary is
terrain (water) so it *feels* like a world that bounds you, but the mechanical stop is
a hard edge so you don't have to perfectly author traversable-vs-not across a huge
margin. The water past the island doesn't need to be "real" — it just needs to *look
like the reason you stop.*
- *Pros:* elegant appearance at a cheap mechanism; sidesteps the hardest authoring cost; player never perceives them as two things.
- *Cons:* the visual boundary terrain must read as genuinely impassable; it's "cosmetic honesty," not true terrain-bounding — but the player can't tell.

## De-risking strategies (apply to any choice)
- **Per-map, not universal.** Signature maps (e.g. the bridge) earn the full elegant terrain treatment; lesser maps lean on a cheaper frame/vignette.
- **Start cheap, upgrade hero maps.** The tutorial camp can ship a simpler boundary now; the bridge gets the full treatment where it pays off.
- **Decoration vs. terrain layering (the Wargroove lesson).** Keep a clean tactical grid (terrain-with-meaning) and a separate, mechanically-inert decoration layer for density/life. The void and "box" feel come mostly from missing the decoration + composition layers, not from map size.

## Recommendation
- **Decision A (units):** go **hybrid** — terrain visually bounds the world, an invisible hard edge is the mechanical stop. Most elegance for least cost.
- **Decision B (camera):** **limit the camera**, with a small deliberate margin so a tile or two of non-walkable world/backdrop shows past the last playable tile before it stops. Never reveal raw void.
- **Decision C (backdrop):** lean **Option C (world + vignette)** over the tan frame for tone — TristoTactics is darker/more immersive than Wargroove, so a visible board frame likely fights the mood while a vignette kills the void with immersion intact. *Caveat:* Option A is far less work and was liked on sight; if simplicity wins or the tone reads fine, it's legitimate.

## Decisions (settled 2026-06-06)
- **Decision A (units):** hybrid — terrain visually bounds the world, invisible hard edge is the mechanical stop.
- **Decision B (camera):** limit the camera with a small margin; never reveal raw void.
- **Decision C (backdrop):** **Option C — world + vignette.** Tone call settled toward
  *"I'm looking at a place in the world"* (immersive), not a tactical board. Real terrain
  spills past the playable grid; a soft vignette darkens the outer margin.
- **Scope:** **global** — build one framing system applied to all maps (not hero-maps-only).

## Implementation sketch (per the decisions)
1. **Backdrop margin** — every map gets a band of non-walkable backdrop terrain past
   the playable edge (woods/water/sprawl), with an invisible hard edge at the playable
   tiles underneath. In the text-map system this is an authored/auto-generated margin.
2. **Camera limits** — a reusable component sets `Camera2D.limit_*` from the tilemap's
   used rect + a small margin, so a tile or two of backdrop shows before the stop.
3. **Vignette** — a screen-space CanvasLayer overlay (shader/texture) darkening the
   edges; tone-appropriate, cheap, global.
