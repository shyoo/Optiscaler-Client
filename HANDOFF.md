# Optiscaler-Client (shyoo fork) — Handoff

**Current state and what to do next, not a changelog.** Replaced as work lands, never stacked.
Fork-only file; see [`AGENTS.md`](AGENTS.md).

## Where things stand

- The fork's `general` = upstream `general` @ `61893cb` (merged in), plus the fork-only
  workspace files. Its product code is identical to upstream's. The landing policy doesn't push;
  `origin/general` is pushed by hand after an upstream sync.
- **dlssg_for_sm86 is upstream** (2026-10-06): #117 was rebased by the maintainer as `a2bfd76`
  (the feature) and `61893cb` (the review: main install buttons, None, badge colour, no status
  line), and closed rather than merged on GitHub. `pr/dlssg-sm86` is deleted. The posted text is
  kept in [`fork/pr/dlssg-sm86.md`](fork/pr/dlssg-sm86.md).
- Design: [`fork/PLAN-dlssg-sm86.md`](fork/PLAN-dlssg-sm86.md). Concrete plan and the **as-built
  deviations**: top of [`fork/IMPL-dlssg-sm86.md`](fork/IMPL-dlssg-sm86.md). Read that before
  changing the feature. In short:
  - Services: `DlssgSm86PackageService` (pinned manifest, download, verify, cache) and
    `DlssgSm86Service` (Windows-only; eligibility, install/update/uninstall, INI, HAGS).
    `DlssgSm86Records` is the platform-neutral lookup used by the analyzer and OptiScaler's
    collision guard.
  - Backup record: store key `game.InstallPath + "::dlssg_sm86"`. `InstallationManifest.ComponentId`
    keeps it out of `FindBackupDirUnder`.
  - A copy of the mod placed by hand (any version) is detected by the UTF-16 `dlssg_sm86.ini` string
    in the DLL and blocks the install (`DlssgSm86Blocker.ManualInstall`).
  - UI: `Views/ManageGameWindow.DlssgSm86.cs` (selectors in the Experimental zone; hooks in the
    main file's install / uninstall / button-state code) and `Views/CacheManagementWindow.DlssgSm86.cs`.
    No buttons of its own: the main Auto/Manual Install and Uninstall run it, following the
    service's `GetPendingAction` plan (Install / Update / Apply / Remove / nothing); keep decisions
    out of the view, as the maintainer asked on #103. "None" works like the FSR 4 swap at None.
    45 `TxtDlssgSm86*` keys in all 14 languages.
  - Pinned: mod `0.3.5` @ `9621db5`. To bump the mod version, run
    `fork/tools/pin-dlssg-manifest.sh <tag>`, then rerun the harness.
- **Verified:**
  - The user's manual pass on FF16 / RTX 3080 Ti (all steps as expected, including OptiScaler
    together with the mod, the collision refusal, and a byte-identical uninstall).
  - The user's later checks in the app: the manual-install blocker with their 0.2.4 copy, and the
    button labels after the pending-action refactor.
  - After the #117 review (2026-10-04), the user's FF16 checks of the new flow: DLSS FG alone,
    None changing nothing on its own, Uninstall of DLSS FG alone, and None + OptiScaler reinstall
    removing it. Not re-checked by hand: Manual Install's exe picker, the combined uninstall
    message, the collision text, gamepad navigation.
  - `fork/tools/dlssg-harness` (49 checks).
  - Windows and linux-x64 builds.

## What is unproven

- Games other than FF16. Notably, no MFG-capable game (Streamline ≥ 2.8, for 3X/4X/6X) has been
  tried, and neither has a UE game whose exe sits in `Binaries\Win64`.

## Next

- Fixes to the feature now go straight to a new `pr/<topic>` branch cut from `upstream/general`.
- Follow-ups agreed on #103 (each its own PR later): the Diagnose button (plan §5 PR 2), and FG
  provider integration plus auto-selection in `GetRecommendation` (PR 3).

Housekeeping the user deferred: delete the stale `warmstart/t902` branch (local and `origin`).
