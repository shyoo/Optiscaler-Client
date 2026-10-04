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
- Title: `feat: add dlssg_for_sm86 support (DLSS Frame Generation on RTX 20/30)`
- The description below is what the user posted on #117, with the review's changes edited in as
  small as possible (the user's request). Paste it over the current description.

---

Adds sdli1995/dlssg_for_sm86 as a standalone component, as agreed in #103. It enables DLSS Frame Generation on RTX 20/30 (Turing/Ampere) in D3D12 games that already ship Streamline DLSS-G. It works with or without OptiScaler, and is installed and uninstalled through the main buttons, like the FSR 4 swap.

Do note that it is currently enabled under `experimental`. Once stabilized, it can be promoted to regular FG options. I have manually tested installation / update / removal and in-game play, and it worked correctly.

Download and verification
- The mod publishes no releases or hashes. The pinned manifest (assets/configs/dlssg_sm86_manifest.json) fixes mod 0.3.5 at its commit, for both runtimes: 310.9, up to 6X, and 310.1, up to 4X.
- Files are fetched from upstream at that commit and never mirrored, since the proxies embed NVIDIA's DLSS-G runtime. Downloads go through the shared proxy-aware HttpClient (StreamToFileAsync, now internal).
- Each file must match its pinned size, SHA-256 and signer thumbprint before use, cached files included. A mismatch deletes the file. The mod is self-signed, so the signer is compared by thumbprint.

Install, update, uninstall (DlssgSm86Service, Windows only)
- Eligibility: a preferred GPU that is RTX 20/30 (new GpuSelectionHelper.IsTuringRtx / IsAmpere), no anti-cheat, Streamline DLSS-G present, and at least one free proxy name next to the rendering executable.
- Every free name of version/winmm/dbghelp/dinput8 is installed, per the mod's active/standby design. A name is skipped when OptiScaler, the FSR 4 swap, an ASI loader, ReShade or another file holds it. dxgi/d3d12 are never used.
- A copy of the mod placed by hand (any version, any proxy name) is recognised and must be removed first, so two builds never share a process.
- The install record lives in the backup store under its own key (game root + "::dlssg_sm86", like Setup NR's "::dlssnr"). UninstallOptiScaler never touches it, and the reverse also holds. A new InstallationManifest.ComponentId keeps such records out of FindBackupDirUnder.
- Files are staged before the game folder changes, and a failed install rolls back. Update / build switch carries the user's INI values over (6X is clamped to 4X on 310.1). Uninstall removes or restores only files still identical to what was installed, and asks before deleting a hand-edited INI.
- InstallOptiScaler refuses an injection method the mod already uses.

UI
- A "DLSS FG (RTX 20/30)" section in the Manage Game window's Experimental zone has Build (None by default), Max frame generation, and a HAGS warning that links to the graphics settings. The setting is never changed for the user. The main Auto/Manual Install installs it with OptiScaler and the FSR 4 swap, or on its own when both are None, and the main Uninstall removes it too. None works like the FSR 4 swap at None. A blocked game shows the reason in an info box. It uses the existing styles and controls, the progress overlay, toasts and dialogs, and has gamepad support.
- The section is hidden, never shown disabled, on Linux, with Experimental Features off, and on GPUs other than RTX 20/30. The code lives in ManageGameWindow.DlssgSm86.cs, with small hooks in the main file. The service decides what an install does with it (GetPendingAction); the window only runs that.
- Its Detected Components badge has its own colour, as the OptiScaler and FSR 4 swap badges do.
- The Cache Management page lists and deletes cached builds.
- 45 new strings in all 14 language files. English is authoritative; the others are machine-assisted.
- README feature line and acknowledgments (sdli1995; Coldwood1026 for the SM75 port).

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
