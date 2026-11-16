"""Pending gaps the operator carries over from an earlier run: `config/deferred_gaps.jsonl`, a
versioned list the operator owns. Each row binds one gap of an earlier run's ledger, as it stood
undecided at a fixed commit: the source commit, run and gap id, the law and its content digest, the
occurrence of the words in the law (`<law>@<digest>:<start>-<end>`), the words themselves, the gap's
kind, proposal and state there. The file must exist; an empty list is an empty file.

A new run binds every row whose law is in its corpus to the corpus as it is (the law's digest and
the words at the occurrence), refuses to start on a row that no longer matches (it needs
re-binding), and fixes into its own directory the list's text and the rows it bound. From then on
the run reads only its fixed copy, and every read checks it whole against the run's saved inputs:
the list's text must have the digest the run's recorded semantic inputs hold (never a digest the
copy states about itself), and the rows must be exactly that list's rows of the run's corpus laws.
Every gap view of the run shows each row as a pending context row under its source identity
(`<source run>:<source id>`), which no live id (`G<n>`) can equal, until the run files the gap
itself. A live gap filed on a context row records where it came from (`deferred_from`), and it and
its decision stand for the row from then on.

A declaration is withdrawn by the operator removing its row in a later baseline, once the live gap
filed for it is rejected or retired. A live gap so decided while the list still declares the same
source identity and occurrence is a conflict, which the start of a new gap round refuses."""
from __future__ import annotations
import hashlib
import json
import re
from pathlib import Path
from . import jsonl

DECLARATIONS = Path(__file__).resolve().parents[2] / "config" / "deferred_gaps.jsonl"
FIXED = "deferred_gaps.json"
FIELDS = ("source_commit", "source_run", "source_id", "law", "law_digest", "occurrence", "span", "kind", "proposal", "source_state")
#: the states of a source gap that leave it pending: undecided, or accepted and not yet carried
PENDING_STATES = ("proposed", "accepted")
_OCCURRENCE = re.compile(r"^(?P<law>.+)@(?P<digest>[0-9a-f]+):(?P<start>\d+)-(?P<end>\d+)$")


class DeclarationError(SystemExit):
    """The declarations cannot be read whole, or a row no longer matches the corpus it is bound to."""


def identity(row: dict) -> str:
    """A declaration's source identity, `<source run>:<source id>`: never a live gap id."""
    return f"{row['source_run']}:{row['source_id']}"


def key(row: dict) -> tuple[str, str, str]:
    """What a declaration and the live gap filed for it share: the source run, the source id and the occurrence."""
    src = row.get("deferred_from") or row
    return str(src.get("source_run")), str(src.get("source_id")), str(row.get("occurrence"))


def row_defects(row) -> list[str]:
    """Why a row is not a declaration: not an object, a field missing or not a non-empty string, an
    occurrence that does not name its law and digest, or a source state that is not pending."""
    if not isinstance(row, dict):
        return ["it is not an object"]
    out = [f"`{k}` is missing or not a non-empty string" for k in FIELDS if not isinstance(row.get(k), str) or not row[k].strip()]
    if out:
        return out
    m = _OCCURRENCE.match(row["occurrence"])
    if not m or m["law"] != row["law"] or m["digest"] != row["law_digest"] or int(m["start"]) >= int(m["end"]):
        out.append(f"its occurrence {row['occurrence']!r} is not `{row['law']}@{row['law_digest']}:<start>-<end>`")
    if row["source_state"] not in PENDING_STATES:
        out.append(f"its source state is {row['source_state']!r}: only a pending gap ({', '.join(PENDING_STATES)}) is declared")
    if ":" in row["source_run"]:
        out.append("its source run contains `:`")
    return out


