# Optiscaler-Client (shyoo fork) — Handoff

**Current state and what to do next, not a changelog.** Replaced as work lands, never stacked.
Fork-only file; see [`AGENTS.md`](AGENTS.md).

## Where things stand

- The fork's `general` = upstream `general` @ `f73cf2c` (v1.0.8), plus the fork-only workspace
  files, plus the **dlssg_for_sm86 feature** (t909). Local `general` in the main checkout is ahead
  of `origin/general`: the landing policy doesn't push, and the user pushes when they choose to.
- **dlssg_for_sm86 is done and the PR branch is pushed**: `origin/pr/dlssg-sm86` (head `1e438c1`).
  It holds 7 product commits cut from `upstream/general` @ `f73cf2c`, with the AGENTS.md guards
  clean, the same product content as `general`, and a build with 0 warnings. **The user opens the
  upstream PR** with the text in [`fork/pr/dlssg-sm86.md`](fork/pr/dlssg-sm86.md). Agents never
  open it.
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
  - UI: `Views/ManageGameWindow.DlssgSm86.cs` (card in the Experimental zone, four hooks in the main
    file) and `Views/CacheManagementWindow.DlssgSm86.cs`. 45 `TxtDlssgSm86*` keys in all 14
    languages.
  - Pinned: mod `0.3.5` @ `9621db5`. To bump the mod version, run
    `fork/tools/pin-dlssg-manifest.sh <tag>`, then rerun the harness.
- **Verified:**
  - The user's manual pass on FF16 / RTX 3080 Ti (all steps as expected, including OptiScaler
    together with the mod, the collision refusal, and a byte-identical uninstall).
  - `fork/tools/dlssg-harness` (33 checks).
  - Windows and linux-x64 builds.

## What is unproven

- The manual-install message in the real UI: it was added after the user's pass and is covered by
  the harness only.
- Games other than FF16. Notably, no MFG-capable game (Streamline ≥ 2.8, for 3X/4X/6X) has been
  tried, and neither has a UE game whose exe sits in `Binaries\Win64`.

## Next

- The user opens the upstream PR from `pr/dlssg-sm86`. Review feedback becomes new commits on
  `general` (via Warmstart tasks), then gets cherry-picked onto `pr/dlssg-sm86` and pushed to
  `origin`. Never force-push once the PR is open, unless the user asks.
- Follow-ups agreed on #103 (each its own PR later): the Diagnose button (plan §5 PR 2), and FG
  provider integration plus auto-selection in `GetRecommendation` (PR 3).

Housekeeping the user deferred: delete the stale `warmstart/t902` branch (local and `origin`).
