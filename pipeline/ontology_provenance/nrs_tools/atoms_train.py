"""Derive the training-only ontology artifacts from the full ones and `split_atoms.json`.

    python -m nrs_tools.atoms_train        # from pipeline/ontology_provenance, after nrs_tools.split

Writes
  traffic-spec-agent/ontology/ATOMS_train.md                 ATOMS.md without the test-only atoms, values
                                                             and derived concepts
  traffic-spec-agent/library/splits/train/TrafficSpec/Core/Atoms.lean
                                                             Atoms.lean without their definitions
  traffic-spec-agent/library/splits/train/TrafficSpec/Core/Ontology/*.lean
                                                             generated from ATOMS_train.md by gen_ontology

The training run swaps these three over the full ones (the tree under splits/train mirrors the
library). Nothing else in Core is touched: the other files are audited (SPLIT_AUDIT.md), not split.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PIPE = HERE.parents[1]
AGENT = PIPE / "traffic-spec-agent"
SPLIT = AGENT / "laws" / "example" / "split_atoms.json"
ATOMS_MD = AGENT / "ontology" / "ATOMS.md"
ATOMS_TRAIN_MD = AGENT / "ontology" / "ATOMS_train.md"
ATOMS_LEAN = AGENT / "library" / "TrafficSpec" / "Core" / "Atoms.lean"
TRAIN_ROOT = AGENT / "library" / "splits" / "train" / "TrafficSpec" / "Core"

#: Operationalization rows (ATOMS.md §8) that name a test-only concept as an aid; the clause is
#: dropped in the training variant. (row fragment, replacement)
SECTION8_EDITS = [
    ("`drv.speed_below_traffic` with `drv.queue_behind`", "`drv.speed_below_traffic`"),
    ("the speed margin, the queue size, the duration", "the speed margin, the duration"),
    ("`drv.standing_or_parked` with `sig.door_open` or a passenger exchange", "`drv.standing_or_parked` with a passenger exchange"),
]


def def_name(atom_id: str) -> str:
    return atom_id.replace(".", "_")


def filter_atoms_md(text: str, atoms: list[str], values: list[str], derived: list[str]) -> str:
    out = []
    drop_ids = set(atoms) | set(derived)
    for line in text.splitlines():
        m = re.match(r"^\| `([a-z]+\.[a-z_]+)` \|", line)
        if m and m.group(1) in drop_ids:
            continue
        for aid, val in (v.split("=") for v in values):
            if m and m.group(1) == aid:
                # inside a `{a, b, val, c}` set or a `: a, b, val, c **Not` code list
                line = re.sub(r"(\{[^}]*?), " + re.escape(val) + r"(?=[,}])", r"\1", line)
                line = re.sub(r"(\{)" + re.escape(val) + r", ", r"\1", line)
                line = re.sub(r", " + re.escape(val) + r"(?= \*\*Not|,)", "", line)
        for old, new in SECTION8_EDITS:
            line = line.replace(old, new)
        out.append(line)
    banner = ("<!-- TRAINING SPLIT. Generated from ATOMS.md by ontology_provenance/nrs_tools/atoms_train.py:\n"
              "     the atoms, values and derived concepts whose only textual support is a test line are\n"
              "     omitted. Do not edit; edit ATOMS.md or the split and regenerate. -->\n")
    return banner + "\n".join(out) + "\n"


def filter_atoms_lean(text: str, atoms: list[str]) -> str:
    names = [def_name(a) for a in atoms]
    lines = text.splitlines()
    keep, i = [], 0
    while i < len(lines):
        line = lines[i]
        m = re.match(r"^(?:private )?def ([a-z]+_\w+)", line)
        if m and any(m.group(1) == n or m.group(1).startswith(n + "_") for n in names):
            # drop a one-line doc comment right above, and the def with its indented continuation
            if keep and keep[-1].startswith("/--") and keep[-1].rstrip().endswith("-/"):
                keep.pop()
            i += 1
            while i < len(lines) and (lines[i].startswith("  ") or lines[i].startswith("\t")):
                i += 1
            continue
        keep.append(line)
        i += 1
    banner = ("/-\n  TRAINING SPLIT of TrafficSpec.Core.Atoms. Generated from Core/Atoms.lean by\n"
              "  ontology_provenance/nrs_tools/atoms_train.py: the definitions of the atoms whose only textual\n"
              "  support is a test line are omitted. Do not edit; regenerate.\n-/\n")
    return banner + "\n".join(keep) + "\n"


def main() -> int:
    split = json.loads(SPLIT.read_text(encoding="utf-8"))
    atoms, values, derived = split["test_only_atoms"], split["test_only_values"], split["test_only_derived"]
    ATOMS_TRAIN_MD.write_text(filter_atoms_md(ATOMS_MD.read_text(encoding="utf-8"), atoms, values, derived), encoding="utf-8")
    TRAIN_ROOT.mkdir(parents=True, exist_ok=True)
    (TRAIN_ROOT / "Atoms.lean").write_text(filter_atoms_lean(ATOMS_LEAN.read_text(encoding="utf-8"), atoms), encoding="utf-8")
    r = subprocess.run([sys.executable, "-m", "scripts.gen_ontology", "--atoms", str(ATOMS_TRAIN_MD),
                        "--out", str(TRAIN_ROOT / "Ontology")], cwd=AGENT, capture_output=True, text=True)
    print(r.stdout.strip(), r.stderr.strip())
    # what the training ontology still says about a test-only concept, for the reviewer
    words = re.compile(r"school bus|turnout|roundabout|rotary|delivery device|carrying device|skate|low-speed|"
                       r"vending|compression brake|reversing lamp|steering angle|signal arm|door|queue", re.I)
    residue = [f"  ATOMS_train.md:{n}: {l[:120]}" for n, l in enumerate(ATOMS_TRAIN_MD.read_text(encoding='utf-8').splitlines(), 1) if words.search(l)]
    print(f"removed {len(atoms)} atoms, {len(values)} values, {len(derived)} derived concepts")
    print("training ontology lines still mentioning a test-only concept (reviewed in SPLIT.md):")
    print("\n".join(residue) or "  none")
    return r.returncode


if __name__ == "__main__":
    sys.exit(main())
