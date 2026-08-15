#!/usr/bin/env python3
"""Collect GitHub repositories whose primary language/search language is Lean.

The GitHub Search API only exposes the first 1,000 matches for a query. This
collector avoids that ceiling by searching immutable repository creation windows
and recursively splitting any window that still has too many matches.
"""

from __future__ import annotations

import argparse
import csv
import getpass
import http.client
import json
import math
import os
import signal
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any


API_URL = "https://api.github.com/search/repositories"
MAX_SEARCH_RESULTS = 1000
PER_PAGE = 100
DEFAULT_START = "2013-01-01"
DEFAULT_LANGUAGE = "Lean"


@dataclass(frozen=True)
class Window:
    start: datetime
    end: datetime

    def label(self) -> str:
        return f"{format_dt(self.start)}__{format_dt(self.end)}".replace(":", "").replace("Z", "z")


def utc_now_end_of_day() -> datetime:
    now = datetime.now(timezone.utc)
    return datetime(now.year, now.month, now.day, 23, 59, 59, tzinfo=timezone.utc)


def parse_dt(value: str, *, end_of_day: bool = False) -> datetime:
    value = value.strip()
    if value.endswith("Z"):
        value = value[:-1] + "+00:00"
    if "T" in value:
        dt = datetime.fromisoformat(value)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)
    dt = datetime.fromisoformat(value).replace(tzinfo=timezone.utc)
    if end_of_day:
        return dt.replace(hour=23, minute=59, second=59, microsecond=0)
    return dt.replace(hour=0, minute=0, second=0, microsecond=0)


