# TristoTactics — Systems Design

The mechanics layer: how the game plays — combat rules, stakes, relationships,
combos, the advancing line, the hero's time powers. Distinct from the story docs
(`overview.md` / the four-part bible `bible_01`–`bible_04` / `collision_ledger.md`), the build tracker
(`implementation_status.md`), and the writer-facing references.

Legend: **[settled]** firm · **[for now]** working answer, deliberately not
canon yet · **[open]** undecided.

Last updated: 2026-06-12


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

## Camp eavesdrops & audible fates [current decision 2026-06-11; fiction in bible_02]

**The eavesdrop channel** — companion↔companion conversations the player walks
up on in camp: the third content channel beside missions and hero-facing bond
scenes (doctrine in bible_02's *Camp life* section). Mechanically:

- **Two-character barks, no hero input** (the silent protagonist holds):
  proximity-triggered exchanges of a few lines between two companions placed
  in the camp scene.
- **~A dozen authored relationships, not N²** — pair partners plus a handful
  of cross-pair frictions. Each authored relationship gets Act 1 exchanges and
  an Act 2 *shadow* (same pair, same subject, opposite meaning).
- **Trigger-engine territory**: region + flag conditions select which exchange
  plays at the current camp pitch; the plumbing is agent work, the words are
  Tristan's.
- `[open]` Presentation (floating text vs. dialogue box), trigger radius,
  whether exchanges are re-listenable, and how many per camp visit.

**Audible fates** — companion outcomes delivered through a recurring line
changing (or pointedly not changing) per the bond outcome: Lyra's pre-heal
invocation, Elena's post-battle victory bark (doctrine in bible_02). Systems
hook: **the bark system must support per-outcome variants of a character's
signature recurring line.** Cheap to build, but it must be designed in from
the first bark pass — signature lines can never be hard-coded single strings,
or the fates have nowhere to live.

**Location-triggered companion scenes** — Elena's camp scenes don't sit at a
fixed NPC spot: she is found wherever the current camp pitch is *most worth
looking at*, and the player learns the pattern (want Elena? find the view).
Camp set-dressing becomes character content; each re-pitch needs one
designated "the view" spot for her placement.

## Companion kits & fate hooks [current decision 2026-06-12; fiction in bible_02]

**The protect-triangle** (kit doctrine for the defensive roles — no two
redundant):

- **Knight = anchor/wall** — zone control, defends *terrain*: holds tiles,
  punishes movement through her zone, rewards picking the right ground.
  Protects positions.
- **Borin = intercept/bodyguard** — mobile, reaction-based: moves himself
  into harm meant for another (his existing pre-hit intercept follow-up is
  this kit's seed). Protects people. **His kit IS his wound** — the dive
  performed a hundred casual times across the campaign before the one
  scripted dive that costs everything.
- **Paladin = frontline medic** — heal-primary, tank-flavored: adjacency /
  short-range mending, presence-based mitigation, heavy armor so the healing
  stands in the fire. Protects the wounded. Deliberately no overlap with
  Lyra's backline blessing or either tank.

**Playable fates** (sibling to audible fates): a fate delivered through a
*mechanic the player has used all game* recurring with new meaning — Borin's
dive is the flagship (the same intercept verb, casual a hundred times, then
once with everything on it). Systems hook: signature reactions need the same
per-outcome variant support as signature lines.

**Visible fates** (second sibling): Act 2 outcomes visible on bodies — the
Knight's haircut at her vow is the flagship. Production hook: the character
art/portrait pipeline must support a **mid-game portrait + sprite swap** per
companion; budget at least one (the Knight) and design the pipeline so more
are cheap.

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
- **The last phase is an input fight (seventh batch, 2026-06-12 — staging
  hook):** post-cut, the dying Throne turns the amplifier on the hero (the
  fight to give the heart back — bible_04). Mechanically: the reach-and-refuse
  gains **input resistance** — the refusal earned against active sabotage,
  fought inside the player's hands. PROTECT carried from batch 4: the spark
  must be genuinely mechanically takeable; the refusal is never skippable
  ceremony. Implementation shape open (resisted stick/cursor pull, degrading
  prompts, reversed inputs — resolve by feel; it must read as the Throne's
  hand, not jank).

## Environmental biography — the Guardian's story fragments [current decision 2026-06-12; fiction in bible_04]

Her story is assembled by the player across Act 2 from world fragments, never
exposition (the environmental-biography doctrine). Design rules:

- **Optional-but-converging**: thorough players assemble more; the critical
  path carries the minimum set for the ending's reunion to land. `[open]` The
  minimum critical-path set — which fragments are unmissable — is a
  mission-design question; decide it when Act 2 missions are scoped, and
  place the unmissable fragments on mandatory routes (a shrine the party
  camps in, not a side room).
- **No codex dumps** — every fragment is IN the world: a frieze, a rhyme, an
  elder's aside, a ruined shrine used as a campsite.
- **Three discovery channels** — temples (archaeology), folklore (the
  Wizard's stratum), living memory (the elders) — and they should *disagree
  slightly at the edges*, the way real old knowledge does.
- **The name is the capstone (eighth batch):** the apex of the
  optional-but-converging structure — her actual name, recoverable in pieces
  across all three channels, assembled *last* by the thorough player. It
  pays off as the hero's one word at the ending. `[open]` The name itself is
  the naming session's crown item (engineering spec in bible_04's Manifest).

## The ending sequence — systems notes [current decision 2026-06-12; staging in bible_04]

**The conditional cameo pass** (the flight montage): every collected/saved/
sided-with character appears as a **fate-tell** — one-image deltas, caught
mid-life, no bows. Mechanically tractable by design: 8 companions × ~2 fates
plus a roster of binary flags (saved/not, sided/not); each cameo is one
composition with a bonded/neutral variant selected by save state; **text not
VO.** The discipline is in authoring (the delta must be readable in one
image: the haircut, the view, the planting, the still-there), not in
plumbing.

**The last gathering = the eavesdrop system's finale**: the final scene is
the camp-hub grammar run once more, slow — placement + bark variants
selected by save state per companion fate, the pairs-twice conversations as
content. Minimal new systems: it reuses the eavesdrop channel's
variant-selection machinery; what it needs is the fate flags feeding
placement and line selection. (One new requirement: the scene must support
*everyone placed at once* — the eavesdrop system elsewhere stages pairs.
The ninth batch's group scenes depend on this same capability.)

**The gathering's gate mechanics (ninth batch, 2026-06-12)**: the gathering
is playable — a walkable space, not a cutscene. Mechanics:
- **Finite content, done-talking states**: each companion's final content is
  finite; once spent they don't refresh into filler — they sit, present,
  done talking (a state, not a bug: it's the scene's thesis). A **soft
  indicator** marks who hasn't been heard yet — informational, never
  prompting.
- **THE ZERO-SHAME RULE (PROTECT)**: no NPC impatience, no music shift, no
  "the others are waiting." The game waits as long as the player does.
- **The walk is the confirm**: the exit NPC asks "Are you ready to go?" and
  the answer is movement — walking past the NPC through the exit commits;
  turning back returns to the fire, unremarked. No dialogue choice, no menu,
  no button prompt beyond the warning that the exit is final.
- `[open]` **The conditioning boundary**: group scenes vary lightly by
  overall party temperature; the full bonded/neutral split lives in the
  one-on-ones, where writing is per-companion anyway. Keeps the conditional
  matrix at the layer the fates were designed for; prevents combinatorial
  explosion in ensemble banter. Lean recorded; rule at implementation.

**The rise-and-follow (staging/animation note)**: the hero exits alone; the
party rises and falls in, unordered, zero dialogue. Needs: per-companion
rise animations (or one shared get-up with per-character timing), a follow
formation, and the `[open]` rise order (who stands first/last) decided at
staging. Cheap in tech, load-bearing in feel — the timing IS the writing.

**The title swap (production item)**: the post-completion title screen
changes — the title card becomes the last shot of the film. Needs: a
completion flag persisted outside the save slot (profile-level), a second
title composition `[open — the changed image, candidates in bible_04]`, and
the credits rolling over the resolved motif (ledger Row 10).

**The motif system (audio-design note)**: the Guardian's Act 1 glitches
carry a musical signature — three or four corrupted notes as a plantable
**audio retrieval cue**; the ending theme resolves the same melody whole.
**Production implication, flagged hard: the glitch SFX and the ending theme
must be composed together** — the broken version is derived from the whole,
not retrofitted. This decides glitch SFX work *now*: placeholder glitch
audio is fine, but the final glitch SFX cannot be locked before the theme
exists.

**Budget backward from the fire (the scene-budget method)**: anchor the
scene-budget doc on the last gathering — enumerate what the fire must be
able to say about each companion, each pair, each fate, and the hero; that
list generates the minimum bond-scene spine the campaign must deliver to
earn it. The ending is the spec for the VN half; the destination designs the
road. **Sequencing corollary (ninth batch — write the fire LAST)**: the
gathering's scenes are written after the bond scenes exist and the routes
are authored — they are interest on deposits; the backward-budget specs what
the road must deposit, the road gets built, then the fire gets written,
rich.

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
  visible choices, never silent expiries. **Act 2 second front (seventh batch,
  2026-06-12):** the land-sickening — the wasteland spreading from the capital
  as the rising proceeds (fiction in bible_01/bible_04). Mechanically it is
  the same clock *rendered*, not a second resource: region states gain a
  sickness tint/stage tied to clock progress, and the gray's reach IS the
  visible timer (continuous with the finale's diegetic clock — no abstract
  timer anywhere).
- **Hero time powers (Guardian fragment)** — very limited, not a generic undo;
  grow stronger as the hero nears the Guardian. Rare and special, not the
  foundation of combat.
