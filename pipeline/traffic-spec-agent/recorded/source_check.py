"""What a recording's source declares against what its trace holds: a report, per recording, of
where the manifest's observability declarations and the entities and relations of the trace agree
or not, read under Core's decoder. Deterministic, no model, no Lean run.

Reason: a recording whose data contradicts its manifest makes a rule unknown or silently not
applicable, and the label check cannot tell that from a rule defect; this report states, before any
repair is paid for, which recordings carry such contradictions.

It is a report and nothing else: no recording is rejected, no status, outcome, route or evidence
changes because of it, and a recording with no finding is not certified correct.

A recording's manifest is its source's (one per scene-graph generator or adapter version, shared by
every recording of that source), so a declaration finding speaks of the source, seen on one trace.

Each finding has one case:
- `i`: the manifest declares the atom observed and the recording holds no entity it applies to (a
  legally empty list: the recording has no such thing);
- `ii`: not observed: the manifest declares the atom absent (Core masks it, so every read of it is
  unknown);
- `iii`: declared observed, yet an entity or relation that should be there is missing, or a
  declaration contradicts the entities present (a kind the manifest declares absent labels a
  structure, device or road user; a kind it declares observed is listed unobserved on one where the
  listing takes effect).
and one family: `declaration` (an atom's observability against the kinds and fields present),
`association` (a relation the source states: `dev.governs`, `st.entrance_of`, `st.on_way`,
`st.lane_enters`), and geometry, which is no finding but a fact (see below). Each finding carries
the atom, the check, the entity family, how many distinct entities and how many observations it
concerns out of how many checked, and at most two examples (scene index, time, entity id).

What should carry a field, read from the atoms' contracts (refinements through Core's kind
hierarchy, `StructureKind.parent?`, never by name):
- a lane and every kind refining it, but a centre turn lane, and a bicycle lane or path, carry
  `lane.direction`; every lane kind carries `lane.ordinal` and `lane.count` (`st.lane_adjacency`),
  `lane.marking_left` and `lane.marking_right`, `lane.width`, and the key `lane.leads_to`
  (`st.lane_connectivity`, an empty list allowed);
- a roadway and every kind refining it carry `curvature`, `grade` and `sight_distance`;
- every structure carries `boundary` or `position` (`st.region_geometry`);
- a stop line and a crosswalk carry the key `entrance_of`; every structure but a highway carries the
  key `ways` (`st.on_way`); every intersection is entered by some carrier (`st.lane_enters`);
- every device carries the key `governs`; a device of a kind carries the attributes its kind atom
  states (a traffic signal its `indications` in every scene, a speed limit sign its value and kind,
  a regulatory sign its code and conditions, and so on);
- the subject in every scene, and every other road user classified `motor_vehicle`, carry each
  `sig.*` field the manifest observes (a `subject` capability: the subject alone); every road user
  carries each `kin.*` field the manifest observes, under the same rule for `subject`; every scene
  carries each `env.*` field observed, a subject that is among its road users (`ru.subject`), and
  occupancy observed for every road user (`rel.occupies`).
A field present while its atom is declared absent is no finding: the source holds data it does not
vouch for, and Core masks it.

Geometry is reported as facts with no verdict, since the map-crop and highway contract is not
agreed: where highways exist, how many roadways, lanes and intersections have every boundary vertex
inside one highway, inside some highway, partly or not at all; how many structures name their ways
and whether those are highways. `st.on_way` is only ever read from the trace, never inferred from
containment or nearness.

Structures are checked once per distinct content of each id (a map repeated in every scene is
checked once); road users, devices and scene fields once per scene.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import sys
from collections import Counter
from concurrent.futures import ProcessPoolExecutor
from dataclasses import dataclass
from pathlib import Path

from . import projection

REPO = Path(__file__).resolve().parents[1]
ONTOLOGY_DIR = Path("TrafficSpec/Core/Vocab/Ontology")
CASES = ("i", "ii", "iii")
EXAMPLES = 2
#: Distance (m) within which a vertex on a highway's edge counts as inside it.
EDGE_TOLERANCE = 0.05


# ---------------------------------------------------------------------------------------------
# The kinds, as Core's generated ontology states them
# ---------------------------------------------------------------------------------------------
def _camel_map(text: str, typ: str) -> dict[str, str]:
    """Constructor name → string, from a generated `ofString` of `typ`."""
    m = re.search(rf"def ofString \(s : String\) : Option {typ} :=(.*?)\n  \| _ =>", text, re.S)
    if not m:
        raise ValueError(f"no ofString for {typ}")
    return {c: s for s, c in re.findall(r'\| "([^"]+)" => some \.(\w+)', m.group(1))}


def _block(text: str, head: str) -> str:
    i = text.index(head)
    j = text.find("\n/--", i)
    return text[i:j if j >= 0 else None]


@dataclass(frozen=True)
class Kinds:
    structures: tuple[str, ...]
    parent: dict
    abstract: frozenset
    devices: tuple[str, ...]
    classes: tuple[str, ...]
    digest: str

    @classmethod
    def from_library(cls, library: Path | None = None) -> "Kinds":
        """The structure kinds with their refinement (`parent?`, `isAbstract`), the device kinds and
        the road-user classes of a library's generated ontology."""
        d = Path(library or REPO / "library") / ONTOLOGY_DIR
        st, dev, ru = ((d / f).read_text(encoding="utf-8") for f in ("Structure.lean", "Device.lean", "RoadUser.lean"))
        names = _camel_map(st, "StructureKind")
        parent = {names[a]: names[b] for a, b in re.findall(r"\| \.(\w+) => some \.(\w+)",
                                                             _block(st, "def parent? : StructureKind"))}
        abstract = frozenset(names[a] for a in re.findall(r"\| \.(\w+) => true", _block(st, "def isAbstract : StructureKind")))
        digest = hashlib.sha256((st + dev + ru).encode()).hexdigest()
        return cls(tuple(names.values()), parent, abstract, tuple(_camel_map(dev, "DeviceKind").values()),
                   tuple(_camel_map(ru, "RoadUserClass").values()), digest)

    def refines(self, a: str, b: str) -> bool:
        """Whether kind `a` refines kind `b`, reflexively and transitively (`StructureKind.refines`)."""
        while a is not None:
            if a == b:
                return True
            a = self.parent.get(a)
        return False

    def mask_applies(self, label: str, m: str) -> bool:
        """Whether a kind `m` listed unobserved on a structure labelled `label` leaves that structure's
        membership open (`Structure.maskApplies`)."""
        p = self.parent.get(m)
        return p is None or p in self.abstract or self.refines(m, label)

    def of_kind(self, k: str) -> tuple[str, ...]:
        """Every concrete kind refining `k` (itself included)."""
        return tuple(x for x in self.structures if self.refines(x, k) and x not in self.abstract)


