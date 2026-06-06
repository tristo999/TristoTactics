# TristoTactics — Story Beats Plan

The **ordering layer.** The collision ledger is the design spine (the
scenes-that-happen-twice); this doc is the **sequence** — every beat in order,
both acts, with collisions placed in time, retrieval cues planted at the right
moments, and characters/gameplay noted. It is NOT a return to the old retired
21-beat "LOCKED DECISION" bible; it's the connective tissue the ledger always
implied you'd need, built on current canon.

**Source of truth for *why*:** `overview.md` / the four-part bible
(`bible_01_world` … `bible_04_act2`) / `collision_ledger.md`. This doc must not contradict them; where it adds detail,
it inherits their `[settled]/[open]` discipline.

Legend: **[settled]** firm · **[for now]** working answer, not canon ·
**[open]** undecided, do not assume.

Last updated: 2026-06-01


## How to read this

Each beat lists, where relevant: what happens · what the player *believes* in the
moment · collisions planted or paid off (→ ledger row) · retrieval cues · which
characters appear/recruit · gameplay shape · status.

**The whole engine:** Act 1 plants, Act 2 pays off, the player connects it
themselves, late. So Act 1 beats are mostly about planting cheap, sincere,
unmarked moments; Act 2 beats are mostly about recontextualizing them without
ever announcing the repeat.


## Collision pairing map (the wiring)

Which Act 1 beat collides with which Act 2 beat. Load-bearing — read this before
the beats.

| Ledger row | Act 1 (plant) | Act 2 (payoff) | Retrieval cue |
|---|---|---|---|
| **5 — the camp you defended** | A1·B2 training raid (you repel "insurgents") | A2·B2 you *sent* that raid as a distraction; you're inside the emptied camp | camp landmark (e.g. cracked signal-bell) |
| **2 — the unheard face-off** | A1·B4 shadowed figures, garbled threats, cut down | A2 mid — three-stage: you're the figure, unheard | the garbled line (threat → clear) |
| **1 — the bridge** | A1·B5 bridge collapses, you curse the saboteurs | A2 mid — you set the charges, timed to kill fewest | red bridge in the rain |
| **3 — the comrade boss** | A1 mid — an unremarkable enemy commander you beat and celebrated | A2 mid — the one who held the line; was your comrade | the boss's weapon / stance / one line |
| **4 — the kind trap [open]** | A1 — a kindness the game rewarded | A2 — it was the cruelest thing you did | TBD |

Note: the collisions are spaced out. Act 2 is mostly its own campaign (gathering,
sabotage, the line advancing) with these as **peaks, not texture.**


## OPENING — built [settled]

Void walk, Guardian's fragmented transmissions ("Are you there?…" → "…follow the
path…" → "…this world needs you…"), name entry, the warm "Welcome," the
interception (screen break, "No… It's too late…"), the final "{Name}… Find me…"
white-out. The hero wakes redirected to the Authority's camp.

- Plants the **master cue:** the texture of the Guardian's voice — fragmented,
  glitched, reaching through interference. Every Act 1 glitch recalls this; the
  full sentence at the capital pays it off.
- "Find me…" is now literally true and load-bearing: the Guardian is still there
  to be found, at the capital, and Act 1 is the hero being marched toward exactly
  that.
- **[open]** the Phase-3 "companion / Act 2 vision" placeholder (code TODO,
  undocumented). Decision pending: cut it, or promote it to the game's
  largest-scale retrieval cue (unreadable flashes planted before Act 1, paid off
  at the very end). Must NOT read as parseable foreshadowing.


## ACT 1 — THE LOYAL BLADE

Through-line: the hero is the weapon the Authority marches toward the one door it
could never open, certain it's righteous, moving toward the Guardian's voice the
whole time without knowing it. No permadeath (see `systems_design.md`) — downed
units are critically injured, back next mission. The one authored exception is
Beat 7.

### A1·B1 — ARRIVAL [settled, build 🟡]

