# ai-starter-pack

A drop-in, language-agnostic harness that runs an autonomous **Claude + Codex**
development loop 24/7 inside a devcontainer. You drop your own project into the
repo and point one seam file at your build commands; the harness drives the
work — a **Planner** turns your intent into carved tasks, an **Orchestrator**
delegates each build unit to **Codex**, verifies it with evidence, commits, and
hands off to itself again. It ships **no application, no database, no storage** —
only the method, the devcontainer, the skills, and the handoff loop.

---

## The loop

```
                     ┌──────────────────────────────────────────────────┐
                     │                   YOU (owner)                    │
                     │   drop your project in · steer · read ntfy       │
                     └───────────────────┬──────────────────────────────┘
                                         │ intent · feedback
                                         ▼
   ┌─────────────────────────┐  carves   ┌──────────────────────────────┐
   │  PLANNER                │──────────▶│  .planner/ dossier           │
   │  2nd Claude window      │ decisions │  00-CHARTER  01-STATE        │
   │  `make planner`         │  + queued │  02-ROADMAP  03-BACKLOG(##NOW)│
   │  propose-before-carve   │  backlog  │  04-DECISIONS  99-JOURNAL    │
   │  never writes code      │           │  tasks/<ID>.md               │
   └─────────────────────────┘           └───────────────┬──────────────┘
                                                          │ reads
                                                          ▼
   ┌──────────────────────────────────────────────────────────────────────┐
   │  ORCHESTRATOR   main Claude · `make handoff` · tmux `agent` · ULTRACODE │
   │  reads HANDOFF_FLAG.md + dossier → DELEGATES each lot → VERIFIES        │
   │  ( $(TEST_CMD) + browse QA ) → commits (1 lot = 1 commit) →             │
   │  rewrites HANDOFF_FLAG.md at a clean boundary                          │
   └────────┬───────────────────────────────────────────┬──────────────────┘
            │ codex exec (one disjoint file-unit)        │ rewrites flag
            ▼                                            ▼
   ┌─────────────────────────┐  diff + report  ┌──────────────────────────┐
   │  CODEX (executor)       │────────────────▶│  HANDOFF_FLAG.md (baton) │
   │  yolo · sandboxed       │  back to orch.  └─────────────┬────────────┘
   │  one unit at a time     │                               │ file change
   └─────────────────────────┘                               ▼
                                           ┌──────────────────────────────┐
                                           │  RELAY  handoff-watch.sh      │
                                           │  wait for idle → type /clear  │
                                           │  + instruction ───────────────┼─┐
                                           └──────────────────────────────┘ │
                                                                            │
              ntfy ──▶ 📱  phone escape valve                              │
              (blocked on a permission · idle too long)    loops back to ──┘
                                                           the ORCHESTRATOR
```

The orchestrator perpetuates the loop **itself**: when it finishes a lot it
rewrites `HANDOFF_FLAG.md`; the relay notices the file changed, waits until the
session is idle, types `/clear` to drop stale context, then types the standing
instruction — and the orchestrator reads the fresh flag and continues. Round
and round, unattended, with `ntfy` pinging your phone only when it is genuinely
stuck.

---

## Start in 90 seconds

1. **Open the repo in the devcontainer** (VS Code: *Reopen in Container*). The
   image bundles the whole toolchain — Claude Code, Codex, tmux, Chromium, uv,
   bun — so there is nothing else to install.

2. **Point the harness at your project.** Copy the seam file and fill in your
   real commands:

   ```bash
   cp project.mk.example project.mk      # project.mk is gitignored
   $EDITOR project.mk                    # set TEST_CMD, LINT_CMD, DEV_CMD, …
   ```

3. **Launch the orchestrator** in one terminal:

   ```bash
   make handoff        # starts Claude in tmux session `agent` + arms the relay
   ```

