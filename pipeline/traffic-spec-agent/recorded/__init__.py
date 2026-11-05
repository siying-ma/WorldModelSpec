"""Recorded driving data for training and evaluation: one deterministic implementation of reading
the labelled archive, projecting a recording onto the active split, joining monitor verdicts and
scoring them against labels, and reporting what a manifest lets a rule decide.

The harness (training) and the evaluation scripts both use this package, so a recording is read,
projected and scored the same way in both. Nothing here calls a model.

Modules:
- `archive`: the labelled archive, read by recording id without extracting it.
- `labels`: a recording's label and the provisional label contract.
- `projection`: a recording's trace and manifest projected onto the active split's atoms.
- `scoring`: monitor verdicts joined per law, and fixed-denominator scoring against labels.
- `decidability`: what each rule can decide under a recording's manifest, before any monitor run.
- `source_check`: where a recording's manifest and the entities of its trace agree or not (a report).
"""
