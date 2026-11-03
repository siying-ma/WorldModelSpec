# Traffic-law verifier: evaluation guide

This directory holds a ready-to-use verifier package and what you need to run it on recorded
driving data. A package checks a driving trace against the traffic laws one pipeline run
formalized, and says, for every law, whether the trace violates it and why.

| path | what it is |
|---|---|
| `smoke25/` | The package built from pipeline run `smoke25`: 3 rules (NRS-484A-450-2, NRS-484B-600-1a, NRS-484B-600-1e), the monitor, the explainer, the `verify` command and its Python API. Its own `README.md` is the reference for the package. |
| `template/` | The package's command, Python API, `install.sh` and README, copied into every package that is built. Edit here, not in a package. |
| `evaluate_cases.py` | Runs a package on every recorded case of a dataset and compares each law verdict with the case's label. |

Building packages and testing the explainer live next door, in `../verifier_tools/` (see its README).

## 1. Launching the evaluation step

### 1.1 Install a package (once per machine)

Requirements: Linux or macOS, `bash`, `curl`, `git`, Python 3.8+, about 2 GB of disk.

```bash
cd smoke25
./install.sh
```

This installs the Lean toolchain manager (elan) when no `lake` is on the path, then builds two
programs: `lean/.lake/build/bin/monitor` (computes verdicts) and `lean/.lake/build/bin/explain`
(explains them). The first build takes a few minutes.

### 1.2 Check one trace

```bash
./verify TRACE.json --manifest MANIFEST.json                 # every packaged law
./verify TRACE.json --manifest MANIFEST.json --law NRS-484B-600-1e
./verify TRACE.json --manifest MANIFEST.json --explain-all    # explain every verdict, not only violations
./verify TRACE.json --manifest MANIFEST.json --json           # the full report as JSON
./verify --list                                               # the packaged laws and rules
```

- `TRACE.json` is a trace in the Core format, `{"scenes": [...]}`, one scene per observation.
- `MANIFEST.json` says, for each atom, whether the source observed it (`exact`,
  `estimate:<class>`, `subject`) or could not see it (`absent`).
  - An absent atom is blanked before evaluation, so a rule that needs it says `unknown`, never
    `compliant`.
  - Without `--manifest`, every atom is taken as observed.

Exit status:

| status | meaning |
|---|---|
| `0` | no law is violated |
| `1` | at least one law is violated |
| `2` | an error |

Real output, a vehicle at 85 mph against the 80 mph cap:

```
NRS-484B-600-1e      VIOLATED        Basic rule (1)(e)
    NRS_484B_600_1e        violated        1.5 s
        veh=track 31: violated at t=0.05–8.00 s
          why, at t=0.05 s:
          rule NRS_484B_600_1e at t=50 ms (observation 1), veh=track 31: verdict violated
          applies: true
          obligation:
            false: kin_speed(veh=track 31) = 37.967  ≤  35.763
                right side: 35.763
```

A law's verdict joins the verdicts of its rules. A rule's verdict joins the verdicts of its
groundings, one grounding per assignment of road users to the rule's roles (for example
`veh=track 31`). The first verdict of this list that occurs wins:

| verdict | meaning |
|---|---|
| `violated` | at some observation the rule applied and its obligation failed |
| `undecided` | the rule did not finish within the deadline, or the monitor failed |
| `unknown` | the outcome turns on something the trace does not supply (the reasons are listed) |
| `compliant` | the rule applied and its obligation held throughout |
| `not_applicable` | the rule never applied |

### 1.3 Evaluate a dataset against its labels

A dataset is a directory with one sub-directory per recording. Each recording holds:

| file | content |
|---|---|
| `trace.json` | the trace |
| `manifest.json` | optional: the manifest |
| `label.json` | optional: the law the recording is about (`law_id`) and the expected verdict (`recorded_label`: `compliant`, `violation` or `not applicable`) |

```bash
python3 evaluate_cases.py smoke25 /path/to/cases --law NRS-484B-600-1e
python3 evaluate_cases.py smoke25 /path/to/cases --case 'C230222-*' --explain all --out results.jsonl
```

Every selected case gets exactly one status, so the denominator never shrinks:

| status | meaning |
|---|---|
| `match` | the law's verdict equals the label |
| `mismatch` | the law's verdict is decided and differs from the label |
| `unknown` | the law's verdict is unknown (the trace does not supply what it turns on) |
| `undecided` | the deadline passed or the monitor failed |
| `no_rule` | the package holds no rule of the labelled law |
| `unlabelled` | the case has no label; its verdict is still reported |

Only `match` counts as agreement. Real output on four recordings:

```
case                                             law                label           verdict         status
C230222-focused-600-1e-80-above                  NRS-484B-600-1e    violated        violated        match
C230222-focused-600-1e-80-at                     NRS-484B-600-1e    compliant       compliant       match
C230222-focused-600-1e-80-below                  NRS-484B-600-1e    compliant       compliant       match
C329610-600-1e-80-above                          NRS-484B-600-1e    violated        unknown         unknown
```

