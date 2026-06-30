---
name: app-run-tests
description: Run the owner's project test suite through the harness. Runs $(TEST_CMD) (and $(LINT_CMD)) defined in project.mk via `make test`. This is a TEMPLATE — the owner fills project.mk and flesh out this skill with their project's real test specifics (known-good baseline, slow/integration markers, how to run a single test). Use to verify a change before committing or accepting a lot.
---

# Run the project tests

> **TEMPLATE skill.** The harness ships no application, so it cannot know how
> your project tests. This skill bridges to whatever your project uses through
> one seam: `project.mk`. Fill that file, then replace the `<fill-in>` markers
> below with your project's real specifics. Keep this skill honest — it is the
> orchestrator's verify gate (author != approver).

## The seam: project.mk

The root `Makefile` does `-include project.mk` (gitignored). Copy the example
and set the command:

```bash
cp project.mk.example project.mk
# then edit:  TEST_CMD = <your real test command, e.g. pytest -q  /  bun test  /  go test ./...>
#             LINT_CMD = <your real lint command>
```

`make test` runs `$(TEST_CMD)`; `make lint` runs `$(LINT_CMD)`. Never hardcode a
test runner into a skill or the orchestrator — always go through these vars.

## Run

```bash
make test    # runs $(TEST_CMD) from project.mk
make lint    # runs $(LINT_CMD) from project.mk
```

Targeted runs (preferred when verifying a single change — faster, sharper
signal). Fill in with your runner's real syntax:

```bash
<fill-in: run a single test file, e.g. pytest tests/test_x.py -q>
<fill-in: run by keyword/name, e.g. pytest -k "auth" -q  /  bun test -t "login">
```

## Known-good baseline (fill this in)

Record what "green enough" means for **your** project so a session can tell a
real regression from pre-existing debt:

- Known-green anchor: `<fill-in: a suite/file that must always pass, and its count>`
- Pre-existing failures to ignore (if any): `<fill-in: list, or "none — full suite must be green">`
- Slow / integration / live tests gated behind a flag: `<fill-in: marker + how to opt in, e.g. --run-slow needs an API key>`

## Interpreting results

If your targeted test passes and the only failures are in the documented
baseline above, the change is clean. A non-zero exit on the **full** suite is
only acceptable if it matches a baseline you have written down here — otherwise
treat it as a regression and do not accept the lot.
