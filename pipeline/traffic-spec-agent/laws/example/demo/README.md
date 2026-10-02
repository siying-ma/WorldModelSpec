# Demo subset — 15 training lines of everyday driving

A first run of the whole loop on plain driving obligations: speed, following, signals, stop signs,
intersection right-of-way, turning, lane changes, signalling and pedestrians. The subset is closed
under references (nothing is brought in by a bracketed id), every line is in the training split,
and no line names a vehicle class or road feature that only a few lines use. `../smoke/` is a
subset of it.

| id | the duty | what it exercises |
|---|---|---|
| `NRS-484B-600-1e` | never above 80 mph | a figure the statute states, written through a unit constructor; the aggregate "vehicle" |
| `NRS-484B-600-1c` | not above the posted limit | a device quantifier (a speed-limit sign) anchored to the subject's road |
| `LVMC-11-16-060` | 25 mph where no other limit is posted | a figure in words; an exception on the absence of a sign; a second body of law |
| `NRS-484B-600-1a` | no faster than reasonable and proper | a standard that is the whole duty: a surrogate rule with proposed parameters |
| `LVMC-11-12-080-A` | not following too closely | two road users in one lane; a standard with proposed parameters; a class exception (funeral processions) |
| `NRS-484B-307-6a` | not entering on red | a signal's indication; entering the intersection as a concept |
| `NRS-484A-450-2` | stopping at a stop sign | "stop" as a definition-born concept; three alternative stopping places |
| `NRS-484B-250-1` | yielding to a vehicle already in the intersection | "right-of-way" as a definition-born concept; an exception that composes `NRS-484B-250-4` by id |
| `NRS-484B-250-2` | yielding to the vehicle on the right | "approximately the same time" as a proposed parameter; a second composition of the same root |
| `NRS-484B-250-4` | an inoperative signal treated as a stop sign | the composition root, planned first; two obligations; what other vehicles did before (a past operator) |
| `NRS-484B-253` | yielding when turning left | two obligations; "immediate hazard" as a standard; turning as a concept |
| `NRS-484B-223-1b` | signalling and checking before changing lanes | a lane change as a concept; an ordering in time (signal, then move); a safety standard |
| `NRS-484B-413-2` | signalling over the last 100 or 300 feet | a distance window; two stated figures; a legal district as a reading assumption; a "regardless of the weather" residue |
| `NRS-484B-413-3` | signalling before stopping or slowing suddenly | the vehicle immediately to the rear; "suddenly" as a proposed parameter |
| `NRS-484B-280-1a` | due care toward pedestrians | a standard of care as a surrogate; the aggregate "pedestrian" |

"Business or residential district" (`NRS-484B-413-2`) has no definition here: the posted
definitions are of "business district" and "residence district", and a district enters a rule only
as a reading assumption declared per map or per trace.

`definitions.jsonl` holds the 17 posted definitions whose terms occur in these lines and whose
applicability clause reaches them (NRS 484A.010 for the NRS lines; LVMC 11.02.020 for the LVMC
lines, which use no word LVMC 11.02 defines). Regenerate both files with

```bash
cd pipeline/ontology_provenance
python -m nrs_tools.subset demo NRS-484B-600-1e NRS-484B-600-1c LVMC-11-16-060 NRS-484B-600-1a \
  LVMC-11-12-080-A NRS-484B-307-6a NRS-484A-450-2 NRS-484B-250-1 NRS-484B-250-2 NRS-484B-250-4 \
  NRS-484B-253 NRS-484B-223-1b NRS-484B-413-2 NRS-484B-413-3 NRS-484B-280-1a
```

Run it (see `../../../README.md` for the options) after `python -m harness split --use train` and
`python -m harness init --fresh --snapshot <previous run>`:

```bash
python -m harness loop --run_id demo6 --laws laws/example/demo/laws.jsonl \
  --ontology_file ontology/ATOMS_train.md --reading readings/lasvegas.json --model opus \
  --max_iterations 3 --plan_batch 4
```
