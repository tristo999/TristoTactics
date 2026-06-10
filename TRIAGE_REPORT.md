# TristoTactics — Doc Triage Report

**Date:** 2026-06-09 · **Scope:** every project `.md`/`.txt` doc, triaged against the
ruling canon hierarchy (4-part bible = narrative source of truth; ledger = living
working table; systems_design/slice_spec = build docs; everything else narrative = a
superseded candidate).

---

## EXECUTION STATUS (rulings applied 2026-06-09)

| Ruling | Status |
|---|---|
| **§4** Soften ledger Row 3 to "comrade-or-trusted-NPC `[open]`"; bump stamp + add bible-verified note | ✅ **DONE** — `collision_ledger.md` row 3 cell + Row 3 craft note + `Last updated` stamp |
| **§5.1** Slim `story_beats_plan.md` to (1) pairing map + (2) bare ordering skeleton; audit prose for unique content first | ⏳ **AUDIT DONE — AWAITING RULING.** 3 unique items found (see "§5.1 audit" below); not slimmed yet (need your move-or-die call per item) |
| **§5.2** Resolve "stay with me" nit toward the implemented scene (add line to bible) | ✅ **DONE** — added to `bible_03_act1.md` void-sequence transmission examples |
| **§5.3** Create `docs/archive/`, move 5 historical docs, add archive README | ✅ **DONE** — `git mv` (history preserved) + `docs/archive/README.md` |
| **§5.4** Add level-spec superseded note to `docs/levels/camp_v2.md` | ✅ **DONE** |
| **§5.5** Accuracy pass on `dialogue_system.md` | ✅ **DONE** — all type/API claims verified accurate; added "current tools" note (CineFx + scripting ladder postdate the doc). Details below. |
| **§5.6** Keep `overview.md` as-is | ✅ **DONE** (no change) |

### §5.5 accuracy-pass result
`dialogue_system.md` was **accurate**, not stale, on every checkable claim:
`DialogueLine` fields (exact), `DialogueSequence` (exists: `scripts/story/dialogue_sequence.gd`),
the `res://dialogue/beat0/` folder + its two `.tres` files, `CinematicTrigger` exports,
the events list, and cps default = 30 (`dialogue_box.gd:8`) all match the code. The only
gap was age: it predates `CineFx` and the `TriggerEngine`, so I added a top-of-doc
"current tools" note and updated the "recommended approach" line. Nothing was unsure.

### §5.1 audit — unique content in `story_beats_plan.md` (NEEDS YOUR MOVE-OR-DIE RULING)
The beat plan is ~98% a re-sequence of bible content (every beat's prose is in the
bible; the Warlock "genuinely dark, not a mislabeled blessing" = `bible_02_cast.md:197`
verbatim; Priestess temple-evidence = `bible_02_cast.md:129`; "What blocks fuller detail"
duplicates the `bible_04` Manifest; `[build 🟡/🟥/⬜]` tags belong in
`implementation_status.md`). **Three items are genuinely NOT in the bible:**

1. **The summoning circle as an Act-2 recovered retrieval cue.** Beat plan: A1·B1
   plants "the summoning circle the hero stands on (recovered in A2·B2 when the party
   passes it)"; A2·B2 "they pass the summoning circle and recognize it." The bible only
   has the hero *waking* on the circle (`bible_03_act1.md:37`) — never as an Act-2 cue.
   *Recommend:* move to `collision_ledger.md` Row 5 cue (a second camp cue) + optional
   one-liner in `bible_04` camp-infiltration. *Or die.*
2. **Placement: the Town Mission as candidate home for the Priestess's temple-evidence
   thread** ("a destroyed temple near/under the town — she explains it away") and/or
   collision Row 4. Bible has the thread and the Row 4 hole, but not this placement.
   *Recommend:* move to `collision_ledger.md` "Open rows" (Row 4 candidate home) +
   `implementation_status.md` Town beat note. *Or die.*
3. **Placement: the capital betrayal is what forces the Priestess's faith conflict fully
   open** (the "Faith note"). Bible has the faith arc (`bible_02_cast.md:106-131`) but
   not this sequencing trigger. *Recommend:* one line into `bible_03_act1.md` "The
   choice"/"true form" stretch (it's a narrative consequence). *Or die.*

Tell me move-to-`<doc>` or die for each, and I'll place them, then slim the beat plan
to the pairing map + a one-line-per-beat skeleton (number → location → objective).

---

## TL;DR

- **The narrative docs are already in good shape.** The genuinely-superseded
  scaffolding (the old **21-beat `story_map.md`** + a "Story & Lore handoff") was
  **already deleted on 2026-05-31** and folded into the bible/ledger (recorded in
  `overview.md` §"Superseded scaffolding"). It survives only in git history.