The last recording's manifest declares every atom absent, so the rule is unsupported and the law
is `unknown`. It is not counted as agreement. Each case's full report, with its verdicts, violated
intervals and explanations, is written as one JSON line. The output file is `--out`, by default
`evaluation_<package>.jsonl`. The case directories are only read.

Options:

| option | meaning |
|---|---|
| `--case GLOB` | select case directories by name |
| `--law ID`, `--rule ID` | restrict the laws or rules checked |
| `--explain none\|violations\|all` | what to explain; the default is `violations` |
| `--timeout S` | seconds per rule; the default is 600 |
| `--jobs N` | rules run at once per case; the default is 2 |

### 1.4 From Python

```python
import sys; sys.path.insert(0, "/path/to/smoke25")
from traffic_verifier import verify
rep = verify("trace.json", "manifest.json", law_ids=["NRS-484B-600-1e"], timeout=600, jobs=2,
             explain="all")              # True: violations only (default); "all": every grounding; False: none
rep["violated_laws"]                     # ["NRS-484B-600-1e"]
rep["laws"]["NRS-484B-600-1e"]["rules"][0]["groundings"][0]["scan"]   # the explanations (with explain="all")
```

### 1.5 A package for another run

```bash
python3 ../verifier_tools/make_package.py <run> --out <dir>        # then <dir>/install.sh
```

The package takes the run's accepted rules and concepts, its reading, the full split's Core and
`template/`. One caveat applies while the pipeline library's `Main.lean` (the monitor) is older than
the one in `smoke25`: a newly built package registers composed rules the old way. Deliver
`smoke25` as it is until the library's copy is updated.

### 1.6 Time and memory

- **Run time depends on the rule, not only on the trace.**
  - A speed cap takes about 16 ms per observation.
  - A rule that nests quantifiers over many regions can take far longer. NRS-484A-450-2 on a
    recording with 34 regions did not finish 20 observations in 30 minutes.
  - Use `--timeout`: such a rule reports `undecided`, which is not a match.
- **Memory grows with the trace.** Each rule's process holds the decoded trace: about 2 GB for
  1,600 observations, and 11 GB for 4,500. Lower `--jobs` for long traces.
- **Explaining costs more than monitoring.** An explanation is bounded by the same `--timeout`. If
  it does not finish, the report says so, and the verdict is unchanged.

## 2. How each explanation is made

Explanations come from `explain`, a second program built from `lean/Explain.lean`. It never
computes its own verdict. Every guarantee below follows from that:

- **It runs the rule exactly as the monitor does.**
  - The whole trace is admitted, with track identities joined and absent atoms masked.
  - The rule is registered with every rule it composes, and concepts are expanded.
  - It uses the monitor's support check and the monitor's groundings.
- **The verdict it prints at an observation is the monitor's verdict there,** with its reasons.
- **Every value it prints comes from the same evaluator.**

### 2.1 Why a rule is violated (default)

**When:** for every violated grounding, two per rule at most.

**At:** the first observation of its first violated interval.

**How:** the obligation is walked from the top. Each line is `value: part`, indented by depth.
- A conjunction opens only the conjuncts that carry its value; a false `and` shows the false ones.
- A disjunction opens its disjuncts.
- An implication shows its condition and opens its consequent.
- A negation opens its operand.
- A quantifier ("some region …", "every road user …") says how many members are present and how
  many carry the value. It opens up to three of those members, with their binding (`junc = region 11:`).
- A comparison prints both sides' values, the right side's expression, and the parameter values it
  reads (`p.stop_point_tolerance = 1.000`).
  - Where a bound depends on something the trace does not supply, every possible value is
    printed: `28.453 ≤ 14.892 or 28.292 (by case: …)`.
  - The comparison is decided only if it comes out the same in every case.
- The siblings that do not carry the value are listed on one line each, unopened.

### 2.2 Why a rule has any verdict (`--explain-all`, `explain="all"`)

Every grounding is explained, whatever its verdict. The explainer chooses the observations itself,
and each comes with the reason it was chosen:

| the grounding's verdict | observations explained |
|---|---|
| violated somewhere | the first observation of each violated interval (at most three) |
| engaged, never violated | the first unknown observation, if any; and, for each comparison of the obligation that is not under a quantifier or a temporal operator, the compliant observation where it is relatively closest to its boundary |
| never engaged | the observation where the most binder classes and applicability conditions hold |

In the "never engaged" case the number of conditions holding is a count, not a distance.
Comparisons under quantifiers or temporal operators are not searched for a margin; how many were
skipped is reported in `scan_notes`. Real output on a compliant recording (the fastest moment, 6.3%
below the bound):

```
        veh=track 35: compliant
          at t=8.00 s (engaged observation at which `kin_speed(veh=track 35)` is relatively closest to `35.763` (margin 63/1000)):
          applies: true
          obligation:
            true: kin_speed(veh=track 35) = 33.526  ≤  35.763
```

These observations are a diagnosis aid. They are not a proof that the nearest miss was found.

### 2.3 Why a rule does not apply

When the rule is not engaged at the explained observation, the explanation first walks the binder
classes (who can fill each role) and the applicability, then the obligation. A `not_applicable`
verdict thus shows the condition that failed. In this example (a 450-2 witness) the road user is
not a "vehicle" under the law's definition, though it is the subject:

