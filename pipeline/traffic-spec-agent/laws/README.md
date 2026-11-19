# Active split: demo-overlap-v5

The corpus is 252 laws: 224 training and 28 held-out, named in `example/law-split.json` and
written by `python -m nrs_tools.split`; training cites no held-out law, and each split's
`definitions.jsonl` holds the definitions its laws resolve to. See `audit_and_scripts/SPLIT.md`.
Corpus partition (training/held-out) is distinct from scenario role (training/testing).
demo-overlap-v4 (2026-11-17) is the v3 roster without the two training lines that left the corpus
(LVMC 11.40.170, NRS 484B.627(1)(c)); the held-out lines and their files are unchanged.
demo-overlap-v5 (2026-11-18) is the v4 roster with the five statutory lines that return to the
corpus (NRS 484B.287(1)(a), (b), 484B.290, 484B.350(1)(a), (b); *Overlapping obligations* below) as
training lines, since training lines cite them; the held-out lines and their files are unchanged.
Historical scope notes follow.

# The law corpus — the traffic law in force in Las Vegas

## Layout

| path | what it holds |
|---|---|
| `full_list/` | the whole corpus as **posted law**: `laws.jsonl` (252 obligations) and `definitions.jsonl` (135), each record `id`, `title`, `text`, `source` and nothing else — what a government website shows and what a person adds a new law with |
| `example/train/`, `example/test/` | the training / test split of `full_list/laws.jsonl` (224 / 28), each with the `definitions.jsonl` that goes with it (`audit_and_scripts/SPLIT.md`) |
| `example/demo/`, `example/carla_smoke/` | reference-closed subsets of the training set for a first run (22 demo laws) and for a CARLA smoke test (2 lines whose duties carry standards of judgement, one of them a surrogate); each has a README saying what its lines exercise (`python -m nrs_tools.subset <name> <law id> … [--split train\|test\|full]` from `pipeline/ontology_provenance/`: the named laws, every law their texts name, all in the named split, and the posted definitions whose terms occur in a line that the definition's own applicability clause reaches) |
| `audit_and_scripts/` | the **analysis**, never the law: the sidecars `laws_meta.jsonl` (subject, theme, tier, overlap decisions, reference resolution per line) and `definitions_meta.jsonl`; the lines kept out (`excluded.jsonl` 47, `unobservable.jsonl` 4, `unresolvable.jsonl` 31) and `laws_full.jsonl` (corpus + excluded, 299); the record of how the corpus was decided: `OVERLAPS.md`, `CORPUS_AUDIT_2026-09-19.md`, `CONCRETE_DEPENDENCIES.md`, `SPLIT.md`, `SPLIT_AUDIT.md`, `split_atoms.json` |

The parsers, the selection list and the generators that produce all of it live outside the agent's
reach in `pipeline/ontology_provenance/nrs_tools/`.

## Scope (2026-10-13)

The corpus covers ordinary urban Las Vegas driving, judged for a vehicle driver (car, truck, bus,
taxi or emergency vehicle). A law leaves when what triggers it is a rare actor or event (a funeral
procession, an ice-cream truck with its signal arm out, a horse, a delivery robot, a mobile
carrying device, a low-speed vehicle, a train at a crossing) or a road the valley does not have
(canyons and mountain highways, rural turnouts), or when it binds only a skateboard or moped rider
(19 + 4 lines, `excluded_reason` "outside the ODD" or "ego scope"). A law whose trigger is an
everyday act stays even when it names a rare place for it (a U-turn on a curve), and a law another
corpus law cites stays. The evidence and the rule are in
`pipeline/ontology_provenance/LONGTAIL_ENCOUNTER_RATES_2026-10-12.md`; the list is
`nrs_tools/tiers.py` (`EXCLUDED`). With the funeral procession out of scope, the following rule is
NRS 484B.127(1) rather than LVMC 11.12.080(A), whose only addition is the procession exception
(`nrs_tools/overlaps.py`).

Operator decisions of 2026-11-17 under the same rule: the horse-drawn vehicles of LVMC 11.22.120(B)
and the three-wheeled electric vehicles excepted by NRS 484B.117(2) are rare actors, removed from
their lines by scope edits (*Laws changed for the scope* below); LVMC 11.40.170 (where a bicycle or
scooter is parked) and NRS 484B.627(1)(c) (use alternate routes on a controlled-access highway) do
not judge a driving situation a recording can show, and are in `excluded.jsonl` with their
`excluded_reason`. The equipment paragraph LVMC 11.38.120(A) (headlamp and tail lamp, their colour and
visibility) is an excluded line; LVMC 11.38.120(B), the duty to have those lights burning, stays and
cites (A) as a provision instead of carrying it. In the same way, the equipment paragraph NRS
484D.165(1) (the front and rear lamps every vehicle is equipped with, their colour, visibility and
location) is an excluded line (operator decision K4, 2026-11-18); NRS 484D.165(3), the duty to
display those lamps lighted on a vehicle parked or stopped at night, stays and cites (1) as a
provision instead of carrying it appended.

### Laws changed for the scope

These corpus lines are not the posted text as published, or not the line the corpus kept before
the scope. Every change is made by the generator from `nrs_tools/tiers.py` (`SCOPE_EDITS`,
`EXCLUDED`), `nrs_tools/overlaps.py` or the cutting tables (`make_laws.py` `SPEC`,
`references.py`), never by hand, and is recorded on the line in
`audit_and_scripts/laws_meta.jsonl` (`scope_edit`, `supersedes`, `refs`). The unedited text stays in
`pipeline/ontology_provenance/nrs_tools/sources/` and in git: the corpus, split, sidecars, evaluation records
and ontology before the scope of 2026-10-13 are those of commit `300f115`, and retired subsets are in
the history of `laws/example/`.

| line | change | posted words | corpus words | why |
|---|---|---|---|---|
| `LVMC-11-22-100` | **text edited** (`scope_edit`) | "No person shall ride or drive any **horse or** vehicle over or across any pavement newly laid …" | "No person shall ride or drive any vehicle over or across any pavement newly laid …" | a ridden horse is outside the scope; the duty to drive no vehicle over newly laid pavement stays, and `ru.ridden_or_herded_animal` leaves the ontology with it |
| `NRS-484B-117-1` | **text edited** (`scope_edit`; subsection 2 no longer appended) | "Except as otherwise provided in subsection 2 [(2) appended below], the driver of a vehicle shall not drive upon or within any sidewalk area … The provisions of subsection 1 do not apply to a vehicle that is powered solely by electricity and designed to travel on three wheels when such a vehicle is operated: (a) As an authorized emergency vehicle; (b) By an officer … of a law enforcement agency …; or (c) By a security guard …" | "the driver of a vehicle shall not drive upon or within any sidewalk area except at a permanent or temporary driveway or alley entrance. A person who violates this subsection is guilty of a misdemeanor." | the three-wheeled electric vehicles of the exception are a rare actor outside the scope; the sidewalk prohibition stays. The words "Except as otherwise provided in subsection 2," are removed by the scope edit, and subsection 2 is no longer appended (`references.py`), so no reference is left without its target |
| `LVMC-11-22-120-B` | **text edited** (`scope_edit`) | "… the use of the roadway by motor-driven cycles, bicycles**, horse-drawn vehicles** or other nonmotorized traffic …" | "… the use of the roadway by motor-driven cycles, bicycles or other nonmotorized traffic …" | a horse-drawn vehicle is outside the scope; the duty to obey the signs restricting the roadway for the other classes stays |
| `LVMC-11-38-120-B` | **line recut** ((A) no longer prepended; `LVMC-11-38-120-A` excluded and cited as the provision `DEF-LVMC-11-38-120-A`) | "All vehicles covered under this Section … shall carry at least one lighted headlamp … and one tail lamp … to the rear. The lights required by this Section shall be burning whenever …" | "The lights required by this Section [DEF-LVMC-11-38-120-A] shall be burning whenever such vehicles are in motion during the period from one-half hour after sunset … at least five hundred feet ahead." | the equipment duty of (A) is no conduct; the duty of (B) and its times and visibility condition are kept verbatim |
| `NRS-484D-165-3` | **line recut** ((1) no longer appended; `NRS-484D-165-1` excluded and cited as the provision `DEF-NRS-484D-165-1`) | "… such vehicle shall display lighted lamps meeting the requirements of subsection 1 [(1) appended below]. Every vehicle shall be equipped with one or more lamps which, when lighted, shall display a white or amber light … The location of such lamps shall be such that …" | "… such vehicle shall display lighted lamps meeting the requirements of subsection 1 [DEF-NRS-484D-165-1]." | the equipment duty of (1) is no conduct; the duty of (3), its occasion and its light condition are kept verbatim, and the lamps it requires are named by the provision |
| `NRS-484B-290` | **text edited** (`scope_edit`) | "… take precautions before proceeding to avoid a crash or injury to the person. **A person who violates this section is guilty of a civil infraction punishable pursuant to NRS 484A.703 to 484A.705, inclusive.**" | "… take precautions before proceeding to avoid a crash or injury to the person." | removed, exactly: "A person who violates this section is guilty of a civil infraction punishable pursuant to NRS 484A.703 to 484A.705, inclusive." A separate operator decision for this line, not a general rule of removing penalty sentences: NRS 484B.283(1) and 484B.287(1) cite NRS 484B.290, so its duty must stay in the corpus, and the sentence's citation of the penalties of NRS 484A.703 to 484A.705, which are no corpus line, would send the line to `unresolvable.jsonl`; the section is one undivided paragraph, so this sentence alone is removed and the operative text stays whole (operator, 2026-11-18; note below) |
| `NRS-484B-127-1` (in place of `LVMC-11-12-080-A`) | **line replaced** (overlap decision reversed) | LVMC 11.12.080(A): "… The provisions of this Section shall not apply to funeral processions." | NRS 484B.127(1): the same following rule without that sentence | funeral processions are outside the scope; the words of the two rules are otherwise the same, and the statute is kept for identical words (`OVERLAPS.md`) |

Removing the penalty sentence of NRS 484B.290 is a separate operator decision for that one line
(2026-11-18), not a general rule of removing penalty sentences. NRS 484B.283(1) and 484B.287(1) cite
NRS 484B.290, so its driving duty needs to stay in the corpus; kept whole, the line's citation of the
penalties of NRS 484A.703 to 484A.705 (no corpus line) would be an unresolved penalty reference and
would send it to `unresolvable.jsonl`. Lines that carry such a penalty reference otherwise stay where
that rule puts them: NRS 484B.327(2) and NRS 484B.550(1) remain out of the corpus, in
`unresolvable.jsonl`. No other
line's penalty sentence is removed (NRS-484B-117-1 keeps "A person who violates this subsection is
guilty of a misdemeanor.").

No other line's text differs from the posted law.

## The corpus

`full_list/laws.jsonl` is the **pipeline corpus: 252 obligations** taken verbatim from the three bodies of
law that govern driving on Las Vegas streets. 389 lines were cut; 60 were dropped because another
line states the same obligation more narrowly (*Overlapping obligations* below); 82 more are kept
out of the pipeline corpus because they do not judge a driving situation or lie outside the scope below
(`audit_and_scripts/excluded.jsonl`, 47), carry a reference no source can resolve (`audit_and_scripts/unresolvable.jsonl`, 31), or impose no duty
any planned source can observe (`audit_and_scripts/unobservable.jsonl`, 4); 5 lines that had been dropped
for a narrower text return because that text is unresolvable (`reinstated_for`).
`audit_and_scripts/laws_full.jsonl`
(299) is the corpus plus the excluded lines. Every line has a `tier` in `audit_and_scripts/laws_meta.jsonl`
(over the 299 lines of `laws_full.jsonl` — C: no judgement element, 177; Q: a concrete rule with a
judgement element, 90; S: the obligation is only a standard of care, 32) so that the planner and the evaluation can treat them differently
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

A corpus line is posted law and nothing else:

```json
{"id": "LVMC-11-52-130-A11",
 "title": "Posted places (A)(11)",
 "text":  "<verbatim text>",
 "source": "LVMC 11.52.130(A)(11)"}
```

- `source` — the citation as the website gives it: the exact subsection path, and after `with`,
  any further paragraphs whose text was prepended or appended to this line.
- `id` — the citation rewritten as an identifier: `NRS-484B-307-8d` is NRS 484B.307(8)(d);
  `LVMC-11-43-010-C1` is LVMC 11.43.010(C)(1). Section-level ids (no path) are sections with a
  single undivided paragraph. Derived from `source`; nobody types it.
- `title` — the section heading as posted, with the subsection path appended for a split section.
- `text` — the law's own words, except the lines listed under *Laws changed for the scope*. Where
  the law refers to another provision, the person who
  prepares a line resolves the reference in place: the target's corpus id in square brackets right
  after the referring words ("subsection 4 [NRS-484B-250-4]", a `[DEF-…]` id for a defined term),
  or the referenced paragraph appended with a "[(2) appended below]" note. A reference no line can
  resolve keeps the law's words and the line goes to `audit_and_scripts/unresolvable.jsonl`. The
  bracket is an annotation; the words of the law are unchanged. Every item is the preparer's
  responsibility; the pipeline does not resolve references itself.

The pipeline renders exactly `id`, `title` and `text` (`format_laws`) and reads ids
(`plan_validate.load_law_ids`). Nothing else about a line exists on the agent's side.

**What is analysis, and where it lives.** Whose conduct a line judges (`subject`: `driver` on 193
of the 252 corpus lines, `rider`, `pedestrian`, `motorcyclist`, `delivery_device_operator`, …), its coarse grouping
(`theme`, 26 of them), whether it carries a judgement standard (`tier` C / Q / S, see the ontology
§8), which broader lines it displaced (`supersedes`), which ids its references resolve to (`refs`),
which references no source can resolve (`unresolved`, as `{phrase, kind, note}`), and a return
from the dropped list (`reinstated_for`) are things the corpus construction *inferred*. They are
kept per line in `audit_and_scripts/laws_meta.jsonl`, keyed by `id`, for the split, the evaluation
scenarios and the audits. The planner infers subject and structure from the text, as it must for a
line it has never seen; a tier it cannot see is a tier it cannot lean on.

## Definitions

`full_list/definitions.jsonl` (135 records: 125 term definitions and 10 provisions) is built **from the definition chapters of the sources, not
from the corpus**: every "X defined" section of NRS 484A.015–.320 (chapter-wide definitions, 63),
NRS 484B.003–.077 (rules-of-the-road definitions, 25) plus the low-speed-vehicle definition inside
484B.637, NRS 486.011–.057 (motorcycles, 7) and LVMC 11.02 (19), and the 10 term definitions of NRS
482, 482A and 489 that a corpus text or definition takes a meaning from by citation. Each record is posted law
(`id`, `title`, `text`, `source`); its analysis — `kind: term`, the defined `terms`, `applies_to`
(NRS or LVMC), `term_in_corpus` — is in `audit_and_scripts/definitions_meta.jsonl`. Where
both sources define a term (commercial vehicle, trailer, taxicab, electric bicycle, electric
scooter, muffler) the municipal definition governs municipal lines and the statutory one
statutory lines, as LVMC 11.02.020 itself provides. `term_in_corpus` is an informational flag
(82 of the 125 term records name a term that occurs in some line); no term was selected or dropped by it. NRS 484B.800–.827
define terms for the traffic-stop data chapter and no rule of the road, and are excluded.

Ten further records are `kind: provision` in the sidecar: operative text that a line cites for its trigger
and that lives in a chapter not in the corpus — the emergency-lamp requirements of NRS
484A.480(3), the HOV sign conditions of 484A.460, high and low beam (484D.210), hand-signal
meanings (484B.420), the ice-cream-truck safety equipment (LVMC 6.47.100(C)), bus-stop and
taxistand designation by signs (11.60.010), the local e-scooter ordinance (11.40.185(A)) and the
handicapped-space sign (11.52.135(A)) and the headlamp and tail lamp a motorcycle carries (LVMC 11.38.120(A), itself an excluded equipment line: the provision only says which lights LVMC 11.38.120(B) means) and the front and rear lamps every vehicle is equipped with (NRS 484D.165(1), itself an excluded equipment line: the provision only says which lamps NRS 484D.165(3) means). Lines refer to them in the text by `[DEF-...]`; each carries
`used_by`.

The definitions that apply to the laws of a plan, resolved by the operator's declared
precedence, are rendered to the planner *after* the laws under their own heading by
`definitions_block` in `harness/phases/plan.py`, and are never a valid law reference. Definitions that a rule section states for itself ("As used in this section, 'traffic
incident' means …") are appended to the line that needs them instead.

## The corpus and what is kept out of it

Every line has a `tier` (C / Q / S) in `audit_and_scripts/laws_meta.jsonl`; `pipeline/ontology_provenance/nrs_tools/tiers.py`
and `references.py` hold the classification and its reasons. The corpus itself is `full_list/laws.jsonl`; the other four views live in `audit_and_scripts/`
and partition as follows (`laws_full.jsonl` = `laws.jsonl` + `excluded.jsonl`, 299).

| file | lines | what it holds |
|---|---|---|
| `laws.jsonl` | 252 | **the pipeline corpus**: tiers C (147), Q (79) and S (26) together. The planner decides, per line, how a judgement element is operationalized (`ATOMS.md` §8); a tier-S rule is a surrogate and is evaluated separately |
| `excluded.jsonl` | 47 | 23 lines outside the scope (below) and 24 lines that do not judge a driving situation: rider apparel (3), equipment legality while driving (9, among them the motorcycle headlamp and tail lamp of LVMC 11.38.120(A) and the vehicle lamps of NRS 484D.165(1)), where a parked bicycle or scooter stands (LVMC 11.40.170), a choice of route that one recording cannot show (NRS 484B.627(1)(c)), NRS 484B.700(1), a permission rather than an obligation, and **a rider's own body configuration on their own machine (9)** — the seat, hand and stunt duties of NRS 484B.770(1)–(2), 484B.780, 486.181(1), 486.191(1), 486.211 and LVMC 11.38.040, 11.40.150, 11.40.185(B), whose whole obligation is how the rider sits or holds the machine and is therefore neither conduct a driving plan performs nor a fact one turns on. Each carries `excluded_reason` |
| `unobservable.jsonl` | 4 | lines whose **every** duty rests on a signal no planned source observes, so no verdict about them can be founded: three horn duties (NRS 484B.270(5)(b), 484B.280(1)(b), 484D.400(2)) and the compression brake (484D.285(1)). Neither planned source carries sound. Each carries `unobservable_reason`. Kept apart from `excluded.jsonl` because the reason is the source, not the law, and it reverses the moment a source supplies the signal; see `OBSERVABILITY_2026-09-29.md`. A line that merely *contains* such a duty beside an observable one stays in the corpus and carries a residue |
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
48 municipal and 12 statutory lines dropped, 9 overlaps kept as partial (both texts stay). Examples of the
statute losing: LVMC 11.52.130(A)(4) states both hydrant distances unconditionally where NRS
484B.450(1)(d) defers the twenty-foot case to a local ordinance; LVMC 11.30.030 forbids passing a
vehicle stopped for a pedestrian outright where NRS conditions it on what the driver 'has
determined'. Examples of the Code losing: NRS 484B.283(1)(a) yields to a pedestrian within a
crosswalk on the driver's half, LVMC 11.30.020 to any pedestrian crossing the roadway.

Operator decision of 2026-11-18: four pairs once decided for the municipal text are partial
overlaps, because neither text contains the other, and the five statutory lines return to the
corpus beside the municipal lines: NRS 484B.287(1)(a) and (b) (a pedestrian crossing the highway,
shoulder included) beside LVMC 11.30.060(A) and (B) (the roadway); NRS 484B.290 (a blind pedestrian
with a service animal or white cane; yield and a full stop if necessary) beside LVMC 11.30.140(B)
(a white cane or a person assisting; an immediate full stop); NRS 484B.350(1)(a) and (b) (obey a
school crossing guard wherever the guard directs, until the highway is clear) beside LVMC 11.46.030
(stop fifty feet from a school pedestrian lane until released). The citations of those sections in
NRS 484B.283(1) ("Except as otherwise provided in NRS 484B.287, 484B.290 and 484B.350") and NRS
484B.287(1) ("Except as provided in NRS 484B.290") now resolve to the statutory lines they name, not
to the municipal lines; no corpus line's citation of one code resolves to a line of the other.

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
   the sign a municipal prohibition refers to (11.22.120). Where the paragraph a line refers to is
   itself an excluded line, it is not joined: it is cited as a provision and the referring words carry its
   id ("The lights required by this Section [DEF-LVMC-11-38-120-A]", "lighted lamps meeting the
   requirements of subsection 1 [DEF-NRS-484D-165-1]").
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

252 lines; 193 bind a `driver`. At `--max-nodes-per-iter 4` a full pass is on the order of 71
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

The evaluation scenarios — for every line of `full_list/laws.jsonl`, the structured reading an
evaluator needs before it can judge a trace against that line — live with the rest of the
evaluation, outside the pipeline, in `pipeline/evaluation/evaluation_scenario/` (see
[its README](../../evaluation/evaluation_scenario/README.md)).
