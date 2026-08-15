# traffic-spec-agent — architecture and execution flow

A summary of what this repository is and exactly how a run proceeds, from an
English law clause to a Lean rule landed in the library.

---

## 1. What it is

Given a corpus of traffic-law clauses in natural language, this repository
produces a Lean 4 library of formal specifications over **CARLA scene graphs**,
using two Claude Code agents and a deterministic gate.

- A **plan agent** reads the corpus and decides what to formalize, how to
  decompose it, and what acceptance scenarios the law implies.
- A **coding agent** writes one Lean rule per planned node.
- A **gate** (`tools/check_spec.py`) decides acceptance. It is a process
  boundary, not an instruction — an agent cannot talk its way past it.
- A deterministic **integrate** step lands accepted rules or reverts them.

The product is `library/TrafficSpec/`. Everything else is machinery.

### Design commitments

| Commitment | Mechanism |
|---|---|
| A spec must be able to fire on real data | Vocabulary derived from the CARLA generator; `CARLA_INCOMPATIBLE` verdict |
| A spec must actually test something | Grounding counts; `SCENARIO_VACUOUS` verdict |
| A spec must mean what the law says | Positive **and** negative scenarios derived from the text before any Lean exists |
| The library must stay coherent | Whole-library build + scenario re-run on every integrate; revert on failure |
| Failures must teach, not stop | Every failure becomes a typed note in `AUTO_NOTES.md` for the next plan phase |

---

## 2. Repository map

```
library/TrafficSpec/            THE PRODUCT — a Lake project, no mathlib
  Core/                           frozen language; agents may not edit
    Scene.lean                      CARLA entities, relations, scenes, Trace = List Scene
    Formula.lean                    SFProp — finite-trace LTL + bounded operator
    Semantics.lean                  eval : Trace → Nat → SFProp → Bool  (fuel-based)
    Monitor.lean                    Verdict, monitorFrames, NamedProperty
    Grounding.lean                  Binder / PropertySchema / RuleEntry / Scenario
                                    + the tab-separated report the gate parses
    Decimal.lean                    exact milli-unit parsing of CARLA float-strings
                                    (self-testing: #guard asserts, fails the build)
    Builders.lean                   mkEgo / mkActor / mkLane / mkRoad / mkRel / frame
    Vocab.lean                      Pred.* — THE predicate vocabulary
  Carla/Sample.lean               CARLA-shaped smoke trace, 8 frames
  Rules/<Theme>/<Slug>.lean       one formalized rule per file (agent-written)
  Index.lean                      GENERATED registry (allRules, allScenarios)

carla/schema.json               the CARLA compatibility contract
carla/adapter.py                RSV .pkl frames + ego log → a Lean Trace
laws/example/laws.jsonl         input corpus, one clause per line
prompts/                        prompt_plan.txt, prompt_code.txt
scripts/                        the harness (never invoked by an agent)
tools/check_spec.py             the gate (the only thing an agent invokes)
state/<run>/                    PROGRESS.md, USER_HINTS.md, AUTO_NOTES.md, iter_NNN/
results/<run>/                  per-node artifacts, summary.json
```

---

## 3. Execution flow

### 3.1 Commands

```bash
bash setup.sh                                  # elan + toolchain + python deps
python -m scripts.run_spec init                # verify toolchain, build Core, create state
python -m scripts.run_spec loop --run-id first --max-iterations 2 --model opus
python -m scripts.run_spec verify              # rebuild + all scenarios, no agent
python -m scripts.run_spec index               # regenerate Index.lean from rule files
python -m scripts.run_spec status --run-id first
python -m scripts.run_spec cleanup --run-id first --results
```

`loop` is the normal path. `verify` is the independent check — it runs the same
whole-library verification integrate uses, with no model involved.

### 3.2 The loop

