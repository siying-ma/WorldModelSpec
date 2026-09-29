"""Split the pipeline corpus into a training set (build the autoformalization repository) and a
test set (new legislation: rules, road structures and devices the repository has never seen).

    python -m nrs_tools.split          # from pipeline/ontology_provenance

Reads  laws/full_list/{laws.jsonl, definitions.jsonl} (posted law) and the analysis sidecars
       laws/audit_and_scripts/{laws_meta.jsonl, definitions_meta.jsonl} (tier, refs, terms, used_by).
Writes laws/example/train/{laws.jsonl, definitions.jsonl}, laws/example/test/{laws.jsonl,
       definitions.jsonl} — a split is a directory, so `--laws laws/example/train/laws.jsonl` makes
       the plan phase read the definitions beside it and nothing else — plus
       laws/audit_and_scripts/{split_atoms.json, SPLIT.md}.

The test set is chosen by hand (TEST below, with the reason per line) and then held to the
constraints the split must satisfy, which this script checks and refuses to write otherwise:

  1. Self-containment. No training line references a test line (`refs`), so the repository built
     from the training set never depends on a law it has not seen. Test lines may reference
     training lines: new legislation builds on the existing code.
  2. New atoms. The test set introduces concrete atoms and enumeration values that no training
     line mentions, so the evaluation measures the ability to extend the ontology, not only to
     reuse it. Support is computed two ways and unioned: the provenance document's hand-written
     statute references per atom, and a keyword lexicon over the verbatim text (atom_lexicon.py).
  3. Definitions. A definition record follows the lines that use it: one used only by test lines,
     or whose term occurs in no training text, goes to the test side.
"""
from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from atom_lexicon import ATOMS, VALUES, scan  # noqa: E402

HERE = Path(__file__).resolve().parent
PIPE = HERE.parents[1]
LAWS_ROOT = PIPE / "traffic-spec-agent" / "laws"
CORPUS_DIR = LAWS_ROOT / "full_list"          # the unsplit corpus this script reads
SPLIT_DIR = LAWS_ROOT / "example"             # train/ and test/ are written here
AUDIT_DIR = LAWS_ROOT / "audit_and_scripts"   # split_atoms.json and SPLIT.md
PROVENANCE = HERE.parent / "nrs_atoms_provenance.md"
ATOMS_MD = PIPE / "traffic-spec-agent" / "ontology" / "ATOMS.md"