4. **Launch the planner** in a second terminal (a separate Claude window):

   ```bash
   make planner        # opens the planner role on the .planner/ dossier
   ```

5. **Write the first baton.** Overwrite `HANDOFF_FLAG.md` with your first
   hand-off note (the file ships pre-filled as a template — see its header). The
   moment you save it, the relay drives the orchestrator and the loop begins.

That's it. The planner keeps the backlog full; the orchestrator keeps building.

---

## The three roles

Three agents, three jobs, three hard boundaries. They never free-roam the same
tree.

> **GOLDEN RULE — never let two agents free-roam the same tree.** One writer on
> the source-of-truth; disjoint file units; **author ≠ approver.** Git is the
> undo button between every unit.

### 1. Planner

A **second Claude window**, running the `planner` skill. It **owns the
`.planner/` dossier** and nothing else. It turns your input into decisions,
carved task files, and a queued backlog — but **never writes project code**. Its
guiding principle is **"propose before you carve":** surface a decision and its
assumptions, let you promote it, then carve the work. The single action pointer
for the orchestrator is the `## NOW` block inside `.planner/03-BACKLOG.md`.

### 2. Orchestrator

The **main Claude**, launched by `make handoff`, living in a tmux session the
relay drives. It runs at **ULTRACODE** effort. Each cycle it reads
`HANDOFF_FLAG.md` plus the dossier, **delegates** each build unit to Codex,
**verifies with evidence** (re-runs `$(TEST_CMD)` itself, drives the UI through
browse QA), commits (**1 lot = 1 commit**), then **rewrites `HANDOFF_FLAG.md`**
at a clean boundary to trigger the next cycle. It owns the source-of-truth and is
the approver — it does not let Codex self-certify.

### 3. Codex (executor)

Invoked by the orchestrator, **one disjoint file-unit at a time** via
`codex exec`. It touches no source-of-truth document, does its scoped unit,
reports back with a diff, and the orchestrator integrates and reviews. Codex is
the hands; it never holds the plan.

---

## The `project.mk` seam

`project.mk` is the **single place** the generic harness meets your real
project. The root `Makefile` does `-include project.mk`, so every skill and the
orchestrator's verify step call **your** commands through these variables —
nothing project-specific is ever hardcoded in the harness. Copy
`project.mk.example` to `project.mk` (gitignored) and fill it in:

| Variable         | What it is                                              | Example                       |
|------------------|---------------------------------------------------------|-------------------------------|
| `TEST_CMD`       | Run the test suite (the orchestrator re-runs this)      | `pytest -q`                   |
| `LINT_CMD`       | Lint / static analysis                                  | `ruff check . && eslint .`    |
| `RESET_DB_CMD`   | Reset to a clean dev database (no-op if you have none)  | `./scripts/reset-db.sh`       |
| `UP_CMD`         | Bring up backing services                               | `docker compose up -d`        |
| `DEV_CMD`        | Start the app for manual / browse QA                    | `npm run dev`                 |
| `BOOTSTRAP_CMD`  | One-time install / setup                                | `uv sync && npm install`      |

Leave any line blank or as a harmless no-op (`true`) if it doesn't apply — the
harness only invokes what it needs for a given step.

---

## How Codex is driven

The orchestrator hands each unit to Codex with one canonical, non-interactive
invocation:

```bash
codex exec --dangerously-bypass-approvals-and-sandbox --disable hooks \
  -c multi_agent=false -o /tmp/codex-out.md - < /tmp/codex-brief.txt
```

- Add `-c model_reasoning_effort="high"` for deep design or debugging units;
  omit it (medium default) or use `"low"` for mechanical, low-ambiguity units.
- The **yolo flags are required** because the devcontainer is *externally*
  sandboxed — bubblewrap can't nest inside an unprivileged container, so Codex
  cannot self-sandbox. `--disable hooks` stops the oh-my-codex Stop hook from
  trapping a non-interactive run.

