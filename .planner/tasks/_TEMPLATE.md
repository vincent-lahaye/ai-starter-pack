<!--
  tasks/_TEMPLATE.md — the carve template for a chantier.
  OWNER of the carve: the PLANNER. BUILT BY: the work agent (orchestrator + Codex).
  Copy this file to tasks/<ID>-<slug>.md and fill every section. A carved task is
  the contract the orchestrator builds against. Keep it factual: real file paths,
  real anchors, no fabricated values. Sections you genuinely don't need can be
  marked "n/a" — but think before deleting one.
-->

# \<ID\> — \<chantier title\>

> **Status: PROPOSED / to-spec (opened S\<n\>, \<YYYY-MM-DD\>).** Decision
> **[[DEC-0NN]]**. **Carved by the planner** (the `.planner/` dossier); **built by
> the work agent in a fresh context**, in orchestrate-codex mode, at a clean
> boundary, **after a design pass**.
> **Do NOT start the build without:** (a) the decisions accepted (§5), (b) the API
> keys / secrets provided (§6), (c) the design pass written (§8 Lot `D0`).
> Voice/i18n + the **mandatory visual gate** apply. Hard invariants in §7.

## 0. The trigger (what prompted this)

> Why this chantier exists, in the owner's words or from a concrete observation.
> One short paragraph + the consolidated direction. State the root cause if known
> (with a file anchor), not just the symptom.

\<The owner reported / an investigation found \<symptom\>; root cause =
`<path:line>`. Consolidated direction: \<what we will do and why\>.\>

## 1. Target change (the parcours / the shape)

> What the end state looks like for the user (the journey) or for the system. Be
> concrete enough that "done" is checkable. Contrast it with today where useful.

\<The target experience / behaviour, step by step.\>

## 2. Data model / core change

> The heart of the change. What moves, what is added, what becomes an override vs
> a source of truth. Name the tables/modules/files. **No fabricated identifiers.**

\<What changes structurally, and where it lives in code.\>

## 3. External dependencies (~X % already there)

> What already exists vs what is missing, with file anchors. Distinguish "wire up
> the existing thing" from "build the new thing". Note any new third-party
> dependency (and confirm it is justified — prefer zero new deps).

**Exists:** \<what is already wired, `<path:line>`\>. **Missing:** \<the real
gaps\>.

## 4. Small returns / sub-scope (carve fast — but note the nuance)

> Minor, independently-shippable returns. ⚠️ Nuance: the main refactor (§1) may
> **rework** some of these — decide at build time whether each is standalone or
> folded into a build lot. A table keeps it honest.

| # | Return | Anchor | Survives the refactor? |
|---|--------|--------|------------------------|
| R1 | \<the small fix\> | `<path:line>` | yes / partially / folded into §1 |
| R2 | \<a "reproduce first, don't fix blind"\> | `<path:line>` | yes |

## 5. Open questions to SETTLE before carving the build

> The decisions the owner must promote first. Frame each as a question; do not
> pre-answer with a fabricated value. Link to `04-DECISIONS.md` where relevant.

1. **(confirmation)** \<the thing we expect "yes" on\>?
2. **(scope)** \<exactly what the change covers — and what it does not\>?
3. **(default)** \<the default behaviour / value the owner must set\>?

## 6. Keys / secrets needed (the owner provides)

> Any API keys, credentials, or environment values required to build/verify. They
> live in the **gitignored** project env, never committed. List only the ones
> genuinely missing.

**Present:** \<what the template already has\>. **To provide** (gitignored env,
never committed): `<KEY_A>`, `<KEY_B>`.

## 7. Invariants & guardrails (HARD)

> The lines this chantier must not cross. Pull the project-wide ones from
> `CLAUDE.md`; add the chantier-specific ones.

- **No fabricated values** (ids, prices, rates) — every number is sourced or it is
  an open question.
- **Author ≠ approver:** the orchestrator reviews every Codex diff and re-runs
  `$(TEST_CMD)` before accepting a lot.
- **Visual gate mandatory** for any UI/flow change (drive the real screen,
  screenshot, vision-check the style); backend-only lots are exempt and covered by
  `$(TEST_CMD)` on a fresh DB.
- Build = orchestrate-codex, lot by lot, clean boundary, conventional commit with
  **no AI-attribution trailer**.

## 8. Lots proposed (revisable — freeze after the design pass)

> A chantier is carved into lots. **`D0`** is a non-build design pass that
> produces a spec; then **`M0, M1, … Mn`** are build lots. **1 lot = 1 Codex unit
> = 1 commit = 1 independent review + gate.** Keep lots file-disjoint so two units
> never touch the same file.

- **`D0` — DESIGN pass (prerequisite, NON-build):** write the spec — target
  parcours (§1), data model (§2), external deps (§3), the advanced/fine-tuning
  surface (§5). Validate with the owner. **Before any code.**
- **`M0` — \<surviving small returns / first build lot\>** (§4): \<scope\>. Can
  start early if standalone.
- **`M1` — \<core build lot\>** (§2): \<scope\>. Depends on `D0`.
- **`M2` — \<next build lot\>** (§1): \<scope\>.
- **`Mn` — Cross-cutting verification + VISUAL GATE** (disposable stack) +
  fact-check any claimed value (§7) before any published copy.

## 9. Sources of truth

> The anchors that ground this carve: decision links, the real code paths
> (`file:line`), and any prior memory/notes. This is what a fresh build agent
> reads to trust the carve.

- Decision: **[[DEC-0NN]]**. Diagnosis: \<the in-the-tree investigation that
  produced §0–§4\>.
- Key code: `<path/to/module_a>`, `<path/to/module_b:line>`; front
  `<path/to/component>`.
- Related notes: [[<memory-or-doc-pointer>]], [[<another-pointer>]].

---

**▷ NEXT STEP = `D0` (design pass), once §5 (open questions) and §6 (keys) are settled with the owner.**
