# Smoke subset — 2 training lines, one composing the other

The smallest corpus that runs every stage of the loop once: two lines of one section, closed under
references, and a subset of `../demo/`.

| id | what it is there for |
|---|---|
| `NRS-484B-250-4` | the root: a driver entering an intersection whose signal is inoperative stops as at a stop sign, then proceeds yielding to vehicles that previously completed a stop or are within the intersection. Two obligations (two nodes); "stop" is a defined term ("complete cessation from movement", DEF-NRS-484A-255), so a concept is planned from its definition |
| `NRS-484B-250-2` | composes the root by id: the yield-to-the-right rule, with the device exception "Except as otherwise provided in subsection 4 [NRS-484B-250-4]". "Right-of-way" (DEF-NRS-484A-210) and entering the intersection are concepts; "approximately the same time" is a standard the plan operationalizes with a proposed reading parameter |

Together the two lines name the aggregate words "vehicle", "driver" and "traffic", so the plan
writes `aggregates.jsonl` from their definitions.

Expect, with `--plan_batch 1` (the root is planned first and the second line is shown its planned
nodes): concept records gated and reviewed, three nodes, one composition, a proposed parameter in
the reading, and a review per accepted node.

`definitions.jsonl` holds the 12 posted definitions whose terms occur in the two lines and whose
applicability clause reaches them (NRS 484A.010: chapters 484A to 484E). Regenerate both files with

```bash
cd pipeline/ontology_provenance
python -m nrs_tools.subset smoke NRS-484B-250-2 NRS-484B-250-4
```
