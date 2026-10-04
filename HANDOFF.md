# Optiscaler-Client (shyoo fork) — Handoff

**Current state and what to do next, not a changelog.** Replaced as work lands, never stacked.
Fork-only file; see [`AGENTS.md`](AGENTS.md).

## Where things stand

- The fork's `general` = upstream `general` @ `f73cf2c` (v1.0.8) + the fork-only workspace files
  (`AGENTS.md`, `HANDOFF.md`, `fork/`, the fork-local `.gitignore` block). No product code has
  changed yet. `dotnet build` is green at this baseline (.NET SDK 10.0.401, 0 warnings).
- Local `general` in the main checkout is ahead of `origin/general` (Warmstart's landing policy is
  `commit-and-merge`, which doesn't push). The user pushes `general` when they choose to.
- The maintainer approved the dlssg_for_sm86 proposal on upstream issue #103 (their only reply,
  2026-10-03 19:19 UTC). The implementation plan is
  [`fork/PLAN-dlssg-sm86.md`](fork/PLAN-dlssg-sm86.md).
- **The plan's open questions are decided, not asked** (plan §9). The user chose to settle them
  in-fork and discuss details in the PR. In short:
  - **Q1 code-behind:** no DI, no ViewModel. Logic in the service; a thin
    `Views/ManageGameWindow.DlssgSm86.cs` partial; service from
    `PlatformServiceFactory.CreateDlssgSm86Service()` (null off Windows).
  - **Q2 tests:** no test project in PR 1; §7 scenarios are checked by hand in plan task 8.
  - **Q3 placement:** inside the Experimental zone (`GridExperimentalZone`, Settings →
    Experimental). Hidden on Linux and on non-Turing/Ampere GPUs; game-level blockers shown with
    the reason.
  - **Q4 collision:** installing OptiScaler onto a DLSSG proxy name is refused with a message.
  - **Q5 proxies:** every free name of version/winmm/dbghelp/dinput8; size shown before download.
  - **Q6 docs:** README feature line + acknowledgments; no CHANGELOG (the maintainer writes it).

## What is unproven

- Whether `GameInstallationService.DetermineInstallDirectory` gives the rendering-exe directory
  for UE games whose Streamline DLLs sit under `Engine\Plugins\…` (plan §4.4).
- The exact per-build file list at mod commit `9621db5` (the docs describe four root proxies; the
  repo keeps three of them under `alternatives/`). The pin script settles this.
- Coexistence of the mod with OptiScaler's own DLSS-G output providers (plan §8).

## Next

Nothing is blocked on the maintainer any more. Start plan §6:

1. **Task 2:** pin script (fork-only, under `fork/`, no `.cs`) + product manifest JSON for mod
   tag `0.3.5`, both builds (310.9 / 310.1). Settles the per-build file list above.
2. **Tasks 3 and 4 in parallel:** models + GPU helpers + package service (needs task 2); backup
   store component scope (independent).
3. Then task 5 (install/update/uninstall + collision guards), task 6 (UI, strings ×14, gamepad),
   task 7 (cache management + README).

Housekeeping the user deferred: delete the stale `warmstart/t902` branch (local and `origin`).
