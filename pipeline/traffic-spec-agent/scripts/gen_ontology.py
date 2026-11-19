"""Generate library/TrafficSpec/Core/Vocab/Ontology/*.lean from ontology/ATOMS.md.

Every attribute enumeration written in an atom's contract as `**attr** ∈ {a, b(dir), …}` (or, for
the sign catalogue, `**code**: a, b, …`, ended by `;` or the **Not a stand-in for** clause) becomes one Lean inductive; the atom ids of the seven
atom families and the primitive ids become string lists; the units of the measured atoms (the
units table) and of the primitives (the last two columns of a primitive's row) become the
dimension tables of `Dimensions.lean`; a structure kind's `**Refines:** st.<kind>` clause becomes
`StructureKind.parent?` and its transitive closure `StructureKind.ancestors`, a structure kind whose
contract begins with `**Abstract.**` becomes `StructureKind.isAbstract`, and every structure kind is
listed in `StructureKind.all`. Nothing else
is generated: structured attributes (a rider's posture, a sign's conditions) are hand-written
records in World.lean.

    python -m scripts.gen_ontology            # write the files
    python -m scripts.gen_ontology --check    # exit 1 if the files on disk differ (the doctor's bijection check)

The generator is the only path from ATOMS.md to Lean, so the bijection holds by construction; the
check mode catches a hand edit on either side.
"""
from __future__ import annotations
import re, sys
from pathlib import Path

from harness.model.ontology import NOT_KINDS

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
    ("st.driveway_or_alley_entrance", "kind"): "EntranceKind",
    ("st.railway_track", "kind"): "RailwayKind",
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
# the ids of `NOT_KINDS` are attributes or relations of that family and are not kinds.
KIND_ENUMS = {"ru": ("RoadUserClass", NOT_KINDS["ru"]), "st": ("StructureKind", NOT_KINDS["st"]),
              "dev": ("DeviceKind", NOT_KINDS["dev"])}
FAMILIES = ("ru", "kin", "st", "dev", "sig", "env", "rel")

ROW = re.compile(r"^\| `((?:ru|kin|st|dev|sig|env|rel|prim)\.[a-z_]+)` \| (.*)$")
ENUM = re.compile(r"\*\*(\w+)\*\* ∈ \{([^}]*)\}")
DIRSET = re.compile(r"with dir ∈ \{([^}]*)\}")
REFINES = re.compile(r"\*\*Refines:\*\*\s*(\S+)")
REFINES_ID = re.compile(r"^`(st\.[a-z_]+)`$")
ABSTRACT = re.compile(r"^\*\*Abstract\.\*\*")
CODES = re.compile(r"\*\*code\*\*, [^:]*: ([^*|;]+?)(?:;| \*\*Not)|\*\*code\*\*: ([^*|;]+?)(?:;| \*\*Not)")

#: How ATOMS.md writes two units Core's decoder spells otherwise; `boolean` is no quantity.
ONTOLOGY_SPELLING = {"m/s²": "m/s^2", "1": "ratio"}
MEASURE_ROW = re.compile(r"^\| `((?:ru|kin|st|dev|sig|env|rel)\.[a-z_]+)` \| `([a-z_]+)` \| ([^|]+?) \|$")

def dim(unit: str, where: str) -> tuple[int, int, int, int]:
    """The exponents of metre, second, degree and kilogram of a unit as ATOMS.md writes it, from Core's units."""
    from harness.model import units
    spelled = ONTOLOGY_SPELLING.get(unit, unit)
    if spelled not in units.FACTORS:
        raise SystemExit(f"{where}: unknown unit {unit!r} (known: {', '.join(units.spellings())}, boolean)")
    return units.DIMS[units.FACTORS[spelled][0]]

def camel(v: str) -> str:
    parts = v.strip().split("_")
    return parts[0] + "".join(p.capitalize() for p in parts[1:])

