# Optiscaler-Client (shyoo fork) — agent guide

How to work in this fork. Read [`HANDOFF.md`](HANDOFF.md) first: it is the only file that carries
current state. [`README.md`](README.md) is upstream's own and describes the product.

**This file, `HANDOFF.md`, `fork/` and the marked block at the end of `.gitignore` are fork-only.
They must never reach an upstream pull request.** This repository is public, so nothing committed
here may contain secrets, tokens, or personal machine paths.

## What this fork is for

- Fork: `origin` = https://github.com/shyoo/Optiscaler-Client. Everything agents push goes here.
- Upstream: `upstream` = https://github.com/Optiscaler-Client/Optiscaler-Client (maintainer:
  Agustinm28; integration branch `general`, releases from `main`). **Fetch-only for agents.**
- Check before any push: `git remote get-url origin` must print the `shyoo` URL. If the remotes
  are named differently, stop and ask; don't guess.
- Current goal: add **dlssg_for_sm86** (DLSS Frame Generation on RTX 20/30) as a standalone
  component, as agreed in upstream issue #103. The plan is
  [`fork/PLAN-dlssg-sm86.md`](fork/PLAN-dlssg-sm86.md).

## Branch model

| Branch | What it holds |
|---|---|
| `general` (fork: `origin/general`) | Upstream `general` **+** the fork-only files **+** finished fork work not yet upstream. Warmstart task branches land here. |
| `warmstart/t*` | One task each. Cut from `general`, landed back onto it. |
| `pr/<topic>` | One upstream PR candidate each. Cut from **`upstream/general`** and carrying **product commits only**. Pushed to **`origin`** (the fork) only; the user opens the PR against `Optiscaler-Client:general`. |

⛔ **Never create a pull request, issue, comment or push on upstream (`upstream`,
`Optiscaler-Client/Optiscaler-Client`).** Agents push `pr/<topic>` branches to `origin` and stop
there. The user reviews the branch and opens the upstream PR themselves.

- Don't run `gh pr create` at all. On a fork, `gh` targets the parent repository by default, so a
  bare `gh pr create` opens the PR on upstream. That's how an upstream PR got opened by mistake
  once already. If a fork-internal PR is ever wanted, the user asks for it explicitly, and it uses
  `--repo shyoo/Optiscaler-Client --base general`.
- Warmstart landing must merge or push into the fork's `general`, never open a pull request.

- **Syncing with upstream:** `git fetch upstream`, then on `general` run
  `git merge upstream/general` and push to `origin`.
  Merge, don't rebase: `general` is pushed to a public fork, so no history rewrites and no force
  pushes.
- **Making a PR branch:**
  ```sh
  git fetch upstream
  git switch -c pr/<topic> upstream/general
  git cherry-pick <product commits, oldest first>
  # guard: must print nothing
  git diff --name-only upstream/general...HEAD | grep -E '^(AGENTS\.md|HANDOFF\.md|fork/)'
  git diff upstream/general...HEAD -- .gitignore   # must not contain the fork-local block
  git push -u origin pr/<topic>                     # the fork only, never upstream
  ```
  Then hand over to the user with the branch name and a proposed PR title and description. Write
  the description to `fork/pr/<topic>.md` (a `fork:` commit), not to GitHub.
  Once a PR is merged upstream, the next `git merge upstream/general` brings the same change back
  into `general` (git resolves identical cherry-picks cleanly in most cases).

## Fork-only files

- `AGENTS.md`, `HANDOFF.md`: this guide and the current state.
- `fork/**`: plans, notes, dev scripts (e.g. the dlssg_for_sm86 manifest pinning script).
  **Never put `.cs` files here.** The root `OptiscalerClient.csproj` compiles every `**/*.cs`
  under the repo root, so they'd be built into the app.
- The block at the end of `.gitignore`, between the `fork-local` markers.

**Never mix fork-only paths and product code in one commit.** Start fork-only commit subjects with
`fork:` (e.g. `fork: update handoff`), so they're easy to leave out when cherry-picking. When a
task touches both, make two commits; don't squash them together.

## Before you start

- **.NET 10 SDK** is required (`net10.0`); the dev machine has 10.0.401 next to 9.0.304. A missing
  10.x SDK shows up as NETSDK1045 and fails the landing check.
- Windows is the only platform this fork's feature targets. Linux must keep building, and the new
  UI must be hidden there.

## Checks

Run these and make them pass before you report done:

- `dotnet build OptiscalerClient.csproj -c Debug`: no errors and no new warnings.
- Docs-only changes (fork files, markdown): no build needed.

## When you commit

- Commit style follows upstream: lowercase conventional subjects (`feat: …`, `fix: …`,
  `docs: …`, `style: …`); fork-only work uses `fork: …`. Explain *why* in the body.
- One coherent commit per task where it is safe to squash. Keep fork-only and product commits
  separate (see above).
- Update [`HANDOFF.md`](HANDOFF.md) in a `fork:` commit alongside the work: what changed, what is
  next.
- ⛔ Never commit build output, downloaded mod binaries (`*.dll` from dlssg_for_sm86 or any
  other upstream), credentials, or anything gitignored.

## Upstream conventions (maintainer, issue #103)

- Logic in **Services**, not Views. Async disk and network work, off the UI thread.
- **No hardcoded user-facing strings.** Every new key goes into **all 14**
  `Languages/Strings.*.axaml` files. Read them with `GetResourceString(key, fallback)` as the
  existing code does.
- Platform-specific logic in its own service; Windows-only features are **hidden** on Linux, not
  disabled.
- Reuse what exists: `GpuSelectionHelper` (GPU gating), `BackupStoreService` (backups),
  `AntiCheatHelper`, `NetworkService` / `HttpRetryHelper` (downloads, proxy-aware),
  `PlatformServiceFactory` (platform services), global styles and resources in
  `App.axaml` / `Styles/`.
- New `.cs` files carry the same GPL-3.0-or-later header as existing ones.
- The maintainer's text mentions MVVM and a DI container, but the code has neither (services are
  created with `new`; Views are code-behind). Follow the existing pattern unless the maintainer
  answers otherwise (plan §9 Q1).

## Pitfalls

- **One backup manifest per game, and `UninstallOptiScaler` deletes the whole
  `Backups/<slug>/`.** Anything that has to survive an OptiScaler uninstall can't live in that
  manifest. The FSR 4 swap lives there on purpose; the dlssg_for_sm86 component must not (plan
  §4.5).
- The backup store key is the directory OptiScaler was actually installed into, which isn't
  always `game.InstallPath` (see `BackupStoreService.FindBackupDirUnder`).
- `Views/ManageGameWindow.axaml.cs` is about 7.9k lines and changes often upstream. Put new
  sections in their own partial file (`ManageGameWindow.<Feature>.cs`) to keep merges cheap.
- The csproj has `InternalsVisibleTo("Optiscaler-Client.Tests")`, but no test project is in the
  repo.
