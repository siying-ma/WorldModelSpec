# Demo subset — 14 training lines of everyday driving

A first run of the whole loop on everyday driving obligations: speed limits, red signals, stop
signs, intersection right-of-way, turning position, turn signals, one-way and divided highways,
backing and lane changes. Every line is in the training split, nothing is brought in by a
bracketed id, and no line names a vehicle class, road user or road feature only a few lines use.
Lines were chosen to keep judgement elements to a minimum: 13 of the 14 are tier C (no judgement
element) in `../../audit_and_scripts/laws_meta.jsonl`. `../smoke/` is a subset of it.

| id | the duty | what it exercises |
|---|---|---|
| `NRS-484B-600-1e` | never above 80 mph | a figure the statute states, written through a unit constructor; the aggregate "vehicle" |
| `NRS-484B-600-1c` | not above the posted limit | a device quantifier (a speed-limit sign) anchored to the subject's road |
| `NRS-484B-307-6a` | not entering the intersection on red | a signal's indication; entering the intersection as a concept; a warning clause that imposes nothing |
| `NRS-484A-450-2` | stopping at a stop sign | "stop" as a definition-born concept; three alternative stopping places |
| `NRS-484B-250-1` | yielding to a vehicle already in the intersection | "right-of-way" as a definition-born concept; an exception that composes `NRS-484B-250-4` by id |
| `NRS-484B-250-2` | yielding to the vehicle on the right | a second composition of the same root; "approximately the same time" as a proposed parameter |
| `NRS-484B-250-4` | an inoperative signal treated as a stop sign | the composition root, planned first; two obligations; what other vehicles did before (a past operator) |
| `NRS-484B-400-2a` | approaching a left turn next to the centerline | turning as a concept; lane position relative to the centerline |
| `NRS-484B-400-2b` | leaving a left turn right of the centerline | the same lead-in as 400-2a, planned as its own line |
| `NRS-484B-413-2` | signalling over the last 100 or 300 feet | a distance window; two stated figures; a legal district as a reading assumption; a "regardless of the weather" span that imposes nothing |
| `NRS-484B-220-1` | driving one-way roads in the designated direction | a sign and the lane direction it governs |
| `NRS-484B-227-1` | keeping to the right-hand roadway of a divided highway | several prohibitions in one line; crossing a dividing section only at an opening or crossover |
| `NRS-484B-113-2` | not backing into an intersection, over a crosswalk or around a corner | backing as a concept; three regions |
| `NRS-484B-223-1b` | signalling before leaving a lane | a lane change as a concept; an ordering in time (signal, then move); the demo's one tier-Q line ("with safety") |

Judgement left in on purpose, each small: "approximately the same time" (250-2), "proceed
cautiously" and "where the driver has a view of approaching traffic" (250-4, 450-2), "intends to
turn" (400-2a, 400-2b), "with safety" (223-1b). "Business or residential district" (413-2) has
no definition here: the posted definitions are of "business district" and "residence district",
and a district enters a rule only as a reading assumption declared per map or per trace.

`definitions.jsonl` holds the 18 posted definitions whose terms occur in these lines and whose
applicability clause reaches them (NRS 484A.010, NRS 484B.003). Regenerate both files with

```bash
cd pipeline/ontology_provenance
python -m nrs_tools.subset demo NRS-484B-600-1e NRS-484B-600-1c NRS-484B-307-6a NRS-484A-450-2 \
  NRS-484B-250-1 NRS-484B-250-2 NRS-484B-250-4 NRS-484B-400-2a NRS-484B-400-2b NRS-484B-413-2 \
  NRS-484B-220-1 NRS-484B-227-1 NRS-484B-113-2 NRS-484B-223-1b
```

Run it (see `../../../README.md` for the options) after `python -m harness split --use train`
and `python -m harness init --fresh --snapshot <previous run>`:

```bash
python -m harness loop --run_id demo6 --laws laws/example/demo/laws.jsonl \
  --ontology_file ontology/ATOMS_train.md --reading library/TrafficSpec/Readings/lasvegas.json --model opus \
  --max_iterations 3 --plan_batch 4
```
