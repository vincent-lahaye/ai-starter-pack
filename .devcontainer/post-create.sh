#!/usr/bin/env bash
# post-create.sh — idempotent devcontainer setup for ai-starter-pack.
#
# Runs once after container creation (devcontainer.json postCreateCommand) and is
# safe to re-run by hand. It wires the agent state that must survive rebuilds
# (Claude config, Codex state, personal dotfiles), pre-warms the methodology
# plugin + browser QA tool, arms the handoff relay, and — only if the owner has
# dropped a project in — runs their bootstrap. Every step is best-effort: a
# failure here must never leave the container unusable.
set -euo pipefail

WORKSPACE=/workspaces/ai-starter-pack
cd "$WORKSPACE"

# ---------------------------------------------------------------------------
# 1. Claude Code settings in the CONTAINER home (defence-in-depth).
#    A committed project .claude/settings.json (if present) wins over user scope
#    anyway; this guarantees the anti-attribution default even for sessions that
#    run with the container HOME and no project scope. Never touches the host.
# ---------------------------------------------------------------------------
echo "Seeding container ~/.claude/settings.json (anti-attribution default)..."
mkdir -p "$HOME/.claude"
if [ ! -f "$HOME/.claude/settings.json" ]; then
  cp "$WORKSPACE/.devcontainer/claude-user-settings.json" "$HOME/.claude/settings.json" || true
  echo "  ~/.claude/settings.json created."
else
  echo "  ~/.claude/settings.json already exists — left untouched."
fi

# ---------------------------------------------------------------------------
# 2. Persist Claude Code's MAIN config across rebuilds.
#    ~/.claude/ is bind-mounted (persisted), but Claude's main config file
#    ~/.claude.json (OAuth account + onboarding flag) lives in the bare home,
#    OUTSIDE any mount — so it is wiped on every rebuild, forcing a re-login.
#    Keep the real file inside the persisted ~/.claude/ and symlink it back.
# ---------------------------------------------------------------------------
echo "Persisting Claude config (~/.claude.json -> ~/.claude/.claude.json)..."
CLAUDE_JSON="$HOME/.claude.json"
CLAUDE_JSON_PERSISTED="$HOME/.claude/.claude.json"
if [ -L "$CLAUDE_JSON" ]; then
  echo "  already a symlink — nothing to do."
else
  if [ -f "$CLAUDE_JSON" ] && [ ! -e "$CLAUDE_JSON_PERSISTED" ]; then
    mv "$CLAUDE_JSON" "$CLAUDE_JSON_PERSISTED"   # first run: move the real file in
  elif [ -f "$CLAUDE_JSON" ]; then
    rm -f "$CLAUDE_JSON"                          # persisted copy wins; drop the ephemeral one
  fi
  ln -sfn "$CLAUDE_JSON_PERSISTED" "$CLAUDE_JSON"
  echo "  symlink created (login + config now survive rebuilds)."
fi

# ---------------------------------------------------------------------------
# 3. Persist/migrate Codex state across rebuilds.
#    ~/.codex is bind-mounted from .devcontainer/.codex-data. Docker normally
#    creates that mount, but if the directory is ever a plain ephemeral dir
#    (mount disabled), migrate its contents into the persisted location and
#    symlink it back so Codex auth/history/skills survive.
# ---------------------------------------------------------------------------
echo "Ensuring Codex state is persisted (~/.codex -> .devcontainer/.codex-data)..."
CODEX_DIR="$HOME/.codex"
CODEX_PERSISTED="$WORKSPACE/.devcontainer/.codex-data"
mkdir -p "$CODEX_PERSISTED"
if mountpoint -q "$CODEX_DIR" 2>/dev/null; then
  echo "  ~/.codex is already backed by the devcontainer bind mount."
elif [ -L "$CODEX_DIR" ]; then
  echo "  ~/.codex is already a symlink — nothing to do."