```
scripts/loop.py :: Loop.run()
│
│  for each iteration (up to --max-iterations):
│    iter_num = next unused state/<run>/iter_NNN
│    stage    = read from PROGRESS.md   ── "COMPLETE" → stop
│
├─ ① PLAN               phases/plan.py            agent
│     capture AUTO_NOTES.md + USER_HINTS.md  (read only; cleared after success)
│     interpolate prompts/prompt_plan.txt with:
│       · the law corpus            · a summary of existing rules
│       · the Pred.* vocabulary     · the CARLA schema + what it cannot express
│       · harness feedback          · operator hints
│     run one `claude -p` session
│     agent writes → objectives.jsonl, PLAN.md, PROGRESS.md
│     clear AUTO_NOTES.md and the temporary section of USER_HINTS.md
│
├─ ② VALIDATE           plan_validate.py          deterministic, no model
│     reject on: bad JSON · missing keys · node_id ≠ "<theme>/<slug>"
│                theme/slug not a Lean identifier · unresolvable law_ref
│                empty binders · missing positive OR negative scenario
│                duplicate scenario names · collision with an existing rule
│                more nodes than --max-nodes-per-iter
│     ON FAILURE → write objections to AUTO_NOTES.md, SKIP the code phase,
│                  continue to the next iteration. No sessions are spent.
│
├─ ③ CODE               phases/code.py            agent, one session per node, serial
│     per node, preprocessor.py prepares results/<run>/iter_NNN/nodes/<node>/:
│       node_spec.json        the planner's node, verbatim
│       baseline.json         sha256 of every library source file (scope check)
│       target_snapshot.lean  prior contents of the target file (rollback)
│       progress.jsonl        append-only gate log
│     then one `claude -p` session per node, which loops:
│       edit Rules/<Theme>/<Slug>.lean → run check_spec.py → branch on verdict
│     stops on OK, on an unresolvable blocker, or on max-turns / budget / timeout
│     writes node_report.json  {status, formalization_choices, blockers,
│                               missing_vocab, suggest_decompose}
│
├─ ④ INTEGRATE          phases/integrate.py       deterministic, no model
│     roll back every node that never reached OK
│     index_sync.py → regenerate Index.lean from the rule files on disk
│     lake build (whole library)
│     lake env lean on a generated harness → re-run EVERY registered rule's scenarios
│     ON FAILURE → revert candidates newest-first, rebuilding after each, until
│                  the library verifies again; report each reverted node
│
└─ ⑤ FEEDBACK           loop.py
      node outcomes + integrate results + uncovered law ids → AUTO_NOTES.md
      one line appended to PROGRESS.md ## Log
      results/<run>/summary.json rewritten
```

There is no `prove`, `review`, or `finalize` phase. Build verification lives in
④; the bookkeeping a `finalize` phase would do (summary, log, feedback) is ⑤.

### 3.3 Phase inputs and outputs

| Phase | Reads | Writes | Blocks on failure? |
|---|---|---|---|
| ① Plan | `laws.jsonl`, library, `Vocab.lean`, `schema.json`, `AUTO_NOTES.md`, `USER_HINTS.md` | `objectives.jsonl`, `PLAN.md`, `PROGRESS.md` | no |
| ② Validate | `objectives.jsonl`, `laws.jsonl`, library | `AUTO_NOTES.md` | **skips ③ and ④** |
| ③ Code | `node_spec.json`, `Vocab.lean`, `Builders.lean`, example rule | `Rules/<Theme>/<Slug>.lean`, `node_report.json`, `verdict.json`, `result.json` | no — per-node |
| ④ Integrate | rule files, snapshots | `Index.lean`, `library_report.txt`, reverts | stops the loop only if the library will not verify at all |
| ⑤ Feedback | node results | `AUTO_NOTES.md`, `PROGRESS.md`, `summary.json` | no |

---

## 4. The gate — `tools/check_spec.py`

Invoked by the coding agent after every edit:

