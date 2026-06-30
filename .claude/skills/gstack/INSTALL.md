# Installing gstack `browse` (browser-QA for the visual gate)

`browse` is the headless-browser CLI behind ai-starter-pack's **visual gate**:
whenever a change touches the UI or adds a user journey, the work is not "done"
until you have driven the real screen, captured screenshots, and vision-checked
the style. `browse` is what drives that real screen.

## What it is

`gstack browse` is a **third-party** browser-QA tool — MIT-licensed,
copyright (c) Garry Tan. It is **not** part of this repo and is **not**
vendored here. This repo only provides the runtime it needs and documents how
to enable it.

## What the devcontainer already gives you

The devcontainer ships the two runtime prerequisites, so no system setup is
needed on your side:

- **Chromium** at `/usr/bin/chromium`, exported as `BUN_CHROME_PATH` so `browse`
  finds the browser without auto-downloading one.
- **Bun**, the runtime `browse` executes under.
- **Noto fonts**, so screenshots render text instead of tofu boxes.

It also sets `CONTAINER=1`. `browse` reads that and automatically passes
`--no-sandbox` to Chromium — the Chrome sandbox cannot nest inside this
externally-sandboxed container, and `--no-sandbox` is the correct, expected
behaviour here. You do not need to add the flag yourself.

## Where it installs — user scope, not the repo

Install `browse` at **user scope**, under your Claude home:

```
~/.claude/skills/gstack
```

User scope (not project scope) is deliberate: the compiled `browse` binary and
its `node_modules` are large, machine-specific, and third-party — they must
**never be committed** to this repository. `.gitignore` already excludes
`.claude/skills/gstack/browse/dist/` and any
`.claude/skills/gstack/**/node_modules/` as a safety net, but the canonical home
is `~/.claude/skills/gstack`, outside the repo tree entirely.

This `INSTALL.md` lives in the repo only as documentation; it is the sole file
under `.claude/skills/gstack/` that this project tracks.

## How to install

Install it **from the gstack marketplace skill** (its own source/marketplace —
follow that skill's published instructions; this repo does not mirror or pin a
download URL, so it cannot go stale here).

The devcontainer's `post-create` step **attempts this install best-effort** on
first creation, so in most cases `browse` is already present when you open the
container. If it is missing (offline first build, marketplace unreachable, fresh
machine), run the gstack marketplace skill's install yourself to populate
`~/.claude/skills/gstack`, then re-run the QA gate.

## Verifying

After installation, confirm the binary resolves and the browser path is wired:

```bash
ls ~/.claude/skills/gstack/browse/dist/browse
echo "$BUN_CHROME_PATH"   # -> /usr/bin/chromium
```

If both are present, the visual gate is ready.

## Using it

Do not invoke `browse` ad-hoc for UI verification. Drive it through the
**`browse-qa` skill**, which runs the documentation-mode pass the method
requires: open the changed screen(s), capture screenshots, and vision-check that
the style holds (layout, spacing, theming, no overflow or contrast regressions).
Backend-only changes are exempt — the test gate covers those.
