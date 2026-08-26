# The example corpus

`laws.jsonl` is **92 single-sentence clauses** transcribed from British Columbia's
official learner manual:

> ICBC, *Learn to drive smart — your guide to driving safely*
> <https://icbc.com/assets/en/63cHBOAVpOAQGOOMBFhFbL/driver-full.pdf>

Every line carries a `source` field naming the chapter, the manual's own section
heading, and the printed page the sentence came from. The pipeline never reads
`source` — `format_laws` renders only `id`, `title` and `text` — so the planning
agent judges each clause from the clause alone. The field is there so a human can
check a transcription against the manual.

## The atomicity invariant

**One law = one sentence = one obligation.** No clause carries a list, a set of
exceptions, or a second requirement. This is deliberate and it is the point of
the corpus in its current form: with atomic clauses, judgement 2 of the plan
prompt (decompose or not?) has nothing to do, so one law becomes one node, and
the count of accepted rules *is* the number of laws formalized. Nothing has to be
reconstructed from a parent/child tree to read the score.

Longer, compound clauses are the harder test and belong in a later corpus — they
mix throughput with decomposition quality, and you cannot tell the two apart from
a node count.

## Why it was rewritten

The corpus this replaces was eight invented clauses in statutory voice. Three
stated obligations no BC law imposes — a four-metre following minimum, a 30 km/h
limit inside intersections, a one-second minimum dwell at a stop sign — and two
more were narrower than the real rule (a steady red with no right-turn-on-red
exception; an emergency clause that said *yield* where BC says **stop**). Invented
numbers test whether the pipeline can formalize a sentence; they cannot test
whether it can formalize a *law*, because a wrong formalization has nothing to be
wrong against. Every number here is now the manual's own.

## Ids

Seven of the original eight ids kept their subject, so `lawRefs` and label files
naming them still point at the same obligation:

| id | obligation |
|---|---|
| `EX-SPEED-001` | 50 km/h within cities and towns |
| `EX-FOLLOW-001` | at least two seconds of space in front |
| `EX-JUNCTION-001` | yield to a vehicle that arrived first |
| `EX-STOP-001` | a stop sign means a complete stop |
| `EX-SIGNAL-001` | a red light means a complete stop |
| `EX-LANE-001` | travel in one of the right-hand lanes |
| `EX-EMERGENCY-001` | all traffic in both directions must stop |

`EX-SPEED-002` is the exception: it was "30 km/h within an intersection", an
invented rule with no BC counterpart, and is now "80 km/h outside cities and
towns". Any label note written against the old text is stale — recheck
`labels/*.json` before the next `monitor` run.

Within a theme, numbering is dense and has no meaning beyond order.

## What the corpus exercises

Clauses were chosen for spread, not for formalizability — nothing was trimmed to
fit what the pipeline can read, because where its reach ends is the measurement.
Grouped by what the *sentence* demands of a trace:

- **A threshold on one actor's state** — `EX-SPEED-001..003`, `EX-STOP-001`,
  `EX-SIGNAL-001/002/007`.
- **A metric separation between two actors** — `EX-VULNERABLE-001..003`
  (1.0 m / 1.5 m / 0.5 m), `EX-FOLLOW-006` (150 m), `EX-RAIL-004` (5–15 m),
  `EX-PARK-003..006/009` (5 m, 6 m, 15 m, 30 cm). Several sit far outside the
  range at which a scene graph relates two actors at all.
- **A distance stated as a duration** — `EX-FOLLOW-001..005`, whose threshold
  moves with speed.
- **A condition on the posted limit, not on the vehicle** — `EX-SPEED-006/007`
  (70 or 40, keyed on whether the limit is 80 or more), `EX-VULNERABLE-002`
  (1.5 m only above 50), `EX-BUS-003` (only where the limit is 60 or lower).
- **Arrival order between two vehicles** — `EX-JUNCTION-001..005`,
  `EX-JUNCTION-014`, `EX-STOP-006`. "Arrived first" and "at the same time" are
  relations over time, not over a frame.
- **Another road user's intent** — `EX-JUNCTION-005/007`, `EX-STOP-006`,
  `EX-BUS-003`, which turn on whether the *other* vehicle is turning left or
  signalling to pull out.
- **A defeasible obligation** — `EX-SIGNAL-005` ("unless you cannot safely stop
  in time"), `EX-TURN-001` ("if it interferes with other traffic"),
  `EX-LANE-004`. Drop the exception and the rule reports violations the law does
  not.
- **Time of day and calendar** — `EX-SPEED-004` (dawn to dusk), `EX-SPEED-005`
  (8 a.m. to 5 p.m. on school days).
- **Road furniture and markings as objects** — `EX-JUNCTION-009/010` (yield
  sign), `EX-LANE-008/009` (bicycle lane, and whether its line is broken),
  `EX-RAIL-001..005` (gate, flashing lights, nearest rail),
  `EX-PEDESTRIAN-001..003` (crosswalk), `EX-PARK-003` (fire hydrant),
  `EX-BUS-001/002` (alternating red lamps), `EX-SIGNAL-007/008` (a *flashing*
  signal, a green arrow).
- **Context a trace may not name** — "within cities and towns" (`EX-SPEED-001`),
  "a divided highway" (`EX-EMERGENCY-002`), "a one-way street"
  (`EX-SIGNAL-004`), "a business district", "a curve" (`EX-TURN-002`).

Clauses in the last four groups are expected to come back `unsupported`, or
formalized with a stated residue. That is a result, not a failure.

## Sizing

92 atomic clauses is roughly 92 nodes. At `--max-nodes-per-iter 4` that is ~23
iterations, each one plan session plus up to four serial coding sessions. To
measure throughput on a shorter budget, run a theme at a time: copy the lines you
want into `laws/<theme>/laws.jsonl` and point `--laws` at it. The planner will
otherwise range over all 92 every iteration.

## Transcription notes

- Text is the manual's wording, lightly normalized: curly quotes and dashes
  flattened to ASCII, subjects made explicit where splitting a compound sentence
  left a dangling pronoun.
- Only sentences the manual frames as a requirement ("you must", "it is illegal",
  "the limit is", "you should") were transcribed. Advice, technique and
  explanation were dropped.
- The manual is a learner's guide, not the statute — it restates the Motor
  Vehicle Act in plain language. Where the manual says "should" the clause says
  "should", so the agent sees the modality the source used.
