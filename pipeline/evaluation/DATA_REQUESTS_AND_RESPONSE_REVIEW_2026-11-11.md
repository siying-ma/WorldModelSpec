# Data requests and review of the 2026-11-08 response

Written 2026-11-11 for the data producer and the operator. It covers:
1. how we want the scene-graph generator upgraded, once, so the traces carry every atom the parser
   can produce;
2. where the 2026-11-08 response disagrees with the delivered data;
3. the precheck we run on a delivery before the label stage;
4. the current bottlenecks of label repair, and our proposal for judgment-call labels.

The item-by-item audit of the delivery is `DELIVERY_2026-11-08_AUDIT.md`.

Every count below was taken by a script from the delivery `demo-train-20261108T223214Z` (189
recordings, all traces verified against their metadata sha256). `[F]` marks a counted fact; `[J]`
marks our judgment.

## 1. One-time generator upgrade: every atom the parser can give

### 1.1 Plan

We are about to run the pipeline once on all 221 training laws. That run plans and codes every
law, and reports which atoms the rules read and which gaps remain. The run is a one-time
discovery of the atoms the corpus needs.

After that run, the ontology is settled in one batch. We then ask for a **single upgrade of the
scene-graph generator** that covers the settled atom list. Later label checks and repairs may still
change some rules, and may ask for small additions, but those requests will be far narrower than
this one.

### 1.2 What we ask of every trace

**Coverage follows the parser's capability, not the law the recording is labelled for.** Every
recording carries, for every entity in it, every atom the parser can produce.

- **Scenario content may still be designed from the law.** Which objects and events a scene holds
  is a scenario-design choice. A junction without a traffic signal emits no signal, and that is
  correct.
- **The fields of an entity that is in the scene are never trimmed by law.** If the parser can
  give a vehicle's acceleration, lane markings, occupancy or classes, they are written in every
  recording.
- **A field may be left out in three cases only:**
  1. the parser cannot produce it, declared `absent` or `estimate:<class>` in the manifest;
  2. the ontology allows the entity no value;
  3. the value is genuinely unknown, marked with `unobserved_kinds` or `unobserved_classes`.

  A membership known to be false is never marked unknown.
- **One manifest per parser (or adapter version).** If two export paths differ in capability
  (for example imported maps and native generated maps), they are two sources with two manifests.
  Alternatively, both are brought to the same capability. A manifest that declares `exact` for an
  atom some recordings do not carry is not acceptable.

**Example: 413-2 and the hand signal.** Here we assume the declared district premise matches
between rule and trace.

- **The law.** 413-2 reads: "A **signal** of intention to turn … shall be given continuously during
  not less than the last 100 feet traveled in a business or residential district". It does not say
  "turn indicator". Nevada lets any driver give that signal by lamp or by hand and arm: NRS 484B.420
  describes the arm positions for left, right and stop or slow.
- **What the rule reads.** The rule therefore reads the signal as `sig.turn_indicator ∨
  sig.hand_signal`, held over the last 100 ft (300 ft outside a district). This is the correct
  reading of the law.
- **What an agent reading the law would supply.** It would likely see "turn signal", supply
  `sig.turn_indicator` only, and treat `sig.hand_signal` as unrelated. CARLA renders no arm
  signals, so the atom is left out. That is what this delivery does: `sig.hand_signal` is in no
  manifest entry and on no road user.
- **Effect on the 15 plain labels of 413-2** [F]. In every recording, the ego's indicator is `off`
  and then switches to `left` until the turn.
  - **10 compliant labels:** the indicator is `left` in every frame of the window, and
    `left ∨ unknown` is true. The verdict is decided.
  - **5 violated labels:** the indicator is `off` somewhere in the last 100 ft, and
    `off ∨ unknown` is unknown. Someone might have signalled by hand, so **no violation can ever be
    decided**.
- **The fix is a source-level fact.** No CARLA driver gives an arm signal, so `hand_signal:
  no_signal` on every road user, with the atom declared observed, is a fact of the source, not an
  invention. With it, `off ∨ false` is false, and the violated labels become decidable too, other
  blockers aside.

