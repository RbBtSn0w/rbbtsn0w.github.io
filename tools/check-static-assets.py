#!/usr/bin/env python3
"""Check that a production build serves theme dependencies from local files."""

import argparse
import re
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit


class Resources(HTMLParser):
    def __init__(self):
        super().__init__()
        self.urls = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "script" and attrs.get("src"):
            self.urls.append(attrs["src"])
        elif tag == "link" and attrs.get("rel") in {"stylesheet", "preload", "modulepreload"}:
            self.urls.append(attrs.get("href", ""))


def check(root):
    errors = set()
    library_files = set()
    pages = list(root.rglob("*.html"))
    if not pages:
        errors.add("No generated HTML found")
    for page in pages:
        parser = Resources()
        parser.feed(page.read_text(encoding="utf-8"))
        for url in parser.urls:
            parsed = urlsplit(url)
            if parsed.hostname in {"cdn.jsdelivr.net", "fonts.googleapis.com", "fonts.gstatic.com"}:
                errors.add(f"External theme dependency: {url}")
            if not parsed.netloc and parsed.path.startswith("/assets/lib/"):
                library_files.add(root / unquote(parsed.path).lstrip("/"))

    # Follow CSS fonts/images/imports as well as top-level HTML references.
    pending = list(library_files)
    visited = set()
    while pending:
        path = pending.pop()
        if path in visited:
            continue
        visited.add(path)
        if not path.is_file():
            errors.add(f"Missing asset: {path.relative_to(root)}")
            continue
        if path.suffix != ".css":
            continue
        css = path.read_text(encoding="utf-8")
        for match in re.finditer(r"url\(\s*['\"]?([^)'\"\s]+)", css):
            url = match.group(1)
            parsed = urlsplit(url)
            if parsed.scheme == "data" or url.startswith("#"):
                continue
            if parsed.netloc or parsed.scheme:
                errors.add(f"External CSS resource: {url}")
                continue
            asset = (root / parsed.path.lstrip("/")) if parsed.path.startswith("/") else path.parent / parsed.path
            pending.append(asset.resolve())
    for error in sorted(errors):
        print(f"FAIL: {error}")
    if not errors:
        print(f"PASS: {len(pages)} pages; {len(library_files)} direct library assets; {len(visited)} assets including CSS dependencies")
    return bool(errors)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("site", nargs="?", default="_site")
    args = parser.parse_args()
    raise SystemExit(check(Path(args.site).resolve()))
