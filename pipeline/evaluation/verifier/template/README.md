# traffic-verifier

Given a driving trace, report which formalized traffic laws it violates.

The package is self-contained: a Lean 4 project (the specification language, the formalized
rules, and a compiled monitor) plus a small Python 3 command and API with no dependencies outside
the standard library. Nothing here formalizes law; the rules are fixed when the package is built
(`PROVENANCE.json` names the run they come from and the Core digest).

## Install

Requirements: Linux or macOS, `bash`, `curl`, `git`, Python 3.8+, about 2 GB of disk.

```bash
./install.sh
```

This installs elan, the Lean toolchain manager, into `~/.elan` if no `lake` is on the path. elan
then fetches the Lean version pinned in `lean/lean-toolchain`. Finally it builds the monitor
(`lean/.lake/build/bin/monitor`). The first build takes a few minutes; later builds are cached.

## Run

```bash
./verify TRACE.json --manifest MANIFEST.json
```

| option | meaning |
|---|---|
| `--manifest M` | the source's capability manifest; without it every atom is taken as observed |
| `--law ID` / `--rule ID` | check only these laws or rules (repeatable) |
| `--timeout S` | seconds per rule (default 600); a rule past it is `undecided` |
| `--jobs N` | rules monitored at once (default 2) |
| `--json` | print the full report as JSON |
| `--no-explain` | do not explain violations |
| `--explain-all` | also explain every grounding whatever its verdict, at observations the explainer chooses |
| `--list` | list the packaged laws and rules |
| `--no-normalize` | hand trace and manifest to the monitor unchanged |

Exit status: `0` no law violated, `1` at least one law violated, `2` error. A run with exit
status `0` may still list undecided laws: those were not checked to the end (a trace that does not
decode, a manifest naming an unknown atom, a missing build).

Python API:

```python
import sys; sys.path.insert(0, "/path/to/traffic-verifier")
from traffic_verifier import verify
report = verify("trace.json", "manifest.json", timeout=600, jobs=2)
report["violated_laws"]            # e.g. ["NRS-484B-600-1e"]
report["undecided_laws"]           # laws whose rules passed the deadline
report["laws"]["NRS-484B-600-1e"]  # verdict, and per rule: groundings, violated intervals (ms)
```

## Input

- **trace.json**: `{"scenes": [...]}`, one scene per observation, in the Core trace format: road
  users with classes, kinematics and signals; road structures (lanes, intersections, crosswalks,
  stop lines, ...) with their geometry and attributes; devices; environment; occupancy. Time `t`
  is in milliseconds and strictly increasing.
- **manifest.json**: `{"source": ..., "reid_gap": 0, "atoms": {"<atom id>": "exact" |
  "estimate:<class>" | "absent" | "subject"}}`. It tells "the source looked and nothing was there"
  apart from "the source cannot see that": an `absent` atom is blanked before evaluation, so a rule
  that needs it says `unknown`, never `compliant`. `data/atom_ids.json` lists every atom id.

By default the input is normalized first: atom ids the manifest does not list are declared absent,
and retired road-user classes are dropped from `unobserved_classes`.

## Output