Hero wakes in the summoning chamber (Authority ritual gear, signs of a violent
interception). Walks out into an active camp. Vael approaches, unhurried — "You
actually made it. I was starting to wonder. You must be a little confused."

- **Player believes:** *the Authority summoned you* to be its champion — a warm, competent, righteous power that made you. No kingdom-call, no artifact, no voice to chase; the half-felt "find me" has no object the empire allows (the player holds that thread, not the hero).
- **Gameplay:** introductory, no combat.
- **Plants:** Vael's warmth (the whole Act 1 lie, in one face). The summoning
  circle the hero stands on (recovered in A2·B2 when the Act 2 party passes it).

### A1·B2 — TUTORIAL / TRAINING [settled, build 🟥]

Two-phase. **Phase 1 sparring:** Vael coaches; teaches the grammar of combos (the
basic follow-up — stand near each other, chain in). Nonlethal, teaches core
verbs. **Phase 2:** "insurgents" raid the camp; first lethal combat; Vael's
framing flips coach→commander ("they came for you — defend yourselves"). The
first real combos land here, in the live fight.

- **Player believes:** unprovoked kingdom aggression against a soft target.
- **→ Collision row 5 (plant).** The raid is a distraction the Act 2 party will
  later send. Both parties are here at once, separated by the walls — Act 1 never
  knows.
- **Cue (plant):** the camp landmark. Lock it before this map is built.
- **Second cue (plant):** Vael teaches you combos. The monster arms the bond the
  game will later exploit — poison only in retrospect.
- **Companions / recruiting [open]:** which companions are present and how they
  join is undecided — possibly *all* of them are here for introductions, possibly
  a smaller starting set with the rest recruited across B3. Resolve when the cast
  and recruit order are pinned.
- **Gameplay:** tutorial → first lethal battle.

### A1·B3 — EARLY CAMPAIGN [settled, build ⬜]

Missions against kingdom "insurgents." Party establishing, bonds building, camp
life. First Guardian glitches begin — subtle, dismissed as artifact interference
per Vael.

- **Player believes:** a righteous campaign with strange harmless hiccups.
- **Cue (plant, cheap):** establish the language of the garbled-figure / glitch
  early and low-stakes, so the filter is fluent before it matters.
- **Recruiting window [open]:** the earliest-designed companions (Archer,
  Priestess/Healer) and likely the dwarf land in this stretch — *unless* the
  cast is introduced all at once at the tutorial (see B2). Exact order open.

### A1·B4 — SHADOWED FIGURES [settled, build ⬜]

Cloaked figures appear in a battle; movement unusual; their shouts come through
garbled as threats. Authority labels them saboteurs; party accepts it; you cut
them down and move on.

- **→ Collision row 2 (plant).** These are the Act 2 party. The lie renders them
  as sneering monsters.
- **Cue (plant):** the exact garbled line — heard as a threat here, heard clear
  from the other side in Act 2.

### A1·B5 — BRIDGE INCIDENT [settled, build ⬜]

A bridge comes down mid-mission, in the rain — and across the broken span you see
them: cloaked figures on the far side, watching. **The first time the two parties
truly face each other**; no contact, the gap uncrossable, and you're too war-worn
to recognize yourselves. The Authority calls it sabotage; you curse them.

- **→ Collision row 1 (plant).** The Act 2 party brought it down. This is also the
  **slice's capstone image** — the slice ends here, on the stare across the gap
  (see `slice_spec.md`).
- **Cue (plant):** the red bridge in the rain. Build the map as a *territory
  boundary* (the Act 2 objective sits mostly on the far side), not a symmetric
  arena, so it's reusable with inverted objectives for the payoff.

### A1·B(mid) — TOWN MISSION [settled, build ⬜]

An Authority operation in a civilian settlement; casualties; the first visible
cost of the war, framed and rationalized by Vael.

- **Player believes:** regrettable necessity.
- **Candidate home for:** the Priestess's temple-evidence thread (a destroyed old
  temple near/under the town — she explains it away); and/or collision row 4 (the
  kind trap) **[open]**.

