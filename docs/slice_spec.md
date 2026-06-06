# TristoTactics — Vertical Slice Spec (Vision Build)

## What this is

A playable vertical slice built to **show the game to artists and
collaborators** — to communicate the vision, the feel, and the core loop well
enough that someone can make assets or systems for it. It is **not** a public /
Steam demo, so it does not need to protect the story twist (collaborators are
inside the tent and should know the whole thing via the bible). Its job is
*alignment*, not marketing.

Shape: **Opening → the camp → the tutorial → a mission or two → the bridge
face-off → end on the stare across the gap.** (Act 1 only; the slice has no Act
2, so it naturally ends on intrigue without spoiling anything.)

The feeling at the end should be the game's stated Act 1 emotional goal: *my
squad is full, the campaign feels heroic, something is faintly wrong, and who is
this strange party I keep seeing?* Curiosity, not comprehension.

Last updated: 2026-06-05


## The honest scope insight (read this first)

The **engine is done**; the **identity is not.** The battle system, pathfinding,
attack flow, enemy AI, walking scenes, the 15-event story/dialogue/glitch
system, save/load, pause, victory screens — all ✅ and proven. What the slice
*doesn't* have yet is every mechanic that makes TristoTactics itself:

- **Combos** — the ability framework exists but only `HealAbility` is concrete;
  follow-ups, passives, and duo abilities are unbuilt. This is the signature
  tactical verb and it does not exist yet.
- **Relationship / bonding system** — not built at all.
- **Silent-hero expressive choices** — the dialogue system *plays* lines; it does
  not yet *offer the player a choice of response.* Unbuilt.
- **The advancing line** (time-as-resource) — unbuilt.

So this slice is not an assembly job. **It is where the signature systems get
built for the first time.** That's the real reason it's the right next thing: it
forces the game's identity into existence on a small, contained stage instead of
in the abstract. Combat already works; the slice is how *TristoTactics* starts
working.


## What the slice must prove (mechanics checklist)

| Mechanic | Build state | Where the slice shows it |
|---|---|---|
| Tactics combat (move/attack/turns) | ✅ exists | Tutorial battle onward |
| **Combos** (follow-ups first) | ❌ build | Vael *teaches* the follow-up in the tutorial; used in real fights after |
| **Bonding / relationships** | ❌ build | At least 2 companions you bond with across the slice |
| **Silent-hero expressive choices** | ❌ build | Camp/companion talk (bonding) + ≥1 *complicity* beat (believe Vael / dismiss a glitch) |
| Glitches (low wrongness) | ✅ exists | Seeded in the campaign missions, escalating slightly toward the bridge |
| The advancing line (a taste) | ❌ build / or fake | Optional for the slice — see Open Gates |
| Hero fragment / time power | — | Out of slice (barely present this early in Act 1) |

The slice does **not** need: the keystone, Beat 7, any collision *payoff*, the
veil-drop, or Act 2 anything. Those are all later/Act 2 and would either spoil or
overscope.


## Beat-by-beat

### Opening — build 🟡 (nearly done)
The void walk, the Guardian's fragmented transmissions, name entry, the
interception, "Find me," white-out. **Remaining:** the swirl-shader placeholder
(`opening_corridor_scene.gd:389`) and the two placeholder lines at L427–428
(the companion / Act 2-vision line — note this ties to the still-open question of
whether the opening plants an unreadable end-game cue; decide before finishing).

### Beat 1 — ARRIVAL / the camp — build 🟡
Wake in the summoning chamber, walk out into the camp, Vael's warm greeting
(*"You actually made it…"*). **Remaining:** the scene is currently just a walking
room with a door — needs Vael, soldiers, torchlight, the camp atmosphere, and
the arrival dialogue (the corrected lie: *the Authority summoned you*). No combat.
- *Demonstrates:* tone, Vael's warmth, the silent hero, the world.

