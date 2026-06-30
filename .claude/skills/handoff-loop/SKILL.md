---
name: handoff-loop
description: Pass the baton to the next orchestrator session by writing HANDOFF_FLAG.md at a clean boundary. Use at the END of a work session, once the tree is committed, to hand off autonomous work. The relay watches HANDOFF_FLAG.md, waits for idle, then /clear + restarts the orchestrator on the fresh dossier state. Keywords: handoff, baton, HANDOFF_FLAG, relay, passation, continue the loop.
---

# Hand off the loop (write HANDOFF_FLAG.md)

This is how one orchestrator session passes the baton to the next one, so the
autonomous build loop keeps running 24/7 without a human in the chair.

**Not the same as the Superpowers `handoff` skill.** That one compacts the
current conversation into a summary so a fresh agent can resume *the same task*.
This skill is the opposite end: you have **finished** a lot, the tree is clean
and committed, and you are deliberately ending your session so the **relay**
spins up a brand-new orchestrator on the latest dossier state. The artifact is a
file — `HANDOFF_FLAG.md` at the repo root — not a chat summary.

## How the relay works (so you write the flag at the right moment)

A background watcher (`.claude/hooks/handoff-watch.sh`, armed by `make handoff`)
watches `HANDOFF_FLAG.md`. When its content **changes**, the relay:

1. waits for your session to go **idle** (pane unchanged for a few seconds — it
   never types into a busy session),
2. types `/clear` + Enter into the tmux session and lets it settle,
3. types `HANDOFF_INSTRUCTION` (default: *"Read HANDOFF_FLAG.md at the repo root
   and execute the handoff now, with the usual safety checks."*) + Enter.

The next orchestrator wakes up with a clean context and reads the flag you wrote.
So the flag IS the only message the next session gets — make it self-contained.

## WHEN to write it (hard sequence — do not shortcut)

Write the flag **only** at a clean boundary, at the very end of your session:

1. The current lot is **fully done and verified** (you re-ran `$(TEST_CMD)`
   yourself; author != approver).
2. The working tree is **clean** — every change is committed (`git status`
   reports nothing to commit). Git is the undo; the next session must start from
   a committed tree.
3. The dossier is current — `.planner/03-BACKLOG.md` `## NOW`, `99-JOURNAL.md`,
   and any active `tasks/<ID>.md` reflect reality.
4. **Then** rewrite `HANDOFF_FLAG.md` and commit it as its **own** atomic commit
   (e.g. `chore(handoff): pass baton after M3`). That commit is the content
   change the relay fires on.

Never write the flag mid-edit, with a dirty tree, or "to save progress" — that
hands a broken boundary to the next session. If you are not at a clean stop,
keep working or stop without touching the flag.

## FLAG TEMPLATE

Overwrite `HANDOFF_FLAG.md` with this structure (fill every section):

```markdown
# HANDOFF FLAG

## STATUS
- Session: <short id / date>
- Phase: <chantier + lot, e.g. "auth-rework / M3 of M0..M5">
- Delivered this session: <one or two lines on what now works and is committed>

## HAND-OFF NOTE (for the human owner)
Plain language, no jargon. What changed, what the owner would see if they looked
at the app right now, and anything they personally need to decide or unblock.
Two to four sentences. This is the part a non-engineer reads.

## DONE
- <committed lot / fix, with the commit subject or short SHA>
- <verification evidence: which tests ran green, which screen was vision-checked>

## NEXT
- <the single next action — should match `## NOW` in 03-BACKLOG.md>
- <any carved tasks/<ID>.md the next session should open first>

## ABSOLUTE RULES
- Never break a working deploy. If a change can't be verified, do not ship it.
- The tree stays clean: start from a committed tree, end on a committed tree.
- Git is the undo. Every Codex unit begins from a clean boundary; review the
  diff before accepting (author != approver). Never run yolo on dirty work.
- One writer on the source of truth (the orchestrator). Disjoint file units.

## READING ORDER (next session: read in this order)
1. `.planner/00-CHARTER.md` — the mission and guardrails.
2. `## NOW` block in `.planner/03-BACKLOG.md` — the single action pointer.
3. Latest entries in `.planner/99-JOURNAL.md` — what just happened and why.
4. The active `.planner/tasks/<ID>.md` for the lot named in NEXT.

## COMMIT CONVENTIONS
- Atomic commits: 1 lot = 1 commit. The handoff flag is its own commit.
- Conventional, imperative subjects (e.g. `feat(api): add token refresh`).
- NO AI-attribution trailers (no "Co-authored-by: Claude", no "Generated
  with...", no robot-emoji line). The git hooks strip/reject them anyway.

## SMOKE
<one command the next session can run to confirm the stack is healthy before it
starts — e.g. `make up && make test` — and the expected good result.>
```

## After you write it

Commit the flag, then **stop** (let your turn end). Do not keep typing — the
relay needs your pane to fall idle before it can drive `/clear`. If `make
handoff` was never started, the change is simply queued: the relay fires the
moment the drivable session comes up. Check `.handoff/logs/handoff-watch.log` if
a handoff seems stuck.
