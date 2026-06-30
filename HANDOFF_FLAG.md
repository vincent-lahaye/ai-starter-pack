<!--
  HANDOFF_FLAG.md — THE BATON. This is a TEMPLATE: overwrite it at every handoff.

  The relay (.claude/hooks/handoff-watch.sh) watches this file. When its content
  changes, it waits for the orchestrator's tmux session to go idle, types /clear,
  then types the standing instruction — which sends the orchestrator back to the
  top of this file. So: only rewrite this when the tree is CLEAN and the NEXT step
  is unambiguous. Saving it = pulling the lever.

  This shipped copy is filled in as a first example for a fresh repo. Replace
  every section with your real state. Keep the structure; change the content.
-->

# HANDOFF_FLAG

STATUS: READY — fresh repo, awaiting first chantier from the planner.

## HAND-OFF NOTE (to the owner)

Welcome. The harness is wired but your project isn't in it yet. Before this baton
can drive real work:

1. Copy `project.mk.example` → `project.mk` and fill in your build commands
   (`TEST_CMD`, `LINT_CMD`, `DEV_CMD`, …). The orchestrator verifies through
   these — they must be real.
2. Open the **planner** in a second window (`make planner`) and let it carve the
   first chantier into the `.planner/` dossier, with a `## NOW` pointer in
   `03-BACKLOG.md`.
3. Overwrite this file with a real hand-off note pointing at that first lot, then
   save — the relay takes it from there.

Until `## NOW` names a concrete lot, there is nothing to build: confirm the tree
is clean and wait for the planner.

## DONE

- Harness scaffolding in place (devcontainer, relay hooks, skills, dossier
  skeleton). Nothing project-specific has been built yet.

## NEXT

- Read the dossier. If `.planner/03-BACKLOG.md` `## NOW` names a lot, pick it up,
  delegate it to Codex, verify, commit, and rewrite this baton. If `## NOW` is
  empty, stop and wait for the planner — do not invent work.

## ABSOLUTE RULES

- Never let two agents free-roam the same tree. Disjoint Codex units only.
- **Author ≠ approver:** review every Codex diff and re-run `$(TEST_CMD)` yourself
  before accepting a lot.
- 1 lot = 1 Codex unit = 1 commit. Every unit starts from a clean, committed tree.
- UI or new-flow change → drive the real screen through browse QA, screenshot it,
  and vision-check the style before calling it done.
- Commits carry **no** AI-attribution trailers; conventional, imperative subjects.
- Don't fabricate. If a command, path, or decision is unknown, verify or stop.

## READING ORDER

1. `.planner/00-CHARTER.md` — the mission and its invariants.
2. The `## NOW` block in `.planner/03-BACKLOG.md` — the single action pointer.
3. The latest entry in `.planner/99-JOURNAL.md` — what just happened.
4. The active `.planner/tasks/<ID>.md` — the unit's spec.

## COMMIT CONVENTIONS

- Conventional, imperative subjects: `feat: …`, `fix: …`, `docs: …`, `refactor: …`.
- One lot per commit, from a clean tree.
- No `Co-authored-by: Claude`, no `Generated with…`, no robot-emoji line.

<!-- smoke line: if you can read this, the relay cleared context and re-instructed you — start at the READING ORDER above. -->
