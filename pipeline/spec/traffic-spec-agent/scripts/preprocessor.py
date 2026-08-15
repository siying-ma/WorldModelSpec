"""Per-node scaffolding and resume selection.

Mirrors cc-refactor-agent's `scripts/preprocessor.py`: a task directory holds
everything one Claude session needs and produces, a task is complete only when
its `result.json` says so, and anything else is deleted and re-prepared from
scratch rather than resumed halfway.
"""

from __future__ import annotations

import json
import shutil
import sys
from datetime import datetime
from pathlib import Path

from .task import SpecNode, SpecNodeTask

# Reuse the gate's manifest function so the baseline and the scope check can
# never disagree about which files are in scope.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from tools.check_spec import library_manifest, scope_diff  # noqa: E402

__all__ = [
    "capture_baseline", "library_manifest", "load_nodes", "prepare_node_task",
    "prepare_tasks_for_resume", "rollback_node", "scope_diff",
]


def load_nodes(objectives_file: Path) -> list[SpecNode]:
    """Read objectives.jsonl into nodes, skipping malformed lines with a warning."""
    nodes: list[SpecNode] = []
    with open(objectives_file, "r", encoding="utf-8") as f:
        for lineno, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith("//"):
                continue
            try:
                nodes.append(SpecNode.from_dict(json.loads(line)))
            except (json.JSONDecodeError, KeyError, TypeError) as exc:
                print(f"[warn] {objectives_file}:{lineno}: skipping bad entry: {exc}",
                      file=sys.stderr)
    return nodes


def capture_baseline(task: SpecNodeTask) -> dict[str, str]:
    """Record what the library looks like right now, and return it.

    This is the scope check's reference point: everything except the node's own
    target file must still hash the same when the gate runs. It MUST be taken at
    the start of the node's own session, not when the whole iteration is prepared.

    Preparing all nodes up front and baselining them there was a real bug: nodes
    run serially, so node N's baseline predated nodes 1..N-1's accepted rule
    files, and the gate reported `added: <sibling>.lean` — a SCOPE_VIOLATION for
    work the node had not done. Every node after the first was guaranteed to fail,
    and agents responded by working around the gate rather than trusting it.

    The returned dict is what the harness keeps for its own post-session
    re-check; the file on disk is what the agent-invoked gate reads.
    """
    manifest = library_manifest(task.library_root)
    task.baseline_file.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    return manifest


def prepare_node_task(task: SpecNodeTask) -> None:
    """Create the task directory and everything the session and gate rely on."""
    task.task_dir.mkdir(parents=True, exist_ok=True)

    task.node_spec_file.write_text(
        json.dumps(task.node.to_dict(), indent=2, ensure_ascii=False), encoding="utf-8"
    )

    # A baseline is written here so the file always exists, but it is only a
    # placeholder: preparation happens for every node at once, while sessions run
    # serially, so by the time node N starts, nodes 1..N-1 have added their own
    # rule files and this manifest is stale. `capture_baseline` re-takes it
    # immediately before each session — see the comment there.
    capture_baseline(task)

    # Snapshot for integrate-time rollback. Absence of the snapshot file means
    # the target did not exist, so rollback deletes rather than restores.
    if task.target_path.exists():
        task.snapshot_file.write_text(
            task.target_path.read_text(encoding="utf-8"), encoding="utf-8"
        )
    elif task.snapshot_file.exists():
        task.snapshot_file.unlink()

    if not task.progress_file.exists():
        seed = {
            "attempt": 0,
            "verdict": "PREPARED",
            "detail": f"node {task.node.node_id} prepared",
            "timestamp": datetime.now().isoformat(),
        }
        task.progress_file.write_text(
            json.dumps(seed, ensure_ascii=False) + "\n", encoding="utf-8"
        )

    task.target_path.parent.mkdir(parents=True, exist_ok=True)
    print(f"[info] Prepared node '{task.node.node_id}' -> {task.node.target_file}")


def rollback_node(task: SpecNodeTask) -> None:
    """Undo a rejected node's edit to the library."""
    if task.snapshot_file.exists():
        task.target_path.write_text(
            task.snapshot_file.read_text(encoding="utf-8"), encoding="utf-8"
        )
        print(f"[info] Restored {task.node.target_file} from snapshot")
    elif task.target_path.exists():
        task.target_path.unlink()
        print(f"[info] Removed {task.node.target_file}")


def prepare_tasks_for_resume(
    tasks: list[SpecNodeTask],
) -> tuple[list[SpecNodeTask], list[tuple[SpecNodeTask, dict]]]:
    """Split tasks into "needs running" and "already accepted".

    A task counts as done only when `result.json` has `success: true`. Anything
    else — a failed run, an interrupted run with no result, an unreadable
    result — has its directory removed and is prepared fresh, so a resumed run
    never inherits half-written state.
    """
    to_run: list[SpecNodeTask] = []
    done: list[tuple[SpecNodeTask, dict]] = []

    for task in tasks:
        task_dir = task.task_dir
        expected = task.node.sanitized
        if not expected or task_dir.name != expected:
            raise ValueError(
                f"Refusing to reset unexpected task directory for "
                f"'{task.node.node_id}': {task_dir}"
            )

        reason = "no result.json (incomplete previous run)"
        if task.result_file.exists():
            try:
                loaded = json.loads(task.result_file.read_text(encoding="utf-8"))
                if isinstance(loaded, dict):
                    if loaded.get("success") is True:
                        done.append((task, loaded))
                        print(f"[info] Skipping already accepted node: {task.node.node_id}")
                        continue
                    reason = f"previous verdict was {loaded.get('verdict', 'unknown')}"
                else:
                    reason = "result.json is not a JSON object"
            except (OSError, json.JSONDecodeError) as exc:
                reason = f"could not read result.json: {exc}"

        print(f"[info] Resetting node '{task.node.node_id}' ({reason})")
        if task_dir.exists():
            shutil.rmtree(task_dir)
        prepare_node_task(task)
        to_run.append(task)

    print(f"[info] Resume scan: {len(done)} accepted, {len(to_run)} to run")
    return to_run, done
