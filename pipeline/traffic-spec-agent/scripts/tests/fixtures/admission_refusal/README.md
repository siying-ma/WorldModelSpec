# admission_refusal

The minimal records the admission-refusal tests need (`test_declarations_and_regions.AdmissionRefusesBeforeAnyVerdict`
and `test_admission_refusal_monitor`), extracted from run smoke22 (now under `results/Archive_old/smoke22/`) so the
tests no longer read a run folder. Nothing else of that run is kept.

| file | source (under `results/Archive_old/smoke22/`) | sha256 |
|---|---|---|
| `trace.json` | `iter-000/recheck/NRS_484B_127_1/trace_1.json` | `b0e3614226b835c763bac81ffe9ce75c748096a2b0e1b126882ce4874930c3b3` |
| `case.json` | `iter-000/recheck/NRS_484B_127_1/case_1.json` | `03d5f30679953346b3da852a0f4484007d30c4e8ef58b856d3e855d2178f8574` |
| `reading.json` | `reading.json` | `669ee333c36425ffb1ceea9c546af1e1fb2526c6f994eaa95ce97f7485d5570e` |
| `concept.jsonl` | the `drv.control.intersection_signal_inoperative` line of `accepted_concepts.jsonl` (file sha256 `cc3aeec7…5ec4`) | `829aa7c418a64fd049ec7f696b8ecc87c800fdd3cf833ff03639ea2a687200cf` |

## Lean sources

The rule and concept modules those tests run, with the concepts the rule calls, as smoke22 used them. smoke22
inherited the rule and the two concepts it calls from its base run smoke21; each file is byte-identical to the
copy in `results/Archive_old/pre_smoke23/library_snapshot/` (the library as smoke22 left it). The tests copy
Core and these files into a temporary library, build those modules there, and run on it; they read nothing of
the working tree's build cache.

| file (under `library/`) | source (under `results/Archive_old/`) | sha256 |
|---|---|---|
| `TrafficSpec/Rules/NRS_484B/NRS_484B_127_1.lean` | `smoke21/iter-005/integrate/candidates/TrafficSpec/Rules/NRS_484B/NRS_484B_127_1.lean` | `68ccb62392d38505336bd22f9f2036d07f08de79c47efd081c281a44fcff1364` |
| `TrafficSpec/Concepts/interaction/follows_in_line_of_travel.lean` | `smoke21/iter-003/integrate/candidates/TrafficSpec/Concepts/interaction/follows_in_line_of_travel.lean` | `661252d88ec48e8c3b8276930c2e4eb9c1574621d0659986f73ac259a68b186d` |
| `TrafficSpec/Concepts/interaction/travel_gap.lean` | `smoke21/iter-004/integrate/candidates/TrafficSpec/Concepts/interaction/travel_gap.lean` | `ba67d7eb953e12c5675fd64a65dd4c15fd284332ff9cbf4ee200503c011ca96a` |
| `TrafficSpec/Concepts/control/intersection_signal_inoperative.lean` | `smoke22/iter-001/integrate/candidates/TrafficSpec/Concepts/control/intersection_signal_inoperative.lean` | `4af13bb44967a82eb6d8d0a311e39919a0a0fc714441f693698478b98caaf0ff` |

Why it is a counterexample: `trace.json` is an admitted trace (one scene, one highway, two cars). The tests make
the refused trace from it by giving scene 0 two intent records for the same vehicle and region; the
admission requires each declaration once per vehicle and target (`Core/Runtime/Admission.lean`), so that
trace must reach no verdict on any route: the monitor exits 2, the node review's certificate and the
concept review's harness return it to the reviewer without asking a judge.

A missing file here, or one whose sha256 differs from this table, makes the tests fail, never skip; only a
missing Lean toolchain or an unbuilt monitor skips them.
