# Corpus split — demo-overlap-v2

Approved exchange: 20 laws in each direction, eight existing held-out laws
retained. Counts remain 221 training / 28 held-out / 249 total. The 22 demo
laws are protected and unchanged. Law records are neither edited nor added.

The active roster is in ../example/test/laws.jsonl; training is its exact
complement in the original corpus. ../example/law-split.json versions the policy.
The detailed rationale is in the reviewed proposal under
runs/scenario_pipeline/work/demo/_campaigns/law-split-v2-review/SUMMARY.md.

This split tests composition, exceptions and ontology extension. Shared entities
and relations are intentional. It is not a claim that the laws contradict, nor
that training is reference-closed. The recorded training→held-out references are
270-2b→213-1; 300-1→307-2a/307-8a; 484D-165-3 and 484D-215-1→484D-100-1.
Keep these dependencies explicit in a fresh formalization experiment.

Training includes 123 existing definitions; the three retained held-out definition
records remain available for augmentation as well. Definitions shared by both
partitions do not add normative laws or alter the demo.

## Filtered training vocabulary

`split_atoms.json` and ATOMS_train.md follow the active split. Training definition
usage is included, so shared high-beam vocabulary is not falsely withheld.
The hazardous-place sign value remains shared because training law 484B.500
explicitly governs hazardous or congested places. The withheld atoms are
`dev.school_bus_signal` and `sig.brake_lamp`; no enum value is exclusively withheld.

Generated training views expose newly required door, roundabout, school-bus,
lighting and vehicle-control declarations. Corresponding runtime-name filtering
keeps the training codec and generic semantics compilable. Full ontology/Core
sources are unchanged. This does not invent judgment meanings or repair preexisting
unimplemented semantic accessors by guessing their meaning.

`python -m nrs_tools.split` now regenerates derived views only while the versioned
policy is active; it cannot revert corpus membership to the historical roster.
Use scenario_pipeline's reviewed migration command for a new corpus version.

## Evidence

All selected law/cell/actor assignments, partition receipts and overlap reports
are under runs/scenario_pipeline/inputs/planning/law-split-demo-overlap-v2.
Video and Lean/Core pairs remain in the canonical recording store. Historical
out-of-corpus and demo-held-out records remain preserved but are not included
in the new active held-out evaluation. Recovery of the 68 out-of-corpus pairs
adds no excluded law to this corpus and claims no new target-law acceptance.