# ---------------------------------------------------------------------------------------------
# What should carry which field
# ---------------------------------------------------------------------------------------------
#: atom → (carrier kind, kinds excluded among its refinements, field path, ...)
STRUCTURE_FIELDS = (
    ("st.lane_direction", "lane", ("centre_turn_lane",), ("lane", "direction")),
    ("st.lane_direction", "bicycle_lane_or_path", (), ("lane", "direction")),
    ("st.lane_adjacency", "lane", (), ("lane", "ordinal")),
    ("st.lane_adjacency", "lane", (), ("lane", "count")),
    ("st.lane_marking", "lane", (), ("lane", "marking_left")),
    ("st.lane_marking", "lane", (), ("lane", "marking_right")),
    ("st.lane_width", "lane", (), ("lane", "width")),
    ("st.lane_connectivity", "lane", (), ("lane", "leads_to", "key")),
    ("st.curvature", "roadway", (), ("curvature",)),
    ("st.grade", "roadway", (), ("grade",)),
    ("st.sight_distance", "roadway", (), ("sight_distance",)),
)
#: device kind → the attributes its kind atom states
DEVICE_FIELDS = {
    "traffic_signal": ("indications",), "pedestrian_signal": ("ped_state",), "lane_control_signal": ("lane_control",),
    "speed_limit_beacon": ("flashing",), "crossing_warning_signal": ("active",),
    "speed_limit_sign": ("speed_value", "speed_kind"), "regulatory_sign": ("code", "conditions"),
    "zone_sign": ("zone_kind", "conditions"), "railway_signal_or_gate": ("rail_lights", "gate"),
    "human_direction": ("human_role", "human_indication"),
}
KIN = {"kin.position": "position", "kin.heading": "heading", "kin.velocity": "velocity", "kin.speed": "speed",
       "kin.accel_longitudinal": "accel_longitudinal", "kin.yaw_rate": "yaw_rate", "kin.extent": "extent",
       "kin.steer_angle": "steer_angle", "kin.path_length": "path_length", "kin.engine_running": "engine_running",
       "kin.parking_brake": "parking_brake", "kin.gear": "gear", "kin.throttle": "throttle", "kin.service_brake": "service_brake"}
