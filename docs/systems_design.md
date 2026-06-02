# TristoTactics — Systems Design

The mechanics layer: how the game plays — combat rules, stakes, relationships,
combos, the advancing line, the hero's time powers. Distinct from the story docs
(`overview.md` / `world_bible.md` / `collision_ledger.md`), the build tracker
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
authored, not rolled** — see the open thread for Act 2.

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

Once the Authority has discarded the party (the protection's gone), the rules
can change and **authored death** becomes possible — the chosen, designed losses
(e.g. the finale's mercy-inversion). This is deliberately unresolved; it resolves
by feel once combat is real, and it does not block any Act 1 work. The Act 1 /
Act 2 split may eventually be framed in fiction the same way the gods are: death,
like the divine, is held off by the Authority's presence and becomes real only
once it's gone. Not canon yet.


## Other systems — homed here when ready (not yet written up)

These were designed across recent sessions and belong in this doc, but aren't
formalized yet. Listed so they don't get lost:

- **Relationship / bonding model** — bonds built through use, story events, and
  a limited number of side quests per run. Player-driven and uneven by design.
  Drives combos and the Beat 7 choice.
- **Combo system** — follow-ups (the teachable atom; reach & shape express
  character), passives, and duo/team abilities, unlocking and deepening with
  relationships. Positioning-for-combos as the core tactical verb.
- **The advancing Authority line** — the single clock. Progresses only as the
  player spends time on things; pushes the strategic layer (where to go, who to
  save, who to bond with) while leaving the tactical layer free. Lockouts must be
  visible choices, never silent expiries.
- **Hero time powers (Guardian fragment)** — very limited, not a generic undo;
  grow stronger as the hero nears the Guardian. Rare and special, not the
  foundation of combat.