# --------------------------------------------------------------------------------------------
# The test set: 29 of 285 lines (10.2%), in clusters that each bring something the training set
# never mentions. "Ordinary" lines test plain generalization to a new rule over known atoms.
# --------------------------------------------------------------------------------------------
TEST: dict[str, str] = {
    # a device class the statute created in 2019: rights of a pedestrian, its own duties
    "NRS-484B-787-2a": "personal delivery device: new road-user class `ru.personal_delivery_device`",
    "NRS-484B-787-2b": "personal delivery device: same class, device-obedience duty",
    "NRS-484B-787-2c": "personal delivery device: same class, interference standard (tier S)",
    # a second statute-created device class (2021)
    "NRS-484B-790-2a": "mobile carrying device: new road-user class `ru.mobile_carrying_device`",
    "NRS-484B-790-2b": "mobile carrying device: same class, device-obedience duty",
    "NRS-484B-790-2c": "mobile carrying device: same class, interference standard (tier S)",
    # a road structure with its own traffic pattern
    "NRS-484B-220-2": "rotary island: new structure `st.roundabout` (statute wording)",
    "LVMC-11-43-010-A": "roundabout: circulation direction",
    "LVMC-11-43-010-B": "roundabout: yield on entry",
    "LVMC-11-43-010-C1": "roundabout: exit lane discipline (left)",
    "LVMC-11-43-010-C2": "roundabout: exit lane discipline (right)",
    # a vehicle class the statute defines by speed capability
    "NRS-484B-637-2b": "low-speed vehicle: new class `ru.low_speed_vehicle`, posted-limit condition",
    # a vending vehicle with engaged safety equipment
    "LVMC-11-22-150-A": "ice cream truck: new class `ru.vending_vehicle` (tier S)",
    "LVMC-11-22-150-B": "ice cream truck: same class, 15 mph within 100 ft",
    # an audible device
    "NRS-484D-285-1": "engine compression brake: new signal `sig.compression_brake` (tier Q)",
    # a structure designated by sign
    "NRS-484B-630-1": "slow vehicle with five following: new structure `st.turnout`, queue concept (tier Q)",
    # doors
    "NRS-484B-153-2": "opening a door toward traffic: new signal `sig.door_open` (tier Q)",
    "NRS-484B-153-3": "door left open: same signal (tier Q)",
    # a lamp state
    "NRS-484D-205-4": "backup lamps in forward motion: new signal `sig.reverse_lamp`",
    # a steering input as the obligation itself
    "NRS-484B-533": "unattended on a grade: new kinematic atom `kin.steer_angle`",
    # small wheeled devices with pedestrian duties
    "LVMC-11-22-130-A": "coasters, skates, skateboards: new class `ru.other_conveyance`",
    "LVMC-11-22-130-B": "same class: posted sidewalk prohibition",
    "LVMC-11-22-130-C": "same class: posted property prohibition",
    # school bus stop
    "NRS-484B-353-1": "stopped school bus with flashing red: new class `ru.school_bus`, device `dev.school_bus_signal`",
    "NRS-484B-360-1": "school bus speed cap: same class",
    # a sign kind
    "NRS-484B-633-2": "bridge speed: new sign kind `dev.speed_limit_sign` = structure_maximum",
    # ordinary new rule over known atoms (a reversible lane): plain generalization
    "LVMC-11-42-030": "reversible lanes by sign and period: ordinary line over known atoms",
    # two ordinary lines, so the test set is not only new-atom lines
    "LVMC-11-12-100-C": "two-way left-turn lane discipline: ordinary line over known atoms",
    "NRS-484B-450-1m": "no stopping on a bridge or in a tunnel: ordinary line over known atoms",
}

# Atoms with no support on either side are ontology design, not test knowledge: they stay in the
# training ontology. Listed so the report can say so.
ZERO_SUPPORT_STAY = ("sig.brake_lamp", "sig.hazard", "sig.signal_arm")


def load(name: str, root: Path = None) -> list[dict]:
    return [json.loads(l) for l in ((root or CORPUS_DIR) / name).read_text(encoding="utf-8").splitlines() if l.strip()]


def with_meta(rows: list[dict], meta_name: str) -> list[dict]:
    """Posted records joined with their analysis sidecar (the split reads tier, refs, terms, used_by)."""
    meta = {m["id"]: m for m in load(meta_name, AUDIT_DIR)}
    return [{**meta.get(r["id"], {}), **r} for r in rows]


def posted(rows: list[dict]) -> list[dict]:
    return [{k: r[k] for k in ("id", "title", "text", "source") if k in r} for r in rows]


def dump(name: str, rows: list[dict]) -> None:
    path = SPLIT_DIR / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows), encoding="utf-8")


# --------------------------------------------------------------------------------------------
# Provenance: statute references per atom → corpus line ids
# --------------------------------------------------------------------------------------------
SEC = re.compile(r"(484[ABD]|486)\.(\d{3})(?!\d)(\(\d+\))?|(?<![\d.])\.(\d{3})(?!\d)(\(\d+\))?|LVMC (11)\.(\d{2})\.(\d{3})(?!\d)(\([A-Z]\))?|(?<=[,;] )(\d{2})\.(\d{3})(?!\d)(\([A-Z]\))?")


def _sub(g: str | None) -> str:
    """`(2)` → `-2`, `(A)` → `-A`: the subsection part of a corpus line id."""
    return "-" + g.strip("()") if g else ""