**Verify before done.** A lot is not finished when Codex says so. The
orchestrator reviews the diff, **re-runs `$(TEST_CMD)` itself**, and — for any UI
or new-flow change — drives the real screen through browse QA. Evidence before
assertion, every time.

**Author ≠ approver.** Codex writes; the orchestrator reads, tests, and accepts
or rejects. The agent that produced a change never gets to certify it.

---

## The safety model

- **Git is the undo.** Every Codex unit starts from a clean, committed tree, so
  any unit can be thrown away with one `git restore` / `git reset`.
- **Yolo-Codex is safe *only because the container is externally sandboxed*.**
  Never point this loop at valuable uncommitted work outside the container, and
  never run it on a host where Codex's bypass flags would touch real
  infrastructure.
- **Author ≠ approver.** The orchestrator independently verifies every diff
  before a lot is accepted.
- **`ntfy` is the human escape valve.** It pings your phone when the orchestrator
  is blocked on a permission prompt (immediately, high priority) or has sat idle
  too long (after a delay, cancelled the moment you return).
- **Commits carry no AI-attribution trailers** — no `Co-authored-by: Claude`, no
  `Generated with…`, no robot-emoji line. Conventional, imperative subjects only.

---

## Running it 24/7

The **relay** (`.claude/hooks/handoff-watch.sh`, controlled by
`handoff-watchctl.sh`) is what makes the loop unattended. `make handoff` launches
the orchestrator inside tmux **and** arms the relay in one shot. Manage the relay
directly with:

```bash
make handoff-relay ARG=start    # arm the watcher in the background
make handoff-relay ARG=status   # is it running?
make handoff-relay ARG=tail     # follow .handoff/logs/handoff-watch.log
make handoff-relay ARG=stop     # disarm it
```

When `HANDOFF_FLAG.md` changes, the relay waits for the session to go **idle**
(the tmux pane byte-identical for a few seconds — Claude has handed back), types
`/clear`, settles, then types the standing instruction. It never types into a
busy session.

### Env knobs

| Variable                | Default                                  | Controls                                                        |
|-------------------------|------------------------------------------|----------------------------------------------------------------|
| `HANDOFF_TMUX_SESSION`  | `agent`                                  | tmux session the relay drives / the orchestrator lives in      |
| `HANDOFF_POLL_SECS`     | `3`                                      | polling interval when `inotify` is unavailable                 |
| `HANDOFF_DEBOUNCE_SECS` | `2`                                      | settle time after a flag change before driving                 |
| `HANDOFF_IDLE_STABLE`   | `5`                                      | seconds the pane must stay byte-identical to count as idle     |
| `HANDOFF_IDLE_TIMEOUT`  | `600`                                    | give up waiting for idle after this many seconds (then retry)  |
| `HANDOFF_CLEAR_SETTLE`  | `30`                                     | pause after `/clear` before typing the instruction             |
| `HANDOFF_INSTRUCTION`   | `Read HANDOFF_FLAG.md at the repo root and execute the handoff now, with the usual safety checks.` | the line typed into the session after `/clear`                 |

Two more, for tuning the launch rather than the timing:

- `HANDOFF_CLAUDE_CMD` — override the orchestrator launch command (default
  `claude --dangerously-skip-permissions --remote-control`); set it to plain
  `claude` for a tamer, prompt-on-everything session.
- `HANDOFF_RELAY_DISABLE=1` — start the orchestrator session **without** arming
  the relay: a manual, one-shot mode with no auto-loop.

### Unattended permissions

By default the orchestrator launches with **`--dangerously-skip-permissions`**,
because a relay-driven session must not stall on a permission prompt. The same
caveat as Codex applies: this auto-approves every tool, including arbitrary Bash,
so it is **only** safe because the container is externally sandboxed. Don't run
the unattended mode on a tree that holds secrets or uncommitted value you can't
afford to lose. For a supervised run, launch with
`HANDOFF_CLAUDE_CMD=claude make handoff` and approve actions yourself.

