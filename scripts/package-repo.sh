#!/usr/bin/env bash
# Packages repository.8nime zip and regenerates addons.xml.md5.
# Run this locally after editing addons.xml, then commit and push.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_DIR="$ROOT/repo"
ZIPS_DIR="$REPO_DIR/zips"
VERSION="1.0.0"

REPO_ZIP_DIR="$ZIPS_DIR/repository.8nime"
mkdir -p "$REPO_ZIP_DIR"

REPO_ADDON_DIR="$ROOT/.tmp/repository.8nime"
rm -rf "$REPO_ADDON_DIR"
mkdir -p "$REPO_ADDON_DIR"

cat > "$REPO_ADDON_DIR/addon.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<addon id="repository.8nime" name="8nime Repository" version="1.0.0" provider-name="8nime">
  <extension point="xbmc.addon.repository" name="8nime Repository">
    <dir>
      <info compressed="false">https://8nime.github.io/8nime-repo/repo/addons.xml</info>
      <checksum>https://8nime.github.io/8nime-repo/repo/addons.xml.md5</checksum>
      <datadir zip="true">https://github.com/8nime/8nime-repo/releases/download/</datadir>
    </dir>
  </extension>
  <extension point="xbmc.addon.metadata">
    <summary lang="en">Repository for 8nime Kodi builds and wizard</summary>
    <description lang="en">Hosts 8nimeWizard and 8nime build packages.</description>
    <platform>all</platform>
  </extension>
</addon>
EOF

cd "$ROOT/.tmp"
if command -v zip &>/dev/null; then
  zip -r "$REPO_ZIP_DIR/repository.8nime-${VERSION}.zip" repository.8nime
else
  python3 - "$REPO_ZIP_DIR/repository.8nime-${VERSION}.zip" repository.8nime <<'PY'
import sys, zipfile, os
out, src = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(src):
        for f in files:
            path = os.path.join(root, f)
            zf.write(path, path)
PY
fi
rm -rf "$REPO_ADDON_DIR"

if command -v md5sum &>/dev/null; then
  md5sum "$REPO_DIR/addons.xml" | awk '{print $1}' > "$REPO_DIR/addons.xml.md5"
elif command -v md5 &>/dev/null; then
  md5 -q "$REPO_DIR/addons.xml" > "$REPO_DIR/addons.xml.md5"
fi

echo "Done. Commit repo/addons.xml, repo/addons.xml.md5, hosted/, and push to serve via GitHub Pages."
