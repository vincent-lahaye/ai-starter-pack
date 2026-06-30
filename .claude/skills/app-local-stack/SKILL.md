---
name: app-local-stack
description: Bring the owner's project up locally through the harness. Runs $(UP_CMD) and $(DEV_CMD) (and $(BOOTSTRAP_CMD)) defined in project.mk via `make up` / `make dev`. This is a TEMPLATE — the owner fills project.mk and flesh out this skill with their project's real run specifics (services, ports, env, first-time setup). Use to start the app, run the dev servers, or diagnose why the local stack isn't responding.
---

# Run the project local stack

> **TEMPLATE skill.** The harness ships no application, no services. This skill
> bridges to your project through `project.mk`, so the same `make up` / `make
> dev` words work no matter what your project is. Fill that file, then replace
> the `<fill-in>` markers with your project's real services, ports, and setup.

## The seam: project.mk

The root `Makefile` does `-include project.mk` (gitignored). Set the commands:

```bash
cp project.mk.example project.mk    # if you haven't already
# then edit:
#   BOOTSTRAP_CMD = <one-time setup: install deps, create .env, etc.>
#   UP_CMD        = <start backing services, e.g. docker compose up -d db>
#   DEV_CMD       = <run the app / dev servers, e.g. npm run dev  /  uvicorn ...>
```

`make bootstrap` runs `$(BOOTSTRAP_CMD)`, `make up` runs `$(UP_CMD)`, `make dev`
runs `$(DEV_CMD)`. Never hardcode a service or port into a skill or the
orchestrator — always go through these vars.

## First-time setup (idempotent)

```bash
make bootstrap   # runs $(BOOTSTRAP_CMD) — deps, .env, hooks
make up          # runs $(UP_CMD) — backing services
```

## Run the stack

```bash
make up    # start backing services (DB, cache, etc.) — $(UP_CMD)
make dev   # run the app / dev servers — $(DEV_CMD)
```

URLs (fill in for your project):

- App / frontend: `<fill-in, e.g. http://localhost:3000>`
- API / backend: `<fill-in, e.g. http://localhost:8000>`
- Other services: `<fill-in, or "none">`

## Diagnose (fill this in)

Common issues and the one command that fixes each, for **your** stack:

- "Service not reachable" -> `<fill-in, e.g. `make up`, then check the port>`
- Missing deps / stale install -> `<fill-in, e.g. `make bootstrap`>`
- Port already in use -> `<fill-in: which process owns the port and how to free it>`
- Data store wedged / schema stale -> see the `app-reset-db` skill.

If the app still does not come up, capture the exact error and check it against
the setup steps above before retrying.
