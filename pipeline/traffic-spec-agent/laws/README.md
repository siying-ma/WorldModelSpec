# The law corpus — the traffic law in force in Las Vegas

## Layout

| path | what it holds |
|---|---|
| `full_list/` | the whole corpus: `laws.jsonl` (285), `laws_full.jsonl` (296), `excluded.jsonl` (11), `unresolvable.jsonl` (31), `definitions.jsonl` (123) |
| `example/train/`, `example/test/` | the training / test split of `full_list/laws.jsonl`, each with the `definitions.jsonl` that goes with it |
| `evaluation_scenario/` | one evaluation description per corpus line — required observations, activation conditions, exceptions, timing requirements (see its own README) |
| `audit_and_scripts/` | the record of how the corpus was decided: `OVERLAPS.md`, `CORPUS_AUDIT_2026-09-19.md`, `CONCRETE_DEPENDENCIES.md`, `SPLIT.md`, `SPLIT_AUDIT.md`, `split_atoms.json` |

The parsers, the selection list and the generators that produce all of it live outside the agent's
reach in `pipeline/ontology_provenance/nrs_tools/`.

## The corpus

`full_list/laws.jsonl` is the **pipeline corpus: 285 obligations** taken verbatim from the three bodies of
law that govern driving on Las Vegas streets. 387 lines were cut; 65 were dropped because another
line states the same obligation more narrowly (*Overlapping obligations* below); 42 more are kept
out of the pipeline corpus because they do not judge a driving situation (`full_list/excluded.jsonl`,
11) or carry a reference no source can resolve (`full_list/unresolvable.jsonl`, 31); 5 lines that had been dropped
for a narrower text return because that text is unresolvable (`reinstated_for`).
`full_list/laws_full.jsonl`
(296) is the corpus plus the excluded lines, i.e. every resolvable line. Every line carries `tier`
(C: no judgement element, 163; Q: a concrete rule with a judgement element, 87; S: the obligation
is only a standard of care, 35) so that the planner and the evaluation can treat them differently
(ontology `ATOMS.md` §8).

| source | lines | what was taken |
|---|---|---|
| **Nevada Revised Statutes (NRS) 484A, 484B, 484D** | 220 (before the 19 removals) | definitions chapter (only the two conduct sections: stop/yield sign position 484A.450, warning-lamp use 484A.480); rules of the road (the bulk); equipment chapter, only sections regulating *use* of equipment while driving |
| **NRS 486** (motorcycles, mopeds, trimobiles) | 9 | operating rules: passengers, seat, hands, protective gear, lamps, lane use, passing, lane splitting |
| **Las Vegas Municipal Code (LVMC) Title 11 — Vehicles and Traffic** | 93 | every chapter that imposes a duty on a road user: 11.06, 11.12, 11.16, 11.18, 11.20, 11.22, 11.27, 11.28 (use only), 11.30, 11.32, 11.38, 11.40, 11.41, 11.42, 11.43, 11.44, 11.46, 11.48, 11.52, 11.60, 11.68 |

Where the text came from: the NRS chapters from the Legislative Counsel Bureau's published pages
(2025 Wayback snapshot; the live site and Justia sit behind a bot challenge); the LVMC from the
City's Municode publication through its content API (`api.municode.com`, product 14787, job
491986, retrieved 2026-09-18). The City's *Transportation Engineering Fact Sheets* (Public Works,
March 2025) were read in full but are **not** a source of lines: they are explanatory material
for residents and only paraphrase LVMC and NRS provisions. Every LVMC provision they cite
(11.16.060, 11.52.030, 11.52.130, 11.44.020, 11.52.305, 11.02.070) is in the corpus from the
Code itself. The parsed section trees, the generator and the raw section files live in
`pipeline/ontology_provenance/nrs_tools/`, outside the agent's reach.

## Record format

```json
{"id": "LVMC-11-52-130-A11",
 "title": "Posted places (A)(11)",
 "text":  "<verbatim text>",
 "source": "LVMC 11.52.130(A)(11)",
 "subject": "driver",
 "theme":  "stopping_standing_parking",
 "supersedes": ["NRS-484B-450-1f"]}
```

- `id` — source, chapter, section and subsection path. `NRS-484B-307-8d` is NRS 484B.307(8)(d);
  `LVMC-11-43-010-C1` is LVMC 11.43.010(C)(1). Section-level ids (no path) are sections with a
  single undivided paragraph.
