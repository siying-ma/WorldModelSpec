# CARLA 600-1a subset — 1 training line, the speed standard alone

`NRS-484B-600-1a` from `../carla_smoke/`, on its own, so it can be re-run without
`NRS-484B-407`. The line is a duty that is the standard itself ("a
rate of speed greater than is reasonable or proper, having due regard for …"), so the node is a
surrogate; it is meant to be run with the behaviour reviewer deciding (`--review_mode gate`), and
scored on CARLA captures for engagement, decidedness and sensitivity to its parameters, not
against legal labels.

`definitions.jsonl` holds the 3 posted definitions whose terms occur in the line and whose
applicability clause reaches it (NRS 484A.010: chapters 484A to 484E). Regenerate both files with

```bash
cd pipeline/ontology_provenance
python -m nrs_tools.subset carla_600_1a NRS-484B-600-1a
```