---

## What's in the box

```
ai-starter-pack/
├── .devcontainer/          the shared environment (python3.12 + node22; uv, bun,
│                           Claude Code, Codex, omc/omx, tmux, inotify, gh, jq,
│                           ripgrep, Chromium + fonts). Persistence bind-mounts +
│                           pre-warmed Superpowers plugin.
├── .claude/
│   ├── hooks/              the relay + notifier:
│   │     handoff-session.sh   launch/attach the orchestrator in tmux
│   │     handoff-watch.sh     watch the flag, drive the session when idle
│   │     handoff-watchctl.sh  start/stop/status/tail the relay
│   │     ntfy-notify.sh       phone push on blocked / idle
│   │     ntfy.env.example     copy to ntfy.env, set your topic
│   ├── skills/             the method as skills (planner, orchestrate-codex,
│   │                       browse QA, visual gate, …) + gstack INSTALL.md
│   └── settings.json       harness config (Superpowers enabled, no AI trailers)
├── .planner/               the dossier the planner owns
│   ├── 00-CHARTER.md  01-STATE.md  02-ROADMAP.md
│   ├── 03-BACKLOG.md       ← the `## NOW` pointer lives here
│   ├── 04-DECISIONS.md  99-JOURNAL.md
│   └── tasks/<ID>.md  (+ tasks/_TEMPLATE.md)
├── .handoff/logs/          relay log (handoff-watch.log)
├── Makefile                the command surface (handoff, planner, handoff-relay…)
├── project.mk.example      copy → project.mk: your TEST_CMD/LINT_CMD/… seam
├── HANDOFF_FLAG.md         the baton the relay watches (overwrite each handoff)
├── CLAUDE.md               the operating contract every session reads first
└── README.md               this file
```

---

## FAQ / failure modes

**The relay isn't firing.** Check the log: `make handoff-relay ARG=tail`. Common
causes: the orchestrator session isn't running yet (the relay *defers* the change
until a live `agent` session exists — launch `make handoff`); the session was
busy and hit `HANDOFF_IDLE_TIMEOUT` (it retries on the next cycle); or the flag's
content didn't actually change (the relay fires on content hash, not on save).

**"Session busy" / nothing happens after a save.** The relay refuses to type into
a session that is still streaming or mid-edit. It waits for the pane to go idle
(`HANDOFF_IDLE_STABLE` seconds unchanged). If the orchestrator is genuinely stuck
mid-turn, give it the hand back — or raise `HANDOFF_IDLE_TIMEOUT`.

**Codex is looping / stuck.** Kill it: `pkill -f 'codex exec'`. The tree is clean
(git is the undo), so re-brief a tighter unit. If a unit keeps failing, it's
usually under-scoped — carve it smaller in the dossier.

**gstack / browse not installed.** The browser QA tool is installed at user scope
on a best-effort basis by the devcontainer's post-create step. If it's missing,
follow `.claude/skills/gstack/INSTALL.md` to install it. No binary is vendored in
this repo.

**ntfy never pings.** It no-ops until configured. Copy
`.claude/hooks/ntfy.env.example` → `.claude/hooks/ntfy.env` and set `NTFY_TOPIC`
(pick a hard-to-guess value; subscribe to the same topic in the ntfy phone app).

---

## Credits

- **Superpowers** — methodology skills (planning, TDD, debugging, code review),
  by [obra](https://github.com/obra) (`obra/superpowers-marketplace`).
- **gstack / browse** — browser-driven QA, MIT © Garry Tan. Installed at user
  scope, never vendored here.
- **Claude Code** — Anthropic's official CLI for Claude.
- **OpenAI Codex** — the executor CLI driven via `codex exec`.

Released under the **MIT License** © 2026 Vincent Lahaye. See `LICENSE`.
