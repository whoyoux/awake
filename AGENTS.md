# Agent notes for Awake

Awake is a SwiftUI menu bar app (`MenuBarExtra`, no Dock icon) that keeps
the Mac and display awake with an IOKit power assertion. It is meant for
the Mac App Store (free) and lives in a public GitHub repository.

## Owner's decisions

- Name **Awake**, bundle id `dev.whxx.awake`, Apple Developer team
  `73SQTP34GN` (individual account; the store seller name is the owner's
  legal name).
- Distribution: Mac App Store, free. App Sandbox on; no extra entitlements
  are needed for power assertions.
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
- `scripts/make-icon.swift`: draws the app icon PNGs with AppKit
  (`swift scripts/make-icon.swift` from the repo root).

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
- Ask before anything public-facing: pushing to the public repo, App Store
  submission.

## Mac App Store checklist

- App icon (asset catalog; currently a generated placeholder).
- App Store Connect record: description, screenshots, category Utilities,
  privacy policy URL, support URL (a small static page, e.g. on `whxx.dev`).
- Privacy nutrition label: Data Not Collected.
- Archive in Xcode (Release), upload, App Review.
