# Reference snapshot: pilot (draft, 2026-10-21)

This folder is the pilot of revision 34, Part 2: a small, fixed set of reference passages that a
planning session may cite when it proposes a parameter value. It holds only what Part 0's six
parameter families need.

**Status: draft, for the operator to proofread.**
- No pipeline component reads this folder yet. Nothing under `traffic-spec-agent/` was changed.
- When revision 33 has landed, the snapshot moves to `traffic-spec-agent/references/`, where Part 2
  places it, and its digest becomes a semantic input of a run.
- Every passage text was transcribed from its PDF's text layer. Every judgement field (quantity,
  conditions, kind, supports, does not support, value form) was drafted by a development session
  and is marked `"curation": {"status": "draft"}`. Part 2 makes those fields the operator's, so
  each one needs your confirmation or correction.

## 1. What is in the folder

| Path | What it is |
|---|---|
| `manifest.json` | One entry per document: id, title, number, edition, date, publisher, URL, file, sha256, licence, why this edition, retrieval date. |
| `sources/*.pdf` | The four source files, byte for byte as downloaded on 2026-10-21. |
| `passages/<document>.json` | The passages of one document (33 in all). |
| `index.json` | The topic index: per topic, its passages with their quantity, kind and value form. Curated by topic, never by law. |
| `check_snapshot.py` | Re-checks the snapshot after any edit (§6). |
| `README.md` | This file. Its passage sheets (§8) are generated from `passages/*.json`; the JSON is authoritative. |

## 2. The documents

| id | Document | Edition | sha256 (first 16) | Licence | Why this edition |
|---|---|---|---|---|---|
| `nv-dmv-700` | Nevada Driver's Handbook, DMV 700 | March 2024 | `0119999c0e6469aa` | Nevada state publication; **reuse terms to confirm** | The edition the DMV serves at `dmv.nv.gov/pdfforms/dlbook.pdf` on 2026-10-21. It supersedes the July 2023 state-library copy of the first candidate list. |
| `mutcd-11r1` | Manual on Uniform Traffic Control Devices | 11th Edition with Revision 1 incorporated, December 2025 (Hotlinks PDF) | `f508594285e5fccc` | U.S. federal work, public domain | FHWA's 11th Edition page states that this is the current official edition, available only as this PDF. **Nevada's adoption, and Revision 1's effective date, are yours to confirm.** |
| `fhwa-sa-10-001` | Speed Concepts: Informational Guide, FHWA-SA-10-001 | September 2009 | `dbd1eb24d37c4d15` | U.S. federal work, public domain | The only edition. ROSA P copy; FHWA also serves it at `highways.dot.gov/media/13901`. |
| `nhtsa-hs-809-702` | A Comprehensive Examination of Naturalistic Lane-Changes, DOT HS 809 702 | Final report, March 2004 | `e033954cfb0b24b4` | U.S. DOT report, contractor-authored; **reuse terms to confirm** | The only edition. ROSA P copy; NHTSA's document page refused automated download. |

The full hashes are in `manifest.json`. The four PDFs total 38 MB; the MUTCD alone is 31.6 MB.
**Whether `sources/` is committed or kept local is yours to decide.** The hashes pin the files
either way.

## 3. The passage format

Each passage carries the five fields Part 2 names, plus the statutory-figure list:

| Field | Meaning |
|---|---|
| `quantity` | `what` is measured or prescribed, and its `definition`: for a time, its start and end events; for a distance, its reference points. |
| `conditions` | Each condition under which the passage's figures hold, with an id (`c1`, …). A parameter that cites the passage must handle each one (Part 3: `branch`, `outside_scope` or `unsupported`). |
| `kind` | One of: legal requirement, driver advice, design assumption, device placement, naturalistic statistic, **definition**. |
| `supports` / `does_not_support` | Which quantity the passage can support, and what may not be inferred from it. |
| `value_form` | One of: none, single value, range, mean, mean and standard deviation, table, and the like. |
| `statutory_figures` | Numbers in the passage that restate a statute's figure, which may not be cited for a parameter. **Empty in every passage** (§5). |

**Fields this pilot adds.** Each is for the pilot to keep or drop:

| Field | Why it was added |
|---|---|
| `kind: definition` | The MUTCD, FHWA and NHTSA definitions fit none of Part 2's five kinds. |
| `figures` | Each number with its unit, its statistic (minimum, mean, range, …) and the conditions it holds under. It makes `quoted` and `selected` checkable without re-parsing the text, and ties each number to its conditions. |
| `locator` | Section or heading, PDF page and printed page; for the MUTCD, also the paragraph category (Standard, Guidance, Option, Support). |
| `transcription` | `verbatim` for running text, checked sentence by sentence against the source. `table` or `figure` where the layout had to be rewritten into one line. |
| `notes` | What the transcription changed, or what the text cites second-hand. |
| `curation` | Draft or reviewed, by whom. |

## 4. Topics

| Topic | Passages | For which pilot family |
|---|---|---|
| `following-headway` | 3 | 3. Following headway (and 4. Following reach, which no passage gives) |
| `stop-position` | 9 | 2. Stop position |
| `stopping-sight-distance` | 8 | 6. Reasonable speed (the sight limb), and the stopping-distance terms |
| `speed-concepts` | 6 | 6. Reasonable speed |
| `lane-change` | 7 | 5. Lane-change window |

Family 1 (halt speed) has no topic, and none is expected: it is a `source` quantity, whose value
comes from the source profile, not from a reference (Part 1).

## 5. What to proofread, and what is yours to decide

1. **Each `table` and `figure` passage against its page.** The checker only confirms that each
   number occurs on the cited page; it cannot check which cell a number belongs to.
   - `nv-dmv-700#stopping.table` and `nv-dmv-700#defensive.zones-figure` (handbook pp. 41–42);
   - `fhwa-sa-10-001#ch4.table-2` (p. 11);
   - `nhtsa-hs-809-702#ch3.table-3.22` (p. 61), `#ch1.table-1.2` (p. 9), `#ch1.table-1.1` (p. 5).
2. **Every drafted judgement field.** Above all `conditions`, `supports` and `does_not_support`:
   they decide what a planner may cite a passage for.
3. **Statutory figures.** None is flagged.
   - I left out the passages that list legal figures: the handbook's speed-limit examples (p. 35)
     and its signalling distances before a lane change (p. 45).
   - No passage was compared with the corpus. A development session does not consult the corpus to
     curate the snapshot, and the held-out laws must not be read.
   - Once the doctor's check exists, it lists every number equal to a corpus figure for your
     decision.
