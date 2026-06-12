# TristoTactics — Systems Design

The mechanics layer: how the game plays — combat rules, stakes, relationships,
combos, the advancing line, the hero's time powers. Distinct from the story docs
(`overview.md` / the four-part bible `bible_01`–`bible_04` / `collision_ledger.md`), the build tracker
(`implementation_status.md`), and the writer-facing references.

Legend: **[settled]** firm · **[for now]** working answer, deliberately not
canon yet · **[open]** undecided.

Last updated: 2026-06-01


## Death & Stakes — Act 1 [for now]

**Decided up front: Act 1 has no permadeath.** This is settled and not to be
relitigated — it was worked through exhaustively, and permadeath is incompatible
with the game's structure (the two acts are welded together by the collisions; a
character lost to a bad turn punches a hole in scenes the other act needs, which
is unauthored studio-scale branching for a solo dev). Stakes come from elsewhere
(below), not from the dice deleting someone you love. **Death in this game is
authored, not rolled** — see the open thread for Act 2. (The one authored loss
inside Act 1 is **Beat 7's choice**: the companion you don't save is *presumed
dead*, though the truth — revealed in Act 2 — is the Throne took them alive
and reforged them into the Unchosen. See the story beats plan.)

### What happens when a character hits 0 HP in Act 1

- They play a death animation and leave the battlefield for the rest of that
  fight.
- The player knows they're coming back — it reads as "down for this fight," not
  a fake-out. No deception, honest stakes.
- They are **critically injured, not dead.** Healed and available again next
  mission.

### The cost (why it still hurts)

**In-fight:** losing the unit is the punishment — no extra penalty needed.
Because combos are central, a downed character costs far more than one body: you
lose every follow-up, passive, and duo ability they were part of, and the
interlock with everyone they're bonded to. A bonded pair going down doesn't cost
two units, it costs the *web* between them and the rest of the squad. The board
gets quietly, disproportionately worse.

**Lingering (out of battle):** going down sets back the character's relationship
progress with the whole party. So letting someone fall costs you ground on the
bonds you're building toward (combos, Beat 7 closeness, all of it), not just the
fight.

### The fiction (why the mechanic feels earned)

Going down hurt them — they feel unprotected, or like they were made to
sacrifice. Their "healing" is set back, and that recovery is the in-world reason
the bonds cool. Mechanic and feeling line up: the relationship slide isn't an
arbitrary penalty, it's the character pulling back after being hurt.

### Why this fits the game

It leans on the relationship system instead of fighting it: protecting your
bonded units becomes urgent because losing them damages the exact thing the
whole game is built on. Real stakes every fight, zero structural damage to the
story.

### [open] — Act 2 death