The atom looked unrelated to the law's wording, yet it decides a third of the law's labels. Only
the full capability, written whether or not a law seems to need it, avoids this.

**Why partial data makes an unknown uninterpretable.** When a rule's verdict is unknown on a
recording, there are two possible causes:

1. The planner read the law correctly, and the data lacks a value the reading needs. This is a
   data request.
2. The planner chose an atom or a formulation the law does not need. This is a rule defect, and
   the rule must be repaired.

If the trace carries every atom the parser can produce, the two causes separate by themselves:
- A missing value then means only a capability the manifest declares `absent`, known before any
  run.
- An unknown on an atom the manifest declares observed points at the rule.
- A planner who reads an unrelated atom gets a decided verdict that disagrees with the label, which
  the label check already handles.

If the trace carries only what the data side judged related, every unknown is ambiguous. We would
need an extra agent, or a person, to decide case by case whether the data or the rule is at fault.
That step costs time and money, and it can be wrong in both directions:
- blaming the data for a rule error leaves a wrong rule in place;
- blaming the rule for missing data makes the planner rewrite a correct reading to avoid the atom,
  which moves the rule away from the law.

Either error lowers the accuracy of the final rules on real driving scenes.

### 1.3 Why fields must not be trimmed by law

1. **Which atoms a rule reads is decided by the pipeline's planner, and it changes.**
   - A law can be written in more than one way. Every fresh run and every label repair may choose
     different atoms.
   - Rules compose across laws. 253 reaches `sig.hand_signal` through 413-2. The stop-sign
     exception in 257 is decided by `dev.governs`.
   - A trace trimmed to the data pipeline's own reading of a law produces mismatches as soon as
     the planner reads it differently.
   - The response itself shows this: its B3 row says the earlier "no rule reads crest" claim is no
     longer current.
2. **Testing is not scoped by law.** The downstream task decides which rules a real scene breaks.
   At test time, and in the verifier (trace in, violated laws out), every rule is evaluated on
   every trace, not only the law the recording was made for.

### 1.4 Acceptance check on each delivery

For every atom the manifest declares `exact` or `estimate`, we will count its presence per
recording and per entity class. Coverage below 100% that none of the three reasons in 1.2 explains
is returned to the producer. This check lives in `pipeline/evaluation/` and needs no pipeline
change.

## 2. Where the response disagrees with the data

### 2.1 Labels and judgment-call flags

**How labels are made** [F]:
- Each recording's `metadata.json` holds one `expected_label` for the whole recording, taken from
  the scenario design (label contract v1), and a boolean `judgment_sweep`.
- Each law's `README.md` has a "Judgment call" column. It quotes the statutory words the label
  depends on, for example "business or residential district" for 413-2, or "reasonable or proper"
  for 600-1a.
- Our earlier dataset (`demo-accepted-191-core-v2`) set `judgment_call: true` whenever the producer
  marked a case that way under the demo README's rule ("accepted review metadata, normalized using
  the same rule as the demo README").
- The pipeline defines a judgment call as **a label whose verdict turns on a parameter value the
  pipeline chooses**. The label check scores judgment calls apart and never repairs on them.

**What changed between the two deliveries** [F]:
- No `expected_label` changed.
- **37 flags changed from `true` to `false`.** The response states "Labels and judgment flags are
  preserved" (D row), which does not hold.
- The flag now nearly coincides with "no label":
  - 104 recordings have no verdict and the flag true;
  - 81 have a verdict and the flag false;
  - 3 are `inconclusive` with the flag false (257-2 stopping-reference v1 0001–0003);
  - 1 has a label and the flag true (257-1 `stop-action-v1-0001`, `violation`).
- The effect on training: usable plain labels grow from 47 to 81.

**Question for the producer:** what does `judgment_sweep` mean now, and what rule set it? It
appears to have moved from "the label depends on an open statutory word" to "the recording has no
label". The two flags are different things, and the pipeline needs the first.

**The 37 changed flags, and whether each is a judgment call by the pipeline's definition** [J]:

| Law | Recordings | Labels | Statutory words quoted | Judgment call? |
|---|---|---|---|---|
| 413-2 | 15 (C124163 ×3, C245490 ×6, C329610 ×6) | compliant 10, violated 5 | "business or residential district" | **No.** The distances (100 ft, 300 ft) are stated in the statute, and the district is a premise the scenario declares. Two cautions: the "at" cases sit exactly on the statutory figure, so the verdict hangs on measurement precision; and the "300-" cases express "any other area" by omitting the district premise, which Core reads as unknown, not false. |
| 227-1 | 8 (C124163 ×4, C80903 ×2, C82860 ×2) | compliant 4, violated 4 | "established by a public authority" | **No.** The label follows where the turn crosses: an opening against a divider or prohibited section, 12 m against 20 m crossing stations. The opening's legal status is authored scenario context, not a parameter. |
| 450-2 | 4 (C111325) | compliant 2, violated 2 | "clearly marked stop line; where the driver has a view of approaching traffic" | **No**, where a crosswalk or marked line exists in the trace (a statutory stopping place), and halt against no halt is clear. It would be a judgment call only in the fallback "view of approaching traffic" case. |
| 250-4 | 2 (C111277) | compliant 1, violated 1 | (stop as at a stop sign) | **No.** Full halt before the stop line against no halt. |
| 223-1b | 3 (C245490 lanes 3/2/1) | compliant 2, not applicable 1 | "ascertained that such movement can be made with safety" | **Partly.** Applicability ("two or more clearly marked lanes") is statutory. Compliance turns on a safety margin the pipeline chooses, unless the lane change is clearly free of traffic. Please state whether other traffic is present. |
| 407 | 2 (C104538) | compliant 1, violated 1 | "upon the approach to or near the crest of a grade" | **Probably yes.** "Near" the crest is an open distance the pipeline chooses, unless the U-turn is made at the crest itself. The 500 ft visibility figure is statutory. |
| 257-2 | 3 (stopping-reference v1) | `inconclusive` | "immediate hazard; proceed cautiously; yielding…" | No verdict either way, so the flag has no effect. But the law's README says "Unresolved (judgment call)" while `metadata.json` says `judgment_sweep: false`, which is a contradiction inside the delivery. |

The opposite case: 257-1 `stop-action-v1-0001` is labelled `violation` with the flag true. Its
README says "Objective STOP failure establishes violation". A failure to stop is not a judgment
call, so this label would be usable if the flag were false.

### 2.2 Consistency of the delivered fields

The response explains missing fields as measurement limits, or as "given where the law needs it".
In the data, the missing fields follow the **scenario family and the map source**. Within a single
law and a single cell, one half of the recordings has a field and the other half does not.

**`kin.accel_longitudinal`** (declared `exact`) is absent from every user-scene of 50 recordings
[F]:
- **Whole cell families have none**, across several laws: C245490 (223-1b ×10, 413-2 ×6, 600-1e
  ×3) and C329610 (400-2a ×2, 400-2b ×2, 413-2 ×6, 600-1e ×3).
- **Within the same law and the same cell, the "attempt" or "compliant/violating" family has none
  while the "-v1" family has it.** Six cells show this:

| Law, cell | Without acceleration | With acceleration |
|---|---|---|
| 450-2 C111325 | halt-compliant/violating-attempt | crosswalk-v1 stop / no-stop |
| 307-6a C111331 | compliant/violating-attempt | yellow-v1 |
| 220-1 C150916 | compliant / violating | one-way-v1 |
| 113-2 C110763 | inside / outside (2) | inside / outside (2) |
| 250-1 C111294 | compliant/violating-attempt | yield-v1 |
| 227-1 C124163 | left-turn permitted/prohibited | median-v1 |

The law and its needs are identical within each pair, so "given where the law needs it" cannot
explain the split. It looks like one export path or controller generation that does not write the
field.

