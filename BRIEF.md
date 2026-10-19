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

## Decided with the owner (19 Oct 2026)

- **Name:** Awake. **Bundle id:** `dev.whxx.awake`.
- **v1 features:**
  - Turn on / turn off from the menu bar.
  - Turn on for a set time, with a few presets (e.g. 30 min, 1 h, 2 h, 4 h, 8 h) plus "until turned off".
  - While on, show how long it has been running (a live elapsed-time counter in the menu; for timed sessions also the time left).
  - Block **display sleep too** (like `caffeinate -dims`): use a display-sleep assertion, which also keeps the system awake.
  - No "Open at login" in v1.
- **Minimum macOS:** whatever the chosen APIs need, kept as low as reasonable. Proposal: macOS 14 Sonoma (MenuBarExtra needs 13; 14 adds `@Observable` and covers Macs from 2018 on). Tell the owner the final choice and why.
- **GitHub repo: public**, with a licence (propose MIT and confirm before the first push). Confirm before creating the remote and pushing.

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
