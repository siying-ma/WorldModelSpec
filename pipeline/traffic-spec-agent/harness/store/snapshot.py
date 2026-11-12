"""The immutable snapshot of a closed stage, and its verification and restoration.

A stage's snapshot is written once, when the stage is closed, from the run as its last handoff
export left it: `stages/<stage_id>/manifest.json` records the stage's code baseline, the digest of
every file of that export outside the stage machinery (`files`), of every stage machinery file that
export carried (`history`), and of the export's `handoff/manifest.json` and `handoff/files.txt`
(`control`); the content of each is kept once under `stages/blobs/<sha256>`.

Paths in `files` and `history` are those of the export's `artifacts`, relative to the agent
directory; the two `control` keys are relative to the run's directory. A snapshot never holds
itself: when the stage's last export was written its own manifest did not exist yet, so it first
appears in the next stage's `history`. A snapshot is whole when it and the stored export agree both
ways (`verify`), and a restore writes the export's files and its two control files back byte for
byte into a clean checkout of the stage's baseline commit, so a handoff check and a resume there
see what they saw after that export. Every refusal is a `SystemExit` raised before anything is
written."""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import threading
from pathlib import Path

from . import jsonl, paths, stages

CONTROL = ("handoff/manifest.json", "handoff/files.txt")


def _sha_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def _sha(p: Path) -> str:
    return _sha_bytes(p.read_bytes())


def _write_bytes(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f".{path.name}.tmp-{os.getpid()}-{threading.get_ident()}")
    with open(tmp, "wb") as fh:
        fh.write(data)
        fh.flush()
        os.fsync(fh.fileno())
    os.replace(tmp, path)


def _run_rel(run_id: str) -> Path:
    """The run's directory relative to the agent directory."""
    return paths.run_dir(run_id).resolve().relative_to(paths.REPO.resolve())


def _machinery(rel: str, run_rel: Path) -> bool:
    """Whether an agent-directory path is one of the run's stage machinery files."""
    p = Path(rel)
    return p.is_relative_to(run_rel) and stages.is_machinery(p.relative_to(run_rel))


def _blobs(run_id: str) -> Path:
    return paths.run_dir(run_id) / stages.BLOBS_DIR


def _manifest_file(run_id: str, stage_id: str) -> Path:
    return paths.run_dir(run_id) / stages.STAGES_DIR / stage_id / "manifest.json"


def _refuse(why: str) -> SystemExit:
    return SystemExit(f"[stage] {why} — nothing was written")


