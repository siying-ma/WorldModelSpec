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

## Limits

- **Run time grows with the rule.** A rule reading one quantity (a speed cap) takes about 16 ms
  per observation; one reading road regions and sight distance about 85 ms; a rule that nests
  quantifiers over intersections, carriers and markings can take minutes per observation on a
  map with dozens of regions. Use `--timeout`; such a rule reports `undecided`.
- **Memory grows with the trace.** Each rule's monitor holds the decoded trace: about 2 GB for
  1,600 observations of a simple scene, 11 GB for 4,500. Lower `--jobs` for long traces.
- **Only the packaged laws are checked.** `./verify --list` names them.