**Occupancy (`occupancy_observed`)** [F]:
- In **181 of 189** recordings, every scene lists every road user as observed.
- In **8** recordings it is `[]` in every scene: 450-2 ×2, 307-6a ×2, 220-1 ×2 and 250-4 ×2,
  4,846 scenes in all. The same traces still write **30,386 `occupies` pairs**, so Core reads
  `rel.occupies` as unknown for every road user in them.
- These are the same "attempt" families on the imported maps (2,337 lanes for 450-2, 220-1 and
  250-4; 124 for 307-6a). Each of these laws turns on being in a junction or on a lane, so the
  field is missing exactly where the law needs it most.
- The response says "Occupancy still uses the complete measured union when available". These 8
  traces carry the union but declare it unobserved.

**Other fields that follow the same split** [F]:
- Lane markings are missing on about 1,900–2,000 of about 4,700 lanes in the imported-map
  recordings of 220-1, 250-4 and 450-2, and on 52 lanes in 307-6a. No other recording misses them.
- The whole `sig` block is missing for some road users in 10 of 27 600-1a recordings (26,400
  user-scenes), although every `sig.*` atom is declared `exact`.
- `classes` is `null` on some road users in 6 of 27 600-1a recordings (13,200 user-scenes),
  although `ru.aggregate` is declared `exact`.

### 2.3 `unobserved` marks: used where the value is known, and used unevenly

**The rule.** `unobserved_classes` and `unobserved_kinds` mean "the source cannot tell whether this
entity belongs to this class or kind". Core reads a listed class as unknown whatever `classes` says
(`library/.../Core/Vocab/Atoms.lean:207-208`). So a mark may stand only where the source really
cannot tell. A membership known to be false is never marked unknown. The response's A3 row states
the same principle: masks cleared where the inventory is complete, "`child` uncertainty is cleared
only when pedestrian classification is observed false".

**Example: a car marked as possibly a pedestrian** [F]:
- In 450-2 cell C111325, `cc58ed7ec5ab` (crosswalk-v1 family) writes a CARLA vehicle as
  `classes: ["motor_vehicle"]` and clears `pedestrian`, `child`, `bicycle`, `motorcycle`, `bus`
  and `truck`. That is correct: a vehicle actor's blueprint fixes all of these.
- In the same law and cell, `8b66dc711065` (halt-attempt family), track 24, is also
  `classes: ["motor_vehicle"]` but lists `motorcycle, bus, truck, bicycle, pedestrian, child, …`
  (20 classes) as unobserved.
- The same mask appears on 77,228 user-scenes in 50 recordings, for example 223-1b `010f0658528b`,
  track 57, t = 50 ms.
- **Effect:** every rule that asks "is this road user a pedestrian?" (yield to a pedestrian, keep
  clear of a pedestrian) reads each such car as "may be a pedestrian", and its verdict becomes
  unknown.

**Structure kinds marked unobserved on (nearly) every structure** [F]:
- In 31 recordings, a structure kind the manifest declares observed is listed in `unobserved_kinds`
  on nearly every structure of the map.
- `st.obstruction` is listed on 446 structures in 17 recordings. Example: 413-2 `f80d9ccb8e95`
  lists `centre_line` and `obstruction` as unobserved on all 4 of its structures (lane 1, lane 2,
  roadway 3, highway 4). The map contains none of either.
- `st.roadway`, declared `exact`, is listed unobserved on 32 structures in 4 recordings. Example:
  220-1 `d58b55994437` marks `roadway` unobserved on its lane, sidewalk, one-way roadway and
  highway. The one-way roadway's own kind refines `roadway`, so its roadway membership is known.
- **Effect:**
  - every "is this region a roadway / an obstruction" read becomes unknown on those maps;
  - every region carries a list Core must check, which adds evaluation cost;
  - a map that is fully generated has a complete inventory, so none of these marks is needed.

**Uneven use** [F]: whether a mark appears follows the scenario family, as in 2.2, not what the
source can tell. Within one cell the v1 family clears the vehicle masks and the attempt family keeps
them.

**Request:** clear every `unobserved_*` mark the source can resolve. That covers every class of a
vehicle actor, and every kind of a generated map whose inventory is complete. Apply the same rule
in every export path.

