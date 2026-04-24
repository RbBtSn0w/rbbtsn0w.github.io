#!/usr/bin/env python3
"""Validate a Jekyll/Chirpy post before publication."""

from __future__ import annotations

import argparse
import re
import sys
from html.parser import HTMLParser
from pathlib import Path

try:
    import yaml  # PyYAML — preferred for robust frontmatter parsing

    _HAS_YAML = True
except ImportError:
    _HAS_YAML = False


POST_RE = re.compile(r"^_posts/(\d{4}-\d{2}-\d{2})-(.+)\.md$")
FRONTMATTER_RE = re.compile(r"^([A-Za-z0-9_-]+):\s*(.*)$")
NESTED_RE = re.compile(r"^\s+([A-Za-z0-9_-]+):\s*(.*)$")
MARKDOWN_LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
MERMAID_RE = re.compile(r"(?im)^```mermaid\b|{%-?\s*mermaid\b")
FENCE_START_RE = re.compile(r"^( {0,3})(`{3,}|~{3,})")
MARKDOWN_H1_RE = re.compile(r"^ {0,3}#\s+\S")


class RenderedPageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.in_title = False
        self.title_parts: list[str] = []
        self.h1_count = 0
        self.meta: dict[str, str] = {}
        self.link: dict[str, str] = {}

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attr = {key.lower(): value or "" for key, value in attrs}
        if tag.lower() == "title":
            self.in_title = True
        elif tag.lower() == "h1":
            self.h1_count += 1
        elif tag.lower() == "meta":
            key = attr.get("name") or attr.get("property")
            if key:
                self.meta[key.lower()] = attr.get("content", "")
        elif tag.lower() == "link":
            rel = attr.get("rel", "")
            if rel:
                self.link[rel.lower()] = attr.get("href", "")

    def handle_endtag(self, tag: str) -> None:
        if tag.lower() == "title":
            self.in_title = False

    def handle_data(self, data: str) -> None:
        if self.in_title:
            self.title_parts.append(data)

    @property
    def title(self) -> str:
        return "".join(self.title_parts).strip()


class RepoRootNotFoundError(RuntimeError):
    """Raised when the Jekyll repo root cannot be located."""


def find_repo_root(start: Path) -> Path:
    for candidate in [start, *start.parents]:
        if (candidate / "_config.yml").exists() and (candidate / "_posts").is_dir():
            return candidate
    raise RepoRootNotFoundError(
        "Could not find repo root with _config.yml and _posts/."
    )


def clean_value(value: str) -> str:
    value = value.strip()
    if (value.startswith('"') and value.endswith('"')) or (
        value.startswith("'") and value.endswith("'")
    ):
        return value[1:-1]
    return value


def _flatten_yaml(data: dict, prefix: str = "") -> dict[str, str]:
    """Flatten a parsed YAML dict into dot-separated string values.

    Lists are joined with ``, ``; nested dicts use dot-notation keys.
    This gives downstream checks a uniform ``dict[str, str]`` interface
    regardless of whether the value was a scalar, list, or mapping.
    """
    flat: dict[str, str] = {}
    for key, value in data.items():
        full_key = f"{prefix}.{key}" if prefix else str(key)
        if isinstance(value, dict):
            flat.update(_flatten_yaml(value, full_key))
        elif isinstance(value, list):
            flat[full_key] = ", ".join(str(item) for item in value)
        elif value is None:
            flat[full_key] = ""
        else:
            flat[full_key] = str(value)
    return flat


def _split_raw_frontmatter(text: str) -> tuple[str | None, int | None, str, list[str]]:
    """Extract the raw YAML string and body from a Jekyll post.

    Returns (yaml_text, end_index, body, errors).  *yaml_text* is ``None``
    when no valid frontmatter delimiters are found.
    """
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None, None, text, ["Missing YAML frontmatter block."]

    end_index = None
    for index, line in enumerate(lines[1:], start=1):
        if line.strip() == "---":
            end_index = index
            break
    if end_index is None:
        return None, None, text, ["Frontmatter block is not closed with ---."]

    yaml_text = "\n".join(lines[1:end_index])
    body = "\n".join(lines[end_index + 1 :])
    return yaml_text, end_index, body, []


def _parse_frontmatter_regex(yaml_text: str) -> dict[str, str]:
    """Regex-based fallback when PyYAML is not installed."""
    data: dict[str, str] = {}
    current_key: str | None = None
    for raw_line in yaml_text.splitlines():
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue
        top_match = FRONTMATTER_RE.match(raw_line)
        if top_match and not raw_line.startswith((" ", "\t")):
            current_key = top_match.group(1)
            data[current_key] = clean_value(top_match.group(2))
            continue
        nested_match = NESTED_RE.match(raw_line)
        if nested_match and current_key:
            data[f"{current_key}.{nested_match.group(1)}"] = clean_value(
                nested_match.group(2)
            )
    return data