- `text` — the law's own words. The pipeline renders only `id`, `title` and `text` (see
  `format_laws`); every other field is for people and for filtering.
- `source` — the exact subsection path, and after `with`, any further paragraphs whose text was
  prepended or appended to this line.
- `subject` — whose conduct the obligation judges: `driver` (204 lines), `rider` of a bicycle,
  electric bicycle, electric scooter or wheeled toy (27), `pedestrian` (20), `motorcyclist` (8),
  `delivery_device_operator` (6), `bus_operator` (4), `truck_driver` (3), and single-digit
  groups for occupants, school-bus, taxicab, tour-bus, commercial, hazardous-materials,
  low-speed-vehicle, golf-cart, emergency-vehicle, procession, moped and slow-vehicle operators.
  A run that judges an ego vehicle should filter to `driver` plus any class the ego belongs to.
- `theme` — a coarse grouping (26 of them) used only for selecting sub-corpora.
- `supersedes` — on 64 lines: the ids of lines that stated the same obligation more broadly
  and were therefore dropped from the corpus. Informational; nothing in the pipeline reads it.
- `refs` — on 53 corpus lines: the corpus ids and `DEF-*` ids that the line's internal references
  resolve to. The same ids appear **inside the text** in square brackets right after the
  referring words ("subsection 4 [NRS-484B-250-4]"), so the planner sees the resolution where
  the law makes the reference. The bracket is an annotation; the words of the law are unchanged.
  A reference to a statutory line that was dropped for a narrower municipal text resolves to the
  survivor (NRS 484B.290 → `LVMC-11-30-140-B`).
- `unresolved` — references that cannot be resolved inside the corpus, each as
  `{phrase, kind, note}` (kinds: `schedule`, `external_equipment`, `external_class`,
  `no_criterion`, `penalty`, `purpose`, `permit`, `federal_definition`, `regulation`,
  `administrative`, `region_map`, `removed_target`). A line carrying any other kind is in
  `full_list/unresolvable.jsonl`, so inside the corpus only `removed_target` remains: 3 lines,
  6 marks. A planner node for such a line must carry the phrase as a residue. The audit
  (`audit_and_scripts/CORPUS_AUDIT_2026-09-19.md` §1e) lists every mark made before the removal.

## Definitions

`full_list/definitions.jsonl` (123 records) is built **from the definition chapters of the sources, not
from the corpus**: every "X defined" section of NRS 484A.015–.320 (chapter-wide definitions, 62),
NRS 484B.003–.077 (rules-of-the-road definitions, 25) plus the low-speed-vehicle definition inside
484B.637, NRS 486.011–.057 (motorcycles, 9) and LVMC 11.02 (19). Each record is `kind: term`,
carries the defined `terms`, the verbatim text, its `source` and `applies_to` (NRS or LVMC): where
both sources define a term (commercial vehicle, trailer, taxicab, electric bicycle, electric
scooter, muffler) the municipal definition governs municipal lines and the statutory one
statutory lines, as LVMC 11.02.020 itself provides. `term_in_corpus` is an informational flag
(81 of 122 defined terms occur in some line); no term was selected or dropped by it. NRS 484B.800–.827
define terms for the traffic-stop data chapter and no rule of the road, and are excluded.

Eight further records are `kind: provision`: operative text that a line cites for its trigger
and that lives in a chapter not in the corpus — the emergency-lamp requirements of NRS
484A.480(3), the HOV sign conditions of 484A.460, high and low beam (484D.210), hand-signal
meanings (484B.420), the ice-cream-truck safety equipment (LVMC 6.47.100(C)), bus-stop and
taxistand designation by signs (11.60.010), the local e-scooter ordinance (11.40.185(A)) and the
handicapped-space sign (11.52.135(A)). Lines refer to them in the text by `[DEF-...]`; each carries
`used_by`.

