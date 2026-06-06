#!/usr/bin/env bash
# Rebuilds repository.8nime-<version>.zip and regenerates repo/addons.xml.md5.
#
# Architecture (see repo README / project memory):
#   * The repo INDEX (addons.xml + addons.xml.md5) is served from
#     https://raw.githubusercontent.com/8nime/8nime-repo/main/repo/  — NOT GitHub
#     Pages: Pages gzips the XML and Kodi's HTTP/2 fetch stalls (freeze).
#   * The per-addon zips live on GitHub Releases (the <datadir>).
#   * The repository.8nime install zip is browsable for "install from zip" via
#     GitHub Pages (8nime.github.io), where binary zips download fine.
#
# Run locally after editing repo/addons.xml, then deploy (see final notes).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_DIR="$ROOT/repo"
VERSION="1.0.0"
RAW="https://raw.githubusercontent.com/8nime/8nime-repo/main/repo"

STAGE="$ROOT/.tmp/repository.8nime"
rm -rf "$ROOT/.tmp"
mkdir -p "$STAGE"

cat > "$STAGE/addon.xml" << EOF
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<addon id="repository.8nime" name="8nime Repository" version="${VERSION}" provider-name="8nime">
  <extension point="xbmc.addon.repository" name="8nime Repository">
    <dir>
      <info compressed="false">${RAW}/addons.xml</info>
      <checksum>${RAW}/addons.xml.md5</checksum>
      <datadir zip="true">https://github.com/8nime/8nime-repo/releases/download/</datadir>
    </dir>
  </extension>
  <extension point="xbmc.addon.metadata">
    <summary lang="en">8nime Repository</summary>
    <description lang="en">Hosts 8nime Wizard and the 8nime build with Bingie skin, Otaku, WatchNixtoons2, and Fanime F.</description>
    <platform>all</platform>
    <assets>
      <icon>icon.png</icon>
    </assets>
  </extension>
</addon>
EOF

cp "$REPO_DIR/icon.png" "$STAGE/icon.png"

OUT="$REPO_DIR/repository.8nime-${VERSION}.zip"
rm -f "$OUT"
cd "$ROOT/.tmp"
if command -v zip &>/dev/null; then
  zip -r "$OUT" repository.8nime
else
  python3 - "$OUT" repository.8nime <<'PY'
import sys, zipfile, os
out, src = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, _, files in os.walk(src):
        for f in files:
            path = os.path.join(root, f)
            zf.write(path, path)
PY
fi
rm -rf "$ROOT/.tmp"

# Regenerate the index checksum (bare 32-char hex; Kodi truncates at first space/newline)
if command -v md5sum &>/dev/null; then
  md5sum "$REPO_DIR/addons.xml" | awk '{print $1}' > "$REPO_DIR/addons.xml.md5"
else
  md5 -q "$REPO_DIR/addons.xml" > "$REPO_DIR/addons.xml.md5"
fi

cat << EOF
Done.

Built : $OUT
Index : $REPO_DIR/addons.xml (+ .md5 regenerated)

Deploy:
  1. Commit & push repo/addons.xml, repo/addons.xml.md5, repo/icon.png,
     repo/repository.8nime-${VERSION}.zip to 8nime-repo (raw serves the index).
  2. Copy repository.8nime-${VERSION}.zip into the 8nime.github.io repo root
     (served for "install from zip") and push.
  3. Upload repository.8nime-${VERSION}.zip to the 'repository.8nime' GitHub
     Release on 8nime-repo (the <datadir> self-reference):
       gh release upload repository.8nime "$OUT" --repo 8nime/8nime-repo --clobber

Note: per-addon (wizard / bingie-helper) index entries are regenerated
automatically by .github/workflows/update-metadata.yml on each addon release;
this script only rebuilds the repository.8nime addon itself.
EOF
