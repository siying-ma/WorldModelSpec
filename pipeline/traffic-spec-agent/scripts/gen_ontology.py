"""Generate library/TrafficSpec/Core/Vocab/Ontology/*.lean from ontology/ATOMS.md.

Every attribute enumeration written in an atom's contract as `**attr** ∈ {a, b(dir), …}` (or, for
the sign catalogue, `**code**: a, b, …`) becomes one Lean inductive; the atom ids of §1–§7 and the
primitive ids of §10 become string lists. Nothing else is generated: structured attributes (a rider's
posture, a sign's conditions) are hand-written records in World.lean.

    python -m scripts.gen_ontology            # write the files
    python -m scripts.gen_ontology --check    # exit 1 if the files on disk differ (the doctor's bijection check)

The generator is the only path from ATOMS.md to Lean, so the bijection holds by construction; the
check mode catches a hand edit on either side.
"""
from __future__ import annotations
import re, sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ATOMS = REPO / "ontology" / "ATOMS.md"
OUT = REPO / "library" / "TrafficSpec" / "Core" / "Vocab" / "Ontology"

# (atom id, attribute) -> Lean type name. Anything not listed gets a mechanical name.
TYPE_NAMES = {
    ("ru.emergency_vehicle", "kind"): "EmergencyKind",
    ("ru.official_vehicle", "kind"): "OfficialKind",
    ("st.lane_marking", "type"): "MarkingType",
    ("st.lane_marking", "colour"): "MarkingColour",
    ("st.reserved_lane", "class"): "ReservedClass",
    ("st.turn_lane", "side"): "TurnSide",
    ("st.parking_space", "designation"): "ParkingDesignation",
    ("st.curb_zone", "kind"): "CurbZoneKind",
    ("st.curb_zone", "colour"): "CurbColour",
    ("st.obstruction", "kind"): "ObstructionKind",
    ("dev.traffic_signal", "state"): "SignalIndication",
    ("dev.traffic_signal", "dir"): "ArrowDir",
    ("dev.pedestrian_signal", "state"): "PedSignalState",
    ("dev.lane_control_signal", "state"): "LaneControlState",
    ("dev.speed_limit_sign", "kind"): "SpeedSignKind",
    ("dev.regulatory_sign", "code"): "SignCode",
    ("dev.zone_sign", "kind"): "ZoneKind",
    ("dev.railway_signal_or_gate", "lights"): "RailLights",
    ("dev.railway_signal_or_gate", "gate"): "GateState",
    ("dev.human_direction", "role"): "HumanRole",
    ("dev.human_direction", "indication"): "HumanIndication",
    ("sig.headlamp", "state"): "HeadlampState",
    ("sig.turn_indicator", "state"): "TurnIndicatorState",
    ("sig.warning_lamp", "colour"): "LampColour",
    ("sig.warning_lamp", "mode"): "LampMode",
    ("sig.warning_lamp", "facing"): "Facing",
    ("sig.hand_signal", "meaning"): "HandSignal",
    ("sig.door_open", "side"): "DoorSide",
}
FILE_OF_FAMILY = {"ru": "RoadUser", "st": "Structure", "dev": "Device", "sig": "Signal"}
# Atom ids that are classes/kinds of an entity become constructors of one enumeration per family;
# the ids below are attributes or relations of that family and are not kinds.
KIND_ENUMS = {
    "ru": ("RoadUserClass", {"ru.occupant_count", "ru.rider_posture", "ru.subject", "ru.aggregate"}),
    "st": ("StructureKind", {"st.lane_direction", "st.lane_adjacency", "st.lane_connectivity", "st.lane_enters", "st.lane_marking",
                             "st.lane_width", "st.curvature", "st.grade", "st.sight_distance", "st.region_geometry"}),
    "dev": ("DeviceKind", {"dev.governs", "dev.position", "dev.inoperative"}),
}
FAMILIES = ("ru", "kin", "st", "dev", "sig", "env", "rel")