def load(path: Path | None = None) -> list[dict]:
    """The declarations, read whole: a missing or unreadable file, a row that is no declaration, or
    two rows with one source identity or one occurrence stop the caller, never read as an empty list."""
    path = Path(path or DECLARATIONS)
    if not path.is_file():
        raise DeclarationError(f"the deferred gap declarations {path} are missing: the file is required (an empty file declares none)")
    try:
        rows = jsonl.read_strict(path)
    except Exception as e:                                # noqa: BLE001  (any unreadable line)
        raise DeclarationError(f"the deferred gap declarations {path} cannot be read: {e}") from e
    bad = [f"row {i}: " + "; ".join(d) for i, r in enumerate(rows, 1) if (d := row_defects(r))]
    seen_id, seen_at = {}, {}
    for i, r in enumerate(rows, 1):
        if row_defects(r):
            continue
        for seen, k, what in ((seen_id, identity(r), "source identity"), (seen_at, (r["occurrence"], r["kind"]), "occurrence and kind")):
            if k in seen:
                bad.append(f"rows {seen[k]} and {i} declare one {what} {k}")
            seen[k] = i
    if bad:
        raise DeclarationError(f"the deferred gap declarations {path} are not usable: " + "; ".join(bad[:6]))
    return rows


def digest(path: Path | None = None) -> str:
    """The digest of the declarations file, after it is read whole (`load`)."""
    path = Path(path or DECLARATIONS)
    load(path)
    return _digest(path.read_bytes())


def _digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()[:24]


def binding_defects(row: dict, text: str | None) -> list[str]:
    """Why a declaration does not match its law's current text: the law is not given, its content
    digest differs, or the characters of the occurrence are not the declared words."""
    if text is None:
        return [f"`{row['law']}` is not in the corpus"]
    from ..phases.review import law_digest
    if law_digest(text) != row["law_digest"]:
        return [f"`{row['law']}`'s text has digest {law_digest(text)}, not the declared {row['law_digest']}"]
    m = _OCCURRENCE.match(row["occurrence"])
    words = text[int(m["start"]):int(m["end"])]
    if words != row["span"]:
        return [f"the characters {m['start']}–{m['end']} of `{row['law']}` read {words!r}, not the declared {row['span']!r}"]
    return []


def bind(rows: list[dict], texts: dict[str, str]) -> list[dict]:
    """The declarations of the laws in `texts` (law id ↦ text), each checked against its law: one
    that does not match stops the start, naming every row that needs re-binding."""
    bound, bad = [], []
    for r in rows:
        if r["law"] not in texts:
            continue
        d = binding_defects(r, texts[r["law"]])
        if d:
            bad.append(f"{identity(r)} ({r['occurrence']}): " + "; ".join(d))
        bound.append(r)
    if bad:
        raise DeclarationError("deferred gap declaration(s) no longer match the corpus and need re-binding "
                               "(export them again from their source, or remove them): " + "; ".join(bad))
    return bound


def fix(run_dir: Path, rows: list[dict], list_digest: str) -> None:
    """Fix a new run's bound declarations into its directory, with the text and the digest of the list
    they come from: the list as its saved inputs record it (`list_digest`), or the start stops."""
    data = Path(DECLARATIONS).read_bytes()
    if _digest(data) != list_digest:
        raise DeclarationError(f"the deferred gap declarations {DECLARATIONS} changed while the run started: start it again")
    jsonl.write_atomic(Path(run_dir) / FIXED, json.dumps({"digest": list_digest, "list": data.decode("utf-8"), "rows": rows},
                                                         ensure_ascii=False, indent=1) + "\n")


def recorded_digest(run_dir: Path) -> str | None:
    """The digest of the list a run's saved inputs record: its active stage's semantic inputs, or for a
    run without a stage record those of its `options.json`. A run with a fixed copy, or with a digest
    in either saved record, must have a non-empty digest in every applicable record, and the records
    must agree. Only a run without any such evidence is read as a legacy run carrying no rows."""
    from . import stages
    run_dir = Path(run_dir)
    stage = stages.active_stage(run_dir)
    options = jsonl.read_json(run_dir / "options.json", None) or {}
    records = [("options.json", options.get("semantic") or {})]
    if stage is not None:
        records.append(("active stage", stage.get("semantic") or {}))
    for name, sem in records:
        if not isinstance(sem, dict):
            raise DeclarationError(f"{run_dir}: {name} has unreadable saved inputs for deferred gaps")
    enabled = (run_dir / FIXED).exists() or any("deferred_gaps" in sem for _, sem in records)
    if not enabled:
        return None
    for name, sem in records:
        value = sem.get("deferred_gaps")
        if not isinstance(value, str) or not value.strip():
            raise DeclarationError(f"{run_dir}: {name} is missing the saved deferred_gaps digest: restore the run's checkpoint")
    digests = {sem["deferred_gaps"] for _, sem in records}
    if len(digests) != 1:
        raise DeclarationError(f"{run_dir}: the saved deferred_gaps digests disagree between options and the active stage")
    return digests.pop()