### 2.4 Sight

**407 states a sight requirement in its own words** [F]: "where such vehicle cannot be seen by the
driver of any other vehicle approaching from either direction within 500 feet". 450-2, 250-4 and
257-1 name a stopping point "where the driver has a view of approaching traffic".

**What the delivery provides** [F]:
- `st.sight_distance` and `st.sight_along_way` are both `absent` in the manifest.
- No trace carries either field: 0 of 189 recordings.
- `acquisition-methods.json` gives the same reason for both: "No validated end-to-end source
  implementation; unknown, never false". `HANDOFF.md` adds that sight remains "excluded as
  instructed".
- The response (A13) says the retained "virtual-observer/ego rays cannot simply be renamed into
  either field".
- Its own static coverage says `st.sight_along_way` can be read in 69 recordings (61
  demo-train).

**Effect**, under the rules of our recent runs [F]:
- Every rule that reads sight is unknown where it reads it. 407's violation needs "cannot be seen"
  to be true, so no 407 recording can be judged violated; 4 of its 6 labels are violations.
- 600-1a's reasonable-speed bound cannot be judged compliant.

**Why we think it is obtainable** [J]:
- The delivery already declares `rel.visible` from "original subject-reference-to-actual-body
  collision rays". The ray-casting capability exists.
- `st.sight_along_way` asks for one distance per way. It could be computed by casting rays from the
  driver's eye to sample points along the way until the first occluded one, at the height
  convention the source declares.
- This is a computation on retained geometry, not a renaming of existing rays.

**Requests:**
1. Please confirm who instructed the exclusion and whether it still stands, since we requested
   this atom.
2. If CARLA's map geometry and the retained rays cannot support the computation, say what is
   missing, so we can decide between re-recording and leaving 407 unaligned.

## 3. Precheck before the label stage

This section is for whoever runs the pipeline. It also tells the producer how each delivery will
be read.

### 3.1 What it is

Before a run's label stage, `pipeline/evaluation/precheck/precheck.py` reports, for each law:
- the plain-labelled training recordings;
- how many of them the current data can decide;
- the reason for every blocker it predicts;
- a verdict.

| verdict | when |
|---|---|
| `enter label stage` | some plain label is decidable or only at risk |
| `not aligned (data)` | every plain label is blocked, or the law has none; no label stage and no repair is spent on it |
| `no rule` | the law's plan has no node, or the monitor does not register it |

It is **static and read-only**:
- It runs no rule over a recording. The monitor runs only on a one-scene probe, which yields Core's
  support under each manifest.
- It changes no run, library, dataset or label, and the loop does not read its output.
- It reuses the pipeline's own modules, so it selects recordings and labels exactly as the label
  stage does: `recorded/dataset.py`, `label_check.comparison_set`, `recorded/decidability.py`,
  `recorded/scoring.py` and `recorded/source_check.py`.

The label stage remains the authority on every label. Run order: generation → review → **precheck**
→ label stage.

**Per plain label**, the precheck reports one status:
- **blocked**: Core gives the rule no support;
- **at risk**: one of the following, any of which may leave the verdict unknown:
  - the rule reads an atom the manifest declares absent;
  - the source check finds the trace omits a declared atom (for example `occupancy_observed: []`);
  - a declared assumption or intention is missing;
  - a road user has no `classes`;
- **decidable**: none of these.

**Not predicted:** windows that reach past the recording, boundaries Core rejects as polygons,
identity and sampling gaps, deadlines, and mismatches. Only an evaluation shows these.

### 3.2 Commands (main checkout)

1. **Build the dataset once per delivery.** Run from `pipeline/traffic-spec-agent/`:

   ```
   python3 -m recorded.dataset build <delivery dir> <dataset dir> --jobs 6 --library library
   ```

   The input is the extracted delivery (its non-video files are enough). For the 2026-11-08
   delivery the output is about 26 GB.

2. **Build a monitor that registers the run's rules.** A monitor built before the run's rules were
   indexed registers none of them, and every law then comes out `no rule`. Build in a copy of the
   run's library, or in the library itself while no loop is running:

   ```
   cp -r <run checkout>/pipeline/traffic-spec-agent/library <scratch>/run-library
   (cd <scratch>/run-library && lake build monitor)
   ```