SIG = {"sig.turn_indicator": "turn_indicator", "sig.brake_lamp": "brake_lamp", "sig.hazard": "hazard",
       "sig.headlamp": "headlamp", "sig.position_lamp": "position_lamp", "sig.warning_lamp": "warning_lamps",
       "sig.siren": "siren", "sig.horn": "horn", "sig.hand_signal": "hand_signal", "sig.door_open": "doors_open",
       "sig.compression_brake": "compression_brake"}
ENV = {"env.darkness": "darkness", "env.precipitation": "precipitation", "env.wet_road": "wet_road",
       "env.ice_or_snow": "ice_or_snow", "env.visibility": "visibility", "env.civil_time": "civil_time"}
#: The road-user class whose members carry the lamp and indicator fields besides the subject.
SIGNALLING_CLASS = "motor_vehicle"


def _has(d, path: tuple[str, ...]) -> bool:
    """Whether the field at `path` is present (a value, or with a trailing `key` the key alone)."""
    key_only = path[-1] == "key"
    path = path[:-1] if key_only else path
    for k in path[:-1]:
        d = d.get(k) if isinstance(d, dict) else None
    if not isinstance(d, dict) or path[-1] not in d:
        return False
    return key_only or d[path[-1]] is not None


class _Tally:
    """Per (family, atom, check, entity): the entities and observations missing out of those checked."""

    def __init__(self):
        self.t: dict[tuple, dict] = {}

    def add(self, key: tuple, entity, missing: bool, ex: dict | None = None):
        e = self.t.setdefault(key, {"entities": set(), "observations": 0, "checked": 0, "checked_entities": set(), "examples": [],
                                  "exemplified": set()})
        e["checked"] += 1
        e["checked_entities"].add(entity)
        if missing:
            e["entities"].add(entity)
            e["observations"] += 1
            if ex is not None and len(e["examples"]) < EXAMPLES and entity not in e["exemplified"]:
                e["exemplified"].add(entity)
                e["examples"].append(ex)


# ---------------------------------------------------------------------------------------------
# Geometry facts
# ---------------------------------------------------------------------------------------------
def _seg_dist2(p, a, b) -> float:
    ax, ay = a; bx, by = b; px, py = p
    dx, dy = bx - ax, by - ay
    L = dx * dx + dy * dy
    u = 0.0 if L == 0 else max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / L))
    qx, qy = ax + u * dx - px, ay + u * dy - py
    return qx * qx + qy * qy


def _inside(p, poly, box) -> bool:
    x, y = p
    if not (box[0] - EDGE_TOLERANCE <= x <= box[2] + EDGE_TOLERANCE and box[1] - EDGE_TOLERANCE <= y <= box[3] + EDGE_TOLERANCE):
        return False
    n, c = len(poly), False
    for i in range(n):
        (x1, y1), (x2, y2) = poly[i], poly[(i + 1) % n]
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
            c = not c
    if c:
        return True
    t2 = EDGE_TOLERANCE * EDGE_TOLERANCE
    return any(_seg_dist2(p, poly[i], poly[(i + 1) % n]) <= t2 for i in range(n))


def _containment(kinds: Kinds, first: dict[int, dict]) -> dict | None:
    """Where highways exist: per group (roadway, lane, intersection and their refinements), how many
    structures have every boundary vertex in one highway, every vertex in some highway, some, or none."""
    hw = []
    for st in first.values():
        b = st.get("boundary") or []
        if kinds.refines(st.get("kind"), "highway") and len(b) >= 3:
            xs, ys = [p[0] for p in b], [p[1] for p in b]
            hw.append((b, (min(xs), min(ys), max(xs), max(ys))))
    if not hw:
        return None
    out = {}
    for group in ("roadway", "lane", "intersection"):
        g = {"checked": 0, "in_one_highway": 0, "every_vertex_in_some_highway": 0, "partly": 0, "outside": 0,
             "no_boundary": 0, "examples": {}}
        for sid, st in first.items():
            if not kinds.refines(st.get("kind"), group):
                continue
            b = st.get("boundary") or []
            g["checked"] += 1
            if len(b) < 3:
                g["no_boundary"] += 1
                continue
            ins = [[_inside(p, poly, box) for poly, box in hw] for p in b]
            some = [any(r) for r in ins]
            if any(all(r[h] for r in ins) for h in range(len(hw))):
                g["in_one_highway"] += 1
            if all(some):
                g["every_vertex_in_some_highway"] += 1
            else:
                which = "partly" if any(some) else "outside"
                g[which] += 1
                g["examples"].setdefault(which, {"id": sid, "kind": st.get("kind"),
                                                 "vertices_outside": sum(not s for s in some), "vertices": len(b)})
        out[group] = g
    return out


