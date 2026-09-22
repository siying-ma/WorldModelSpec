"""The gap ledger (design §9): what the ontology cannot carry, proposed by plan sessions,
decided by the operator. Ids are allocated here; nothing else writes the file."""
from __future__ import annotations
import json
from pathlib import Path

KINDS = {"atom", "value", "derived", "operator", "definition", "unresolvable"}
STATES = {"proposed", "accepted", "rejected", "retired"}


class GapLedger:
    def __init__(self, path: Path):
        self.path = path
        self.rows: list[dict] = []
        if path.exists():
            self.rows = [json.loads(l) for l in path.read_text(encoding="utf-8").splitlines() if l.strip()]

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in self.rows), encoding="utf-8")

    def next_id(self) -> str:
        return f"G{len(self.rows) + 1}"

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

    def retired(self) -> set[str]:
        return {r["id"] for r in self.rows if r.get("state") == "retired"}

    def render(self) -> str:
        if not self.rows:
            return "(no gaps recorded)\n"
        out = ["| id | state | kind | span | proposal | decision |", "|---|---|---|---|---|---|"]
        for r in self.rows:
            out.append(f"| {r['id']} | {r['state']} | {r.get('kind')} | {r.get('span', '')[:80]} | {str(r.get('proposal', ''))[:120]} | {r.get('decision', '')} |")
        return "\n".join(out) + "\n"
