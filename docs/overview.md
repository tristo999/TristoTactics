# TristoTactics — Design Overview

The north star. Read this first. It explains what the game is, why it works,
how the documents relate, and what's still open. If you only read one file,
read this one.

Last updated: 2026-05-31 (rewrite — supersedes the old AI-conversation docs)


## What this is, in one breath

A turn-based tactics RPG where you fight a war twice. The first time you're
lied to and you do terrible things believing you're the hero. The second time
you live the same war from the other side, lie gone, and you can't undo any of
it — you can only move through the inevitable with as much mercy as you can
manage. Tone: righteous warmth curdling into tragedy.


## The pitch

A silent hero is summoned across worlds by a failing god — the Guardian — to
lead the last resistance against an empire that has spent centuries blocking the
world's gods out of it and installing itself in the gap (it claims to have
killed them; it only suppressed them). The empire intercepts the summoning. It doesn't kill the
hero. It cuts them off from the Guardian, walls their mind with a lie, and sends
them to war against the very god that called them, certain the whole time that
they're the righteous one. The Guardian bleeds through in glitches — half a
sentence, a wrong color — the only honest voice in a world built on a lie. The
hero fights a campaign of conquest believing it's liberation, bonds with
companions who are themselves broken products of the empire, and is marched,
step by step, toward the one door the empire could never open.

Then they open it. And the story begins again, from the other side.


## The engine — why this is its own game

Three ideas, fused. None is novel alone. The fusion is.

1. **Collisions.** The game is a set of scenes that happen *twice*. Act 1 you
   live them under the lie — you win, you celebrate, you dismiss, you condemn.
   Act 2 the same scenes replay from the other side with the lie gone, and they
   mean the opposite of what you felt the first time. The collisions are the
   actual unit of design. Everything else is connective tissue between them.

2. **The loop is fixed outside, authored inside.** What happened can't change —
   the bridge falls, the friend dies, the war goes the way it went. That's the
   silhouette, carved in stone. But *how* it happened, *why*, and *what it cost*
   were never visible to the Act 1 party, so all of that is yours to write in
   Act 2. The loop isn't a cage. It's a keyhole: the player already knows the
   ending of each scene, so every new piece of context lands as
   recontextualization, not suspense. Not "will they make it" but "I already
   know they make it — oh god, *this* is what it cost."

3. **Mercy under constraint.** The motivation engine. In Act 1 you did maximum
   damage believing you were good. In Act 2 you can't undo the war's shape, but
   inside it your whole job becomes limiting the harm. The bridge falls either
   way — but did it fall on the convoy or after it cleared? The player's
   relationship to harm *inverts* across the two acts. That inversion is the
   emotional arc of the entire second half, and it's measurable, which means
   it's playable.


## The recognition (the structure that ties it together)

The collisions are **not announced as repeats** in Act 2. Act 2 is mostly its
own campaign — its own objectives, its own breathing room — and the collision
scenes play as their own scenes on their own terms. The player relaxes. Stops
bracing. Then, near the end, the pieces suddenly align and the player
**realizes** — is never told — that they've been replaying their own Act 1 from
the blind side the whole time.

The recognition is committed by the player, never delivered in a montage. The
game's job at the climax is to hand over the *final* piece and then get out of
the way. If the game does the connecting, it steals the one thing that makes
this transcendent: the complicity. The player has to be the one who realizes
what they did.

This only works if the player is holding the pieces and just hasn't connected
them. That's what **retrieval cues** are for (see the ledger): sensory
fingerprints on otherwise-unremarkable Act 1 beats — a red bridge in the rain,
a boss's specific weapon, an exact garbled line — forgettable enough that you
don't brace for them, recoverable the instant the alignment comes.


## Themes

- **Victims who believe the victim is the thief.** The empire's central lie.
  Every soldier — and the hero — is a victim taught that the wronged party is
  the villain.
- **Deicide and substitution** *(as the empire tells it).* It claims to have
  killed the old gods and worn the corpse — but the truth is suppression: the
  distant, rarely-interfering gods were *blocked out*, not slain, and the empire
  installed itself in the gap. Brainwashing the hero is the same move at the
  scale of one mind — cut them off from the real voice, install your own.