4. **Licences:** the Nevada handbook and the NHTSA report.
5. **The MUTCD edition:** Nevada's adoption of the 11th Edition, and Revision 1's effective date.
6. **The handbook's page.** The two-second passage is on printed page 42, which is also PDF page 42.
   The second review of revision 34 cited page 41, which holds the stopping-distance table.

**Departures from revision 34's pilot list, for you to accept or reverse:**
- **The AASHTO restatements by Indiana and TxDOT are not included.** *Speed Concepts*, a federal
  public-domain work, states the same design assumptions:
  - 2.5 s perception-reaction time;
  - 11.2 ft/s² deceleration;
  - friction "that of a wet roadway".

  It adds the mean driver (1.1 s, 17.71 ft/s²) and the decelerations achievable by surface. It
  does not print the SSD formula itself; if the formula is wanted, one state manual can be added.
- **One manoeuvre study, not three.** No turning study and no following-reach study was found
  that is worth adding before the pilot needs it. Following uses the handbook, plus NHTSA's
  Table 1.1, which is second-hand.

## 6. Checking after an edit

```
python3 -I check_snapshot.py            # needs pdftotext on PATH
```

It checks:
- every source file's sha256;
- every `verbatim` sentence against the source's text layer;
- every number of a `table` or `figure` passage against its cited page;
- unique ids, condition ids, and no corpus law id;
- that `index.json` lists exactly the passages that name each topic.

On 2026-10-21 it reported `4 documents, 33 passages, 0 errors`. A corrupted copy (a changed
word, a changed table cell, an inserted law id) was reported with each error.

## 7. What the snapshot already shows for the six families (preliminary)

These are first readings for the pilot's value sheets. They are not decisions.

- **Following headway.**
  - The handbook gives 2 s as a minimum only at 40 mph or less. It asks for more at highway speed,
    on slippery roads and in reduced visibility, with no figure.
  - So `p.headway_dry` = 2 s is supported only under condition `c1`. Above 40 mph, a rule that reads
    it must branch, or the value is `unsupported` there.
  - The `p.headway_wet` (3 s) and `p.headway_ice` (5 s) values of demo12 have no passage here. The
    handbook's 5 s label concerns commercial vehicles, not ice.
  - NHTSA Table 1.1 shows observed means of 1.2–1.6 s. These are what drivers do, not a standard.
- **Following reach.** No passage. It is a recognition parameter: provisional, or later calibrated.
- **Stop position.**
  - No passage gives a halt tolerance.
  - The handbook and the MUTCD fix the reference: stop behind the line or crosswalk, otherwise
    before the intersection.
  - The MUTCD gives the line's width (12–24 in) and its placement.
  - So the standard part of `p.stop_place_tolerance` (an allowed overrun) has no evidence. Its
    measurement part is a `source` quantity.
- **Stopping and sight distance.**
  - Design values: 2.5 s and 3.4 m/s², with wet pavement already assumed. Mean driver: 1.1 s and
    5.4 m/s². Achievable: about 3.9 m/s² wet (0.4g), 2.2 m/s² snow (0.22g), 1.5 m/s² ice (0.15g).
  - smoke18's `p.decel_wet` = 2.5 m/s² matches none of these.
  - The handbook's stopping table implies about 5.8 m/s² (19 ft/s²) braking in ideal conditions.
    It must not be mixed with the design values.
- **Reasonable speed.**
  - The handbook's Basic Rule names the factors (traffic, weather and sight, surface, road type and
    width) and gives no figure.
  - *Speed Concepts* says that design speed has not been defined as a safe speed since 2001.
    It also says that the 85th percentile is an engineering convention.
  - So `p.speed_dry` = 25 m/s has no evidence here. This bears on D2, the operationalization.
- **Lane-change window.**
  - Single lane changes average 6.28 s (SD 2.01 s, N = 7,196). Each runs from the first lateral
    movement until the vehicle is settled in the new lane. The roads were an interstate and 4-lane U.S.
    highways, the latter at 45–55 mph.
  - No quantile is reported. Choosing a window that covers most lane changes needs a distribution
    assumption, which Part 3 defers.
  - demo12's "median about 4 s" is not supported by this report. The literature in its Table 1.2
    ranges from 3.2 s to 6.3 s in central values, under differing definitions.

## 8. Passage sheets

Generated from `passages/*.json` on 2026-10-21, grouped by topic. A passage that serves two topics
appears under each.

### Topic `following-headway`

Time or distance kept behind a vehicle ahead.

#### `nv-dmv-700#defensive.following-distance`

- **Where:** heading Defensive Driving Tips, PDF page 42, printed page 42. Transcription: verbatim.
- **Text:**

  > Stay behind at least two seconds. If you are driving 40 mph or less, stay at least two seconds behind the vehicle in front of you. This is a minimum following distance. Most driving instructors recommend up to four seconds. To figure this, start counting “one thousand one” when the rear of a vehicle ahead passes a fixed point, such as a sign. If you reach the sign before you have counted “one thousand two,” you are following too closely. Remember, the two-second rule is a minimum following distance. As your speed increases, so does the time and distance required for you to stop. For example, if you are traveling at 55 mph, you would need almost seven seconds to stop with perfect brakes and ideal road conditions. So at highway speeds or at any speed when streets and roads are slippery and visibility is reduced, allow a safe distance between you and the next vehicle.

- **Quantity:** time headway. *Definition:* time from the rear of the vehicle ahead passing a fixed point until your vehicle reaches that point (the passage does not say which part of your vehicle).
- **Conditions:** `c1` driving 40 mph or less; `c2` not at highway speeds; `c3` streets and roads not slippery; `c4` visibility not reduced.
- **Kind:** driver advice. **Value form:** single recommended minimum, with a recommended upper value.
- **Supports:** a minimum time headway of two seconds at 40 mph or less, in good conditions.
- **Does not support:** any value above 40 mph, at highway speed, on slippery roads or in reduced visibility (the passage asks for more, with no figure); a legal minimum.
- **Figures:** "at least two seconds" (recommended minimum, conditions c1, c2, c3, c4); "up to four seconds" (recommended (instructors), conditions c1); "almost seven seconds to stop at 55 mph" (example (time to stop, not headway)).
- **Statutory figures:** none flagged.