# ---------------------------------------------------------------------------------------------
# One recording
# ---------------------------------------------------------------------------------------------
def observed(state) -> bool:
    return state not in (None, "absent")


def check(scenes, manifest: dict, kinds: Kinds) -> dict:
    """The findings and facts of one recording, from its scenes (any iterable) and its manifest."""
    atoms = dict(manifest.get("atoms") or {})
    cap = lambda a: atoms.get(a, "absent")
    T = _Tally()
    first: dict[int, dict] = {}            # structure id → its first content
    last: dict[int, dict] = {}
    changed = set()
    labelled = {"structure": {}, "device": {}, "road user": {}}      # kind → {entity: example}
    listed = {"structure": {}, "device": {}, "road user": {}}        # kind → {entity: example}, where the listing takes effect
    entered, intersections = set(), {}
    ways_named = ways_bad = 0
    n = 0

    def note(store, k, ent, ex):
        store.setdefault(k, {}).setdefault(ent, ex)

    for i, s in enumerate(scenes):
        n += 1
        t = s.get("t")
        subj = s.get("subject")
        users = s.get("users") or []
        tracks = [u.get("track") for u in users]
        if observed(cap("ru.subject")):
            T.add(("declaration", "ru.subject", "subject_missing", "scene"), i, subj is None or subj not in tracks, {"scene": i, "t": t})
        env = s.get("env") or {}
        for a, k in ENV.items():
            if observed(cap(a)):
                T.add(("declaration", a, "field_missing", "scene"), i, env.get(k) is None, {"scene": i, "t": t})
        oo = s.get("occupancy_observed")
        covered = set(tracks) if oo is True else set(oo) if isinstance(oo, list) else set()
        for u in users:
            tr = u.get("track")
            is_subj = tr == subj
            who = "subject" if is_subj else "other road user"
            ex = {"scene": i, "t": t, "track": tr}
            if observed(cap("rel.occupies")):
                T.add(("declaration", "rel.occupies", "occupancy_not_observed", "road user"), tr, tr not in covered, ex)
            for c in u.get("classes") or []:
                note(labelled["road user"], c, tr, ex)
            for c in u.get("unobserved_classes") or []:
                note(listed["road user"], c, tr, ex)
            kin, sig = u.get("kin") or {}, u.get("sig") or {}
            for a, k in KIN.items():
                st_ = cap(a)
                if observed(st_) and (is_subj or st_ != "subject"):
                    T.add(("declaration", a, "field_missing", who), tr, kin.get(k) is None, ex)
            carrier = is_subj or SIGNALLING_CLASS in (u.get("classes") or [])
            for a, k in SIG.items():
                st_ = cap(a)
                if carrier and observed(st_) and (is_subj or st_ != "subject"):
                    T.add(("declaration", a, "field_missing", who), tr, sig.get(k) is None, ex)
        for d in s.get("devices") or []:
            did, dk = d.get("id"), d.get("kind")
            ex = {"scene": i, "t": t, "device": did, "kind": dk}
            note(labelled["device"], dk, did, ex)
            for k in d.get("unobserved_kinds") or []:
                note(listed["device"], k, did, ex)
            if observed(cap("dev.governs")):
                T.add(("association", "dev.governs", "relation_missing", "device"), did, "governs" not in d, ex)
            if observed(cap("dev.position")):
                T.add(("declaration", "dev.position", "field_missing", "device"), did, d.get("position") is None, ex)
            if observed(cap("dev." + str(dk))):
                for f in DEVICE_FIELDS.get(dk, ()):
                    T.add(("declaration", "dev." + dk, f"{f}_missing", "device"), did, d.get(f) is None, ex)
        for st in s.get("structures") or []:
            sid = st.get("id")
            if last.get(sid) == st:
                continue
            if sid in last:
                changed.add(sid)
            else:
                first[sid] = st
            last[sid] = st
            k = st.get("kind")
            ex = {"scene": i, "t": t, "structure": sid, "kind": k}
            note(labelled["structure"], k, sid, ex)
            for m in st.get("unobserved_kinds") or []:
                if m in kinds.structures and k in kinds.structures and kinds.mask_applies(k, m):
                    note(listed["structure"], m, sid, ex)
            lane = st.get("lane") or {}
            if lane.get("enters_intersection") is not None:
                entered.add(lane["enters_intersection"])
            if k in kinds.structures and kinds.refines(k, "intersection"):
                intersections.setdefault(sid, ex)
            if st.get("ways") is not None:
                ways_named += 1
            for atom, carrier, excluded, path in STRUCTURE_FIELDS:
                if observed(cap(atom)) and k in kinds.structures and kinds.refines(k, carrier) \
                        and not any(kinds.refines(k, x) for x in excluded):
                    T.add(("declaration", atom, f"{'.'.join(p for p in path if p != 'key')}_missing", "structure"), sid,
                          not _has(st, path), ex)
            if observed(cap("st.region_geometry")):
                T.add(("declaration", "st.region_geometry", "boundary_or_position_missing", "structure"), sid,
                      not st.get("boundary") and st.get("position") is None, ex)
            if observed(cap("st.entrance_of")) and k in kinds.structures and (kinds.refines(k, "stop_line") or kinds.refines(k, "crosswalk")):
                T.add(("association", "st.entrance_of", "relation_missing", "structure"), sid, "entrance_of" not in st, ex)
            if observed(cap("st.on_way")) and not (k in kinds.structures and kinds.refines(k, "highway")):
                T.add(("association", "st.on_way", "relation_missing", "structure"), sid, "ways" not in st, ex)

    if observed(cap("st.lane_enters")):
        for sid, ex in sorted(intersections.items()):
            T.add(("association", "st.lane_enters", "intersection_not_entered", "structure"), sid, sid not in entered, ex)
    for st in first.values():
        for w in st.get("ways") or []:
            if not (first.get(w) and kinds.refines(first[w].get("kind"), "highway")):
                ways_bad += 1

    findings = []

    def finding(case, family, atom, chk, entity, e=None, **extra):
        f = {"case": case, "family": family, "atom": atom, "check": chk, "entity": entity}
        if e is not None:
            f.update({"entities": len(e["entities"]), "observations": e["observations"], "checked": e["checked"],
                      "checked_entities": len(e["checked_entities"]), "examples": e["examples"]})
        f.update(extra)
        findings.append(f)

    # observability of kinds: every concrete kind of each entity family the manifest names or the trace holds
    families = (("structure", "st.", [k for k in kinds.structures if k not in kinds.abstract]),
                ("device", "dev.", list(kinds.devices)), ("road user", "ru.", list(kinds.classes)))
    for ent, prefix, all_kinds in families:
        for k in all_kinds:
            atom = prefix + k
            if ent == "structure":
                present = {e: x for lab in kinds.of_kind(k) for e, x in labelled[ent].get(lab, {}).items()}
            else:
                present = labelled[ent].get(k, {})
            ex = [present[e] for e in sorted(present, key=lambda e: (present[e].get("scene", 0), str(e)))][:EXAMPLES]
            if not observed(cap(atom)):
                if present:
                    finding("iii", "declaration", atom, "labelled_but_declared_absent", ent, entities=len(present), examples=ex)
                else:
                    finding("ii", "declaration", atom, "declared_absent", ent)
                continue
            if not present:
                finding("i", "declaration", atom, "declared_observed_none_present", ent)
            lst = listed[ent].get(k, {})
            if lst:
                lex = [lst[e] for e in sorted(lst, key=lambda e: (lst[e].get("scene", 0), str(e)))][:EXAMPLES]
                finding("iii", "declaration", atom, "listed_unobserved_but_declared_observed", ent, entities=len(lst), examples=lex)

    # fields and relations: each check of an atom the manifest observes, by what it found
    checked_atoms = set()
    for (family, atom, chk, entity), e in sorted(T.t.items()):
        checked_atoms.add(atom)
        if e["observations"]:
            finding("iii", family, atom, chk, entity, e)
    field_atoms = ({a for a, *_ in STRUCTURE_FIELDS} | set(KIN) | set(SIG) | set(ENV)
                   | {"st.region_geometry", "st.entrance_of", "st.on_way", "st.lane_enters", "dev.governs", "dev.position",
                      "rel.occupies", "ru.subject"})
    for atom in sorted(field_atoms):
        family = "association" if atom in ("st.entrance_of", "st.on_way", "st.lane_enters", "dev.governs") else "declaration"
        if not observed(cap(atom)):
            finding("ii", family, atom, "declared_absent", "")
        elif atom not in checked_atoms:
            finding("i", family, atom, "declared_observed_none_present", "")

    findings.sort(key=lambda f: (CASES.index(f["case"]), f["family"], f["atom"], f["check"], f["entity"]))
    facts = {"scenes": n, "structures": len(first), "structures_changed": len(changed),
             "structure_kinds": dict(sorted(Counter(st.get("kind") for st in first.values()).items(), key=lambda x: str(x[0]))),
             "highway": {"st.highway": cap("st.highway"), "st.on_way": cap("st.on_way"),
                         "highways": sum(1 for st in first.values() if kinds.refines(st.get("kind"), "highway")),
                         "structures_naming_ways": ways_named, "ways_not_a_highway": ways_bad,
                         "containment": _containment(kinds, first)}}
    return {"findings": findings, "facts": facts}


