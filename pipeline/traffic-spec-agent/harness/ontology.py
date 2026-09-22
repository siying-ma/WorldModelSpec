"""The ontology as the run sees it: ATOMS.md or ATOMS_train.md, parsed for the closed set and
rendered whole for the agents."""
from __future__ import annotations
import re
from dataclasses import dataclass, field
from pathlib import Path

ROW = re.compile(r"^\| `((?:ru|kin|st|dev|sig|env|rel|drv)\.[a-z_]+)` \| (.*)$")
ENUM = re.compile(r"\*\*(\w+)\*\* ∈ \{([^}]*)\}")
DIRSET = re.compile(r"with dir ∈ \{([^}]*)\}")
CODES = re.compile(r"\*\*code\*\*, [^:]*: ([^*|]+?) \*\*Not|\*\*code\*\*: ([^*|]+?) \*\*Not")
ASSUMPTION_RE = re.compile(r"\basm\.[a-z_]+\b")


@dataclass
class Ontology:
    path: Path
    text: str
    atoms: dict[str, str] = field(default_factory=dict)          # id → contract
    values: set[str] = field(default_factory=set)                # "atom=value"
    derived: dict[str, tuple[str, str]] = field(default_factory=dict)   # id → (sketch, params)

    @property
    def atom_ids(self) -> set[str]:
        return set(self.atoms)

    @property
    def derived_ids(self) -> set[str]:
        return set(self.derived)

    def knows(self, ident: str) -> bool:
        if "=" in ident:
            return ident in self.values
        return ident in self.atoms or ident in self.derived

    def contract(self, ident: str) -> str:
        return self.atoms.get(ident) or (self.derived.get(ident, ("", ""))[0])

    def subset_text(self, ids: set[str]) -> str:
        """The contracts of the named ids only, for the blind reader."""
        lines = ["| id | contract |", "|---|---|"]
        for i in sorted(ids):
            c = self.contract(i)
            if c:
                lines.append(f"| `{i}` | {c} |")
        return "\n".join(lines) + "\n"


def load(path: Path) -> Ontology:
    text = path.read_text(encoding="utf-8")
    o = Ontology(path, text)
    section = None
    for line in text.splitlines():
        m = re.match(r"^## (\d+)\.", line)
        if m:
            section = int(m.group(1)); continue
        r = ROW.match(line)
        if not r:
            continue
        aid, rest = r.group(1), r.group(2)
        cells = [c.strip() for c in rest.split(" | ")]
        fam = aid.split(".")[0]
        if section in range(1, 8) and fam != "drv":
            o.atoms[aid] = cells[0]
            for e in ENUM.finditer(rest):
                for v in e.group(2).split(","):
                    v = v.strip()
                    if v:
                        o.values.add(f"{aid}={re.sub(r'\(.*\)', '', v)}")
            c = CODES.search(rest)
            if c:
                for v in (c.group(1) or c.group(2)).split(","):
                    if v.strip():
                        o.values.add(f"{aid}={v.strip()}")
        elif section == 9 and fam == "drv":
            o.derived[aid] = (cells[0], cells[1] if len(cells) > 1 else "")
    return o
