"""The gap ledger: what the ontology cannot carry, proposed by plan and repair sessions, decided
by the operator. It lives beside the rules and concepts (`library/TrafficSpec/Gaps/`) as two
append-only files with one writer each:
- `proposals.jsonl`: the harness appends a proposal; it never writes a decision field;
- `decisions.jsonl`: only the operator's command (`python -m harness gap ...`) appends a decision.
A gap's state is its proposal plus its latest decision, so a decision made at any moment is never
lost to a harness write. Ids come from `counter.txt`, which only grows, so an archived gap's id is
never reused.

A gap names a deficiency of the pipeline, and a round (one run, its resumes included) ends with
every gap it filed resolved: `retired` names the revision that now carries the span
(`retired_by`), `rejected` names where the decision now lives in the pipeline, or `particular`
(`resolved_by`). A new run starts only on a ledger without an open gap (`proposed`, `accepted`);
at that start every resolved gap leaves the library for `results/<the run that proposed it>/gaps.jsonl`,
its decisions with it, so the new round starts on an empty ledger, and a gap that comes back is a
new gap. A record that cites a rejected gap still reads it there, from its run and its base chain.
A run's view also holds the pending gaps the operator carried over from an earlier run and the run
fixed at its start (`deferred_gaps`): each is a context row under its source identity until the run
files it as a live gap (`deferred_from`), which stands for it from then on, decided or not; a new
round does not start while a live gap so filed is rejected or retired and the declaration still stands.
Each run also keeps, append-only, every gap it filed as filed (`results/<run>/gaps_measured.jsonl`):
what a test run found, which no later decision or archive changes."""
from __future__ import annotations
import json
import re
from pathlib import Path
from . import jsonl

DECISION_STATES = ("accepted", "rejected", "retired")
OPEN_STATES = ("proposed", "accepted")
_PROPOSED_IN = re.compile(r"^([A-Za-z0-9_.-]+)/iter-\d{3}$")


class OpenGaps(SystemExit):
    """A new round cannot start: gaps of the last one are not resolved, or cannot be archived."""


