# dlssg_for_sm86 service harness

Fork-only scratch harness that drives `IDlssgSm86Service` end to end against fake game folders:
- eligibility rules;
- real downloads from the pinned commit, verified;
- install, multiplier change, build switch with INI carry-over and 6X→4X clamp;
- uninstall back to a byte-identical folder;
- keeping an edited INI on request;
- rollback of a failed install;
- the OptiScaler collision guard;
- tampered-cache re-download;
- cache listing.

The files are stored as `.txt` because the root csproj compiles every `**/*.cs` under the repo.
Run the harness from a folder **outside** the repository:

```sh
H="$LOCALAPPDATA/Temp/dlssg-harness"; mkdir -p "$H"
cp fork/tools/dlssg-harness/Program.cs.txt "$H/Program.cs"
sed "s#REPO#$(pwd -W)#" fork/tools/dlssg-harness/Harness.csproj.txt > "$H/Harness.csproj"
(cd "$H" && dotnet build -c Debug) && "$H/bin/Debug/net10.0/win-x64/Optiscaler-Client.Tests.exe"
```

The assembly name `Optiscaler-Client.Tests` matches the app's `InternalsVisibleTo`. The harness
sets `OPTISCALER_CLIENT_APPDATA` to a temp folder, so it never touches the real backups, cache or
config. The first run downloads both builds, about 200 MB.
