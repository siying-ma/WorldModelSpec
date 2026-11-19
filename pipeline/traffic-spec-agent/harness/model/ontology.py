"""The ontology as the run sees it: ATOMS.md or ATOMS_train.md, parsed for the closed set and
rendered whole for the agents."""
from __future__ import annotations
import re
from dataclasses import dataclass, field
from pathlib import Path

ROW = re.compile(r"^\| `((?:ru|kin|st|dev|sig|env|rel|prim)\.[a-z_]+)` \| (.*)$")
ENUM = re.compile(r"\*\*(\w+)\*\* ∈ \{([^}]*)\}")
CODES = re.compile(r"\*\*code\*\*, [^:]*: ([^*|;]+?)(?:;| \*\*Not)|\*\*code\*\*: ([^*|;]+?)(?:;| \*\*Not)")
#: The atom ids of the road-user, structure and device families that are attributes of an entity or
#: relations between entities, not classes or kinds of one. Every other atom of those families is a
#: class or a kind: a constructor of Core's generated `RoadUserClass`, `StructureKind` or `DeviceKind`,
#: and, for road users, a class an aggregate classifies.
NOT_KINDS: dict[str, frozenset[str]] = {
    "ru": frozenset({"ru.occupant_count", "ru.unladen_mass", "ru.disabled", "ru.rider_posture", "ru.subject", "ru.aggregate"}),
    "st": frozenset({"st.lane_direction", "st.lane_adjacency", "st.lane_connectivity", "st.lane_enters", "st.lane_marking",
                     "st.lane_width", "st.curvature", "st.grade", "st.sight_distance", "st.region_geometry",
                     "st.on_way", "st.entrance_of", "st.sight_along_way"}),
    "dev": frozenset({"dev.governs", "dev.governs_sidewalk", "dev.governs_parking_space", "dev.position", "dev.inoperative"}),
}
ANCHORS = {"rel.occupies", "st.region_geometry"}   # the relations that tie a feature of the scene to the subject
AGGREGATE = "ru.aggregate"                          # the atom a legal aggregate word is claimed as
#: A row of the catalogue of approved abstractions, in the section on what is not an atom: an id with
#: no family prefix, and its scope.
ABSTRACTION = re.compile(r"^\| `([a-z][a-z0-9_]*)` \| (.*?)\s*\|?\s*$")
NOT_ATOMS = 9                                       # the section on what is not an atom


@dataclass
class Ontology:
    path: Path
    text: str
    atoms: dict[str, str] = field(default_factory=dict)          # id → contract
    values: set[str] = field(default_factory=set)                # "atom=value"
    primitives: dict[str, tuple[str, str]] = field(default_factory=dict)   # id → (contract, params)
    abstractions: dict[str, str] = field(default_factory=dict)  # approved abstraction id → its scope

    @property
    def atom_ids(self) -> set[str]:
        return set(self.atoms)

    @property
    def primitive_ids(self) -> set[str]:
        return set(self.primitives)

    def knows(self, ident: str) -> bool:
        if "=" in ident:
            return ident in self.values
        return ident in self.atoms or ident in self.primitives

    def contract(self, ident: str) -> str:
        return self.atoms.get(ident) or (self.primitives.get(ident, ("", ""))[0])


def anchors_text(onto: "Ontology", lean: bool = False) -> str:
    """The anchoring relations with their contracts, for a prompt: ids, or Lean names when `lean`."""
    parts = []
    for a in sorted(ANCHORS):
        name = a.replace(".", "_") if lean else a
        contract = re.split(r"\s*[(;,]|\s+\*\*", onto.contract(a), maxsplit=1)[0].strip()
        parts.append(f"`{name}`" + (f" ({contract})" if contract else ""))
    return " or ".join(parts) + (" (or an accessor of one)" if lean else "")


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
            a = ABSTRACTION.match(line) if section == NOT_ATOMS else None
            if a:
                o.abstractions[a.group(1)] = a.group(2).strip()
            continue
        aid, rest = r.group(1), r.group(2)
        cells = [c.strip() for c in rest.split(" | ")]
        fam = aid.split(".")[0]
        if section in range(1, 8) and fam != "prim":
            o.atoms[aid] = cells[0]
            for e in ENUM.finditer(rest):
                for v in e.group(2).split(","):
                    v = v.strip()
                    if v:
                        value = re.sub(r'\(.*\)', '', v)
                        o.values.add(f"{aid}={value}")
            c = CODES.search(rest)
            if c:
                for v in (c.group(1) or c.group(2)).split(","):
                    if v.strip():
                        o.values.add(f"{aid}={v.strip()}")
        elif section == 10 and fam == "prim":
            o.primitives[aid] = (cells[0], cells[1] if len(cells) > 1 else "")
    return o
