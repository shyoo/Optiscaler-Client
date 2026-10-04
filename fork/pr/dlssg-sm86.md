# PR draft: dlssg_for_sm86 (DLSS FG on RTX 20/30) as a standalone component

Fork-only. This is the text the user pastes into the upstream PR. It is never opened by an agent.

- Branch: `pr/dlssg-sm86` (on `origin`, cut from `upstream/general`). **Not cut yet:** waiting for
  the manual test pass.
- Base: `Optiscaler-Client:general`
- Title: `feat: dlssg_for_sm86 support (DLSS Frame Generation on RTX 20/30)`

---

Implements the standalone component discussed in #103: [sdli1995/dlssg_for_sm86](https://github.com/sdli1995/dlssg_for_sm86)
enables DLSS Frame Generation on RTX 20/30 (Turing/Ampere) in D3D12 games that already ship
DLSS-G. The nvngx FG-provider integration and auto-selection are left for follow-up PRs, as agreed.

### What it does

- A **"DLSS FG (RTX 20/30)"** card in the Manage Game window's Experimental zone has:
  - Build: 310.9, which allows up to 6X, or 310.1, which allows up to 4X.
  - Max frame generation: 2X / 3X / 4X / 6X.
  - Its own Install / Update / Apply / Uninstall buttons.
  - A status line: where it's installed and under which proxy names, or why it's blocked.
  - A HAGS warning with a shortcut to the graphics settings. It warns only and never changes the
    setting.
- **Visibility:** hidden on Linux, with Experimental Features off, and when the preferred GPU isn't
  RTX 20/30 (new `GpuSelectionHelper.IsTuringRtx` / `IsAmpere`; GTX 16xx excluded). Game-level
  blockers are shown with their reason: anti-cheat, no Streamline DLSS-G, not D3D12, every proxy
  name taken.
- **Proxy names:** every free name of `version`, `winmm`, `dbghelp`, `dinput8` is installed,
  following the mod's own active/standby design. A name is skipped when OptiScaler's record or
  the FSR 4 swap uses it, or when another file holds it (ASI loaders and ReShade are named in the
  message). `dxgi`/`d3d12` are never used.
- **Downloads:** each file comes from upstream at a **pinned commit**
  (`raw.githubusercontent.com/<repo>/<commit>/<path>`) and is never mirrored, since the proxies embed
  NVIDIA's DLSS-G runtime. The pinned manifest (`assets/configs/dlssg_sm86_manifest.json`) records
  each file's size, SHA-256 and the signer thumbprint. Every file is checked before use, cached
  ones included, and deleted on any mismatch. Downloads go through the shared proxy-aware
  `HttpClient` (`ComponentManagementService.StreamToFileAsync`, now `internal`). Upstream publishes
  no releases or hashes, so moving to a new mod version is a deliberate manifest bump.
- **Backups:** the install record goes in the existing backup store under its own key (game root +
  `"::dlssg_sm86"`), the same convention as Setup NR's `"::dlssnr"`. Uninstalling OptiScaler never
  touches it, and the reverse holds too. Files are staged before the game folder is touched, and a
  failed install rolls back. Uninstall removes or restores only files still identical to what was
  installed. A hand-edited `dlssg_sm86.ini` prompts: delete / keep.
- **Update / build switch** carries the user's INI values over. A 6X cap on 310.1 is clamped to 4X
  with a notice.
- **Collision guard:** `InstallOptiScaler` refuses an injection method the mod already uses,
  instead of backing the mod up as a game "original".
- **Small fix:** a new `InstallationManifest.ComponentId` makes `FindBackupDirUnder` skip
  component records, which could otherwise win "first match" over OptiScaler's own.
- **Cache Management:** a page lists cached builds with sizes and lets you delete them.
- **README:** feature line and acknowledgments (sdli1995; Coldwood1026 for the SM75 port). No
  CHANGELOG entry; I left that for you.

### Choices you may want changed

- **No ViewModel / DI.** I followed the existing code-behind pattern: all logic is in
  `DlssgSm86Service` / `DlssgSm86PackageService`. The window part is a thin partial
  (`ManageGameWindow.DlssgSm86.cs`), with four one-line hooks in the main file. The service comes
  from `PlatformServiceFactory.CreateDlssgSm86Service()` (null off Windows). Happy to move it into
  a ViewModel if you want MVVM to start here.
- **No tests in the PR.** There's no test project in the repo. I ran an end-to-end harness against
  fake game folders: eligibility, real pinned downloads and verification, install, build switch,
  byte-identical uninstall, rollback, the collision guard and tamper detection. I'm happy to add
  those as tests if you point me at your test project.
- **Placement:** the Experimental zone, next to RenoDX and Setup NR.
- **About 120 MB per build** when all four names are free; the size is shown on the Install
  button. This could be cut to `version` + `winmm` if you prefer.
- **Translations:** English is authoritative. The other 13 languages are machine-assisted.

### Tested

<!-- fill in from the manual pass (fork task H) -->
- RTX 3080 Ti, Windows 11:
- Builds: Windows and linux-x64, no new warnings.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
