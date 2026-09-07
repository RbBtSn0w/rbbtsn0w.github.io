#!/usr/bin/env python3
"""
google_index_ping.py

Utility to submit blog URLs to the Google Indexing API for rapid crawling and indexing.

NOTE ON GOOGLE INDEXING API COMPLIANCE:
Google officially reserves the Web Search Indexing API for pages containing JobPosting
or BroadcastEvent structured data (https://developers.google.com/search/apis/indexing-api/v3/quickstart).
Submitting standard blog posts or documentation URLs via this endpoint is widely used as a
best-effort crawling signal, but requests may be rejected or rate-limited by Google depending on
account quotas. This script handles non-200 responses gracefully without failing the deployment.

Supports:
1. Extracting URLs from local `_site/sitemap.xml` or online `https://rbbtsn0w.me/sitemap.xml`.
2. Detecting changed posts via git diff (`--changed-only`) with `--diff-filter=ACMR`.
3. Reading credentials from local file path or in-memory JSON (`GCP_SA_KEY` environment variable).
"""

import argparse
import json
import os
import re
import subprocess
import sys
import urllib.request
import xml.etree.ElementTree as ET

DEFAULT_CREDENTIALS_PATH = os.path.expanduser("~/.config/gcp/ga-sa.json")
DEFAULT_SITEMAP_URL = "https://rbbtsn0w.me/sitemap.xml"
CANONICAL_HOST = "https://rbbtsn0w.me"
INDEXING_SCOPE = "https://www.googleapis.com/auth/indexing"
INDEXING_ENDPOINT = "https://indexing.googleapis.com/v3/urlNotifications:publish"


