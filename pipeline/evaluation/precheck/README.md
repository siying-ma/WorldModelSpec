# Label-stage precheck

Before a run's label stage, `precheck.py` computes for each law how many of its plain-labelled
training recordings the current data can decide, and says which laws should enter the label stage.
A law none of whose plain labels can be decided is reported `not aligned (data)`, so no label stage
and no repair is spent on it.

## What it is, and what it is not

- **Static.** It predicts blockers; it never runs a rule over a recording (no label check, no monitor
  run on a trace). The monitor runs only on a one-scene probe trace that holds no road user, so only
  Core's support under the source's manifest is computed (`recorded/decidability.py`). The label
  stage remains the authority on every label: a label the precheck calls decidable can still come
  out unknown, and one it calls at risk can come out decided.
- **Read-only.** It changes no run, library, dataset or label, and adds no step to the loop. It is a
  process step built from the pipeline's own modules, which it imports from
  `pipeline/traffic-spec-agent/` (none of their logic is copied):
  - `recorded/dataset.py`: the dataset folder and its labels;
  - `harness/phases/label_check.py` (`comparison_set`): the recordings, plain labels and judgment
    calls of each law, fixed exactly as the label stage fixes them (it also refuses a dataset whose
    traces or manifests differ from its index);
  - `recorded/decidability.py`: each rule's support under each source manifest;
  - `recorded/scoring.py`: the class and handling of an absent atom, and of a missing assumption or
    intention;
  - `recorded/source_check.py`: what the manifest declares against what the trace holds.

  Its own addition is a count taken in the same streamed pass that feeds the source report: per
  scene, the assumptions supplied, the intentions declared for the subject and the road users
  without `classes`, compared with what each rule's record declares.
- **Not a gate.** Its verdict is advice for the operator. The loop does not read it.

## Run order

After generation and review, before the label stage: **G → R → precheck → L**. Run it once the loop
has stopped awaiting labels (`status awaiting_labels`), on the dataset the label stage will use.

## Inputs

| option | what |
|---|---|
| `--dataset DIR` | a dataset folder built from one delivery by `recorded/dataset.py build` |
| `--run DIR` | the run's directory, `pipeline/traffic-spec-agent/results/<run>`: its ledger (`state.json`) and node records (with those of its `base_run` chain) |
| `--library DIR` | the run's library (default `<run>/../../library`); its ontology is read by the source report |
| `--monitor PATH` | the monitor built in that library (default `<library>/.lake/build/bin/monitor`); it must register the run's rules |
| `--laws A,B` | optional: a subset of the run's laws (default: every law of the run's ledger) |
| `--out FILE` | optional: the JSON report |
| `--jobs N` | traces read at once (default 8) |

No reading is taken: Core's support depends on the manifest alone, and no rule is evaluated.

**Which rules belong to which law.** Exactly as the label stage takes them: the nodes of the law's
final plan in the run's ledger (`state.json`, `ledger[].nodes`), accepted or not. A node the monitor
does not register cannot be run, and the law's verdict is `no rule`. A monitor built before the
run's rules were indexed registers none of them, and every law comes out `no rule`. The label stage
builds its own monitor before it checks; for the precheck, build one from the run's library
(`lake build monitor` inside it while the loop is stopped, or inside a copy of it) and pass it with
`--monitor`.

The precheck reads every trace of the selected laws once (the digests `comparison_set` checks) and
every plain-labelled trace once more (the source report), streamed.

## Commands

From `pipeline/traffic-spec-agent/`, build the dataset once per delivery:

```
python3 -m recorded.dataset build <delivery dir> <dataset dir> [--jobs N] [--library library]
```

Then, from the repository root:

```
python3 pipeline/evaluation/precheck/precheck.py \
    --dataset <dataset dir> \
    --run pipeline/traffic-spec-agent/results/<run> \
    [--library pipeline/traffic-spec-agent/library] [--monitor <path>] \
    [--laws NRS-484B-413-2,NRS-484B-227-1] --out <report>.json
```

Exit status 0 with a report, 2 when an input is refused (no monitor, a dataset of another layout, a
dataset whose files differ from its index).

## What it computes

