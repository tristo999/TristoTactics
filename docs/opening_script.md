# The Opening — Script & Staging (corridor → raid)

**What this is:** Workstream A of the opening cohesion pass — the whole opening as ONE
story: staging (where every character is), camera direction (one grammar), and full
draft dialogue. Everything else (scene work, triggers, maps) implements this document.

**Status: DRAFT.** All dialogue is mine for Tristan's edit — keep/kill/reword freely.
Canon checked against `bible_02_cast.md` / `bible_03_act1.md`; canonical Vael lines from
the bible are used verbatim where they exist. Names Elena/Borin/Lyra = working names.

---

## Camera grammar (global, binding)

| Register | Zoom | Used by |
|---|---|---|
| **WALK** | 2.0 | corridor, chamber, camp arrival + camp walk (CineCam conforms: 1.7 → 2.0) |
| **BATTLE** | 4.0 | spar lessons, raid (spar's 4.5 retired) |

**Rules:** (1) Never cut between registers — *bridge*: the one zoom change in the whole
opening is a slow 2.0 → 4.0 ease at the spar's "hands on the controls" moment, with the
battle HUD fading in during the ease. That's the deliberate "it becomes a tactics game"
beat. (2) **One camp:** the spar/raid yard is *the same place* the arrival walks through
— same map family, same landmarks on screen. No teleporting to a lookalike. (3) Music is
continuity too: **camp theme** from arrival through the whole spar; **battle music starts
at the breach** — the audio *is* the coach→commander flip.

## Where everyone is (staging — "places for all the characters")

When the hero steps out of the chamber, the camp is mid-morning busy (`camp_grounds` regions):

| Who | Where | Doing |
|---|---|---|
| **Vael** | `gathering_commons`, near the fire pit | finishing orders to two pickets |
| **Borin** | armory racks on the `ring_road` (east side) | hauling/checking gear, humming |
| **Elena** | the west fence line (`west_yard` edge) | shooting at a straw post, alone, back to the camp |
| **Lyra** | infirmary tent (`east_yard`) | wrapping a soldier's wrist, murmuring her invocation |
| **Recruits** (Sten/Wynn/Bram) | the sparring pad | drilling sloppily, audible counts |
| **Extras** (tinted soldiers ×4–6) | fires, pickets, one crossing the ring road with wood | ambient loops — the "well-oiled machine" |

---

## SCENE 1 — The corridor (as built)

Unchanged. Camera WALK 2.0. Outstanding: the swirl-shader hole, two placeholder lines.
The voice, the interception, *"{Name}… Find me…"*, white-out.

## SCENE 2 — The chamber (the first silence)

**Camera:** WALK 2.0. **Music: none.** Cold room tone only.

The corridor never left the player alone — this room is the first silence. Wake in
near-black ON the summoning circle, faint light pooled on it (the circle must *register*
— it's a Row 5 cue). Slow light reveal (corridor light-radius tech, no white curtain).
The player waits a beat for the voice. It doesn't come. One door, light leaking under
it. No dialogue, no prompt. Walk out.

## SCENE 3 — Arrival: the warm hand (the lie, delivered)

**Camera:** CineCam at WALK 2.0 throughout. Hero walks out through the south wall
doorway (as built). The camp is ALIVE per the staging table — the pan up the main
street passes fires, pickets, the wood-hauler. Competence on every side; that's what
makes the lie believable.

Vael is mid-orders (as built), notices, comes down.

> **VAEL:** You actually made it. I was starting to wonder.
> **VAEL:** Easy — breathe. The crossing takes it out of everyone the first time.
> *(beat; he looks the hero over, unhurried, like the next item on a list)*
> **VAEL:** You must be a little confused. That's fair. So — the short version, and the
> rest over a hot meal.
> **VAEL:** This is an Authority camp, and the Authority is why you're standing here.
> We reached across worlds for you. Took the circle's keepers the better part of a year
> to find you and pull you through.
> *(the hero says nothing; Vael smiles slightly)*
> **VAEL:** Not a talker. Good. Talkers die of it out here.
> **VAEL:** There's a power east of us — the kingdom — and it has been bleeding this
> land for years. Burning the borderlands. Killing whoever it can't keep. We've held it
> off about as long as holding works. What comes next needs something it can't match.
> *(he puts a hand, briefly, warm, on the hero's shoulder)*
> **VAEL:** That's you. The Authority called, and you came, and that makes you ours —
> and us yours. Welcome to the war, friend.
> **VAEL:** Come. Walk with me — you should meet the people you'll be fighting beside.

*(The lie, complete: the Authority summoned you; the kingdom is the enemy; you are its
champion. No artifact, no voice, nothing for the half-felt "find me" to attach to.)*

## SCENE 4 — The camp walk: meeting the squad (full conversations)

**Camera:** WALK 2.0; the CineCam leads up the main street; each stop is a small framed
two-shot. Vael walks the hero to each companion's *place* — introductions are his
instrument, and he plays it well.

**Stop 1 — Borin, at the armory racks:**

> **VAEL:** Borin. Put the rack down, you'll want to see this.
> **BORIN:** *(turning, a breastplate under one arm)* By the deep roads — so the circle
> works after all. I'd money on it cooking you.
> **VAEL:** Our new champion. Borin's the wall you'll be standing behind.
> **BORIN:** Wall, doorstop, furniture generally. *(grins, raps his chest)* Dwarf-made —
> they don't make us anymore, so mind the antique. You take a hit out there, that's my
> failing, not yours. Remember that.
> **VAEL:** He means it, unfortunately.
> **BORIN:** Aye, unfortunately. *(to the hero, quieter, sizing him kindly)* You look
> half-drowned, lad. Eat something before he marches you. They never eat something.

**Stop 2 — Elena, at the west fence line:** *(she doesn't hear them come up; she
looses three arrows — flat, mechanical, perfect — into the same fist of straw)*

> **VAEL:** Elena.
> **ELENA:** *(startled out of the trance — drops the fourth arrow, fumbles, drops it
> again)* C-commander! I wasn't — these are the practice — I signed for them, there's
> a ledger —
> **VAEL:** *(mild)* The summoned one. Came through this morning.
> **ELENA:** *(a small horrified pause as she realizes who she's flailing in front of)*
> Oh. Oh no. I mean — welcome! I mean — *(deep breath, very fast, eyes down)* — Elena.
> Sharpshooter, third file. It's — yes. Hello.
> **VAEL:** Best eyes in the camp. You'll want her at your shoulder out there.
> **ELENA:** *(barely audible)* …the shoulder's good. I — yes.
> *(as they walk on, she retrieves the dropped arrow, puts it through the straw without
> looking, and goes back to being mortified)*

**Stop 3 — Lyra, at the infirmary tent:** *(wrapping a picket's wrist; she finishes the
murmured invocation before looking up — the blessing first, always)*

> **LYRA:** —and by its light be mended. *(looks up; her warmth is immediate and total)*
> Commander. And — oh. It's *you.*
> **VAEL:** Lyra keeps us standing. Lyra — the Authority's champion.
> **LYRA:** I know what he is. *(to the hero, radiant, taking both his hands without
> asking)* The Authority's own light reached across worlds and chose to carry *you*
> back. Do you understand what an honor it is to be what it wanted? …No. You will.
> **VAEL:** *(dry)* She'll pray on your behalf until you do.
> **LYRA:** Someone must. *(releasing him, already turning back to her soldier, serene)*
> Come bleeding, come broken — the blessing doesn't run out. That's the *point* of it.

*(Her piety lays the lie's second coat — and plants her entire arc in one invocation.)*

## SCENE 5 — The spar (Vael pulls two aside)

**Camera:** arrive at the yard gate in WALK 2.0 — the recruits visible drilling on the
pad, the camp behind (one place, one shot). Vael calls over the two we just met:

> **VAEL:** Borin. Elena. With me — bring the blunts.
> *(they peel off the drill; the recruits keep counting in the background)*
> **VAEL:** First things first. Let's see whether the circle sent us a soldier or a
> sack of turnips.

**The handover:** as control passes to the player, the camera **eases 2.0 → 4.0** and
the battle HUD **fades in during the ease.** This is the one register change in the
opening — the moment it becomes a tactics game, done on purpose.

**The drill — the player controls the HERO** (the student, not three strangers).
Partners are passive during lessons (no AI turns — the lesson owns the turn flow):

1. **MOVE.** Vael: *"Ground first. Take that mark."* → move to the marked tile (region
   trigger). Borin, planted mid-pad, thumps his chest: *"Then come introduce yourself!"*
2. **STRIKE.** Strike Borin (blunted, nonlethal — he wants it). On the hit —
   **BORIN:** *"HA! Good weight! Felt that in me teeth. Again — but bring a friend."*
3. **TOGETHER (the signature).** Vael positions Elena at the hero's shoulder: *"Alone
   you're a blade. Beside someone, you're a squad. Strike — and watch her."* Hero
   strikes Borin → **Elena's follow-up chains, live** (engine-detected, never
   false-praised). She goes flat for exactly the length of the shot — *"…clear."* — then
   instantly flustered: *"w-was that — did I overdo — Borin I'm so sorry —"*
   **BORIN:** *"That's the thing! That's the whole war, right there!"*
   **VAEL:** *"A follow-up. Stand close, move in concert, answer each other's strikes.
   Learn nothing else today, learn that."*
4. **Lyra arrives** to fuss over Borin's bruise — invocation, the bruise fades:
   **LYRA:** *"—and by its light be mended. Honestly, you ASK them to hit you—"*
   *(her reactive heal, demonstrated in fiction.)*

**The breach (in-scene, same yard):** a horn — wrong pattern. The white flash. The
north fence SPLINTERS on screen — insurgents pour through the lanes (engine `spawn`).
**Battle music starts here** — the first time we've heard it.

> **VAEL:** …Those aren't ours.
> **VAEL:** Insurgents — through the north fence! Up, ALL of you — blades out, this is
> no drill!
> **VAEL:** Recruits — fall in behind the champion. Elena, Lyra, Borin — you know your
> work. MOVE!

Recruits flip to your side (`flip_team`); Lyra joins the squad; the drill becomes the
raid **without a cut** — same map, same camera, the marked pad you drilled on is now
the ground you hold. *(Plant discipline: the skirmish must end as a forgettable win —
no ominous scoring. The cracked signal-bell hangs over the yard gate — place it; it's
the Row 5 landmark.)*

## SCENE 6 — The raid (the battle, then quiet)

**Camera:** BATTLE 4.0, party-centered (as built). Existing intro/victory lines mostly
keep, now landing on people we've met:

> **BORIN:** Backs to the pad! Let 'em break on us — Elena, Lyra, on me!
> **ELENA:** *(flat — the trance)* …The lanes are mine. Nothing gets past.
> **LYRA:** Stay standing and I'll keep you that way. Go.

Victory (keep, one addition — Vael's coda, warmth back on like a switch):

> **LYRA:** That's the last of them. Everyone still on their feet?
> **BORIN:** On my feet and then some. Fine shooting, Elena.
> **ELENA:** …I — yes. We held.
> **VAEL:** *(arriving, unhurried again, surveying the bodies without expression for
> exactly one beat too long — then the smile)* Well fought. First morning in a new
> world and already earning your keep. Come — that meal I promised.

---

## Build notes (what implements this)

- **One map:** spar + raid rebase onto one yard that *is* the camp's arena (extend
  `camp_grounds` family / restyle `arena_*` to match and share landmarks). Signal-bell
  placed over the gate. Circle staged in the chamber.
- **Spar rebuilt on the TriggerEngine:** lessons = region/attack triggers; partners
  passive in drill (no AI interleave); breach = `spawn` + `flip_team`, in-scene.
- **Hero becomes a battle unit** (player-controlled, `hero.tres` real stats) — new.
- **Camera:** CineCam 1.7→2.0; spar 4.5→bridged 2.0→4.0 + HUD fade; raid 4.0 keeps.
- **Audio:** camp theme (new key), battle music gated to the breach; horn SFX.
- **Camp life:** staging-table extras (tints + idle loops), fires, infirmary tent.

## For Tristan's ruling

1. All dialogue above — edit freely; especially the lie's wording and Lyra's theology.
2. ~~The hero fights~~ — **RULED (2026-06-10): the hero is the ONLY unit the player
   controls through the spar AND the raid; everyone else is scripted/AI.** Implemented:
   hero = sole player unit, squad/recruits = AI allies, follow-ups fire across friendly
   teams, partners parked (`ai_enabled=false`) during the drill.
3. Elena + Borin as the pulled pair, Lyra at the tent (her heal demoed on arrival at the
   spar) — or a different pair?
4. The kingdom stays unnamed ("the kingdom") until the name is ruled (slice gate 5).
5. Vael's victory coda (the one-beat-too-long look) — flavor or too marked?
