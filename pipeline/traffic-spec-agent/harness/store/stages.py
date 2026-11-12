"""A run's stages: the periods of one code baseline each, entered only by an explicit transition.

A stage has an id (`G0`, `L0`, ...), a kind (`generation`, `review`, `labels`), the launch kinds it
allows, its code baseline, its semantic input digests, its acceptance policy and its scope. Its
record is `stages.jsonl` in the run's directory, appended by a transition only: one `open` row when a
stage is entered and one `close` row when it is left, the two rows of a transition written by one
atomic replacement of the file. The active stage is the last `open` row without a matching `close`.
A run without the file has no stage record and keeps the checks it had before stages existed.

An `open` row holds: `event` ("open"), `run_id`, `stage_id`, `stage_kind`, `launch_kinds`,
`previous_stage_id` (None for the first stage), `transition_id`, `input_checkpoint`
(`{export_id, manifest_sha256, snapshot_manifest_sha256}`, None for the first stage), `code_baseline`
(`{source_commit, code: {files, digest}}`), `state_schema` (the run version that reads the run's
files), `semantic` (the semantic input digests), `acceptance_policy`, `scope` ("all", or
`{laws, sha256}`), `changed_files` (`[{path, class}]` against the previous stage), `effects` (what
its code does that the next transition compares: `{gate, scoring, generated_prompts, prompts}`, the
gate and scoring digests of its files and the generated and written prompt digests), `prompts_approved`
(the prompt digest the operator approved for it, or None) and `opened_at`; a stage adopted from a run
made before stages also holds `adopted_from` (`{export_id, manifest_sha256, head}` of the old export).
A `close` row holds: `event` ("close"), `stage_id`, `transition_id`, `output_checkpoint` and
`closed_at`.

The stage machinery's own files in the run's directory (`MACHINERY_FILES`, and everything under
`STAGES_DIR`) are never part of a stage snapshot's file set: they are the snapshot store, the stage
record and the state of a transition in progress."""
from __future__ import annotations

import hashlib
from pathlib import Path

from . import jsonl

STAGES_FILE = "stages.jsonl"
STAGES_DIR = "stages"
BLOBS_DIR = "stages/blobs"
TRANSITION_FILE = "stage_transition.json"
JOURNAL_FILE = "stage_journal.json"
MACHINERY_FILES = (STAGES_FILE, TRANSITION_FILE, JOURNAL_FILE)

KINDS = ("generation", "review", "labels", "test")
#: The launch kinds a stage of each kind allows, one each: a staged run is generated, reviewed and
#: label-checked in that order, so no launch both generates and checks labels, and no label check
#: runs on a law the review has not passed. A stage adopted from a run made before stages existed is
#: a `generation` stage like any other.
LAUNCH_KINDS = {"generation": ("generation",), "review": ("review",), "labels": ("labels",), "test": ("test",)}
#: A test run (`--mode test` over a training run, `base_run`) has one stage of its own kind, `T0`: it
#: generates the held-out laws add-only over the training run's records and is scored by
#: `score_split`. It is never reviewed or label-checked, enters and leaves no stage by a transition,
#: is never handed over, and is no training evidence: no run builds on it as its base run.
TEST_REFUSAL = "a test run's results are no training evidence: no run takes a test run as its base run"
#: The transitions allowed while no reviewer implementation is registered: only a stage's code may be
#: replaced. A labels stage is entered from a review stage only, and a transition into `review` is
#: refused, so a staged run cannot reach its label check until a reviewer is registered.
ALLOWED_TRANSITIONS = frozenset({("generation", "generation"), ("labels", "labels")})
REVIEW_REFUSAL = ("a review stage needs the review acceptance condition and an accepted reviewer implementation; "
                  "the current baseline registers no reviewer")
LABELS_REFUSAL = "a labels stage is entered from a review stage only: no law is label-checked before its review"
UNSPLIT_REFUSAL = ("a staged run generates, reviews and checks labels in separate stages: a launch that both generates and "
                   "checks labels (neither --label_deferred nor --label_stage) is refused; launch with --label_deferred "
                   "in a generation stage")
#: The states of a transition, in order; any launch is refused while the last transition is short of `done`.
TRANSITION_STATES = ("prepared", "committed", "applied", "exported", "done")


def is_machinery(rel: str | Path) -> bool:
    """Whether a path relative to the run's directory is one of the stage machinery's own files."""
    parts = Path(rel).parts
    return bool(parts) and (parts[0] == STAGES_DIR or (len(parts) == 1 and parts[0] in MACHINERY_FILES))


