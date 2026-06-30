---
name: app-reset-db
description: Reset the owner's project data store to a clean state through the harness. Runs $(RESET_DB_CMD) defined in project.mk via `make reset-db`. This is a TEMPLATE — the owner fills project.mk and flesh out this skill with their project's real reset specifics (which store, migrations, fresh-DB caveats). Use when the schema is stale, migrations are wedged, or a test run needs a clean slate.
---

# Reset the project data store

> **TEMPLATE skill.** The harness ships no database — it does not know whether
> your project uses a SQL server, an embedded DB, a fixtures file, or nothing at
> all. This
> skill bridges to your project through `project.mk`. Fill that file, then
> replace the `<fill-in>` markers with your project's real reset steps. If your
> project has no data store, delete this skill and drop `RESET_DB_CMD`.

## The seam: project.mk

The root `Makefile` does `-include project.mk` (gitignored). Set the command:

```bash
cp project.mk.example project.mk    # if you haven't already
# then edit:  RESET_DB_CMD = <your real reset, e.g. dropdb app && createdb app && alembic upgrade head>
```

`make reset-db` runs `$(RESET_DB_CMD)`. Never hardcode a reset into a skill or
the orchestrator — always go through this var.

## Run

```bash
make reset-db    # runs $(RESET_DB_CMD) from project.mk
```

## Fresh-DB specifics (fill this in)

Document how a clean slate works for **your** store so a session can do it
safely and reproducibly:

- Store + how it runs locally: `<fill-in, e.g. a DB container on :5432 via `make up`>`
- Migrations command: `<fill-in, e.g. alembic upgrade head  /  prisma migrate deploy>`
- Seed data, if any: `<fill-in command, or "none">`
- Caveats: `<fill-in — e.g. drops ALL local data; stop the dev server first;
  the throwaway container has no persistent volume so recreating it is the
  fastest clean slate>`

## Verify

After a reset, confirm the schema is current and the store is reachable:

```bash
<fill-in: a quick check, e.g. re-run migrations (idempotent) or a one-row query>
```

A successful reset leaves migrations fully applied and the app able to connect.
If the reset fails on a connection error, bring the store up first (see the
`app-local-stack` skill) and retry.