- **Complicity has a price even at the top.** Standing in the empire is a
  gradient of how early you folded — so the prosperous "winners" are just the
  kingdoms that capitulated soonest, robbed of their own gods too and taught to
  call it luck. Prosperity is a confession; poverty is a scar from having once
  resisted.
- **Broken people learning to be people again.** The companions are what the
  empire made. The personal-quest pillar is the game arguing they can be more.

The thesis rhymes with itself at three zoom levels — world, kingdom, single
mind — which is the tell of a real theme and not a slogan. Protect that.


## The document map

- **overview.md** (this file) — why the game is like this. The north star.
- **bible_01_world.md / bible_02_cast.md / bible_03_act1.md / bible_04_act2.md**
  — the canon, as a four-part standalone Story Bible (World / Hero+Cast / Act 1 /
  Act 2). Novel-style and readable cold; treat as ground truth. `[GUESS]` tags
  mark open inventions, consolidated in the Manifest at the end of Part Four.
- **collision_ledger.md** — the design blueprint. One row per
  scene-that-happens-twice. The thing you build from, not a beat list.
- **story_beats_plan.md** — the ordering layer: every beat in sequence, both
  acts, with collisions placed in time and retrieval cues planted. Built on the
  ledger; must not contradict the canon.
- **systems_design.md** — the mechanics layer: combat rules, death/stakes,
  relationships, combos, the advancing line, the hero's time powers.
- **slice_spec.md** — the vertical-slice build spec: the Opening→bridge slice
  built to recruit collaborators (and the first place the signature systems —
  combos, bonding, expressive choices — actually get built).
- **implementation_status.md** — the build/process layer: what's coded, what's
  stubbed, the MVP slice and milestones. A different job from the story docs.
- **opening_scene_report.md** — writer-facing breakdown of the opening sequence.
- **dialogue_system.md** — technical reference for the dialogue system.

**Superseded scaffolding (removed 2026-05-31):** an earlier `story_map.md` (a
21-beat list with "LOCKED DECISION" tags) and a Story & Lore handoff were
brainstorming artifacts. Their useful content was folded into the canon docs
above — and the training-camp infiltration into ledger Row 5 — then the originals
were removed (they live in git history). Two things they got wrong, now revised:
the Guardian was never captured (its connection to the hero was jammed), and the
Guardian is not the source of all magic (it guards the core). Nothing here is
locked — everything stays iterable via the `[settled]/[open]` legend.

*(2026-06-05: the single `world_bible.md` was split into the four-part bible above and retired; `slice_spec.md` added.)*


## Two things to keep honest

**Protect the opening.** The whole payoff structure depends on Act 1 being
unremarkable enough that you don't brace. But "deliberately unremarkable" is one
bad step from "actually unengaging," and the player doesn't yet know there's a
payoff coming. Act 1 has to be a genuinely good tactics campaign — warm cast, a
villain you almost like, fights that satisfy — *for a player who will never
reach Act 2.* The collisions are a gift to whoever finishes. The first three
hours have to earn the finish without leaning on them. The premise gives you a
strong cold open (the interception, waking in the wrong place, Vael's
unsettling warmth) and a persistent low wrongness (the glitches). Use them.

**Keep the slice small.** This is designed like a studio game — two acts, six
companions, a branching antagonist, a three-front finale — and it's being built
by one person. A two-act game where Act 2 recontextualizes Act 1 is, in content
terms, more than one game. That's not a reason to shrink the vision. It's a
reason to make the first playable slice small and reachable, so the project
survives long enough to become the big thing. The story is worth telling. The
question that decides whether it gets told is "is the first playable piece small
enough," not "is it good enough." It's good enough.


## The one open keystone

What does the Guardian's fragment actually *do* at the core/door in the finale?
It's the thing the whole two-act loop builds toward — the reason the Guardian
summoned a champion across worlds in the first place. Whatever it is, it should
be something only *this* hero could do: the one who opened the door, who carries
both the guilt and the cure. The doom and the cure run through the same hands.
Left open on purpose. It sets easiest with the whole arch in view, and the arch
is now built.
