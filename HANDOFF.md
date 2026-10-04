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

- **The implementation plan is [`fork/IMPL-dlssg-sm86.md`](fork/IMPL-dlssg-sm86.md)** (t909). It
  wins over the PLAN where they differ. Decisions made there with the user:
  - **D1:** the card has its own Install/Update/Uninstall buttons, outside the main Install
    pipeline.
  - **D2:** the backup record uses store key `<targetDir>::dlssg_sm86` (the `::dlssnr`
    precedent), plus a slug guard in `FindBackupDirUnder`. There is no `_components/` subtree.
  - **D3:** v1 exposes only Build + Max multiplier.

## What is unproven

- Coexistence of the mod with OptiScaler's own DLSS-G output providers (plan §8).
- Whether `X509Certificate.CreateFromSignedFile` builds warning-free on net10 (IMPL §3.2). There is
  a fallback.
- The per-build file list and the UE target directory are **settled** (IMPL §1). 310.1 has no INI
  of its own and uses the root INI.

## Next

Implement IMPL §4 in order: step A (pin script + manifest + models + GPU helpers), then B, C, D,
E/F, G. Then the manual matrix (H) and the PR branch (I).

Housekeeping the user deferred: delete the stale `warmstart/t902` branch (local and `origin`).
