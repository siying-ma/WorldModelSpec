"""Repository paths and the one sys.path fix every entry point needs.

`carla_sgg.sgg.SGG.init_to_world` imports `agents.navigation.global_route_planner`,
which is NOT part of the `carla` wheel — it ships as loose source under
`sim/PythonAPI/carla/agents/`. Nothing in `environment.yml` installs it, so any
script that builds an SGG dies with `ModuleNotFoundError: No module named
'agents'` unless that directory is on the path first.
"""

from __future__ import annotations

import sys
from pathlib import Path

# src/carlaspec/paths.py -> src/carlaspec -> src -> carla_scene_graphs
REPO_ROOT = Path(__file__).resolve().parents[2]
PYTHON_API = REPO_ROOT / "sim" / "PythonAPI" / "carla"
DEFAULT_DATABASE = REPO_ROOT / "database"


def ensure_agents_importable() -> None:
    """Put CARLA's bundled `agents` package on sys.path, idempotently."""
    if not PYTHON_API.is_dir():
        raise RuntimeError(
            f"CARLA PythonAPI not found at {PYTHON_API}. The `agents` package it "
            "ships is required by carla_sgg's map indexing; point PYTHON_API at a "
            "CARLA installation or install the agents package yourself."
        )
    entry = str(PYTHON_API)
    if entry not in sys.path:
        sys.path.insert(0, entry)


def ensure_repo_importable() -> None:
    """Allow `import carla_sgg` when running from anywhere."""
    entry = str(REPO_ROOT)
    if entry not in sys.path:
        sys.path.insert(0, entry)
