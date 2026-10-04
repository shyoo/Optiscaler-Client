# PR draft: dlssg_for_sm86 (DLSS FG on RTX 20/30) as a standalone component

Fork-only. This is the text the user pastes into the upstream PR. It is never opened by an agent.

- Branch: `pr/dlssg-sm86` on `origin` (shyoo/Optiscaler-Client), cut from `upstream/general` @
  `f73cf2c`. Opened by the user as **#117** on 2026-10-03.
  - `b0a7d18`: the original feature, one squashed commit at the user's request.
  - `ca1145b` (pushed 2026-10-04): the maintainer's review (main install buttons, None, badge
    colour, no status line). A new commit, because the PR is open: no force-push.
- PR: https://github.com/Optiscaler-Client/Optiscaler-Client/pull/117. The user edits its
  description and posts the reply below; agents never write on upstream.
- Base: `Optiscaler-Client:general`
- Title: `feat: dlssg_for_sm86 support (DLSS Frame Generation on RTX 20/30)`

---

Implements the standalone component discussed in #103: [sdli1995/dlssg_for_sm86](https://github.com/sdli1995/dlssg_for_sm86)
enables DLSS Frame Generation on RTX 20/30 (Turing/Ampere) in D3D12 games that already ship
DLSS-G. The nvngx FG-provider integration and auto-selection are left for follow-up PRs, as agreed.

### What it does

- A **"DLSS FG (RTX 20/30)"** section in the Manage Game window's Experimental zone has:
  - Build: **None** (the default), 310.9, which allows up to 6X, or 310.1, which allows up to 4X.
  - Max frame generation: 2X / 3X / 4X / 6X.
  - A box with the reason when the game is blocked, and one when a newer pinned version is
    available. No paths are shown; the Detected Components badge shows what's installed.
  - A HAGS warning with a shortcut to the graphics settings. It warns only and never changes the
    setting.
- **Install / uninstall through the main buttons**, like the other components and the FSR 4 swap:
  - Auto/Manual Install installs DLSS FG together with OptiScaler and the FSR 4 swap, into the
    folder OptiScaler goes into. With OptiScaler and FSR 4 both at None, it installs DLSS FG on its
    own. Manual Install then asks for the game's exe.
  - With DLSS FG installed, changing only the multiplier rewrites `MaxGeneratedFrames`; another
    runtime or a newer pinned version reinstalls it.
  - Setting DLSS FG to None works like the FSR 4 swap at None: an OptiScaler (re)install removes
    it (before OptiScaler goes in, so OptiScaler can take its proxy name); otherwise the install
    buttons leave it alone.
  - The main Uninstall removes DLSS FG too, and appears when DLSS FG is the only thing installed.
  - "Update config only" isn't offered while a DLSS FG change is pending, since it wouldn't apply it.
- **Detected Components:** the "DLSS FG for RTX 20/30" badge has its own colour (blue, `AddedMod`),
  next to ViaOptiscaler (purple) and Swapped (amber), since it doesn't ship with the game.
- **Visibility:** hidden on Linux, with Experimental Features off, and when the preferred GPU isn't
  RTX 20/30 (new `GpuSelectionHelper.IsTuringRtx` / `IsAmpere`; GTX 16xx excluded). Game-level
  blockers are shown with their reason: anti-cheat, no Streamline DLSS-G, not D3D12, every proxy
  name taken.
- **Proxy names:** every free name of `version`, `winmm`, `dbghelp`, `dinput8` is installed,
  following the mod's own active/standby design. A name is skipped when OptiScaler's record or
  the FSR 4 swap uses it, or when another file holds it (ASI loaders and ReShade are named in the
  message). `dxgi`/`d3d12` are never used.
- **Manual installs:** many people already copied the mod in by hand, often an older version. That
  copy is recognised under any proxy name: every dlssg_for_sm86 proxy, 0.2.x included, carries the
  UTF-16 name of its INI. The section then says *"dlssg_for_sm86 (manual install) is already in this
  folder: version.dll, dlssg_sm86.ini. Remove those files first"*, rather than installing next to
  it and mixing two builds in one process.
- **Downloads:** each file comes from upstream at a **pinned commit**
  (`raw.githubusercontent.com/<repo>/<commit>/<path>`) and is never mirrored, since the proxies embed
  NVIDIA's DLSS-G runtime. The pinned manifest (`assets/configs/dlssg_sm86_manifest.json`) records
  each file's size, SHA-256 and the signer thumbprint. Every file is checked before use, cached
  ones included, and deleted on any mismatch. Downloads go through the shared proxy-aware
  `HttpClient` (`ComponentManagementService.StreamToFileAsync`, now `internal`). Upstream publishes
  no releases or hashes, so moving to a new mod version is a deliberate manifest bump.
