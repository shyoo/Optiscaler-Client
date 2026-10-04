# Optiscaler-Client (shyoo fork) — Handoff

**Current state and what to do next, not a changelog.** Replaced as work lands, never stacked.
Fork-only file; see [`AGENTS.md`](AGENTS.md).

## Where things stand

- The fork's `general` = upstream `general` @ `f73cf2c` (v1.0.8) + the fork-only workspace files
  (`AGENTS.md`, `HANDOFF.md`, `fork/`, the fork-local `.gitignore` block). No product code has
  changed yet. `dotnet build` is green at this baseline (.NET SDK 10.0.401, 0 warnings).
- The maintainer approved the dlssg_for_sm86 proposal on upstream issue #103. The implementation
  plan is [`fork/PLAN-dlssg-sm86.md`](fork/PLAN-dlssg-sm86.md): agreed scope (§1), the gaps
  between the stated conventions and the code (§2), verified upstream facts for mod tag `0.3.5`
  (§3), design (§4), PR slicing (§5), task breakdown (§6), tests (§7), and questions for the
  maintainer (§9).

## What is unproven

- Whether `GameInstallationService.DetermineInstallDirectory` gives the rendering-exe directory
  for UE games whose Streamline DLLs sit under `Engine\Plugins\…` (plan §4.4).
- The exact per-build file list at mod commit `9621db5` (the docs describe four root proxies; the
  repo keeps three of them under `alternatives/`). The pin script settles this.
- Coexistence of the mod with OptiScaler's own DLSS-G output providers (plan §8).

## Next

1. **Post the §9 questions on issue #103** (the user posts; agents don't comment on upstream).
   Q1 (code-behind vs ViewModel/DI) and Q3 (placement/visibility) gate the UI task.
2. Start plan §6 tasks 2–4: pin script + manifest for `0.3.5`; models + GPU helpers + package
   service; backup-store component scope. Tasks 3 and 4 can run in parallel.