For each plain label (an explicit verdict that is not a judgment call), every **blocker** the data
predicts, each with the rule it concerns, a class and a handling (who the evidence points at, as
`recorded/scoring.py` names them):

| reason | meaning | certain? |
|---|---|---|
| `unsupported` | Core gives the rule no support under the recording's source manifest: its verdict is unknown | yes, except on a `violated` label when some other rule of the law is not unsupported (a law's verdict is violated as soon as one of its rules is) |
| `absent_atom:<atom>` | the rule reads an atom the manifest declares absent (support `partial`: "verdicts may be unknown") | no |
| `source_check:<finding>` | the source report finds the trace omits or contradicts an atom the manifest declares observed, on an atom the rule reads (e.g. `declaration:rel.occupies:occupancy_not_observed:road user` for `occupancy_observed: []`) | no |
| `assumption_missing:<asm>` | an assumption the rule's record (or a rule it composes) declares is not supplied in every scene | no |
| `intention_missing:<int>` | an intention the rule's record declares is declared for the subject in no scene | no |
| `classes_missing:subject` / `:other road user` | road users with no `classes` (the subject: every rule; others: rules that read a road-user atom) | no |
| `unreadable` | the trace could not be read | yes |

The atoms a rule reads are Core's own (`Rule.atomIds`, closed over the rules it composes), obtained
from the same probe under the source manifest with every atom declared absent. A source-report
finding that a kind declared absent labels an entity is not counted again: the support already
counts the absent atom.

A plain label is **blocked** when some blocker is certain, **at risk** when it has only blockers
that may leave it unknown, **decidable** when it has none.

**Not predicted** (only an evaluation shows them): a window that reaches past the recording, geometry
Core cannot use (a boundary it rejects as a polygon, a degenerate region), identity and sampling
gaps, a deadline or a crash, and any mismatch with the label.

## Verdict rules

| verdict | when |
|---|---|
| `no rule` | the law's final plan names no node, or a node the monitor does not register |
| `not aligned (data)` | no plain label is decidable or at risk: every one is blocked, or the law has none |
| `enter label stage` | some plain label is decidable or at risk |

An at-risk label sends its law to the label stage: whether a `partial` rule decides depends on how
the rule uses the absent atom, which only an evaluation shows. Read the `dec` and `risk` columns
together: a law with `dec 0` has no plain label free of predicted blockers, and its reasons say what
the label stage will have to get past.

## Reading the table

```
law                  ledger    rules  rec   plain v/c/na  jc  unl  dec risk  blk  verdict
NRS-484B-253         planned       2    9      0 (0/0/0)   0    9    0    0    0  not aligned (data)
NRS-484B-413-2       planned       1   15    15 (5/10/0)   0    0    0   15    0  enter label stage
    - absent_atom:sig.hand_signal [source_unobserved, data]: 15 plain label(s); rules NRS_484B_413_2; e.g. 0f83f046d9dd: the source declares sig.hand_signal absent; ...
    - assumption_missing:asm.within_business_or_residence_district [declaration, data]: 15 plain label(s); rules NRS_484B_413_2; e.g. 0f83f046d9dd: supplied in 0 of 1570 scenes
NRS-484B-450-1c      blocked       1    0      0 (0/0/0)   0    0    0    0    0  no rule
    not registered in the monitor: NRS_484B_450_1c
```

- `ledger`: the law's state in the run's ledger (the label stage checks only `planned` laws whose
  generation is complete; the precheck reports every law);
- `rules`: the nodes of the final plan; `rec`: the law's recordings in the dataset;
- `plain v/c/na`: plain labels, and how many are violated / compliant / not applicable;
- `jc`: judgment-call labels (never compared in training); `unl`: unlabelled recordings;
- `dec`, `risk`, `blk`: plain labels decidable, at risk, blocked;
- under each law, every reason: its class and handling, how many plain labels it reaches (and on how
  many it is certain), the rules it concerns, one recording and its evidence.

The JSON (`--out`) holds the same per law (`laws.<law>`), each plain label with its status and
blockers (`per_recording`), each rule's support per source (`support`), the atoms each rule reads
(`atoms_read`), the assumptions and intentions each rule declares (`declared_facts`), the overlap of
the run's laws with the dataset's (`overlap`), and the totals.