- **Contradiction hunt: clean.** Every tripwire grep hit across non-bible docs states
  the *correct* canon (Guardian jammed not captured, "no artifact/voice," "never
  announce the repeat," "can't undo Act 1," silent hero). No live contradictions. Two
  minor detail-nits only (below).
- **Superseded headers added: ZERO.** No *current* doc is superseded **by the bible**.
  The historical/ephemeral build docs are stale in a *different* way (superseded by
  git history / `implementation_status`, not by the story bible), so the prescribed
  "SUPERSEDED by the 4-part story bible" header would be inaccurate on them — I left
  them untouched and listed them under UNCLEAR for your ruling.
- **The real "too many docs" problem is build-doc sprawl, not narrative.** Five
  point-in-time build/status docs overlap with `implementation_status`. Flagged for a
  consolidation ruling — not touched.
- **Ledger vs bible: rows match the bible's collision set.** One firmness mismatch on
  Row 3 (proposed note, not edited).

---

## 1. Inventory

Dates = file mtime (≈ last edit). Verdict key: **CANON** / **WORKING** / **SUPERSEDED**
/ **UNCLEAR**.

### Canon — the 4-part story bible

| Doc | Date | One-line | Verdict |
|---|---|---|---|
| `docs/bible_01_world.md` | Jun 5 | World/lore canon (Part 1) | **CANON** |
| `docs/bible_02_cast.md` | Jun 5 | Hero + cast canon (Part 2) | **CANON** |
| `docs/bible_03_act1.md` | Jun 5 | Act 1 canon (Part 3) | **CANON** |
| `docs/bible_04_act2.md` | Jun 5 | Act 2 canon + open-threads Manifest (Part 4) | **CANON** |

### Working — story/design

| Doc | Date | One-line | Verdict |
|---|---|---|---|
| `docs/collision_ledger.md` | May 31 | The collision design blueprint (living 5-row table) | **WORKING** (living table per ruling §2) |
| `docs/overview.md` | May 31 (Jun 5 addendum) | North-star "why" + the document map; records what was superseded | **WORKING** |
| `docs/systems_design.md` | Jun 6 | Mechanics: combat, death/stakes, relationships, combos, advancing line, time powers | **WORKING** (build doc per ruling §3) |
| `docs/slice_spec.md` | Jun 6 | Vertical-slice build spec (Opening→bridge) | **WORKING** (build doc per ruling §3) |
| `docs/story_beats_plan.md` | Jun 1 | 21 KB beat-by-beat ordering layer, both acts | **UNCLEAR** → see §5 (it's a "beat plan" — a named superseded-candidate — but current & bible-deferring) |
| `docs/opening_scene_report.md` | Jun 5 | Writer-facing spec of the *built* opening scene | **UNCLEAR** → see §5 (an "opening sequence doc" — but a current, accurate scene spec) |

### Working — build / technical / level

| Doc | Date | One-line | Verdict |
|---|---|---|---|
| `docs/implementation_status.md` | Jun 7 | Build-state tracker (10-beat Act 1 table + systems); defers to bible for canon | **WORKING** |
| `docs/feature_inventory.md` | Jun 7 | DONE/TODO feature list (for priority sorting) | **WORKING** |
| `docs/trigger_engine.md` | Jun 7 | Trigger-engine authoring guide | **WORKING** |
| `docs/map_generation_playbook.md` | Jun 6 | Map-authoring reference + §8 level semantics | **WORKING** |
| `docs/text_map_system.md` | Jun 6 | Text-map `.map` format technical ref | **WORKING** |
| `docs/dialogue_system.md` | **Mar 12** | Dialogue-system technical ref | **UNCLEAR** → oldest doc by months; verify still accurate |
| `docs/map_boundaries_framing.md` | Jun 6 | Map framing/void design decision | **WORKING** |
| `docs/map_design_process.md` | Jun 6 | Map iteration process | **WORKING** |
| `docs/levels/camp_grounds.md` | Jun 6 | Level spec — camp_grounds map | **WORKING** |
| `docs/levels/camp_v2.md` | Jun 6 | Level spec — **camp_v2 map (superseded by arena_drill/arena_raid)** | **UNCLEAR** → documents a superseded map (level-level, not narrative) |
| `ARCHITECTURE.md` | Jun 7 | Technical architecture reference | **WORKING** |
| `README.md` | — | Repo readme | **WORKING** |

### Historical / ephemeral — build snapshots (NOT narrative; NOT bible-superseded)

| Doc | Date | One-line | Verdict |
|---|---|---|---|
| `docs/session_log_2026-06-06.md` | Jun 6 | Dated build-session log (6 commits) | **UNCLEAR** → see §5 (historical; superseded by git/`implementation_status`, not by the bible) |
| `docs/tutorial_battle_buildlog.md` | Jun 6 | Tutorial-battle build retrospective + lessons | **UNCLEAR** → see §5 (historical) |
| `docs/status_update_2026-06-07.md` | Jun 7 | Point-in-time product status update | **UNCLEAR** → see §5 (ephemeral) |
| `docs/cleanup_analysis_2026-06-07.md` | Jun 7 | Point-in-time cleanup analysis (mostly executed) | **UNCLEAR** → see §5 (ephemeral) |
| `docs/whats_new_2026-06.md` | Jun 7 | June changelog | **UNCLEAR** → see §5 (rolling changelog) |

### Out of scope — third-party

All other `.md`/`.txt` under `addons/`, `assets/`, `.venv/`, `Library/`, and
`.claude/worktrees/` are vendor licenses, READMEs, and tileset rule files (e.g.
`addons/godotsteam/readme.md`, `assets/.../Asset License*.txt`, RPG-Maker tileset
`.txt`). `steam_appid.txt` is just the Steam app id. **None are project story/design
docs.** Not triaged. (Note: `.claude/worktrees/sad-bartik-b836fa/docs/` contains a
*stale snapshot* of three docs — `implementation_status`, `opening_scene_report`, and
the **already-removed `story_map.md`** — because that worktree sits on an old commit.
It's a scratch worktree, not a source of truth; ignore it.)

---

## 2. Contradiction hunt

Grepped every non-bible doc for the known stale tripwires. **No live contradictions.**
Every hit asserts the correct canon:

| Tripwire | Result | Evidence (correct-canon hits) |
|---|---|---|
| Guardian captured/defeated/dead | ✅ clean | `implementation_status.md:82` "the Guardian is *not* captured"; `overview.md:135` "the Guardian was never captured (its connection to the hero was jammed)" |
| Collisions announced / "remember this?" / flashback | ✅ clean | `collision_ledger.md:140-141` "Never announce the repeat… No 'remember this?' No flashback"; `overview.md:66` "not announced as repeats" |
| Hero told kingdom/Guardian summoned them | ✅ clean | `story_beats_plan.md:82` "*the Authority summoned you* … No kingdom-call, no artifact, no voice to chase"; `slice_spec.md:77` "the corrected lie: *the Authority summoned you*"; `overview.md:24` "It claims to have killed them; it only suppressed them" |
| Unchosen/lost companion described as dead | ✅ clean | No doc calls them truly dead; `implementation_status.md:84` "Unchosen Companion sent forward" (alive) |
| Voiced protagonist | ✅ clean | No hits; `overview.md:21` "A silent hero" |
| Structure organized around old 21-beat bible | ✅ clean | All "21-beat" mentions are *disavowals*: `collision_ledger.md:177` "Don't grow a 21-beat bible again"; `implementation_status.md:9`, `story_beats_plan.md:7` ("NOT a return to the old retired 21-beat bible") |
| Act 2 framed as "prevent Act 1" | ✅ clean | `overview.md:14` "you can't undo any of it"; `bible_04_act2.md:33` "not here to *prevent* Act 1 … be ready on the other side of the door"; `systems_design.md:112` time powers are "not a generic undo" |

### Minor detail-nits (not canon violations — your call whether to bother)

1. **`opening_scene_report.md:55` Phase-3 line `"...stay with me..."`** — the bible
   enumerates the opening transmissions as *"Are you there… follow the path… this world
   needs you…"* (`bible_03_act1.md:18`) and does **not** include "stay with me." Not a
   contradiction (the bible says the voice never finishes sentences and isn't
   exhaustive), but the implemented line list and the bible's example list differ. Worth
   reconciling if you want a single quoted source for the opening lines.
2. **`implementation_status.md:90`** self-notes that `dev_sandbox_scene` has "Hardcoded
   dialogue [that] does not align with current canon." Already flagged in-doc; it's a
   dev sandbox off the story path, so this is acknowledged tech debt, not a doc
   contradiction.

---

## 3. Superseded headers added

**None.** No *current* doc is superseded **by the 4-part story bible**:

- The only docs that were genuinely superseded-by-canon (`story_map.md` 21-beat list,
  the Story & Lore handoff) were **already removed 2026-05-31** — they aren't in the
  repo to header.
- The historical/ephemeral build docs (`session_log_*`, `tutorial_battle_buildlog`,
  `status_update_*`, `cleanup_analysis_*`, `whats_new_*`) are stale in a *different*
  sense — superseded by git history / `implementation_status`, **not by the story
  bible** — so stamping them "SUPERSEDED by the 4-part story bible (2026-06)" would be
  factually wrong. Left untouched; surfaced under §5 for your ruling on archival.
- The two named narrative candidates (`story_beats_plan`, `opening_scene_report`) are
  current and bible-consistent, so I did **not** unilaterally header them — they're a
  judgment call for you (§5).

Per your instruction I only had standing permission to add superseded headers; since
nothing cleanly qualifies, I added nothing and am asking before any other edit.

---

## 4. Collision ledger vs. bible

The ledger's five rows match the bible's collision set one-to-one:

| Ledger row | Bible (Act 1 plant / Act 2 payoff) | Match? |
|---|---|---|
| 1 — the bridge | `bible_03:139` / `bible_04:89` | ✅ |
| 2 — the unheard face-off | `bible_03:132` / `bible_04:78` (3-movement arc) | ✅ |
| 3 — the comrade you celebrated killing | `bible_03:161` / `bible_04:96` | ⚠️ firmness mismatch (below) |
| 4 — the kind trap (empty) | `bible_03:173` / `bible_04:102` (flagged `[GUESS]`/open hole) | ✅ |
| 5 — the camp you defended | `bible_03:90` / `bible_04:72` | ✅ |

The whole-system rules also agree (never announce; recognition is the player's;
retrieval cues mandatory; loop fixed outside / authored inside; mercy minimizes cost
except the finale).

### Proposed ledger notes (NOT applied — your call)

1. **Row 3 firmness.** The ledger states the celebrated-kill boss *is* "your Act 2
   comrade" / a party member (`collision_ledger.md:33`). The bible marks this **`[GUESS]`,
   leaning a well-drawn trusted NPC over a party member** (`bible_03_act1.md:163-166`,
   `bible_04_act2.md` Manifest line 253). **Proposed:** soften the ledger's Row 3
   surface/truth to "a comrade-or-trusted-NPC `[open]`" to match the bible's open state,
   so the ledger doesn't read as more settled than canon.
2. **Stale `Last updated` stamp.** The ledger header says `2026-05-31`, predating the
   bibles (Jun 5). Content still tracks, but the date implies it's older than canon.
   **Proposed:** bump the stamp (and add a one-line "verified against the 4-part bible
   2026-06-09") when you next touch it.

Awaiting your go-ahead before editing the ledger.

---

## 5. UNCLEAR — needs your ruling

Ordered by how much it matters.

1. **`story_beats_plan.md` — keep, slim, or supersede?** It's current (Jun 1),
   canon-consistent, and explicitly defers to the bible — *but* it's a 21 KB
   beat-by-beat sequence of both acts, which is arguably the exact "beat bible" the
   collision ledger warns against regrowing (*"Don't grow a 21-beat bible again. Grow
   the ledger,"* `collision_ledger.md:177`). It's the single biggest narrative doc
   outside the bible. **Options:** (a) keep as the WORKING ordering layer (it does
   provide sequencing the bible/ledger don't); (b) **slim** it to just the
   ~10-line "collision pairing map" and delete the prose beats; (c) supersede it
   outright. My lean: **(b) slim it** — keep the wiring table, drop the redundant prose.
2. **`opening_scene_report.md` — keep as the writer/scene reference?** Current and
   accurate to the built scene, with a correct canon note. Overlaps slightly with the
   bible's opening prose but adds the dialogue table + tone notes the bible doesn't.
   My lean: **keep as WORKING**, fix the "stay with me" line nit (§2.1).
3. **Build-doc sprawl — archive policy?** Five point-in-time docs
   (`session_log_2026-06-06`, `tutorial_battle_buildlog`, `status_update_2026-06-07`,
   `cleanup_analysis_2026-06-07`, `whats_new_2026-06`) overlap heavily with
   `implementation_status.md` and each other. They're the actual "too many docs" mass.
   **Options:** (a) move them to a `docs/archive/` folder; (b) fold the still-useful bits
   into `implementation_status` and delete; (c) keep. My lean: **(a) archive folder** —
   preserves history, declutters `docs/`. (These are out of the narrative-canon scope,
   so flagging, not acting.)
4. **`docs/levels/camp_v2.md` — supersede at the level-spec layer?** It documents the
   `camp_v2.map`, which `implementation_status.md:76` calls superseded by
   `arena_drill`/`arena_raid`. Not a narrative doc, but a stale spec. **Lean:** add a
   level-spec "superseded by arena_drill/arena_raid" note (different wording than the
   bible header).
5. **`dialogue_system.md` — still accurate?** Oldest project doc (Mar 12), predates most
   of the codebase's current state. **Lean:** quick accuracy pass, then keep or refresh.
6. **`overview.md` — keep as north-star?** Recommending **keep** (it's the best single
   entry point and the document-map index), but noting it for completeness since it's a
   second narrative-summary doc alongside the bible. It defers to the bible as ground
   truth, so there's no canon risk.

---

*No files were modified to produce this report (this report is the only new file).
Awaiting rulings on §4 (ledger edits) and §5 before any further changes.*
