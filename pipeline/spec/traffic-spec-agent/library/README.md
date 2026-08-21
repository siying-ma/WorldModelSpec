# `TrafficSpec/Rules/*` — the autoformalized library

Every file under this directory was written by a **coding agent**, one file per
session, from a node a **plan agent** had already decided on. Nothing here is
hand-authored, and nothing here was accepted on an agent's own word: acceptance
is `tools/check_spec.py` printing `OK`, re-checked afterwards by
`CodePhase._authorize`.


Current contents: **21 rules, 8 laws, 96 scenarios**, landed over 10 iterations of run `EightRulesAfterSchema` (`state/EightRulesAfterSchema/`).

---

## 1. Plan agent 
The plan agent writes no Lean. It emits `objectives.jsonl`, one JSON object per
rule to write, and `plan_validate.py` rejects the whole plan before any coding starts if any of it is malformed. 

### How many rules a law gets

This is the plan agent's central judgement, and the prompt states the default:
*prefer one clause → one rule; decompose only when you can name what each part
obliges.* In practice the eight-clause corpus produced a **1-to-N fan-out per
law, not per sentence**:

| law | rules | why it fanned out |
|---|---|---|
| `EX-FOLLOW-001` | 5 | Sentence 2 is a bright line (R0003). Sentence 1, "reasonable and prudent", is an open standard with no threshold, so it became **sufficient conditions on different evidence channels**: R0014 reads the lead's `light_brake`, R0015 reads ego `speed`. R0021 and R0024 then restate R0003's and R0014's thresholds through the *angular* edges, because all three earlier rules route through `Pred.followingWithin`, whose `sameLane` conjunct is a shared single point of failure across a lane-node boundary. |
| `EX-LANE-001` | 6 | Sentence 1 (keep right) is R0008 and R0025. Sentence 2 (do not occupy an opposing lane while a vehicle approaches) is R0016, R0017, R0022, R0023 — four rules whose blind spots are deliberate complements: who must be moving (ego vs. witness), and whether the witness carries angular edges at all (a van does not). |
| `EX-SIGNAL-001` | 3 | R0010 covers entry-and-remain. R0018 and R0026 both carry "stop before the line" — R0026 exists because R0018 turned out to be **inert on a real capture**. |
| `EX-STOP-001` | 2 | R0007 and R0019 are the *same duty by two grounding routes*: the stop-sign actor's `controls` edge vs. the map's OpenDRIVE type-`206` landmark via `mayAffect`. Which route survives the abstraction is an empirical question no scenario can answer. |
| `EX-EMERGENCY-001` | 2 | R0012 triggers on a proximity band; CARLA emits no proximity edge for a `van`, so an ambulance is invisible to it. R0020 uses lane membership and restricts itself to `base_class == "van"` so it complements rather than loosens R0012. |
| `EX-SPEED-001` / `EX-SPEED-002` / `EX-JUNCTION-001` | 1 each | Single conditionals. No decomposition. |


### Scenarios

The plan agent writes the acceptance scenarios **before any Lean exists**, from
the law text, and the coding agent must implement every one with exactly the
declared `expected` value and character-identical names. Mechanically required:
at least one `expected: true` and one `expected: false`, since without a negative
a vacuously-true rule passes.

The realised counts are 4–6 per rule (96 across 21 rules). The pattern the files
converged on is one scenario per **load-bearing conjunct**: a scenario that fails
if that conjunct is dropped or inverted. 

**What scenarios cannot do** is the reason `run_spec monitor` exists (the simulation we got from Carla Server): the same
plan agent wrote the scenarios and chose the reading, so a misread clause
produces scenarios that agree with the misreading and the gate still prints `OK`.


### Whether the law is formalizable at all

Four answers, not two — readable today / reachable with a stated residue **Plan agent will try to fill that gap, need to be precisely designed later** /
present in the data but not lifted into Lean (a *vocabulary* gap) / genuinely
absent. Only the fourth justifies `unsupported`, and it must name a key from the
schema's *NOT available* list.

**No law in this corpus is `unsupported`.** Every clause is `formalized`,but for now nothing downstream
re-examines an `unsupported` verdict, so the cost of getting it wrong is a permanently unmeasured obligation, and the residues that survive as approximations are written into the file headers.

---

## 2. Code agent

### The header comment

The prompt requires a comment block recording the law text and **every
formalization choice the text did not dictate**, so "a reviewer must be able to challenge your reading without rerunning you." 


### The mandatory shape for the code

`STRUCTURE_FAIL` unless the file contains `import TrafficSpec.Core`,
`namespace <the exact expected namespace>`, and **`def schema`, `def entry`,
`def scenarios`** under those exact names. A second `STRUCTURE_FAIL` fires later
if `def scenarios` omits a scenario the plan declared.

```lean
import TrafficSpec.Core                    -- Core only. A rule may import nothing else.

namespace TrafficSpec.Rules.<Theme>.<Rnnnn>

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

def schema : PropertySchema where          -- name, binders, formula
def entry  : RuleEntry     where           -- nodeId, lawRefs, schema
-- entity ids, frame helpers, one `def traceX : Trace` per scenario
def scenarios : List Scenario              -- every declared name, exact `expected`

end TrafficSpec.Rules.<Theme>.<Rnnnn>
```

Everything between `entry` and `scenarios` is unconstrained by the gate. The
convention every file follows is `../Carla/Sample.lean`'s (constructed by the `Core\builder.lean`): private id constants,
shared entity and relation lists, a parameterised frame helper, then one
documented `def traceX : Trace` per scenario, so `scenarios` is a flat table of name → trace and each trace carries a doc comment saying what it depicts and what breaks if the formula is wrong.



A coding agent may write only its own target file. `Core/` is frozen, `Index.lean`
is generated by the harness, and another rule is another node's. The gate hashes
every `.lean`/`.toml` under `library/` before the session (`library_manifest`) and
reports any other change as `SCOPE_VIOLATION`; the harness then re-checks scope
against the manifest **it** captured, and rejects an `OK` as `GATE_BYPASS` if the
gate measured a different `--library-root`, a replaced `baseline.json`, or ran
`--skip-build`.