#### `nv-dmv-700#defensive.zones-figure`

- **Where:** heading Defensive Driving Tips (figure), PDF page 42, printed page 42. Transcription: figure.
- **Text:**

  > SEARCH 12 seconds or more. POTENTIAL STOPPING ZONE 4-8 seconds. FOLLOWING DISTANCE 2-4 seconds or more. COMMERCIAL VEHICLES 5 seconds or more.

- **Quantity:** figure labels: search time, stopping zone, following distance in seconds. *Definition:* not defined beyond the labels.
- **Conditions:** `c1` commercial vehicles (for the 5 s label).
- **Kind:** driver advice. **Value form:** range.
- **Supports:** the same advice as the following-distance text, as labels.
- **Does not support:** anything the text does not; the labels carry none of the text's conditions.
- **Figures:** "2-4 seconds or more" (recommended range); "5 seconds or more" (recommended minimum, conditions c1).
- **Statutory figures:** none flagged.
- **Notes:** Figure labels beside the text; order chosen for reading.

#### `nhtsa-hs-809-702#ch1.table-1.1`

- **Where:** chapter 1, table 1.1, PDF page 26, printed page 5. Transcription: table.
- **Text:**

  > Table 1.1. Average Time Headway From Three Relevant Studies. SOURCE | M | SD | N. Van Winsum & Heino (1996) | 1.52 s | 0.27 | 54. Allen, Magdaleno, Serafin, Eckert & Sieja (1997) | 1.22 s | 0.38 | 36. Fancher (1999) | 1.60 s | 0.80 | 108.

- **Quantity:** observed time headway. *Definition:* time gap to the lead vehicle, as each source measured it.
- **Conditions:** `c1` simulator, 70 km/h (Van Winsum & Heino); `c2` highway experiment (Allen et al.); `c3` field operational test, before manual lane changes (Fancher).
- **Kind:** naturalistic statistic. **Value form:** mean and standard deviation.
- **Supports:** how close drivers actually follow.
- **Does not support:** a safe or lawful headway: what drivers do is not what the law requires.
- **Figures:** "1.52 s (0.27)" (mean, conditions c1); "1.22 s (0.38)" (mean, conditions c2); "1.60 s (0.80)" (mean, conditions c3).
- **Statutory figures:** none flagged.
- **Notes:** Secondary citations.

### Topic `stop-position`

Where a halt is made relative to a stop line, crosswalk or intersection.

#### `nv-dmv-700#signs.stop-sign`

- **Where:** heading Stop signs, PDF page 29, printed page 29. Transcription: verbatim.
- **Text:**

  > Stop signs mean you must: • Come to a full stop behind the stop sign at the crosswalk or stop line. If the view of the cross street is blocked, slowly move forward to determine when it is safe to proceed. • If no signs or markings exist, slow down and stop, if necessary, at the point nearest the intersection where there is a view of approaching traffic on the through roadway.

- **Quantity:** where the stop is made. *Definition:* behind the crosswalk or stop line; without markings, the point nearest the intersection with a view of approaching traffic.
- **Conditions:** `c1` a crosswalk or stop line is marked; `c2` no signs or markings.
- **Kind:** driver advice. **Value form:** none.
- **Supports:** the reference feature a halt is measured against.
- **Does not support:** any distance or tolerance about the line.
- **Statutory figures:** none flagged.

#### `nv-dmv-700#signals.red-light`

- **Where:** heading Traffic signals, PDF page 30, printed page 30. Transcription: verbatim.
- **Text:**

  > A red light means STOP. Drivers must come to a complete stop before they reach the intersection. Stop your vehicle behind the crosswalk or stop line. If there is no stop line or crosswalk, stop before entering the intersection. Remain stopped until the light turns green.

- **Quantity:** where the stop is made at a red light. *Definition:* behind the crosswalk or stop line; otherwise before entering the intersection.
- **Conditions:** `c1` a stop line or crosswalk is marked; `c2` no stop line or crosswalk.
- **Kind:** driver advice. **Value form:** none.
- **Supports:** the reference feature a halt is measured against.
- **Does not support:** any distance or tolerance about the line.
- **Statutory figures:** none flagged.

#### `nv-dmv-700#markings.stop-lines`

- **Where:** heading Highway Markings, PDF page 32, printed page 32. Transcription: verbatim.
- **Text:**

  > Stop lines are the wide white lines painted across a traffic lane where you must stop before you enter the intersection. You should be able to see traffic coming from all directions.

- **Quantity:** stop line. *Definition:* a wide white line across a lane where the stop is made before entering the intersection.
- **Conditions:** none stated.
- **Kind:** driver advice. **Value form:** none.
- **Supports:** that the stop is made at the line, before the intersection.
- **Does not support:** any distance or tolerance about the line.
- **Statutory figures:** none flagged.

#### `mutcd-11r1#1C.02.256`

- **Where:** section 1C.02, item 256, category Standard, PDF page 67, printed page 26. Transcription: verbatim.
- **Text:**

  > 256. Stop Line—a solid white pavement marking line extending across approach lanes to indicate the point at which a stop is intended or required to be made.

- **Quantity:** stop line (device). *Definition:* a marking that indicates the point at which a stop is intended or required.
- **Conditions:** none stated.
- **Kind:** definition. **Value form:** none.
- **Supports:** that the stop line marks the stopping point.
- **Does not support:** how far from the line a halted vehicle may stand.
- **Statutory figures:** none flagged.

#### `mutcd-11r1#1C.02.295`

- **Where:** section 1C.02, item 295, category Standard, PDF page 70, printed page 29. Transcription: verbatim.
- **Text:**

  > 295. Yield Line—a row of solid white isosceles triangles pointing toward approaching vehicles extending across approach lanes to indicate the point at which the yield is intended or required to be made.

- **Quantity:** yield line (device). *Definition:* a marking that indicates the point at which a yield is intended or required.
- **Conditions:** none stated.
- **Kind:** definition. **Value form:** none.
- **Supports:** that the yield line marks the yielding point.
- **Does not support:** how far from the line a vehicle may stand.
- **Statutory figures:** none flagged.

#### `mutcd-11r1#1C.02.112d`

