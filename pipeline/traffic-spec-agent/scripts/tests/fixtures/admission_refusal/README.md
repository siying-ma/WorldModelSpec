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

Why it is a counterexample: `trace.json` is an admitted trace (one scene, one highway, two cars). The tests make
the refused trace from it by giving scene 0 two intent records for the same vehicle and region; the
admission requires each declaration once per vehicle and target (`Core/Runtime/Admission.lean`), so that
trace must reach no verdict on any route: the monitor exits 2, the node review's certificate and the
concept review's harness return it to the reviewer without asking a judge.

A missing file here makes the tests fail, never skip; only a missing Lean toolchain or an unbuilt
monitor skips them.