```bash
python3 tools/check_spec.py --node-id <id> --task-dir <dir> --library-root <dir>
```

Checks run in order; the **first failure wins** and prints one verdict token on
the first line, which the coding prompt branches on.

| # | Verdict | Fires when |
|---|---|---|
| 1 | `MISSING_FILE` | the rule file is not at the path the plan specified |
| 2 | `SCOPE_VIOLATION` | any library file other than the target changed since `baseline.json` |
| 3 | `STRUCTURE_FAIL` | missing `namespace`, `import TrafficSpec.Core`, or `def schema` / `def entry` / `def scenarios`; or a planned scenario is absent |
| 4 | `VOCAB_VIOLATION` | `mkAtom` / `AtomicPred` / `Scene → Bool` / `.atom` used, or a `Pred.*` that does not exist (nearest names suggested) |
| 5 | `CARLA_INCOMPATIBLE` | an attribute key outside `schema.json` tier A — data CARLA never emits |
| 6 | `HYGIENE_FAIL` | `sorry` / `axiom` / `native_decide` / `partial def` / `unsafe` / `@[implemented_by]` |
| 7 | `COMPILE_FAIL` | `lake build <module>` fails, or the harness produces no report |
| 8 | `SCENARIO_VACUOUS` | a scenario grounds to **0 bindings** — vacuously satisfied, tests nothing |
| 9 | `SCENARIO_FAIL` | a scenario's verdict disagrees with the plan |
| 10 | `OK` | accepted, pending integration |

Exit status is `0` for every verdict (the text is the payload) and `1` only for a
tool-internal failure such as a missing Lean toolchain.

Checks 3–6 run on a **comment-stripped** copy of the source, so a doc comment
that says "an unsafe following distance" or mentions `Pred.somethingElse` in prose
does not trip a rule. String literals are preserved, because check 5 reads them.

On `SCENARIO_FAIL` the gate prints, per grounding, a per-frame bitmap of where the
grounded formula holds. Two patterns cover most failures:

- **all zeros** — the formula is false everywhere; usually inverted relation
  argument order,
- **all ones** — true everywhere; the antecedent never fires.

---

## 5. The Lean contract

### 5.1 What a rule file must contain

```lean
import TrafficSpec.Core

namespace TrafficSpec.Rules.<Theme>.<SlugHead>      -- SlugHead = slug before the first "_"

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-  law text + every formalization choice the text did not dictate  -/

def schema : PropertySchema where
  name    := "..."
  binders := [vehicleBinder "v", vehicleBinder "w"]
  formula := fun env => let v := arg env 0; let w := arg env 1; □ (...)

def entry : RuleEntry where
  nodeId := "<Theme>/<Slug>" ; lawRefs := ["EX-..."] ; schema := schema

def scenarios : List Scenario :=
  [ { name := "...", trace := ..., expected := true }
  , { name := "...", trace := ..., expected := false } ]

end TrafficSpec.Rules.<Theme>.<SlugHead>
```

`schema`, `entry`, `scenarios` are mandatory and must have exactly those names.

### 5.2 Grounding semantics

A schema is instantiated at every assignment of trace entities to binders, with
**distinct** entities per binder. A rule holds on a trace iff **every** grounding
holds. Zero groundings therefore means vacuous truth — which is what check 8
exists to catch.

### 5.3 The report format

`Core/Grounding.lean :: report` emits tab-separated lines that `NodeReport` in
`check_spec.py` parses. Changing one means changing the other in the same commit.

```
NODE / NAME / LAWREFS / BINDERS / SCENARIOS      header
SCEN   <name> <expected> <actual> <groundings> <PASS|FAIL|VACUOUS>
GROUND <scenario> <binding> <bool>
FRAMES <scenario> <binding> <bitmap>
CARLA  <groundings> <verdict>                    against the smoke trace
RESULT <OK|FAIL>
```

---

## 6. CARLA compatibility

