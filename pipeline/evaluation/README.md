# Evaluation

Everything that evaluates a run lives here, outside the pipeline: no phase reads these files, and
no rule is accepted or returned by them.

- `evaluation_scenario/` — the instruction set for the developers of the adapter: for every corpus
  line, what a trace must show before the line can be judged, and in `adapter/` the trace format,
  the adapter's contract and the changes the pipeline requires of the adapter (see its README).
- The scripts below — the evaluation of a run's accepted rules on the CARLA recordings in
  `../datasets/carla_new/` and `../datasets/demo-thirteen-latest-share-20261010/`. They read the
  pipeline tree and the dataset and write only to their work directory.

## Evaluation on carla_new

| file | what it does |
|---|---|
| `eval_carla_new.sh` | runs the monitor on every case as the dataset ships it |
| `eval_carla_new_filled.sh` | an assumption-based sensitivity run: no ice or snow, visibility 10 000 m, a 3.5 m width for lanes that carry none, and the ego's engine running; these are not recovered measurements |
| `eval_demo13.sh` | runs the monitor on every demo13 case (as shipped, or with `FILL=1` the same assumptions as the filled carla_new run plus an unwritten turn indicator read `off`) and scores the verdicts against the labels |
| `lib/common.sh` | settings, the monitor build, the monitor loop |
| `lib/register_accepted.py` | registers in the library copy exactly the rules and concepts the run holds (its own and its base chain's, as the harness resolves them; fenced versions left out), so a node still being coded never enters the build; writes `registered.json`, each rule with its law |
| `lib/prepare_cases.py` | streams a case into a separate directory, removes retired unobserved classes and absent capabilities, declares newly introduced atoms absent, masks atoms a source reports wrongly (`--mask`), takes the source's manifest for a case that ships none (`--manifest`), and saves input/output hashes in `conversion.json`; positive retired classifications require an explicit source-supported mapping |
| `lib/demo13_manifest.json` | the demo13 exporter's capabilities, which the share does not ship (see below) |
| `lib/score_labels.py` | joins each case's verdicts per law and compares the target law's with the label |
| `lib/test_prepare_cases.py`, `lib/test_score_labels.py` | check streaming, malformed input, measurement preservation, manifest migration, masking, and scoring offline |
| `PARAMETER_SELECTION_EXAMPLE_M023.md` | a worked example: smoke18's 600-1a on M023 is violated for 0.2 s, and the verdict turns on the reaction time and the dry deceleration, not on the rule's structure; what that means for a parameter review |

## Running

```bash
cd /local-scratch2/sma407/WorldModelSpec/pipeline/evaluation
bash eval_carla_new.sh                       # carla_smoke7, the run the library holds
bash eval_carla_new_filled.sh
RUN=carla_smoke6 bash eval_carla_new_filled.sh   # an archived run, read from results/carla_smoke6/library_snapshot
RUN=smoke18 bash eval_carla_new.sh             # no assumed weather, width, or visibility
RUN=smoke20 bash eval_demo13.sh                # demo13 as shipped; a run with a base run is evaluated with its base chain
RUN=smoke20 FILL=1 bash eval_demo13.sh         # demo13 with the assumptions filled

# a run in another tree (a worktree, a copy): point PIPELINE at its traffic-spec-agent
PIPELINE=/path/to/other/pipeline/traffic-spec-agent RUN=<run> bash eval_carla_new_filled.sh
```

Settings: `PIPELINE` (default `../traffic-spec-agent`), `RUN` (default `carla_smoke7`; a run archived
with `init --fresh --snapshot` is read from its `library_snapshot`), `RULES`
(comma-separated node ids; default every accepted rule), `CASES` (default every case), `WORK`
(default `/tmp/eval_<script>_<RUN>`); the filled script also takes `VISIBILITY_M`, `LANE_WIDTH_M`
and `FILL_ENGINE` (1 or 0).

The preparer reads the full generated atom list from `PIPELINE/library` (or its explicit
`--library` argument). It does not add new observations for new atoms, remap sight distance into
atmospheric visibility, change the reading, or modify the dataset. Historical constant-left turn
indicators remain masked. Conversion checks can be run with:

```bash
python3 -m unittest discover -s lib -p 'test_*.py' -v
```

## Reading the output

`GROUND <rule> <binder>=<track> <verdict>` is the verdict for the whole case: violated if any
instant is violated, else unknown if any instant is unknown, else compliant if any is, else not
applicable. In particular, a truncated startup window can keep an otherwise decided episode
unknown. `TL <rule>
<grounding> <from ms> <to ms> <verdict>` is a stretch of the recording with one verdict (times from
the trace's start, both ends inclusive). `UNK <rule> <grounding> <reason> <count>` says what was
missing at how many instants.

## Cases

| case | law the case was built for | what happens | expected |
|---|---|---|---|
| M010 | NRS 484B.407 | U-turn on a curve, sight from approach A 467 ft | 407 violated |
| M011 | NRS 484B.407 | the same, 500.005 ft | 407 compliant (boundary) |
| M012 | NRS 484B.407 | the same, 533 ft | 407 compliant |
| M023 | NRS 484B.600(1)(a) | slow approach (~16 mph) to a 17 m bend, ~100 ft sight, U-turn there | 600-1a compliant; 407 violated |
| M024 | NRS 484B.600(1)(a) | 65 mph into the same bend; leaves the road at 20.35 s | 600-1a violated; 407 compliant (no U-turn) |

The dataset ships no labels; this column is read from each case's measured setup in
`../datasets/carla_new/index.json`. The 407 labels assume the condition is read where the turn
begins: the traces' own per-frame sight distance falls below 500 ft during the turn in M011 and
M012, so a reading at another moment of the turn can decide them the other way.

## demo13

`../datasets/demo-thirteen-latest-share-20261010/`: 58 CARLA cases in 13 cells, each built for one
of 13 demo laws and labelled `compliant`, `non_compliant` or `not_applicable` for it (7 judgment
sweeps of 223-1b are unlabelled). The traces decode with the full split's decoder once the retired
classes in `unobserved_classes` are dropped. The share ships no manifest, so
`lib/demo13_manifest.json` declares one for its exporter: carla_new's manifest (the same adapter
family, with the same fields), changed where the 58 traces differ:

| atom | declared | why |
|---|---|---|
| `st.sight_distance` | absent | no trace writes it |
| `st.lane_connectivity` | exact | lanes carry `leads_to` |
| `st.median_or_divider`, `st.one_way_roadway`, `dev.regulatory_sign`, `dev.inoperative` | `estimate:scenario_authored` | written where a scenario authored them (the 227-1, 220-1 and 250-4 cells); elsewhere their absence is the scenario's claim, not a map survey |
| `sig.turn_indicator` | exact | written `left` while the ego's left indicator is lit (it lights before each left turn and lane change and goes out after it), and not written otherwise, since the export predates the `off` state; an unwritten indicator is unknown, read `off` only with `FILL=1` |

`score.tsv` lists per case the target law, the label, the law's verdict (its rules joined: violated
if any is violated, else unknown, else compliant, else not applicable), whether they match, and
the verdicts of the other laws. A case whose law has no rule in the run is listed, not scored.
A monitor takes minutes to tens of minutes per case and up to ~3 GB.
