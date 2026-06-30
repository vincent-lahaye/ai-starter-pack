# ai-starter-pack devcontainer — a lean, language-agnostic harness for an
# autonomous Claude + Codex development loop. No application, no database, no
# storage services are baked in: only the toolchain, the agent CLIs, and the
# browser needed for visual QA. The owner drops their own project on top.
FROM mcr.microsoft.com/devcontainers/python:1-3.12-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# The MS devcontainer base images ship a stale yarn apt source whose GPG key is
# no longer published — drop it before touching apt to avoid NO_PUBKEY errors.
RUN rm -f /etc/apt/sources.list.d/yarn.list

# Core CLI toolchain. `make` is the harness command surface (root Makefile, e.g.
# `make handoff`). The rest back the relay + agents: inotify-tools (the handoff
# watcher), tmux (the orchestrator session), socat, jq, ripgrep, plus archive +
# trust helpers (unzip, ca-certificates, gnupg, curl).
RUN apt-get update && apt-get install -y --no-install-recommends \
    make \
    tmux \
    inotify-tools \
    jq \
    ripgrep \
    socat \
    unzip \
    ca-certificates \
    gnupg \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Chromium + fonts for browser-driven QA (gstack `browse`). Chromium is baked so
# the QA tool never downloads a browser at runtime; `browse` discovers it at
# /usr/bin/chromium and BUN_CHROME_PATH pins it. CONTAINER=1 makes gstack
# auto-add --no-sandbox (Chromium can't sandbox in an unprivileged container).
# Noto fonts keep headless screenshots free of missing-glyph tofu.
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    fonts-liberation \
    fonts-noto-core \
    fonts-noto-color-emoji \
    && rm -rf /var/lib/apt/lists/*
ENV BUN_CHROME_PATH=/usr/bin/chromium
ENV CONTAINER=1

# GitHub CLI — agents push branches, open PRs, watch CI. Authenticates via a
# GH_TOKEN passed through from the host shell.
RUN install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /etc/apt/keyrings/githubcli.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/githubcli.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Node 22 via NodeSource — the generic JS runtime for project frontends and the
# agent CLIs (Codex, omc, omx) installed below. corepack ships with Node and
# provides the pnpm shim without a global npm install.
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && corepack enable \
    && (corepack prepare pnpm@latest --activate || true) \
    && rm -rf /var/lib/apt/lists/*

# uv — fast Python package + venv manager, system-wide so any Python project the
# owner drops in can use it.
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh \
    && chmod +x /usr/local/bin/uv /usr/local/bin/uvx

# Bun — runtime for the gstack browser daemon (`bun browse/src/server.ts`).
# Installed system-wide so QA tooling finds `bun` on PATH.
RUN curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash \
    && chmod +x /usr/local/bin/bun

# Pre-create the home dirs backing the persisted bind mounts (see
# devcontainer.json) with vscode ownership, so they inherit correct permissions
# on first mount instead of Docker creating them root:root.
#   .claude -> bind .devcontainer/.claude-data   (Claude state + config)
#   .codex  -> bind .devcontainer/.codex-data    (Codex state + config)
#   .home   -> bind .devcontainer/.home          (shell history + dotfiles)
RUN mkdir -p /home/vscode/.claude /home/vscode/.codex \
             /home/vscode/.home/history /home/vscode/.home/dotfiles \
    && chown -R vscode:vscode /home/vscode/.claude /home/vscode/.codex /home/vscode/.home

# Pre-populate ~/.ssh/known_hosts with github.com keys so git-over-SSH doesn't
# fail with "Host key verification failed" on a fresh container.
RUN mkdir -p /home/vscode/.ssh \
    && ssh-keyscan -t ed25519,rsa,ecdsa github.com 2>/dev/null > /home/vscode/.ssh/known_hosts \
    && chmod 700 /home/vscode/.ssh \
    && chmod 600 /home/vscode/.ssh/known_hosts \
    && chown -R vscode:vscode /home/vscode/.ssh

# Prepare the workspace mount point with vscode ownership.
RUN mkdir -p /workspaces/ai-starter-pack && chown -R vscode:vscode /workspaces/ai-starter-pack

# Default shell: zsh (base image already ships zsh + oh-my-zsh for vscode). chsh
# updates /etc/passwd so `docker exec`, SSH, and the agent CLIs all land in zsh.
RUN chsh -s /usr/bin/zsh vscode

# Append the harness rc tail to both shells. Put ~/.local/bin first on PATH (the
# Claude CLI and the vscode-scoped npm globals live there), persist shell history
# into the host-visible bind ~/.home/history so it survives rebuilds, and source
# the developer's personal dotfiles LAST so their aliases/exports win. The
# history reload is required because oh-my-zsh / bash already read the OLD
# default path before this tail runs — redirecting HISTFILE only fixes writes.
# post-create.sh seeds the *.local files (with an `ll` alias) on first run.
RUN cat >> /home/vscode/.zshrc <<'EOF'

# --- ai-starter-pack: user-local bins (Claude CLI, npm -g prefix) on PATH -----
export PATH="$HOME/.local/bin:$PATH"

# --- ai-starter-pack: persist shell history across rebuilds (bind ~/.home) -----
export HISTFILE="$HOME/.home/history/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000
setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE
[ -r "$HISTFILE" ] && fc -R "$HISTFILE"   # reload: oh-my-zsh read the OLD path before this point

# --- ai-starter-pack: personal dotfiles (bind ~/.home/dotfiles, persisted) -----
[ -r "$HOME/.home/dotfiles/zshrc.local" ] && source "$HOME/.home/dotfiles/zshrc.local"
EOF
RUN cat >> /home/vscode/.bashrc <<'EOF'

# --- ai-starter-pack: user-local bins (Claude CLI, npm -g prefix) on PATH -----
export PATH="$HOME/.local/bin:$PATH"

# --- ai-starter-pack: persist shell history across rebuilds (bind ~/.home) -----
export HISTFILE="$HOME/.home/history/.bash_history"
export HISTSIZE=100000
export HISTFILESIZE=200000
shopt -s histappend
[ -r "$HISTFILE" ] && history -r "$HISTFILE"   # reload: bash read the OLD path before .bashrc ran

# --- ai-starter-pack: personal dotfiles (bind ~/.home/dotfiles, persisted) -----
[ -r "$HOME/.home/dotfiles/bashrc.local" ] && source "$HOME/.home/dotfiles/bashrc.local"
EOF

USER vscode

# Route vscode-scoped npm globals into ~/.local (already first on PATH), so the
# agent CLIs install without root and survive rebuilds as part of the image.
RUN npm config set prefix /home/vscode/.local

# Claude Code CLI — the orchestrator + planner run inside the container, so it is
# baked headless (not only via the VS Code extension). Native installer: a
# self-updating binary in the user-writable ~/.local/bin (no sudo).
RUN curl -fsSL https://claude.ai/install.sh | bash

# OpenAI Codex CLI — the executor the orchestrator delegates build units to.
RUN npm install -g @openai/codex

# Multi-agent orchestration helpers: omc (oh-my-claudecode) for Claude Code and
# omx (oh-my-codex) for Codex. Best-effort: exact package names can drift, and a
# missing helper must not fail the image build (the loop runs without them).
RUN npm install -g oh-my-claudecode || true \
    && npm install -g oh-my-codex || true

WORKDIR /workspaces/ai-starter-pack
