# dlssg_for_sm86: implementation plan

Fork-only (see [`AGENTS.md`](../AGENTS.md)). This turns the design in
[`PLAN-dlssg-sm86.md`](PLAN-dlssg-sm86.md) into concrete steps against the code at `general` @
`fc6fbf7` (upstream `f73cf2c`, v1.0.8). Where the two disagree, **this file wins**. The PLAN keeps
the reasons and the upstream agreement.

Written 2026-10-03 after reading the code and the mod repo at `9621db5`.

---

## As built (t909, 2026-10-03): where the code differs from the plan below

Steps A–G are implemented. These choices replace what §2–§3 say:

- **Store key:** `game.InstallPath + "::dlssg_sm86"`, not `<targetDir>::…`. That's the same root
  OptiScaler keys its own record by (`storeKey = game.InstallPath`), so the analyzer finds the
  record without first resolving the exe folder. The folder is in `InstalledGameDirectory`.
- **Reverse-lookup guard:** a new `InstallationManifest.ComponentId` field (`"dlssg_sm86"`).
  `FindBackupDirUnder` skips manifests that set it. The planned slug comparison would have broken
  UE layouts, where OptiScaler's key (the game root) differs from its install folder. The dlssnr
  record doesn't set `ComponentId`, so it's still not skipped; that's left alone on purpose.
- **Update / build switch:** the new files are downloaded and verified first. Then the old install
  is removed and the new one installed. If the new install then fails, the folder is left
  **clean**, not on the previous version. Only local disk I/O can fail at that point.
- **Logs:** uninstall removes `<exeDir>\dlssg_sm86\logs` with no opt-in, but only if the folder
  didn't exist at install time (recorded in `InstalledDirectories`). A folder left from a manual
  install stays.