ROW = re.compile(r"^\| `((?:ru|kin|st|dev|sig|env|rel|prim)\.[a-z_]+)` \| (.*)$")
ENUM = re.compile(r"\*\*(\w+)\*\* ∈ \{([^}]*)\}")
DIRSET = re.compile(r"with dir ∈ \{([^}]*)\}")
CODES = re.compile(r"\*\*code\*\*, [^:]*: ([^*|]+?) \*\*Not|\*\*code\*\*: ([^*|]+?) \*\*Not")

def camel(v: str) -> str:
    parts = v.strip().split("_")
    return parts[0] + "".join(p.capitalize() for p in parts[1:])

def parse(atoms_path: Path = None):
    text = (atoms_path or ATOMS).read_text(encoding="utf-8")
    section = None
    atoms, primitives, enums = [], [], []   # enums: (atom, attr, [values], param_type)
    for line in text.splitlines():
        m = re.match(r"^## (\d+)\.", line)
        if m:
            section = int(m.group(1)); continue
        r = ROW.match(line)
        if not r:
            continue
        aid, rest = r.group(1), r.group(2)
        fam = aid.split(".")[0]
        if section in range(1, 8) and fam in FAMILIES:
            atoms.append(aid)
            for e in ENUM.finditer(rest):
                attr, vals = e.group(1), [v.strip() for v in e.group(2).split(",") if v.strip()]
                enums.append((aid, attr, vals))
            d = DIRSET.search(rest)
            if d:
                enums.append((aid, "dir", [v.strip() for v in d.group(1).split(",") if v.strip()]))
            c = CODES.search(rest)
            if c:
                vals = [v.strip() for v in (c.group(1) or c.group(2)).split(",") if v.strip()]
                enums.append((aid, "code", vals))
        elif section == 10 and fam == "prim":
            primitives.append(aid)
    return atoms, primitives, enums

def render_codec(name, vals, param_types):
    """`ofString`/`toString` between the ATOMS.md spelling ("green_arrow(left)") and the constructor."""
    plain = [v for v in vals if "(" not in v]
    pars = [(re.match(r"^(\w+)\((\w+)\)$", v).group(1), re.match(r"^(\w+)\((\w+)\)$", v).group(2)) for v in vals if "(" in v]
    lines = [f"namespace {name}", f"def ofString (s : String) : Option {name} :=", "  match s with"]
    for v in plain:
        lines.append(f'  | "{v}" => some .{camel(v)}')
    if pars:
        lines.append("  | s =>")
        conds = []
        for ctor, par in pars:
            ptype = param_types.get(par, "ArrowDir")
            conds.append(f'    if s.startsWith "{ctor}(" && s.endsWith ")" then\n'
                         f'      ({ptype}.ofString ((s.drop {len(ctor)+1}).dropEnd 1).toString).map .{camel(ctor)}\n    else')
        lines.append("\n".join(conds) + " Option.none")
    else:
        lines.append("  | _ => Option.none")
    lines.append(f"def toString : {name} → String")
    for v in plain:
        lines.append(f'  | .{camel(v)} => "{v}"')
    for ctor, par in pars:
        ptype = param_types.get(par, "ArrowDir")
        lines.append(f'  | .{camel(ctor)} d => "{ctor}(" ++ {ptype}.toString d ++ ")"')
    lines.append(f"instance : ToString {name} := ⟨toString⟩")
    lines.append(f"end {name}")
    return "\n".join(lines)

def render_inductive(aid, attr, vals):
    name = TYPE_NAMES.get((aid, attr)) or (camel(aid.split(".")[1]).capitalize() + attr.capitalize())
    lines = [f"/-- `{aid}` **{attr}** — generated from ATOMS.md; do not edit. -/",
             f"inductive {name}"]
    param_types = {}
    for v in vals:
        pm = re.match(r"^(\w+)\((\w+)\)$", v)
        if pm:
            ctor, par = camel(pm.group(1)), pm.group(2)
            ptype = TYPE_NAMES.get((aid, par), "ArrowDir")
            param_types[par] = ptype
            lines.append(f"  | {ctor} (d : {ptype})")
        else:
            lines.append(f"  | {camel(v)}")
    lines.append("  deriving DecidableEq, Repr, Inhabited")
    lines.append("")
    lines.append(render_codec(name, vals, param_types))
    return name, "\n".join(lines)