def split_frontmatter(text: str) -> tuple[dict[str, str], str, list[str]]:
    """Parse Jekyll frontmatter into a flat ``dict[str, str]``.

    Uses ``yaml.safe_load`` when PyYAML is available, falling back to a
    regex-based parser that handles simple ``key: value`` pairs and one
    level of nesting.
    """
    yaml_text, _end_index, body, errors = _split_raw_frontmatter(text)
    if yaml_text is None:
        return {}, body, errors

    if _HAS_YAML:
        try:
            parsed = yaml.safe_load(yaml_text)
            if not isinstance(parsed, dict):
                return {}, body, ["Frontmatter did not parse as a YAML mapping."]
            return _flatten_yaml(parsed), body, errors
        except yaml.YAMLError as exc:
            errors.append(f"YAML parse error: {exc}")
            return {}, body, errors
    else:
        return _parse_frontmatter_regex(yaml_text), body, errors


def site_path_for_url(repo_root: Path, url: str) -> Path:
    clean_url = url.split("#", 1)[0].split("?", 1)[0]
    relative = clean_url.lstrip("/")
    if clean_url.endswith("/"):
        return repo_root / "_site" / relative / "index.html"
    return repo_root / "_site" / relative


DRAFT_MARKER_RE = re.compile(r"\b(TODO|TBD|FIXME)\b")


def extract_markdown_links(body: str) -> list[str]:
    links: list[str] = []
    for match in MARKDOWN_LINK_RE.finditer(body):
        target = match.group(1).strip()
        if target.startswith(("http://", "https://", "mailto:", "#")):
            continue
        links.append(target)
    return links


def _iter_prose_lines(body: str):
    """Yield lines that are outside fenced code blocks and indented code.

    An unclosed fence causes the rest of the document to be treated as code,
    matching CommonMark semantics — subsequent lines are intentionally skipped.
    """
    fence_marker: str | None = None
    for line in body.splitlines():
        if fence_marker:
            fence_match = FENCE_START_RE.match(line)
            if (
                fence_match
                and fence_match.group(2)[0] == fence_marker[0]
                and len(fence_match.group(2)) >= len(fence_marker)
            ):
                fence_marker = None
            continue

        fence_match = FENCE_START_RE.match(line)
        if fence_match:
            fence_marker = fence_match.group(2)
            continue

        if line.startswith(("    ", "\t")):
            continue

        yield line


def markdown_body_has_h1(body: str) -> bool:
    """Return True if *body* contains a Markdown ATX H1 outside code blocks."""
    return any(MARKDOWN_H1_RE.match(line) for line in _iter_prose_lines(body))


def _body_has_draft_markers(body: str) -> bool:
    """Return True if prose lines contain TODO/TBD/FIXME markers.

    Code blocks are excluded so that illustrative examples containing
    these markers (e.g., ``// TODO: refactor``) do not trigger false positives.
    """
    return any(DRAFT_MARKER_RE.search(line) for line in _iter_prose_lines(body))