3. **Run the precheck.** Run from the repository root:

   ```
   python3 pipeline/evaluation/precheck/precheck.py \
       --dataset <dataset dir> \
       --run <run checkout>/pipeline/traffic-spec-agent/results/<run id> \
       --monitor <scratch>/run-library/.lake/build/bin/monitor \
       [--laws NRS-484B-413-2,NRS-484B-227-1] \
       --out precheck_<run id>.json
   ```

   The command prints the per-law table on stdout and writes the full JSON with `--out`. Exit
   status 0 means a report was written; 2 means an input was refused (no monitor, a dataset whose
   files differ from its index).

`pipeline/evaluation/precheck/README.md` documents every option, the reason codes, and how to read
the table and the JSON.

### 3.3 First result: the 2026-11-08 delivery with run `smoke31-1111-0039`

smoke31 plans 29 laws. Nine of them have recordings in this delivery, with 37 plain labels between
them.
- **Plain labels:** 0 decidable, 37 at risk, 0 blocked.
- **Law verdicts:** 6 enter the label stage (113-2, 227-1, 250-1, 250-4, 257-1, 413-2). 16 are not
  aligned for lack of data: 14 have no recording, and 253 and 600-1a have no plain label. 7 have no
  registered rule.

To see how far the static prediction holds, we then ran smoke31's rules on the same plain-labelled
recordings. That run was a report-only diagnostic: the label check's own scoring, written into no
run. The last column shows its result.

| Law | Plain (violated / compliant) | Predicted blockers (plain labels reached) | Diagnostic result |
|---|---|---|---|
| 113-2 | 2 / 2 | declared city-limits premise not supplied (4) | 4 decided, **4 match** |
| 250-1 | 2 / 2 | `st.sight_along_way` absent; `st.on_way` missing (4); approach lane does not enter the junction (2) | 4 decided, **4 match** |
| 227-1 | 4 / 4 | `st.on_way` missing (8; for example 42 of 54 structures in `0819c0dc3305`); `st.roadway` listed unobserved (2) | 1 match; 7 unknown: `st.on_way` (4), `st.on_way` + `st.roadway` (2), `st.lane_direction` (1) |
| 257-1 | 0 / 4 | `dev.human_direction` absent, `st.sight_along_way` absent, `st.on_way` missing (4 each) | 4 unknown: `dev.human_direction` |
| 413-2 | 5 / 10 | `sig.hand_signal` absent (15); declared district premise not supplied (15, a name mismatch between the run's id and the trace's); lane direction missing (9) | 15 unknown: `st.lane_direction` on all 15, plus a truncated window on the 12 C245490/C329610 recordings |
| 250-4 | 1 / 1 | `st.sight_along_way` absent; occupancy not observed (520 of 520); `entrance_of`, `on_way`, `enters_intersection` missing (2 each) | both reached the 900 s deadline (large imported map) |

**Totals:** 37 plain labels; 9 decided, all 9 match, 0 mismatch; 26 unknown; 2 deadline.

Three lessons:
- **"At risk" does not mean "unknown".** In 113-2 and 250-1 every predicted blocker sits in a
  branch the evaluation never reaches. Examples: a premise inside a disjunction; sight read only
  under a device exception that is decided false on a junction without devices; missing `ways` on
  structures the rule does not read.
- **The deciding unknown can differ from the predicted one.** In 413-2 the hand signal never became
  the deciding reason. `st.lane_direction` did: the run's veering concept reads a lane direction on
  every travel region the ego occupies, including the roadway and the highway, which have no lane
  record. The lanes themselves carry their direction. This unknown comes from the rule's
  formulation, not from the data, although it carries a data-style tag (see 4.1, item 3).
- **Whether an absent atom blocks a law depends on the rule.** `dev.human_direction` left no
  verdict unknown under an earlier run's 257-1 rule, but under smoke31's rule it is the deciding
  unknown on all 4 plain labels.

