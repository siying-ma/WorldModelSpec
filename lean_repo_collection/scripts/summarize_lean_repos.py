#!/usr/bin/env python3
"""Summarize collected Lean repository data."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path
from typing import Any


def load_repos(path: Path) -> list[dict[str, Any]]:
    if path.suffix == ".jsonl":
        repos = []
        with path.open(encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if line:
                    repos.append(json.loads(line))
        return repos
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo_file", nargs="?", default="projects/lean_repositories.json")
    parser.add_argument("--top", type=int, default=20)
    args = parser.parse_args()

    repo_file = Path(args.repo_file)
    repos = load_repos(repo_file)
    by_year = Counter((repo.get("created_at") or "unknown")[:4] for repo in repos)
    by_owner_type = Counter(repo.get("owner_type") or "unknown" for repo in repos)
    languages = Counter(repo.get("language") or "unknown" for repo in repos)
    forks = sum(1 for repo in repos if repo.get("fork"))
    archived = sum(1 for repo in repos if repo.get("archived"))
    top_starred = sorted(repos, key=lambda repo: int(repo.get("stargazers_count") or 0), reverse=True)[
        : args.top
    ]

    summary = {
        "repo_file": str(repo_file.resolve()),
        "repo_count": len(repos),
        "fork_count": forks,
        "non_fork_count": len(repos) - forks,
        "archived_count": archived,
        "owner_types": dict(by_owner_type.most_common()),
        "languages": dict(languages.most_common()),
        "created_by_year": dict(sorted(by_year.items())),
        "top_starred": [
            {
                "full_name": repo.get("full_name"),
                "stars": repo.get("stargazers_count"),
                "url": repo.get("html_url"),
                "created_at": repo.get("created_at"),
                "fork": repo.get("fork"),
            }
            for repo in top_starred
        ],
    }
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
