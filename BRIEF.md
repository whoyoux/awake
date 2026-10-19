# Awake (working name): a menu bar app that keeps the Mac awake

Handoff from the PlantCare session (19 Oct 2026). This file is the starting context for the new project; turn it into `AGENTS.md` / `README.md` once the project exists.

## Why

While PlantCare builds run locally (15–20 min `eas build --local`) the owner kept asking the agent to start and stop `caffeinate -dims`. They want a tiny menu bar app instead: click to keep the Mac awake, click again to let it sleep.

## Decisions so far

- **Distribution: Mac App Store, free.** Done properly from the start: a real Xcode project (not a single `swiftc` file), so the same project is used day to day and later shipped.
- **Approach:** SwiftUI `MenuBarExtra`, menu-bar only (`LSUIElement`, no Dock icon). Keep the Mac awake with IOKit power assertions (`IOPMAssertionCreateWithName`, the API `caffeinate` itself uses), not by spawning `caffeinate`: nothing lingers after quitting, and it works inside the App Sandbox (Amphetamine does the same on the Mac App Store).
- Menu bar icon reflects the state (e.g. empty / filled cup, light and dark).
- **Git from day one**; this folder is the repo (`main`). Remote (GitHub) to be decided with the owner.
- **Developer account:** Apple Developer Program, **individual**: the seller name on the store is the owner's legal name (fine). Team ID `73SQTP34GN` (same team as PlantCare).

## Still to decide with the owner (ask before building)

1. **Name** (must be unique on the Mac App Store) and bundle id (PlantCare uses `dev.whxx.<app>`, so likely `dev.whxx.<name>`).
2. **Features for v1:** plain on/off toggle only, or also a timer (1 h / 2 h / until turned off) and "Open at login" (`SMAppService`, allowed in the store). Also: keep only the system awake, or the display too (`caffeinate -dims` kept both).
3. Minimum macOS version (suggest 14) and universal build (Apple silicon + Intel).
4. GitHub repo: public with a licence (e.g. MIT) or private.

## Mac App Store checklist

- App Sandbox on; no extra entitlements expected for power assertions.
- App icon (asset catalog) + menu bar template images.
- App Store Connect record, description, screenshots, category (Utilities), privacy policy URL ("collects no data"), support URL. Hosting could be a small static page on Cloudflare like PlantCare's site (`whxx.dev`).
- Privacy nutrition label: Data Not Collected.
- Archive in Xcode, upload, App Review.

## How the owner works (carry over)

- Talk to the owner in **Polish**; code, comments, commits and docs in **English**.
- **Never download or run prebuilt binaries** or self-updating launchers (including skill scripts that fetch engines). Prefer Apple frameworks; avoid third-party dependencies (no Sparkle etc.) unless the owner agrees.
- **Never ask for keys, certificates or passwords in chat**; say where they go and let the owner enter them.
- Commits: one topic each, body explains why, end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Verify before calling something done (build it, run it, look at it), and say plainly what could not be verified.
- Before anything public-facing (App Store submission, pushing to a public repo) ask first.
