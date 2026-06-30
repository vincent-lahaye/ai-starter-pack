#!/usr/bin/env bash
# handoff-watch.sh — interactive handoff relay (tmux keystroke driver).
#
# Watches HANDOFF_FLAG.md. When its content changes, it DRIVES YOUR LIVE Claude
# session (the one running inside tmux via handoff-session.sh) by typing `/clear`
# and then the handoff instruction for you — but only at the right moment:
#
#   1. change detected (+ debounce)
#   2. WAIT until the session is idle — Claude may still be mid-edit/streaming.
#      Claude Code animates a spinner that repaints the terminal every second
#      while it works, so "pane unchanged for a few seconds" == Claude gave the
#      hand back. We never type into a busy session (that queued + reordered the
#      keystrokes before).
#   3. type `/clear` + Enter
#   4. wait (HANDOFF_CLEAR_SETTLE, default 30s) so the clear fully lands
#   5. type the handoff instruction + Enter
#
# If the session is still busy after HANDOFF_IDLE_TIMEOUT, or not running yet, the
# change is NOT consumed and is retried on the next cycle.
#
# inotify is used when available; otherwise it falls back to polling so it works
# before the devcontainer is rebuilt with inotify-tools.
#
# Control it via handoff-watchctl.sh (start/stop/status/tail). Env knobs:
#   HANDOFF_TMUX_SESSION   target tmux session (default agent)
#   HANDOFF_POLL_SECS      polling interval when inotify is absent (default 3)
#   HANDOFF_DEBOUNCE_SECS  settle time after a change before driving (default 2)
#   HANDOFF_IDLE_STABLE    seconds the pane must stay unchanged to count as idle (default 5)
#   HANDOFF_IDLE_TIMEOUT   give up waiting for idle after this many seconds (default 600)
#   HANDOFF_CLEAR_SETTLE   pause after /clear before typing the instruction (default 30)
#   HANDOFF_INSTRUCTION    the line typed into the session after /clear (default below)
set -euo pipefail

project_dir="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
target="$project_dir/HANDOFF_FLAG.md"

session="${HANDOFF_TMUX_SESSION:-agent}"
poll_secs="${HANDOFF_POLL_SECS:-3}"
debounce_secs="${HANDOFF_DEBOUNCE_SECS:-2}"
idle_stable="${HANDOFF_IDLE_STABLE:-5}"
idle_timeout="${HANDOFF_IDLE_TIMEOUT:-600}"
clear_settle="${HANDOFF_CLEAR_SETTLE:-30}"

instruction="${HANDOFF_INSTRUCTION:-Read HANDOFF_FLAG.md at the repo root and execute the handoff now, with the usual safety checks.}"

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/claude-handoff"
state_key="$(printf '%s' "$project_dir" | shasum -a 256 | awk '{print $1}')"
driven_state="$state_dir/$state_key.watch.sha"
log_dir="$project_dir/.handoff/logs"
log="$log_dir/handoff-watch.log"
mkdir -p "$state_dir" "$log_dir"

logmsg() { printf '%s  %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" | tee -a "$log" >&2; }
cur_hash() { [[ -s "$target" ]] && shasum -a 256 "$target" | awk '{print $1}' || echo ""; }
pane_sig() { tmux capture-pane -t "$session" -p 2>/dev/null | shasum -a 256 | awk '{print $1}'; }

# Seed the baseline so an already-present flag does not fire on startup.
if [[ ! -s "$driven_state" ]]; then
  cur_hash > "$driven_state"
  logmsg "seeded baseline hash ($(cut -c1-12 < "$driven_state")…)"
fi

# Block until the pane has been byte-identical for $idle_stable seconds (Claude
# at rest), or $idle_timeout elapses. Returns 0 if idle, 1 on timeout.
wait_for_idle() {
  local prev="" same=0 waited=0
  while (( waited < idle_timeout )); do
    local sig; sig="$(pane_sig)"
    if [[ -n "$sig" && "$sig" == "$prev" ]]; then
      same=$((same + 1))
      (( same >= idle_stable )) && return 0
    else
      same=0; prev="$sig"
    fi
    sleep 1
    waited=$((waited + 1))
  done
  return 1
}

drive_session() {
  local hash="$1"
  if ! tmux has-session -t "$session" 2>/dev/null; then
    # No live session to drive yet. Do NOT consume the change, so it fires as
    # soon as you launch `make handoff` (poll mode retries every cycle).
    logmsg "tmux session '$session' not running — deferring handoff (launch: make handoff)"
    return 1
  fi

  logmsg "change on hash ${hash:0:12}… — waiting for '$session' to go idle"
  if ! wait_for_idle; then
    logmsg "session still busy after ${idle_timeout}s — deferring (will retry)"
    return 1
  fi

  logmsg "session idle — typing /clear"
  tmux send-keys -t "$session" -l '/clear'
  sleep 0.4
  tmux send-keys -t "$session" Enter
  logmsg "/clear sent — settling ${clear_settle}s before the instruction"
  sleep "$clear_settle"

  logmsg "typing handoff instruction"
  tmux send-keys -t "$session" -l "$instruction"
  sleep 0.4
  tmux send-keys -t "$session" Enter
  logmsg "handoff driven into '$session'"
  return 0
}

maybe_fire() {
  local now; now="$(cur_hash)"
  local last; last="$(cat "$driven_state" 2>/dev/null || echo "")"
  [[ -z "$now" || "$now" == "$last" ]] && return 0
  # Debounce: wait for writes to settle, then re-check.
  sleep "$debounce_secs"
  now="$(cur_hash)"
  [[ -z "$now" || "$now" == "$last" ]] && return 0
  # Only consume the change once we actually drove a live session.
  if drive_session "$now"; then
    printf '%s' "$now" > "$driven_state"
  fi
}

logmsg "watching $target -> session '$session' (inotify=$(command -v inotifywait >/dev/null && echo yes || echo no), poll=${poll_secs}s, idle_stable=${idle_stable}s, clear_settle=${clear_settle}s)"

if command -v inotifywait >/dev/null 2>&1; then
  # Watch the directory (editors replace the inode on save) and react on any event.
  while inotifywait -q -e close_write,moved_to,create "$(dirname "$target")" >/dev/null 2>&1; do
    maybe_fire
  done
else
  while true; do
    maybe_fire
    sleep "$poll_secs"
  done
fi
