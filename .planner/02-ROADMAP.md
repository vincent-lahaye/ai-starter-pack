<!--
  02-ROADMAP.md — the plan and its reasoning, as PHASES (P0..P4).
  OWNER: the PLANNER. This is a PROPOSAL (the per-item status lives in
  04-DECISIONS.md), refined with the owner. It carries the "why" of the
  sequencing; the day-to-day pointer lives in 03-BACKLOG.md `## NOW`.
-->

# 02 — Roadmap, phases & sequencing

> The plan and its reasoning. This is a **proposal** (decision-level status lives
> in `04-DECISIONS.md`), to be refined with the owner. The roadmap is
> *milestone-gated*, not *date-gated*: a phase ends when its exit criteria are
> met, not on a calendar date. Replace the placeholder milestones below with your
> project's real phases.

```
P0  Orchestration foundation     <- this .planner/ dossier + the handoff loop
      |
P1  Close the product core       ---------------+
    - P1.1 <build the spine>                     |  (in parallel where surfaces
    - P1.2 <second surface>                      |   are independent; few deps)
    - P1.3 <fill the gaps>                       |
      |                                          |
P2  <Migration / cutover apparatus>  <-----------+
    - P2.1 <new capability A>
    - P2.2 <new capability B>
    - P2.3 <user-facing surface>
      |
P3  Pre-production validation
    - P3.1 <validation environment>  (an open decision — see 04-DECISIONS.md)
    - P3.2 <end-to-end validation, real backing services>
    - P3.3 <runbooks + observability>
      |
P4  Cutover / public launch
    - <pre-launch notice / comms, if any>
    - <public launch + monitoring>
```

---

## Reasoning per phase

### P0 — Orchestration foundation
Stand up the working method itself: this `.planner/` dossier, the handoff loop
(`HANDOFF_FLAG.md` + the relay), and the project seam (`project.mk`). Done when a
fresh agent can onboard from the charter and pick up the baton cleanly.

### P1 — Close the product core
The "finish, don't build" trio. Reframe each item as *finishing* existing work
where possible (deploy + verify + fix known defects) rather than net-new
construction. Order the spine first; run independent surfaces in parallel.

### P2 — <Migration / cutover apparatus>
The net-new work that the launch depends on. Usually depends on P1 (the thing it
migrates/cuts over to). Sequence it after the core is closed.

### P3 — Pre-production validation
Be sure it works before the public sees it. The *validation environment* is often
an **open decision** (local first, a separate test cluster, or staging) — keep it
in `04-DECISIONS.md` until promoted.

### P4 — Cutover
Any pre-launch notice/comms first, then the public launch, then monitoring.

---

## Cross-cutting threads (always active)
- **Don't break production** at every step.
- **Build-in-public hygiene:** zero secrets in committed files.
- **Verification discipline:** functional checks via the browser-driven QA gate;
  anything money/data-adjacent verified against the real backing services in a
  safe environment.