- **Manual installs (added after the user's test pass):** new blocker `ManualInstall`. Any file under
  the four names, or `dxgi.dll`/`d3d12.dll`, that contains the UTF-16 string `dlssg_sm86.ini` is a
  hand-copied mod (0.2.4 and 0.3.5 both match; system DLLs don't). The card lists those files plus
  the INI and asks the user to remove them first, so two builds are never mixed.
- **NotDx12:** blocks only when there's Vulkan evidence and no D3D12 evidence. `IsDirectX12` alone
  is false for most DX12 games, which don't ship d3d12 DLLs.
- **Thumbprint:** `X509Certificate.CreateFromSignedFile` is obsolete (SYSLIB0057), and
  `X509CertificateLoader` has no PE-signature equivalent, so the warning is suppressed at that one
  call.
- **Gamepad:** a hook in `GetRootNeighborCandidates` lets the partial supply every DLSSG-related
  neighbour. Each list ends with the regular map's target.
- **Cache page:** its own partial (`CacheManagementWindow.DlssgSm86.cs`). "Clear application
  cache" needed no change: it already removes all of `Cache/`.
- **Pending action in the service (after review against #103):** `IDlssgSm86Service.GetPendingAction`
  returns a `DlssgSm86ActionPlan` (Install / Update / ApplyMultiplier / None, download size, update
  available, can run). The window only renders it, and the click handler uses the same plan to
  choose `SetMaxGeneratedFrames` or `InstallAsync`. The 6X→4X clamp is one helper,
  `DlssgSm86Multipliers.Clamp`, used by both the combo box and the service.
- **Re-check refusal:** `InstallAsync` throws `DlssgSm86BlockedException` (carrying the eligibility)
  when the folder changed since the window looked, and the dialog shows the blocker's own text.
- **Strings:** 51 keys ×14. The verification failure reasons and the backup failure are translated
  too, so no English detail is left in the error dialogs.
- **Downloads:** only the proxies needed for the free names are downloaded (lazily, per file).

Verified by: `fork/tools/dlssg-harness` (41 checks), Windows + `linux-x64` builds with no
warnings, and the user's manual pass on FF16 / RTX 3080 Ti (task H, steps 1–10, all as expected,
and later the manual-install blocker against their 0.2.4 `version.dll`). The pending-action move
came after that pass; the user then confirmed Apply and Update labels in the app.

## 0. Decisions made in this round (user, 2026-10-03)

| # | Decision | Replaces |
|---|---|---|
| D1 | **The card has its own buttons.** The DLSSG card in the Experimental zone has Build + Max multiplier combos and its own Install / Update / Uninstall button. It isn't wired into the main Install button or `ExecuteInstallAsync`, and the main Uninstall doesn't touch it. | PLAN §4.8 (confirms it) |
| D2 | **Backup record = store-key precedent.** Store key `<targetDir> + "::dlssg_sm86"`, the same convention as `DlssNrOnAmdService` (`gameDir + "::dlssnr"`). No new `_components/` subtree and no scoped API on `BackupStoreService`. Add one guard to `FindBackupDirUnder` (§3.3). | PLAN §4.5 bullets 1–2, commit 3 |
| D3 | **INI knobs in v1 = Build + Max multiplier only.** `Optimized` stays at the factory value (1). | PLAN §4.6 "if exposed, `Optimized`" |

Already decided before this round (PLAN §9): code-behind with no DI; no test project; inside
`GridExperimentalZone`, hidden on Linux and on non-Turing/Ampere GPUs; refuse OptiScaler onto a
DLSSG proxy name; install every free utility name; README only, no CHANGELOG.

## 1. Facts settled while planning (were "unproven" in HANDOFF)

**Per-build file list at `9621db573e07ed54f50c15bbb585ed9a7bdfac28`** (from `git/trees`):

| Build | Proxies we install | INI |
|---|---|---|
| 310.9 (default) | `version.dll` (root), `alternatives/{winmm,dbghelp,dinput8}.dll`, about 30.0 MB each | root `dlssg_sm86.ini` (3548 B) |
| 310.1 | `310.1/version.dll`, `310.1/alternatives/{winmm,dbghelp,dinput8}.dll`, about 28.0 MB each | **none in `310.1/`**. Use the root INI: per `docs/INSTALL.en.md`, "the INI keys are identical in both variants". |

Never installed: `alternatives/{dxgi,d3d12}.dll` (manual only upstream), `.DS_Store`,
`README*`, `archive/**`. The four proxies differ only by name and forwarding target, but each is a
separately built, separately signed binary, so each one is downloaded on its own.

**Target directory (PLAN §4.4 "VERIFY").** This is right by construction.
`DetermineInstallDirectory` returns the directory of `DetermineMainExecutable`, which prefers
`<Project>\Binaries\Win64\*.exe`. That's the rendering exe even when `sl.interposer.dll` sits under
`Engine\Plugins\…`, and proxies only load from the exe's directory. The remaining risk is the
heuristic picking the wrong exe. Mitigations:
- If OptiScaler's committed manifest exists, use its `InstalledGameDirectory`.
- Show the target folder in the card.

**OptiScaler's lists don't claim our names.** `KnownOptiscalerArtifacts` has the proxy names
commented out, and `SensitiveArtifacts` holds only `dxgi.dll` + FFX/XeSS DLLs. So residue cleanup
and Folder Cleanup don't treat our files as OptiScaler's. The only collision is the chosen
`InjectionMethod` (§3.4).

## 2. Code map: what changes where

New files (GPL header, `namespace OptiscalerClient.*`):

| File | Contents |
|---|---|
| `Models/DlssgSm86.cs` | `enum DlssgSm86Build { V310_9, V310_1 }`, `enum DlssgSm86Multiplier { X2=1, X3=2, X4=3, X6=5 }` (value = `MaxGeneratedFrames`), `enum DlssgSm86Blocker { None, NoDlssG, NotDx12, AntiCheat, NoFreeProxyName, NoTargetDir }`, `record DlssgSm86Eligibility(...)`, the package-manifest classes, and `record DlssgSm86InstallState(Version, Build, ProxyNames, TargetDir, Multiplier)`. |
| `assets/configs/dlssg_sm86_manifest.json` | Pinned trust root (§3.1). |
| `Services/DlssgSm86PackageService.cs` | Manifest load, download + verify, and the cache (§3.2). Cross-platform code, only used on Windows. |
| `Services/IDlssgSm86Service.cs` + `Services/DlssgSm86Service.cs` | Eligibility, proxy-name choice, install / update / uninstall, INI, HAGS (§3.3–3.6). The implementation is `[SupportedOSPlatform("windows")]`. |
| `Views/ManageGameWindow.DlssgSm86.cs` | Thin partial: populate, click handlers, gamepad entries (§3.7). |
| `fork/tools/pin-dlssg-manifest.sh` | Fork-only pin script (§3.1). |

Edits to existing files (keep each one small; the big files change often upstream):

| File | Edit |
|---|---|
| `OptiscalerClient.csproj` | Copy-to-output rule for the new JSON, next to the other `assets\configs\*.json`. |
| `Helpers/GpuSelectionHelper.cs` | `IsTuringRtx`, `IsAmpere`, `IsDlssgSm86Capable` (§3.3). |
| `Services/PlatformServiceFactory.cs` | `CreateDlssgSm86Service()` → `IDlssgSm86Service?` (null off Windows). |
| `Services/ComponentManagementService.cs` | `StreamToFileAsync`: `private static` → `internal static`. One word, reused by the package service. |
| `Services/BackupStoreService.cs` | `FindBackupDirUnder` slug guard (§3.3). |
| `Services/GameInstallationService.cs` | Reverse-collision guard at the top of `InstallOptiScaler` (§3.4). |
| `Models/Game.cs` | `IsDlssgSm86Installed`, `DlssgSm86Version`, `DlssgSm86Build`. |
| `Services/GameAnalyzerService.cs` | Reset the three fields next to the other resets (~l.157), then set them from the `::dlssg_sm86` manifest (§3.6). |
| `Views/ManageGameWindow.axaml` | A second row inside the Experimental zone's `StackPanel`, below the RenoDX/Setup NR grid (§3.7). |
| `Views/ManageGameWindow.axaml.cs` | Call the partial's `PopulateDlssgSm86Async()` from the existing Experimental visibility block (~l.1545). Add our controls to the gamepad direction map (~l.990–1050). An `LstComponents` entry when installed. |
| `Views/CacheManagementWindow.axaml.cs` | A `"dlssgsm86"` sidebar section: per-version/build cards with sizes and delete. Include it in "Clear application cache". |
| `Languages/Strings.*.axaml` ×14 | `TxtDlssgSm86*` keys (§3.8). |
| `README.md` | Feature line + acknowledgment (separate `docs:` commit). |

## 3. Component designs

### 3.1 Pinned manifest + pin script

The JSON shape (camelCase; read with a `JsonSerializerContext`; add the types to
`OptimizerContext` if that's where the app keeps them, so trimming stays happy):

```json
{
  "modVersion": "0.3.5",
  "commit": "9621db573e07ed54f50c15bbb585ed9a7bdfac28",
  "repo": "sdli1995/dlssg_for_sm86",
  "signerThumbprint": "85BA66762F851E49148D706915D09026281418E6",
  "builds": [
    { "id": "310.9", "maxMultiplier": 5, "files": [
      { "name": "version.dll", "path": "version.dll", "role": "proxy", "size": 30021920, "sha256": "…", "gitBlobSha": "efd92261…" },
      { "name": "winmm.dll",   "path": "alternatives/winmm.dll", "role": "proxy", … },
      { "name": "dbghelp.dll", "path": "alternatives/dbghelp.dll", "role": "proxy", … },
      { "name": "dinput8.dll", "path": "alternatives/dinput8.dll", "role": "proxy", … },
      { "name": "dlssg_sm86.ini", "path": "dlssg_sm86.ini", "role": "ini", … } ] },
    { "id": "310.1", "maxMultiplier": 3, "files": [ "…310.1/version.dll, 310.1/alternatives/*, root INI…" ] }
  ]
}
```

The URL is built as `https://raw.githubusercontent.com/{repo}/{commit}/{path}`. It is never stored
per file, so a repo or commit bump touches one field each.

Pin script, `fork/tools/pin-dlssg-manifest.sh <tag>`:
1. Resolve the tag to its commit with `gh api repos/…/git/ref/tags/<tag>`. Dereference it if
   it's an annotated tag.
2. Read the tree with `git/trees/<commit>?recursive=1`. Check that every expected path exists and
   take `size` and `gitBlobSha`.
3. Download each file into a temp dir. Compute `sha256sum`. Check
   `size == stat`, and `git hash-object` == the blob SHA.
4. Check each DLL's signature thumbprint:
   `powershell -NoProfile -Command "(Get-AuthenticodeSignature <f>).SignerCertificate.Thumbprint"`.
   The `Status` is `UnknownError` for this self-signed cert; that's expected.
5. Write the JSON with `jq`, then delete the temp dir. It never commits binaries.

### 3.2 `DlssgSm86PackageService`

- `LoadManifest()`: read the JSON from `AppContext.BaseDirectory/assets/configs/`, the same way the
  other config JSONs are located. Cache it in a static.
- `GetBuildCacheDir(build)` = `<AppData>/Cache/DlssgSm86/<modVersion>/<buildId>/`. Same root as
  `ComponentManagementService._cacheDir`, so "Clear application cache" sees it.
- `GetMissingFiles(build, proxyNames)`, `GetDownloadSize(build, proxyNames)`: the size shown before
  download (PLAN §9 Q5).
- `EnsureFilesAsync(build, proxyNames, IProgress<double>, CancellationToken)`: for each missing
  file, download to `<name>.part` with `ComponentManagementService.StreamToFileAsync` (shared
  `NetworkService` client, so proxy settings apply), verify, then `File.Move` to the final name.
  Progress is aggregated by bytes across the files. A file already in the cache is **re-verified**
  (size + SHA-256) before use, never trusted blindly.
- `Verify(file, entry)`: size, then SHA-256, then, for `role: proxy`, the signer thumbprint. On any
  mismatch, delete the file and throw `DlssgSm86VerificationException` (message names the file and
  the check that failed).
  - Thumbprint API: try `X509Certificate.CreateFromSignedFile`. If it's obsolete on net10 (a
    SYSLIB warning breaks the "no new warnings" check), P/Invoke `CryptQueryObject` or
    `WinVerifyTrust` with `WTD_REVOKE_NONE`, or drop the runtime check. The pinned SHA-256 already
    covers integrity, so the thumbprint is defence in depth. Decide when coding, and note it in the
    PR.
- `ListCached()`, `DeleteCached(version, build)`, `GetCachedSize(...)`: for Cache Management.
- An in-flight download dictionary keyed by build, the same idea as
  `DlssNrOnAmdService._inFlightDownloads`, so two Manage windows don't download the same build twice.

### 3.3 Eligibility, GPU gate, proxy names (`DlssgSm86Service`)

**GPU helpers** (`GpuSelectionHelper`, same regex style as `IsBlackwell`):
- `IsTuringRtx`: NVIDIA and (`RTX\s?20(50|60|70|80)`, `TITAN RTX`, or
  `Quadro RTX\s?\d{4}`). A GTX 16xx never matches, because it has no tensor cores.
- `IsAmpere`: NVIDIA and (`RTX\s?30(50|60|70|80|90)`, or `RTX\s?A\d{3,4}\b`, which matches
  A2000–A6000 but not "RTX 2000 Ada").
- `IsDlssgSm86Capable(gpu) => IsTuringRtx(gpu) || IsAmpere(gpu)`.
- The card is **hidden** unless all of these hold: `service != null`, the Experimental switch is
  on, and `IsDlssgSm86Capable(GetPreferredGpu(gpuService, Config.DefaultGpuId))`. Use whatever the
  window already resolves as its GPU.

**`GetEligibility(Game game)`** runs inside `Task.Run`. In order, the first blocker wins:
1. Target dir: the manifest's `InstalledGameDirectory`, else OptiScaler's committed manifest dir,
   else `GameInstallationService.DetermineInstallDirectory(game)`. → `NoTargetDir`.
2. `AntiCheatHelper.IsPresent(game.InstallPath)` or `game.HasAntiCheat` → `AntiCheat`.
3. `FrameGenerationConfigurationService.DetectCapabilities(game)`: `HasNativeDlssG`, **or**
   `sl.dlss_g.dll` found under the install path (DetectCapabilities doesn't look for it).
   → `NoDlssG`. `!IsDirectX12` → `NotDx12`.
4. Free proxy names (below). If there are none → `NoFreeProxyName`, with the occupying file names.

**Free proxy names**, in the order `version`, `winmm`, `dbghelp`, `dinput8`. A name is taken when:
- it is ours (in our own manifest) → **free**. This keeps update and reinstall working;
- OptiScaler's committed manifest for the target dir has it as `InjectionMethod`, or in
  `FilesCreated` / `FilesOverwritten` / `InstalledFiles`;
- the FSR 4 swap entry `DllSwapTargetFileName` lists it;
- the file exists on disk and isn't ours. Label the owner where it's recognisable: `*.asi` present
  → "ASI loader"; `ReShade*.ini` → "ReShade"; else "game/unknown".

**`FindBackupDirUnder` guard (D2).** Inside the loop, skip a manifest whose folder name ≠
`ComputeGameSlug(manifest.InstalledGameDirectory)`. A `::dlssg_sm86` (or `::dlssnr`) record
hashes to a different slug than its directory, so OptiScaler's reverse lookup can never pick it.
Mention it in the PR as a small fix that also covers dlssnr.

### 3.4 Install / update / uninstall

The store key is `K = targetDir + "::dlssg_sm86"`. `InstallationManifest` is reused with
`IncludesOptiscaler = false`, `InstalledGameDirectory = targetDir`, plus three new optional fields:
`DlssgSm86Version`, `DlssgSm86Build` and `DlssgSm86ProxyNames` (a list).

**Install(game, build, multiplier, progress, ct):**
1. Re-run eligibility. The UI result may be stale.
2. `EnsureFilesAsync` for the chosen build + free names + the INI.
3. Save the manifest as `in_progress` (a crash leaves a recoverable record).
4. For each proxy and the INI: copy the cache file to `<target>.dlssg_tmp`.
5. For each target: if a file exists, it isn't ours (shouldn't happen, since names were filtered),
   so `BackupFile(K, …)` and record it in `FilesOverwritten` with `PreInstallSha256`. Otherwise
   `FilesCreated`. Then move `*.dlssg_tmp` → target and record `PostInstallSha256`.
6. INI: set `[FrameGeneration] MaxGeneratedFrames` to the chosen multiplier, clamped to the
   build's `maxMultiplier`. Record the post-write hash.
7. Mark the manifest `committed`. Re-analyze the game (`InvalidateCacheForPath` + `AnalyzeGame` +
   `FlushCacheToDisk`, like `SwapFsr4Dll`).
8. Any exception → rollback: delete the `*.dlssg_tmp` and created files, restore the backups,
   delete the store entry. Use a local journal list; `InstallationRollbackJournal` is private to
   `GameInstallationService`, so don't widen it.

**Update** (the pinned version differs from the installed one, or Build changed):
- Read the current INI's user values: all keys in the factory INI's sections, not just the ones
  we expose.
- Uninstall our files without the edited-INI prompt, then install the new set, then write the
  carried-over values back onto the new factory INI with the line-preserving setter.
- 6X → 310.1: clamp to 4X and return a notice for the toast.

**Multiplier change only** (same version + build): rewrite the INI key in place and update its
`PostInstallSha256`. No download.

**Uninstall(game, deleteLogs):**
- For each record: if the current SHA-256 equals `PostInstallSha256`, delete the file or restore
  its backup. A missing file is fine.
- Hash mismatch on the INI → the View asks first: keep my INI / delete anyway. Hash mismatch on a
  DLL (something replaced it) → leave it alone and report it.
- `deleteLogs` → delete `<target>\dlssg_sm86\` (the default log dir).
- `DeleteBackup(K)`. Never touch `%LOCALAPPDATA%\DlssgSm86\bundles`.
- Delete with retry on sharing violations. `DeleteFileWithRetry` is private in
  `GameInstallationService`, so give this service its own small copy, or make that one
  `internal static`. Prefer the one-word change.

**Reverse-collision guard** (`GameInstallationService.InstallOptiScaler`, right after `gameDir` is
resolved):

```csharp
var dlssgNames = DlssgSm86Service.GetInstalledProxyNames(gameDir); // static, reads "::dlssg_sm86" manifest; empty off Windows
if (dlssgNames.Contains(injectionDllName, StringComparer.OrdinalIgnoreCase))
    throw new DlssgProxyCollisionException(injectionDllName, dlssgNames);
```

`GetInstalledProxyNames` must be a static, platform-neutral helper: plain JSON read, no registry.
It returns empty when there's no manifest, so the guard costs nothing on Linux. The
`ManageGameWindow` install path catches the exception type and shows the localised message
(`TxtDlssgSm86CollisionMsg`) in the existing error dialog. Bulk/Quick Install surface it as a
per-game failure through their existing error text. The default injection is `dxgi.dll`, which we
never use, so this only triggers when the user picked version/winmm/dbghelp/dinput8.

### 3.5 INI setter

Add `IniLineEditor.SetValue(path, section, key, value)` / `GetValue` as a small static in the new
service file. It edits one line in place, appends the key to the section if it's missing, and
keeps comments and CRLF. `GameInstallationService` has only a private reader (~l.1410), so don't
reach into it.

### 3.6 Detection (`GameAnalyzerService`)

After the OptiScaler block: resolve the target dir the same way as eligibility, but cheaply. Use
only candidate dirs already computed there (InstallPath, the exe dir, and OptiScaler's
`InstalledGameDirectory`). Load the `::dlssg_sm86` manifest if it's committed, and set
`IsDlssgSm86Installed` / `Version` / `Build`. Don't add a directory scan: the analyzer runs for
every game at startup.

### 3.7 UI (Manage Game window)

XAML: a new `Border Name="PanelDlssgSm86"` row in the Experimental zone's `StackPanel`, below
the existing grids. Same caption + "?" tooltip pattern as `PanelRenodxVersion`. Layout uses the
zone's `ColumnDefinitions="*,*,*"`:
- Col 0: `CmbDlssgSm86Build` (310.9 / 310.1).
- Col 1: `CmbDlssgSm86Multiplier` (2X / 3X / 4X / 6X; 6X hidden on 310.1).
- Col 2: `BtnDlssgSm86Action`. Its label follows the state: Install (size) / Update / Apply /
  Installed. Next to it, `BtnDlssgSm86Uninstall`, visible when installed.
- Below, full width:
  - `TxtDlssgSm86Status`: Installed v0.3.5 (310.9) · `version.dll, winmm.dll, …` · target folder.
  - `TxtDlssgSm86Blocker`: the reason, buttons disabled.
  - `PanelDlssgSm86Hags`: styled like `PanelModdedWarning`, with an "Open graphics settings"
    button → `IShellService.OpenUrl("ms-settings:display-advancedgraphics")`.
  - A one-line multiplier note.

Code-behind partial (`ManageGameWindow.DlssgSm86.cs`):
- `PopulateDlssgSm86Async()`: hide and return if the service is null, Experimental is off, or the
  GPU isn't capable. Otherwise run eligibility + install state + HAGS in `Task.Run` and set the
  controls.
- Click handlers call the service with `Progress<double>` → `BdProgress`. Finish with
  `ShowToastAsync`. Confirm uninstall with `ConfirmDialog`. All strings come from
  `GetResourceString(key, fallback)`.
- Gamepad: add the three or four controls to the hand-written direction map in the main file
  (~l.990–1050). Below `CmbSetupNr`/`CmbDlssNrDanielVersion`, before `BtnUninstall`. That's the
  one unavoidable edit to that hot region; keep it minimal.
- Responsive: check that `ManageGameWindow.Responsive.cs` collapses the zone's 3-column grid at
  narrow widths. If it addresses grids by name, register ours.

HAGS (`IDlssgSm86Service.GetHagsState()` → `On | Off | Unknown`): read
`HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\HwSchMode` (2 = on). `Off` shows the
panel. It never blocks and never writes.

### 3.8 Strings (English is authoritative; ×14, machine-assisted for the others)

About 20 keys, prefix `TxtDlssgSm86`: `Title`, `Tooltip`, `BuildLbl`, `BuildTooltip`,
`MultiplierLbl`, `MultiplierTooltip`, `MultiplierNote`, `Install` (`{0}` = size), `Update`,
`Apply`, `Uninstall`, `StatusInstalled` (`{0}` version, `{1}` build, `{2}` proxies),
`StatusUpdateAvailable`, `Blocker{NoDlssG,NotDx12,AntiCheat,NoFreeProxyName,NoTargetDir}`,
`HagsOff`, `HagsOpenSettings`, `UninstallConfirm`, `IniEditedPrompt`, `DeleteLogsOption`,
`CollisionMsg`, `VerifyFailed`, `ClampedTo4xNotice`, `InstalledToast`, `UninstalledToast`,
`CacheSection`. Write a quick script check that every key exists in all 14 files (the same key set).

## 4. Work breakdown and commits

Product commits keep the PLAN §5 shape, with commit 3 shrunk. Fork commits (`fork:`) stay separate.

| Step | Commit(s) | Content | Check |
|---|---|---|---|
| A | `fork: add dlssg manifest pin script` + `feat: add dlssg_for_sm86 package model and pinned manifest` | Pin script; run it for 0.3.5; `Models/DlssgSm86.cs`; JSON + csproj rule; GPU helpers | build; the JSON lands in `bin/…/assets/configs` |
| B | `feat: download and verify dlssg_for_sm86 builds` | Package service; `StreamToFileAsync` → internal | build; a scratch run downloads 310.9 into the cache; a tampered byte → file deleted + error |
| C | `fix: keep component backups out of the optiscaler reverse lookup` | The `FindBackupDirUnder` slug guard (D2) | build; an existing dlssnr game still resolves correctly |
| D | `feat: install, update and uninstall dlssg_for_sm86` | Service + factory + INI editor + `Game` fields + analyzer + collision guard | build; folder hash before install == after uninstall |
| E | `feat: add dlssg_for_sm86 section to manage game window` | XAML row, partial, HAGS panel, gamepad, strings ×14 | build; manual UI pass; key-parity script |
| F | `feat: show dlssg_for_sm86 in cache management` | Cache section + clear-all | build |
| G | `docs: credit dlssg_for_sm86 in readme` | README | — |
| H | `fork: …` | Manual matrix (PLAN §7) on the 3080 Ti; fixes; HANDOFF | — |
| I | — | `pr/dlssg-sm86` from `upstream/general`, cherry-pick A(product)–G, push to `origin`, `fork/pr/dlssg-sm86.md` | AGENTS.md guard commands |

Dependencies: A → B → D → E/F (E and F can run in parallel), and C is independent. B and C can
run in parallel. The parallelism is small, so one agent doing A→G in order is fine; delegation only
pays for E's 14 translations.

## 5. Risks specific to the implementation

- **New warnings.** `[SupportedOSPlatform]` use without guards triggers CA1416. Call the Windows
  service only through `IDlssgSm86Service?` from the factory. The static
  `GetInstalledProxyNames` must not touch the registry. Also watch for SYSLIB obsoletions in the
  thumbprint API (§3.2).
- **Download size.** About 120 MB per build when all four names are free. The size is shown on the
  button. Only missing files are fetched, and switching builds downloads the other build once.
- **Experimental-zone layout.** The zone was designed for one row of selectors. A second row with
  status text may need responsive handling at narrow widths in 14 languages (German and Russian are
  the longest).
- **Main-file churn.** The touches to `ManageGameWindow.axaml.cs` are: one call in the visibility
  block, the gamepad map, and one `LstComponents` entry. Everything else goes in the partial.
