<!--
  03-BACKLOG.md — the pilot file (the day-to-day driver).
  OWNER: the PLANNER. The `## NOW` block below is THE single action pointer: the
  one place that says what is being worked on right now. The orchestrator reads
  it first. Keep exactly one ACTIVE chantier in `## NOW`; everything else lives
  under "NEXT (queued)" or "PREVIOUS (closed)". Never let two chantiers be ACTIVE.
-->

# 03 — Backlog (the day-to-day driver)

Statuses: `TODO` · `DOING` · `REVIEW` · `DONE` · `BLOCKED`.
Priority: `P0` (now) … `P3` (later). "Dep" = prerequisite tasks.
IDs are stable. One `tasks/<ID>.md` file for any task that overflows a single line.

---

## NOW  *(single pointer to the in-flight action — the only source)*

> The `## NOW` block holds exactly **one** ACTIVE chantier. Everything below it is
> queued or closed. The example below is a **placeholder** — replace it with your
> real active chantier, or set it to "No active chantier — pick the next one with
> the owner" when the tree is clean and nothing is in flight.

### NOW — ACTIVE: `EXMPL` — \<short chantier title\> [[DEC-001]]   *(placeholder — replace me)*

- **STATUS:** `DOING` · **PRIORITY:** P0 · **Opened:** session 1, \<YYYY-MM-DD\>
- **PHASE:** BUILD — design pass `D0` accepted; building lot by lot.
- **DONE so far:** `D0` (spec written, accepted) · `M0` (`<commit>`, reviewed +
  gated) · `M1` (`<commit>`, reviewed + gated).
- **NEXT:** `M2` — \<one line on the next build lot\> — buildable now / **gated on
  \<decision or key\>**.
- **Gate:** browser-driven visual QA (drive the real screen, screenshot,
  vision-check the style) is **mandatory** before this chantier closes; backend-
  only lots are exempt and covered by `$(TEST_CMD)` on a fresh DB.
- **Carve:** full scope in `tasks/EXMPL-<slug>.md`; design spec in
  `tasks/EXMPL-D0-design.md`.
- **Invariants:** author ≠ approver; 1 lot = 1 Codex unit = 1 commit = 1 review +
  gate; clean tree at every boundary; no fabricated values.

---

## NEXT (queued)

> Chantiers carved and ready, in priority order. Pick the top one at the next
> handoff once the active chantier closes. **Do NOT start** a chantier without
> (a) its decisions accepted, (b) any required keys provided, (c) a written `D0`
> design pass.

- **P1 · `EXMPL2` — \<title\>** [[DEC-002]] — carved by the planner; **take at the
  next handoff** once `EXMPL` is in good shape. Scope: `tasks/EXMPL2-<slug>.md`.
  Blocked on: \<the one prerequisite\>. **Next step = `D0` (design pass).**
- **P2 · `EXMPL3` — \<title\>** — idea captured, **not yet carved** (propose
  before you carve). Needs a decision from the owner first.

---

## PREVIOUS (closed)

> Closed chantiers, newest first. One line each: ID, what shipped, the commits,
> and that the gate passed. Detail lives in each `tasks/<ID>.md` and in
> `99-JOURNAL.md` — do not re-narrate it here.

- **`EXMPL0` — \<title\>** — CLOSED (session 0, \<YYYY-MM-DD\>). Lots `M0`→`Mn`
  shipped / verified / gated (`<commit>`, `<commit>`). Visual gate PASS. No active
  follow-up. Detail: `tasks/EXMPL0-<slug>.md` + `99-JOURNAL.md`.