def get_sitemap_urls(sitemap_path=None, posts_only=True):
    """Parses sitemap XML from a file or remote URL and returns list of URLs."""
    xml_data = None
    if sitemap_path and os.path.exists(sitemap_path):
        with open(sitemap_path, "r", encoding="utf-8") as f:
            xml_data = f.read()
    elif os.path.exists("_site/sitemap.xml"):
        with open("_site/sitemap.xml", "r", encoding="utf-8") as f:
            xml_data = f.read()
    else:
        req = urllib.request.Request(
            DEFAULT_SITEMAP_URL,
            headers={"User-Agent": "google-index-ping/1.0"}
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            xml_data = resp.read().decode("utf-8")

    root = ET.fromstring(xml_data)
    namespace = {"ns": "http://www.sitemaps.org/schemas/sitemap/0.9"}

    urls = []
    for loc in root.findall(".//ns:loc", namespace):
        url = loc.text.strip()
        if posts_only:
            if "/posts/" in url:
                urls.append(url)
        else:
            urls.append(url)

    return sorted(list(set(urls)))


def get_changed_posts_urls(git_diff_range="HEAD~1..HEAD"):
    """Detects modified or newly added markdown files under _posts/ and returns their canonical URLs."""
    try:
        # Filter to Added, Copied, Modified, Renamed (exclude Deleted)
        diff_cmd = ["git", "diff", "--name-only", "--diff-filter=ACMR", git_diff_range]
        res = subprocess.run(diff_cmd, capture_output=True, text=True, check=True)
        files = res.stdout.strip().splitlines()
    except Exception as e:
        print(f"Warning: git diff failed ({e}), falling back to diff against HEAD~1", file=sys.stderr)
        try:
            res = subprocess.run(["git", "diff", "--name-only", "--diff-filter=ACMR", "HEAD~1"], capture_output=True, text=True, check=True)
            files = res.stdout.strip().splitlines()
        except Exception as e2:
            print(f"Error running git diff: {e2}", file=sys.stderr)
            return []

    urls = []
    for f in files:
        if not os.path.exists(f):
            continue
        m = re.match(r"_posts/\d{4}-\d{2}-\d{2}-(.*?)\.md", f)
        if m:
            slug = m.group(1)
            urls.append(f"{CANONICAL_HOST}/posts/{slug}/")

    return sorted(list(set(urls)))


def submit_url(url, creds):
    """Submits a single URL to Google Indexing API."""
    import google.auth.transport.requests
    import requests

    if not creds.valid:
        request = google.auth.transport.requests.Request()
        creds.refresh(request)

    headers = {
        "Authorization": f"Bearer {creds.token}",
        "Content-Type": "application/json"
    }
    payload = {
        "url": url,
        "type": "URL_UPDATED"
    }

    resp = requests.post(INDEXING_ENDPOINT, json=payload, headers=headers, timeout=15)
    return resp.status_code, resp.json()


def load_credentials(custom_path=None):
    """Loads Google Service Account credentials from JSON string or file path."""
    from google.oauth2 import service_account

    # 1. Check in-memory JSON from environment (GitHub Actions Secret)
    env_json = os.environ.get("GCP_SA_KEY") or os.environ.get("GOOGLE_APPLICATION_CREDENTIALS_JSON")
    if env_json and env_json.strip():
        try:
            info = json.loads(env_json)
            return service_account.Credentials.from_service_account_info(info, scopes=[INDEXING_SCOPE])
        except Exception as e:
            print(f"Failed to parse in-memory GCP_SA_KEY: {e}", file=sys.stderr)

    # 2. Check file path
    creds_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS") or custom_path or DEFAULT_CREDENTIALS_PATH
    if os.path.exists(creds_path):
        try:
            return service_account.Credentials.from_service_account_file(creds_path, scopes=[INDEXING_SCOPE])
        except Exception as e:
            print(f"Failed to load credentials file at {creds_path}: {e}", file=sys.stderr)

    return None


def main():
    parser = argparse.ArgumentParser(
        description="Submit URLs to Google Indexing API (Best-effort signal; Google officially documents this for JobPosting/BroadcastEvent)"
    )
    parser.add_argument("--sitemap", help="Path to local sitemap.xml")
    parser.add_argument("--url", help="Single URL to submit")
    parser.add_argument("--changed-only", action="store_true", help="Detect changed/added posts from git diff")
    parser.add_argument("--git-range", default="HEAD~1..HEAD", help="Git diff revision range (default: HEAD~1..HEAD)")
    parser.add_argument("--all", action="store_true", help="Submit all URLs including tags/pages (default: posts only)")
    parser.add_argument("--limit", type=int, default=None, help="Limit number of URLs to submit")
    parser.add_argument("--dry-run", action="store_true", help="Print URLs without submitting")
    parser.add_argument("--credentials", default=DEFAULT_CREDENTIALS_PATH, help="Path to Service Account JSON")
    args = parser.parse_args()

    # 1. Determine Target URLs
    if args.url:
        target_urls = [args.url]
    elif args.changed_only:
        target_urls = get_changed_posts_urls(git_diff_range=args.git_range)
        if not target_urls:
            print("No modified or new posts detected in git diff. Nothing to submit.")
            sys.exit(0)
    else:
        posts_only = not args.all
        target_urls = get_sitemap_urls(args.sitemap, posts_only=posts_only)

    if args.limit:
        target_urls = target_urls[:args.limit]

    print(f"Discovered {len(target_urls)} URL(s) to process.")

    if args.dry_run:
        print("[DRY RUN] Listing URLs:")
        for idx, u in enumerate(target_urls, 1):
            print(f"  {idx:2d}. {u}")
        print("\nPass credentials and remove --dry-run to submit to Google Indexing API.")
        return

    # 2. Authenticate
    creds = load_credentials(args.credentials)
    if not creds:
        print("Warning: Google Service Account credentials not found (checked GCP_SA_KEY and file paths).", file=sys.stderr)
        print("Skipping Google Indexing submission without error.", file=sys.stderr)
        sys.exit(0)

    # 3. Submit
    success_count = 0
    notice_count = 0

    print(f"Submitting {len(target_urls)} URL(s) to Google Indexing API (best-effort)...")
    for idx, u in enumerate(target_urls, 1):
        try:
            status_code, resp_data = submit_url(u, creds=creds)
            if status_code == 200:
                print(f"[{idx}/{len(target_urls)}] OK (200): {u}")
                success_count += 1
            else:
                error_msg = resp_data.get("error", {}).get("message", str(resp_data))
                print(f"[{idx}/{len(target_urls)}] NOTICE ({status_code}): {u} -> {error_msg}")
                notice_count += 1
        except Exception as e:
            print(f"[{idx}/{len(target_urls)}] WARNING: {u} -> {e}")
            notice_count += 1

    print(f"\nCompleted: {success_count} accepted, {notice_count} notices.")


if __name__ == "__main__":
    main()