class GapLedger:
    def __init__(self, directory: Path, archives: tuple[Path, ...] = (), context: tuple[dict, ...] = ()):
        self.dir = directory
        self.proposals_file = directory / "proposals.jsonl"
        self.decisions_file = directory / "decisions.jsonl"
        self.counter = directory / "counter.txt"
        #: the archived gaps a record of this run may cite: its own run's and its base chain's
        self.archives = tuple(archives)
        #: the pending gaps carried over from an earlier run that the run fixed (`deferred_gaps.context_row`)
        self.context = tuple(context)

    @classmethod
    def for_run(cls, directory: Path, run) -> "GapLedger":
        """The ledger as a run's records read it: the live rows, the archived gaps of the run and of
        its base chain, and the pending gaps carried over from an earlier run that the run fixed at
        its start, checked whole against its saved inputs (`deferred_gaps.fixed`): a changed or
        missing copy stops the reader."""
        from . import paths, deferred_gaps
        if run is None:
            return cls(directory)
        ids = [run.opts.run_id] + list(getattr(run, "base_chain", []) or [])
        return cls(directory, tuple(paths.run_dir(r) / "gaps.jsonl" for r in ids),
                   tuple(deferred_gaps.context_row(d) for d in deferred_gaps.fixed(run.opts)))

    @property
    def rows(self) -> list[dict]:
        """Every gap: the live ones (`live_rows`), then each carried-over pending gap (`context`) for
        which no live gap of this ledger or of its archives was filed (`deferred_from`, on the same
        source identity and occurrence): a live gap so filed, and its decision, stand for it."""
        live = self.live_rows()
        if not self.context:
            return live
        from .deferred_gaps import key
        filed = {key(r) for r in live + self.archived_rows() if isinstance(r.get("deferred_from"), dict)}
        return live + [dict(c) for c in self.context if key({"deferred_from": c["deferred"], "occurrence": c["occurrence"]}) not in filed]

    def live_rows(self) -> list[dict]:
        """Every gap of the live ledger: its proposal with its latest decision applied (`state` `proposed` when undecided)."""
        latest: dict[str, dict] = {}
        for d in jsonl.read_strict(self.decisions_file):
            latest[d["id"]] = d
        out = []
        for p in jsonl.read_strict(self.proposals_file):
            d = latest.get(p["id"], {})
            out.append({**p, "state": d.get("state", "proposed"), "decision": d.get("decision", ""), "retired_by": d.get("retired_by", ""),
                        "resolved_by": d.get("resolved_by", "")})
        return out

    def archived_rows(self) -> list[dict]:
        """The archived gaps of the runs this ledger was opened for."""
        return [r for f in self.archives for r in jsonl.read_strict(f)]

    def _numbers(self) -> list[int]:
        return [int(r["id"][1:]) for r in jsonl.read_strict(self.proposals_file) if str(r.get("id", "")).startswith("G") and str(r["id"])[1:].isdigit()]

    def _counter(self) -> int:
        try:
            return int(self.counter.read_text(encoding="utf-8").strip() or 0) if self.counter.exists() else 0
        except ValueError:
            return 0

    def next_id(self) -> str:
        """The next id: past every id proposed and past the counter, which remembers archived ids."""
        return f"G{max(self._counter(), max(self._numbers(), default=0) + 1, 1)}"

    def match(self, proposal: dict) -> dict | None:
        """The existing gap of the same kind on the same occurrence of the law's words (`occurrence`:
        the law, its content digest and the characters; the same words twice in a law are two
        occurrences), or, for a row recorded without one, on the same words of the same laws."""
        span = proposal.get("span_text") or proposal.get("span")
        for r in self.rows:
            if r.get("kind") != proposal.get("kind"):
                continue
            if r.get("occurrence") and proposal.get("occurrence"):
                if r["occurrence"] == proposal["occurrence"]:
                    return r
            elif r.get("span") == span and set(r.get("law_refs", [])) == set(proposal.get("law_refs", [])):
                return r
        return None

    def add(self, proposal: dict, run: str, iteration: int) -> str:
        """The gap's id: an undecided match is the same gap; a decided match is returned as it is (the
        caller routes the recurrence back with that decision, never as a new pending one). A proposal
        that cites the decided gap it follows (`linked_to`) and names the contract clause that still
        excludes the span (`excluding_clause`) is a linked new proposal, for the operator to judge. A
        match on a carried-over pending gap files a live gap on its occurrence, recording its source
        (`deferred_from`); from then on that live gap is the match."""
        m = self.match(proposal)
        linked = proposal.get("linked_to") if proposal.get("excluding_clause") else None
        carried = m.get("deferred") if m is not None and isinstance(m.get("deferred"), dict) else None
        if m is not None and carried is None and not (linked and linked == m["id"] and m["state"] in ("rejected", "retired")):
            if str(m.get("proposed_in", "")).startswith(f"{run}/"):
                self._measure(m, run)                      # a filing cut off before its measurement is completed here
            return m["id"]
        gid = self.next_id()
        row = {"id": gid, "kind": proposal.get("kind"), "span": proposal.get("span_text") or proposal.get("span"),
               "law_refs": proposal.get("law_refs", []), "node_id": proposal.get("node_id"),
               "proposal": proposal.get("proposal", ""), "nearest": proposal.get("nearest", []),
               "proposed_in": f"{run}/iter-{iteration:03d}", **({"occurrence": proposal["occurrence"]} if proposal.get("occurrence") else {})}
        if carried:
            row.update({"occurrence": m["occurrence"], "deferred_from": dict(carried)})
        elif linked:
            row.update({"linked_to": linked, "excluding_clause": proposal.get("excluding_clause")})
        jsonl.append_atomic(self.proposals_file, row)
        jsonl.write_atomic(self.counter, str(int(gid[1:]) + 1) + "\n")
        self._measure(row, run)
        return gid

    @staticmethod
    def _measure(row: dict, run: str) -> None:
        """Record a gap this run filed, as filed, once (`results/<run>/gaps_measured.jsonl`)."""
        from . import paths
        f = paths.run_dir(run) / "gaps_measured.jsonl"
        if row["id"] not in {r.get("id") for r in jsonl.read_strict(f)}:
            proposal = {k: v for k, v in row.items() if k not in ("state", "decision", "retired_by", "resolved_by")}
            jsonl.append_atomic(f, proposal)

    def decide(self, gid: str, state: str, decision: str, retired_by: str = "", resolved_by: str = "") -> None:
        """The operator's decision on a gap (appended; the latest one stands). A retirement names the
        revision that carries the span (`retired_by`); a rejection names where the decision now lives
        in the pipeline, or `particular` (`resolved_by`)."""
        if state not in DECISION_STATES:
            raise SystemExit(f"a decision is one of {DECISION_STATES}")
        if gid not in {r["id"] for r in self.live_rows()} and ":" in gid:
            alias = [r["id"] for r in self.live_rows() if isinstance(r.get("deferred_from"), dict)
                     and f"{r['deferred_from'].get('source_run')}:{r['deferred_from'].get('source_id')}" == gid]
            raise SystemExit(f"{gid} names a pending gap carried over from an earlier run, not a gap of this ledger: "
                             + (f"decide its live gap {', '.join(alias)}" if alias else
                                "no run has filed it yet; decide the live gap a run files for it (`deferred_from`)"))
        if gid not in {r["id"] for r in self.live_rows()}:
            raise SystemExit(f"no gap {gid}")
        if state == "retired" and not retired_by.strip():
            raise SystemExit("a retirement names the revision that now carries the span: --retired_by \"<revision>\"")
        if state == "rejected" and not resolved_by.strip():
            raise SystemExit("a rejection names where its decision now lives in the pipeline, or `particular`: --resolved_by \"<place>\"")
        jsonl.append_atomic(self.decisions_file, {"id": gid, "state": state, "decision": decision, "retired_by": retired_by,
                                                  **({"resolved_by": resolved_by} if resolved_by else {})})

    def decision(self, gid: str) -> tuple[str, str] | None:
        """The operator's decision on a gap (state, words), or None while it is undecided."""
        r = next((r for r in self.rows if r["id"] == gid), None)
        return (r["state"], str(r.get("decision", ""))) if r and r["state"] != "proposed" else None

    def decided(self) -> dict[str, tuple[str, str]]:
        """Gaps the operator has closed, retired or rejected, with the decision's words."""
        return {r["id"]: (r["state"], str(r.get("decision", ""))) for r in self.rows if r.get("state") in ("retired", "rejected")}

    def rejected(self) -> dict[str, dict]:
        """Each rejected gap, as a cited narrowing is checked and shown against it: the laws it was
        filed on, the occurrence of its words (`<law>@<digest>:<start>-<end>`, absent on older rows),
        its words, and the operator's decision."""
        return {r["id"]: {"laws": set(r.get("law_refs", [])), "occurrence": r.get("occurrence"), "span": r.get("span", ""),
                          "decision": str(r.get("decision", ""))} for r in self.archived_rows() + self.rows if r.get("state") == "rejected"}

    def cited_block(self, record: dict) -> str:
        """The operator's decisions a record's narrowings cite (`gap`), for every session that reads the
        record: each gap's decision in the operator's words and the words it was filed on. Empty when
        the record cites none. A decision settles only those words."""
        rejected = self.rejected()
        cited = sorted({n.get("gap") for n in record.get("narrowings") or [] if isinstance(n, dict) and isinstance(n.get("gap"), str)})
        if not cited:
            return ""
        out = ["### The operator's decisions this record follows", "",
               "A narrowing that names a gap carries its span as the operator decided that gap. The decision settles "
               "only the distinction it names, on the words it was filed on; every other distinction of those words is "
               "judged as usual.", ""]
        for gid in cited:
            r = rejected.get(gid)
            if r is None:
                out.append(f"- `{gid}`: no rejected gap of the ledger has this id; the record cites no decision")
                continue
            where = f" ({r['occurrence']})" if r.get("occurrence") else ""
            out.append(f"- `{gid}`, filed on the words \u201c{r['span']}\u201d{where}: {r['decision']}")
        return "\n".join(out) + "\n"

    def open_rows(self) -> list[dict]:
        """The live gaps not yet resolved: `proposed`, or `accepted` and not yet carried."""
        return [r for r in self.live_rows() if r["state"] in OPEN_STATES]

    def start_round(self, results: Path, manifest: dict[str, str] | None = None) -> list[tuple[str, str]]:
        """The gate of a new round: refuses while a gap is open; else moves every resolved gap to
        `results/<the run that proposed it>/gaps.jsonl` (`manifest` names the run of a row whose
        `proposed_in` does not), with its proposal, its latest state and every decision, and only
        after every archive is written and read back equal clears the live rows. A gap already in
        its archive with the same content is not written again; with other content the round does
        not start. Returns (gap id, run) for every gap moved. Before anything else, a live gap filed for
        a carried-over pending gap (`deferred_from`) that is rejected or retired while the declarations
        still declare it stops the round: the declaration is removed first."""
        if any(isinstance(r.get("deferred_from"), dict) for r in self.live_rows()):
            from . import deferred_gaps
            stale = deferred_gaps.conflicts(self.live_rows(), deferred_gaps.load())
            if stale:
                raise OpenGaps("a new round does not start while a declaration of a carried-over gap stands after its live gap was "
                               "decided: " + "; ".join(stale))
        open_ = self.open_rows()
        if open_:
            raise OpenGaps("a new round starts only when every gap of the last one is resolved: "
                           + "; ".join(f"{r['id']} ({r['state']}): {str(r.get('span', ''))[:60]}" for r in open_)
                           + " — decide each with `python -m harness gap decide`")
        decisions: dict[str, list[dict]] = {}
        for d in jsonl.read_strict(self.decisions_file):
            decisions.setdefault(d["id"], []).append(d)
        manifest = manifest or {}
        moves, missing = [], []
        for r in self.live_rows():
            m = _PROPOSED_IN.match(str(r.get("proposed_in", "")))
            run = manifest.get(r["id"]) or (m.group(1) if m else None)
            if not run or not (results / run).is_dir():
                missing.append(r["id"]); continue
            moves.append((run, {**r, "decisions": decisions.get(r["id"], [])}))
        if missing:
            raise OpenGaps(f"gap(s) {missing} name no run whose results directory exists: give their runs in a manifest "
                           "(`python -m harness gap archive --manifest <file.json>`, {\"<gap id>\": \"<run>\"})")
        by_file: dict[Path, list[dict]] = {}
        for run, row in moves:
            by_file.setdefault(results / run / "gaps.jsonl", []).append(row)
        for f, rows in by_file.items():                       # every conflict is found before anything is written
            kept = {k["id"]: k for k in jsonl.read_strict(f)}
            clash = [r["id"] for r in rows if r["id"] in kept and kept[r["id"]] != json.loads(json.dumps(r))]
            if clash:
                raise OpenGaps(f"{f} already holds gap(s) {clash} with other content; the round does not start")
        for f, rows in by_file.items():
            kept = {k["id"] for k in jsonl.read_strict(f)}
            for r in rows:
                if r["id"] not in kept:
                    jsonl.append_atomic(f, r)
        for f, rows in by_file.items():                       # read back before the live rows go
            kept = {k["id"]: k for k in jsonl.read_strict(f)}
            if any(kept.get(r["id"]) != json.loads(json.dumps(r)) for r in rows):
                raise OpenGaps(f"{f} does not read back as written; the live ledger is left as it is")
        top = max([self._counter()] + [n + 1 for n in self._numbers()])
        jsonl.write_atomic(self.counter, f"{top}\n")
        jsonl.write_rows(self.proposals_file, [])
        jsonl.write_rows(self.decisions_file, [])
        return [(r[1]["id"], r[0]) for r in moves]

    def visible(self, law_ids: set[str], base_run: str | None = None) -> list[dict]:
        """The rows a run may be shown: gaps on a law of its corpus, and gaps its base run proposed.
        A gap on a law outside the corpus (another split's) never reaches its plan."""
        base = f"{base_run}/" if base_run else None
        return [r for r in self.rows if set(r.get("law_refs", [])) & law_ids
                or (base and str(r.get("proposed_in", "")).startswith(base))]

    def render(self, law_ids: set[str] | None = None, base_run: str | None = None) -> str:
        """The ledger as a table; with `law_ids`, only the rows `visible` to that corpus."""
        rows = self.rows
        if not rows:
            return "(no gaps recorded)\n"
        if law_ids is not None:
            rows = self.visible(law_ids, base_run)
        if not rows:
            return "(no gaps recorded on the laws of this corpus)\n"
        out = ["| id | state | kind | span | proposal | decision |", "|---|---|---|---|---|---|"]
        for r in rows:
            src = r.get("deferred") or r.get("deferred_from")
            note = (("carried over pending" if r.get("deferred") else "filed for the gap carried over")
                    + f" from run {src.get('source_run')} (its {src.get('source_id')}, commit {str(src.get('source_commit'))[:12]}) "
                    f"on {r.get('occurrence')}") if isinstance(src, dict) else ""
            decision = "; ".join(x for x in (r.get("decision", ""), note) if x)
            out.append(f"| {r['id']} | {r['state']} | {r.get('kind')} | {r.get('span', '')[:80]} | {str(r.get('proposal', ''))[:120]} | {decision} |")
        return "\n".join(out) + "\n"