def generate(atoms_path: Path = None):
    atoms, primitives, enums = parse(atoms_path)
    files = {}
    source = (atoms_path or ATOMS).name
    header = ("/-\n  TrafficSpec.Core.Vocab.Ontology.{name}\n  GENERATED by scripts/gen_ontology.py from ontology/" + source + ". Do not edit: the doctor\n"
              "  regenerates and compares. Constructors are the attribute values the ontology lists,\n"
              "  with no meaning attached; what a value obliges is a rule's business.\n-/\n"
              "namespace TrafficSpec\n\n")
    per_file: dict[str, list[str]] = {f: [] for f in FILE_OF_FAMILY.values()}
    # ArrowDir must precede the types that use it: order enums so `dir` comes first within a file
    enums_sorted = sorted(enums, key=lambda e: (FILE_OF_FAMILY.get(e[0].split(".")[0], "Misc"), 0 if e[1] == "dir" else 1))
    seen = set()
    for aid, attr, vals in enums_sorted:
        fam = aid.split(".")[0]
        fname = FILE_OF_FAMILY.get(fam, "Misc")
        name, body = render_inductive(aid, attr, vals)
        if name in seen:
            raise SystemExit(f"duplicate type name {name}")
        seen.add(name)
        per_file.setdefault(fname, []).append(body)
    for fam, (tname, excl) in KIND_ENUMS.items():
        kinds = [a.split(".")[1] for a in atoms if a.startswith(fam + ".") and a not in excl]
        body = (f"/-- The `{fam}.*` kinds of ATOMS.md, one constructor per class atom — generated; do not edit. -/\n"
                f"inductive {tname}\n" + "\n".join(f"  | {camel(k)}" for k in kinds)
                + "\n  deriving DecidableEq, Repr, Inhabited\n\n"
                + render_codec(tname, kinds, {}))
        per_file[FILE_OF_FAMILY[fam]].insert(0, body)
    for fname, bodies in per_file.items():
        if not bodies: continue
        text = header.replace("{name}", fname) + "\n\n".join(bodies) + "\n\nend TrafficSpec\n"
        files[f"{fname}.lean"] = text
    ids = (header.replace("{name}", "Ids")
           + "/-- Every atom id of ATOMS.md §1–§7, in file order. -/\ndef atomIds : List String := [\n"
           + ",\n".join(f'  "{a}"' for a in atoms) + "\n]\n\n"
           + "/-- Every primitive id of ATOMS.md §10, in file order. -/\ndef primitiveIds : List String := [\n"
           + ",\n".join(f'  "{d}"' for d in primitives) + "\n]\n\nend TrafficSpec\n")
    files["Ids.lean"] = ids
    return files

def main(argv):
    # --atoms <ATOMS.md variant> --out <directory>: generate a split's ontology (e.g. the training-only
    # ATOMS_train.md into library/splits/train/TrafficSpec/Core/Vocab/Ontology); defaults are the full ontology.
    atoms_path = Path(argv[argv.index("--atoms") + 1]) if "--atoms" in argv else ATOMS
    out = Path(argv[argv.index("--out") + 1]) if "--out" in argv else OUT
    files = generate(atoms_path)
    check = "--check" in argv
    out.mkdir(parents=True, exist_ok=True)
    drift = []
    for fname, text in files.items():
        path = out / fname
        if check:
            if not path.exists() or path.read_text(encoding="utf-8") != text:
                drift.append(fname)
        else:
            path.write_text(text, encoding="utf-8")
    if check:
        stale = [p.name for p in out.glob("*.lean") if p.name not in files]
        if drift or stale:
            print("ontology drift:", drift, "stale:", stale); return 1
        print(f"ontology in sync: {len(files)} generated files"); return 0
    print(f"wrote {len(files)} files to {out}")
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
