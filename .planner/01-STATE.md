<!--
  01-STATE.md — the gap analysis: what is coded vs deployed vs verified.
  OWNER: the PLANNER. Update it only when the real state of the repo changes.
  Single source of truth: this file does NOT re-copy what already lives in the
  repo or in CLAUDE.md (layout, commands, architecture). It keeps ONLY the honest
  "done vs to-do" gap analysis that is documented nowhere else.
-->

# 01 — State of the real (gap analysis)

> What we know about the real state of the project, zone by zone, with an honest
> "done vs to-do" verdict. **Code that exists ≠ verified/deployed.**
>
> **Single source of truth:** this file does not re-copy what lives elsewhere. The
> *repo layout*, the command surface, and the architecture invariants are
> described in `CLAUDE.md` (kept current) — we refer to them, we do not duplicate
> them here. Below we keep only the gap analysis documented nowhere else.

Snapshot: **<YYYY-MM-DD>**

---

## How to read this file

Each zone gets a one-line verdict in the table, then a short paragraph that
explains *why it is not "done"* — the concrete gap, with a pointer to the source
(file path, test name, task ID). The point is to keep "looks finished" and
"actually verified in the real environment" clearly separated.

Verdict vocabulary: **coded** (written, not run anywhere real) · **deployed**
(running in the target environment) · **verified** (proven by tests + a live/
browser-driven check) · **missing** (does not exist yet).

| Zone | Coded | Deployed | Verified | One-line gap |
|------|:-----:|:--------:|:--------:|--------------|
| _\<core feature A\>_ | yes | no | no | _written, never run against the real backing service_ |
| _\<core feature B\>_ | yes | yes | partial | _live, but one known defect tracked as [[DEC-0NN]] / a failing canary_ |
| _\<surface C\>_ | partial | no | no | _scaffolded, copy is a WIP_ |
| _\<migration / cutover apparatus\>_ | no | no | no | _nothing exists yet (all new)_ |

> The rows above are **placeholders** — replace them with your project's real
> zones. Keep the table short (the surfaces that matter), and let the prose below
> carry the detail.

---

## _\<Zone name\>_ — *coded, NEITHER deployed NOR verified*

> Example zone. Describe what exists in code (with a file pointer), then state
> plainly why it is not "done".

Implementation is advanced in `<path/to/module>`: <one sentence on what is there>.

**Why this is NOT "done":**

- **Neither deployed nor verified for real** against the actual environment.
- **Known defect** (tracked): <one sentence> — test: `<path::test_name>`.
- **No <missing piece>** anywhere yet (see the migration/cutover section).

---

## _\<Zone name\>_ — *exists, ~complete, to validate/finish*

> Example zone. Something that is built and roughly complete but needs a
> validation pass before it counts as done.

<One sentence on what exists and where.>

**Gap:** <the deferred checks — build, visual review, copy alignment — and where
they are tracked>.

---

## Sources to correct (single truth)

> When you find a source (a README, a CLAUDE.md line, a comment) that is stale or
> wrong, list it here and carve a correction task — never patch a copy in this
> dossier. Example:
>
> - `<path/to/FILE>` still claims `<stale fact>` — **outdated**. → correction task
>   `<ID>`.

---

## Environment notes (memory reminders)

> Short, durable gotchas about the dev environment that are not worth a full task
> but you do not want to rediscover. Examples:
>
> - Shared devcontainer; persistent state lives under `.devcontainer/.claude-data/`
>   and `.devcontainer/.home/`.
> - Deterministic dev ports; the project seam (`project.mk`) carries the real
>   commands (`$(UP_CMD)`, `$(DEV_CMD)`, `$(TEST_CMD)`, …) — never hardcode them.
