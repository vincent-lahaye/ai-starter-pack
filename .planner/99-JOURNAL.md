<!--
  99-JOURNAL.md — immutable session history.
  OWNER: the PLANNER (and the orchestrator at end-of-session). One dated, CLOSED
  entry per session, newest on top. NEVER write the next action here — the next
  action lives in 03-BACKLOG.md `## NOW`. The journal records what happened and
  what we learned; it is append-mostly history, not a plan.
-->

# 99 — Session journal (history)

> **Immutable history.** One dated and **closed** entry per session: what
> happened + what we learned. **Never** write the next action here — it lives in
> the `## NOW` block at the top of `03-BACKLOG.md` (the single pointer). Newest on
> top.

---

## \<YYYY-MM-DD\> — Session 1 · **\<one-line headline: what shipped / what was decided\>**   *(example entry — replace me)*

> This is a **skeleton** of a closed entry. Replace it with your first real
> session, and add new entries above it as you go. A good entry is concrete:
> commits, evidence, and one honest lesson.

Picked up the handoff from session 0 ("\<what the previous `## NOW` said\>").
**Safety preflight OK:** on the default branch, clean tree, no `codex exec`
running, a single relay active.

**What happened.** \<2–5 sentences. The lots built, the Codex units dispatched,
the decisions the owner made in-session. Name the commits and the surfaces
touched.\>

**Verification (evidence, author ≠ approver).** \<What you actually ran and saw:
`$(TEST_CMD)` on a fresh DB → N passed; `$(LINT_CMD)` clean; an independent code
review verdict; the browser-driven visual gate PASS (screenshots + vision style
check) or EXEMPT (backend-only).\>

**Committed `<commit>`** (\<N files\>, conventional subject, no AI-attribution
trailer). Tree clean at the boundary; `HANDOFF_FLAG.md` rewritten.

**Next** lives in `03-BACKLOG.md` `## NOW` — not here. **Learned:** \<one durable
lesson — a gotcha, a pattern that worked, a wrong assumption corrected.\>

---

<!--
  Add new sessions ABOVE this line, newest on top. Suggested heading shape:

  ## <YYYY-MM-DD> — Session N · **<headline>**

  Keep each entry CLOSED: it describes a finished session. If work is still in
  flight, that belongs in 03-BACKLOG.md `## NOW`, not in a journal entry.
-->