### A1·B(mid) — THE CELEBRATED KILL [settled concept, build ⬜]

An unremarkable enemy commander, beaten in a standard mission. Victory sting, XP,
a companion's "nice work." The player barely looks at the face.

- **→ Collision row 3 (plant).** Non-negotiable: must read as a forgettable win —
  no ominous scoring, no lingering camera, no "that felt off." The forgettability
  is the weapon.
- **Cue (plant):** the commander's weapon / stance / one line.
- **[open]** whether the Act 2 payoff is a party member or — likely cleaner — an
  Act 1 NPC you trusted (sidesteps the death/roster tangle, hits as hard).

### A1·B7 — THE CHOICE [open — do not assume]

**Placement (revised 2026-06):** this happens *at the capital, inside THE TURN
below* — not a mid-campaign beat. The save-power is the Guardian breaking through
at the capital (its first true gift), which is *why* the hero can reach only one.

Two of the hero's highest-bonded companions fall. **The only settled thing: the
player must choose which one to save.** The other is **presumed dead** — the
player believes they lost them. (Truth, revealed in Act 2: the Authority took
them alive and reforged them into the Unchosen — see below.) This is the authored
exception to no-Act-1-death.

This is the game's most personal mechanic: the player's own freely-built, uneven
bonds turned against them. Each playthrough's worst moment differs.

**[open] — parked on purpose:**

- The **save mechanism**: whether a fragmentary Guardian power is involved, or the
  hero is by then close enough to the Guardian to access it, is a question for
  when this beat is designed.
- Is the choice between two **bonded companions** (highest ceiling, leans fully on
  player-authored love) or two recurring **lightly-bonded NPCs** (lower ceiling,
  far cheaper, dodges roster/death tangles)? Strong feeling on both sides; not
  settled.
- The Unchosen's Act 2 role (recurring antagonist → defector) is what makes the
  companion version expensive (six-way authoring). Cheaper paths: write the role
  **character-agnostic** (the empire reforges whoever it takes — on-theme), or let
  the loser simply be gone and let Vael carry the Act 2 antagonist load. Decide
  the consequence before the choice.

### A1 — THE TURN (ending) [settled]

The march reaches the capital. The Authority **discards the hero** — stops
jamming the connection, not because the hero broke free but because it wants the
anguish. The Guardian's first clear words land in the instant the hero realizes
they doomed it: reunion and guilt in the same breath. **Here the Choice fires**
(A1·B7 above): an orchestrated strike on the hero's two most-bonded; the
Guardian's first gift — a surge of bent time — reaches only one. You save one;
the other is taken, and you are meant to believe them dead. The Authority takes
the core →

- manifests its **true form** (the final boss is the empire unmasked), and
- opens a **door** through which an **endless legion** begins to come.

In Act 1, **the hero opens that door.** The Guardian sends a fragment forward
through time; the Authority sends the Unchosen Companion forward to hunt. The
party loses. Cut to Act 2.

**Faith note:** this is the betrayal that finally forces the Priestess's faith
conflict fully open — all the temple/doctrine evidence she shelved across Act 1
crashes in at once. Per the world bible, faith *erodes and fights back* rather
than snapping clean, and her **full recovery is gated on her personal side
quest** (the discovery that her religion's real god was never the Authority,
only displaced by it). The capital is the crack, not the cure.

---

## ACT 2 — THE FRACTURED BLADE

Spine: the party lived the ending, so they race to gather what's needed — mostly
**people** (the final-battle roster) — across a **shrinking map** as the
Authority's line advances. The door opens regardless (the loop holds); the point
is to be **ready on the other side** this time. Mostly its own campaign;
collisions are peaks. The player now knows — but the game never announces the
repeats. Recognition is committed by the player, late.

Act 2's mission texture (the "looks evil from Act 1, was salvation" pattern — the
player's relationship to harm has inverted): examples worked out earlier —

- burn a supply depot (A1 reports sabotage; the supplies were poisoned and would
  have killed a village);
