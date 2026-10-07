# Evaluation on carla_new

External evaluation of a run's accepted rules on the CARLA recordings in `../datasets/carla_new/`.
Nothing here is part of the pipeline: no phase reads these files, no rule is accepted or returned
by them, and the scripts write only to their work directory. They read the pipeline tree and the
dataset.

| file | what it does |
|---|---|
| `eval_carla_new.sh` | runs the monitor on every case as the dataset ships it |
| `eval_carla_new_filled.sh` | the same, with what CARLA knows but the adapter does not export filled in: no ice or snow, clear air (visibility 10 000 m), a 3.5 m width for lanes that carry none, and the ego's engine running |
| `lib/common.sh` | settings, the monitor build, the monitor loop |
| `lib/register_accepted.py` | registers in the library copy exactly the rules and concepts the run accepted, so a node still being coded never enters the build |
| `lib/prepare_cases.py` | copies a case; maps the retired class spelling `animal_or_animal_drawn` to its two successors; with `--fill`, adds the filled facts |

## Running

```bash
cd /local-scratch2/sma407/WorldModelSpec/pipeline/evaluation
bash eval_carla_new.sh                       # carla_smoke7, the run the library holds
bash eval_carla_new_filled.sh
RUN=carla_smoke6 bash eval_carla_new_filled.sh   # an archived run, read from results/carla_smoke6/library_snapshot

# a run in another tree (a worktree, a copy): point PIPELINE at its traffic-spec-agent
PIPELINE=/path/to/other/pipeline/traffic-spec-agent RUN=<run> bash eval_carla_new_filled.sh
```

Settings: `PIPELINE` (default `../traffic-spec-agent`), `RUN` (default `carla_smoke7`; a run archived
with `init --fresh --snapshot` is read from its `library_snapshot`), `RULES`
(comma-separated node ids; default every accepted rule), `CASES` (default every case), `WORK`
(default `/tmp/eval_<script>_<RUN>`); the filled script also takes `VISIBILITY_M`, `LANE_WIDTH_M`
and `FILL_ENGINE` (1 or 0).

## Reading the output

`GROUND <rule> <binder>=<track> <verdict>` is the verdict for the whole case: violated if any
instant is violated, else compliant if any is, else not applicable, else unknown. `TL <rule>
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