- **Backups:** the install record goes in the existing backup store under its own key (game root +
  `"::dlssg_sm86"`), the same convention as Setup NR's `"::dlssnr"`. `UninstallOptiScaler` never
  touches it; the main Uninstall removes DLSS FG through its own record first. Files are staged before the game folder is touched, and a
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

### Structure

- **Logic in services, none in the view.** `DlssgSm86PackageService` (pinned manifest, download,
  verification, cache) and `DlssgSm86Service` (Windows-only: eligibility, install / update /
  uninstall, INI, HAGS) do all the work. The service also decides what the next install does with
  DLSS FG for the current selection (`GetPendingAction`: Install / Update / Apply / Remove /
  nothing), so the window only runs that plan.
- **The window part** is its own partial, `ManageGameWindow.DlssgSm86.cs`. The main file only has
  short hooks: in `ExecuteInstallAsync`, the uninstall confirmation, `UpdateStatus`, the
  install-button state, "Update config only" eligibility, and the badge's `IsAddedMod` flag.
- **Platform split:** the service comes from `PlatformServiceFactory.CreateDlssgSm86Service()`,
  which returns null off Windows, as the GPU and gamepad services do. `DlssgSm86Records` holds the
  platform-neutral lookup that the analyzer and OptiScaler's collision guard use.

### Choices you may want changed

- **Placement:** the Experimental zone, next to RenoDX and Setup NR.
- **About 120 MB per build** when all four names are free. This could be cut to `version` +
  `winmm` if you prefer.
- **Manual Install with the FSR 4 swap and DLSS FG** (OptiScaler at None) asks twice: the DLL to
  replace, then the game's exe.
- **Translations:** English is authoritative. The other 13 languages are machine-assisted.

### Tested

By hand on an **RTX 3080 Ti, Windows 11**, with **Final Fantasy XVI** (Streamline DLSS-G).

With the main install buttons (after the review):
- DLSS FG alone (OptiScaler and FSR 4 at None): Auto Install installs it, the blue badge appears,
  and DLSS Frame Generation is available in game.
- Setting DLSS FG to None with nothing else selected changes nothing: the install buttons are
  disabled, the files stay, and frame generation still works in game.
- Uninstall with only DLSS FG installed removes it, and frame generation is unavailable in game
  again.
- With OptiScaler and DLSS FG installed, DLSS FG at None plus "Auto Update / Reinstall" removes
  DLSS FG and keeps OptiScaler.

From the first version (same backend):
- Install of runtime 310.9: the mod went in as `version.dll`, `winmm.dll`, `dbghelp.dll` and
  `dinput8.dll` plus the INI. Frame generation works in game at 2X, which is the cap of FF16's
  own Streamline plugin.
- Changing only the multiplier rewrites only `MaxGeneratedFrames`. Switching 310.9 → 310.1 keeps
  the user's INI values.
- Uninstall with a hand-edited INI asks first (Delete / Keep). Afterwards the game folder is
  byte-identical to before the install (SHA-256 of every top-level file).
- OptiScaler with injection `winmm.dll` is refused with an error naming the mod's proxy names, and
  nothing is written. OptiScaler 0.9.4 via `dxgi.dll` (FG disabled) installs next to the mod, and
  both work in game.
- A copy of the mod placed by hand (an older 0.2.4 `version.dll`) blocks the install with the
  manual-install message, and nothing is written.
- The Cache Management page lists and deletes cached builds.

Builds: Windows and linux-x64, no new warnings.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## Reply to the review comment (for the user to post on #117)

Thanks for the review! All four points are in `ca1145b`:

1. DLSS FG now goes through the main Auto/Manual Install and Uninstall buttons. It installs with
   OptiScaler and the FSR 4 swap when they're selected, into the same folder, or on its own when
   both are None (Manual Install then asks for the game's exe). The main Uninstall removes all of
   them.
5. The selector has a "None" entry, which is the default. It behaves like the FSR 4 swap at None:
   an OptiScaler reinstall removes DLSS FG; otherwise the install buttons leave it alone.
7. The badge has its own colour (blue, an `AddedMod` class next to `ViaOptiscaler` / `Swapped`).
9. I dropped the status line. Only the reason a game is blocked and "update available" remain, as
   info boxes like the FSR 4 hint, without paths.

I updated the description, including what I re-tested on FF16 with the new flow.