## 4. Label repair: current bottlenecks and a proposal for judgment calls

### 4.1 Bottlenecks [F, counted on the 2026-11-08 delivery]

1. **Few labels can drive a repair.** The label stage compares plain labels only: 81 of 189
   recordings. Six laws (127-1, 127-2, 127-3, 250-2, 253, 600-1a, 87 recordings) have none. 257-1's
   four are all compliant, so they leave no contrast to fit against.
2. **No mismatch, many unknowns, and an unknown repairs nothing.** In the precheck, 0 of 37 plain
   labels are free of predicted data blockers. In the diagnostic of 3.3, 9 labels matched,
   0 mismatched, 26 were unknown and 2 hit the deadline. With no mismatch, there is nothing to
   repair against.
3. **An unknown does not say whose fault it is.** It may come from missing data or from the rule's
   own formulation. Both carry the same tag, so formulation unknowns are reported as data and never
   repaired. Two examples:
   - 413-2 in run smoke28: an exact run length (`distanceWhile`) left even the compliant cases
     unknown, where the window form (`holdsFor`) decides them;
   - 413-2 in run smoke31: a lane direction read on regions that have no lanes (3.3).
4. **Data defects can surface as mismatches and be "repaired" into the rule.** In 250-4, `governs`
   names lanes only. Under an earlier run's rule this made both labels `not_applicable`, and those
   labels are now plain. The repair would see only the rendered mismatch.
5. **Declared-fact ids change between runs.** Run smoke31 renamed the district premise, so its
   413-2 rule finds the premise in no trace even though the data carries it.
6. **Scenario coverage.** In 253 the approach is 42.7 m, short of the 300 ft the statute names. In
   413-2's C245490 recordings no turn happens.

**Remedies.**
- Data: section 2, and `DELIVERY_2026-11-08_AUDIT.md`.
- Pipeline:
  - freeze the declaration-id catalogue after the 221-law discovery run;
  - add a **completion check** for each unknown: re-evaluate with the missing value set each
    possible way. If every completion gives the same verdict, the unknown comes from the
    formulation, and the law goes to coverage repair. If the verdicts differ, it is a data request,
    stated precisely (for example "`hand_signal: no_signal` decides it").

  Both pipeline changes need design and approval.

### 4.2 Judgment calls: sweep relations instead of labels

A judgment-call label turns on a threshold the pipeline chooses, for example "near the crest",
"with safety" or "reasonable and prudent". It is never used to repair, so these laws train on
nothing. The proposal was approved in principle on 2026-11-03 and is not yet implemented:

- **Use the sweeps, not a verdict per recording.** The producer's judgment cells are parameter
  sweeps: 223-1b varies the signal lead from 0 to 165 m, 257-2 varies counterpart position and
  post-stop speed, and 127-x and 600-1a vary headway and speed. For each sweep family, one
  **relation** is fixed before training. It states:
  - the factor and its direction, for example "signalling earlier never makes a compliant case
    violated";
  - the conditions held equal;
  - the obligation and subject;
  - the quantity that must respond: an intermediate value such as a safe-speed bound, or the
    verdict.
- **Who writes the relations.** A model from a second vendor drafts them, from the law text, the
  family name and the factor only, never from the rules. They are reviewed once and frozen.
  Training checks them with deterministic code: pass, fail, or insufficient.
- **Guards.**
  - Only cases with the same applicability and a decided verdict are compared.
  - The intermediate quantity is checked before the verdict. A factor that moves the bound
    without crossing it rightly leaves the verdict unchanged.
  - Missing coverage is `insufficient`, not a rule error.
  - A relation constrains the rule. It does not prove the law aligned.
  - The threshold value itself stays the operator's decision in the reading. After it is frozen,
    the judgment-call labels are re-confirmed as a new label version and scored normally.
- **What we need from the producer.** A stated meaning for `judgment_sweep`; see 2.1, where it now
  nearly equals "no label". And for each sweep cell, the varied factor, its values and units, and
  the conditions held fixed. The README "Test setting" column already carries most of this.
