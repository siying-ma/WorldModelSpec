"""The gap ledger: what the ontology cannot carry, proposed by plan and repair sessions, decided
by the operator. It lives beside the rules and concepts (`library/TrafficSpec/Gaps/`) as two
append-only files with one writer each:
- `proposals.jsonl`: the harness appends a proposal; it never writes a decision field;
- `decisions.jsonl`: only the operator's command (`python -m harness gap ...`) appends a decision.
A gap's state is its proposal plus its latest decision, so a decision made at any moment is never
lost to a harness write. Ids come from `counter.txt`, which only grows, so an archived gap's id is
never reused."""
from __future__ import annotations
from pathlib import Path
from . import jsonl

DECISION_STATES = ("accepted", "rejected", "retired")


class GapLedger:
    def __init__(self, directory: Path):
        self.dir = directory
        self.proposals_file = directory / "proposals.jsonl"
        self.decisions_file = directory / "decisions.jsonl"
        self.counter = directory / "counter.txt"

    @property
    def rows(self) -> list[dict]:
        """Every gap: its proposal with its latest decision applied (`state` `proposed` when undecided)."""
        latest: dict[str, dict] = {}
        for d in jsonl.read_strict(self.decisions_file):
            latest[d["id"]] = d
        out = []
        for p in jsonl.read_strict(self.proposals_file):
            d = latest.get(p["id"], {})
            out.append({**p, "state": d.get("state", "proposed"), "decision": d.get("decision", ""), "retired_by": d.get("retired_by", "")})
        return out

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
        excludes the span (`excluding_clause`) is a linked new proposal, for the operator to judge."""
        m = self.match(proposal)
        linked = proposal.get("linked_to") if proposal.get("excluding_clause") else None
        if m is not None and not (linked and linked == m["id"] and m["state"] in ("rejected", "retired")):
            return m["id"]
        gid = self.next_id()
        row = {"id": gid, "kind": proposal.get("kind"), "span": proposal.get("span_text") or proposal.get("span"),
               "law_refs": proposal.get("law_refs", []), "node_id": proposal.get("node_id"),
               "proposal": proposal.get("proposal", ""), "nearest": proposal.get("nearest", []),
               "proposed_in": f"{run}/iter-{iteration:03d}", **({"occurrence": proposal["occurrence"]} if proposal.get("occurrence") else {})}
        if linked:
            row.update({"linked_to": linked, "excluding_clause": proposal.get("excluding_clause")})
        jsonl.append_atomic(self.proposals_file, row)
        jsonl.write_atomic(self.counter, str(int(gid[1:]) + 1) + "\n")
        return gid

    def decide(self, gid: str, state: str, decision: str, retired_by: str = "") -> None:
        """The operator's decision on a gap (appended; the latest one stands)."""
        if state not in DECISION_STATES:
            raise SystemExit(f"a decision is one of {DECISION_STATES}")
        if gid not in {r["id"] for r in self.rows}:
            raise SystemExit(f"no gap {gid}")
        jsonl.append_atomic(self.decisions_file, {"id": gid, "state": state, "decision": decision, "retired_by": retired_by})

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
                          "decision": str(r.get("decision", ""))} for r in self.rows if r.get("state") == "rejected"}

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

    def remove_undecided(self) -> list[dict]:
        """The operator's archive of a fresh library: the proposals still undecided (or accepted) leave
        the ledger; the decided ones stay, with their decisions. Returns the rows removed."""
        rows = self.rows
        gone = [r for r in rows if r["state"] in ("proposed", "accepted")]
        if gone:
            ids = {r["id"] for r in gone}
            keep = [p for p in jsonl.read_strict(self.proposals_file) if p["id"] not in ids]
            jsonl.write_rows(self.proposals_file, keep)
            jsonl.write_rows(self.decisions_file, [d for d in jsonl.read_strict(self.decisions_file) if d["id"] not in ids])
        return gone

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
            out.append(f"| {r['id']} | {r['state']} | {r.get('kind')} | {r.get('span', '')[:80]} | {str(r.get('proposal', ''))[:120]} | {r.get('decision', '')} |")
        return "\n".join(out) + "\n"
