# ai-starter-pack — single command surface.
#
# Run `make` (or `make help`) to see everything. This Makefile ships NO
# application: the harness drives an autonomous Claude + Codex loop, and your
# OWN project plugs in through the seam variables defined in `project.mk`
# (copied from `project.mk.example`). The targets below either drive the
# harness (handoff, planner, doctor) or pass through to your project's commands
# (test, lint, reset-db, up, dev, bootstrap) — they never hardcode a stack.

# Optional project seam — gitignored, copied from project.mk.example. Defines
# TEST_CMD / LINT_CMD / RESET_DB_CMD / UP_CMD / DEV_CMD / BOOTSTRAP_CMD. The
# leading `-` makes it optional: the harness works before you wire it.
-include project.mk

.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c

# Colors (fall back to empty when not a tty).
BOLD := $(shell tput bold 2>/dev/null || true)
RST  := $(shell tput sgr0 2>/dev/null || true)

# =============================================================================
# Help
# =============================================================================

## help: show this message
.PHONY: help
help:
	@printf '\n%s\n\n' "$(BOLD)ai-starter-pack — make targets$(RST)"
	@grep -hE '^## [a-z-]+:' $(MAKEFILE_LIST) \
	  | sed -E 's/^## ([a-z-]+): (.*)/  \1\t\2/' \
	  | column -t -s "$$(printf '\t')"
	@printf '\n%s\n' "$(BOLD)First run$(RST)"
	@printf '  %s\n' "1. cp project.mk.example project.mk    # then edit it for your stack"
	@printf '  %s\n' "2. make bootstrap                      # install your project's deps"
	@printf '  %s\n' "3. make handoff                        # launch the orchestrator (tmux: agent)"
	@printf '  %s\n' "4. make planner                        # 2nd window: load the planner skill"
	@printf '\n'

# =============================================================================
# Harness — autonomous Claude + Codex loop
# =============================================================================

## handoff: launch the orchestrator Claude in the relay-driven tmux session
.PHONY: handoff
handoff:
	@bash .claude/hooks/handoff-session.sh

## handoff-relay: control the handoff watcher (ARG=start|stop|status|tail)
.PHONY: handoff-relay
handoff-relay:
	@bash .claude/hooks/handoff-watchctl.sh $(or $(ARG),status)

## planner: open a 2nd tmux session 'planner' running Claude (load the planner skill there)
.PHONY: planner
planner:
	@tmux new-session -A -s planner claude

## doctor: print tool versions and warn about anything missing
.PHONY: doctor
doctor:
	@echo "$(BOLD)ai-starter-pack — toolchain doctor$(RST)"; \
	missing=0; \
	for tool in claude codex omc omx tmux bun uv gh jq rg chromium; do \
	  if command -v "$$tool" >/dev/null 2>&1; then \
	    ver="$$("$$tool" --version 2>/dev/null | head -1 || true)"; \
	    printf '  ok    %-9s %s\n' "$$tool" "$$ver"; \
	  else \
	    printf '  MISS  %-9s (not on PATH)\n' "$$tool"; \
	    missing=$$((missing + 1)); \
	  fi; \
	done; \
	if [ "$$missing" -gt 0 ]; then \
	  echo "$$missing tool(s) missing — the harness may not be fully functional."; \
	else \
	  echo "All tools present."; \
	fi

# =============================================================================
# Project seam — pass through to YOUR project's commands (set in project.mk)
# =============================================================================

## bootstrap: install your project's deps (runs BOOTSTRAP_CMD from project.mk)
.PHONY: bootstrap
bootstrap:
	@if [ -z "$(BOOTSTRAP_CMD)" ]; then \
	  echo "BOOTSTRAP_CMD is not set — define it in project.mk (copy project.mk.example)."; \
	fi
	@$(BOOTSTRAP_CMD)

## test: run your project's test suite (runs TEST_CMD from project.mk)
.PHONY: test
test:
	@if [ -z "$(TEST_CMD)" ]; then \
	  echo "set TEST_CMD in project.mk (copy project.mk.example)." >&2; exit 1; \
	fi
	@$(TEST_CMD)

## lint: lint your project (runs LINT_CMD from project.mk)
.PHONY: lint
lint:
	@if [ -z "$(LINT_CMD)" ]; then \
	  echo "set LINT_CMD in project.mk (copy project.mk.example)." >&2; exit 1; \
	fi
	@$(LINT_CMD)

## reset-db: wipe and re-create your project's database (runs RESET_DB_CMD from project.mk)
.PHONY: reset-db
reset-db:
	@if [ -z "$(RESET_DB_CMD)" ]; then \
	  echo "set RESET_DB_CMD in project.mk (copy project.mk.example)." >&2; exit 1; \
	fi
	@$(RESET_DB_CMD)

## up: start your project's backing services (runs UP_CMD from project.mk)
.PHONY: up
up:
	@if [ -z "$(UP_CMD)" ]; then \
	  echo "set UP_CMD in project.mk (copy project.mk.example)." >&2; exit 1; \
	fi
	@$(UP_CMD)

## dev: run your project's dev servers (runs DEV_CMD from project.mk)
.PHONY: dev
dev:
	@if [ -z "$(DEV_CMD)" ]; then \
	  echo "set DEV_CMD in project.mk (copy project.mk.example)." >&2; exit 1; \
	fi
	@$(DEV_CMD)