def _sha_reader(stream, h):
    class R:
        def read(self, k=-1):
            b = stream.read(k)
            h.update(b)
            return b
    return R()


def check_files(trace: Path, manifest: Path, library: Path | None = None) -> dict:
    """One recording's report from its files, streamed (the trace is never held whole), with the
    sha256 of the trace and the manifest it was computed on; a file that cannot be read gives an
    `error` and no findings."""
    out = {"trace_sha256": None, "manifest_sha256": None}
    try:
        kinds = Kinds.from_library(library)
        mb = Path(manifest).read_bytes()
        out["manifest_sha256"] = hashlib.sha256(mb).hexdigest()
        h = hashlib.sha256()
        with Path(trace).open("rb") as f:
            rep = check(projection.iter_scenes(_sha_reader(f, h), chunk_size=1 << 22), json.loads(mb), kinds)
            while f.read(1 << 22):
                pass
        out["trace_sha256"] = h.hexdigest()
        out.update(rep)
    except Exception as e:                       # a report: an unreadable recording is said so, never raised
        out["error"] = f"{type(e).__name__}: {str(e)[:300]}"
        out.update({"findings": [], "facts": {}})
    return out


def version(library: Path | None = None) -> str:
    """The digest a stored report is bound to: this module and the library's ontology."""
    return hashlib.sha256(Path(__file__).read_bytes() + Kinds.from_library(library).digest.encode()).hexdigest()