def provenance_support(law_ids: list[str]) -> dict[str, set[str]]:
    text = PROVENANCE.read_text(encoding="utf-8")
    out: dict[str, set[str]] = defaultdict(set)
    for m in re.finditer(r"^\| ((?:`[a-z]+\.[a-z_]+`[^|]*?)+) \| ([^|]*) \|", text, re.M):
        atoms = re.findall(r"`([a-z]+\.[a-z_]+)`", m.group(1))
        prov = m.group(2)
        chapter = None
        prefixes = []
        for s in SEC.finditer(prov):
            if s.group(1):
                chapter = s.group(1); prefixes.append(f"NRS-{chapter}-{s.group(2)}{_sub(s.group(3))}")
            elif s.group(4) and chapter and chapter != "LVMC":
                prefixes.append(f"NRS-{chapter}-{s.group(4)}{_sub(s.group(5))}")
            elif s.group(6):
                chapter = "LVMC"; prefixes.append(f"LVMC-11-{s.group(7)}-{s.group(8)}{_sub(s.group(9))}")
            elif s.group(10) and chapter == "LVMC":
                prefixes.append(f"LVMC-11-{s.group(10)}-{s.group(11)}{_sub(s.group(12))}")
        for a in atoms:
            for p in prefixes:
                for lid in law_ids:
                    if lid == p or lid.startswith(p + "-"):
                        out[a].add(lid)
    return out


