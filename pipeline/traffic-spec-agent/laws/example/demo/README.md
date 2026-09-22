# Demo subset — 18 training lines, closed under cross-references

A dry-run corpus for the pipeline before the full training run: two clusters of lines that
reference one another as exceptions or conditions, taken from `../train/laws.jsonl` and closed
under the references recorded in `../../audit_and_scripts/laws_meta.jsonl` (every line a member
references is a member). The records are posted law only, as in the parent corpus;
`definitions.jsonl` carries the definitions whose terms occur in these lines.

Run with `--laws laws/example/demo/laws.jsonl --ontology_file ontology/ATOMS_train.md`.