Once the Throne has discarded the party (the protection's gone), the rules
can change and **authored death** becomes possible — the chosen, designed losses
(e.g. the finale's mercy-inversion). This is deliberately unresolved; it resolves
by feel once combat is real, and it does not block any Act 1 work. The Act 1 /
Act 2 split may eventually be framed in fiction the same way the gods are: death,
like the divine, is held off by the Throne's presence and becomes real only
once it's gone. Not canon yet.


## Teams & unit control [settled]

Three teams, with a simple hostility model (`Constants.is_hostile`): same team is
friendly; the **enemy** team is hostile to everyone else; **player** and **ally**
are friendly to each other.

- **Player team** — your squad. Manually controlled.
- **Enemy team** — AI-controlled (`EnemyCharacter`), seeks the nearest *hostile*.
- **Ally team ("green" units)** — AI-controlled, *not* part of your squad (camp
  soldiers, sparring partners, guests). The player does **not** command them
  (genre-standard; narratively they aren't yours). Implemented as `EnemyCharacter`
  with `team_override = TEAM_ALLY` — the AI seeks the nearest hostile, so the same
  logic drives both enemies and allies; no separate class/scene. Allies don't
  count toward win/lose (battle is won when enemies are gone, lost when the player
  squad is gone). Spawn an ally via a roster entry `{ "team": "ally", ... }`.

**Control model — the opening [settled 2026-06-10]:** the player controls **only the
Hero** through the tutorial spar and the raid; the squad (Elena/Borin/Lyra) and the
recruits fight beside you as scripted AI **allies**. Mechanically: hero = the one
player-team unit; companions spawn `team: "ally"`; follow-ups fire across *friendly*
teams (player↔ally, hostility-based — not team-equality); `EnemyCharacter.ai_enabled =
false` parks a unit so scripted scenes own the turn flow (reactions still fire).
`[open]` when (or whether) direct squad control expands in later missions.

Mid-battle team *change* is built as a primitive (`CharacterBase.set_team` /
`TriggerAct.flip_team`); using it live in a scene (spar partners → allies at the
breach) is wired per-scene when the combined drill→raid scene is built.

## The camp hub [settled 2026-06-10]

The war camp is the game's **persistent social hub**: one camp, struck and
re-pitched as the Throne's line advances, the party's home between missions for
all of Act 1 (Act 2 mirrors it with the party's own camp — different camp, same
idea). The campaign loop is **mission → camp (talk, bond, breathe) → mission**, and
the camp re-pitching on new ground each stage is the advancing line made tangible.

Build economy: ONE camp scene (the `camp_grounds` family) serves the whole act —
re-dressed surroundings per stage (backdrop/terrain beyond the camp edge), same
interior geography. Camp-life systems (bonding talks, expressive choices, side-quest
hooks) get built once, in one venue, and run all campaign. Not yet built beyond the
arrival scene; the camp-hub scene (free walk + companion talks between missions) is
the natural home for bonding v1's spend side.

## The finale's battle structure [current decision 2026-06-11; fiction in bible_04]

The final battle is an **interruption of an ascension**, fought through a
bodyguard. Mechanical shape:

- **The anchors** — three physical anchor-points (`[open]` name; count = three,
  tuning open) channel visibly into the Throne's chrysalis. Each is a **solvable
  tactics puzzle**: an elite, *finite* garrison on terrain-driven,
  elevation-heavy ground — while the endless legion supplies unsolvable
  *perimeter pressure* around them. Severing an anchor slows the rising, thins
  the perimeter, and visibly slackens the field: minutes bought, a corridor
  opened.
- **The clock is diegetic.** The ascension's progress is read off the
  battlefield — channeling thickening, the form accreting where the beams
  converge. No abstract timer anywhere.
- **The deployment payoff.** Three simultaneous objectives split the gathered
  roster: who hits which anchor, who holds which approach. Every Act 2
  gathering thread cashes out as a deployment decision — the one mission where
  "who did you save" is read off the deployment screen.
- **[open] Assault structure:** truly simultaneous three-squad battles vs. one
  party hitting anchors in sequence while the line collapses behind them (the
  shrinking-map noose recompiled into a single mission). Gameplay-budget
  decision; resolve when the finale is scoped.
- *Doc-facing note:* the assault may deliberately reuse the tutorial's combat
  grammar — cover, elevation, the follow-up — the final fight conducted in the
  language the monster taught you in lesson one.
- Sequence: anchors severed → rising stalled → perimeter thinned → the
  monstrosity assailable → the boss fight proper → the keystone (bible_04).

## Other systems — homed here when ready (not yet written up)

These were designed across recent sessions and belong in this doc, but aren't
formalized yet. Listed so they don't get lost:

- **Relationship / bonding model** — bonds built through use, story events, and
  a limited number of side quests per run. Player-driven and uneven by design.
  Drives combos and the Beat 7 choice. **Each companion's wound only fully heals
  if the player completes their whole personal side quest** — skip it and they
  stay partly broken (see the world bible's cast doctrine).
- **Combo system** — follow-ups (the teachable atom; reach & shape express
  character), passives, and duo/team abilities, unlocking and deepening with
  relationships. Positioning-for-combos as the core tactical verb.
- **The advancing Throne line** — the single clock. Progresses only as the
  player spends time on things; pushes the strategic layer (where to go, who to
  save, who to bond with) while leaving the tactical layer free. Lockouts must be
  visible choices, never silent expiries.
- **Hero time powers (Guardian fragment)** — very limited, not a generic undo;
  grow stronger as the hero nears the Guardian. Rare and special, not the
  foundation of combat.
