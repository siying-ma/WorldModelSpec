"""Recorded driving data for training and evaluation: one deterministic implementation of building
the training dataset from one data delivery, projecting a recording onto the active split, joining
monitor verdicts and scoring them against labels, and reporting what a manifest lets a rule decide.

The harness (training) and the evaluation scripts both use this package, so a recording is read,
projected and scored the same way in both. Nothing here calls a model.

Modules:
- `dataset`: the training dataset folder, built from one delivery, and its reader.
- `labels`: a recording's label and the label contract.
- `projection`: a source's manifest and a recording's trace projected onto the active split's atoms.
- `scoring`: monitor verdicts joined per law, and fixed-denominator scoring against labels.
- `decidability`: what each rule can decide under a manifest, before any monitor run.
- `source_check`: where a recording's source manifest and the entities of its trace agree or not (a report).
"""
