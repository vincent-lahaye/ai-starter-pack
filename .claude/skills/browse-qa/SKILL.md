---
name: browse-qa
description: The UI/visual gate. Drive the real app headless to verify any UI change or new user journey — capture screenshots of the affected screens AND vision-analyse each (layout, spacing, theme, no broken/unstyled/overflow). Uses gstack `browse` if installed, else falls back to the project's own browser tooling. A UI/flow change is NOT done without screenshots + a vision style check. Keywords: browse, screenshot, visual gate, UI verification, dogfood.
---

# browse-qa — the UI / visual gate

Any change that touches the UI **or** introduces a new user journey (a new
parcours, a new screen, a new flow) is **not done** until you have driven the
real app in a headless browser and:

1. **captured screenshots** of the affected screen(s) and their key states, and
2. **vision-analysed each screenshot** — read the image and confirm not just
   that the flow works but that the **style holds**: layout, spacing,
   theme/branding, no broken or unstyled elements, no overflow, no contrast
   regression.

Backend-only changes are exempt — the test/reset-db gates cover those. This gate
is for anything a human would otherwise click through by hand. Keep it
lightweight: drive only the changed screens, not the whole app.

## Step 1 — locate the browser tool

The preferred driver is gstack `browse` (third-party, MIT (c) Garry Tan),
installed at user scope by the devcontainer's post-create (best-effort). Check
for it:

```bash
B=~/.claude/skills/gstack/browse/dist/browse
if [ -x "$B" ]; then echo "READY: $B"; else echo "NO_GSTACK"; fi
```

- **READY** — use `$B` (commands below).
- **NO_GSTACK** — say so explicitly, then follow the install note in
  `.claude/skills/gstack/INSTALL.md`. If you cannot install it, **fall back to
  the project's own browser tooling** (whatever the owner's project ships:
  Playwright, Cypress, a dev-server screenshot script, etc.) and still satisfy
  the two requirements above — screenshots + a vision check. Never skip the gate
  just because gstack is absent.

## Step 2 — drive the screen (gstack `browse`)

Persistent headless Chromium: first call auto-starts (~3s), then ~100ms per
command. State (cookies, login) persists between calls.

```bash
$B goto http://localhost:3000/the-changed-screen   # navigate
$B text                                             # did real content load?
$B console                                          # any JS errors?
$B is visible ".key-element"                        # key UI present?
$B screenshot /tmp/qa/screen.png                    # capture evidence
```

Drive a flow when the change is a journey, not a single screen:

```bash
$B snapshot -i                 # list interactive elements (@e refs)
$B fill @e3 "user@test.com"
$B fill @e4 "secret"
$B click @e5                   # submit
$B snapshot -D                 # diff: what changed after the action?
$B is visible ".dashboard"     # success state reached?
$B screenshot /tmp/qa/after.png
```

Useful extras: `$B responsive /tmp/qa/layout` (mobile + tablet + desktop in one
shot), `$B is enabled "#submit"`, `$B network` (failed requests).

## Step 3 — vision-check every screenshot

After each capture, **Read the PNG** so the image enters context, then judge it
as a designer would:

- Layout and alignment — nothing clipped, collapsed, or stacked wrong.
- Spacing and rhythm — consistent padding/margins, no cramped or blown-out gaps.
- Theme and branding — correct colors, fonts, logo; tenant/theme applied.
- No broken or unstyled elements — no raw HTML, no missing CSS, no fallback
  system fonts where the brand font should be.
- No overflow, no contrast failures, no z-index/modal glitches.

Give a clear **pass/fail per screen** with the reason. If a structured verdict
skill (e.g. `visual-verdict`) is available, use it; otherwise state the verdict
inline.

## The rule

A UI or new-journey change reported as complete **without screenshots and a
vision style check is incomplete.** Show the screenshots to the owner (Read the
PNGs), state the verdict, and only then call the change done.