elif [ -d "$CODEX_DIR" ]; then
  shopt -s dotglob nullglob
  codex_entries=("$CODEX_DIR"/*)
  if [ "${#codex_entries[@]}" -gt 0 ] && [ -z "$(find "$CODEX_PERSISTED" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
    mv "${codex_entries[@]}" "$CODEX_PERSISTED"/
    echo "  existing Codex state migrated into .devcontainer/.codex-data."
  elif [ "${#codex_entries[@]}" -gt 0 ]; then
    backup_dir="$CODEX_PERSISTED/.migration-backups/$(date +%Y%m%d%H%M%S)"
    mkdir -p "$backup_dir"
    mv "${codex_entries[@]}" "$backup_dir"/
    echo "  persisted Codex state already exists — saved current state to $backup_dir."
  fi
  shopt -u dotglob nullglob
  rmdir "$CODEX_DIR" 2>/dev/null || true
  ln -sfn "$CODEX_PERSISTED" "$CODEX_DIR"
  echo "  symlink created for Codex state."
else
  ln -sfn "$CODEX_PERSISTED" "$CODEX_DIR"
  echo "  symlink created for Codex state."
fi

# ---------------------------------------------------------------------------
# 4. Seed per-developer personal dotfiles in the host-visible bind ~/.home.
#    ~/.zshrc / ~/.bashrc (baked in the image) source
#    ~/.home/dotfiles/{zshrc,bashrc}.local LAST. Seed those from the committed
#    template .devcontainer/home-skel/ ONLY if missing — never clobber edits.
# ---------------------------------------------------------------------------
echo "Seeding personal dotfiles (~/.home/dotfiles/*.local)..."
mkdir -p "$HOME/.home/dotfiles" "$HOME/.home/history"
for shell in zsh bash; do
  target="$HOME/.home/dotfiles/${shell}rc.local"
  skel="$WORKSPACE/.devcontainer/home-skel/${shell}rc.local"
  if [ ! -f "$target" ]; then
    if [ -f "$skel" ]; then
      cp "$skel" "$target"
    else
      printf "# Personal %s config (persisted). Add your aliases/exports here.\nalias ll='ls -alFh'\n" "$shell" > "$target"
    fi
    echo "  ${shell}rc.local seeded (includes 'll')."
  fi
done

# ---------------------------------------------------------------------------
# 5. Methodology plugin (Superpowers — obra/superpowers-marketplace).
#    Provides the planning / TDD / systematic-debugging skills the loop leans on.
#    This pre-warms the per-container plugin cache (which lives in the ~/.claude
#    bind mount and can't be baked into the image). Best-effort: offline => NO-OP,
#    and Claude still auto-installs from committed project settings on first use.
# ---------------------------------------------------------------------------
echo ""
echo "Pre-warming the Superpowers methodology plugin (obra/superpowers-marketplace)..."
if command -v claude >/dev/null 2>&1; then
  claude plugin marketplace add obra/superpowers-marketplace --scope user >/dev/null 2>&1 || true
  if claude plugin install superpowers@superpowers-marketplace --scope user >/dev/null 2>&1; then
    echo "  Superpowers ready (cache pre-warmed)."
  else
    echo "  WARN: pre-warm deferred (offline?) — Claude installs it on first session."
  fi
else
  echo "  claude CLI not found — skipping pre-warm."
fi

# ---------------------------------------------------------------------------
# 6. Browser QA tool (gstack `browse`) at USER scope (~/.claude/skills/gstack).
#    gstack is third-party (MIT, (c) Garry Tan) and is NOT vendored as a binary.
#    We don't guess a download URL: if it isn't already present, point at the
#    committed install note. Chromium + Bun are already baked, so once installed
#    it works headless out of the box.
# ---------------------------------------------------------------------------
echo ""
echo "Checking browser QA tool (gstack browse)..."
if [ -e "$HOME/.claude/skills/gstack/browse/dist/browse" ] || [ -e "$HOME/.claude/skills/gstack/browse/src/server.ts" ]; then
  echo "  gstack already installed at ~/.claude/skills/gstack."
else
  echo "  gstack not installed — see .claude/skills/gstack/INSTALL.md for the user-scope install."
fi

# ---------------------------------------------------------------------------
# 7. Handoff relay. Watches HANDOFF_FLAG.md and, on each rewrite, drives the live
#    Claude session running in tmux. The watcher is a detached process that does
#    not survive a rebuild, so (re)start it here. handoff-watchctl.sh is
#    idempotent (no-ops if already running). Opt out with HANDOFF_RELAY_DISABLE=1.
# ---------------------------------------------------------------------------
echo ""
if [ "${HANDOFF_RELAY_DISABLE:-0}" != "1" ] && [ -x "$WORKSPACE/.claude/hooks/handoff-watchctl.sh" ]; then
  if CLAUDE_PROJECT_DIR="$WORKSPACE" "$WORKSPACE/.claude/hooks/handoff-watchctl.sh" start; then
    echo "Handoff relay armed (set HANDOFF_RELAY_DISABLE=1 to skip)."
  else
    echo "  handoff relay not started (non-fatal)."
  fi
else
  echo "Handoff relay skipped (HANDOFF_RELAY_DISABLE=1 or control script absent)."
fi

# ---------------------------------------------------------------------------
# 8. Project bootstrap (only if the owner has dropped a project in). The root
#    Makefile does `-include project.mk`; if that seam exists and defines
#    BOOTSTRAP_CMD, run it. Best-effort — never aborts container setup.
# ---------------------------------------------------------------------------
echo ""
if [ -f "$WORKSPACE/project.mk" ] && grep -qE '^[[:space:]]*BOOTSTRAP_CMD[[:space:]]*[:?]?=' "$WORKSPACE/project.mk"; then
  echo "project.mk defines BOOTSTRAP_CMD — running 'make bootstrap'..."
  make -C "$WORKSPACE" bootstrap || echo "  WARN: 'make bootstrap' failed — run it by hand once the project is ready."
else
  echo "No project.mk BOOTSTRAP_CMD — skipping project bootstrap (drop your project in, then copy project.mk.example -> project.mk)."
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "Devcontainer ready. ai-starter-pack harness is armed."
echo "  - Drop your project into the workspace, then: cp project.mk.example project.mk"
echo "  - Plan with the 'planner' skill (.planner/ dossier), build with 'make handoff'."
echo "  - 'make help' lists the command surface."
