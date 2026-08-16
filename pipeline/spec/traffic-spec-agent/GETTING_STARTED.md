# Getting started

For someone new to Claude Code agents. Explains what the wrapper actually is,
where your input goes, where the output is built, how specifications are checked,
and — importantly — what "checked" does and does not guarantee.

If you only read one section, read [§6 On the word "prove"](#6-on-the-word-prove).

**Where this sits among the other docs.** `README.md` is the front door.
`ARCHITECTURE.md` is the numbered reference — cite it rather than re-deriving:
§4 for verdict details, §5.1 for the rule-file skeleton, §5.3 for the report
format, §6 for CARLA tiers, §7 for artifact paths. `CLAUDE.md` is what an
interactive Claude Code session auto-loads. This file is the narrative
walkthrough that connects them, and it is the only one that documents
[`monitor`](#75-monitor--checking-the-library-against-a-real-capture) end to end.

---

## 1. What a "Claude Code wrapper" is

`claude` is a command-line program. Run with `-p` ("print" / headless mode) it takes
**one large text prompt**, then works autonomously for up to N turns using its own
tools — read file, edit file, run bash — and exits. There is no conversation and no
human in the loop.

The wrapper is ordinary Python that launches it. From `scripts/runner.py:85-100`,
verbatim:

```python
cmd = [
    "claude",
    "-p",
    "--verbose",
    "--output-format", "stream-json",          # NDJSON we can parse
    "--permission-mode", "bypassPermissions",  # don't prompt before editing
    "--max-turns", str(max_turns),
]
resolved = resolve_model(model)
if resolved:
    cmd += ["--model", resolved]
if effort:
    cmd += ["--effort", effort]
if max_budget_usd is not None:
    cmd += ["--max-budget-usd", f"{max_budget_usd:.2f}"]
cmd.append(prompt)                             # the prompt is the last positional arg
```

That is the entire mechanism. The wrapper:

1. **builds a prompt** from a template plus your data (law text, the Lean vocabulary,
   the CARLA schema),
2. **launches the agent** as a subprocess with the repo as its working directory,
3. **lets it edit files on disk directly** — there is no structured hand-off of code;
   the agent literally writes `library/TrafficSpec/Rules/Speed/R0001_max_speed.lean`,
4. **checks the result with a separate deterministic program** that the agent cannot
   influence, and then **re-checks the checker's own provenance** (§4).

Step 4 is the load-bearing design idea. The agent is unreliable. The gate is not.
Nothing the agent *claims* ("I verified this works") counts; only what
`tools/check_spec.py` prints counts — and even that is re-validated by the harness,
because a gate call is itself something an agent can misconfigure.

> **Security note.** `--permission-mode bypassPermissions` lets the subprocess run
> arbitrary shell commands as you. It is passed unconditionally — there is no flag to
> turn it off. Know that before starting a long unattended run on a shared machine.

### Model selection

There is **no default model**. `model` defaults to `None`, and when it is falsy the
`--model` flag is omitted entirely, so the Claude Code CLI's own default applies.
Aliases (`runner.py:24-29`):

| `--model` | resolves to |
|---|---|
| `opus` | `claude-opus-5` |
| `sonnet` | `claude-sonnet-5` |
| `haiku` | `claude-haiku-4-5-20251001` |
| `fable` | `claude-fable-5` |

Any other string is passed through verbatim as a full model id.

### The two agents

| Agent | Sessions per iteration | Writes | Prompt template |
|---|---|---|---|
| **Plan** | 1 | `objectives.jsonl`, `PLAN.md`, `PROGRESS.md` | `prompts/prompt_plan.txt` (7,585 B) |
| **Code** | 1 per planned rule, **serial** | one `Rules/<Theme>/<Slug>.lean` | `prompts/prompt_code.txt` (8,504 B) |

Those are template sizes. The *filled* prompts are far larger, because the law
corpus and the CARLA schema summary are interpolated in: observed plan prompts run
~15 KB for a small corpus and ~35–42 KB for the bundled eight-law corpus; rendered
code prompts run ~38–43 KB.

Everything else in the loop — validation, integration, reporting — is deterministic
Python with no model involved.

### Process handling

stdout (newline-delimited JSON, one object per agent action) is redirected straight
to a file, with stderr merged into it; nothing is streamed to your console except
`[info]` lines. `scripts/runner.py` installs `SIGINT`/`SIGTERM` handlers **at import
time** (`runner.py:58-59`), so `_kill_all` terminates every live Claude subprocess on
Ctrl-C.

---

## 2. Where your informal law goes

**One file, JSON Lines format**: one JSON object per line, no wrapping array, no
trailing commas.

The bundled example is `laws/example/laws.jsonl`, whose first line is:

```json
{"id": "EX-FOLLOW-001", "title": "Following too closely", "text": "The driver of a motor vehicle shall not follow another vehicle more closely than is reasonable and prudent. A vehicle shall not remain within four metres of the vehicle it is following."}
```

| Field | Required | Purpose |
|---|---|---|
| `id` | yes | Stable identifier. Every generated rule records it in `lawRefs`, and `plan_validate.py` **rejects** a plan citing an id not in this file. This is the traceability link between statute and Lean. |
| `title` | no | Shown to the agent for readability. |
| `text` | yes | Verbatim statute text. This is the **only** thing the agent knows about the law's meaning. |

The bundled corpus is eight clauses, and the library currently covers **all eight**:

| id | title | formalized by |
|---|---|---|
| `EX-FOLLOW-001` | Following too closely | `Following/R0003`, `Following/R0010` |
| `EX-SPEED-001` | Maximum speed | `Speed/R0001` |
| `EX-SPEED-002` | Speed in a junction | `Speed/R0002` |
| `EX-JUNCTION-001` | Yielding within an intersection | `Junction/R0006` |
| `EX-LANE-001` | Driving on the right | `Lane/R0008`, `Lane/R0011` |
| `EX-STOP-001` | Complete stop | `Stop/R0005` |
| `EX-SIGNAL-001` | Steady red signal | `Signal/R0004` |
| `EX-EMERGENCY-001` | Emergency vehicles | `Emergency/R0012`, `Emergency/R0013` |

One law may be carried by several rules — a decomposed clause. The rule numbering
has gaps (no `R0007`, `R0009`) because those nodes were planned but rolled back.

To use your own corpus:

```bash
mkdir -p laws/bc
$EDITOR laws/bc/laws.jsonl
python -m scripts.run_spec loop --run-id bc1 --laws laws/bc/laws.jsonl
```

Paths are resolved relative to the repo root, or may be absolute.

**Two things that matter in practice.**

*Ids must be stable.* Renumbering between runs leaves existing rules with dangling
`lawRefs` and breaks coverage reporting.

*Granularity is a real choice.* One line per statutory subsection is usually right.
Put five separate obligations on one line and the plan agent must decompose it into
several rules (it can, but decomposition is where it makes mistakes). Split too
finely and you get rules with no content.

---

## 3. Where the library is constructed

Physically `library/TrafficSpec/`. It is an ordinary Lake project — you can open it
in VS Code and build it by hand with `cd library && lake build`. The toolchain is
pinned by `library/lean-toolchain` to `leanprover/lean4:v4.28.0`. No mathlib.

Three layers, with very different ownership:

```
library/TrafficSpec/
├── Core/            ← hand-written, FROZEN. Agents may not touch it.
│   ├── Scene.lean       18 EntityTypes, 18 RelLabels, Trace = List Scene
│   ├── Formula.lean     the temporal logic (□ ◇ ◯ 𝒰 ℛ, plus bounded)
│   ├── Semantics.lean   eval : Trace → Nat → SFProp → Bool
│   ├── Vocab.lean       Pred.* — the predicates every rule is built from
│   ├── Decimal.lean     exact comparison of CARLA's float-strings (44 #guard tests)
│   ├── Builders.lean    mkEgo / mkActor / mkLane / mkRel — for scenario traces
│   ├── Grounding.lean   quantification + the report format the gate parses
│   └── Monitor.lean     NamedProperty / checkProperty / monitorFrames
│
├── Carla/
│   ├── Sample.lean      an 8-frame hand-authored smoke trace (every rule is tested on it)
│   └── Captured.lean    GENERATED by carla/adapter.py from a real capture (50 frames)
│
├── Rules/           ← WRITTEN BY THE CODING AGENT. This is the product.
│   ├── Emergency/R0012_pull_right_for_emergency.lean
│   ├── Emergency/R0013_clear_junction_for_emergency.lean
│   ├── Following/R0003_following_distance.lean
│   ├── Following/R0010_prudent_gap_when_lead_brakes.lean
│   ├── Junction/R0006_yield_in_occupied_junction.lean
│   ├── Lane/R0008_opposing_lane_oncoming.lean
│   ├── Lane/R0011_keep_right_of_roadway.lean
│   ├── Signal/R0004_red_light_entry.lean
│   ├── Speed/R0001_max_speed.lean
│   ├── Speed/R0002_junction_speed.lean
│   └── Stop/R0005_stop_sign_dwell.lean
│
├── Rules_first/     ← an earlier run's snapshot. NOT imported by Index.lean; dead weight.
└── Index.lean       ← GENERATED by scripts/index_sync.py. Never edit by hand.
```

**Why `Core/` is frozen.** Agents may not invent scene predicates. If a rule needs
"vehicle approaching a junction," it must use `Pred.approachingJunction`, which was
written against the real CARLA scene-graph schema. If the predicate it needs does not
exist, the gate rejects the file and the agent must report `missing_vocab` and stop.

That single constraint is what makes CARLA compatibility *enforceable* rather than
aspirational: `Core/Vocab.lean` is the only place scene-graph access happens, so it is
the only place that can be wrong.

**The formula language** (`Core/Formula.lean:30-62`) is `atom`, `top`, `bot`, `neg`,
`conj`, `disj`, `impl`, `next`, `until`, `release`, `eventually`, `always`, `bounded`,
with scoped notation `⊤ₛ ⊥ₛ ¬ₛ ⋀ ⋁ ⟹ ◯ 𝒰 ℛ ◇ □`. Note `◯` has **strong-next**
semantics and atoms read false past the end of a trace, so the last frame can never
manufacture a violation.

**`Index.lean` is generated** and holds three marker-delimited blocks — imports,
`allRules`, `allScenarios` — plus the hand-written `checkLibrary`, `scenarioReport`
and `scenarioReportIO` below them. A rule that compiles but is not registered there is
invisible to the library, which is why the integrate phase treats an unregistered rule
file as a failure.

The agent writes **directly into the library** — no git worktree. Before its session,
`preprocessor.py` snapshots the target file; if it is rejected,
`rollback_node()` restores the snapshot or deletes the file.

---

## 4. How a specification is checked

The coding agent's prompt states that the only way to finish is to make this command
print `OK`:

```bash
python3 tools/check_spec.py \
  --node-id "Speed/R0001_max_speed" \
  --task-dir "results/bc1/iter_001/nodes/Speed_R0001_max_speed" \
  --library-root "library"
```

A fourth flag, `--skip-build`, exists for harness debugging. **Using it to obtain an
`OK` is detected and rejected** — see "The gate is not the last word" below.

Checks run in order and the **first failure wins**, printing one verdict token on
line 1 that the prompt tells the agent how to respond to. There are **ten distinct
tokens across fourteen emission points**: `MISSING_FILE`, `VOCAB_VIOLATION`,
`STRUCTURE_FAIL` and `COMPILE_FAIL` each fire at two different places — and for the
latter two, once before Lean runs and once after.

### Checks before Lean: text analysis only

| # | Verdict | Mechanism |
|---|---|---|
| 0 | `MISSING_FILE` | `node_spec.json` absent from `--task-dir`. A pre-check: it returns without writing `progress.jsonl`/`verdict.json` at all. |
| 1 | `MISSING_FILE` | The rule file is not where the plan said it would be. |
| 2 | `SCOPE_VIOLATION` | SHA-256 every library file, compare against `baseline.json` captured before the session. Anything other than the target changed → reject. This is how "`Core/` is frozen" is enforced. Skipped entirely if `baseline.json` is absent. |
| 3 | `STRUCTURE_FAIL` | Does the file declare the right `namespace`, `import TrafficSpec.Core`, and `def schema` / `def entry` / `def scenarios`? |
| 4a | `VOCAB_VIOLATION` | `ADHOC_PATTERNS` — `mkAtom`, `AtomicPred`, `Scene → Bool`, `.atom`: an agent writing its own predicate. |
| 4b | `VOCAB_VIOLATION` | A `Pred.foo` not defined in `Vocab.lean`. Prints nearest matches. Silently no-ops if `Vocab.lean` cannot be read. |
| 5 | `CARLA_INCOMPATIBLE` | Extracts attribute-key string literals and checks them against `carla/schema.json` → `attribute_keys.tier_a`. `attrEq v "signal_state" "red"` is rejected — CARLA scene graphs carry no such key, so that rule could never fire. |
| — | *(warning only)* | Tier-A-but-not-tier-B keys are collected and printed alongside the eventual `OK`. Not a failure. |
| 6 | `HYGIENE_FAIL` | Six patterns: `sorry`, `axiom`, `native_decide`, `partial def`, `@[implemented_by`, `unsafe`. |

These run on a **comment-stripped** copy of the source, so a doc comment reading "an
unsafe following distance" does not trip check 6.

### Checks that invoke Lean: two subprocess calls

```bash
# 7 — does it compile?   (cwd = library/, so lean-toolchain applies; 900 s timeout)
lake build TrafficSpec.Rules.Speed.R0001_max_speed
```

```lean
-- 8–9 — the gate GENERATES task_dir/harness.lean and runs `lake env lean` on it
--        (300 s timeout):
import TrafficSpec.Rules.Speed.R0001_max_speed
import TrafficSpec.Carla.Sample

#eval TrafficSpec.reportIO TrafficSpec.Rules.Speed.R0001.entry
                           TrafficSpec.Rules.Speed.R0001.scenarios
                           TrafficSpec.Carla.sampleTrace
```

Note the module path and the namespace differ: the file is
`R0001_max_speed`, the namespace is `R0001`. `SpecNode.slug_namespace` takes only the
leading identifier of the slug, so declarations read `Rules.Speed.R0001.entry`. Both
values are written into `node_spec.json` so the agent and the gate never re-derive
them differently.

`#eval` **executes** the monitor. `reportIO` (in `Core/Grounding.lean`) prints
tab-separated lines that Python parses:

```
NODE	Speed/R0001_max_speed
NAME	max_speed
LAWREFS	EX-SPEED-001
BINDERS	1
SCENARIOS	2
SCEN	compliant_cruise	true	true	2	PASS
SCEN	exceeds_limit	false	true	2	FAIL
GROUND	exceeds_limit	v=e1, w=e2	true
FRAMES	exceeds_limit	v=e1, w=e2	111111
CARLA	2	false
RESULT	FAIL
```

Line layouts: `SCEN ⟨name⟩ ⟨expected⟩ ⟨actual⟩ ⟨groundings⟩ ⟨status⟩`,
`GROUND ⟨scenario⟩ ⟨binding⟩ ⟨verdict⟩`, `FRAMES ⟨scenario⟩ ⟨binding⟩ ⟨bitmap⟩`,
`CARLA ⟨groundings⟩ ⟨verdict|none⟩`, `BINDERS ⟨count⟩`, `RESULT OK|FAIL`.
`NODE`/`NAME`/`LAWREFS`/`SCENARIOS` are emitted but ignored by the parser.

Reading that: scenario `exceeds_limit` should have been **violated**
(`expected=false`) but came out **satisfied**; the `FRAMES` bitmap shows the formula
held at all six frames. The agent receives this and edits.

Two verdicts carry most of the quality signal:

- **`SCENARIO_FAIL`** — the specification disagrees with the acceptance tests the
  planner derived from the statute.
- **`SCENARIO_VACUOUS`** — the grounding count is 0. This is the dominant failure mode
  in this domain: a rule quantified over two vehicles, tested on a trace containing
  one, is *vacuously true*. It looks correct, reads correctly, and monitors nothing.

Worth knowing: **`PASS`/`FAIL`/`VACUOUS` is decided inside Lean**
(`Core/Grounding.lean`), not in Python. The gate only reads the sixth column. And the
gate's process exit status is `0` for *every* verdict including failures — it is `1`
only when the tooling itself breaks (schema missing, `lake` not found).

### The gate is not the last word

A gate call has two caller-controlled inputs — `--library-root` and the
`baseline.json` it compares against — so an `OK` is only as trustworthy as the thing
that produced it. `CodePhase._authorize` (`scripts/phases/code.py:267-317`)
independently re-checks every `OK` before accepting the node, and the docstring
records why in plain terms: **both bypasses were actually observed** in the
`test_eight_rules` run — one node pointed the gate at a copy of the library with its
siblings deleted, another regenerated `baseline.json` over the real one. Both printed
`OK`.

So acceptance requires, in this order:

1. the verdict is literally `OK` (anything else is rejected immediately);
2. the harness's **own** scope re-check against the manifest it captured is clean —
   otherwise `SCOPE_VIOLATION`, which short-circuits, so a node failing both this and
   provenance is never labelled `GATE_BYPASS`;
3. provenance: the gate measured the run's library, `baseline.json` was not replaced,
   and `--skip-build` was not used — otherwise **`GATE_BYPASS`**.

`GATE_BYPASS` is emitted by the harness, **never by `check_spec.py`**. One
back-compat hole to be aware of: a `verdict.json` carrying neither `library_root` nor
`baseline_sha` is accepted on the scope check alone.

Then the **integrate** phase asks a different question: rebuild the whole library and
re-run **every** rule's scenarios, so a new rule that breaks an existing one is
reverted.

---

## 5. End to end, one law

**Input** — `laws/bc/laws.jsonl`:

```json
{"id": "BC-146-1", "title": "Speed limit", "text": "A person must not drive a vehicle at a rate of speed exceeding 50 km/h."}
```

**① Plan.** The wrapper fills `prompts/prompt_plan.txt` with your laws, a summary of
the existing library, the predicate vocabulary and the CARLA schema (including an
explicit list of what CARLA *cannot* express), and runs one session. It writes
`state/bc1/iter_001/objectives.jsonl`:

```json
{"node_id": "Speed/R0001_max_speed", "theme": "Speed", "slug": "R0001_max_speed",
 "law_refs": ["BC-146-1"], "description": "ego must not exceed 50 km/h",
 "binders": ["v"],
 "scenarios": [{"name": "compliant_cruise", "expected": true,
                "description": "ego holds 12 m/s for six frames"},
               {"name": "exceeds_limit", "expected": false,
                "description": "ego reaches 16 m/s mid-run"}],
 "notes": "speed exists on ego only — gate on Pred.isEgo"}
```

The seven required keys are `node_id`, `theme`, `slug`, `law_refs`, `description`,
`binders`, `scenarios`; `notes` and `parent` are optional.

**② Validate.** Pure Python, ~21 checks. Confirms `BC-146-1` exists, identifier shapes,
`node_id == "<theme>/<slug>"`, no duplicate or colliding node id, non-empty binders,
at least one positive **and** one negative scenario, unique scenario names, and the
node cap. On failure it writes objections to `AUTO_NOTES.md` and **returns before the
code phase is even constructed** — no agent sessions are spent on a bad plan.

**③ Code.** One session writes
`library/TrafficSpec/Rules/Speed/R0001_max_speed.lean`:

```lean
import TrafficSpec.Core
namespace TrafficSpec.Rules.Speed.R0001
open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

def schema : PropertySchema where
  name    := "max_speed"
  binders := [vehicleBinder "v"]
  formula := fun env => let v := arg env 0
                        □ (isEgo v ⟹ speedLeKph v 50)

def entry : RuleEntry where
  nodeId := "Speed/R0001_max_speed"; lawRefs := ["BC-146-1"]; schema := schema

def scenarios : List Scenario := [ /- two concrete traces -/ ]
end TrafficSpec.Rules.Speed.R0001
```

It runs the gate, reads the verdict, edits, repeats until `OK`. The harness then
re-authorizes that `OK` (§4). A rejected node is **rolled back immediately**, so its
file is not part of the library the next node is baselined against.

**④ Integrate.** Regenerate `Index.lean`, `lake build` the whole library, re-run every
rule's scenarios. Pass → the rules stay. Fail → revert candidates **newest-first**,
re-syncing and re-verifying after each, until the library builds again.

**⑤ Feedback.** Outcomes and still-uncovered law ids are written to `AUTO_NOTES.md`,
which the next iteration's planner reads and the harness then clears.

---

## 6. On the word "prove"

**Nothing in this pipeline proves anything.** The distinction matters for how you
describe the work.

### What happens: evaluation

```lean
satisfies τ φ   -- = eval τ 0 φ : Bool, computed on ONE concrete finite trace
```

The gate builds 3–5 concrete traces per rule (typically ~6 frames, 2 vehicles), runs
the monitor, and compares against the expected verdict. The logical content is:

> ∀ these four specific traces on which this rule behaves as the planner intended.

That is a **unit test**. A good one — exhaustive over groundings, and evaluated by
Lean rather than asserted in Python — but a test.

### What proving would mean

A Lean `theorem` whose proof term the kernel checks, quantified over *all* traces:

```lean
theorem no_conflict (τ : Trace) :
    satisfies τ ruleA.asProp = true → satisfies τ ruleB.asProp = true := by
  ...
```

There is **no `theorem` and no `lemma` anywhere in `library/TrafficSpec/`** — verified,
the count is zero. The only kernel-checked propositions in the repository are the
**44 `#guard` assertions in `Core/Decimal.lean`**, and those concern arithmetic on
specific strings, not traffic law.

This is a consequence of scope: the consistency-checking work was deliberately
dropped, and the proofs went with it.

### What you can and cannot claim

| Claim | Supported |
|---|---|
| Specs compile against a CARLA-faithful scene-graph ontology | ✔ `lake build` |
| Specs are executable monitors over finite traces | ✔ |
| Each spec is validated against positive and negative scenarios derived from the statute | ✔ |
| Specs are non-vacuous on their test scenarios | ✔ `SCENARIO_VACUOUS` |
| Specs agree with a human reading of one real CARLA capture | ✔ *only where* `monitor` has been run and labelled — see §7.5 |
| Specs are **proved** correct | ✘ |
| Specs are **proved** mutually consistent | ✘ |
| The spec faithfully captures the statute | ✘ — see below |

### The faithfulness caveat

The acceptance scenarios are the only in-loop check on *meaning*, and they are written
by the **same plan agent** that specified the rule. If the planner misreads "within
four metres" as "within four seconds," it emits scenarios consistent with that
misreading, the coding agent satisfies them, and the gate prints `OK`. The pipeline is
self-consistent and wrong.

`monitor` (§7.5) is the one check that breaks this loop, because the expectation comes
from a person who watched the footage rather than from the agent that wrote the rule.
It is not a proof either, and it is only as good as the labels — the bundled ones are
marked `DRAFT … NEEDS HUMAN CONFIRMATION`.

A broader remedy — a bulk `audit` command with a reader that did not write the rule —
is designed but not built.

### If you want real proofs

The design is in `../DESIGN_traffic_spec_agent.md` §3. The first blocker is
architectural: `AtomicPred` holds an opaque `test : Scene → Bool` closure
(`Core/Formula.lean:14-17`) and compares by label only, so the kernel cannot relate two
predicates to each other. Reifying atoms into an inductive datatype comes first. That
is a project, not a flag.

---

## 7. Commands, in order

```bash
# 0. one-time setup: elan + Lean toolchain + `fire` + build the library
bash setup.sh

# 1. environment check + build + state scaffold
python -m scripts.run_spec init

# 2. see the prompts WITHOUT spending any tokens
python -m scripts.run_spec loop --run-id smoke --max-iterations 1 \
    --max-nodes-per-iter 1 --dry-run
less state/smoke/iter_001/plan_prompt.txt

# 3. one real iteration, one rule, cheap model
python -m scripts.run_spec loop --run-id first --max-iterations 1 \
    --max-nodes-per-iter 1 --model sonnet

# 4. inspect
python -m scripts.run_spec status --run-id first
cat results/first/iter_001/nodes/*/progress.jsonl    # every gate call + verdict
cat results/first/summary.json

# 5. independent re-verification, no agent involved
python -m scripts.run_spec verify
```

`setup.sh` installs `fire` into whatever environment is **already active** (conda,
venv, or system) and only falls back to creating a local `.venv` if it cannot. Its
last step builds the library. Run `lake` only from inside `library/`; from the repo
root, elan tries to fetch its own default toolchain.

Step 2 is the fastest way to understand the system: the file it writes is exactly what
the agent will see.

### 7.1 The seven subcommands

| Command | Purpose |
|---|---|
| `init` | Check `claude` and `lake` are on PATH, `lake build` the library, scaffold `state/<run>/`. |
| `loop` | The plan → validate → code → integrate → feedback cycle. |
| `verify` | Rebuild and re-run every registered rule's scenarios. **No agent involved.** |
| `monitor` | Evaluate the whole library against a real CARLA capture and diff against human labels (§7.5). |
| `index` | Regenerate `Index.lean` from the rule files on disk. Supports its own `--dry-run`. |
| `status` | Print discovered rules, `PROGRESS.md`, and the path to `summary.json`. |
| `cleanup` | Delete `*harness*.lean` everywhere; with `--results`, also `results/<run-id>/`. |

### 7.2 Useful flags on `loop`

| Flag | Default | Meaning |
|---|---|---|
| `--run-id` | `default` | Names `state/<id>/` and `results/<id>/`. Re-running the same id **resumes**. |
| `--laws` | `laws/example/laws.jsonl` | Your corpus |
| `--library-root` | `library` | |
| `--max-iterations` | `3` | Plan→code→integrate cycles |
| `--max-nodes-per-iter` | `4` | Rules per iteration (= coding sessions) |
| `--max-turns` | `60` | Per-session turn cap |
| `--timeout-minutes` | `45` | Per-session wall-clock cap; `0`/`None` disables |
| `--model` | *(none — flag omitted)* | `opus` / `sonnet` / `haiku` / `fable`, or a full model id |
| `--effort` | — | Passed through verbatim; **not validated** |
| `--max-budget-usd` | — | Per-session spend cap, formatted to 2 dp |
| `--from-phase` | — | `plan` / `code` / `integrate` — skip earlier phases **in iteration 1 only** |
| `--force-stage` | — | Override the stage read from `PROGRESS.md` |
| `--dry-run` | `false` | Write prompts, launch nothing |

**Resume** works at the node level: re-running with the same `--run-id` keeps node
directories whose `result.json` has `success: true` (an identity check against `True`)
and deletes/re-prepares every other one, so a resumed run never inherits half-written
state.

### 7.3 Stages

`PROGRESS.md` carries `- stage: …`, and only two values are recognised: `formalize`
and `COMPLETE`. `COMPLETE` breaks the loop.

### 7.4 A caveat that will bite you in CI

`main()` is a bare `fire.Fire(Cli)`. **`fire` prints a command's return value rather
than using it as the process exit status**, so `$?` is `0` even when `verify` finds
failures or `monitor` reports disagreements. Read the printed value, or wrap `main()`
in `sys.exit(...)`.

### 7.5 `monitor` — checking the library against a real capture

This is the only check in the repository that does not depend on the agent that wrote
the specification. It converts a real CARLA capture to a Lean trace, evaluates **every
registered rule** on it, and diffs the verdicts against a label file written by a
person from the footage.

```bash
python -m scripts.run_spec monitor \
    --rsv-dir  sceneflow_sample/data/rsv \
    --ego-log  sceneflow_sample/data/ego_logs.json \
    --labels   labels/sceneflow_sample.json \
    --module-name Captured \
    --adapter-python $(which python)   # needs networkx to unpickle a capture
```

What it does, in order:

1. **Convert** — runs `carla/adapter.py` as a subprocess (under `--adapter-python`, or
   `sys.executable`) writing `library/TrafficSpec/Carla/<module-name>.lean`.
   `--skip-convert` reuses an existing one and ignores `--rsv-dir`/`--ego-log`.
2. **Build** — `lake build TrafficSpec.Carla.<module-name>`.
3. **Evaluate** — generates `results/_capture_harness.lean`, which imports
   `TrafficSpec.Index` and prints `FRAMES ⟨n⟩` plus one
   `CAP ⟨nodeId⟩ ⟨lawRefs⟩ ⟨groundings⟩ ⟨holds⟩` line per rule, then runs it.
4. **Diff** — parses those lines, loads the labels, and prints a per-law table.

Note the `CAP`/`FRAMES` capture format is generated as a Python string in
`scripts/lean_check.py`, *not* defined in `Grounding.lean` — and the 2-field capture
`FRAMES` line is a different thing from the 4-field per-binding `FRAMES` line in the
node report, despite the shared tag.

A label file needs only three keys the code actually reads — `capture`, `annotator`,
and `labels`; `source`, `evidence` and `caveat` in the bundled examples are free-form
documentation and are never parsed:

```json
{
  "capture": "sceneflow_sample",
  "annotator": "who labelled it, and from what evidence",
  "labels": [
    {"law": "EX-LANE-001", "verdict": "compliant", "note": "rightmost lane throughout"},
    {"law": "EX-JUNCTION-001", "verdict": "not_applicable", "note": "no junction in this capture"}
  ]
}
```

`verdict` must be one of `compliant`, `violated`, `not_applicable`. `not_applicable`
is not a formality: a law whose situation never arises in a capture is untested by it,
and recording that as agreement would let a benchmark of vacuous rules score
perfectly.

Each law is then classified `ok`, `FALSE POSITIVE` (lawful footage reported as a
violation), `MISSED VIOLATION`, `UNTESTED` (label says engaged, rule grounds zero
times), `SPURIOUS GROUNDING`, or `NO RULE`.

**Read the second summary line, not the first.** The report tells you how many laws
are *engaged and grounded*; the raw agreement figure is inflated by every
`not_applicable`.

Captures come from the sibling CARLA pipeline at `../../sg/carla_scene_graphs/`. Three
label files ship here — `sceneflow_sample.json`, `red_light_compliant.json`,
`red_light_violation.json` — and **all three are drafts marked
`NEEDS HUMAN CONFIRMATION`**. Confirm them against the camera stills before treating
any agreement figure as evidence.

---

## 8. Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `lake: command not found` | Toolchain not installed or not on PATH. `bash setup.sh`, or `source ~/.elan/env`. |
| Build fails in `Core/Decimal.lean` on a `#guard` | The decimal parser is genuinely wrong, not a toolchain problem. Those 44 assertions are unit tests. |
| Plan rejected every iteration | Read `state/<run>/AUTO_NOTES.md` — it contains the exact objections. Common cause: the planner omitted a negative scenario. |
| Every node returns `SCENARIO_VACUOUS` | Scenario traces lack distinct entities for every binder. A two-binder rule needs two separate vehicles per trace. |
| Every node returns `CARLA_INCOMPATIBLE` | The corpus depends on data CARLA has no notion of. Check `carla/schema.json` → `unavailable`. But first check `available_not_exposed`: a field that exists but has no predicate is a **vocabulary gap**, not an unsupported law. |
| A node returns `GATE_BYPASS` | The rule may be fine — the *gate call* was misconfigured (wrong `--library-root`, replaced `baseline.json`, or `--skip-build`). Re-plan the node unchanged. |
| A node loops until `max_turns` | Read its `progress.jsonl` — the verdict sequence shows what it kept failing. Repeated `SCENARIO_FAIL` usually means the clause needs decomposition. |
| `SCENARIO_FAIL` with an all-zeros bitmap | Usually an inverted relation order — `Pred.behind v w` means *v* is behind *w*. |
| `SCENARIO_FAIL` with an all-ones bitmap | The antecedent never fires; the rule is satisfied for the wrong reason. |
| `monitor` fails with `No module named 'networkx'` | Re-run with `--adapter-python` pointing at an interpreter that has it. The gate prints this hint itself. |
| `$?` is 0 but the run clearly failed | `fire` prints return values instead of exiting with them (§7.4). |
| `claude: command not found` | Only needed for `loop`. `lake build`, `verify`, `index` and `monitor` work without it. |

Every gate invocation is appended to
`results/<run>/iter_NNN/nodes/<node>/progress.jsonl`, so the full verdict history for
any rule is one `cat` away. That file is the first place to look when something
behaves oddly.

---

# 9. Code walkthrough — every file, in call order

§1–§5 explained the system conceptually. This section is the literal control flow:
you type one command, and here is every file that runs, in the order it runs, and
what each one reads and writes.

Read it alongside the source. Nothing here is a simplification.

## 9.0 The command

```bash
python -m scripts.run_spec loop --run-id bc1 --laws laws/bc/laws.jsonl --model sonnet
```

`python -m scripts.run_spec` executes `scripts/run_spec.py` as a module, so its
`if __name__ == "__main__": main()` fires.

## 9.1 Entry and context construction

| Step | File · function | What it does |
|---|---|---|
| 1 | `scripts/run_spec.py` · `main()` | `fire.Fire(Cli)` — Google Fire turns the `Cli` class into a CLI, so `loop` becomes the subcommand and `--run-id` etc. become its keyword arguments |
| 2 | `scripts/run_spec.py` · `Cli.loop()` | Resolves `--laws` against the repo root via `_resolve()`, errors out if the corpus is missing |
| 3 | `scripts/state.py` · `LoopOptions` | A dataclass holding every knob: iterations, node cap, turns, timeout, model, effort, budget, `from_phase`, `force_stage`, `dry_run` |
| 4 | `scripts/loop.py` · `build_context()` | Builds `LoopContext`, hardcoding `state_dir = repo_root/state/<run>`, `results_dir = repo_root/results/<run>`, `prompts_dir = repo_root/prompts` |
| 5 | `scripts/state.py` · `LoopContext` | Holds the paths. Its `@property` accessors are where every later path comes from |
| 6 | `scripts/loop.py` · `Loop(ctx).run()` | The orchestrator. Everything below happens inside it |

**Note on `LoopContext`:** every path property hangs off `state_dir` *except*
`nodes_dir`, which hangs off `results_dir`. That asymmetry is why plan artifacts live
under `state/` and per-node coding artifacts under `results/`.

## 9.2 Startup

| Step | File · function | Effect |
|---|---|---|
| 7 | `scripts/state.py` · `init_state_dir()` | Creates `state/bc1/` with `PROGRESS.md` (stage `formalize` + an empty coverage table), `USER_HINTS.md`, and an empty `AUTO_NOTES.md` — only if absent, so a resumed run keeps its history |

> **There is no schema drift check.** Nothing verifies that `carla/schema.json` still
> matches `Core/Scene.lean`'s `EntityType`/`RelLabel` or the attribute keys
> `Core/Vocab.lean` reads. No Python file in the repo opens `Scene.lean` at all. The
> schema's tier-A lists *are* injected into the plan prompt as the available
> constructors, so drift would silently tell the planner about constructors that do
> not exist — but that consistency is maintained by human convention only (the rule is
> stated in `CLAUDE.md`, for people, not enforced by a script).

Then per iteration:

| Step | File · function | Effect |
|---|---|---|
| 8 | `scripts/state.py` · `next_iter_num()` | Scans `state/bc1/iter_*` and returns `max + 1`. The directory number comes from here, **not** from the loop counter |
| 9 | `scripts/state.py` · `read_stage()` | Regexes `- stage: …` out of `PROGRESS.md`; `COMPLETE` breaks the loop |
| 10 | `scripts/loop.py` · `skip_set()` | Turns `--from-phase code` into `{"plan"}`, honoured **only in iteration 1** |
| 11 | `scripts/loop.py` · `Loop._iterate()` | Runs the five phases below |

## 9.3 Phase ① — Plan

`scripts/phases/plan.py` · `PlanPhase.run()`

| Step | File · function | Reads | Writes |
|---|---|---|---|
| 12 | `PlanPhase.run()` | `state/bc1/AUTO_NOTES.md`, `state/bc1/USER_HINTS.md` | — |
| 13 | `json.loads` | `carla/schema.json` | — |
| 14 | `plan.py` · `load_laws()` | `laws/bc/laws.jsonl` | — |
| 15 | `plan.py` · `format_laws()` | — | a markdown block, one section per clause |
| 16 | `plan.py` · `summarize_library()` | every `library/TrafficSpec/Rules/**/*.lean` | a list of existing rules + their `lawRefs` |
| 17 | `plan.py` · `summarize_vocab()` | `library/TrafficSpec/Core/Vocab.lean` | every `def` grouped under its `§` heading — this is how the planner learns the vocabulary |
| 18 | `plan.py` · `summarize_schema()` | the parsed schema | constructor lists, the proximity-band table, `relation_coverage`, the time base, and all four availability tiers, plus pitfalls and recipes |
| 19 | `str.format()` | `prompts/prompt_plan.txt` | 14 interpolated keys |
| 20 | `PlanPhase.run()` | — | `state/bc1/iter_001/plan_prompt.txt` — **read this file to see exactly what the agent sees** |
| 21 | `scripts/runner.py` · `run_claude()` | — | spawns the subprocess (§9.4) |
| 22 | `runner.py` · `parse_result_line()` | `plan_claude_raw.jsonl` | the final `type:"result"` object — cost and token counts |
| 23 | `state.py` · `LoopContext.write_meta()` | — | `iter_001/meta.json` |
| 24 | `state.py` · `clear_auto_notes()`, `clear_temporary_hints()` | — | empties `AUTO_NOTES.md`; resets only the *temporary* section of `USER_HINTS.md` |

Steps 12 and 24 are the **capture-inject-clear** discipline: the feedback is read
*before* the session and cleared only *after* it returns, so a crash leaves the notes
intact for the retry.

## 9.4 What the agent subprocess actually does

`runner.run_claude()` builds and spawns the command shown in §1, with
`cwd = repo_root`. stdout is redirected to `iter_001/plan_claude_raw.jsonl` with
stderr merged in. The Python side does not talk to the agent while it runs — it waits,
with a timeout, and kills the process on expiry or on Ctrl-C.

Inside, the **plan agent** reads its prompt and writes with its own tools:

- `state/bc1/iter_001/objectives.jsonl` — one JSON node per rule to build
- `state/bc1/iter_001/PLAN.md` — prose rationale
- `state/bc1/PROGRESS.md` — the coverage table and the stage (**run-level**, not
  per-iteration)

## 9.5 Phase ② — Validate (no model)

`scripts/plan_validate.py` · `validate()`, called directly from `Loop._iterate()`

| Step | File · function | Purpose |
|---|---|---|
| 25 | `plan_validate.load_law_ids()` | reads `laws/bc/laws.jsonl` — the set of legal `law_refs` |
| 26 | `plan_validate.existing_node_ids()` | walks `Rules/**` — node ids already in the library, to reject collisions |
| 27 | `scripts/task.py` · `SpecNode.from_dict()` | parses one line; `ScenarioSpec.from_dict()` parses each scenario |
| 28 | `task.py` · `SpecNode` properties | derives `target_file`, `module`, `namespace`, `slug_namespace`, `sanitized` — so the harness, the prompt and the gate all use identical values |
| 29 | `plan_validate.validate()` | the ~21 checks listed in §5 |
| 30 | `plan_validate.write_auto_notes()` | on failure: objections → `AUTO_NOTES.md`, and `_iterate()` **returns immediately** — phases ③ and ④ never run |

A rejected plan therefore costs one plan session and zero coding sessions.

Two ordering quirks worth knowing: the law-ref check is skipped entirely if the laws
file is missing or empty, and a `parent` reference is resolved against nodes seen
*so far*, so a forward reference to a parent defined later in the file is rejected.

## 9.6 Phase ③ — Code

`scripts/phases/code.py` · `CodePhase.run()`

| Step | File · function | Effect |
|---|---|---|
| 31 | `code.py` imports `summarize_schema`, `summarize_vocab` from `plan.py` | the coder is shown the same vocabulary and schema as the planner, built once for all nodes |
| 32 | `scripts/task.py` · `SpecNodeTask` | per node: paths for `node_spec.json`, `baseline.json`, `target_snapshot.lean`, `progress.jsonl`, `verdict.json`, `node_report.json`, `claude_raw.jsonl`, `harness.lean`, `result.json` |
| 33 | `scripts/preprocessor.py` · `prepare_tasks_for_resume()` | keeps task dirs whose `result.json` has `success: true`; `rmtree`s and re-prepares everything else |
| 34 | `preprocessor.py` · `prepare_node_task()` | writes `node_spec.json`; snapshots the target file, or *unlinks* a stale snapshot if the target does not exist; seeds `progress.jsonl` |
| 35 | `preprocessor.py` · `capture_baseline()` — using `library_manifest` imported *from* `tools/check_spec.py` | SHA-256 of every library source file → `baseline.json`. The gate and the baseline share one function so they can never disagree about what is in scope |
| 36 | `code.py` · `format_law_text()`, `format_scenarios()` | pulls the statute text for this node's `law_refs`; renders the scenario table |
| 37 | `code.py` · `build_prompt()` | fills `prompts/prompt_code.txt` (19 keys) → `task_dir/prompt.txt` |
| 38 | `runner.run_claude()` | one session per node, **serially** (§9.7) |
| 39 | `code.py` · `read_verdict()`, `read_report()` | reads `verdict.json` (written by the gate) and `node_report.json` (written by the agent) |
| 40 | `code.py` · `CodePhase._authorize()` | **re-checks scope and provenance; this, not `verdict.json`, decides acceptance** (§4) |
| 41 | `code.py` · `SpecNodeResult` → `result.json` | `accepted`/`success` reflect `_authorize`, not the agent |
| 42 | `preprocessor.rollback_node()` | a rejected node's file is reverted **immediately**, not at integrate |
| 43 | `code.py` · `_notes_for()` | turns each outcome into planner-facing prose for `AUTO_NOTES.md` |

Steps 35 and 42 are two halves of one lesson, and both carry the reasoning in the
source. The baseline **must** be taken at the start of each node's own session: nodes
run serially, so a baseline taken when the iteration was prepared predates the earlier
nodes' accepted files, and every node after the first got a `SCOPE_VIOLATION` naming a
sibling's rule — "agents responded by working around the gate rather than trusting
it." Symmetrically, a rejected node left on disk becomes an out-of-scope change
reported to the *next* node, propagating a failure into work that has not started.

## 9.7 Inside one coding session — the gate loop

The agent edits `library/TrafficSpec/Rules/<Theme>/<Slug>.lean` directly, then runs:

```bash
python3 tools/check_spec.py --node-id … --task-dir … --library-root library
```

`tools/check_spec.py` · `main()` then executes, in order:

| Step | File · function | Check |
|---|---|---|
| 44 | reads `task_dir/node_spec.json` | target path, module, namespace, declared scenarios |
| 45 | `check_spec.strip_lean_comments()` | blanks comments, keeps string literals — so prose never trips a pattern check |
| 46 | `check_spec.library_manifest()` vs `baseline.json`, via `scope_diff()` | `SCOPE_VIOLATION` |
| 47 | `DEF_RE` + namespace/import search | `STRUCTURE_FAIL` |
| 48 | `ADHOC_PATTERNS`; `PRED_USE_RE` vs `check_spec.vocab_names()` | `VOCAB_VIOLATION` |
| 49 | `check_spec.load_schema()`; `ATTR_CALL_RE` | `CARLA_INCOMPATIBLE` |
| 50 | `HYGIENE_PATTERNS` (six) | `HYGIENE_FAIL` |
| 51 | `scripts/lean_check.py` · `lake_build()` — `lake build <module>`, 900 s | `COMPILE_FAIL` |
| 52 | `lean_check.write_node_harness()` | generates `task_dir/harness.lean` |
| 53 | `lean_check.eval_harness()` — `lake env lean harness.lean`, 300 s | runs Lean (§9.8) |
| 54 | `check_spec.NodeReport(output)` | parses the six tab-separated line types |
| 55 | verdict selection | no parseable report → `COMPILE_FAIL`; a declared scenario with no `SCEN` line → `STRUCTURE_FAIL`; then `SCENARIO_VACUOUS` → `SCENARIO_FAIL` → `OK` |
| 56 | `check_spec.record()` | appends to `progress.jsonl`; writes `verdict.json` **including `library_root`, `baseline_sha` and `skip_build`** — the provenance step 40 checks |

`lean_check.first_errors()` / `parse_diagnostics()` compress Lean's output into a short
digest so a `COMPILE_FAIL` message stays readable.

The agent reads the verdict token, edits, and repeats — that is the inner loop. When it
gets `OK`, it writes `node_report.json` and stops. Both Lean calls run with
`cwd = library_root`, which is what makes the `lean-toolchain` pin apply.

## 9.8 What runs inside Lean

`harness.lean` is a comment plus three content lines (§4). `#eval` forces evaluation at
elaboration time, and the call chain is:

```
Core/Grounding.lean  reportIO → report
                       ├── scenarioLine / groundingLines / frameLines
                       └── RuleEntry.check / groundings / groundingCount
                             └── PropertySchema.bindings
                                   ├── rawBindings → extend
                                   ├── traceEntityIds   ← uses Scene.entitiesOfTypes
                                   └── distinctIds      ← no binder may share an entity
                                         ↓
Core/Semantics.lean  satisfies τ φ  =  eval τ 0 φ
                       ├── the temporal loops (loopAlways / loopUntil / loopBounded …)
                       └── evalAtom → AtomicPred.test
                             ↓
Core/Vocab.lean      the Pred.* closure for this atom
                       ├── Core/Scene.lean    hasRelation / relatedToTyped / getAttr
                       └── Core/Decimal.lean  parseMilli / leMilli   (numeric attributes)
```

`Core/Builders.lean` does not appear in that chain — it is used *when the file is
elaborated*, to construct the scenario traces and `Carla/Sample.lean`.
`Core/Monitor.lean` supplies `NamedProperty` / `checkProperty` / `monitorFrames`, used by
`Grounding.lean` and by `Index.lean`'s `checkLibrary`.

The report comes back out as stdout text, which step 54 parses. That round trip —
Python generates Lean, Lean evaluates and prints, Python parses — is how a Boolean
computed inside Lean reaches the agent as a verdict.

## 9.9 Phase ④ — Integrate (no model)

`scripts/phases/integrate.py` · `IntegratePhase.run()`

| Step | File · function | Effect |
|---|---|---|
| 57 | `preprocessor.rollback_node()` | safety net for a phase that died part-way; the code phase already rolls each rejection back as it happens, and `rollback_node` is idempotent |
| 58 | *(early return)* | if no accepted candidates: print and stop — no index sync, no build |
| 59 | `scripts/index_sync.py` · `sync()` | `discover()` walks `Rules/**` building a `RuleFile` per file; `_replace_block()` rewrites the three generated blocks in `Index.lean`. **Any structural defect → nothing is written and every candidate is reverted** |
| 60 | `lean_check.lake_build()` | the **whole** library, not one module |
| 61 | `lean_check.write_library_harness()` | `iter_001/library_harness.lean` — `import TrafficSpec.Index` + `#eval TrafficSpec.scenarioReportIO` |
| 62 | `lean_check.eval_harness()` | re-runs **every registered rule's** scenarios; output saved to `iter_001/library_report.txt` |
| 63 | `IntegratePhase._verify()` | scans for any line starting `SCEN\t` whose last field is not `PASS` — a regression in an *older* rule fails integration |
| 64 | bisect | on failure, revert candidates **newest-first**, re-`sync()`, re-`_verify()` after each, until the library builds again |

One sharp edge: if `Index.lean` has lost its `BEGIN/END GENERATED` markers,
`_replace_block` raises `ValueError`, and `IntegratePhase` catches only
`LeanUnavailable` — so that propagates out uncaught.

## 9.10 Phase ⑤ — Feedback and reporting

| Step | File · function | Writes |
|---|---|---|
| 65 | `Loop._uncovered_laws()` | law ids not mentioned in any rule file (plain substring match) |
| 66 | `plan_validate.write_auto_notes()` | node outcomes + uncovered law ids (capped at 40) → `AUTO_NOTES.md`, consumed by the next iteration's step 12 |
| 67 | `state.append_log()` | one line under `## Log` in `PROGRESS.md` |
| 68 | `Loop._write_summary()` | `results/bc1/summary.json` — per-iteration and totals |
| 69 | `Loop.print_summary()` | the terminal table |

## 9.11 Artifact layout

```
state/<run>/
├── PROGRESS.md            run-level: stage + coverage table + log
├── USER_HINTS.md          run-level: operator hints (temporary + persistent)
├── AUTO_NOTES.md          run-level: written by the loop, cleared by the plan phase
└── iter_NNN/
    ├── plan_prompt.txt         exactly what the plan agent saw
    ├── plan_claude_raw.jsonl   NDJSON of the plan session
    ├── objectives.jsonl        the plan
    ├── PLAN.md                 prose rationale
    ├── meta.json               cost / duration / terminal reason
    ├── library_harness.lean    integrate: all scenarios
    └── library_report.txt      its output

results/<run>/
├── summary.json           run-level: per-iteration + totals
└── iter_NNN/nodes/<Theme>_<Slug>/
    ├── node_spec.json          the node, incl. derived target_file/module/namespace
    ├── prompt.txt              exactly what the coding agent saw
    ├── baseline.json           SHA-256 manifest captured at session start
    ├── target_snapshot.lean    only if the target file pre-existed
    ├── claude_raw.jsonl        NDJSON of the coding session
    ├── progress.jsonl          every gate call + verdict
    ├── verdict.json            the gate's last verdict + its provenance
    ├── harness.lean            generated, node-scoped
    ├── node_report.json        written by the agent
    └── result.json             `success` — written by the harness, read by resume
```

`NNN` is zero-padded to three digits and comes from `next_iter_num()`. The node
directory name is `node_id` with every non-`[A-Za-z0-9_]` character replaced by `_`.

## 9.12 Complete call graph

```
scripts/run_spec.py        Cli.loop
  └── scripts/loop.py      build_context → LoopContext (state.py)
      └── Loop.run
          ├── state.py            init_state_dir
          └── Loop._iterate                        (once per iteration)
              ├── phases/plan.py      PlanPhase.run
              │     ├── load_laws / format_laws          ← laws/*.jsonl
              │     ├── summarize_library                ← Rules/**
              │     ├── summarize_vocab                  ← Core/Vocab.lean
              │     ├── summarize_schema                 ← carla/schema.json
              │     ├── prompts/prompt_plan.txt
              │     ├── runner.py  run_claude ─────────► [PLAN AGENT] → objectives.jsonl
              │     └── state.py   clear_auto_notes / clear_temporary_hints
              │
              ├── plan_validate.py    validate            → nodes, or AUTO_NOTES + stop
              │     └── task.py       SpecNode.from_dict
              │
              ├── phases/code.py      CodePhase.run       (serial, one session per node)
              │     ├── preprocessor.py  prepare_tasks_for_resume → prepare_node_task
              │     │     └── tools/check_spec.py  library_manifest → baseline.json
              │     ├── build_prompt ← prompts/prompt_code.txt
              │     ├── runner.py  run_claude ─────────► [CODING AGENT]
              │     │      └── loops: edit Rules/*.lean
              │     │                 → tools/check_spec.py
              │     │                      ├── strip_lean_comments, regex checks
              │     │                      ├── carla/schema.json     (CARLA_INCOMPATIBLE)
              │     │                      ├── Core/Vocab.lean       (VOCAB_VIOLATION)
              │     │                      ├── lean_check.lake_build (COMPILE_FAIL)
              │     │                      ├── lean_check.write_node_harness + eval_harness
              │     │                      │      └── LEAN: Grounding → Semantics → Vocab
              │     │                      │                → Scene / Decimal
              │     │                      └── verdict.json (+ provenance) + progress.jsonl
              │     ├── CodePhase._authorize   ← re-checks scope + provenance → GATE_BYPASS
              │     └── preprocessor.rollback_node        (immediately, on rejection)
              │
              └── phases/integrate.py IntegratePhase.run
                    ├── preprocessor.rollback_node        (safety net)
                    ├── index_sync.py  sync → Index.lean
                    └── lean_check     lake_build (all) + library harness (all scenarios)
```

## 9.13 Files not on the `loop` runtime path

| File | When it runs |
|---|---|
| `carla/adapter.py` | Called by `run_spec monitor`, and runnable by hand. Never called by `loop`. |
| `scripts/capture_eval.py` | `monitor` only. |
| `library/TrafficSpec/Carla/Captured.lean` | Generated by the adapter; imported only by the capture harness. |
| `library/TrafficSpec/Rules_first/` | An earlier run's snapshot. Not registered in `Index.lean`, not built, not checked. |
| `library/TrafficSpec.lean` | The library's root module — only for `import TrafficSpec` from outside. |
| `library/TrafficSpec/Index.lean` | Written by step 59; *read* by steps 61–62, by `run_spec verify`, and by `monitor`'s capture harness. |
| `scripts/phases/base.py` | Defines `Phase` / `PhaseResult`; no logic of its own. |
| `scripts/state.py` · `write_stage()`, `capture_and_clear()` | **Dead code** — defined, never called. `capture_and_clear`'s docstring references a `clear_feedback` function that does not exist. |
| `docs/`, `*.md` | Documentation. `CLAUDE.md` is auto-loaded by an interactive Claude Code session. |
| `setup.sh`, `pyproject.toml` | Installation. |

## 9.14 The shortest way to see all of this yourself

```bash
python -m scripts.run_spec loop --run-id trace --max-iterations 1 \
    --max-nodes-per-iter 1 --dry-run
```

Steps 1–20 run for real; step 21 is skipped. You get
`state/trace/iter_001/plan_prompt.txt` — the exact prompt — with no tokens spent, and
the terminal shows the phase banners in order.