```
rule NRS_484A_450_2 at t=4000 ms (observation 5), veh=track 1: verdict not_applicable
chosen: never engaged; the observation at which the most binder classes and applicability conjuncts hold (1 of 2; a count, not a distance)
applies: false
binder veh:
  false: and
    false: ru_aggregate(veh=track 1, "DEF-NRS-484A-320::vehicle")
    true: ru_subject(veh=track 1)
```

### 2.4 Temporal operators

A temporal operator prints one more line, `window (op): …`. The line says which observations the
operator reads and how the Core decides it at this observation, branch for branch. Where a single
observation decides the operator, its operand is walked at that observation, and the explanation
says so: `(the operand at the deciding observation t=… ms:)`.

| operator | what decides it |
|---|---|
| `holdsFor` (φ throughout the window behind) | window past the trace start: truncated (unknown), whatever φ holds; sampling gap: unknown; otherwise the first observation where φ fails (false) or is unknown, or the whole window (true) |
| `atLast` (φ at the last time ψ held, in the window behind) | searching back from the observation: the first ψ that is not false. If ψ holds there, φ at that observation is the value; if ψ is unknown there, the value is unknown. Earlier observations where ψ held do not decide it. |
| `within` (φ somewhere in the window ahead) | the first observation where φ holds; otherwise the first where φ is unknown; otherwise the whole window (false), or truncated at the trace end |
| `untilWithin` | the first observation of the goal, if φ held at every observation before it; otherwise where the goal is unknown, or where φ fails first |
| `since` (looking back without a bound) | the latest observation where the right operand held (true), where the left operand failed (false), or where an operand is unknown; the search reaching the trace start without a decision is truncated |
| `rises` (true here, not at the previous observation) | the operand false here decides; otherwise its value at the previous observation; the first observation has none (truncated) |

Real output (a 450-2 witness), where a stop at the start of the recording cannot be ruled in or out:

```
unknown (window_truncated:rises, window_truncated:since): since (looking back)
    window (since): reads t=0…2000 ms; decided at t=0 ms: an operand is unknown here (left unknown, right false)
  (the operand at the deciding observation t=0 ms:)
  ...
          becomes true here (was not at the previous observation)
              window (rises): at t=0 ms; first observation: the previous value is unknown (truncated)
```

### 2.5 Exact values (`explain --values`)

The explanation tree is a diagnosis. For example, a true conjunction is not opened. A check that
needs a quantity uses `--values` instead. It lists every comparison of the rule at one
observation, unpruned:
- through every connective;
- for every member of every quantifier;
- inside temporal operators, at that same observation.

Each comparison comes with a path, its binding, its value, and both sides as exact fractions:

```bash
lean/.lake/build/bin/explain --manifest M --reading data/reading.json --rule NRS_484B_600_1e \
    --bind veh=35 --at 4050 --values --json TRACE
```

```json
{"path": "obligation", "binding": "veh=track 35", "value": "true",
 "cmp": {"lhs": {"term": "kin_speed(veh=track 35)", "text": "33.520", "exact": {"num": 6703948211673513, "den": 200000000000000}},
         "op": "≤",
         "rhs": {"term": "35.763", "text": "35.763", "exact": {"num": 22352, "den": 625}}, "params": {}}}
```

The text rounds to three decimals; `exact` does not. Two values that print alike can still differ.

### 2.6 When nothing can be explained

- **Unsupported.** When the manifest declares absent everything a rule's obligation reads, the
  monitor evaluates no grounding. The explainer says so and explains nothing:

  ```
  rule NRS_484B_600_1e is unsupported by the manifest (absent: ru.subject, ru.aggregate, kin.speed): the monitor evaluates no grounding, and nothing is explained
  ```

- **Partial.** When the manifest declares only some of those atoms absent, the support is partial.
  The rule still runs, and every conclusion it can still decide is kept and explained.
- **Truncated.** Bounds keep an explanation readable: three members per quantifier, depth 16,
  forty disjuncts, 160 text lines. Every bound that cut something is listed under `truncated`. A
  truncated explanation is never a complete account.

### 2.7 Running the explainer alone

```
explain --manifest M --reading data/reading.json --rule ID --bind NAME=TRACK --at T_MS [--values] [--json] TRACE
explain --manifest M --reading data/reading.json --rule ID [--bind NAME=TRACK] --scan [--max K] [--max-groundings N] [--json] TRACE
```

- `--bind` must name each of the rule's binders once.
- Without `--bind`, `--scan` explains every grounding the monitor evaluates. `--max-groundings`
  cuts the list, and the total is still reported.
- `--json` prints `{rule, support, absent, groundings_total, groundings_explained, groundings}`.
  - Each grounding holds `{binding, episode, episode_reasons, choice_notes, explanations}`.
  - Each explanation holds `{at_ms, verdict, verdict_reasons, chosen_because, applies, classes,
    applicability, obligation, truncated, text}`.
  - A tree node is `{value, reasons, head, cmp?, window?, note?, truncated?, children}`.
