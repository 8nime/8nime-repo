#!/usr/bin/env python3
"""Regenerate one addon's <addon> entry in the served addons.xml from the real
addon.xml that shipped inside the released zip.

This keeps the Kodi repository index (addons.xml) a faithful copy of each
addon's actual manifest -- version, <requires>, extension points and metadata --
instead of hand-patching only the version number (which silently drifts).

Usage:
    regen-addons-xml.py <addon_id> <real_addon_xml> <served_addons_xml>

The repository.8nime entry (and any other addon not being released) is left
untouched: only the block whose id matches <addon_id> is replaced. If the addon
is not yet present it is inserted just before </addons>.
"""
from __future__ import annotations

import re
import sys


def main() -> int:
    if len(sys.argv) != 4:
        sys.stderr.write(__doc__ or "")
        return 2

    addon_id, real_path, served_path = sys.argv[1], sys.argv[2], sys.argv[3]

    with open(real_path, encoding="utf-8") as fh:
        real = fh.read()
    # Drop the <?xml ...?> declaration; we only want the <addon> element.
    real = re.sub(r"<\?xml[^>]*\?>\s*", "", real).strip()

    # Re-indent the block by two spaces so it nests cleanly inside <addons>.
    block = "\n".join(
        ("  " + line if line.strip() else line) for line in real.splitlines()
    )

    with open(served_path, encoding="utf-8") as fh:
        content = fh.read()

    # Match the existing <addon id="<addon_id>" ...> ... </addon> block, including
    # any leading indentation, non-greedily up to its closing tag.
    pattern = re.compile(
        r'[ \t]*<addon id="%s".*?</addon>' % re.escape(addon_id),
        re.DOTALL,
    )

    if pattern.search(content):
        content = pattern.sub(lambda _m: block, content, count=1)
    else:
        content = content.replace("</addons>", block + "\n</addons>", 1)

    with open(served_path, "w", encoding="utf-8") as fh:
        fh.write(content)

    print("regenerated addons.xml entry for %s" % addon_id)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