def parse(atoms_path: Path = None):
    text = (atoms_path or ATOMS).read_text(encoding="utf-8")
    section = None
    atoms, primitives, enums = [], [], []   # enums: (atom, attr, [values], param_type)
    measures, prim_units = [], []            # (lean name, dim); (lean name, result dim or None, [param dims])
    refines = {}                             # structure kind id -> the kind id it refines
    abstract = set()                         # structure kind ids whose contract begins with **Abstract.**
    for line in text.splitlines():
        m = re.match(r"^## (\d+)\.", line)
        if m:
            section = int(m.group(1)); continue
        if section == 11:
            mm = MEASURE_ROW.match(line)
            if mm:
                measures.append((mm.group(2), dim(mm.group(3).strip(), mm.group(2))))
            continue
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
            found = REFINES.findall(rest)
            if found:
                target = REFINES_ID.match(found[0].rstrip(".,;"))
                if fam != "st" or len(found) > 1 or not target:
                    raise SystemExit(f"{aid}: a **Refines:** clause names one structure kind as `st.<kind>`, on a structure kind")
                refines[aid] = target.group(1)
            if ABSTRACT.match(rest):
                if fam != "st":
                    raise SystemExit(f"{aid}: only a structure kind is **Abstract.**")
                abstract.add(aid)
        elif section == 10 and fam == "prim":
            primitives.append(aid)
            cells = [c.strip() for c in rest.rstrip(" |").split(" | ")]
            if len(cells) < 4:
                raise SystemExit(f"{aid}: the primitive's row lacks its result unit and parameter units columns")
            name = aid.replace(".", "_")
            result = None if cells[2] == "boolean" else dim(cells[2], name)
            ps = [] if cells[3] in ("—", "-", "") else [dim(u.strip(), name) for u in cells[3].split(",")]
            prim_units.append((name, result, ps))
    return atoms, primitives, enums, measures, prim_units, refines, abstract

def render_refinement(kinds: list[str], refines: dict[str, str], abstract: set[str] = frozenset()) -> str:
    """`parent?`, `ancestors`, `isAbstract` and `all` on `StructureKind`, from the `**Refines:**`
    clauses and the `**Abstract.**` marks; every kind named must be a kind of the same ontology, the
    relation must have no cycle, and an abstract kind refines no kind and is refined by one at least."""
    for a in sorted(abstract):
        if a in refines:
            raise SystemExit(f"{a}: an abstract kind refines no kind")
        if a not in refines.values():
            raise SystemExit(f"{a}: an abstract kind is refined by one kind at least")
    ancestors = {}
    for k in kinds:
        chain, cur = [], "st." + k
        while cur in refines:
            cur = refines[cur]
            name = cur.split(".", 1)[1]
            if name not in kinds:
                raise SystemExit(f"st.{k}: refines {cur}, which is no structure kind of this ontology")
            if name == k or name in chain:
                raise SystemExit(f"st.{k}: the **Refines:** clauses form a cycle")
            chain.append(name)
        if chain:
            ancestors[k] = chain
    lines = ["/-- The kind this kind refines (its contract's **Refines:** clause); `none` for a kind that refines none. -/",
             "def parent? : StructureKind → Option StructureKind"]
    lines += [f"  | .{camel(k)} => some .{camel(a[0])}" for k, a in ancestors.items()]
    lines += ["  | _ => none",
              "/-- Every kind this kind refines, nearest first: its parent, the parent's parent, and so on. -/",
              "def ancestors : StructureKind → List StructureKind"]
    lines += [f"  | .{camel(k)} => [{', '.join('.' + camel(x) for x in a)}]" for k, a in ancestors.items()]
    lines += ["  | _ => []",
              "/-- Whether the kind is abstract (its contract's **Abstract.** mark): the union of the kinds refining it. -/",
              "def isAbstract : StructureKind → Bool"]
    lines += [f"  | .{camel(k)} => true" for k in kinds if "st." + k in abstract]
    lines += ["  | _ => false",
              "/-- Every structure kind, in ontology order. -/",
              "def all : List StructureKind := [" + ", ".join("." + camel(k) for k in kinds) + "]"]
    return "\n".join(lines)