def _one(args):
    rid, trace, manifest, library = args
    return rid, check_files(Path(trace), Path(manifest), library)


def run(items: list[tuple[str, Path, Path]], jobs: int = 8, library: Path | None = None) -> dict[str, dict]:
    """Reports of several recordings, `(recording id, trace, manifest)`, in processes; keyed by id in
    sorted order."""
    args = [(rid, str(t), str(m), library) for rid, t, m in items]
    if jobs <= 1 or len(args) <= 1:
        res = [_one(a) for a in args]
    else:
        with ProcessPoolExecutor(min(jobs, len(args))) as pool:
            res = list(pool.map(_one, args))
    return dict(sorted(res))


def ensure(path: Path, ds, rids: list[str], bound: dict[str, dict] | None = None, jobs: int = 8,
           library: Path | None = None) -> dict[str, dict]:
    """The reports of `rids` of dataset `ds` (each recording's trace against its source's manifest),
    kept in `path` with the run: a report already there is
    reused when it was made by this version on the same trace and manifest (`bound`, recording id →
    {"trace", "manifest"} sha256, as the run's fixed comparison set has them); every other one is
    computed once and the file rewritten. A report whose files differ from `bound` says so in its
    `error`. Returns recording id → report."""
    path = Path(path)
    ver = version(library)
    try:
        was = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}
    except (OSError, ValueError):
        was = {}
    stored = was.get("recordings", {}) if was.get("version") == ver else {}
    bound = bound or {}

    def fits(rid):
        r, b = stored.get(rid), bound.get(rid)
        return bool(r and b and b.get("trace") and r.get("trace_sha256") == b["trace"] and r.get("manifest_sha256") == b["manifest"])

    todo = [rid for rid in sorted(set(rids)) if not fits(rid)]
    new = run([(rid, ds.files(rid)["trace"], ds.files(rid)["manifest"]) for rid in todo], jobs, library) if todo else {}
    for rid, r in new.items():
        b = bound.get(rid)
        if b and b.get("trace") and not r.get("error") and (r["trace_sha256"], r["manifest_sha256"]) != (b["trace"], b["manifest"]):
            r["error"] = "the trace or manifest is not the one the run's comparison set fixed"
    recs = {**stored, **new}
    if new or not path.exists():
        doc = {"version": ver, "data_version": ds.data_version, "recordings": dict(sorted(recs.items()))}
        path.parent.mkdir(parents=True, exist_ok=True)
        tmp = path.with_name(path.name + ".tmp")
        tmp.write_text(json.dumps(doc, indent=1, sort_keys=True) + "\n", encoding="utf-8")
        os.replace(tmp, path)
    return {rid: recs[rid] for rid in sorted(set(rids))}


