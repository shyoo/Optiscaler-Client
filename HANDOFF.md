# Optiscaler-Client (shyoo fork) — Handoff

**Current state and what to do next, not a changelog.** Replaced as work lands, never stacked.
Fork-only file; see [`AGENTS.md`](AGENTS.md).

## Where things stand

- The fork's `general` = upstream `general` @ `f73cf2c` (v1.0.8), plus the fork-only workspace
  files, plus the **dlssg_for_sm86 feature** (t909). Local `general` in the main checkout is ahead
  of `origin/general`: the landing policy doesn't push, and the user pushes when they choose to.
- **dlssg_for_sm86 is implemented** as six product commits plus one `docs:` commit, matching the
  PR slicing in plan §5. The design is [`fork/PLAN-dlssg-sm86.md`](fork/PLAN-dlssg-sm86.md); the
  concrete plan and the **as-built deviations** are at the top of
  [`fork/IMPL-dlssg-sm86.md`](fork/IMPL-dlssg-sm86.md). Read that section before changing the
  feature. In short:
  - Services: `DlssgSm86PackageService` (pinned manifest, download, verify, cache) and
    `DlssgSm86Service` (Windows-only; eligibility, install/update/uninstall, INI, HAGS).
    `DlssgSm86Records` is the platform-neutral lookup used by the analyzer and OptiScaler's
    collision guard.
  - Backup record: store key `game.InstallPath + "::dlssg_sm86"`. `InstallationManifest.ComponentId`
    keeps it out of `FindBackupDirUnder`.
  - UI: `Views/ManageGameWindow.DlssgSm86.cs` (card in the Experimental zone, four hooks in the main
    file) and `Views/CacheManagementWindow.DlssgSm86.cs`. 43 `TxtDlssgSm86*` keys in all 14
    languages.
  - Pinned: mod `0.3.5` @ `9621db5`, both runtimes (310.9 / 310.1). To bump the mod version, run
    `fork/tools/pin-dlssg-manifest.sh <tag>`.
- **Verified:** `fork/tools/dlssg-harness` (27 end-to-end checks against fake game folders, with
  real pinned downloads) all pass. Windows and `linux-x64` builds have 0 warnings.
- Settled decisions (don't reopen): plan §9 Q1–Q6, and IMPL D1 (own buttons), D2 (store-key
  precedent) and D3 (Build + multiplier only).
- The PR text is drafted in [`fork/pr/dlssg-sm86.md`](fork/pr/dlssg-sm86.md). Its "Tested" section
  is still empty.

## What is unproven

- **The UI has never been seen running**: layout at narrow widths in 14 languages, gamepad
  navigation, the progress overlay, the dialogs.
- **No real game yet**: FG actually showing up, HAGS behaviour, coexistence with OptiScaler's own
  DLSS-G output providers (plan §8).

## Next

1. **Task H, the manual matrix (the user, on the RTX 3080 Ti):** plan §7 "Manual" list. Turn on
   Settings → Experimental, open a DLSS-G game (FF16), then install, launch, uninstall, and check
   the folder is identical. Also do OptiScaler + DLSSG together and uninstall each one
   independently. Fix whatever turns up, then fill in "Tested" in `fork/pr/dlssg-sm86.md`.
2. **Task I:** cut `pr/dlssg-sm86` from `upstream/general`, cherry-pick the product commits
   (`feat:`/`fix:`/`docs:` subjects mentioning dlssg_for_sm86 or component backups, oldest first),
   run the AGENTS.md guard and push to `origin` only. The user opens the upstream PR.

Housekeeping the user deferred: delete the stale `warmstart/t902` branch (local and `origin`).
