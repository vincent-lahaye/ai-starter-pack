#!/usr/bin/env bash
# ntfy-notify.sh — Claude Code `Notification` hook: push an ntfy alert when
# Claude needs you. Outbound only; it injects nothing into Claude's context.
#
# Two cases, deliberately handled differently:
#   - permission_prompt : Claude is BLOCKED (question / authorization). Pinged
#     IMMEDIATELY, high priority.
#   - idle_prompt (and the empty fallback) : turn finished, nothing asked. This
#     was almost always a false alarm, so instead of pinging right away we ARM a
#     timer (NTFY_IDLE_DELAY, default 3600s = 60 min) in the background. If you
#     come back before it expires — a new event arrives, or you submit a prompt
#     (UserPromptSubmit hook calls this script with `cancel`) — the timer is
#     killed and nothing is sent. Only a genuinely long absence pings you.
#
# Wire it as a Notification hook AND (for `cancel`) a UserPromptSubmit hook (see
# .claude/settings.local.json). Config lives in the gitignored
# .claude/hooks/ntfy.env (copy ntfy.env.example). If no topic is configured,
# this no-ops silently — safe for other contributors.
set -euo pipefail

mode="${1:-notify}"

input="$(cat 2>/dev/null || true)"
ntype="$(jq -r '.notification_type // empty' <<<"$input" 2>/dev/null || echo "")"
message="$(jq -r '.message // empty' <<<"$input" 2>/dev/null || echo "")"
cwd="$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null || echo "")"

# Per-session pidfile for the armed idle timer (keyed by working directory so
# concurrent sessions in different repos don't clobber each other's timers).
key="$(printf '%s' "${cwd:-default}" | cksum | cut -d' ' -f1)"
pidfile="${TMPDIR:-/tmp}/ntfy-idle-${key}.pid"

# Kill any previously armed idle timer (you're back / a new event arrived).
cancel_idle() {
  [[ -f "$pidfile" ]] || return 0
  kill "$(cat "$pidfile" 2>/dev/null)" 2>/dev/null || true
  rm -f "$pidfile"
}

# `cancel` mode: invoked from the UserPromptSubmit hook when you actually reply.
if [[ "$mode" == "cancel" ]]; then
  cancel_idle
  exit 0
fi

# Notification mode: only react to the two prompt types; ignore auth_success etc.
case "$ntype" in
  permission_prompt|idle_prompt|"") : ;;
  *) exit 0 ;;
esac

# Any fresh notification supersedes a pending idle timer.
cancel_idle

cfg="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ntfy.env"
# shellcheck disable=SC1090
[[ -f "$cfg" ]] && . "$cfg"
: "${NTFY_URL:=https://ntfy.sh}"
: "${NTFY_IDLE_DELAY:=3600}"   # seconds to wait before pinging on idle (60 min)
[[ -z "${NTFY_TOPIC:-}" ]] && exit 0   # not configured -> no-op

session="$(basename "${cwd:-session}")"

# Fire one ntfy push. Args: title / body / tag / priority.
send() {
  curl -fsS --max-time 8 \
    ${NTFY_TOKEN:+-H "Authorization: Bearer ${NTFY_TOKEN}"} \
    -H "Title: ${1}" \
    -H "Tags: ${2}" \
    -H "Priority: ${3}" \
    -d "${4}" \
    "${NTFY_URL%/}/${NTFY_TOPIC}" >/dev/null 2>&1 || true
}

case "$ntype" in
  permission_prompt)
    # Blocked, needs an action now. NTFY_TITLE/NTFY_PRIORITY still override.
    send \
      "${NTFY_TITLE:-🙋 Claude needs you}" \
      "bell" \
      "${NTFY_PRIORITY:-high}" \
      "${message:-Claude is waiting for an authorization} — ${session}"
    ;;
  *)  # idle_prompt or empty fallback: arm a delayed ping, cancellable.
    title="${NTFY_TITLE:-⏳ Claude has been idle a while}"
    body="${message:-Turn finished a while ago, still waiting (nothing blocked)} — ${session}"
    priority="${NTFY_PRIORITY:-default}"
    delay="$NTFY_IDLE_DELAY"
    timer() {
      sleep "$delay"
      send "$title" "hourglass_flowing_sand" "$priority" "$body"
      rm -f "$pidfile"
    }
    # Detach so the timer survives this hook process (and its process group)
    # exiting. setsid starts a fresh shell, so export everything it needs.
    export NTFY_URL NTFY_TOPIC title body priority delay pidfile
    [[ -n "${NTFY_TOKEN:-}" ]] && export NTFY_TOKEN
    export -f send timer
    if command -v setsid >/dev/null 2>&1; then
      setsid bash -c 'timer' </dev/null >/dev/null 2>&1 &
    else
      ( timer ) </dev/null >/dev/null 2>&1 &
    fi
    echo "$!" >"$pidfile"
    disown 2>/dev/null || true
    ;;
esac
