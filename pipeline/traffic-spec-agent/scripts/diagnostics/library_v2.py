"""Hold the Core v2 Lean library to its sources.

Every check compares a generated or declared list with the file that is supposed to agree with
it, and names both on failure:

- the `Ontology/*.lean` files on disk are exactly what `gen_ontology` produces from `ATOMS.md`;
- every atom id of `ATOMS.md` has one `def <family>_<name>` in `Atoms.lean`, every `def` there is
  an atom or an attribute accessor of one, and every name is dispatched by `Semantics.lean`;
- every `drv.*` id has one `def drv_*` in `Derived.lean`, and `Derived.derivedNames` and
  `Derived.reads` list exactly those;
- rule files import only the whitelisted Core modules;
- every registered manifest is complete over the atom ids.

No Lean is run: the Lean tests (`TrafficSpec/Tests/*.lean`) hold the same bijections at build
time through `#guard`; these checks make the failure legible without a build.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

from .doctor_result import Result, OK, FAIL, SKIP, VacuousCheck, _nonempty

#: Modules a rule file may import. A rule reads the world through the atoms and the derived
#: concepts and declares itself through Rule; it never sees the trace, the census or the builders.
RULE_IMPORT_WHITELIST = {
    "TrafficSpec.Core.Rule", "TrafficSpec.Core.Formula", "TrafficSpec.Core.Params",
    "TrafficSpec.Core.Units", "TrafficSpec.Core.Time", "TrafficSpec.Core.Tri",
    "TrafficSpec.Core.Ontology.RoadUser", "TrafficSpec.Core.Ontology.Structure",
    "TrafficSpec.Core.Ontology.Device", "TrafficSpec.Core.Ontology.Signal",
    "TrafficSpec.Core.Ontology.Ids",
}


def _def_name(atom_id: str) -> str:
    return atom_id.replace(".", "_")


class LibraryV2Checks:
    def __init__(self, repo_root: Path, library_root: Path):
        self.repo = repo_root
        self.lib = library_root
        self.core = library_root / "TrafficSpec" / "Core"

    def _ids(self) -> tuple[list[str], list[str]]:
        text = (self.core / "Ontology" / "Ids.lean").read_text(encoding="utf-8")
        atoms_part, _, derived_part = text.partition("def derivedIds")
        atoms = _nonempty(re.findall(r'^\s*"([a-z]+\.[a-z_]+)"', atoms_part, re.M), "atomIds")
        derived = _nonempty(re.findall(r'^\s*"(drv\.[a-z_]+)"', derived_part, re.M), "derivedIds")
        return atoms, derived

    def ontology_generated_in_sync(self) -> Result:
        src = ("ontology/ATOMS.md → scripts/gen_ontology.py",
               "library/TrafficSpec/Core/Ontology/*.lean")
        from scripts import gen_ontology
        active = (self.lib / "splits" / "ACTIVE")
        which = active.read_text().strip() if active.exists() else "full"
        atoms_md = self.repo / "ontology" / ("ATOMS_train.md" if which == "train" else "ATOMS.md")
        src = (f"ontology/{atoms_md.name} → scripts/gen_ontology.py (active split: {which})",
               "library/TrafficSpec/Core/Ontology/*.lean")
        files = gen_ontology.generate(atoms_md)
        out = self.core / "Ontology"
        drift = [n for n, t in files.items()
                 if not (out / n).exists() or (out / n).read_text(encoding="utf-8") != t]
        stale = [p.name for p in out.glob("*.lean") if p.name not in files]
        if drift or stale:
            return Result("ontology generated", FAIL, f"drift: {drift}; stale: {stale}", src)
        return Result("ontology generated", OK, f"{len(files)} files match the generator", src)

    def training_split_in_sync(self) -> Result:
        """The training-only ontology (a split of the corpus) is what its sources generate.

        `laws/audit_and_scripts/split_atoms.json` names the atoms only the test lines support; `ATOMS_train.md`
        must be ATOMS.md minus exactly those, `splits/train/…/Ontology` must be generated from it, and
        the training `Atoms.lean` must lack exactly their definitions.
        """
        src = ("laws/audit_and_scripts/split_atoms.json (nrs_tools/split.py)",
               "ontology/ATOMS_train.md, library/splits/train/TrafficSpec/Core/{Atoms.lean,Ontology/*} (nrs_tools/atoms_train.py)")
        split_file = self.repo / "laws" / "audit_and_scripts" / "split_atoms.json"
        train_md = self.repo / "ontology" / "ATOMS_train.md"
        train_root = self.lib / "splits" / "train" / "TrafficSpec" / "Core"
        if not (split_file.exists() and train_md.exists() and train_root.exists()):
            return Result("training split", SKIP, "no training split generated", src)
        from scripts import gen_ontology
        split = json.loads(split_file.read_text(encoding="utf-8"))
        removed = {a.replace(".", "_") for a in split["test_only_atoms"]}
        files = gen_ontology.generate(train_md)
        out = train_root / "Ontology"
        drift = [n for n, t in files.items()
                 if not (out / n).exists() or (out / n).read_text(encoding="utf-8") != t]
        full_core = self.lib / "splits" / "full" / "TrafficSpec" / "Core"
        full_core = full_core if (full_core / "Atoms.lean").exists() else self.core   # before any swap the Core holds the full files
        full_ids = set(re.findall(r'"([a-z]+\.[a-z_]+)"', (full_core / "Ontology" / "Ids.lean").read_text(encoding="utf-8")))
        train_ids = set(re.findall(r'"([a-z]+\.[a-z_]+)"', (out / "Ids.lean").read_text(encoding="utf-8")))
        expected_gone = set(split["test_only_atoms"]) | set(split["test_only_derived"])
        if (full_ids - train_ids) != expected_gone:
            return Result("training split", FAIL,
                          f"training Ids omit {sorted(full_ids - train_ids)}, split says {sorted(expected_gone)}", src)
        full_defs = set(re.findall(r"^def ([a-z]+_\w+)", (full_core / "Atoms.lean").read_text(encoding="utf-8"), re.M))
        train_defs = set(re.findall(r"^def ([a-z]+_\w+)", (train_root / "Atoms.lean").read_text(encoding="utf-8"), re.M))
        gone = full_defs - train_defs
        wrong = sorted(d for d in gone if not any(d == r or d.startswith(r + "_") for r in removed))
        kept = sorted(d for d in train_defs if any(d == r or d.startswith(r + "_") for r in removed))
        if drift or wrong or kept:
            return Result("training split", FAIL,
                          f"ontology drift {drift}; defs removed that are no test-only atom {wrong}; "
                          f"test-only defs still present {kept}", src)
        return Result("training split", OK,
                      f"{len(expected_gone)} ids and {len(gone)} defs omitted, ontology regenerates identically", src)

    def atoms_bijection(self) -> Result:
        src = ("library/TrafficSpec/Core/Ontology/Ids.lean → atomIds",
               "library/TrafficSpec/Core/Atoms.lean → def", "Semantics.lean → dispatch tables")
        atoms, _ = self._ids()
        text = (self.core / "Atoms.lean").read_text(encoding="utf-8")
        defs = _nonempty(re.findall(r"^def ([a-z]+_\w+)", text, re.M), "Atoms.lean defs")
        wanted = {_def_name(a) for a in atoms}
        missing = sorted(wanted - set(defs))
        # every def is an atom or an accessor `<atom>_<suffix>` of one
        orphans = sorted(d for d in defs
                         if d not in wanted and not any(d.startswith(w + "_") for w in wanted)
                         and not d.startswith("rel_ahead_in_lane") and not d.startswith("rel_behind_in_lane"))
        sem = (self.core / "Semantics.lean").read_text(encoding="utf-8")
        undispatched = sorted(a for a in atoms
                              if f'"{_def_name(a)}"' not in sem
                              and not (a.startswith(("ru.", "st.", "dev.")) and a.count(".") == 1))
        problems = []
        if missing:
            problems.append(f"ids without a def: {missing}")
        if orphans:
            problems.append(f"defs that are no atom: {orphans}")
        if undispatched:
            problems.append(f"ids the evaluator never dispatches by name: {undispatched}")
        if problems:
            return Result("atoms bijection", FAIL, "; ".join(problems), src)
        return Result("atoms bijection", OK,
                      f"{len(atoms)} atom ids ↔ defs; {len(defs) - len(wanted)} accessors", src)

    def derived_bijection(self) -> Result:
        src = ("library/TrafficSpec/Core/Ontology/Ids.lean → derivedIds",
               "library/TrafficSpec/Core/Derived.lean → def drv_*, derivedNames, reads")
        _, derived = self._ids()
        text = (self.core / "Derived.lean").read_text(encoding="utf-8")
        defs = set(_nonempty(re.findall(r"^def (drv_\w+)", text, re.M), "Derived.lean defs"))
        wanted = {_def_name(d) for d in derived}
        names_block = text.split("def derivedNames")[1].split("]")[0]
        names = set(_nonempty(re.findall(r'"(drv_\w+)"', names_block), "derivedNames"))
        reads_block = text.split("def reads")[1].split("| _ => []")[0]
        reads = set(_nonempty(re.findall(r'^\s*\| "(drv_\w+)"', reads_block, re.M), "reads"))
        problems = []
        if wanted - defs:
            problems.append(f"ids without a def: {sorted(wanted - defs)}")
        if defs - wanted:
            problems.append(f"defs without an id: {sorted(defs - wanted)}")
        if names != wanted:
            problems.append(f"derivedNames ≠ ids: {sorted(names ^ wanted)}")
        if reads != wanted:
            problems.append(f"reads table ≠ ids: {sorted(reads ^ wanted)}")
        if problems:
            return Result("derived bijection", FAIL, "; ".join(problems), src)
        return Result("derived bijection", OK, f"{len(derived)} derived ids ↔ defs, names, reads", src)

    def rule_imports_whitelisted(self) -> Result:
        src = ("library/TrafficSpec/Rules/**/*.lean → import",
               "scripts/diagnostics/library_v2.py → RULE_IMPORT_WHITELIST")
        rules = sorted((self.lib / "TrafficSpec" / "Rules").rglob("*.lean"))
        if not rules:
            return Result("rule imports", SKIP, "no rule files yet", src)
        bad = []
        for p in rules:
            for m in re.finditer(r"^import (\S+)", p.read_text(encoding="utf-8"), re.M):
                if m.group(1) not in RULE_IMPORT_WHITELIST:
                    bad.append(f"{p.relative_to(self.lib)} imports {m.group(1)}")
        if bad:
            return Result("rule imports", FAIL, "; ".join(bad[:5]), src)
        return Result("rule imports", OK, f"{len(rules)} rule files import only the whitelist", src)

    def manifests_complete(self) -> Result:
        src = ("library/manifests/*.json → atoms", "library/TrafficSpec/Core/Ontology/Ids.lean → atomIds")
        files = sorted((self.lib / "manifests").glob("*.json"))
        if not files:
            return Result("manifests complete", SKIP, "no manifests registered yet", src)
        atoms, _ = self._ids()
        bad = []
        for p in files:
            doc = json.loads(p.read_text(encoding="utf-8"))
            entries = set(doc.get("atoms", {}))
            missing, unknown = sorted(set(atoms) - entries), sorted(entries - set(atoms))
            values = {v for v in doc.get("atoms", {}).values()
                      if v not in ("exact", "absent") and not str(v).startswith("estimate:")}
            if missing or unknown or values:
                bad.append(f"{p.name}: missing {missing[:3]} unknown {unknown[:3]} bad values {sorted(values)[:3]}")
        if bad:
            return Result("manifests complete", FAIL, "; ".join(bad), src)
        return Result("manifests complete", OK, f"{len(files)} manifests cover all {len(atoms)} atom ids", src)

    def checks(self):
        return [self.ontology_generated_in_sync, self.training_split_in_sync, self.atoms_bijection, self.derived_bijection,
                self.rule_imports_whitelisted, self.manifests_complete]