- assassinate an Authority officer (looks like terrorism; he was about to expose
  and execute the kingdom's hidden resistance);
- the bridge (A1 reroutes and curses the enemy; it stopped reinforcements from
  reaching a town in time to massacre it — this is collision row 1).

The Act 2 victory framing: not "defeat the enemy" but "get out without destroying
who you used to be." The enemy is you.

### A2·B1 — ARRIVAL (pre-war) [settled, build ⬜]

Party arrives **at the capital, at the Guardian, before the war reaches it** —
the Guardian completes the summoning, landing the throw that missed. The
connection is no longer jammed: for the first time the party and the Guardian are
on the same side. They carry the fragment, now understood (vs. Act 1's blind
flickers). Establishing mission; new objective grammar (gather, sabotage, prepare).

### A2·B2 — MARGINS + CAMP INFILTRATION [settled, build ⬜]

Sabotage operations begin across fronts. **Key op → Collision row 5 (payoff):**
the party sends the small loyalist distraction that pulls the Act 1 party outside
(the very raid of A1·B2), slips into the emptied camp, **overhears Vael unmasked**
(bored contempt for the kingdom's defense; an offhand "band of misfits" aside
about the incoming hero) — cut off mid-sentence by the summoning flash they
cannot stop — watches his performance switch back on as he leaves to greet the
hero, and retrieves the confiscated item (arrived with the hero at the original
summoning; never shown in Act 1). They pass the summoning circle and recognize
it. Clock = the Act 1 battle outside; when it ends, the window closes.

- **Cue (recovered):** the camp landmark.
- **[open]** what the item is (tied to the Guardian's intent; may touch the
  keystone).

### A2 (mid) — THE BRIDGE [settled, build ⬜]

**Collision row 1 (payoff).** The party sets the charges and times the detonation
to kill the fewest inside a fall that was always going to happen. The Act 1 party
witnesses the smoke and curses them. You earn the condemnation you already
watched yourself deliver.

- **Cue (recovered):** red bridge in the rain. **Gameplay:** mercy-under-
  constraint as a timing/positioning problem.

### A2 (mid) — THE UNHEARD FACE-OFFS [settled, build ⬜]

**Collision row 2 (payoff)** — the three-stage arc (see ledger):

1. **Bargaining:** hoods down, own voices, shouting — it fails, the filter holds.
2. **Refusing anyway:** shift from words to the fragment — reaching costs the Act
   2 hero present-tense safety (the "grief verb").
3. **The one that lands:** the hero pushes a single fragment backward — it
   surfaces in Act 1 as a glitch the hero already dismissed. It works, and it
   changes nothing. Triumph and futility are the same event.

- **Cue (recovered):** the garbled line, now heard clear.
- **Buried gift:** some of the "voice that asked them to find it" was the hero's
  own future self, reaching back. Never stated.

### A2 (mid) — THE COMRADE BOSS [settled concept, build ⬜]

**Collision row 3 (payoff).** The figure the Act 1 party celebrated killing was
your comrade (or trusted NPC — see A1 plant), who peeled off to hold the line and
buy you time, holding back your own past self. Consider playing the kill
off-screen — reported by absence — since the player already saw it from the
winning side. No speech, no foreknowledge, just grief.

### A2 — THE GATHERING THREADS [mix]

Woven through the shrinking-map campaign:

- **The dwarf finds his people alive** in the mountains at the kingdom's edge
  **[settled concept]** — the bereavement lie breaks; the family + the mountains
  turn his Act-1 "I'm lesser" dive into the Act-2 "I am a dwarf, these are my
  people" dive. His found kin likely join the final-battle roster (a reunion you
  then must spend).
- **Loved NPC rescue [open identity]** — saved from a fate witnessed in Act 1;
  ends up on the kingdom flank.
- **The Warlock arc [for now]** — bound by pact to a dark god as a disposable
  orphan; the empire always meant to let the god collect (he has already lived the
  discard, before the game begins). Reached deeply, the party gives him the
  strength to **break the pact**; reached lightly, he at least starts looking for
  the way out. His power is genuinely dark, not mislabeled-divine. *Distinct from
  the undesigned Wizard — the party has both.*
