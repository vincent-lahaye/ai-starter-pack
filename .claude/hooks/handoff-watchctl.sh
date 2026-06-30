#!/usr/bin/env bash
# handoff-watchctl.sh — start/stop/status/tail for the headless handoff relay.
#
#   .claude/hooks/handoff-watchctl.sh start   # launch the watcher in background
#   .claude/hooks/handoff-watchctl.sh stop    # stop it
#   .claude/hooks/handoff-watchctl.sh status  # is it running?
#   .claude/hooks/handoff-watchctl.sh tail    # follow the relay log
#
# Full autonomy (auto-approve every tool, including arbitrary Bash) — use with
# care, this is the unattended mode on revenue/secret-sensitive work:
#   HANDOFF_CLAUDE_EXTRA=--dangerously-skip-permissions \
#     .claude/hooks/handoff-watchctl.sh start
set -euo pipefail

project_dir="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
watcher="$project_dir/.claude/hooks/handoff-watch.sh"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/claude-handoff"
state_key="$(printf '%s' "$project_dir" | shasum -a 256 | awk '{print $1}')"
pidfile="$state_dir/$state_key.watch.pid"
log="$project_dir/.handoff/logs/handoff-watch.log"
mkdir -p "$state_dir"

running() { [[ -s "$pidfile" ]] && kill -0 "$(cat "$pidfile")" 2>/dev/null; }

case "${1:-status}" in
  start)
    if running; then echo "already running (pid $(cat "$pidfile"))"; exit 0; fi
    CLAUDE_PROJECT_DIR="$project_dir" nohup bash "$watcher" >/dev/null 2>&1 &
    echo $! > "$pidfile"
    echo "started (pid $(cat "$pidfile")) — log: $log"
    ;;
  stop)
    if ! running; then echo "not running"; rm -f "$pidfile"; exit 0; fi
    pid="$(cat "$pidfile")"
    # Kill the watcher and any child claude leg in its process group.
    pkill -TERM -P "$pid" 2>/dev/null || true
    kill -TERM "$pid" 2>/dev/null || true
    rm -f "$pidfile"
    echo "stopped (pid $pid)"
    ;;
  status)
    if running; then echo "running (pid $(cat "$pidfile"))"; else echo "stopped"; fi
    ;;
  tail)
    exec tail -n 40 -f "$log"
    ;;
  *)
    echo "usage: $0 {start|stop|status|tail}" >&2; exit 2 ;;
esac
