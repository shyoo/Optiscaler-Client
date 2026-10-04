#!/usr/bin/env bash
# Fork-only dev script: pins a dlssg_for_sm86 tag into assets/configs/dlssg_sm86_manifest.json.
#
# Resolves <tag> to its commit, checks every file the client installs exists in that commit's
# tree, downloads each one once to a temp dir, and records size, SHA-256 and git blob SHA. Proxy
# DLLs must carry the pinned self-signed signer thumbprint (Get-AuthenticodeSignature reports
# Status=UnknownError for this cert; that is expected, only the thumbprint is compared).
# Nothing it downloads is kept or committed — only the JSON it writes goes upstream.
#
# Needs: gh (authenticated), curl, sha256sum, git, powershell (Windows) or pwsh.
# Usage: fork/tools/pin-dlssg-manifest.sh 0.3.5 [output.json]
set -euo pipefail

REPO="sdli1995/dlssg_for_sm86"
SIGNER_THUMBPRINT="85BA66762F851E49148D706915D09026281418E6"
TAG="${1:?usage: $0 <tag> [output.json]}"
OUT="${2:-$(git rev-parse --show-toplevel)/assets/configs/dlssg_sm86_manifest.json}"

# build id | max MaxGeneratedFrames | "name=path" ... (the INI is shared: 310.1/ ships none)
BUILDS=(
  "310.9|5|version.dll=version.dll winmm.dll=alternatives/winmm.dll dbghelp.dll=alternatives/dbghelp.dll dinput8.dll=alternatives/dinput8.dll dlssg_sm86.ini=dlssg_sm86.ini"
  "310.1|3|version.dll=310.1/version.dll winmm.dll=310.1/alternatives/winmm.dll dbghelp.dll=310.1/alternatives/dbghelp.dll dinput8.dll=310.1/alternatives/dinput8.dll dlssg_sm86.ini=dlssg_sm86.ini"
)

PS=powershell; command -v "$PS" >/dev/null || PS=pwsh

# ── tag → commit (dereference annotated tags) ───────────────────────────────
read -r ref_type ref_sha < <(gh api "repos/$REPO/git/ref/tags/$TAG" --jq '.object.type + " " + .object.sha')
if [ "$ref_type" = "tag" ]; then
  ref_sha=$(gh api "repos/$REPO/git/tags/$ref_sha" --jq '.object.sha')
fi
COMMIT="$ref_sha"
echo "tag $TAG -> commit $COMMIT" >&2

TREE=$(gh api "repos/$REPO/git/trees/$COMMIT?recursive=1" --jq '.tree[] | select(.type=="blob") | "\(.path)\t\(.size)\t\(.sha)"')

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

json_builds=""
for spec in "${BUILDS[@]}"; do
  IFS='|' read -r build_id max_frames files <<<"$spec"
  json_files=""
  for pair in $files; do
    name="${pair%%=*}"; path="${pair#*=}"
    line=$(printf '%s\n' "$TREE" | awk -F'\t' -v p="$path" '$1==p {print; exit}')
    [ -n "$line" ] || { echo "missing in tree: $path" >&2; exit 1; }
    size=$(cut -f2 <<<"$line"); blob=$(cut -f3 <<<"$line")

    local_file="$TMP/${path//\//_}"
    if [ ! -f "$local_file" ]; then
      echo "downloading $path ($size bytes)" >&2
      curl -fsSL --retry 3 -o "$local_file" "https://raw.githubusercontent.com/$REPO/$COMMIT/$path"
    fi
    actual_size=$(stat -c %s "$local_file")
    [ "$actual_size" = "$size" ] || { echo "size mismatch for $path: $actual_size != $size" >&2; exit 1; }
    actual_blob=$(git hash-object "$local_file")
    [ "$actual_blob" = "$blob" ] || { echo "blob mismatch for $path" >&2; exit 1; }
    sha=$(sha256sum "$local_file" | cut -d' ' -f1 | tr 'a-f' 'A-F')

    role=ini
    if [[ "$name" == *.dll ]]; then
      role=proxy
      win_path=$(cygpath -w "$local_file" 2>/dev/null || echo "$local_file")
      thumb=$("$PS" -NoProfile -Command "(Get-AuthenticodeSignature -LiteralPath '$win_path').SignerCertificate.Thumbprint" | tr -d '\r')
      [ "$thumb" = "$SIGNER_THUMBPRINT" ] || { echo "signer mismatch for $path: '$thumb'" >&2; exit 1; }
    fi

    [ -n "$json_files" ] && json_files+=","
    json_files+=$(printf '\n        { "name": "%s", "path": "%s", "role": "%s", "size": %s, "sha256": "%s", "gitBlobSha": "%s" }' \
      "$name" "$path" "$role" "$size" "$sha" "$blob")
  done
  [ -n "$json_builds" ] && json_builds+=","
  json_builds+=$(printf '\n    {\n      "id": "%s",\n      "maxGeneratedFrames": %s,\n      "files": [%s\n      ]\n    }' \
    "$build_id" "$max_frames" "$json_files")
done

cat >"$OUT" <<JSON
{
  "modVersion": "$TAG",
  "repo": "$REPO",
  "commit": "$COMMIT",
  "signerThumbprint": "$SIGNER_THUMBPRINT",
  "builds": [$json_builds
  ]
}
JSON
echo "wrote $OUT" >&2