- **The roster is the shopping list:** every ally gathered is someone who will
  stand (and likely fall) at the finale.

### A2 — VAEL [settled]

Unmasked (a scene of his quiet, routine cruelty, observed from shadow —
escalating from the words overheard in B2 to action) → Final confrontation (he
finally identifies the party, fights from wounded pride, dies a mid-Act-2 boss,
never learns they time-traveled).

### A2 — THE UNCHOSEN [open — see A1·B7]

Presumed dead since Beat 7, the Unchosen is revealed alive — taken and reforged
by the Authority, leading a special force hunting the party as traitors. Pursues
through Act 2; at the revelation moment is cornered on the party when the
Authority becomes the monster, witnesses it directly, lets them go, defects,
brings forces over. (All contingent on the A1·B7 resolution and the chosen
authoring approach.)

### A2 — THE REVELATION MOMENT [settled]

The Unchosen corners the party exactly as the Authority — taking the core —
becomes the true form. Witnessed directly, can't be rationalized. The lie breaks
for them. They let the party go.

### THE FINALE — THREE FRONTS [settled, keystone open]

The capital under attack, the core taken, the door open, the legion pouring
through.

- **Flanks — the unwinnable vigil.** The Guardian's last soldiers and the
  Authority's old army unite (the lie breaking, shown as a **formation, not a
  speech** — two banners in one line) against the endless legion. They cannot
  win; the legion has no bottom. Their only objective is **time** — hold so the
  hero reaches the door. They spend their lives for minutes.
- **Center — the hero and the door.** The hero races to the door to reclose it,
  carrying the fragment. The legion is the clock; the flanks bleed the whole time
  the hero is at the door. Let the player feel the line thinning behind them.
- **Mercy inverts.** All of Act 2 trained the player to minimize cost; the finale
  is the one place they must spend lives. Grace isn't saving everyone — it's
  **being worthy of the sacrifice**, reaching the door before the line runs out.
- **The keystone — [open].** What the fragment does at the core/door. The thing
  the whole loop builds toward; only this hero (who opened the door, who carries
  guilt and cure) can do it. Three "gifted" companions point at it (Priestess,
  Warlock, dwarf) — it may be a convergence, not a single act. The empire's
  stolen divine, reclaimed through the people it was stolen through. Left open on
  purpose.

### Resolution [settled]

Door reclosed (mechanism = keystone). Authority's control collapses; the
suppression lifts and **the gods can return to what they were doing** (the
world-scale grace: you didn't summon salvation, you removed the weight on it).
The gods were never killed — only blocked out — so this is a lifting, not a
resurrection. **[open]** whether the gods themselves return or only fragments of
their power remain. The hero reaches the destination the Guardian was bringing
them to all along.

### SILENT RECONCILIATION [settled]

Hero and the returned Unchosen. No dialogue — a look, a nod. Survivors stand
together; some wounds healed, some permanent. The player fills in the rest.


## What blocks fuller detail (open threads)

These keep specific beats from being fully specced. None block building the early
Act 1 beats (B1–B5), which are settled enough to build now.

- **Beat 7** — companions vs. NPCs; the save mechanism; the Unchosen's
  consequence. (Parked.)
- **The keystone** — what the fragment does at the door.
- **Act 2 death rules** — resolves by feel once combat is real.
- **The remaining cast** — Wizard, Knight, Rogue (Tank = dwarf; Warlock = a
  *distinct*, barely-planned bondable mage). Plus the **roster count/composition**
  now that Warlock and Wizard are separate characters. Affects recruit order and
  Beat 7.
- **Row 4** — the kind-trap collision (the set's missing shape).
- **Loved NPC** identity; the confiscated item (A2·B2); kingdom name.
- **The gods after the fall** — themselves, or only power-fragments? Is the
  Guardian a god?
- **Mission counts & maps per beat** — downstream of cast + Beat 7.
