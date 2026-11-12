"""Stage records for tests, built whole: an `open` row with every field a staged run's readers
check (the state schema, the code baseline, the semantic inputs, the acceptance policy and the
effects), each taken from the current tree and the run's saved options (none for a bare run that
was never launched) unless a test gives it, and the `close` row a transition writes before the
next `open`."""
import json
from pathlib import Path

from harness.store import paths, stages
from harness.store.state import DEPENDENCY_POLICY, RUN_VERSION, acceptance_policy


def saved_options(run_id: str) -> dict:
    return json.loads((paths.run_dir(run_id) / "options.json").read_text())


def open_row(stage_id: str, run_id: str = "r", kind: str | None = None, prev: str | None = None, transition: str = "t0",
             scope="all", source_commit: str | None = None, **given) -> dict:
    """The `open` row of a stage of `run_id` on the current tree. Defaults: the kind from the stage
    id's letter, the code of this tree (`handoff.code_digest`), the run's saved semantic inputs and
    acceptance policy (`review: none`), the effects of this tree on those inputs. A scope given as a
    collection of law ids is written as a transition writes it. `given` replaces any field, and a
    field given there is never computed (so a test outside the harness's tree passes them all)."""
    kind = kind or {"G": "generation", "R": "review", "L": "labels"}[stage_id[0]]
    if scope != "all" and not isinstance(scope, dict):
        from harness.tools.stage import scope_value
        scope = scope_value(sorted(scope))
    row = {"event": "open", "run_id": run_id, "stage_id": stage_id, "stage_kind": kind,
           "launch_kinds": list(stages.LAUNCH_KINDS[kind]), "previous_stage_id": prev, "transition_id": transition,
           "input_checkpoint": None, "state_schema": RUN_VERSION, "scope": scope, "changed_files": [],
           "prompts_approved": None, "opened_at": "2026-11-11T00:00:00"}
    if "code_baseline" not in given:
        from harness.tools import handoff
        row["code_baseline"] = {"source_commit": source_commit, "code": handoff.code_digest()}
    if "semantic" not in given or "acceptance_policy" not in given:
        if (paths.run_dir(run_id) / "options.json").exists():
            saved = saved_options(run_id)
            row["semantic"] = saved["semantic"]
            row["acceptance_policy"] = {**acceptance_policy(saved), "review": "none"}
        else:                                            # a bare run of a test, never launched: no saved inputs to take
            row["semantic"] = {}
            row["acceptance_policy"] = {"label_repair": True, "dependency": DEPENDENCY_POLICY, "review": "none"}
    if "effects" not in given:
        from harness.tools.stage import effects_at
        row["effects"] = effects_at(paths.REPO, given.get("semantic", row.get("semantic")) or {})
    return {**row, **given}


def close_row(stage_id: str, transition: str) -> dict:
    return {"event": "close", "stage_id": stage_id, "transition_id": transition, "output_checkpoint": None,
            "closed_at": "2026-11-11T00:00:01"}


def write_stages(run_dir: Path, *rows: dict) -> None:
    """The stage record holding `rows`, checked by the real reader."""
    (Path(run_dir) / stages.STAGES_FILE).write_text("".join(json.dumps(r) + "\n" for r in rows))
    stages.read_stages(run_dir)


# -- the real takeover of the library, as separate processes would take it ---------------------------
import os
from contextlib import contextmanager
from unittest import mock

from harness.store import owner

REAL_OWNER = {k: getattr(owner, k) for k in ("acquire", "acquire_for_command", "acquire_for_transition") if hasattr(owner, k)}


def released() -> None:
    """This process gives the library up as a process that ends does: its lock closed, its record and
    environment marks forgotten (the owner record on disk stays, as an ended process leaves it)."""
    if owner._FD is not None:
        owner._FD.close()
    owner._FD, owner._RECORD = None, {}
    for k in (owner.ENV, owner.LIB_ENV):
        os.environ.pop(k, None)


@contextmanager
def real_ownership():
    """The real takeover in force, whatever a fixture stood in for it; every call made inside is one
    process's: give the library up with `released` between them. It starts as a fresh process does,
    with no owner state (an earlier test's lock, record or environment marks are set aside), gives the
    library up at the end, and then puts back what it set aside."""
    saved = (owner._FD, owner._RECORD, {k: os.environ.get(k) for k in (owner.ENV, owner.LIB_ENV)})
    owner._FD, owner._RECORD = None, {}
    for k in (owner.ENV, owner.LIB_ENV):
        os.environ.pop(k, None)
    try:
        with mock.patch.multiple(owner, **REAL_OWNER):
            yield
    finally:
        released()
        owner._FD, owner._RECORD = saved[0], saved[1]
        for k, v in saved[2].items():
            if v is not None:
                os.environ[k] = v
