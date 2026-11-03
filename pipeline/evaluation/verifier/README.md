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