Per law, one verdict, joined from its rules (a law may be formalized as several rules), and per rule
from its groundings (one per assignment of road users to the rule's roles, e.g. `veh=track 35`):

| verdict | meaning |
|---|---|
| `violated` | at some observation the rule applied and its obligation failed |
| `undecided` | the rule did not finish within the deadline, or the monitor failed |
| `unknown` | the outcome turns on something the trace does not supply (reasons are listed) |
| `compliant` | the rule applied and its obligation held throughout |
| `not_applicable` | the rule never applied |

The first verdict of this list that occurs wins. For a violation the report gives the
observation intervals, as `t` values of the trace.

**Partial coverage.** A rule may omit, under an approved abstraction, a kind of words of its law
(for instance an equipment specification that qualifies an act the rule checks). Such a rule, and
every law it belongs to, carries `partial_coverage: true` and the abstractions' ids in
`abstractions`; the report lists those laws in `partial_coverage_laws`. Its verdict checks the
conduct the rule states, not full compliance with the law. A law with `partial_coverage: false` is
complete within the approved task scope (scope readings are disclosed in the rule's reading); not a
word-by-word verification of every qualifier of the statute.

**Why a rule is violated.** For each violated grounding (two per rule at most) the report also
explains the first violated observation. It walks the rule's obligation from the top with the
monitor's own evaluator and prints, indented, the value of each part that carries the verdict:
the conjuncts that are false, the road users or regions for which a "for every" fails, and for each
failing comparison the value of both sides and the parameters it reads. Where a bound depends on
something the trace does not supply, both possible values are printed and the comparison is
decided only if it fails in every case. A temporal operator also says which observations it reads
and which one decides it (see below). For example, for a speed rule:

```
NRS-484B-600-1a      VIOLATED        Basic rule (1)(a)
    NRS_484B_600_1a        violated        49.7 s
        veh=track 33: violated at t=5.15–32.00 s
          why, at t=5.15 s:
          ...
              lane = region 1:
                false: implies
                  true: (condition) rel_occupies(veh=track 33, lane=region 1)
                  false: kin_speed(veh=track 33) = 28.453  ≤  14.892 or 28.292 (by case: ...)
```

**Why a rule has any verdict.** With `--explain-all` (Python: `verify(..., explain="all")`), every
grounding is explained, not only violated ones, at observations the explainer chooses itself; each
grounding's report gains `scan`, a list of `{at_ms, verdict, verdict_reasons, chosen_because, text,
classes, applicability, obligation, truncated}`, and `scan_notes`, what the choice left out. The
observations are:

| the rule on this grounding | observations explained |
|---|---|
| violated somewhere | the first observation of each violated interval (at most three) |
| engaged, never violated | the first unknown observation, if any; and, for each comparison of the obligation outside quantifiers and temporal operators, the compliant observation at which it is relatively closest to its boundary (the others are counted as not searched) |
| never engaged | the observation at which the most binder classes and applicability conjuncts hold (a count, not a distance) |

At each, the binder classes and the applicability are walked as well as the obligation, so a
`not_applicable` verdict shows which condition failed. A temporal operator also reports what it reads
and how the Core decides it there: a window past the trace (truncated), a sampling gap, the
observation that decides it (then its operand is walked there), or the interval that decides it
together. The tree is a diagnosis: a true conjunction is not opened, and members, depth and lines are
bounded; each cut is listed under `truncated`.

The explainer is a separate program, `lean/.lake/build/bin/explain`, built from the one file
`lean/Explain.lean` (the package builder copies the same file), and can also be run alone:

```
explain --manifest M --reading data/reading.json --rule ID --bind veh=TRACK --at T_MS [--values] [--json] TRACE
explain --manifest M --reading data/reading.json --rule ID [--bind veh=TRACK] --scan [--max K] [--max-groundings N] [--json] TRACE
```

It runs the rule as the monitor does: the whole trace, the rule with every rule it composes, the
monitor's support (an unsupported rule is reported, and nothing is explained) and the monitor's
groundings (every one without `--bind`, or at most `--max-groundings`). `--bind` must name each of
the rule's binders once. `--values` lists every comparison of the rule at the observation, unpruned
(every connective, every quantifier member, temporal operands at that observation), each with a
path and both sides as exact rationals `{num, den}`: the interface for a check that reads a
quantity. `--json` prints `{rule, support, absent, groundings_total, groundings_explained,
groundings: [...]}`; in a tree a node is `{value, reasons, head, cmp?, window?, note?, truncated?,
children}`, a comparison side `{term, text, exact?, unknown?, cases?}`.

The monitor, given `--rules`, also registers every rule those rules compose, and reports only the
rules asked for: a composition is evaluated as with the whole rule set.

## Limits

- **Run time grows with the rule.** A rule reading one quantity (a speed cap) takes about 16 ms
  per observation; one reading road regions and sight distance about 85 ms; a rule that nests
  quantifiers over intersections, carriers and markings can take minutes per observation on a
  map with dozens of regions. Use `--timeout`; such a rule reports `undecided`.
- **Memory grows with the trace.** Each rule's monitor holds the decoded trace: about 2 GB for
  1,600 observations of a simple scene, 11 GB for 4,500. Lower `--jobs` for long traces.
- **Explaining costs more than monitoring.** The explainer evaluates each part of the rule it walks
  separately, and each such evaluation recomputes the parts below it, so an explanation of a rule
  with deep quantifier nesting costs a large multiple of its monitoring. Every call is bounded by
  `--timeout`; an explanation that does not finish says so in the report.
- **Only the packaged laws are checked.** `./verify --list` names them.
