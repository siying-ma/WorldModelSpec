"""Hold the Core v2 Lean library to its sources.

Every check compares a generated or declared list with the file that is supposed to agree with
it, and names both on failure:

- the `Ontology/*.lean` files on disk are exactly what `gen_ontology` produces from `ATOMS.md`;
- every atom id of `ATOMS.md` has one `def <family>_<name>` in `Atoms.lean`, every `def` there is
  an atom or an attribute accessor of one, and every name is dispatched by `Semantics.lean`;
- every `prim.*` id has one `def prim_*` in `Primitives.lean`, and `Primitives.primitiveNames` and
  `Primitives.reads` list exactly those;
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
    "TrafficSpec.Core.Language.Rule", "TrafficSpec.Core.Language.Formula", "TrafficSpec.Core.Vocab.Params",
    "TrafficSpec.Core.Foundations.Units", "TrafficSpec.Core.Foundations.Time", "TrafficSpec.Core.Foundations.Tri",
    "TrafficSpec.Core.Vocab.Ontology.RoadUser", "TrafficSpec.Core.Vocab.Ontology.Structure",
    "TrafficSpec.Core.Vocab.Ontology.Device", "TrafficSpec.Core.Vocab.Ontology.Signal",
    "TrafficSpec.Core.Vocab.Ontology.Ids",
}
#: Modules a concept file may import: the concept record and the language it is written in.
CONCEPT_IMPORT_WHITELIST = {"TrafficSpec.Core.Language.Concept"}


def _def_name(atom_id: str) -> str:
    return atom_id.replace(".", "_")


class LibraryV2Checks:
    def __init__(self, repo_root: Path, library_root: Path):
        self.repo = repo_root
        self.lib = library_root
        self.core = library_root / "TrafficSpec" / "Core"

    def _ids(self, core: Path | None = None) -> tuple[list[str], list[str]]:
        text = ((core or self.core) / "Vocab" / "Ontology" / "Ids.lean").read_text(encoding="utf-8")
        atoms_part, _, prim_part = text.partition("def primitiveIds")
        atoms = _nonempty(re.findall(r'^\s*"([a-z]+\.[a-z_]+)"', atoms_part, re.M), "atomIds")
        prims = _nonempty(re.findall(r'^\s*"(prim\.[a-z_]+)"', prim_part, re.M), "primitiveIds")
        return atoms, prims

    def ontology_generated_in_sync(self) -> Result:
        src = ("ontology/ATOMS.md → scripts/gen_ontology.py",
               "library/TrafficSpec/Core/Vocab/Ontology/*.lean")
        from scripts import gen_ontology
        active = (self.lib / "splits" / "ACTIVE")
        which = active.read_text().strip() if active.exists() else "full"
        atoms_md = self.repo / "ontology" / ("ATOMS_train.md" if which == "train" else "ATOMS.md")
        src = (f"ontology/{atoms_md.name} → scripts/gen_ontology.py (active split: {which})",
               "library/TrafficSpec/Core/Vocab/Ontology/*.lean")
        files = gen_ontology.generate(atoms_md)
        out = self.core / "Vocab" / "Ontology"
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
               "ontology/ATOMS_train.md, library/splits/train/TrafficSpec/Core/Vocab/{Atoms.lean,Ontology/*} (nrs_tools/atoms_train.py)")
        split_file = self.repo / "laws" / "audit_and_scripts" / "split_atoms.json"
        train_md = self.repo / "ontology" / "ATOMS_train.md"
        train_root = self.lib / "splits" / "train" / "TrafficSpec" / "Core"
        if not (split_file.exists() and train_md.exists() and train_root.exists()):
            return Result("training split", SKIP, "no training split generated", src)
        from scripts import gen_ontology
        split = json.loads(split_file.read_text(encoding="utf-8"))
        removed = {a.replace(".", "_") for a in split["test_only_atoms"]}
        files = gen_ontology.generate(train_md)
        out = train_root / "Vocab" / "Ontology"
        drift = [n for n, t in files.items()
                 if not (out / n).exists() or (out / n).read_text(encoding="utf-8") != t]
        full_core = self.lib / "splits" / "full" / "TrafficSpec" / "Core"
        full_core = full_core if (full_core / "Vocab" / "Atoms.lean").exists() else self.core   # before any swap the Core holds the full files
        full_ids = set(re.findall(r'"([a-z]+\.[a-z_]+)"', (full_core / "Vocab" / "Ontology" / "Ids.lean").read_text(encoding="utf-8")))
        train_ids = set(re.findall(r'"([a-z]+\.[a-z_]+)"', (out / "Ids.lean").read_text(encoding="utf-8")))
        expected_gone = set(split["test_only_atoms"]) | set(split.get("test_only_primitives", []))
        if (full_ids - train_ids) != expected_gone:
            return Result("training split", FAIL,
                          f"training Ids omit {sorted(full_ids - train_ids)}, split says {sorted(expected_gone)}", src)
        full_defs = set(re.findall(r"^def ([a-z]+_\w+)", (full_core / "Vocab" / "Atoms.lean").read_text(encoding="utf-8"), re.M))
        train_defs = set(re.findall(r"^def ([a-z]+_\w+)", (train_root / "Vocab" / "Atoms.lean").read_text(encoding="utf-8"), re.M))
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
        src = ("library/TrafficSpec/Core/Vocab/Ontology/Ids.lean → atomIds",
               "library/TrafficSpec/Core/Vocab/Atoms.lean → def", "Language/Semantics.lean → dispatch tables")
        atoms, _ = self._ids()
        text = (self.core / "Vocab" / "Atoms.lean").read_text(encoding="utf-8")
        defs = _nonempty(re.findall(r"^def ([a-z]+_\w+)", text, re.M), "Atoms.lean defs")
        wanted = {_def_name(a) for a in atoms}
        missing = sorted(wanted - set(defs))
        # every def is an atom or an accessor `<atom>_<suffix>` of one
        orphans = sorted(d for d in defs
                         if d not in wanted and not any(d.startswith(w + "_") for w in wanted)
                         and not d.startswith("rel_ahead_in_lane") and not d.startswith("rel_behind_in_lane"))
        sem = (self.core / "Language" / "Semantics.lean").read_text(encoding="utf-8")
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

    def primitive_bijection(self) -> Result:
        src = ("library/TrafficSpec/Core/Vocab/Ontology/Ids.lean → primitiveIds",
               "library/TrafficSpec/Core/Vocab/Primitives.lean → def prim_*, primitiveNames, reads")
        _, prims = self._ids()
        text = (self.core / "Vocab" / "Primitives.lean").read_text(encoding="utf-8")
        defs = set(_nonempty(re.findall(r"^def (prim_\w+)", text, re.M), "Primitives.lean defs"))
        wanted = {_def_name(d) for d in prims}
        names_block = text.split("def primitiveNames")[1].split("]")[0]
        names = set(_nonempty(re.findall(r'"(prim_\w+)"', names_block), "primitiveNames"))
        reads_block = text.split("def reads")[1].split("| _ => []")[0]
        reads = set(_nonempty(re.findall(r'"(prim_\w+)"', reads_block), "reads"))
        problems = []
        if wanted - defs:
            problems.append(f"ids without a def: {sorted(wanted - defs)}")
        if defs - wanted:
            problems.append(f"defs without an id: {sorted(defs - wanted)}")
        if names != wanted:
            problems.append(f"primitiveNames ≠ ids: {sorted(names ^ wanted)}")
        if reads != wanted:
            problems.append(f"reads table ≠ ids: {sorted(reads ^ wanted)}")
        if problems:
            return Result("primitive bijection", FAIL, "; ".join(problems), src)
        return Result("primitive bijection", OK, f"{len(prims)} primitive ids ↔ defs, names, reads", src)

    def rule_imports_whitelisted(self) -> Result:
        src = ("library/TrafficSpec/{Rules,Concepts}/**/*.lean → import",
               "scripts/diagnostics/library_v2.py → RULE_IMPORT_WHITELIST, CONCEPT_IMPORT_WHITELIST")
        rules = sorted((self.lib / "TrafficSpec" / "Rules").rglob("*.lean"))
        concepts = sorted((self.lib / "TrafficSpec" / "Concepts").rglob("*.lean"))
        if not rules and not concepts:
            return Result("rule imports", SKIP, "no rule or concept files yet", src)
        bad = []
        for p, allowed in [(p, RULE_IMPORT_WHITELIST) for p in rules] + [(p, CONCEPT_IMPORT_WHITELIST) for p in concepts]:
            for m in re.finditer(r"^import (\S+)", p.read_text(encoding="utf-8"), re.M):
                if m.group(1) not in allowed:
                    bad.append(f"{p.relative_to(self.lib)} imports {m.group(1)}")
        if bad:
            return Result("rule imports", FAIL, "; ".join(bad[:5]), src)
        return Result("rule imports", OK, f"{len(rules)} rule and {len(concepts)} concept files import only their whitelist", src)

    def manifests_complete(self) -> Result:
        """A manifest describes a source over the full ontology, whichever split is active: the
        monitor that reads it runs on the full split, so it is checked against the full atom ids."""
        full_core = self.lib / "splits" / "full" / "TrafficSpec" / "Core"
        core = full_core if (full_core / "Vocab" / "Ontology" / "Ids.lean").exists() else self.core
        src = ("library/manifests/*.json → atoms", f"{core.relative_to(self.lib)}/Vocab/Ontology/Ids.lean → atomIds")
        files = sorted((self.lib / "manifests").glob("*.json"))
        if not files:
            return Result("manifests complete", SKIP, "no manifests registered yet", src)
        atoms, _ = self._ids(core)
        bad = []
        for p in files:
            doc = json.loads(p.read_text(encoding="utf-8"))
            entries = set(doc.get("atoms", {}))
            missing, unknown = sorted(set(atoms) - entries), sorted(entries - set(atoms))
            values = {v for v in doc.get("atoms", {}).values()
                      if v not in ("exact", "absent", "subject") and not str(v).startswith("estimate:")}
            if missing or unknown or values:
                bad.append(f"{p.name}: missing {missing[:3]} unknown {unknown[:3]} bad values {sorted(values)[:3]}")
        if bad:
            return Result("manifests complete", FAIL, "; ".join(bad), src)
        return Result("manifests complete", OK, f"{len(files)} manifests cover all {len(atoms)} atom ids", src)

    def checks(self):
        return [self.ontology_generated_in_sync, self.training_split_in_sync, self.atoms_bijection, self.primitive_bijection,
                self.rule_imports_whitelisted, self.manifests_complete]