def read_stages(run_dir: Path) -> list[dict]:
    """The rows of the run's stage record, checked whole: every row is an `open` or a `close`; a
    `close` names the stage open before it, with the same transition id as the `open` that follows
    it; an `open` names as its previous stage the stage closed just before it (None for the first);
    stage ids are unique; at most one stage is open. A record that breaks any of these is a
    `DataIntegrityError`, never read in part. An absent file gives []."""
    f = Path(run_dir) / STAGES_FILE
    rows = jsonl.read_strict(f)
    open_id, closed_last, seen = None, None, set()
    pending_close = None
    for i, r in enumerate(rows, 1):
        ev = r.get("event")
        if ev == "open":
            sid = r.get("stage_id")
            if not isinstance(sid, str) or not sid or sid in seen:
                raise jsonl.DataIntegrityError(f, i, f"stage id {sid!r} missing or repeated")
            if open_id is not None:
                raise jsonl.DataIntegrityError(f, i, f"stage `{sid}` opened while `{open_id}` is open")
            if r.get("previous_stage_id") != closed_last:
                raise jsonl.DataIntegrityError(f, i, f"stage `{sid}` names `{r.get('previous_stage_id')}` as its previous stage, "
                                                     f"not `{closed_last}`")
            if r.get("stage_kind") not in KINDS:
                raise jsonl.DataIntegrityError(f, i, f"stage `{sid}` has the kind {r.get('stage_kind')!r}")
            if pending_close is not None and r.get("transition_id") != pending_close:
                raise jsonl.DataIntegrityError(f, i, f"stage `{sid}` is opened by another transition than the one that closed "
                                                     f"`{closed_last}`")
            seen.add(sid)
            open_id, pending_close = sid, None
        elif ev == "close":
            if r.get("stage_id") != open_id or open_id is None:
                raise jsonl.DataIntegrityError(f, i, f"`close` of `{r.get('stage_id')}`, which is not the open stage")
            closed_last, open_id, pending_close = open_id, None, r.get("transition_id")
        else:
            raise jsonl.DataIntegrityError(f, i, f"a row of event {ev!r}")
    if open_id is None and rows:
        raise jsonl.DataIntegrityError(f, len(rows), "no stage is open")
    return rows


def active_stage(run_dir: Path) -> dict | None:
    """The `open` row of the run's active stage, or None for a run without a stage record."""
    rows = read_stages(run_dir)
    return next((r for r in reversed(rows) if r.get("event") == "open"), None)


def stages_sha256(run_dir: Path) -> str | None:
    """The sha256 of the run's stage record as it is on disk, or None without one."""
    f = Path(run_dir) / STAGES_FILE
    return hashlib.sha256(f.read_bytes()).hexdigest() if f.is_file() else None


def transition_state(run_dir: Path) -> dict | None:
    """The state file of the run's last transition, or None when no transition was ever begun."""
    return jsonl.read_json(Path(run_dir) / TRANSITION_FILE, None)


def transition_refusal(run_dir: Path) -> str | None:
    """Why no launch, handoff or other transition may start: a transition begun and short of `done`
    (it is finished by running the same transition again); None otherwise."""
    st = transition_state(run_dir)
    if st is None or st.get("status") == "done":
        return None
    return (f"the stage transition `{st.get('transition_id')}` stopped at `{st.get('status')}`: finish it by running the "
            "same `stage enter` (or `stage adopt`) again before anything else runs on this run")


def unfinished_transitions(results: Path, own: tuple[str, str] | None = None) -> str | None:
    """Why no command may write the library or a run while any run under `results` has a stage
    transition begun and short of `done` (the library, its gap ledger and every run's handed files are
    what the transition's journal and export stand on), naming each; None when there is none. Only
    the transition's own work goes on: `own`, (run id, transition id), is that transition."""
    out = []
    for rd in sorted(p for p in Path(results).iterdir() if p.is_dir()) if Path(results).is_dir() else []:
        try:
            st = transition_state(rd)
            mine = own is not None and own[0] == rd.name and st is not None and st.get("transition_id") == own[1]
            why = None if mine else transition_refusal(rd)
        except jsonl.DataIntegrityError as e:
            why = f"its transition state cannot be read ({e})"
        if why:
            out.append(f"run `{rd.name}`: {why}")
    return "; ".join(out) or None


def scope_laws(stage: dict | None) -> list[str] | None:
    """The laws a stage is limited to, or None when it covers every law of the run (no stage record,
    or scope "all")."""
    if stage is None or stage.get("scope") in (None, "all"):
        return None
    return list(stage["scope"]["laws"])
