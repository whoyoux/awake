# Agent notes for Awake

Awake is a SwiftUI menu bar app (`MenuBarExtra`, no Dock icon) that keeps
the Mac and display awake with an IOKit power assertion. It is free,
open source (public GitHub repo `whoyoux/awake`) and distributed as
GitHub Releases.

## Owner's decisions

- Name **Awake**, bundle id `dev.whxx.awake`, Apple Developer team
  `73SQTP34GN` (individual account).
- Distribution: **GitHub Releases**, not the Mac App Store (owner's
  decision, 19 Oct 2026). Releases are Developer ID signed, notarized and
  stapled zips made by `scripts/release.sh`. App Sandbox stays on (not
  required outside the store, but nothing needs to leave it). No
  auto-updater: Sparkle would be a third-party dependency.
- Minimum macOS **14 Sonoma**: `MenuBarExtra` needs 13, and 14 adds the
  Observation framework (`@Observable`) used by `AwakeController`. 14 runs
  on Macs from 2018 on.
- v1 scope: turn on / off; turn on for a preset time (30 min, 1 h, 2 h,
  4 h, 8 h) or until turned off; live elapsed time (and time left for timed
  sessions); a menu bar icon showing the state in light and dark mode.
  "Open at Login" checkbox (added at the owner's request, 19 Oct 2026),
  off by default: App Review guideline 2.4.5 requires the user's consent
  before an app launches itself at login.
- Use `PreventUserIdleDisplaySleep` (like `caffeinate -d`), not a spawned
  `caffeinate` process.
- Licence: MIT.

## Layout

- `Awake.xcodeproj`: uses a folder-synchronised group, so any file added
  under `Awake/` is part of the target without editing `project.pbxproj`.
- `Awake/AwakeApp.swift`: the `MenuBarExtra` scene and menu bar icon
  (SF Symbols `cup.and.saucer` / `cup.and.saucer.fill`, template images,
  so they follow light and dark mode).
- `Awake/AwakeController.swift`: state, the session timer, re-checking the
  end time on wake (timers do not count time while the Mac sleeps).
- `Awake/PowerAssertion.swift`: wraps `IOPMAssertionCreateWithName` /
  `IOPMAssertionRelease`.
- `Awake/LoginItem.swift`: "Open at Login" via `SMAppService.mainApp`
  (works in the sandbox; the user can also change it in System Settings >
  General > Login Items).
- `Awake/MenuContentView.swift`: the panel. It is a window-style
  `MenuBarExtra` so the timers update live while it is open.
- `Awake/AppIcon.icon`: the app icon as an Icon Composer bundle (espresso
  gradient fill + cup artwork layer). Xcode builds the Liquid Glass icon for
  macOS 26+ and `AppIcon.icns` for older systems from it.
- `scripts/generate-icon-artwork.mjs`: generates cup artwork candidates
  with `openai/gpt-image-1` through OpenRouter (plain Node, prompt written
  out in the script in the SnapAI style, no npm packages). Needs
  `OPENROUTER_API_KEY` in the gitignored `.env.icons.local` at the repo
  root; each run costs money (about $0.50 for 3 images). Candidates go to
  `build/icon-candidates/`.
- `scripts/make-icon.swift`: `--artwork <png>` writes `Awake/AppIcon.icon`
  around a chosen candidate; `preview <png> <candidates>...` renders
  candidates as icons for choosing. It can also draw a cup itself (no AI).

## Building and checking

```sh
xcodebuild -project Awake.xcodeproj -scheme Awake -configuration Debug -derivedDataPath build/DerivedData build
```

Debug builds accept `-AwakeStartSeconds N` to turn Awake on at launch
(N > 0 timed, 0 until turned off), so behaviour can be checked from the
shell:

```sh
build/DerivedData/Build/Products/Debug/Awake.app/Contents/MacOS/Awake -AwakeStartSeconds 15 &
pmset -g assertions | grep Awake   # present now, gone after 15 s
```

## How the owner works

- Talk to the owner in **Polish**; code, comments, commits and docs in
  **English**.
- **Never download or run prebuilt binaries** or self-updating launchers
  (including skill scripts that fetch engines). Prefer Apple frameworks;
  no third-party dependencies (no Sparkle etc.) unless the owner agrees.
- **Never ask for keys, certificates or passwords in chat**; say where they
  go and let the owner enter them.
- Commits: one topic each, the body explains why, and they end with a
  `Co-Authored-By:` line for the agent.
- Verify before calling something done (build it, run it, look at it), and
  say plainly what could not be verified.
- Ask before anything public-facing: pushing to the public repo,
  publishing a GitHub release.

## Releasing

1. One-time, by the owner: create a "Developer ID Application" certificate
   (Xcode > Settings > Accounts > Manage Certificates) and store notary
   credentials with `xcrun notarytool store-credentials awake-notary
   --apple-id <apple id> --team-id 73SQTP34GN`.
2. Bump `MARKETING_VERSION` (and `CURRENT_PROJECT_VERSION`) in the project.
3. `scripts/release.sh` archives, exports with Developer ID, notarizes,
   staples and writes `build/release/Awake-<version>.zip`.
4. After the owner agrees: `gh release create v<version> <zip> --title
   "Awake <version>" --generate-notes`.