def write(run_id: str, stage_id: str, transition_id: str) -> dict:
    """Write the snapshot of the closing stage `stage_id` and return its manifest.

    The run's handoff manifest is the anchor: every file its `artifacts` lists must be on disk with
    the digest it records, both handoff files must be there, and a manifest that names a stage must
    name this one. Each file and both control files are kept as blobs (one already stored under the
    same digest is kept; one whose content is not its name is refused), then the snapshot manifest is
    written once: an equal one already there is returned as it is, a different one is refused. The
    snapshot is then verified both ways against the stored export."""
    rd = paths.run_dir(run_id)
    hd = rd / "handoff"
    raw = {name: (rd / name).read_bytes() for name in CONTROL if (rd / name).is_file()}
    if len(raw) < len(CONTROL):
        raise _refuse(f"`{run_id}` has no whole handoff export ({', '.join(n for n in CONTROL if n not in raw)} missing): "
                      "export the run before its stage is closed")
    try:
        m = json.loads(raw["handoff/manifest.json"].decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as e:
        raise _refuse(f"`{run_id}`'s handoff manifest cannot be read ({e})")
    if "stage_id" in m and m["stage_id"] != stage_id:
        raise _refuse(f"`{run_id}`'s last export was made in stage `{m['stage_id']}`, not in the closing stage `{stage_id}`")
    arts = m.get("artifacts") or {}
    differ = [f for f, h in sorted(arts.items()) if not (paths.REPO / f).is_file() or _sha(paths.REPO / f) != h]
    if differ:
        raise _refuse(f"{len(differ)} file(s) of `{run_id}` are missing or not as its last export recorded "
                      f"({', '.join(differ[:8])}): export the run at its checkpoint before its stage is closed")
    run_rel = _run_rel(run_id)
    files = {f: h for f, h in sorted(arts.items()) if not _machinery(f, run_rel)}
    history = {f: h for f, h in sorted(arts.items()) if _machinery(f, run_rel)}
    control = {name: {"sha256": _sha_bytes(b)} for name, b in raw.items()}
    manifest = {"stage_id": stage_id, "transition_id": transition_id, "baseline": m.get("baseline"),
                "files": files, "history": history, "control": control}
    mf = _manifest_file(run_id, stage_id)
    was = jsonl.read_json(mf, None)
    if was is not None and was != manifest:
        raise _refuse(f"stage `{stage_id}` of `{run_id}` already has another snapshot ({mf.relative_to(rd)})")
    bd = _blobs(run_id)
    wanted = {h: paths.REPO / f for f, h in {**files, **history}.items()}
    bad = sorted(h for h in set(wanted) | {c["sha256"] for c in control.values()} if (bd / h).is_file() and _sha(bd / h) != h)
    if bad:
        raise _refuse(f"stored blob(s) of `{run_id}` do not hash to their names: {', '.join(bad[:8])}")
    for name, b in raw.items():
        if not (bd / control[name]["sha256"]).is_file():
            _write_bytes(bd / control[name]["sha256"], b)
    for h, src in wanted.items():
        if not (bd / h).is_file():
            data = src.read_bytes()
            if _sha_bytes(data) != h:
                raise SystemExit(f"[stage] `{src}` changed while stage `{stage_id}`'s snapshot was written; its manifest "
                                 "was not written")
            _write_bytes(bd / h, data)
    if was is None:
        jsonl.write_atomic(mf, json.dumps(manifest, indent=1, ensure_ascii=False))
    problems = verify(run_id, stage_id)
    if problems:
        raise SystemExit(f"[stage] the snapshot of stage `{stage_id}` of `{run_id}` is not whole: " + "; ".join(problems[:8]))
    return manifest


def _stage_ids(run_id: str) -> list[str]:
    d = paths.run_dir(run_id) / stages.STAGES_DIR
    return sorted(p.parent.name for p in d.glob("*/manifest.json")) if d.is_dir() else []


def _problems(run_id: str, sid: str) -> list[str]:
    """Why one snapshot does not match the export it was taken from, both ways."""
    bd = _blobs(run_id)
    try:
        s = jsonl.read_json(_manifest_file(run_id, sid), None)
    except jsonl.DataIntegrityError as e:
        return [f"{sid}: its manifest cannot be read ({e})"]
    if s is None:
        return [f"{sid}: no snapshot"]
    out = []
    if s.get("stage_id") != sid:
        out.append(f"{sid}: its manifest names the stage `{s.get('stage_id')}`")
    files, history, control = s.get("files") or {}, s.get("history") or {}, s.get("control") or {}
    for f in sorted(set(files) | set(history)):
        if Path(f).is_absolute() or ".." in Path(f).parts:
            out.append(f"{sid}: `{f}` is not a path inside the agent directory")
    refs = {**files, **history}
    blob = {}
    for h in sorted(set(refs.values()) | {(control.get(n) or {}).get("sha256") for n in CONTROL}):
        p = bd / str(h)
        if not p.is_file():
            out.append(f"{sid}: blob {h} is missing")
        elif _sha(p) != h:
            out.append(f"{sid}: blob {h} does not hash to its name")
        else:
            blob[h] = p
    raw = {}
    for n in CONTROL:
        h = (control.get(n) or {}).get("sha256")
        if h is None:
            out.append(f"{sid}: no `{n}` in its control record")
        elif h in blob:
            raw[n] = blob[h].read_bytes()
    if len(raw) < len(CONTROL):
        return out
    try:
        m = json.loads(raw["handoff/manifest.json"].decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as e:
        return out + [f"{sid}: its stored handoff manifest cannot be read ({e})"]
    arts = m.get("artifacts") or {}
    run_rel = _run_rel(run_id)
    both = sorted(set(files) & set(history))
    if both:
        out.append(f"{sid}: in both `files` and `history`: {', '.join(both[:8])}")
    if s.get("baseline") != m.get("baseline"):
        out.append(f"{sid}: its baseline is not the stored export's")
    if "stage_id" in m and m["stage_id"] != sid:
        out.append(f"{sid}: the stored export was made in stage `{m['stage_id']}`")
    out += [f"{sid}: `history` holds `{f}`, not a stage machinery file" for f in sorted(history) if not _machinery(f, run_rel)]
    out += [f"{sid}: `files` holds the stage machinery file `{f}`" for f in sorted(files) if _machinery(f, run_rel)]
    out += [f"{sid}: `{f}` is in the snapshot, not in the stored export's artifacts" for f in sorted(set(refs) - set(arts))]
    out += [f"{sid}: `{f}` is in the stored export's artifacts, not in the snapshot" for f in sorted(set(arts) - set(refs))]
    out += [f"{sid}: `{f}` has another digest in the snapshot than in the stored export"
            for f in sorted(set(refs) & set(arts)) if refs[f] != arts[f]]
    listed = raw["handoff/files.txt"].decode("utf-8", "replace").splitlines()
    expected = sorted(arts) + [(run_rel / n).as_posix() for n in CONTROL]
    if sorted(listed) != sorted(expected):
        extra, missing = sorted(set(listed) - set(expected)), sorted(set(expected) - set(listed))
        out.append(f"{sid}: the stored files.txt does not list the export's artifacts and its two handoff files"
                   + (f" (extra: {', '.join(extra[:8])})" if extra else "") + (f" (missing: {', '.join(missing[:8])})" if missing else "")
                   + (" (a path listed twice)" if not extra and not missing else ""))
    return out


def verify(run_id: str, stage_id: str | None = None) -> list[str]:
    """Why the snapshot of `stage_id` (every closed stage when None) is not whole; [] when it is.

    For each snapshot: the union of `files` and `history` is the stored export's `artifacts`, with
    the same digests, both ways (each path missing or extra on either side is named); `files` and
    `history` share no path; `history` holds only stage machinery files and `files` none; the stored
    `files.txt` lists the artifacts and the two handoff files; every blob it names is there and
    hashes to its name. With None, every blob of the store hashes to its name too."""
    ids = _stage_ids(run_id) if stage_id is None else [stage_id]
    out = [x for sid in ids for x in _problems(run_id, sid)]
    if stage_id is None and _blobs(run_id).is_dir():
        out += [f"blob {p.name} does not hash to its name" for p in sorted(_blobs(run_id).iterdir())
                if p.is_file() and not p.name.startswith(".") and _sha(p) != p.name]
    return out


def _git(into: Path, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["git", "-C", str(into), *args], capture_output=True)


def _code_digest_at(into: Path) -> dict:
    """`handoff.code_digest` computed over the checkout at `into`, every file read from that checkout:
    the doctor's split tool too, at its place beside the agent directory in the repository layout
    (`handoff.DOCTOR_TOOL`), never the copy this process would import; absent there, it is recorded
    as None."""
    from ..tools import handoff
    found = set()
    for pat in handoff.CODE_PATTERNS:
        found |= {p for p in into.glob(pat) if p.is_file() and "__pycache__" not in p.parts}
    files = {p.relative_to(into).as_posix(): _sha(p) for p in sorted(found)}
    tool = (into / handoff.DOCTOR_TOOL).resolve()
    files[handoff.DOCTOR_TOOL] = _sha(tool) if tool.is_file() else None
    return {"files": files, "digest": hashlib.sha256(json.dumps(files, sort_keys=True).encode()).hexdigest()}


def restore(run_id: str, stage_id: str, into: Path) -> None:
    """Restore the run as stage `stage_id`'s last export left it into the clean checkout `into`.

    `into` is the agent directory of a git checkout whose HEAD is the snapshot's baseline commit,
    whose working tree is clean, whose code is the baseline's, which has no directory of the run and
    no untracked file at a path of the snapshot (a path the commit itself tracks, such as a library
    record, is the baseline's and is replaced). Every file of `files` and `history` is written to its
    path and checked, then the two handoff files' bytes; never this machine's import record. Every
    condition is checked before the first write."""
    into = Path(into).resolve()
    why = verify(run_id, stage_id)
    if why:
        raise _refuse(f"the snapshot of stage `{stage_id}` of `{run_id}` is not whole: " + "; ".join(why[:8]))
    s = jsonl.read_json(_manifest_file(run_id, stage_id), None)
    base = s.get("baseline") or {}
    commit, digest = base.get("source_commit"), (base.get("code") or {}).get("digest")
    if not commit:
        raise _refuse(f"the snapshot of stage `{stage_id}` records no baseline commit to restore into")
    head = _git(into, "rev-parse", "HEAD") if into.is_dir() else None
    if head is None or head.returncode != 0:
        raise _refuse(f"`{into}` is not a git checkout")
    want = _git(into, "rev-parse", "--verify", "--quiet", f"{commit}^{{commit}}")
    if want.returncode != 0 or head.stdout.strip() != want.stdout.strip():
        raise _refuse(f"`{into}` is at {head.stdout.decode().strip()}, not at the stage's baseline commit {commit}")
    dirty = _git(into, "status", "--porcelain", "--untracked-files=all")
    if dirty.returncode != 0 or dirty.stdout.strip():
        raise _refuse(f"`{into}`'s working tree is not clean")
    run_rel = _run_rel(run_id)
    if (into / run_rel).exists():
        raise _refuse(f"`{into}` already holds the run's directory `{run_rel.as_posix()}`")
    tracked = set(_git(into, "ls-files", "-z").stdout.decode("utf-8", "replace").split("\0"))
    targets = {**s["files"], **s["history"]}
    present = sorted(f for f in targets if (into / f).exists() and f not in tracked)
    if present:
        raise _refuse(f"`{into}` already holds file(s) of the snapshot: {', '.join(present[:8])}")
    code = _code_digest_at(into)
    if code["digest"] != digest:
        was = (base.get("code") or {}).get("files") or {}
        diff = sorted(k for k in set(was) | set(code["files"]) if was.get(k) != code["files"].get(k))
        raise _refuse(f"the code at `{into}` differs from the stage's baseline ({len(diff)} file(s): {', '.join(diff[:8])})")
    bd = _blobs(run_id)
    for f, h in sorted(targets.items()):
        _write_bytes(into / f, (bd / h).read_bytes())
        if _sha(into / f) != h:
            raise SystemExit(f"[stage] `{into / f}` does not hold the snapshot's content after it was written")
    for n in CONTROL:
        h = s["control"][n]["sha256"]
        _write_bytes(into / run_rel / n, (bd / h).read_bytes())
        if _sha(into / run_rel / n) != h:
            raise SystemExit(f"[stage] `{into / run_rel / n}` does not hold the snapshot's content after it was written")