# ---------------------------------------------------------------------------------------------
# Summaries
# ---------------------------------------------------------------------------------------------
def key(f: dict) -> str:
    return ":".join(x for x in (f["family"], f["atom"], f["check"], f["entity"]) if x)


def summary(reports: dict[str, dict], per_recording: bool = True) -> dict:
    """Over some recordings: per case, each finding with the number of recordings that have it; the
    number of recordings with a finding of each case; the unreadable ones; and per recording the
    keys of its case `iii` findings with the number of its `i` and `ii` findings."""
    by = {c: Counter() for c in CASES}
    with_ = Counter()
    per = {}
    for rid, r in sorted(reports.items()):
        fs = (r or {}).get("findings", [])
        for c in CASES:
            ks = sorted({key(f) for f in fs if f["case"] == c})
            by[c].update(ks)
            with_[c] += bool(ks)
        per[rid] = {"iii": sorted({key(f) for f in fs if f["case"] == "iii"}),
                    "i": sum(f["case"] == "i" for f in fs), "ii": sum(f["case"] == "ii" for f in fs)}
    out = {"recordings": len(reports), "unreadable": sorted(rid for rid, r in reports.items() if not r or r.get("error")),
           "recordings_with": {c: with_[c] for c in CASES},
           "findings": {c: dict(sorted(by[c].items(), key=lambda x: (-x[1], x[0]))) for c in CASES}}
    if per_recording:
        out["per_recording"] = per
    return out


def main(argv: list[str]) -> int:
    """python -m recorded.source_check <dataset folder> [--out FILE] [--laws A,B] [--jobs N]: each
    recording's trace against its source's manifest"""
    import argparse
    from . import dataset as dataset_mod
    p = argparse.ArgumentParser(prog="python -m recorded.source_check", description=main.__doc__)
    p.add_argument("dataset")
    p.add_argument("--out", default="")
    p.add_argument("--laws", default="")
    p.add_argument("--jobs", type=int, default=8)
    a = p.parse_args(argv)
    ds = dataset_mod.Dataset(a.dataset)
    laws = {x for x in a.laws.split(",") if x}
    rows = [r for r in ds.rows if not laws or r["law_id"] in laws]
    reports = run([(r["recording_id"], ds.files(r["recording_id"])["trace"], ds.files(r["recording_id"])["manifest"]) for r in rows], a.jobs)
    index = {r["recording_id"]: r for r in rows}
    for rid, r in reports.items():
        bad = [k for k, want in ds.expected_sha256(rid).items() if want != r.get(f"{k}_sha256")]
        if bad and not r.get("error"):
            r["error"] = f"its {' and '.join(bad)} differ from what the dataset states"
    per_law = {law: summary({rid: rep for rid, rep in reports.items() if index[rid]["law_id"] == law}, per_recording=False)
               for law in sorted({r["law_id"] for r in rows})}
    whole = summary(reports)
    doc = {"dataset": str(ds.path), "data_version": ds.data_version, "version": version(), "summary": whole,
           "per_law": per_law, "recordings": reports}
    if a.out:
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Path(a.out).write_text(json.dumps(doc, indent=1, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({k: v for k, v in whole.items() if k != "per_recording"}, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