- **Where:** section 1C.02, item 112(d), category Standard, PDF page 61, printed page 20. Transcription: verbatim.
- **Text:**

  > (d) At a location controlled by a traffic control signal, regardless of the distance between the separate intersections as defined in (c) above: (1) If a stop line, yield line, or crosswalk has not been designated on the roadway (within the median) between the separate intersections, the two intersections and the roadway (median) between them shall be considered as one intersection; (2) Where a stop line, yield line, or crosswalk is designated on the roadway on the intersection approach, the area within the crosswalk and/or beyond the designated stop line or yield line shall be part of the intersection; and (3) Where a crosswalk is designated on a roadway on the departure from the intersection, the intersection shall include the area extending to the far side of such crosswalk.

- **Quantity:** extent of a signalized intersection. *Definition:* with a designated stop line, the area beyond it is part of the intersection.
- **Conditions:** `c1` a location controlled by a traffic control signal.
- **Kind:** definition. **Value form:** none.
- **Supports:** that, at a signal, passing the stop line is entering the intersection (for this Manual's purposes).
- **Does not support:** how the corpus defines an intersection (the corpus's posted definition governs a law); a distance tolerance.
- **Statutory figures:** none flagged.
- **Notes:** Part of the MUTCD definition of Intersection; (a)–(c) are not included.

#### `mutcd-11r1#3B.19.01-02`

- **Where:** section 3B.19, paragraphs 01–02, category Option (01); Standard (02), PDF page 614, printed page 573. Transcription: verbatim.
- **Text:**

  > Option: 01 Stop lines may be used to indicate the point behind which vehicles are required to stop in compliance with a STOP (R1-1) sign, a Stop Here for Pedestrians (R1-5b) sign, a Stop Here for School Crossing (R1-5c) sign, a Stop Here for Trail Crossing (R-5e) sign, or some other traffic control device that requires vehicles to stop, except YIELD signs that are not associated with passive grade crossings. Standard: 02 Stop lines shall consist of solid white lines extending across approach lanes to indicate the point at which the stop is intended or required to be made.

- **Quantity:** use of a stop line. *Definition:* the line marks the point behind which vehicles stop.
- **Conditions:** none stated.
- **Kind:** device placement. **Value form:** none.
- **Supports:** that the reference for a halt is the line, and that vehicles stop behind it.
- **Does not support:** a tolerance distance for a halt.
- **Statutory figures:** none flagged.

#### `mutcd-11r1#3B.19.05`

- **Where:** section 3B.19, paragraphs 05, category Guidance, PDF page 614, printed page 573. Transcription: verbatim.
- **Text:**

  > Guidance: 05 Stop lines should be 12 to 24 inches wide.

- **Quantity:** stop line width (device dimension). *Definition:* width of the painted line, measured along the direction of travel.
- **Conditions:** none stated.
- **Kind:** device placement. **Value form:** range.
- **Supports:** the width of the line itself (12 to 24 in, about 0.30 to 0.61 m), which bears on where 'at' or 'behind' the line is read.
- **Does not support:** an allowed overrun or a halt tolerance.
- **Figures:** "12 to 24 inches" (range).
- **Statutory figures:** none flagged.

#### `mutcd-11r1#3B.19.13`

- **Where:** section 3B.19, paragraphs 13, category Guidance, PDF page 614, printed page 573. Transcription: verbatim.
- **Text:**

  > Guidance: 13 If used, stop and yield lines should be placed a minimum of 4 feet in advance of the nearest crosswalk line at controlled intersections, except for yield lines at roundabouts as provided for in Section 3D.04 and at midblock crosswalks. In the absence of a marked crosswalk, the stop line or yield line should be placed at the desired stopping or yielding point, but should not be placed more than 30 feet or less than 4 feet from the nearest edge of the intersecting traveled way.

- **Quantity:** placement of the stop or yield line (device). *Definition:* distance of the line from the crosswalk, or from the edge of the intersecting traveled way.
- **Conditions:** `c1` controlled intersections with a marked crosswalk; `c2` no marked crosswalk.
- **Kind:** device placement. **Value form:** range.
- **Supports:** where lines are placed relative to crosswalks and the intersecting traveled way.
- **Does not support:** where a vehicle halts, or how far past the line it may stand.
- **Figures:** "a minimum of 4 feet" (minimum, conditions c1); "not more than 30 feet or less than 4 feet" (range, conditions c2).
- **Statutory figures:** none flagged.

### Topic `stopping-sight-distance`

Reaction time, braking deceleration and stopping distance.

#### `nv-dmv-700#stopping.reaction-time`

- **Where:** heading Stopping, PDF page 41, printed page 41. Transcription: verbatim.
- **Text:**

  > These three things together are called “Perception and Reaction Distance.” The amount of time it takes from the time you see that you need to stop until you step on the brakes is called “reaction time.” Reaction time increases as driving decisions become more complex or when unexpected events occur. Highway safety studies show normal reaction times are 2 to 2.5 seconds.

- **Quantity:** driver reaction time. *Definition:* time from seeing that a stop is needed until the foot steps on the brake pedal.
- **Conditions:** `c1` normal driving decisions; longer when decisions are complex or events unexpected.
- **Kind:** driver advice. **Value form:** range.
- **Supports:** a plausible range for a driver's reaction time in a stopping model.
- **Does not support:** which point of the range to choose; a design value (no population or percentile is stated); a legal standard.
- **Figures:** "2 to 2.5 seconds" (range of normal values, conditions c1).
- **Statutory figures:** none flagged.
- **Notes:** Cites unnamed 'highway safety studies'.

#### `nv-dmv-700#stopping.surface`

- **Where:** heading Stopping, PDF page 41, printed page 41. Transcription: verbatim.
- **Text:**

  > Stopping distances on a wet highway may be more than double those on dry pavement. Be especially careful during the first rain of a season because the mixture of oil and water on pavement is very dangerous. Stopping distances on packed snow and ice are greatly increased. For example, if you are going 30 mph, your stopping distance on ice would be 373 feet, well over the length of a football field.

- **Quantity:** stopping distance by surface. *Definition:* not defined in the passage; read with the table on the same page (reaction distance plus braking distance).
- **Conditions:** `c1` wet highway; `c2` packed snow and ice; `c3` 30 mph, on ice (for the 373 ft example).
- **Kind:** driver advice. **Value form:** single example value.
- **Supports:** that surface multiplies stopping distance, and its order of magnitude.
- **Does not support:** a deceleration for any surface (the reaction time and speed basis of the 373 ft figure are not stated); a factor for wet roads ('may be more than double' is not a value).
- **Figures:** "373 feet" (example, conditions c2, c3).
- **Statutory figures:** none flagged.

#### `nv-dmv-700#stopping.table`

- **Where:** heading Stopping Distance and Time, PDF page 41, printed page 41. Transcription: figure.
- **Text:**

  > STOPPING DISTANCE AND TIME For a typical passenger car with perfect 4-wheel brakes, dry pavement, level road, 2.5 second reaction time. MPH | Perception and Reaction Distance | Braking Distance | total. 25 | 92 Ft. | 35 Ft. | 127 Ft. (4.40 seconds). 35 | 128 Ft. | 68 Ft. | 196 Ft. (5.14 seconds). 45 | 165 Ft. | 113 Ft. | 278 Ft. (5.90 seconds). 55 | 202 Ft. | 168 Ft. | 370 Ft. (6.66 seconds). 65 | 238 Ft. | 256 Ft. | 494 Ft. (7.86 seconds).

- **Quantity:** stopping distance and time by speed. *Definition:* perception and reaction distance plus braking distance; the time in parentheses is the time to stop.
- **Conditions:** `c1` typical passenger car; `c2` perfect 4-wheel brakes; `c3` dry pavement; `c4` level road; `c5` 2.5 second reaction time.
- **Kind:** driver advice. **Value form:** table.
- **Supports:** stopping distances under ideal conditions, by speed.
- **Does not support:** wet, icy or degraded conditions; a design or legal stopping distance. Its braking distances imply about 19 ft/s2 (25 mph, 35 ft), far above the 11.2 ft/s2 design assumption, so it must not be mixed with design values.
- **Figures:** "2.5 second reaction time" (assumption, conditions c5); "25 mph: 92 / 35 / 127 ft (4.40 s)" (table row, conditions c1, c2, c3, c4, c5); "35 mph: 128 / 68 / 196 ft (5.14 s)" (table row, conditions c1, c2, c3, c4, c5); "45 mph: 165 / 113 / 278 ft (5.90 s)" (table row, conditions c1, c2, c3, c4, c5); "55 mph: 202 / 168 / 370 ft (6.66 s)" (table row, conditions c1, c2, c3, c4, c5); "65 mph: 238 / 256 / 494 ft (7.86 s)" (table row, conditions c1, c2, c3, c4, c5).
- **Statutory figures:** none flagged.
- **Notes:** The table is a figure; its cells are transcribed. The column heading of the totals is not printed; 'total' is added.

#### `fhwa-sa-10-001#ch2.sight-distance`

- **Where:** chapter 2, PDF page 12, printed page 4. Transcription: verbatim.
- **Text:**

  > Sight distance – the length along a roadway over which a driver has uninterrupted visibility – this is known as available sight distance. Different minimum sight distance design criteria exist for various operations and maneuvers, including stopping sight distance, passing sight distance and intersection sight distance.

- **Quantity:** available sight distance. *Definition:* length of roadway over which the driver has uninterrupted visibility.
- **Conditions:** none stated.
- **Kind:** definition. **Value form:** none.
- **Supports:** the meaning of sight distance.
- **Does not support:** a value.
- **Statutory figures:** none flagged.

#### `fhwa-sa-10-001#ch4.ssd-assumptions`

- **Where:** chapter 4, heading Sight Distance, PDF page 18, printed page 10. Transcription: verbatim.
- **Text:**

  > Stopping sight distance should be provided along the entire length of every road and street. In that sense, it is the most common type of sight distance. The first and second columns in table 2 indicate the relationship between design speed and the Green Book stopping sight distance criteria on relatively level roadways. The criteria assume a driver perception-reaction time of 2.5 seconds, driver eye height of 3.5 feet and an object height (i.e., tail lights of another vehicle) of 2.0 feet. The assumptions for driver eye height and tail light height reflect the 5th percentile statistics (9). This means that 95 percent of vehicles have a driver eye height and tail light height greater than these values. The assumed perception-reaction time exceeds the 90th percentile driver reaction time. However, normal perception-reaction times vary from about 0.75 to 1.5 seconds (10) depending on the alertness, fatigue level, alcohol consumption, and age of the driver.

- **Quantity:** perception-reaction time assumed by the AASHTO stopping sight distance criteria. *Definition:* driver perception-reaction time; eye and object heights for sight lines.
- **Conditions:** `c1` relatively level roadways; `c2` design criteria (a design driver, above the 90th percentile).
- **Kind:** design assumption. **Value form:** single value, with a range for normal drivers.
- **Supports:** a perception-reaction time of 2.5 s as a design value covering more than 90 percent of drivers; 0.75 to 1.5 s as normal times.
- **Does not support:** a typical driver's reaction time (2.5 s exceeds the 90th percentile).
- **Figures:** "2.5 seconds" (design assumption (above 90th percentile), conditions c1, c2); "3.5 feet" (5th percentile (eye height), conditions c2); "2.0 feet" (5th percentile (object height), conditions c2); "about 0.75 to 1.5 seconds" (range of normal times).
- **Statutory figures:** none flagged.

#### `fhwa-sa-10-001#ch4.table-2`

- **Where:** chapter 4, table 2, PDF page 19, printed page 11. Transcription: table.
- **Text:**

  > Table 2. Comparison of stopping sight distance requirements for various conditions. Design speed (mph) | AASHTO design stopping sight distance criteria (feet) | Estimated stopping sight distance for mean driver (feet) | Estimated stopping sight distance for dry roadway conditions (feet). 15 | 80 | 40 | 75. 20 | 115 | 60 | 110. 25 | 155 | 80 | 150. 30 | 200 | 105 | 190. 35 | 250 | 135 | 235. 40 | 305 | 165 | 285. 45 | 360 | 200 | 340. 50 | 425 | 235 | 400. 55 | 495 | 275 | 465. 60 | 570 | 320 | 535. 65 | 645 | 365 | 605. 70 | 730 | 415 | 680. 75 | 820 | 465 | 765. 80 | 910 | 520 | 850.

- **Quantity:** stopping sight distance by design speed. *Definition:* design criteria (2.5 s, 11.2 ft/s2), mean driver (1.1 s, 17.71 ft/s2), and 90th percentile driver on dry roadway.
- **Conditions:** `c1` relatively level roadways; `c2` column 2: design driver, wet-roadway friction; `c3` column 3: mean driver; `c4` column 4: 90th percentile driver, dry roadway.
- **Kind:** design assumption. **Value form:** table.
- **Supports:** required stopping distances by speed under each column's assumptions.
- **Does not support:** a speed limit or a reasonable speed (the table gives distances for a speed, not a speed for conditions).
- **Figures:** "design criteria column" (table column, conditions c1, c2); "mean driver column" (table column, conditions c1, c3); "dry roadway column" (table column, conditions c1, c4).
- **Statutory figures:** none flagged.
- **Notes:** Table cells transcribed row by row.

#### `fhwa-sa-10-001#ch4.ssd-deceleration`

- **Where:** chapter 4, heading Sight Distance, PDF page 19, printed page 11. Transcription: verbatim.
- **Text:**

  > Another assumption used in developing Green Book stopping sight distance criteria is that braking will result in a vehicle deceleration rate of 11.2 feet/second2 [0.35g]. This deceleration rate was developed through research in consideration of developments in vehicle technologies and driver performance. It also assumes that the friction provided by the driving surface is adequate to support this rate. Some vehicles with good tires on good pavement can brake at 0.85g or higher with most able to brake in emergency stops at 0.7g or better. Although most pavements provide adequate friction for the assumed deceleration rate, inclement weather conditions (e.g., snow and ice) may not. On wet pavement, most vehicles can stop at 0.4g or higher even with bald tires. The deceleration rate on ice [0.15g] and snow [0.22g] are lower (11). It has also been shown that heavy vehicles achieve the same deceleration rate as passenger cars on wet pavement when the heavy vehicle is equipped with antilock brakes (12). Since the AASHTO design criteria accounts for wet pavement and allows for controlled braking, it has been shown that the design stopping sight distance criteria are adequate for heavy vehicles.

- **Quantity:** braking deceleration. *Definition:* deceleration assumed by the design criteria, and achievable decelerations by surface.
- **Conditions:** `c1` design criteria: controlled braking, wet pavement accounted for; `c2` emergency stop, good tires, good pavement; `c3` wet pavement; `c4` ice; `c5` snow; `c6` heavy vehicles with antilock brakes, wet pavement.
- **Kind:** design assumption. **Value form:** single value, with values by surface.
- **Supports:** 3.4 m/s2 (11.2 ft/s2) as the design deceleration, which already accounts for wet pavement; achievable decelerations by surface (0.4g wet, 0.22g snow, 0.15g ice).
- **Does not support:** a separate, lower design deceleration for wet roads (the design value already assumes wet pavement).
- **Figures:** "11.2 feet/second2 [0.35g]" (design assumption, conditions c1); "0.85g" (achievable (some vehicles), conditions c2); "0.7g" (achievable (most, emergency), conditions c2); "0.4g" (achievable (most vehicles), conditions c3); "ice [0.15g]" (achievable, conditions c4); "snow [0.22g]" (achievable, conditions c5).
- **Statutory figures:** none flagged.

#### `fhwa-sa-10-001#ch4.ssd-mean-driver-and-wet`

- **Where:** chapter 4, heading Sight Distance, PDF page 19–20, printed page 11–12. Transcription: verbatim.
- **Text:**

  > In addition to the Green Book stopping sight distance design criteria shown in table 2, the third column is the estimated stopping sight distance based on the mean driver with a reaction time of 1.1 seconds and a vehicle deceleration rate of 17.71 ft/sec2 (9). This is intended to show how large the difference in required stopping sight distance is between the average driver and the design or 90th percentile driver. The final column in table 2 also shows the stopping sight distance required for the 90th percentile driver on dry roadway conditions. The design criteria assume that the available friction is that of a wet roadway. The difference between estimated wet and dry stopping sight distance is not based upon available friction, but drivers’ tendency to decelerate at a higher rate on dry pavement conditions. However, in an emergency stop, the difference between wet and dry stopping distance is due to friction.

- **Quantity:** mean-driver assumptions, and the surface assumed by the design criteria. *Definition:* reaction time and deceleration of the mean driver; design criteria assume wet-roadway friction.
- **Conditions:** `c1` mean driver; `c2` design criteria: wet roadway; `c3` 90th percentile driver, dry roadway.
- **Kind:** design assumption. **Value form:** single values.
- **Supports:** that the design criteria assume wet-roadway friction; the mean driver's 1.1 s and 17.71 ft/s2.
- **Does not support:** a dry/wet split of the design deceleration.
- **Figures:** "1.1 seconds" (mean driver, conditions c1); "17.71 ft/sec2" (mean driver, conditions c1).
- **Statutory figures:** none flagged.

### Topic `speed-concepts`

Design, operating, posted and reasonable speed, and how they differ.

#### `nv-dmv-700#speed.basic-rule`

- **Where:** heading Controlling Speed, PDF page 35, printed page 35. Transcription: verbatim.
- **Text:**

  > Nevada has a Basic Rule for driving at a “reasonable or proper” speed. This means that in addition to any posted speed limits, drivers must consider: • The amount and type of traffic • The weather and the distance you can see • The condition of the road surface; that is, whether it is dry, wet, icy or snow-covered • The type of road: — whether it is flat and straight or steep and curvy — whether it is wide or narrow It also means that drivers are never to drive at a speed that endangers you or anyone else. Depending on conditions, the safe speed may be considerably less than the posted speed limit. Remember: Speed limits are set for normal driving conditions. When bad weather makes it hard to see or makes the road slick, drivers need to adjust their speed.

- **Quantity:** factors of a reasonable or proper speed. *Definition:* traffic, weather and sight distance, surface, road geometry and width.
- **Conditions:** none stated.
- **Kind:** driver advice. **Value form:** none.
- **Supports:** the factors a reading of a reasonable speed considers.
- **Does not support:** any speed value; the weight of any factor.
- **Statutory figures:** none flagged.
- **Notes:** Restates a statutory standard in plain words; it carries no figure.

#### `fhwa-sa-10-001#ch2.85th-percentile-speed`

- **Where:** chapter 2, PDF page 11, printed page 3. Transcription: verbatim.
- **Text:**

  > 85th percentile speed – the speed at or below which 85 percent of vehicles travel. Also, see Speed distribution.

- **Quantity:** 85th percentile speed. *Definition:* the speed at or below which 85 percent of vehicles travel.
- **Conditions:** none stated.
- **Kind:** definition. **Value form:** none.
- **Supports:** the meaning of the statistic.
- **Does not support:** a reasonable speed for a driver.
- **Statutory figures:** none flagged.

#### `fhwa-sa-10-001#ch2.designated-design-speed`

- **Where:** chapter 2, PDF page 11, printed page 3. Transcription: verbatim.
- **Text:**

  > Designated design speed – the speed established as part of the geometric design process for a specific segment of roadway.

- **Quantity:** designated design speed. *Definition:* the speed established in geometric design for a road segment.
- **Conditions:** none stated.
- **Kind:** definition. **Value form:** none.
- **Supports:** the meaning of design speed.
- **Does not support:** a reasonable or safe speed for a driver.
- **Statutory figures:** none flagged.

#### `fhwa-sa-10-001#ch2.operating-speed`

- **Where:** chapter 2, PDF page 12, printed page 4. Transcription: verbatim.
- **Text:**

  > Operating speed - the speeds at which vehicles are observed operating during free flow conditions. Free flow speeds are those observed from vehicles whose operations are unimpeded by traffic control devices (e.g., traffic signals) or by other vehicles in the traffic stream. The 85th percentile of the distribution of observed speeds is the most frequently used measure of the operating speed.

- **Quantity:** operating speed. *Definition:* observed free-flow speeds; usually measured as their 85th percentile.
- **Conditions:** `c1` free flow conditions.
- **Kind:** definition. **Value form:** none.
- **Supports:** the meaning of operating speed.
- **Does not support:** what speed the law requires (an observed speed is not a standard).
- **Statutory figures:** none flagged.

#### `fhwa-sa-10-001#ch4.design-speed`

- **Where:** chapter 4, heading Design Speed, PDF page 17, printed page 9. Transcription: verbatim.
- **Text:**

  > The design speed is a selected speed used to determine the various geometric design features of the roadway (1). The historical evolution of the design speed definition has been well documented in NCHRP Report 504 (5). The design speed concept was first proposed in 1936 as “the maximum reasonably uniform speed which would be adopted by the faster driving group of vehicle operations, once clear of urban areas (6).” The American Association of State Highway Officials (AASHO) accepted a modified definition of design speed in 1938 as “the maximum approximately uniform speed which probably will be adopted by the faster group of drivers, but not, necessarily, by the small percentage of reckless ones (7).” Beginning with the 1954 version of A Policy on Geometric Design of Rural Highways, the definition of the design speed was “the maximum safe speed that can be maintained over a specified section of highway when conditions are so favorable that the design features of the highway govern. (8).” Inclusion of the “maximum safe speed” was included in the design speed definition until release of the 2001 version of the AASHTO Green Book. Removal of “the maximum safe speed” from the design speed definition was proposed in 1997 as a result of NCHRP Report 400 (9). It was recognized that operating speeds can be greater than the design speed, and the term safe was removed to avoid the perception that speeds greater than the design speed were “unsafe” (5).

- **Quantity:** design speed. *Definition:* a selected speed used to determine geometric design features; no longer defined as a safe speed.
- **Conditions:** none stated.
- **Kind:** definition. **Value form:** none.
- **Supports:** that design speed is a design input, and since 2001 is not defined as a maximum safe speed.
- **Does not support:** a reasonable or maximum safe speed for a driver on the road.
- **Statutory figures:** none flagged.

#### `fhwa-sa-10-001#ch4.85th-percentile-reasonable`

- **Where:** chapter 4, PDF page 31, printed page 23. Transcription: verbatim.
- **Text:**

  > The 85th percentile speed is used extensively in the field of traffic engineering and safety. Since the majority of drivers are considered reasonable and should be accommodated, some numerical definition for this segment of the driver population is needed. Over time, the 85th percentile driver (or speed) has been used to characterize reasonable and prudent behavior.

- **Quantity:** use of the 85th percentile speed in traffic engineering. *Definition:* a convention for characterizing the majority of drivers.
- **Conditions:** none stated.
- **Kind:** naturalistic statistic. **Value form:** none.
- **Supports:** that engineering practice uses the 85th percentile as a convention, for example in setting speed limits.
- **Does not support:** the value of a legal standard of conduct: what most drivers do is not what the law requires.
- **Statutory figures:** none flagged.

### Topic `lane-change`

What a lane change is, and how long it takes.

#### `nhtsa-hs-809-702#exec.methods`

- **Where:** section Executive Summary, PDF page 5, printed page ii. Transcription: verbatim.
- **Text:**

  > Sixteen commuters who normally drove more than 25 miles (40 km) in each direction participated. All were volunteers and were paid nominally for their participation. Half commuted on an interstate and half commuted on a U.S. highway. The interstate route was I-81 in southwestern Virginia, a heavily traveled divided interstate with hills and many heavy vehicles. The highway route included both U.S. 460 and U.S. 11. These roads require lane changes at somewhat slower travel speeds (45 to 55 mph) and are largely 4-lane (two in each direction). Half of the participants normally drove a sedan and half normally drove an SUV (sport utility vehicle). Participants were aged 20 to 64 (M = 40.8, SD = 12.2), with equal gender representation.

- **Quantity:** study population and roads. *Definition:* who drove, where, and at what speeds.
- **Conditions:** `c1` 16 commuters, Virginia; `c2` interstate and 4-lane U.S. highway; `c3` highway route at 45 to 55 mph.
- **Kind:** naturalistic statistic. **Value form:** none.
- **Supports:** the conditions under which the study's lane-change figures hold.
- **Does not support:** urban streets, intersections or low-speed lane changes.
- **Statutory figures:** none flagged.

#### `nhtsa-hs-809-702#exec.identification`

- **Where:** section Executive Summary, PDF page 5–6, printed page ii–iii. Transcription: verbatim.
- **Text:**

  > As part of the lane change identification process, the initiation and end points for each lane change were specified by video review. Each lane change was categorized by maneuver type, direction, severity, urgency, and success/magnitude. Lane change initiation was the point that the vehicle first moved laterally; the lane change ended when the vehicle was settled in the destination lane.

- **Quantity:** start and end of a lane change. *Definition:* start: the vehicle first moves laterally; end: the vehicle is settled in the destination lane; both by video review.
- **Conditions:** none stated.
- **Kind:** naturalistic statistic. **Value form:** none.
- **Supports:** the definition of the duration the study reports.
- **Does not support:** durations measured with other definitions (for example from the lane-line crossing).
- **Statutory figures:** none flagged.

#### `nhtsa-hs-809-702#exec.results`

- **Where:** section Executive Summary, PDF page 7, printed page iv. Transcription: verbatim.
- **Text:**

  > There were 8,667 lane changes observed with a mean duration of 9.07 s. Of these, 83% were single lane changes with a mean duration of 6.28 s.

- **Quantity:** lane-change duration. *Definition:* as in exec.identification.
- **Conditions:** `c1` all lane changes (single, passing, multiple); `c2` single lane changes.
- **Kind:** naturalistic statistic. **Value form:** mean.
- **Supports:** mean durations.
- **Does not support:** a quantile, or a window that covers most lane changes.
- **Figures:** "mean duration of 9.07 s" (mean, conditions c1); "mean duration of 6.28 s" (mean, conditions c2).
- **Statutory figures:** none flagged.

#### `nhtsa-hs-809-702#glossary.duration`

- **Where:** section Glossary and Acronyms, PDF page 12, printed page ix. Transcription: verbatim.
- **Text:**

  > Duration: Refers to the time required to complete lane change. Duration is calculated by subtracting the end synch number from the start synch number. See also Warning Duration.

- **Quantity:** duration. *Definition:* end synch number minus start synch number; Table 2.3 gives seconds as (End Sync minus Start Sync)/10.
- **Conditions:** none stated.
- **Kind:** definition. **Value form:** none.
- **Supports:** how the duration was computed.
- **Does not support:** a value.
- **Statutory figures:** none flagged.

#### `nhtsa-hs-809-702#ch3.table-3.22`

- **Where:** chapter 3, table 3.22, PDF page 82, printed page 61. Transcription: table.
- **Text:**

  > Table 3.22. Success/Magnitude Distributions. Success/Magnitude | Frequency | Mean Duration (St Dev) | Mean Severity (St Dev) | Mean Urgency (St Dev). Single | 7,196 | 6.28 (2.01) | 1.14 (0.69) | 1.03 (0.17). Passing | 1,071 | 26.88 (9.11) | 1.25 (0.95) | 1.16 (0.40). Multiple | 289 | 10.97 (4.99) | 1.30 (1.05) | 1.02 (0.15). Unsuccessful/partial | 111 | 13.08 (27.22) | 1.32 (1.14) | 1.06 (0.31). Grand Total or Mean | 8,667 | 9.07 (8.36) | 1.16 (0.75) | 1.04 (0.22).

- **Quantity:** lane-change duration by kind. *Definition:* as in exec.identification; seconds.
- **Conditions:** `c1` single lane changes; `c2` passing manoeuvres (two lane changes within 45 s); `c3` multiple lane changes.
- **Kind:** naturalistic statistic. **Value form:** mean and standard deviation.
- **Supports:** mean and standard deviation of single lane-change duration (6.28 s, SD 2.01 s, N = 7,196).
- **Does not support:** a quantile (none is reported; deriving one from mean and SD needs a distribution assumption).
- **Figures:** "Single: 6.28 (2.01)" (mean, conditions c1); "Single: (2.01)" (standard deviation, conditions c1).
- **Statutory figures:** none flagged.
- **Notes:** Table cells transcribed row by row; standard deviations are printed under each mean.

#### `nhtsa-hs-809-702#ch1.definition`

- **Where:** chapter 1, heading Definition of a Lane Change, PDF page 24, printed page 3. Transcription: verbatim.
- **Text:**

  > A lane change has been defined as a deliberate and substantial shift in the lateral position of a vehicle (Chovan et al., 1994). Worrall and Bullen (1970) described a lane change in three parts: the head portion is the time and distance required for a vehicle to move from a straight-ahead path to the first intercept of the lane line. The actual lane change starts when a vehicle first encroaches on the lane line between the original and destination lane. The maneuver ends once the vehicle has completely crossed that line. The tail portion of the maneuver is the time and distance required for a vehicle to return to a straight-ahead path in the destination lane after crossing the lane line.

- **Quantity:** definitions of a lane change in the literature. *Definition:* head, crossing and tail portions.
- **Conditions:** none stated.
- **Kind:** definition. **Value form:** none.
- **Supports:** that durations in the literature differ by which portions they include.
- **Does not support:** a value.
- **Statutory figures:** none flagged.

#### `nhtsa-hs-809-702#ch1.table-1.2`

- **Where:** chapter 1, table 1.2, PDF page 30, printed page 9. Transcription: table.
- **Text:**

  > Table 1.2. Lane Change Duration as Reported by Various Sources. Source | Range | Mean/Median/Mode | Notes. Worrall & Bullen (1970) | 2.3 to 4.1 s | Median = 3.2 s | Underestimated due to resolution. Finnegan & Green (1990) | 4.9 to 7.6 s | Median = 6.3 s | Including visual search time. Chovan et al. (1994) | 2.0 to 16 s | - | Initial range for CAS. Tijerina et al. (1997) | 3.5 to 6.5 s | Mean = 5.0 s | City streets. Tijerina et al. (1997) | 3.5 to 8.5 s | Mean = 5.8 s | Highway. Hetrick (1997) | 3.4 to 13.6 s | Mode = 6.0 s | City and highway segments. Hanowski et al. (2000a) | 1.1 to 16.5 s (SD = 1.71) | Mean = 4.8 s (6.0 s if head of 1.25 is added) | Local short-haul truck drivers, speeds < 45 mph; does not include head.

- **Quantity:** lane-change durations reported elsewhere. *Definition:* each source's own definition (see ch1.definition).
- **Conditions:** `c1` city streets (Tijerina); `c2` highway (Tijerina); `c3` short-haul trucks, < 45 mph, no head (Hanowski).
- **Kind:** naturalistic statistic. **Value form:** range.
- **Supports:** ranges and central values from other studies, each under its own definition.
- **Does not support:** one value without its source's definition and conditions.
- **Figures:** "Tijerina et al. (1997) city: 3.5 to 6.5 s, mean 5.0 s" (range, conditions c1); "Tijerina et al. (1997) highway: 3.5 to 8.5 s, mean 5.8 s" (range, conditions c2); "Hetrick (1997): 3.4 to 13.6 s, mode 6.0 s" (range).
- **Statutory figures:** none flagged.
- **Notes:** Secondary citations: values are this report's summary of other studies.