def validate(post_arg: str) -> int:
    repo_root = find_repo_root(Path.cwd().resolve())
    post_path = Path(post_arg).expanduser()
    if not post_path.is_absolute():
        post_path = repo_root / post_path
    post_path = post_path.resolve()

    errors: list[str] = []
    warnings: list[str] = []

    if not post_path.exists():
        print(f"FAIL: {post_arg} does not exist.")
        return 1

    try:
        relative_post = post_path.relative_to(repo_root).as_posix()
    except ValueError:
        print(f"FAIL: {post_arg} is outside the repository root.")
        return 1

    match = POST_RE.match(relative_post)
    filename_date = ""
    slug = ""
    expected_url = ""
    if not match:
        errors.append("Post path must match _posts/YYYY-MM-DD-<slug>.md.")
    else:
        filename_date = match.group(1)
        slug = match.group(2)
        expected_url = f"/posts/{slug}/"
        if "_" in slug:
            warnings.append("Slug contains underscores; prefer hyphen-separated words.")
        if slug.lower() != slug:
            warnings.append("Slug contains uppercase letters; prefer lowercase slugs.")

    text = post_path.read_text(encoding="utf-8")
    frontmatter, body, fm_errors = split_frontmatter(text)
    errors.extend(fm_errors)

    required_fields = ["title", "date", "description", "categories", "tags"]
    for field in required_fields:
        value = frontmatter.get(field, "").strip()
        # Under yaml.safe_load an empty list becomes ""; under the regex
        # fallback it stays the literal string "[]". Both cases are caught.
        if not value or value == "[]":
            errors.append(f"Frontmatter field `{field}` is required and must be non-empty.")

    if filename_date and frontmatter.get("date"):
        # _flatten_yaml stringifies datetime objects via str(); the first 10
        # characters are always YYYY-MM-DD regardless of timezone suffix.
        frontmatter_date = frontmatter["date"][:10]
        if filename_date != frontmatter_date:
            errors.append(
                f"Filename date {filename_date} does not match frontmatter date {frontmatter_date}."
            )

    title = frontmatter.get("title", "")
    description = frontmatter.get("description", "")
    if len(title) > 75:
        warnings.append("Title is long; verify the rendered search title remains clear.")
    if description and not 80 <= len(description) <= 180:
        warnings.append(
            "Description length is outside the usual one-to-two sentence working range."
        )

    if markdown_body_has_h1(body):
        errors.append("Jekyll posts must not include a Markdown body-level H1 (`#`).")
    if _body_has_draft_markers(body):
        errors.append("Draft markers such as TODO/TBD/FIXME must be resolved before publishing.")
    uses_mermaid = bool(MERMAID_RE.search(body))
    mermaid_enabled = frontmatter.get("mermaid", "").strip().lower() == "true"
    if uses_mermaid and not mermaid_enabled:
        errors.append("Post contains Mermaid diagrams but frontmatter does not set `mermaid: true`.")
    if mermaid_enabled and not uses_mermaid:
        warnings.append("Frontmatter sets `mermaid: true`, but no Mermaid diagram was found.")

    image_path = frontmatter.get("image.path", "")
    image_alt = frontmatter.get("image.alt", "")
    if image_path:
        if image_path.startswith("/"):
            image_file = repo_root / image_path.lstrip("/")
            if not image_file.exists():
                errors.append(f"Frontmatter image does not exist: {image_path}")
        if not image_alt:
            errors.append("Frontmatter image has a path but no alt text.")
    else:
        warnings.append("No frontmatter image path found; social sharing may be weaker.")

    internal_post_links = 0
    for link in extract_markdown_links(body):
        if link.startswith("/posts/"):
            if expected_url and link.split("#", 1)[0].split("?", 1)[0] != expected_url:
                internal_post_links += 1
            target_path = site_path_for_url(repo_root, link)
            if not target_path.exists():
                errors.append(f"Internal post link is not present in _site: {link}")
        elif link.startswith("/"):
            target_path = site_path_for_url(repo_root, link)
            if not target_path.exists():
                errors.append(f"Internal site link is not present in _site: {link}")
    if internal_post_links < 2:
        warnings.append("Fewer than 2 internal links to related posts were found.")

    if expected_url:
        rendered_path = site_path_for_url(repo_root, expected_url)
        if not rendered_path.exists():
            try:
                display = rendered_path.relative_to(repo_root)
            except ValueError:
                display = rendered_path
            errors.append(
                f"Rendered post is missing: {display}. Run jekyll build first."
            )
        else:
            parser = RenderedPageParser()
            parser.feed(rendered_path.read_text(encoding="utf-8", errors="replace"))
            if parser.h1_count != 1:
                errors.append(f"Rendered HTML must contain exactly one H1; found {parser.h1_count}.")
            if title and title not in parser.title:
                warnings.append("Rendered <title> does not include the frontmatter title.")
            if not parser.meta.get("description"):
                errors.append("Rendered HTML is missing meta description.")
            canonical = parser.link.get("canonical", "")
            if expected_url not in canonical:
                errors.append("Rendered canonical URL does not include the expected post URL.")
            for og_key in ["og:title", "og:description", "og:url", "og:image"]:
                if not parser.meta.get(og_key):
                    warnings.append(f"Rendered HTML is missing {og_key}.")

        search_index = repo_root / "_site" / "assets" / "js" / "data" / "search.json"
        if search_index.exists():
            if expected_url not in search_index.read_text(encoding="utf-8", errors="replace"):
                errors.append("Search index does not include the expected post URL.")
        else:
            warnings.append("_site search index is missing; build output may be incomplete.")

        sitemap = repo_root / "_site" / "sitemap.xml"
        if sitemap.exists():
            sitemap_text = sitemap.read_text(encoding="utf-8", errors="replace")
            if expected_url not in sitemap_text and f"/posts/{slug}/" not in sitemap_text:
                errors.append("Sitemap does not include the expected post URL.")
        else:
            warnings.append("_site/sitemap.xml is missing; build output may be incomplete.")

    print(f"Pre-publish check: {relative_post}")
    if expected_url:
        print(f"Expected URL: {expected_url}")

    if errors:
        print("\nERRORS:")
        for error in errors:
            print(f"- {error}")
    if warnings:
        print("\nWARNINGS:")
        for warning in warnings:
            print(f"- {warning}")

    if errors:
        print("\nFAIL")
        return 1
    print("\nPASS")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("post", help="Path to a Jekyll post under _posts/")
    args = parser.parse_args()
    try:
        return validate(args.post)
    except RepoRootNotFoundError as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
