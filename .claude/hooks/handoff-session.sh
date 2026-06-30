#!/usr/bin/env bash
# handoff-session.sh — launch (or re-attach) Claude Code inside a tmux session
# that the handoff relay can drive.
#
# This is visually identical to running `claude` directly: you are attached and
# interact normally. The only difference is that the session lives inside tmux,
# so the watcher (handoff-watch.sh) can type `/clear` + the next instruction for
# you when HANDOFF_FLAG.md is rewritten. Detach any time with Ctrl-b d (Claude
# keeps running); re-run this to re-attach.
#
# Env: HANDOFF_TMUX_SESSION (default agent), HANDOFF_CLAUDE_CMD (default claude).
set -euo pipefail

session="${HANDOFF_TMUX_SESSION:-agent}"
# Driven by the relay (auto /clear + typed instruction), so the session must not
# stall on permission prompts — launch with skip-permissions by default. Also
# enable Remote Control (--remote-control) so you can reach this session from the
# claude.ai app after an ntfy ping. Override with HANDOFF_CLAUDE_CMD for a tamer
# launch (e.g. plain `claude`).
cmd="${HANDOFF_CLAUDE_CMD:-claude --dangerously-skip-permissions --remote-control}"
project_dir="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$project_dir"

# Make sure the relay watcher is armed (idempotent — no-op if already running),
# so a single `make handoff` both launches the drivable session and the watcher.
HANDOFF_TMUX_SESSION="$session" CLAUDE_PROJECT_DIR="$project_dir" \
  bash "$project_dir/.claude/hooks/handoff-watchctl.sh" start || true

# -A: attach if the session already exists, otherwise create it running claude.
# Disable destroy-on-detach so the session (and Claude) survive a detach.
exec tmux new-session -A -s "$session" -e "CLAUDE_PROJECT_DIR=$project_dir" "$cmd"
