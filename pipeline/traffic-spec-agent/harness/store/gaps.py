"""The gap ledger: what the ontology cannot carry, proposed by plan and repair sessions, decided
by the operator. It lives beside the rules and concepts (`library/TrafficSpec/Gaps/`); ids come
from a counter beside it that only grows, so an archived gap's id is never reused; nothing but
the harness writes either file."""
from __future__ import annotations
import json
from pathlib import Path

class GapLedger:
    def __init__(self, path: Path):
        self.path = path
        self.counter = path.with_name("counter.txt")
        self.rows: list[dict] = []
        if path.exists():
            self.rows = [json.loads(l) for l in path.read_text(encoding="utf-8").splitlines() if l.strip()]

    def _numbers(self) -> list[int]:
        return [int(r["id"][1:]) for r in self.rows if str(r.get("id", "")).startswith("G") and str(r["id"])[1:].isdigit()]

    def _counter(self) -> int:
        try:
            return int(self.counter.read_text(encoding="utf-8").strip() or 0) if self.counter.exists() else 0
        except ValueError:
            return 0

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in self.rows), encoding="utf-8")
        self.counter.write_text(str(max(self._counter(), max(self._numbers(), default=0) + 1)) + "\n", encoding="utf-8")

    def next_id(self) -> str:
        """The next id: past every id the ledger holds and past the counter, which remembers the
        ids of rows archived with earlier runs."""
        return f"G{max(self._counter(), max(self._numbers(), default=0) + 1, 1)}"

    def add(self, proposal: dict, run: str, iteration: int) -> str:
        span = proposal.get("span_text") or proposal.get("span")
        for r in self.rows:      # the same words of the same law, proposed again: the same gap
            if r.get("span") == span and set(r.get("law_refs", [])) == set(proposal.get("law_refs", [])) and r.get("kind") == proposal.get("kind"):
                return r["id"]
        gid = self.next_id()
        row = {"id": gid, "kind": proposal.get("kind"), "span": proposal.get("span_text") or proposal.get("span"),
               "law_refs": proposal.get("law_refs", []), "node_id": proposal.get("node_id"),
               "proposal": proposal.get("proposal", ""), "nearest": proposal.get("nearest", []),
               "state": "proposed", "decision": "", "retired_by": "", "proposed_in": f"{run}/iter-{iteration:03d}"}
        self.rows.append(row)
        return gid

    def decided(self) -> dict[str, tuple[str, str]]:
        """Gaps the operator has closed, retired or rejected, with the decision's words."""
        return {r["id"]: (r["state"], str(r.get("decision", ""))) for r in self.rows if r.get("state") in ("retired", "rejected")}

    def visible(self, law_ids: set[str], base_run: str | None = None) -> list[dict]:
        """The rows a run may be shown: gaps on a law of its corpus, and gaps its base run proposed.
        A gap on a law outside the corpus (another split's) never reaches its plan."""
        base = f"{base_run}/" if base_run else None
        return [r for r in self.rows if set(r.get("law_refs", [])) & law_ids
                or (base and str(r.get("proposed_in", "")).startswith(base))]

    def render(self, law_ids: set[str] | None = None, base_run: str | None = None) -> str:
        """The ledger as a table; with `law_ids`, only the rows `visible` to that corpus."""
        if not self.rows:
            return "(no gaps recorded)\n"
        rows = self.rows if law_ids is None else self.visible(law_ids, base_run)
        if not rows:
            return "(no gaps recorded on the laws of this corpus)\n"
        out = ["| id | state | kind | span | proposal | decision |", "|---|---|---|---|---|---|"]
        for r in rows:
            out.append(f"| {r['id']} | {r['state']} | {r.get('kind')} | {r.get('span', '')[:80]} | {str(r.get('proposal', ''))[:120]} | {r.get('decision', '')} |")
        return "\n".join(out) + "\n"