### Beat 2 — TUTORIAL + RAID — build 🟥 (stub) — the big one
Two phases. **Sparring:** Vael coaches the core verbs *and teaches the first
combo* (the follow-up — stand close, chain your partner's strike). **Raid:**
"insurgents" hit the camp, combat turns lethal, first real fight; companions
join.
- *Demonstrates:* combat, **combos (taught here)**, the coach→commander tonal
  flip, first companions.
- *Plants:* collision row 5 (the camp raid — the distraction the Act 2 party
  will later send). The skirmish must read as a forgettable win.
- *Builds:* the combo system's first concrete abilities; TutorialManager hookups.

### Beat 3 — EARLY CAMPAIGN mission — build ⬜
A standard mission against kingdom "insurgents." Bonds deepen (camp/expressive
choices between missions). First **glitches** appear and are dismissed; first
**moral flicker** (an enemy resolves into a frightened person for half a second).
- *Demonstrates:* combat at slightly higher complexity, bonding choices, glitches.

### Beat 4 — SHADOWED FIGURES (first glimpse) — build ⬜
Cloaked figures appear in a battle; their shouts come through as garbled threats;
Authority calls them saboteurs; you move on.
- *Plants:* collision row 2 (the unheard face-off) and the garbled-line cue.
- *Demonstrates:* the escalating wrongness; sets up the bridge.

### Beat 5 — THE BRIDGE / FIRST FACE-OFF — build ⬜ — the capstone
A bridge comes down in the rain; across the broken span the two parties **face
each other** — no contact, the gap uncrossable. The Act 1 party is too war-worn
to recognize themselves. **The slice ends here, on the stare across the gap.**
- *Plants:* collision row 1 (the bridge) + the red-bridge-in-rain cue.
- *Demonstrates:* a real battle, atmosphere, and the central hook as a final
  image.
- **Build note:** the map must be reusable with inverted objectives for the Act 2
  payoff (most of the Act 2 party's mission happens on the *far* side — the bridge
  is a territory boundary, not a symmetric arena). Build it that way now.


## Cast in the slice

**Two companions minimum** — you need two to show a *duo combo* and the
beginnings of bonding/preference. Almost certainly the **Archer** plus one other.
- The Archer is the most-designed companion and her two-state design (anxious
  mess ↔ lethal trance) reads fast and sells the "VN-depth character" pillar.
- Second companion: open. The **dwarf** is a strong pick — his protective
  follow-up combos beautifully with the Archer's ranged shots and shows the
  combo system's *character-expressive* range (protect vs. strike). `[open]`
- Their names are still open (cast open question).


## Asset needs (for the artists this slice is meant to recruit)

- **Characters:** the silent Hero; 2 companions (Archer + 1); Commander Vael
  (sprite + portrait, warm register); Authority soldiers; kingdom defenders /
  "insurgents" — *faction-neutral visual identity* so the Act 2 reframe lands;
  the cloaked Act-2-party figures (shadowed, unreadable).
- **Tilesets / environments:** summoning chamber; the war camp / training ground
  (reused for Act 2 B2 infiltration); kingdom outskirts; the **red bridge in the
  rain** (the cue — make it distinct and memorable).
- **VFX:** glitch effects (✅ exists); the opening swirl shader (needed); bridge
  collapse; rain.
- **UI:** combo / follow-up indicators; the bonding readout; the expressive-choice
  prompt (wordless/tone options if the hero stays mute — see protagonist
  approach).
- **Audio:** opening, camp, tutorial, battle, and a tension cue for the bridge.


## Open gates (decide these to fully scope the slice)

1. **The second companion** (identity + name) — needed for the duo combo and the
   second bond.
2. **Combo specifics for the slice** — which 2–3 follow-ups/passives the slice
   actually demonstrates (enough to feel the system, not the whole kit).
3. **Does the advancing line appear in the slice**, or is it deferred? (It can be
   faked/hinted for a vision build; full system can wait.)
4. **The expressive-choice form** — wordless action/tone vs. short worded
   responses (leaning wordless, per the silent-hero discussion).
5. **Kingdom name** — only if any slice dialogue references the place.


## The end frame

The slice ends on the bridge: the broken span, the rain, the strange party
staring back across the gap, and cut. The player should be *fond of their squad,
comfortable with the combat, and quietly unsettled* — holding the central
question without an answer. That single image is the whole pitch, and it gives
away nothing.