The vocabulary is derived from the scene-graph generator's RoadScene2Vec
abstraction (`process_to_rsv`), not from a downstream adapter.
`carla/schema.json` records the contract: **tier A** is what the generator can
produce (hard failure outside it), **tier B** is what the bundled sample contains
(warning outside it — no smoke coverage).

Traps encoded in the vocabulary, the prompts, and the gate:

| Trap | Reality |
|---|---|
| Proximity band names | `safetyHazard` is the **closest** (< 2 m); `near` is 10–16 m, the second **farthest**. Use `Pred.withinMetres n`. |
| Relation direction | `a --lbl--> b` reads "**a** is `lbl` **b**". `Pred.behind v w` ⇒ *v* is the follower. Inverting it silently reverses a rule. |
| Dynamics channels | `speed`, `accel`, `throttle`, `brake`, `steer` exist on the **ego vehicle only**. Others carry `name`/`sem_class`. |
| Numeric attributes | float-formatted strings. Compare via `Core/Decimal.lean` in milli-units; never `attrEq` a number, never `Float`. |
| `isIn` is overloaded | entity→lane, lane→road, road→junction. Use `Pred.inLane` / `inJunction` / `approachingJunction`. |
| Ego-centric edges | distance and angular edges relate ego to others by default, so two non-ego actors may never ground. |
| Not in the graph at all | signal state, sign kind, speed limit, geometry, turn signals, right-of-way. A law needing one of these is `unsupported`, naming the field. |

Two upstream discrepancies the adapter handles: the generator emits
`safety_hazard` while its own docs say `safe_hazard` (both accepted), and
`travelsTo` is absent from the reference project's adapter (mapped here).

---

## 7. Artifacts

```
state/<run>/
  PROGRESS.md            stage + per-law coverage table + iteration log
  USER_HINTS.md          yours: temporary (cleared each iteration) + persistent
  AUTO_NOTES.md          harness → planner feedback; cleared once consumed
  iter_NNN/
    plan_prompt.txt  plan_claude_raw.jsonl
    objectives.jsonl  PLAN.md  meta.json
    library_harness.lean  library_report.txt

results/<run>/
  summary.json           per-iteration + totals: planned/accepted/landed/reverted,
                         cost, rules in library, laws covered
  iter_NNN/nodes/<node>/
    node_spec.json  prompt.txt  claude_raw.jsonl
    baseline.json   target_snapshot.lean
    progress.jsonl  verdict.json  node_report.json  result.json  harness.lean
```

**Resume.** Re-running `loop` with the same `--run-id` keeps node directories
whose `result.json` has `success: true` and deletes/re-prepares every other one,
so a resumed run never inherits half-written state. `--from-phase {plan,code,
integrate}` skips earlier phases in the first iteration.

---

## 8. Scope

**Present:** the plan → validate → code → integrate loop, the Lean core, the
CARLA vocabulary and adapter, the gate, resume, and cost/coverage reporting.

**Deliberately absent:** consistency proofs between rules, defeasibility and rule
priorities, proof obligations, a prover phase, review/faithfulness auditing,
retrieval, node deduplication, worktree parallelism. See
`../DESIGN_traffic_spec_agent.md` for how those attach.

**Known gap.** Faithfulness to the statute is not mechanically checked and cannot
be. The scenarios are the proxy, but they are written by the same planner that
specified the rule, so a misread clause yields scenarios that agree with the
misreading. Closing this needs a reader that did not write the rule — best added
later as a separate bulk `audit` command rather than a per-iteration phase, since
its value scales with the number of rules, not iterations.

**Status.** The Python harness is exercised: every gate verdict, all plan-validation
rejections, index regeneration, and a full dry run. The Lean library has **not
been compiled** — no toolchain was available when it was written. Run
`bash setup.sh && python -m scripts.run_spec init` first; `init` builds the
library and stops on failure. Expect to fix a few elaboration errors on that first
build.
