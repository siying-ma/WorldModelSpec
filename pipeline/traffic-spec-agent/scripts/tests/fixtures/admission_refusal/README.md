# admission_refusal

The minimal records the admission-refusal tests need (`test_declarations_and_regions.AdmissionRefusesBeforeAnyVerdict`
and `test_admission_refusal_monitor`), extracted from run smoke22 (now under `results/Archive_old/smoke22/`) so the
tests no longer read a run folder. Nothing else of that run is kept.

| file | source (under `results/Archive_old/smoke22/`) | sha256 |
|---|---|---|
| `trace.json` | `iter-000/recheck/NRS_484B_127_1/trace_1.json` | `b0e3614226b835c763bac81ffe9ce75c748096a2b0e1b126882ce4874930c3b3` |
| `concept.jsonl` | the `drv.control.intersection_signal_inoperative` line of `accepted_concepts.jsonl` (file sha256 `cc3aeec7…5ec4`) | `829aa7c418a64fd049ec7f696b8ecc87c800fdd3cf833ff03639ea2a687200cf` |

## Lean source

The concept module the concept-review test runs, as smoke22 used it. The test copies Core and this file into a
temporary library, builds that module there, and runs on it; it reads nothing of the working tree's build cache.

| file (under `library/`) | source (under `results/Archive_old/`) | sha256 |
|---|---|---|
| `TrafficSpec/Concepts/control/intersection_signal_inoperative.lean` | `smoke22/iter-001/integrate/candidates/TrafficSpec/Concepts/control/intersection_signal_inoperative.lean` | `4af13bb44967a82eb6d8d0a311e39919a0a0fc714441f693698478b98caaf0ff` |

Why it is a counterexample: `trace.json` is an admitted trace (one scene, one highway, two cars). The tests make
the refused trace from it by giving scene 0 two intent records for the same vehicle and region; the
admission requires each declaration once per vehicle and target (`Core/Runtime/Admission.lean`), so that
trace must reach no verdict on any route: the monitor exits 2, and the concept review's harness returns it to
the reviewer without asking the adjudicator.

A missing file here, or one whose sha256 differs from this table, makes the tests fail, never skip; only a
missing Lean toolchain or an unbuilt monitor skips them.
