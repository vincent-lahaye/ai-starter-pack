---
name: orchestrate-codex
description: Default working mode — the main Claude orchestrates and verifies while Codex executes well-scoped, disjoint units via `codex exec`. Use for refactors, multi-file features, audits, migrations, or any parallelizable build. Keywords: orchestrate, drive codex, executor mode, codex exec, handoff.
---

# Orchestrate + Codex (orchestrator/executor working mode)

The devcontainer bundles both Claude Code and the Codex CLI (`codex`, login persisted
in `.devcontainer/.codex-data/`). For substantial work the most reliable,
highest-throughput pattern is **one orchestrator + Codex as executor**, not two
free-roaming agents on the same tree (which corrupt each other's work).

This is the harness's recommended default. The orchestrator is the main Claude — the
one `make handoff` launches into tmux at ULTRACODE effort — reading `HANDOFF_FLAG.md`
and the planner's `.planner/` dossier, then delegating each build unit to Codex.

## Roles

- **Orchestrator (Claude)** — owns the **single source of truth** for the build: the
  working tree, the git history, and the `HANDOFF_FLAG.md` baton. Reads the lot pointed
  at by the `## NOW` block in `.planner/03-BACKLOG.md` (plus its `.planner/tasks/<ID>.md`),
  decomposes it into disjoint units, dispatches each to an executor, **verifies the result
  with evidence**, integrates the diff, and commits. The orchestrator **consumes** the
  `.planner/` dossier as upstream input — it never edits it (that is the planner's, written
  in a separate window).
- **Executor (Codex)** — runs **one well-scoped unit at a time** on a **disjoint set of
  files**, then reports back. The executor never touches the source of truth (no commits,
  no `HANDOFF_FLAG.md`, no `.planner/`) — it proposes a diff; the orchestrator integrates.

## Coordination rules (non-negotiable — corruption-avoidance)

1. **One writer on the source of truth.** Only the orchestrator integrates the working
   tree, commits, and rewrites `HANDOFF_FLAG.md`. The executor reports; the orchestrator
   folds the result in. Two writers race and clobber.
2. **Disjoint file units.** Two agents must never edit the same file concurrently. Scope
   each unit to a non-overlapping set of files. Use **one git branch per unit** if units
   might touch nearby code, so an integration conflict is a merge, not a corruption.
3. **One owner of any running stack/DB.** Whoever runs the app/DB/tests (via the
   `project.mk` commands) owns it; the other agent does not start conflicting services on
   the same ports or the same database.
4. **Verify before "done".** Executors are optimistic ("production-ready"). Never accept a
   self-report. The orchestrator re-runs the real checks and reviews the diff itself —
   **author != approver**.

## Dispatching Codex (`codex exec`)

Codex runs **non-interactively** with `codex exec`. The reliable pattern: **write the brief
to a scratch file**, pipe it on **stdin** (avoids shell-escaping pain — briefs carry
backticks, quotes, and paths), and capture the final message to a file. The canonical line:

```bash
codex exec --dangerously-bypass-approvals-and-sandbox --disable hooks -c multi_agent=false -o /tmp/codex-out.md - < /tmp/codex-brief.txt
```

Run it from the repo root (`/home/vincent/Projects/ai-starter-pack`). Run long units in the
**background**, **read `/tmp/codex-out.md`** for the final answer, and **monitor** — kill a
run that loops or hangs with `pkill -f 'codex exec'`; don't let it spin.

### Flags

| Flag | Why / when |
|---|---|
| `--dangerously-bypass-approvals-and-sandbox` | **YOLO** — no approvals, no FS sandbox. **Required here**, not optional: the sandboxed modes rely on bubblewrap, which fails inside this unprivileged/nested container (`bwrap: No permissions to create a new namespace`); Codex then can't even read files and (with hooks on) loops forever. YOLO skips bubblewrap entirely, so it actually runs. **Safe here** because the container is *externally* sandboxed — isolated from the host (no host docker socket; it can't reach the host daemon or your other projects). The safety net is **git + the container, not Codex's sandbox**: start from a clean, committed tree so `git` is the undo, and review the diff before accepting. Never YOLO on top of valuable uncommitted work. |
| `--disable hooks` | **Required** for non-interactive runs: the bundled oh-my-codex "Stop" hook otherwise traps `codex exec` in a post-completion loop (it keeps demanding a stop condition it can't satisfy headless). `--disable hooks` → clean exit. |
| `-c multi_agent=false` | Disables oh-my-codex's internal multi-agent fan-out, so the unit stays a single, predictable executor leg. **You** own decomposition into disjoint units — not Codex spawning sub-agents you can't see. |
| `-o, --output-last-message <FILE>` | Write Codex's final message to a file (clean capture). Convention: `/tmp/codex-out.md`. |
| `-c model_reasoning_effort="high"` | Thinking depth. Use **`high`** for deep design or tricky debugging; **omit** (the `medium` default) or use **`low`** for mechanical, well-specified units (faster, cheaper). |
| `-m, --model <model>` | Override the model set in `~/.codex/config.toml` for a single run. |

Other occasionally-useful flags: `-C, --cd <DIR>` (working root) · `--add-dir <DIR>` (extra
writable dir) · `--json` (stream JSONL progress) · `codex exec resume --last` (continue the
most recent session to iterate).

## The brief template

Write the brief to `/tmp/codex-brief.txt` and pipe it on stdin (above). Give Codex one
tightly-scoped unit:

```
# Context + hard constraints
<what this unit is part of, and the decisions it must NOT re-litigate>

# Task
<the concrete change — cite file:line so the work is grounded in real code>

# Deliverable
<a plan/spec, OR a concrete edit and exactly which files it may touch>

# Testing
The change MUST pass `$(TEST_CMD)` (from project.mk). State which tests to
add/extend and run.

# Constraints
- Stay within the listed files; touch nothing else.
- Do NOT touch HANDOFF_FLAG.md or anything under .planner/.
- (Investigation units only) Report only, edit nothing — cite file:line.
```

For a **design pass** (lot `D0`), the deliverable is a spec, the constraint is
"report only, edit nothing", and `-c model_reasoning_effort="high"` is usually warranted.
For a **build lot** (`M0 … Mn`), the deliverable is a concrete diff over a named file set.

## Verify before "done" (orchestrator)

A lot is only done after the orchestrator — not Codex — has confirmed it:

1. **Read `/tmp/codex-out.md`** for what Codex claims it did.
2. **Re-run `$(TEST_CMD)` yourself** (from `project.mk`) and confirm it passes. Do not
   trust the executor's summary; run the real command and read the real output.
3. **Review the diff** for design soundness — not just that tests pass, but that the change
   is the *right* change. For risky units, run a separate reviewer pass.
4. **For any UI or flow change**, drive the real screen(s) via the **`browse-qa`** skill
   (gstack `browse` under the hood): capture screenshots and run a **vision style check**
   (layout, spacing, theme, no broken/unstyled/overflowing elements). A UI change without
   screenshots + a vision check is **incomplete**.
5. **Confirm a clean git tree** (no stray files, nothing unstaged you didn't mean to keep),
   then **commit — 1 lot = 1 commit**. Conventional, imperative subject. **No
   AI-attribution trailers** (no "Co-authored-by", no "Generated with…", no robot-emoji
   line). Record any open follow-up explicitly so nothing is lost; the planner picks it up.

## The H24 handoff loop

The harness runs this loop unattended around the clock:

- **`make handoff`** launches Claude into a tmux session (default `agent`, env
  `HANDOFF_TMUX_SESSION`) and **arms the relay** (`.claude/hooks/handoff-watch.sh`). One
  command gives you both the drivable session and the watcher.
- The relay **watches `HANDOFF_FLAG.md`** at the repo root. When its content changes, it
  **waits for the session to go idle** (Claude no longer mid-edit/streaming), then types
  **`/clear`** followed by the instruction (env `HANDOFF_INSTRUCTION`, default: *"Read
  HANDOFF_FLAG.md at the repo root and execute the handoff now, with the usual safety
  checks."*).
- The orchestrator advances the loop by **rewriting `HANDOFF_FLAG.md` at a clean boundary**
  — after a lot is committed and the tree is clean — pointing the next cycle at the next
  lot. That rewrite is the only signal the relay needs to roll a fresh, compacted context
  into the next unit of work.

Relay control:

- `make handoff-relay ARG=start` · `ARG=stop` · `ARG=status` · `ARG=tail` — start/stop the
  watcher, check it, or follow `.handoff/logs/handoff-watch.log`.
- Set **`HANDOFF_RELAY_DISABLE=1`** to keep `make handoff` from arming the relay — launches
  the drivable session for hands-on/supervised work without the auto-advance loop.
- **ntfy is the escape valve**: when the orchestrator is blocked on a permission or has been
  idle too long, `.claude/hooks/ntfy-notify.sh` pings the owner's phone (configure via
  `.claude/hooks/ntfy.env`, copied from `ntfy.env.example`).

## When NOT to use this

- Trivial one-offs, single-file edits, quick lookups → just do them directly; spinning up an
  executor is overhead.
- When you need a second *model's perspective* rather than execution → an advisory ask
  (e.g. `omc ask codex`) is the lighter tool.

---
File written: /home/vincent/Projects/ai-starter-pack/.claude/skills/orchestrate-codex/SKILL.md