def main() -> int:
    laws = with_meta(load("laws.jsonl"), "laws_meta.jsonl")
    defs = with_meta(load("definitions.jsonl"), "definitions_meta.jsonl")
    if not all("tier" in x for x in laws):
        print("laws_meta.jsonl lacks a tier for some line; run nrs_tools.publish first"); return 1
    ids = [x["id"] for x in laws]
    by_id = {x["id"]: x for x in laws}
    missing = [t for t in TEST if t not in by_id]
    if missing:
        print("test ids not in the corpus:", missing); return 1
    test_ids = set(TEST)
    train = [x for x in laws if x["id"] not in test_ids]
    test = [x for x in laws if x["id"] in test_ids]

    # 1. self-containment
    leaks = [(x["id"], r) for x in train for r in x.get("refs", []) if r in test_ids]
    if leaks:
        print("training lines reference test lines:", leaks); return 1
    back_refs = [(x["id"], r) for x in test for r in x.get("refs", []) if r in by_id and r not in test_ids]

    # 2. atom support, both ways
    lex_atoms: dict[str, set[str]] = defaultdict(set)
    lex_values: dict[str, set[str]] = defaultdict(set)
    for x in laws:
        a, v = scan(x["text"] + " " + x["title"])
        for k in a: lex_atoms[k].add(x["id"])
        for k in v: lex_values[k].add(x["id"])
    prov = provenance_support(ids)
    support = {a: lex_atoms.get(a, set()) | prov.get(a, set()) for a in ATOMS}
    drv_support = {a: s for a, s in prov.items() if a.startswith("drv.")}

    def side(s: set[str]) -> str:
        if not s: return "none"
        if s <= test_ids: return "test-only"
        if not (s & test_ids): return "train-only"
        return "both"

    test_only_atoms = sorted(a for a, s in support.items() if side(s) == "test-only")
    zero = sorted(a for a, s in support.items() if not s)
    test_only_values = sorted(v for v, s in lex_values.items() if side(s) == "test-only"
                              and v.split("=")[0] not in test_only_atoms)
    test_only_drv = sorted(a for a, s in drv_support.items() if side(s) == "test-only")
    both_atoms = sorted(a for a, s in support.items() if side(s) == "both")

    # 3. definitions
    train_text = " ".join((x["text"] + " " + x["title"]).lower() for x in train)
    defs_train, defs_test, def_reasons = [], [], []
    for d in defs:
        used = set(d.get("used_by") or [])
        terms = [t.lower() for t in (d.get("terms") or [])]
        if used and used <= test_ids:
            defs_test.append(d); def_reasons.append((d["id"], f"used only by {sorted(used)}")); continue
        if terms and not any(re.search(r"\b" + re.escape(t) + r"s?\b", train_text) for t in terms) \
                and any(re.search(r"\b" + re.escape(t) + r"s?\b", (x["text"] + " " + x["title"]).lower())
                        for t in terms for x in test):
            defs_test.append(d); def_reasons.append((d["id"], f"terms {terms} occur only in test text")); continue
        defs_train.append(d)

    # outputs
    dump("train/laws.jsonl", posted(train))
    dump("test/laws.jsonl", posted(test))
    dump("train/definitions.jsonl", posted(defs_train))
    dump("test/definitions.jsonl", posted(defs_test))
    (AUDIT_DIR / "split_atoms.json").write_text(json.dumps({
        "test_ids": sorted(test_ids),
        "test_only_atoms": test_only_atoms,
        "test_only_values": test_only_values,
        "test_only_primitives": [],   # concepts are pipeline nodes since 2026-09-28; no primitive is test-only
        "zero_support_atoms_kept_in_train": zero,
        "train_atoms": sorted(a for a in ATOMS if a not in test_only_atoms),
    }, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")

    # report
    tiers = lambda rows: {t: sum(1 for r in rows if r["tier"] == t) for t in ("C", "Q", "S")}
    themes = defaultdict(int)
    for x in test: themes[x["theme"]] += 1
    L = []
    L.append("# Corpus split — training and test (2026-09-20)\n")
    L.append("Generated by `ontology_provenance/nrs_tools/split.py`; do not edit by hand.\n")
    L.append(f"| set | lines | C | Q | S | file |\n|---|---|---|---|---|---|")
    L.append(f"| training | {len(train)} | {tiers(train)['C']} | {tiers(train)['Q']} | {tiers(train)['S']} | `example/train/laws.jsonl` |")
    L.append(f"| test | {len(test)} ({100*len(test)/len(laws):.1f}%) | {tiers(test)['C']} | {tiers(test)['Q']} | {tiers(test)['S']} | `example/test/laws.jsonl` |")
    L.append(f"| definitions | {len(defs_train)} training / {len(defs_test)} test | | | | `example/train/definitions.jsonl`, `example/test/definitions.jsonl` |\n")
    L.append("Run the pipeline on a split with `--laws laws/example/train/laws.jsonl`: the plan phase reads the "
             "`definitions.jsonl` beside the corpus it is given, so the test definitions never reach a training run. "
             "The split files are posted law (`id`, `title`, `text`, `source`); the tiers, themes and references "
             "this report uses come from `audit_and_scripts/laws_meta.jsonl`.\n")
    L.append("## Purpose\n")
    L.append("The training set builds the autoformalization repository: its ontology, derived concepts, plans and rules. "
             "The test set stands for legislation the repository has never seen — new road-user classes the statute "
             "creates, a road structure with its own traffic pattern, new devices, new signals — and asks whether the "
             "pipeline can extend the ontology and formalize the new text, not only reuse what it has.\n")
    L.append("## Constraints checked\n")
    L.append("1. **Self-contained training set.** No training line references a test line. "
             f"Test lines referencing training lines (allowed, new law builds on old): {back_refs or 'none'}.")
    L.append("2. **The test set introduces atoms.** An atom or enumeration value is *test-only* when every corpus line "
             "that mentions it — by the provenance document's statute references or by the keyword lexicon over the "
             "verbatim text — is a test line. The lists below are what the training ontology must not contain.")
    L.append("3. **Definitions follow their lines.** A definition used only by test lines, or whose term occurs in no "
             "training text, is in `example/test/definitions.jsonl`.\n")
    L.append("## Training-only ontology artifacts\n")
    L.append("`ontology_provenance/nrs_tools/atoms_train.py` derives, from the lists below: `ontology/ATOMS_train.md`, "
             "`library/splits/train/TrafficSpec/Core/Atoms.lean` and `library/splits/train/TrafficSpec/Core/Ontology/*.lean` "
             "(generated from `ATOMS_train.md` by `gen_ontology.py --atoms … --out …`). A training run swaps these over the "
             "full files; the tree under `splits/train` mirrors the library. The other Core files are audited, not split: "
             "see `SPLIT_AUDIT.md`.\n")
    L.append("## Test lines and why\n")
    L.append("| line | tier | theme | brings |\n|---|---|---|---|")
    for x in test:
        L.append(f"| `{x['id']}` | {x['tier']} | {x['theme']} | {TEST[x['id']]} |")
    L.append(f"\nThemes in the test set: {dict(sorted(themes.items()))}.\n")
    L.append("## Atoms brought only by the test set\n")
    L.append("These atoms have no support in any training line. The training-only `ATOMS_train.md`, "
             "`Ontology/*` and `Atoms.lean` omit them; a training run that needs them has to discover them.\n")
    L.append("| atom | test lines that mention it |\n|---|---|")
    for a in test_only_atoms:
        L.append(f"| `{a}` | {', '.join(sorted(support[a]))} |")
    L.append("\n## Enumeration values brought only by the test set\n")
    L.append("Values of atoms that stay in the training ontology, but whose value no training line mentions "
             "(keyword lexicon; reviewed by hand in `split.py`).\n")
    L.append("| value | test lines |\n|---|---|")
    for v in test_only_values:
        L.append(f"| `{v}` | {', '.join(sorted(lex_values[v]))} |")
    L.append("\n## Derived concepts whose only provenance is a test line\n")
    L.append("Not atoms (ATOMS.md §9); reported for the audit of `Derived.lean`, which is not split.\n")
    for a in test_only_drv:
        L.append(f"- `{a}`: {', '.join(sorted(drv_support[a]))}")
    L.append("\n## Atoms with no textual support on either side\n")
    L.append(f"{', '.join(f'`{a}`' for a in zero)} — ontology design (equipment every source can observe), kept in the training ontology.\n")
    L.append("## Definitions moved to the test side\n")
    for did, why in def_reasons:
        L.append(f"- `{did}`: {why}")
    L.append("\n## Atoms shared by both sides (the test set also reuses the known vocabulary)\n")
    L.append(f"{len(both_atoms)} atoms: {', '.join(f'`{a}`' for a in both_atoms)}\n")
    L.append("## What was rejected, and why\n")
    L.append("- School zones (NRS 484B.363(1)–(4)), which would have brought `dev.speed_limit_beacon`: training lines "
             "NRS 484B.650(1) and 484B.403(1) reference them as exceptions, so moving them breaks self-containment.")
    L.append("- Lane-control signals (NRS 484B.307(12)): referenced by NRS 484B.300(1) (obedience to devices).")
    L.append("- The white-cane stop (LVMC 11.30.140(B)) and the school-crossing signal (LVMC 11.46.030): referenced by "
             "the pedestrian-signal lines NRS 484B.283(1).")
    L.append("- Centre turn lanes (NRS 484B.223(2),(3)) and the bridge sight-line rule (484B.213(2)(c)): referenced by "
             "484B.650(1), 484B.200(1) and 484B.270(2)(b).")
    L.append("- Safety zones (NRS 484B.110, .450(1)(h)): the pedestrian-signal lines 484B.283(1)(d) also name them, so the "
             "atom would not be test-only.")
    L.append("- Tour buses and the curb colour code (LVMC 11.52.030(A)): the colour code is the key to most municipal "
             "parking lines; moving it would gut the training parking corpus.")
    (AUDIT_DIR / "SPLIT.md").write_text("\n".join(L) + "\n", encoding="utf-8")

    for a in ("st.roundabout", "ru.school_bus", "dev.school_bus_signal", "sig.hazard", "sig.signal_arm", "sig.brake_lamp", "ru.other_conveyance", "st.turnout", "kin.steer_angle"):
        print(f"  {a}: lex={sorted(lex_atoms.get(a, []))} prov={sorted(prov.get(a, []))}")
    for v in ("dev.speed_limit_sign=structure_maximum",):
        print(f"  {v}: lex={sorted(lex_values.get(v, []))}")
    print(f"train {len(train)} test {len(test)} defs {len(defs_train)}/{len(defs_test)}")
    print("test-only atoms:", test_only_atoms)
    print("test-only values:", test_only_values)
    print("test-only drv:", test_only_drv)
    print("zero:", zero)
    print("back refs:", back_refs)
    return 0


if __name__ == "__main__":
    sys.exit(main())