def fixed_refusal(run_dir: Path, list_digest: str | None, law_ids) -> str | None:
    """Why a run's fixed declarations cannot be read as the ones its start fixed: the file is missing
    or unreadable, its list's text does not have the digest the run's saved inputs record
    (`list_digest`), or its rows are not exactly that list's rows of the run's corpus laws (`law_ids`)."""
    f = Path(run_dir) / FIXED
    if not f.is_file():
        return f"its fixed deferred gap declarations {f} are missing"
    try:
        d = json.loads(f.read_text(encoding="utf-8"))
    except (OSError, ValueError) as e:
        return f"its fixed deferred gap declarations {f} cannot be read ({type(e).__name__})"
    if not isinstance(d, dict) or not isinstance(d.get("list"), str) or not isinstance(d.get("rows"), list):
        return f"its fixed deferred gap declarations {f} are not whole (a list text and its bound rows)"
    if list_digest is None or _digest(d["list"].encode("utf-8")) != list_digest or d.get("digest") != list_digest:
        return f"its fixed deferred gap declarations {f} are not those of the list its saved inputs record"
    ids = set(law_ids)
    if d["rows"] != [r for r in (json.loads(x) for x in d["list"].splitlines() if x.strip()) if r["law"] in ids]:
        return f"its fixed deferred gap declarations {f} hold other rows than that list binds to the run's corpus"
    return None


def fixed(opts) -> list[dict]:
    """The declarations the run of `opts` fixed at its start, checked whole (`fixed_refusal`) against the
    digest its saved inputs record and its corpus (`opts.laws`): a copy that is missing, unreadable or
    changed stops the reader, never read as no declarations. None for a run whose saved inputs record
    no list (`recorded_digest`)."""
    from . import paths
    from ..model import corpus
    run_id = opts.run_id
    rd = paths.run_dir(run_id)
    recorded = recorded_digest(rd)
    if recorded is None:
        return []
    why = fixed_refusal(rd, recorded, [l.id for l in corpus.load_laws(Path(opts.laws))])
    if why:
        raise DeclarationError(f"run `{run_id}`'s gap view cannot be read: {why} — restore the run's checkpoint, or start a new run id")
    return list(json.loads((rd / FIXED).read_text(encoding="utf-8"))["rows"])


def context_row(row: dict) -> dict:
    """A declaration as a gap view shows it: pending, under its source identity, with its source."""
    return {"id": identity(row), "kind": row["kind"], "span": row["span"], "law_refs": [row["law"]], "occurrence": row["occurrence"],
            "proposal": row["proposal"], "nearest": [], "state": "proposed", "decision": "", "retired_by": "", "resolved_by": "",
            "deferred": {"source_run": row["source_run"], "source_id": row["source_id"], "source_commit": row["source_commit"]}}


def conflicts(live_rows: list[dict], declarations: list[dict]) -> list[str]:
    """Each live gap filed for a declaration (`deferred_from`) that the operator rejected or retired
    while the list still declares the same source identity and occurrence."""
    declared = {key(d): d for d in declarations}
    return [f"{r['id']} ({r['state']}) was filed for {identity(declared[key(r)])} on {r['occurrence']}, which "
            f"{DECLARATIONS.name} still declares pending: remove that row in the next baseline"
            for r in live_rows if isinstance(r.get("deferred_from"), dict) and r.get("state") in ("rejected", "retired") and key(r) in declared]