def format_dt(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def build_initial_windows(start: datetime, end: datetime, days: int) -> list[Window]:
    windows: list[Window] = []
    cursor = start
    while cursor <= end:
        window_end = min(cursor + timedelta(days=days) - timedelta(seconds=1), end)
        windows.append(Window(cursor, window_end))
        cursor = window_end + timedelta(seconds=1)
    return windows


def make_query(language: str, window: Window, include_forks: bool) -> str:
    parts = [
        f"language:{language}",
        f"created:{format_dt(window.start)}..{format_dt(window.end)}",
    ]
    if include_forks:
        parts.append("fork:true")
    else:
        parts.append("fork:false")
    return " ".join(parts)


class HardTimeout:
    def __init__(self, seconds: int):
        self.seconds = seconds
        self.old_handler: Any = None

    def __enter__(self) -> None:
        if self.seconds <= 0 or not hasattr(signal, "SIGALRM"):
            return

        def raise_timeout(signum: int, frame: Any) -> None:
            raise TimeoutError(f"request exceeded {self.seconds}s hard timeout")

        self.old_handler = signal.signal(signal.SIGALRM, raise_timeout)
        signal.setitimer(signal.ITIMER_REAL, self.seconds)

    def __exit__(self, exc_type: Any, exc: Any, tb: Any) -> None:
        if self.seconds <= 0 or not hasattr(signal, "SIGALRM"):
            return
        signal.setitimer(signal.ITIMER_REAL, 0)
        if self.old_handler is not None:
            signal.signal(signal.SIGALRM, self.old_handler)


def request_json(
    url: str,
    token: str | None,
    delay: float,
    request_timeout: int,
    attempts: int = 6,
) -> tuple[dict[str, Any], dict[str, str]]:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "world-model-of-rules-lean-repo-collector",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"

    last_error: Exception | None = None
    for attempt in range(1, attempts + 1):
        if delay > 0:
            time.sleep(delay)
        req = urllib.request.Request(url, headers=headers)
        try:
            with HardTimeout(request_timeout):
                with urllib.request.urlopen(req, timeout=request_timeout) as resp:
                    payload = json.loads(resp.read().decode("utf-8"))
                    response_headers = {k.lower(): v for k, v in resp.headers.items()}
                    return payload, response_headers
        except urllib.error.HTTPError as exc:
            response_headers = {k.lower(): v for k, v in exc.headers.items()}
            body = exc.read().decode("utf-8", errors="replace")
            last_error = RuntimeError(f"HTTP {exc.code}: {body[:500]}")
            if exc.code in {403, 429}:
                reset = response_headers.get("x-ratelimit-reset")
                retry_after = response_headers.get("retry-after")
                sleep_for = 60.0
                if retry_after and retry_after.isdigit():
                    sleep_for = float(retry_after) + 2.0
                elif reset and reset.isdigit():
                    sleep_for = max(5.0, float(reset) - time.time() + 2.0)
                print(f"Rate limited or throttled; sleeping {sleep_for:.1f}s", file=sys.stderr)
                time.sleep(sleep_for)
                continue
            if exc.code >= 500:
                time.sleep(min(60.0, 2.0**attempt))
                continue
            raise last_error
        except (TimeoutError, urllib.error.URLError, http.client.IncompleteRead) as exc:
            last_error = exc
            time.sleep(min(60.0, 2.0**attempt))
    raise RuntimeError(f"Request failed after {attempts} attempts: {last_error}")


def search_url(query: str, page: int, per_page: int) -> str:
    params = urllib.parse.urlencode(
        {
            "q": query,
            "sort": "created",
            "order": "asc",
            "per_page": per_page,
            "page": page,
        }
    )
    return f"{API_URL}?{params}"


def load_or_fetch_page(
    *,
    raw_dir: Path,
    window: Window,
    query: str,
    page: int,
    per_page: int,
    token: str | None,
    delay: float,
    request_timeout: int,
    force: bool,
) -> tuple[dict[str, Any], bool]:
    page_path = raw_dir / f"{window.label()}__page_{page:03d}.json"
    if page_path.exists() and not force:
        return json.loads(page_path.read_text(encoding="utf-8")), True

    payload, headers = request_json(search_url(query, page, per_page), token, delay, request_timeout)
    wrapped = {
        "query": query,
        "page": page,
        "per_page": per_page,
        "fetched_at": format_dt(datetime.now(timezone.utc)),
        "rate_limit": {
            "limit": headers.get("x-ratelimit-limit"),
            "remaining": headers.get("x-ratelimit-remaining"),
            "reset": headers.get("x-ratelimit-reset"),
            "resource": headers.get("x-ratelimit-resource"),
            "used": headers.get("x-ratelimit-used"),
        },
        "payload": payload,
    }
    page_path.write_text(json.dumps(wrapped, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return wrapped, False


def simplify_repo(repo: dict[str, Any]) -> dict[str, Any]:
    owner = repo.get("owner") or {}
    return {
        "id": repo.get("id"),
        "node_id": repo.get("node_id"),
        "name": repo.get("name"),
        "full_name": repo.get("full_name"),
        "owner_login": owner.get("login"),
        "owner_type": owner.get("type"),
        "private": repo.get("private"),
        "fork": repo.get("fork"),
        "html_url": repo.get("html_url"),
        "clone_url": repo.get("clone_url"),
        "ssh_url": repo.get("ssh_url"),
        "git_url": repo.get("git_url"),
        "description": repo.get("description"),
        "language": repo.get("language"),
        "created_at": repo.get("created_at"),
        "updated_at": repo.get("updated_at"),
        "pushed_at": repo.get("pushed_at"),
        "stargazers_count": repo.get("stargazers_count"),
        "watchers_count": repo.get("watchers_count"),
        "forks_count": repo.get("forks_count"),
        "open_issues_count": repo.get("open_issues_count"),
        "archived": repo.get("archived"),
        "disabled": repo.get("disabled"),
        "default_branch": repo.get("default_branch"),
        "license": (repo.get("license") or {}).get("spdx_id"),
        "topics": repo.get("topics") or [],
        "size": repo.get("size"),
    }


def write_outputs(
    projects_dir: Path,
    repos_by_id: dict[int, dict[str, Any]],
    manifest: list[dict[str, Any]],
    *,
    language: str,
    include_forks: bool,
    start: datetime,
    end: datetime,
    experiment: bool,
) -> dict[str, Any]:
    repos = sorted(
        repos_by_id.values(),
        key=lambda item: (item.get("created_at") or "", item.get("full_name") or ""),
    )
    prefix = "experiment_lean" if experiment else "lean"

    json_path = projects_dir / f"{prefix}_repositories.json"
    jsonl_path = projects_dir / f"{prefix}_repositories.jsonl"
    csv_path = projects_dir / f"{prefix}_repositories.csv"
    urls_path = projects_dir / f"{prefix}_repo_urls.txt"
    clones_path = projects_dir / f"{prefix}_clone_urls.txt"
    manifest_path = projects_dir / f"{prefix}_chunk_manifest.json"
    summary_path = projects_dir / f"{prefix}_summary.json"

    json_path.write_text(json.dumps(repos, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    with jsonl_path.open("w", encoding="utf-8") as fh:
        for repo in repos:
            fh.write(json.dumps(repo, sort_keys=True) + "\n")

    fields = [
        "id",
        "full_name",
        "html_url",
        "clone_url",
        "fork",
        "language",
        "created_at",
        "updated_at",
        "pushed_at",
        "stargazers_count",
        "forks_count",
        "archived",
        "license",
        "default_branch",
    ]
    with csv_path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(repos)

    urls_path.write_text(
        "".join(f"{repo['html_url']}\n" for repo in repos if repo.get("html_url")),
        encoding="utf-8",
    )
    clones_path.write_text(
        "".join(f"{repo['clone_url']}\n" for repo in repos if repo.get("clone_url")),
        encoding="utf-8",
    )
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    fork_count = sum(1 for repo in repos if repo.get("fork"))
    archived_count = sum(1 for repo in repos if repo.get("archived"))
    total_stars = sum(int(repo.get("stargazers_count") or 0) for repo in repos)
    summary = {
        "language": language,
        "include_forks": include_forks,
        "start": format_dt(start),
        "end": format_dt(end),
        "generated_at": format_dt(datetime.now(timezone.utc)),
        "repo_count": len(repos),
        "fork_count": fork_count,
        "non_fork_count": len(repos) - fork_count,
        "archived_count": archived_count,
        "total_stars": total_stars,
        "chunks_completed": len(manifest),
        "output_files": {
            "json": str(json_path),
            "jsonl": str(jsonl_path),
            "csv": str(csv_path),
            "repo_urls": str(urls_path),
            "clone_urls": str(clones_path),
            "chunk_manifest": str(manifest_path),
            "summary": str(summary_path),
        },
    }
    summary_path.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return summary


def process_window(
    *,
    window: Window,
    language: str,
    include_forks: bool,
    raw_dir: Path,
    token: str | None,
    delay: float,
    request_timeout: int,
    per_page: int,
    force: bool,
    max_results: int,
    repos_by_id: dict[int, dict[str, Any]],
    manifest: list[dict[str, Any]],
    depth: int = 0,
) -> None:
    query = make_query(language, window, include_forks)
    first_page, from_cache = load_or_fetch_page(
        raw_dir=raw_dir,
        window=window,
        query=query,
        page=1,
        per_page=per_page,
        token=token,
        delay=delay,
        request_timeout=request_timeout,
        force=force,
    )
    payload = first_page["payload"]
    total = int(payload.get("total_count") or 0)

    if total > max_results:
        if window.start >= window.end:
            raise RuntimeError(f"Cannot split one-second window with {total} results: {query}")
        midpoint = window.start + (window.end - window.start) / 2
        midpoint = midpoint.replace(microsecond=0)
        if midpoint < window.start:
            midpoint = window.start
        left = Window(window.start, midpoint)
        right = Window(midpoint + timedelta(seconds=1), window.end)
        print(
            f"Splitting {format_dt(window.start)}..{format_dt(window.end)} "
            f"({total} results)",
            file=sys.stderr,
        )
        process_window(
            window=left,
            language=language,
            include_forks=include_forks,
            raw_dir=raw_dir,
            token=token,
            delay=delay,
            request_timeout=request_timeout,
            per_page=per_page,
            force=force,
            max_results=max_results,
            repos_by_id=repos_by_id,
            manifest=manifest,
            depth=depth + 1,
        )
        process_window(
            window=right,
            language=language,
            include_forks=include_forks,
            raw_dir=raw_dir,
            token=token,
            delay=delay,
            request_timeout=request_timeout,
            per_page=per_page,
            force=force,
            max_results=max_results,
            repos_by_id=repos_by_id,
            manifest=manifest,
            depth=depth + 1,
        )
        return

    pages = max(1, math.ceil(total / per_page))
    pages = min(pages, math.ceil(max_results / per_page))
    items: list[dict[str, Any]] = list(payload.get("items") or [])
    cached_pages = 1 if from_cache else 0
    fetched_pages = 0 if from_cache else 1

    for page in range(2, pages + 1):
        page_data, page_from_cache = load_or_fetch_page(
            raw_dir=raw_dir,
            window=window,
            query=query,
            page=page,
            per_page=per_page,
            token=token,
            delay=delay,
            request_timeout=request_timeout,
            force=force,
        )
        cached_pages += int(page_from_cache)
        fetched_pages += int(not page_from_cache)
        items.extend(page_data["payload"].get("items") or [])

    before = len(repos_by_id)
    for repo in items:
        repo_id = repo.get("id")
        if isinstance(repo_id, int):
            repos_by_id[repo_id] = simplify_repo(repo)
    added = len(repos_by_id) - before

    manifest.append(
        {
            "start": format_dt(window.start),
            "end": format_dt(window.end),
            "query": query,
            "reported_total_count": total,
            "pages": pages,
            "items_seen": len(items),
            "new_unique_repos": added,
            "fetched_pages": fetched_pages,
            "cached_pages": cached_pages,
            "split_depth": depth,
        }
    )
    print(
        f"{format_dt(window.start)}..{format_dt(window.end)}: "
        f"reported={total}, pages={pages}, new_unique={added}",
        file=sys.stderr,
    )


def token_from_args(args: argparse.Namespace) -> str | None:
    if args.token_stdin:
        token = sys.stdin.readline().strip()
        return token or None
    if args.token_file:
        return Path(args.token_file).read_text(encoding="utf-8").strip()
    if args.prompt_token:
        return getpass.getpass("GitHub token: ").strip()
    return os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--language", default=DEFAULT_LANGUAGE)
    parser.add_argument("--start-date", default=DEFAULT_START)
    parser.add_argument("--end-date", default=None)
    parser.add_argument("--projects-dir", default="projects")
    parser.add_argument("--initial-window-days", type=int, default=365)
    parser.add_argument("--per-page", type=int, default=PER_PAGE)
    parser.add_argument("--request-delay", type=float, default=2.1)
    parser.add_argument("--request-timeout", type=int, default=90)
    parser.add_argument("--max-results-per-query", type=int, default=MAX_SEARCH_RESULTS)
    parser.add_argument("--exclude-forks", action="store_true")
    parser.add_argument("--force", action="store_true", help="Refetch pages even when raw page files exist")
    parser.add_argument("--experiment", action="store_true", help="Run a bounded smoke test and write experiment outputs")
    parser.add_argument("--experiment-windows", type=int, default=2)
    parser.add_argument("--experiment-per-page", type=int, default=5)
    parser.add_argument("--token-stdin", action="store_true", help="Read a GitHub token from the first stdin line")
    parser.add_argument("--token-file", default=None)
    parser.add_argument("--prompt-token", action="store_true")
    parser.add_argument(
        "--load-existing-jsonl",
        default=None,
        help="Pre-load repos from an existing JSONL file and merge new results into it",
    )
    args = parser.parse_args()
    if args.per_page < 1 or args.per_page > 100:
        parser.error("--per-page must be between 1 and 100")
    if args.initial_window_days < 1:
        parser.error("--initial-window-days must be positive")
    return args


def main() -> int:
    args = parse_args()
    start = parse_dt(args.start_date)
    end = parse_dt(args.end_date, end_of_day=True) if args.end_date else utc_now_end_of_day()
    if end < start:
        raise SystemExit("--end-date must be on or after --start-date")

    projects_dir = Path(args.projects_dir).resolve()
    projects_dir.mkdir(parents=True, exist_ok=True)
    raw_dir = projects_dir / ("experiment_raw_pages" if args.experiment else "raw_pages")
    raw_dir.mkdir(parents=True, exist_ok=True)

    token = token_from_args(args)
    include_forks = not args.exclude_forks
    windows = build_initial_windows(start, end, args.initial_window_days)
    if args.experiment:
        windows = windows[: max(1, args.experiment_windows)]
        per_page = min(args.per_page, args.experiment_per_page)
    else:
        per_page = args.per_page

    repos_by_id: dict[int, dict[str, Any]] = {}
    manifest: list[dict[str, Any]] = []

    if args.load_existing_jsonl:
        existing_path = Path(args.load_existing_jsonl)
        if existing_path.exists():
            with existing_path.open(encoding="utf-8") as fh:
                for line in fh:
                    line = line.strip()
                    if line:
                        repo = json.loads(line)
                        if isinstance(repo.get("id"), int):
                            repos_by_id[repo["id"]] = repo
            print(f"Pre-loaded {len(repos_by_id)} repos from {existing_path}", file=sys.stderr)
        else:
            print(f"Warning: --load-existing-jsonl path not found: {existing_path}", file=sys.stderr)

        # Use the original start date from the companion summary if available so
        # the output summary reflects the full dataset coverage, not just this run.
        summary_path = existing_path.with_name(existing_path.stem.replace("repositories", "summary") + ".json")
        if summary_path.exists():
            try:
                existing_summary = json.loads(summary_path.read_text(encoding="utf-8"))
                if existing_summary.get("start"):
                    start = parse_dt(existing_summary["start"])
                    print(f"Using dataset start date from existing summary: {format_dt(start)}", file=sys.stderr)
            except Exception:
                pass

    for idx, window in enumerate(windows, start=1):
        print(f"Window {idx}/{len(windows)}", file=sys.stderr)
        process_window(
            window=window,
            language=args.language,
            include_forks=include_forks,
            raw_dir=raw_dir,
            token=token,
            delay=args.request_delay,
            request_timeout=args.request_timeout,
            per_page=per_page,
            force=args.force,
            max_results=args.max_results_per_query,
            repos_by_id=repos_by_id,
            manifest=manifest,
        )

    summary = write_outputs(
        projects_dir,
        repos_by_id,
        manifest,
        language=args.language,
        include_forks=include_forks,
        start=start,
        end=end,
        experiment=args.experiment,
    )
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
