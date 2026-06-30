<!--
  00-CHARTER.md — the founding document of the .planner/ dossier.
  OWNER: the PLANNER (the 2nd Claude window running the `planner` skill).
  This file states the mission, the non-negotiables, the working method, and the
  glossary. It is the first thing a fresh agent reads. Edit it deliberately:
  everything else in .planner/ is downstream of what is written here.
-->

# Charter & orchestration manual

> **Founding document. If you are an agent picking this work up in a fresh
> session, read this file in full, then the `## NOW` block at the top of
> `03-BACKLOG.md`, then the latest entry in `99-JOURNAL.md`. That is the entire
> onboarding ritual.**

Last reviewed: **<YYYY-MM-DD>** · Owner: **you** (the project owner) · Orchestrator: **Claude**

---

## 1. The mission (the north star)

> Replace this section with your project's mission. Keep it short, concrete, and
> testable — one paragraph that a fresh agent can read and immediately know what
> "done" means.

**Mission:** <state your project's mission>.

**Definition of "done" (promoted by the owner):** <state the single, checkable
condition that means the mission is accomplished>. No invented deadlines, no
vanity thresholds — name the one outcome that closes the mission.

This is the most important project on the board. We move deliberately: we verify
before we declare something "done", and we never break what is already live.

---

## 2. The non-negotiables (read before touching anything)

1. **Production never breaks.** If anything is live, real users depend on it. No
   change reaches them without an explicit green light. Git is the undo: every
   unit of work starts from a clean, committed tree.
2. **Code merged ≠ task done.** A large fraction of "finishing" almost always
   means deploy + verify in the real environment + fix the known defects — not
   writing something new. "The tests pass" is the command output; "it works" is a
   live run or a browser-driven check.
3. **Single source of truth.** This dossier never re-copies what already lives in
   the repo (README, `CLAUDE.md`, code). When a source is wrong or stale, **fix
   it at the source** (a dedicated task), never keep a corrected copy here that
   silently diverges.
4. **Public repo, build-in-public.** Assume contributors will read the git
   history. **No secrets in any committed file** (no real hostnames, keys, PII).
   This `.planner/` dossier is gitignored precisely so it can carry private
   working context without ever exposing it.
5. **Go through the single command surface** (`make help`) and the project skills
   — no hand-rolled commands. Every functional/UI check goes through the
   browser-driven QA gate (see `CLAUDE.md` "Testing rule").

---

## 3. The working method (the spirit of this dossier)

The guiding principle: **nothing is set in stone. Everything is living, dated, and
carries its assumptions in the open** — so a misunderstanding shows itself and
gets corrected at zero cost. The lesson behind this: an agent proposes options,
you decide fast, but if a debatable "decision" gets carved in as settled it
pollutes everything downstream.

- **The planner proposes, the owner promotes.** A decision only reaches `ACCEPTED`
  with an explicit "yes" from the owner. And `ACCEPTED` stays revisable (see the
  format in `04-DECISIONS.md`).
- **Single source of truth.** `.planner/` never duplicates what lives in the repo.
  If a source is wrong → **fix the source** (a dedicated task), don't maintain a
  parallel truth.
- **Never fabricate.** Names, prices, dates, paths: if you don't know, say so and
  verify. A confident guess written as fact is worse than an open question.
- **Delegate hard.** For broad/deep work, fan out to sub-agents and to Codex:
  read-only mapping, design passes, multi-step build/research. Keep the
  *conclusions* in `.planner/`, not the raw dumps. Sub-agents are optimistic
  ("production-ready") → verify with evidence.
- **Author ≠ approver.** The orchestrator reviews every Codex diff and re-runs
  `$(TEST_CMD)` itself before accepting a lot. Multi-agent workflows are a heavy
  lever — use them on the owner's explicit opt-in.
- **Never "done" without proof.** Evidence before assertions, always.

### Start-of-session ritual (handoff to a fresh agent)

1. Read this charter.
2. Read the `## NOW` block at the top of `03-BACKLOG.md` — the single action
   pointer.
3. Read the latest entry in `99-JOURNAL.md` for context.
4. On any ambiguity, ask the owner before acting.

### End-of-session ritual

1. Update the statuses in `03-BACKLOG.md` and the `## NOW` block.
2. Add a dated and **closed** entry to `99-JOURNAL.md` (what happened + what we
   learned). The journal is immutable history: never write the *next* action
   there — it lives in `## NOW`.
3. Any decision taken / to take → `04-DECISIONS.md`.
4. If the real state of the repo changed → `01-STATE.md`.

---

## 4. Glossary

- **Planner** — a 2nd Claude window running the `planner` skill. Owns this
  `.planner/` dossier (decisions, backlog, roadmap, task carving). Turns the
  owner's input into decisions + carved task files + a queued backlog. **Never
  writes project code.** Principle: *propose before you carve.*
- **Orchestrator** — the main Claude, launched by `make handoff`, living in a
  tmux session (`agent`) that the relay drives. Reads `HANDOFF_FLAG.md` + the
  dossier, **delegates** each build unit to Codex, **verifies** with evidence,
  commits (1 lot = 1 commit), then rewrites `HANDOFF_FLAG.md` at a clean boundary.
- **Codex (executor)** — invoked by the orchestrator, one disjoint file-unit at a
  time. Touches no source-of-truth; reports back; the orchestrator integrates.
  Golden rule: never let two agents free-roam the same tree.
- **Chantier** — a work item (a feature, refactor, audit, migration). Has a
  stable ID and a status (`TODO | DOING | REVIEW | DONE | BLOCKED`).
- **Lot** — a chantier is carved into lots: **`D0`** = a design pass (non-build,
  produces a spec), then **`M0, M1, … Mn`** = build lots. 1 lot = 1 Codex unit =
  1 commit = 1 independent review + gate.
- **Handoff** — the moment the orchestrator stops at a clean boundary and rewrites
  `HANDOFF_FLAG.md` so a fresh agent (or the relay) can pick the work back up.
- **The baton** — `HANDOFF_FLAG.md` at the repo root: the file the relay watches.
  Whoever holds a clean, committed tree and a fresh `## NOW` holds the baton.