def render_codec(name, vals, param_types, extra: str = ""):
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
    if extra:
        lines.append(extra)
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

def render_dimensions(header: str, measures, prim_units) -> str:
    d = lambda t: f"⟨{t[0]}, {t[1]}, {t[2]}, {t[3]}⟩"
    return (header.replace("{name}", "Dimensions").replace(
                "Constructors are the attribute values the ontology lists,\n  with no meaning attached; what a value obliges is a rule's business.",
                "The units the ontology states for its measured atoms and primitives, as\n  dimensions a case is typed with.")
            + "/-- A physical dimension: the exponents of metre, second, degree and kilogram. -/\n"
            + "structure Dim where\n  m : Int\n  s : Int\n  deg : Int\n  kg : Int\n  deriving DecidableEq, Repr, Inhabited\n\n"
            + "namespace Dimensions\n"
            + "/-- The unit of each measured atom, by the name a formula reads it with. -/\n"
            + "def ofMeasure : List (String × Dim) := [\n"
            + ",\n".join(f'  ("{n}", {d(t)})' for n, t in measures) + "\n]\n\n"
            + "/-- Each primitive by name: its result's unit (`none` for a Boolean one) and its parameters' units\n"
            + "    in order. -/\n"
            + "def ofPrimitive : List (String × Option Dim × List Dim) := [\n"
            + ",\n".join(f'  ("{n}", {"none" if r is None else "some " + d(r)}, [{", ".join(d(p) for p in ps)}])' for n, r, ps in prim_units)
            + "\n]\nend Dimensions\n\nend TrafficSpec\n")

def generate(atoms_path: Path = None):
    atoms, primitives, enums, measures, prim_units, refines, abstract = parse(atoms_path)
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
                + render_codec(tname, kinds, {}, render_refinement(kinds, refines, abstract) if fam == "st" else ""))
        per_file[FILE_OF_FAMILY[fam]].insert(0, body)
    for fname, bodies in per_file.items():
        if not bodies: continue
        text = header.replace("{name}", fname) + "\n\n".join(bodies) + "\n\nend TrafficSpec\n"
        files[f"{fname}.lean"] = text
    ids = (header.replace("{name}", "Ids")
           + "/-- Every atom id of the seven atom families of ATOMS.md, in file order. -/\ndef atomIds : List String := [\n"
           + ",\n".join(f'  "{a}"' for a in atoms) + "\n]\n\n"
           + "/-- Every primitive id of ATOMS.md, in file order. -/\ndef primitiveIds : List String := [\n"
           + ",\n".join(f'  "{d}"' for d in primitives) + "\n]\n\nend TrafficSpec\n")
    files["Ids.lean"] = ids
    files["Dimensions.lean"] = render_dimensions(header, measures, prim_units)
    return files

def main(argv):
    # --atoms <ATOMS.md variant> --out <directory>: generate a split's ontology (e.g. the training-only
    # ATOMS_train.md into library/splits/train/TrafficSpec/Core/Vocab/Ontology); defaults are the full ontology.
    atoms_path = Path(argv[argv.index("--atoms") + 1]) if "--atoms" in argv else ATOMS
    out = Path(argv[argv.index("--out") + 1]) if "--out" in argv else OUT
    check = "--check" in argv
    active = REPO / "library" / "splits" / "ACTIVE"
    split = active.read_text().strip() if active.exists() else "full"
    if not check and ("--atoms" in argv) != ("--out" in argv):
        print("give both --atoms and --out, or neither"); return 2
    if not check and "--atoms" not in argv and split != "full":
        print(f"the Core directory holds the `{split}` split: the full ontology is written only while `full` is active "
              "(python -m harness split --use full); a split's ontology is written with an explicit --atoms and --out pair")
        return 2
    files = generate(atoms_path)
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