All records are rendered to the planner *after* the laws under their own heading by
`format_definitions` in `scripts/phases/plan.py` (about 66 KB of text), and are never a valid law
reference. Definitions that a rule section states for itself ("As used in this section, 'traffic
incident' means …") are appended to the line that needs them instead.

## The corpus and what is kept out of it

Every line carries a `tier` (C / Q / S) and a `bucket`; `pipeline/ontology_provenance/nrs_tools/tiers.py`
and `references.py` hold the classification and its reasons. The four views live in `full_list/`
and partition as follows (`laws_full.jsonl` = `laws.jsonl` + `excluded.jsonl`, 296).

| file | lines | what it holds |
|---|---|---|
| `laws.jsonl` | 285 | **the pipeline corpus**: tiers C (163), Q (87) and S (35) together. The planner decides, per line, how a judgement element is operationalized (`ATOMS.md` §8); a tier-S rule is a surrogate and is evaluated separately |
| `excluded.jsonl` | 11 | lines that do not judge a driving situation: rider apparel (3), equipment legality while driving (7), and NRS 484B.700(1), a permission rather than an obligation. Each carries `excluded_reason` |
| `unresolvable.jsonl` | 31 | **every line that carries an `unresolved` reference** (decided 2026-09-20), with `blocking` stating why. For 8 the unresolved element is the trigger or obligation itself (the two "by their nature can have no application" clauses, a trip's purpose, a park-by-park administrative determination, the golf-cart street schedule, the Pedestrian Mall map, the handicapped permit behind a blue curb). For the other 23 the mark is a peripheral reference — a City Clerk schedule (13 lines), an equipment standard or permit class in a chapter not in the corpus (7), a federal vehicle-class definition (2), a penalty clause (2), an HOV condition "established by regulation" (1) — and the line was removed on the rule that no corpus line may carry an unresolved reference. Lines that are both excluded and marked (NRS 484A.480(5)–(7), 484D.185(1)) stay in `excluded.jsonl`. Where the unresolvable line was the narrower survivor of an overlapping pair, the resolvable text it superseded is reinstated (`reinstated_for`): NRS 484B.503, 484B.507(1), 484B.477(1)(a), LVMC 11.22.100, LVMC 11.38.120(B) |

A reference from a corpus line into a removed line keeps its bracketed id in the text and carries
an `unresolved` mark of kind `removed_target`, which does **not** itself move the line (that would
cascade): NRS 484B.300(1) → 484B.307(11); 484B.208(1) → 484B.323(1); 484B.267(2)(f) → the four
484B.607(1) move-over lines. The move-over duty toward a traffic incident (484B.607) is therefore
no longer in the corpus, because its lines cite the equipment permits behind amber and steady-blue
lamps; the approach-of-an-emergency-vehicle duty (484B.267) remains.

`audit_and_scripts/CONCRETE_DEPENDENCIES.md` (generated) lists, for every tier-C line with references, the tier or
file of each referenced id, so that a tier-C rule that composes a judgement rule or a removed line
is visible before planning.

## Overlapping obligations

The Municipal Code restates much of the statute. Where a municipal line and a statutory line
stated the same obligation, only the one with the **narrower definition** was kept: the text
whose trigger is more concretely stated (a sign, a marked crosswalk, a distance, a vehicle
class) and whose obligation has fewer open judgement terms and states its exceptions. Where the
state statute expressly preempts municipal regulation (NRS 486.180(2), motorcycle operation) the
statute was kept; where the words are identical the statute was kept; where neither text
contains the other, both were kept. Every decision and its reason is in
[audit_and_scripts/OVERLAPS.md](audit_and_scripts/OVERLAPS.md), generated from `overlaps.py` beside the corpus generator. Result:
47 municipal and 18 statutory lines dropped, 5 pairs kept as partial overlaps. Examples of the
statute losing: LVMC 11.52.130(A)(4) states both hydrant distances unconditionally where NRS
484B.450(1)(d) defers the twenty-foot case to a local ordinance; LVMC 11.30.030 forbids passing a
vehicle stopped for a pedestrian outright where NRS conditions it on what the driver 'has
determined'. Examples of the Code losing: NRS 484B.283(1)(a) yields to a pedestrian within a
crosswalk on the driver's half, LVMC 11.30.020 to any pedestrian crossing the roadway.

## How lines were cut

**One paragraph = one line**, with three mechanical adjustments so that each line can be read on
its own:

1. **Lead-ins are prepended.** Where a subsection is a list under a stem that ends in a colon,
   every item is its own line and the stem is repeated in front of it. The list conjunction that
   belonged to the enumeration ("; and", "; or", a trailing ";" or ":") is replaced by a full
   stop; no other word is changed.
2. **Qualifying paragraphs are appended (or, for context that precedes, prepended).** Where the
   law puts an exception or a definition the obligation depends on into a *separate* subsection
   — or into another section, as with the list of vehicles in NRS 484B.210(4) that three other
   lines refer to — that text is joined to the obligation verbatim and recorded in `source` after
   `with`, and the referring words are annotated "[(4) appended below]". Examples: the one-way-highway rider on the no-passing-left rules; the divided-highway
   and traffic-officer exceptions to the school-bus stop; the speed-limit-beacon definition on the
   school-zone rules; the traffic-incident definition on the move-over rules; the funeral
   procession exception on the municipal following rules; the authority paragraph that defines
   the sign a municipal prohibition refers to (11.22.120, 11.38.120).
3. **Nested lists stay inside the line** where the items are alternative *conditions* of one
   obligation rather than separate obligations (the exceptions to driving on the right half; the
   triggers of the railroad stop; the vehicles allowed in a commercial loading zone).

Compound sentences are **not** split — a verbatim corpus cannot be cut inside a sentence.
Decomposing a paragraph that carries two duties is the planning session's job, so the number of
accepted rules is not equal to the number of lines. Coverage is reported per **line**.

Municipal lines carry the Code's own phrasing, which is older than the statute's: "prima facie
speed limit", "Schedule 17-III" (a list held by the City Clerk), "City Traffic Engineer". Where a
prohibition depends on a schedule ("streets described in Schedule 25-I"), the observable is the
sign the same sentence requires ("when signs are erected giving notice thereof"); the schedule
itself is a reading assumption.

## What was left out, and why

- **Definitions** (NRS 484A.015–.320, 484B.003–.077, 486.011–.057; LVMC 11.02). Not
  obligations; the elements they define are what the ontology expresses or declares as reading
  assumptions.
- **Administrative authority, penalties, permits, licensing, reporting, insurance, procedure,
  contractor duties** — no road-user conduct is judged. This removes most of LVMC 11.04, 11.10,
  11.24, 11.32 (contractors), 11.33, 11.34, 11.50, 11.53–11.58, 11.62, 11.65, 11.70 and the
  pedicab and animal-drawn-vehicle licensing of 11.39.
- **Conduct that no exterior observation can support**: open container and drinking while
  driving (NRS 484B.150, LVMC 11.14), handheld device use (484B.165), child restraints, riding in
  a trailer, coasting in neutral, shifting gears on a crossing, unattended-vehicle engine and key
  (NRS 484B.530; the wheel-angle and brake duties of 484B.533 / LVMC 11.52.110 are kept), front
  seat occupancy (LVMC 11.22.080), window tint and windshield obstructions, television receivers,
  noise and muffler condition, load securing (NRS 484D.850/.860, LVMC 11.22.140), test-driving on
  residential streets (11.22.160), off-road driving on private land (11.26).
- **Equipment installation requirements** (headlamp count and height, reflector colour, brakes,
  windshield glass, fenders, mirrors, speedometer, safety chains; NRS 484D generally, 486.201–.311
  except use rules, LVMC 11.28 except horn and siren use, 11.38.060–.110, 11.40.200–.210).
- **Speed-limit administration** (NRS 484B.610–.621; LVMC 11.16.010, .080, .100): the obligation
  they create is the posted limit, already carried by NRS 484B.600(1)(c) and 484B.620(2) and by
  the LVMC prima facie sections that state a number.
- **Applicability rules** — NRS 484B.763, 484B.785(2), 486.331, LVMC 11.06.040, 11.40.060 ("has
  all the rights and duties of the driver of a vehicle"). Recorded here so the reading can declare
  that `driver` lines also bind `rider`, `motorcyclist` and animal-rider subjects; not lines.
- **Municipal duplicates that add nothing**: 11.42.010 and 11.52.280 (signs required before a
  restriction is enforceable — the same rule as NRS 484B.300(2) and LVMC 11.32.030, both of which
  are kept out because they govern enforceability, not conduct), 11.52.245 (a second schedule of
  prohibited streets identical in form to 11.52.240), 11.52.030(C) and (D) (cross-references and
  a permission), 11.48.100 (over-length permits), 11.52.305(C)–(E) (RV permits and mobile
  billboards), 11.52.310–.335 (City parking lots), 11.68 beyond the vehicle prohibition.

## Kept although hard

Lines were chosen for what the law demands, not for what the current sources can observe. Groups
expected to come back `unsupported`, or formalized with a stated residue:

- **Standards without an observable**: reckless, careless or imprudent driving (NRS 484B.653(1)(a),
  LVMC 11.22.020), full time and attention (11.22.010), due care, reasonable-and-proper speed,
  safe backing/turning/starting.
- **Calendar and clock conditions**: school in session and school hours (LVMC 11.16.020 has no
  beacon clause), hours a zone, loading zone or truck restriction is in effect, one to six a.m.
  (11.52.300), seven p.m. to six a.m. (11.48.050), half an hour after sunset.
- **Legal region classes and schedules**: business and residence districts, city limits, through
  streets, truck routes, the Central Traffic District, the Pedestrian Mall, park grounds, and every
  "Schedule NN" of the City Clerk. Declared per map or per trace.
- **Another road user's purpose**: a vehicle stopped "to permit a pedestrian to cross", a bus at
  its "origin or destination point", "expeditious loading". The observable evidence the law itself
  names is what a rule uses; the purpose is a residue.
- **Weight and length classes**: eight thousand pounds unladen (LVMC 11.16.110, 11.48, 11.52.305),
  twenty-four feet overall, seventy feet. Estimated from class and extent at best.
- **Las Vegas-specific devices, classes and rules** (the ontology carries these as atoms flagged
  `local`): flashing yellow arrow, red-X / green-arrow lane signals, the school-zone speed limit
  beacon, HOV lanes with occupancy and hours, centre turn lanes with distance limits, pedestrian
  countdown timers, electric bicycles and scooters, personal delivery and mobile carrying devices,
  low-speed vehicles and golf carts, amber and steady-blue warning lamps, the traffic-incident
  move-over duty, the curb colour code (red / yellow / white / blue / gray), fire lanes, hotel and
  tour-bus loading zones, the fifteen-mph prima facie limits at blind intersections and rail
  crossings, the anti-gridlock rule (11.20.070), the ice-cream-truck rule (11.22.150), the
  taxistand right-turn sign (11.60.090), roundabout lane discipline (11.43.010), the Fremont
  Street sidewalk bans.
- **Composite temporal offences**: aggressive driving (NRS 484B.650(1)); aiding a speed contest
  (LVMC 11.16.090).

## Sizing

285 lines; 204 bind a `driver`. At `--max-nodes-per-iter 4` a full pass is on the order of 71
iterations. To measure on a shorter budget, filter by `subject`, `theme` or id prefix into
`laws/<name>/laws.jsonl` and point `--laws` at it.

## Transcription notes

- Unicode is preserved (curly quotes, section signs, em dashes in municipal catchlines).
  Whitespace before punctuation left by link extraction was removed; nothing else was normalised.
- "[Effective through …]" version notes, legislative history brackets and the Municode ordinance
  history lines ("(Ord. 1278 § 13, 1967: prior code § 10-13-21)") that follow each section were
  dropped, as were Municode "Cross reference" notes.
- Cross-references inside the text are kept and annotated with the id they resolve to (see
  `refs`); where the referenced provision is not in the corpus and not a definition, the line
  carries an `unresolved` mark and the reference is a residue the rule has to state.

## Training / test split (2026-09-20)

`example/train/` and `example/test/` each hold a `laws.jsonl` and the `definitions.jsonl` that goes
with it; run a split with `--laws laws/example/train/laws.jsonl`.
[audit_and_scripts/SPLIT.md](audit_and_scripts/SPLIT.md) records the choice of test lines, the
constraints checked (no training line references a test line; the test set introduces atoms no
training line mentions; definitions follow their lines) and the atoms, values and derived concept
that are test-only. [audit_and_scripts/SPLIT_AUDIT.md](audit_and_scripts/SPLIT_AUDIT.md) says what
in the unsplit Core files exists only because of a test line. `audit_and_scripts/split_atoms.json`
is the machine-readable result the training-only ontology artifacts are derived from
(`ontology/ATOMS_train.md`, `library/splits/train/`). Regenerate with
`python -m nrs_tools.split && python -m nrs_tools.atoms_train` from
`pipeline/ontology_provenance/`.

## Evaluation scenarios

`evaluation_scenario/` carries, for every line of `full_list/laws.jsonl`, the structured reading an
evaluator needs before it can judge a trace against that line: which observations the line requires,
when it is active, what the text excepts, and what it demands of timing. See
[evaluation_scenario/README.md](evaluation_scenario/README.md).
