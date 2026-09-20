# Corpus audit — 322 lines, four questions

Date: 2026-09-19. Scope: every line of `laws.jsonl` after overlap resolution. Method: a
regex sweep over the text (references, exception phrases, judgement vocabulary, numeric
thresholds) followed by a hand classification of every hit. Section 1 was **acted on** the same
day (reference resolution, appended exceptions, definitions, unresolved marks — all generated
from `pipeline/ontology_provenance/nrs_tools/references.py`); sections 2–4 remain proposals.

---

## 1. Vague and dangling references — resolved (2026-09-19)

The rule adopted: **no line may refer to text the planner cannot see.** Every internal reference
now carries, in square brackets right after the referring words, the corpus id(s) it resolves to;
every exception or definition the obligation depends on is either appended to the line or placed
in `definitions.jsonl` and referenced by a `DEF-*` id; and every reference that cannot be resolved
inside the corpus is marked on the line itself in an `unresolved` field with its kind and the
reason. The words of the law are unchanged; the brackets are annotations. All of this is produced
by the generator from `references.py`, so it is reproducible and cannot drift from the text.

Result: 75 lines annotated (`refs` field), 123 definitions (115 term definitions from the
definition chapters plus 8 cited provisions), 39 unresolved marks on 35 lines.

### 1a. Cross-line references — annotated with the target id

"Subsection 4" now reads "subsection 4 [NRS-484B-250-4]". Where the referenced statute was
dropped in the overlap resolution, the annotation follows `supersedes` to the surviving line:
NRS 484B.290 → `LVMC-11-30-140-B`, NRS 484B.350 → `LVMC-11-46-030`, NRS 484B.127(1) →
`LVMC-11-12-080-A`, NRS 484B.287(1)(a)/(b) → `LVMC-11-30-060-A/-B`. Section-wide references
("the provisions of this section", "in violation of NRS 484B.223", "NRS 484B.250 to 484B.267") are
expanded to the full list of lines. Composition targets for the aggressive-driving line
(NRS-484B-650-1) are therefore explicit: 6 speeding lines, 1 device line, 1 passing line, 7 lane
lines, 3 following lines, 18 right-of-way lines.

### 1b. Omitted exceptions — appended

The eleven omissions of the first cut are now appended verbatim, recorded in `source` after
`with`, and the referring words are annotated "[(N) appended below]":

| line | appended | what it adds |
|---|---|---|
| NRS-484A-480-5 | 484A.480(4) | emergency vehicles may flash upper-beam headlamps when responding |
| NRS-484B-117-1 | 484B.117(2) | three-wheeled electric vehicles of emergency services, police, security on sidewalks |
| NRS-484B-210-1 | 484B.210(4) | the 200-foot shoulder limit does not bind emergency, permitted, incident-management, tow, coroner and transit vehicles on a signed shoulder |
| NRS-484B-267-1b, NRS-484B-587-2a, NRS-484B-587-2b | 484B.210(4) (cross-section) | the same list, where those lines say "a vehicle described in paragraphs (a) to (f) of subsection 4 of NRS 484B.210" |
| NRS-484B-587-2b | 484B.587(3) | shoulder use by those vehicles where signed (was on 2a only) |
| NRS-484B-457-1 | 484B.457(2), (3) | left-hand curb on one-way highways; angle parking by ordinance |
| NRS-484B-633-2 | 484B.633(3) | the structure-maximum-speed sign 100 feet before each end |
| NRS-484B-637-2b | 484B.637(3), (4) | neighborhood occupantless vehicles up to 45 mph |
| NRS-484D-165-3 | 484D.165(1) | which lamps a parked vehicle must show |
| NRS-484D-545-1 | 484D.545(3) | no emblem on a highway closed to the public or when guarded |
| LVMC-11-38-130 | 11.38.080 (cross-section) | applies to all motorcycles and motor scooters except enclosed three-wheelers |

### 1c. Definitions in other chapters — why a dangling definition is a problem, and the fix

A dangling *exception* makes a rule over-report violations; a dangling *definition of the
trigger* is worse, because it leaves the planner to invent what the trigger observes. Three
concrete failure modes, one per definition that was missing:

- **"Flashing lights meeting the requirements of subsection 3 of NRS 484A.480"** governs
  all twelve move-over lines and the traffic-incident definition. Without 484A.480(3) the
  planner cannot know that the statute means *red or blue* revolving, flashing or steady lamps,
  not any flashing lamp. The natural guess, "any flashing light" (`sig.warning_lamp` with any
  colour or `sig.hazard`), would make every vehicle with hazard flashers an emergency vehicle
  and the move-over duty would fire on every breakdown. Amber is the colour of tow cars and
  utility vehicles, which the *incident* rule covers under a different duty (slow down, change
  lane) than the *approach* rule (pull right and stop). The colour is the distinction between two
  different obligations, and it was invisible.
- **"Uppermost / lowermost distribution of light" (NRS 484D.210)** is the only place the
  statute says what high beam and low beam are. Without it, "use a distribution other than the
  uppermost within 300 feet" cannot be mapped to `sig.headlamp = low_beam`; the planner would
  either guess or, worse, map it to headlamps off.
- **"Safety equipment described in Subsection (C) of Section 6.47.100"** (ice cream trucks)
  was in a different Title that was never retrieved. The rule "not more than 15 mph within 100
  feet of an ice cream truck that has engaged the safety equipment" had no observable trigger at
  all. LVMC 6.47.100(C) turns out to define it precisely: a roof-mounted flashing amber light, a
  yellow signal arm extended from the left side with two alternately flashing amber lamps, and
  the vehicle's hazard flashers. Every element is a `sig.warning_lamp` or `sig.hazard`
  observation, so the rule is now formalizable.

The general point: a definition the trigger depends on is *part of the obligation's
observable*. Leaving it out does not make the rule vaguer, it makes the rule's atoms unknown,
and the review phase cannot catch a proxy for a trigger it cannot read either. `definitions.jsonl`
therefore carries two kinds of record. First, **every term definition of the definition chapters**
(NRS 484A.015–.320, 484B.003–.077 and 484B.637(1), 486.011–.057, LVMC 11.02; 115 records),
selected from the sources and not from the corpus, so that the planner reads "stop", "highway",
"roadway", "intersection", "crosswalk", "vehicle", "pedestrian", "right-of-way" and "U-turn" as
the law defines them and not in ordinary language. Second, the eight **cited provisions** below,
rendered with the terms, after the laws, under their own heading and never valid as a law reference:

| id | text | used by |
|---|---|---|
| `DEF-NRS-484A-480-3` | emergency lamps: flashing red to the front; red or blue revolving, flashing or steady | 14 lines |
| `DEF-NRS-484A-460-2` | HOV lanes: the sign states occupancy and hours; HOV definition | 2 |
| `DEF-NRS-484D-210-1-2` | high beam and low beam | 2 |
| `DEF-NRS-484B-420` | hand-and-arm signal meanings | 1 |
| `DEF-LVMC-6-47-100-C` | ice cream truck safety equipment | 2 |
| `DEF-LVMC-11-60-010` | bus stops, stands and route end points are designated by signs | 4 |
| `DEF-LVMC-11-40-185-A` | the local ordinance NRS 484B.785 defers to: where e-bikes and e-scooters may operate | 1 |
| `DEF-LVMC-11-52-135-A` | how a handicapped parking space is signed | 1 |

Still external and marked unresolved (§1e): equipment standards (484D.110, 486.011–.381,
49 C.F.R. 571.108), permit classes (484B.748/.757, 484D.185–.200/.475, 484D.190) and federal
vehicle-class definitions (49 C.F.R. 383.5). None of them defines an observable the rule lacks:
in each case the line already names the observable (a lit headlamp, an amber or steady-blue
lamp, a placard) and the reference only says who is *allowed* to carry it.

### 1d. Schedules — what they are and how each line resolves

The Municipal Code does not name streets in its text. Restrictions that apply on particular
streets say "upon those streets described in Schedule NN", where the schedule is a list kept by
the City Clerk and amended by the Traffic Engineer's written finding. Thirteen corpus lines
cite one. A schedule is a **legal region class** in the ontology's sense (`ATOMS.md` §9): it is
not on the road and cannot be read from a scene. Two things save these lines from being
unformalizable, and they differ by line:

| line | schedule | what it lists | the observable the same sentence supplies | residue |
|---|---|---|---|---|
| LVMC-11-16-110 | 25-VII | streets with a 25 mph truck limit | "When signs are erected giving notice thereof" — a truck speed sign (`dev.speed_limit_sign` with a class legend) | none beyond the sign |
| LVMC-11-16-110 | 29-II | truck routes (excluded from 25-VII) | truck-route signs (11.48.080) | none |
| LVMC-11-41-020 | 28-I | streets where golf carts may operate | **none** — the streets are listed, not signed; only the crossing is "marked and signed" | the permitted region is a reading assumption (`asm.*`) |
| LVMC-11-44-020/-030/-040/-060/-080 | 18-I…VI | streets with passenger, hotel, time-limited, commercial and tour-bus loading zones | "in any place marked as a … loading zone" and "during hours when the regulations … are effective" — the curb marking and its sign (`st.curb_zone` kind + `dev.zone_sign` conditions) | the hours, if the sign does not state them |
| LVMC-11-48-030 | 29-II | truck routes | "posted with adequate signs" (11.48.080); temporary routes posted (11.48.070) | whether a given street is a truck route where no sign is in view |
| LVMC-11-52-180-A/-B | 17-I, 17-II | alleys with parking prohibitions | "When signs are posted giving notice thereof" | none |
| LVMC-11-52-250/-260/-270 | 17-IV, 17-V, 17-VI | streets with hourly or time-limited parking prohibitions | "when signs are erected … or the adjacent curbing … is painted" and the hours/limits "specified on the posted signage" | the day exceptions (Sundays, holidays) — calendar assumptions |

So twelve of thirteen schedule references resolve to a sign or curb marking the line itself
requires, which is exactly what the ontology's `dev.zone_sign` (with its `conditions`
attribute) and `st.curb_zone` (with `colour`) were added for. The thirteenth (golf carts) is a
pure region and is marked `schedule_region`. All thirteen carry an `unresolved` mark of kind
`schedule` so that the planner records the schedule as a residue and formalizes the sign.

Related but not schedules: "business district", "residence district", "Central Traffic
District", "Pedestrian Mall" and "park grounds" are region classes defined by ordinance or by
building frontage, likewise reading assumptions; where the Code posts them (pedestrian mall
signs, park entrance signs) `dev.zone_sign` is the observable.

### 1e. Genuinely unresolvable — marked on the line

39 marks on 35 lines. Each is an `unresolved` entry `{phrase, kind, note}` on the line, so the
planner sees it beside the text and the harness can require it to appear in the node's
residues. By kind:

| kind | count | meaning |
|---|---|---|
| `schedule` / `schedule_region` | 14 | a City Clerk street list (§1d) |
| `external_equipment` / `external_standard` | 8 | an equipment specification in a chapter not in the corpus; the observable is already on the line |
| `external_class` / `external_designation` | 4 | a vehicle class or route designation defined elsewhere (DOT vehicles, permit holders, temporary truck routes) |
| `no_criterion` | 2 | "except as to those provisions which by their nature can have no application" — no rule of decision exists |
| `penalty` | 2 | refers to penalty subsections; no conduct |
| `federal_definition` | 2 | 49 C.F.R. § 383.5 (hazardous materials; commercial motor vehicle) |
| `purpose` | 2 | a trip's purpose (school program; celebrity-home tour) |
| `permit` | 2 | a handicapped permit or plate |
| `regulation` | 1 | HOV conditions "established by regulation" but not on the sign |
| `administrative` | 1 | a traffic-engineer determination |
| `region_map` | 1 | the Pedestrian Mall boundary exhibit |

Full list:

| line | kind | phrase | note |
|---|---|---|---|
| `NRS-484A-480-5` | external_standard | “49 C.F.R. § 571.108” | federal lamp standard; the headlamp modulation it permits is not observable as distinct from flashing |
| `NRS-484A-480-6` | external_class | “a vehicle operated pursuant to NRS 408.437” | Department of Transportation vehicles; not in the corpus; approximated by ru.official_vehicle kind highway_maintenance |
| `NRS-484A-480-7` | external_equipment | “a motorcycle pursuant to NRS 486.261” | a blue insert of up to one inch in a motorcycle tail lamp; not distinguishable from a blue lamp at scene scale |
| `NRS-484A-480-7` | external_class | “a vehicle operated pursuant to NRS 408.437” | as for the preceding line |
| `NRS-484B-307-11` | no_criterion | “except as to those provisions which by their nature can have no application” | no rule of decision is given for which provisions apply at a mid-block signal; residue |
| `NRS-484B-323-1` | regulation | “or established by regulation” | conditions not on the sign are not observable |
| `NRS-484B-327-2` | penalty | “any additional penalty set forth in NRS 484B.130 or 484B.135” | penalty clause; no conduct |
| `NRS-484B-360-2` | purpose | “activity which is properly a part of a school program” | the purpose of a trip is not observable; reading assumption per trace |
| `NRS-484B-550-1` | penalty | “Except as otherwise provided in this section” | the other subsections of 484B.550 are penalties; no conduct |
| `NRS-484B-560-1` | federal_definition | “hazardous materials as that term is defined in 49 C.F.R. § 383.5” | the class is federal; the observable is the placard (ru.hazardous_materials_vehicle) |
| `NRS-484B-560-5` | federal_definition | “commercial motor vehicle, as that term is defined in 49 C.F.R. § 383.5” | a weight-and-use class; estimated from vehicle class and size |
| `NRS-484B-607-1a` | external_equipment | “meeting the requirements of NRS 484B.748” | permits and standards for amber and steady-blue lamps (484B.748, 484D.185, .195, .200, .475); the observable is the lamp colour and mode (sig.warning_lamp) |
| `NRS-484B-607-1b` | external_equipment | “meeting the requirements of NRS 484B.748” | permits and standards for amber and steady-blue lamps (484B.748, 484D.185, .195, .200, .475); the observable is the lamp colour and mode (sig.warning_lamp) |
| `NRS-484B-607-1c` | external_equipment | “meeting the requirements of NRS 484B.748” | permits and standards for amber and steady-blue lamps (484B.748, 484D.185, .195, .200, .475); the observable is the lamp colour and mode (sig.warning_lamp) |
| `NRS-484B-607-1d` | external_equipment | “meeting the requirements of NRS 484B.748” | permits and standards for amber and steady-blue lamps (484B.748, 484D.185, .195, .200, .475); the observable is the lamp colour and mode (sig.warning_lamp) |
| `NRS-484B-790-3` | no_criterion | “except those which by their nature can have no application” | which pedestrian duties a mobile carrying device inherits is left to the reader; residue |
| `NRS-484D-185-1` | external_class | “as authorized in NRS 484B.748, 484B.757 or 484D.190” | tow cars at a hazard, private patrol vehicles, food vendors: permit-based classes; approximated by ru.official_vehicle / ru.vending_vehicle |
| `NRS-484D-220-1` | external_equipment | “meeting the requirements of NRS 484D.110” | headlamp count and mounting height; equipment law, not conduct |
| `NRS-486-251-1` | external_equipment | “as respectively required pursuant to NRS 486.011 to 486.381, inclusive” | the lamps a motorcycle carries (head lamp, tail lamp); the observable is a lit head lamp and tail lamp |
| `LVMC-11-16-050` | administrative | “provided after a traffic study the City Traffic Engineer determines that such a prima faci” | whether the limit is in force at a given park is an administrative fact; reading assumption per map |
| `LVMC-11-16-110` | schedule | “Schedule 25-VII” | a street list held by the City Clerk, not in the corpus and not observable on the road; the same sentence makes the posted sign or curb marking the condition, and the sign is the observable |
| `LVMC-11-16-110` | schedule | “Schedule 29-II” | truck routes; posted with signs per 11.48.080 |
| `LVMC-11-41-020` | schedule_region | “locations designated by Schedule 28-I” | the streets where golf carts may operate are listed, not signed; region as reading assumption |
| `LVMC-11-44-020` | schedule | “Schedule 18-I” | a street list held by the City Clerk, not in the corpus and not observable on the road; the same sentence makes the posted sign or curb marking the condition, and the sign is the observable |
| `LVMC-11-44-030` | schedule | “Schedule 18-II” | a street list held by the City Clerk, not in the corpus and not observable on the road; the same sentence makes the posted sign or curb marking the condition, and the sign is the observable |
| `LVMC-11-44-040` | schedule | “Schedule 18-III” | a street list held by the City Clerk, not in the corpus and not observable on the road; the same sentence makes the posted sign or curb marking the condition, and the sign is the observable |
| `LVMC-11-44-060` | schedule | “Schedule 18-V” | a street list held by the City Clerk, not in the corpus and not observable on the road; the same sentence makes the posted sign or curb marking the condition, and the sign is the observable |
| `LVMC-11-44-080` | schedule | “Schedule 18-VI” | a street list held by the City Clerk, not in the corpus and not observable on the road; the same sentence makes the posted sign or curb marking the condition, and the sign is the observable |
| `LVMC-11-48-030` | schedule | “Schedule 29-II” | truck routes; posted with signs per 11.48.080; the sign is the observable |
| `LVMC-11-48-030` | external_designation | “temporary truck routes hereafter designated by the Department of Public Works pursuant to ” | temporary routes are posted with temporary truck-route signs (11.48.070); the sign is the observable |
| `LVMC-11-52-030-E` | permit | “displays a valid handicapped permit or license plate” | not reliably observable; residue |
| `LVMC-11-52-180-A` | schedule | “Schedule 17-I” | a street list held by the City Clerk, not in the corpus and not observable on the road; the same sentence makes the posted sign or curb marking the condition, and the sign is the observable |
| `LVMC-11-52-180-B` | schedule | “Schedule 17-II” | a street list held by the City Clerk, not in the corpus and not observable on the road; the same sentence makes the posted sign or curb marking the condition, and the sign is the observable |
| `LVMC-11-52-250` | schedule | “Schedule 17-IV” | a street list held by the City Clerk, not in the corpus and not observable on the road; the same sentence makes the posted sign or curb marking the condition, and the sign is the observable |
| `LVMC-11-52-260` | schedule | “Schedule 17-V” | a street list held by the City Clerk, not in the corpus and not observable on the road; the same sentence makes the posted sign or curb marking the condition, and the sign is the observable |
| `LVMC-11-52-270` | schedule | “Schedule 17-VI” | a street list held by the City Clerk, not in the corpus and not observable on the road; the same sentence makes the posted sign or curb marking the condition, and the sign is the observable |
| `LVMC-11-52-270` | permit | “lawfully displays on the vehicle a special or temporary handicap parking permit or plate” | a permit or plate is not reliably observable; residue |
| `LVMC-11-60-030-B1` | purpose | “"celebrity home" tour or to any function of a duly established and recognized nonprofit or” | the purpose of the trip is not observable; residue |
| `LVMC-11-68-030` | region_map | “the area designated under Section 11.68.040” | the Pedestrian Mall boundary is an ordinance exhibit map; region as reading assumption, or dev.zone_sign pedestrian_mall where posted |

The two `no_criterion` marks (NRS-484B-307-11, NRS-484B-790-3) are the only references that
no source could resolve: the statute delegates to the reader which provisions apply. Everything
else is either an equipment or class definition whose observable the line already names, or an
administrative fact that the reading declares per map or per trace.

---

## 2. Rules that name another rule as an exception

111 lines carry an exception phrase. Three kinds matter for the pipeline; the fourth is noise.

### 2a. Exceptions that point at a rule in the corpus — rule composition

The design (`CORE_V2_LEAN_DESIGN.md` §5.2, `Formula.rule`) already allows a rule to refer to
another rule's verdict. These lines need it:

| line | phrase | target lines |
|---|---|---|
| NRS-484B-283-1a, -1b, -1d1…-1d4 | "Except as otherwise provided in NRS 484B.287, 484B.290 and 484B.350" | NRS-484B-287-1c/1d/1e; **LVMC-11-30-140-B** (NRS-290 was superseded); **LVMC-11-46-030** (NRS-350 was superseded) |
| NRS-484B-287-1c, -1d, -1e | "Except as provided in NRS 484B.290" | **LVMC-11-30-140-B** |
| NRS-484B-403-1 | "except as prohibited by … NRS 484B.227, 484B.363 and 484B.407" | NRS-484B-227-1, -363-3, -407 |
| NRS-484B-270-2b | "Except as otherwise provided in NRS 484B.213 and 484B.217" | NRS-484B-213-*, -217-2 |
| NRS-484B-300-1 | "Except as otherwise provided in NRS 484B.307" | NRS-484B-307-* |
| NRS-484B-307-2b, -4b, -8b, -9c | "unless directed otherwise by another device as provided in NRS 484B.283" | NRS-484B-283-1d1…1d4 |
| NRS-484B-200-1 | "(a) When overtaking … under the laws governing such movements" | NRS-484B-207-1, -210-1, -213-* |
| NRS-484B-207-2 | "Except when overtaking and passing on the right is permitted" | NRS-484B-210-1 |
| NRS-484B-217-2 | "(4) … turn signal in compliance with NRS 484B.413" | NRS-484B-413-2 |
| NRS-484B-267-2a, NRS-484B-607-1a | "reasonable and proper, pursuant to the criteria set forth in subsection 1 of NRS 484B.600" | NRS-484B-600-1a (a judgement line; see §3) |
| NRS-484B-650-1 | "in violation of NRS 484B.363 or 484B.600 … 484B.300 … 484B.210 … 484B.223 … 484B.127 … 484B.250 to 484B.267" | the corresponding lines; note NRS-484B-127-1 was superseded by **LVMC-11-12-080-A** |
| LVMC-11-52-250, -260 | "Except as provided in LVMC 11.52.030" | LVMC-11-52-030-A/B/E |
| NRS-484B-208-1 | "(a)(3) Traveling in a lane designated for the use of high-occupancy vehicles … if the driver complies" | NRS-484B-323-1 |

**Finding.** Three exception targets now point at a *municipal* survivor because the statutory
line was dropped in the overlap resolution (NRS 484B.290, 484B.350, 484B.127(1)). The
generator should carry this mapping: when a dropped id is the target of a reference, the
reference resolves to the line that supersedes it. Add it to the `refs` field of §1a.

### 2b. "Lawfully" — composition with the *other* road user's rules

17 lines qualify another party's conduct as lawful: pedestrians "lawfully within the
intersection or an adjacent crosswalk" (NRS-484B-307-2a, -3a, -4a, -5a, -7a, -9a, -9b), a person
"lawfully riding" (270-1), a pedestrian who "entered the highway lawfully pursuant to
subparagraph (1)" (283-1d3, -1d4), "lawfully parked" (473-2, LVMC-11-52-180-C), "lawfully placed
signage" (267-1b, 587-2a), "lawfully passing … lawful turning movement" (LVMC-11-18-030-B),
"lawful rate of speed" (777-1), "lawfully displays" (LVMC-11-52-270). Each is a reference to the
verdict of the pedestrian's, rider's or parker's own rules. The design handles it by
`Formula.rule` with a binder map; the pedestrian-subject lines are therefore *needed* even for
a driver-only evaluation, because seven signal rules depend on them. This bears on §4.

### 2c. Two shared exceptions that recur verbatim

- "except when necessary to avoid conflict with other traffic or in compliance with law or the
  directions of a police officer or official traffic-control device" — 17 parking lines
  (NRS-484B-450-*, LVMC-11-52-130-*).
- "except when otherwise directed by a law enforcement officer / police officer" — 12 lines
  (NRS-484B-267-*, -257-*, -300-1, LVMC-11-40-070).

**Recommendation.** Define both once in Core as derived concepts (`drv.forced_halt`:
stopped while a road user ahead within gap g blocks the lane or a device or officer requires a
halt; `drv.officer_directed`: `dev.human_direction` with role police governing the subject's
approach) and have the planner cite them rather than re-derive them 29 times. Both are
law-independent in contract and belong in `ATOMS.md` §9.

### 2d. Exceptions that point outside the corpus

NRS 408.437 (DOT vehicles), 486.261 (blue tail-lamp insert), 484A.469 (local scooter
ordinance; LVMC 11.40.185(A) is that ordinance and is *not* a line), 484B.130 (penalty),
484B.748/.757, 484D.190 (permits for amber lights). All are equipment or administrative; none
changes an observable. Record as residue on the rule.

---

## 3. Judgement standards

152 lines contain judgement vocabulary; 107 of those have no number anywhere in the text. After
hand classification (false positives removed: "safety zone", "hazardous materials", "appropriate
signs", "properly identified by pennants", "purpose of making a left turn" where the purpose is
evidenced by the turn itself), three tiers remain.

### Tier S — the obligation *is* the standard (38 lines; 30 bind a driver)

No observable trigger or threshold; the whole duty is a standard of care.

| id | standard |
|---|---|
| NRS-484B-113-1 | back only with reasonable safety, without interfering |
| NRS-484B-127-3 | caravan spacing sufficient for others to enter |
| NRS-484B-210-2 | pass on the right only in safety |
| NRS-484B-270-1, -7a | intentionally interfere |
| NRS-484B-270-5a, -280-1a | due care to avoid a collision |
| NRS-484B-270-5b, -280-1b, NRS-484D-400-2 | horn if appropriate and when necessary |
| NRS-484B-280-1c | proper caution on observing a pedestrian |
| NRS-484B-270-7b | rider overtakes only if safe |
| NRS-484B-293 | pedestrian keeps right when practicable |
| NRS-484B-310-2 | proceed past flashing yellow only with caution |
| NRS-484B-403-1, -410, -413-1 | U-turn / start / turn only when it can be made with safety |
| NRS-484B-600-1a, -1b | speed reasonable and proper; speed that endangers |
| NRS-484B-603-1 | decrease speed as may be necessary |
| NRS-484B-607-1b, -1c, NRS-484B-267-2b, -2c | proceed with caution; be prepared to stop |
| NRS-484B-623-1, -627-2 | impede the normal and reasonable movement of traffic |
| NRS-484B-653-1a, LVMC-11-22-020, LVMC-11-22-010 | reckless; careless or imprudent; full time and attention |
| NRS-484B-707-1 | follow as closely as is practicable and safe |
| NRS-484B-787-2c, -790-2c | unreasonably interfere |
| NRS-484D-185-1 | amber light only when an unusual traffic hazard exists |
| LVMC-11-12-080-A | follow no closer than reasonable and prudent |
| LVMC-11-12-090 | reasonable precaution near horses |
| LVMC-11-22-150-A | speed greater than is prudent when children are present |
| LVMC-11-40-130 | bicycle speed reasonable and prudent |
| LVMC-11-40-185-B | stunts, unsafe speeds, reckless behaviour (stunts and riding on handlebars are observable; the rest is not) |

### Tier Q — a concrete rule with a judgement qualifier, exception or threshold (≈100 lines)

The core is observable; one element needs a bound. The recurring elements and the bound they
need:

| element (jdg atom) | lines (examples) | what a reading has to supply |
|---|---|---|
| "so close as to constitute an immediate hazard" (`jdg.immediate_hazard`) | 253, 257-1, 257-2, 263, 553-1, 650-1, LVMC-11-12-070-A | a time-to-conflict or gap threshold τ at the conflict point |
| "safe distance", "safely clear" (`jdg.safe`) | 207-1, 270-2a/2b, 213-1, 217-2, 223-1b, 223-2, 768-1, 777-1, 486-351-4 | lateral clearance d (3 ft is stated for bicycles), longitudinal gap g or time gap after a pass |
| "clearly visible … for a sufficient distance", "view is obstructed", "clear and unobstructed view" (`jdg.clearly_visible`) | 213-1, 213-2a, 407 (500 ft stated), LVMC-11-16-030 (400 ft stated), -040 (100 ft stated) | sight distance ≥ a stated or speed-dependent value |
| "as close/near as practicable" (`jdg.practicable`) | 400-3/4/5, 120, 560-3, 267-1b, 777-1, LVMC-11-40-100 (dropped) | a lateral offset bound |
| "if possible / unless unsafe" | 267-2e, 607-1d | a lane-change feasibility test (adjacent lane free within gap) |
| "appropriate signal" | 223-1b, 413-3, 217-2, 768-1 | `sig.turn_indicator` for the distance 413-2 states (100/300 ft) or any indicator before the manoeuvre |
| "knows, or reasonably should know" (`jdg.knowledge`) | 208-1 | replaced by the observable it is about (speed below posted while being overtaken) |
| "so slow as to impede … traffic proceeding immediately behind" (`jdg.impede`) | 627-1a/1b/1c, 630-1 (five vehicles stated) | speed below posted by Δ with n vehicles queued behind for T |
| "except when necessary to avoid conflict with other traffic" (`jdg.necessary`) | 17 parking lines | `drv.forced_halt` (§2c) |
| "expeditious(ly) loading or unloading", "for the purpose of" | 450-1a, 510, 517, LVMC-11-44-*, -52-030-A, -52-180-A, -52-305-A, -60-030-B1, -60-040 | standing time ≤ T with a door open or passenger exchange; otherwise the purpose is a residue |
| "approaching so closely … as to be in danger", "impossible for the driver to yield" | 283-1a, 283-1b | a stopping-distance test from speed |
| "sufficient space on the other side" | LVMC-11-20-070 | length of the vehicle versus the free gap beyond the far boundary |
| "reasonably believes that an emergency requires" | 484D-285-1 | residue |

### Tier C — no judgement element (≈170 lines)

Formalizable as planned.

### Why the current plan is insufficient for S and thin for Q

`CORE_V2_LEAN_DESIGN.md` §6 makes every judgement atom a reading parameter the rule must name.
That works for Tier Q, where the parameter bounds a single element of an otherwise concrete
rule. It does not work for Tier S: the parameter would *be* the rule, so the rule's accuracy
would measure only the reading, and any disagreement with a label is unresolvable by the
triage in §8.7 (there is no atom check to run). The planner would also be asked to invent a
measurement for "due care", which is exactly the proxy substitution the review phase exists to
reject.

**Proposed plan change.**

1. Tag every line with `tier: C | Q | S` in `laws.jsonl` (a corpus-curation field, like
   `subject`; the tagging above is the first draft and should be checked by a second reader).
2. **Tier S lines leave the formalization corpus.** Move them to `laws/example/standards.jsonl`.
   They are not in the coverage denominator and no rule is written for them in the first run.
   They stay in the repository because (a) several Tier Q rules point at them (267-2a and 607-1a
   cite 600(1)(a)'s criteria), and (b) a later phase can attach *surrogate* rules with named
   engineering readings where an accepted one exists — time headway for following distance
   (127-1/LVMC 11.12.080(A)), speed-below-posted-with-queue for impeding (623-1, 627-2), a
   deceleration profile for "decrease speed" (603-1). Surrogates are marked `kind: surrogate`,
   evaluated separately, and never counted as the law's own verdict.
3. **Tier Q rules keep the reading-parameter mechanism, with two additions.** (i) The reading
   file names, per parameter, the engineering convention it comes from (gap acceptance, passing
   sight distance, two-second headway), so a bound is a citation and not a guess. (ii) The
   evaluation reports Tier Q accuracy with a sensitivity sweep over each parameter's declared
   range; a rule whose verdict flips inside the range on a labelled trace is reported as
   *reading-sensitive*, which is a property of the law, not a defect of the rule.
4. **The two shared exceptions of §2c become Core derived concepts**, so the 29 lines that carry
   them do not each invent a measurement.
5. **Review prompt gets a fifth question** for Tier Q: "does the parameter bound the judgement
   element, or has it replaced an observable the statute states?" (e.g. replacing the 3-foot
   bicycle clearance with a generic "safe distance" parameter is a regression the reviewer must
   catch).

---

## 4. Lines that do not judge a driving situation

The evaluation target is an ego vehicle's driving as seen in a traffic scene. Against that
target the corpus divides as follows (driver-subject lines: 227).

| group | lines | examples | judgement |
|---|---|---|---|
| **Core driving conduct** (driver, moving, tier C or Q) | **145** | signals, turns, right-of-way, speed, lanes, overtaking, emergency and incident, school, railroad | the first-run set |
| Driver Tier S standards | 30 | due care, reasonable speed, careless driving | leave the corpus (§3) |
| Stopping, standing, parking (driver) | 48 | hydrant, crosswalk, double parking, curb colours, loading zones | keep in the repository; **not driving** — a stationary ego is judged by them only if the traces contain stops. Valuable as formalization benchmark (concrete distances) rather than as driving evaluation. Tag `scope: parking`; out of the first-run denominator |
| Equipment legality while driving | 7 | NRS-484A-480-5/-6/-7 (lamp colours), NRS-484D-545-1 (emblem), NRS-484D-515-1 (chains), NRS-484D-185-1 (amber light misuse), NRS-484B-783-1 (bicycle lamps) | **recommend excluding**: they judge what a vehicle is fitted with, not how it is driven; they were kept because they are "use" rules, but the use is trivial once the fitting is known |
| Lamp *use* while driving | 8 | NRS-484D-100-1, -220-1, -215-1/-2 (dimming), -205-4 (backup lamps), -165-3/-4, NRS-484B-473-2, NRS-484B-707-2 | keep: observable driver conduct that matters in night scenes |
| Non-driver subjects | 95 | pedestrian (20), rider (29), motorcyclist (10), device operators (7), bus/taxi/tour-bus (7), others | keep; out of the first-run denominator, **except** that the pedestrian lines are needed by the seven signal rules through "lawfully within" (§2b) |

### 4a. Rider and passenger apparel and posture — evaluate whether they belong at all

| id | what it judges | observable in a driving scene? | recommendation |
|---|---|---|---|
| NRS-486-231-2 | helmet and eye protection on motorcycle riders and passengers | only by person-attribute perception; no scene-graph source has it | **exclude**. It judges a person's equipment, not the movement of any road user; it has no bearing on the ego's conduct or on the traffic scene the ego must respond to |
| LVMC-11-38-130 | protective footwear | no | **exclude**, same reason |
| LVMC-11-40-185-C | helmets on minors riding e-bikes and e-scooters | requires age estimation | **exclude** |
| NRS-486-191-1, NRS-484B-770-1 | ride only on the permanent seat | pose | keep only as `rider`/`motorcyclist` conduct, out of the first run |
| NRS-486-181-1, NRS-484B-770-2 | passengers beyond design | occupant count | same |
| NRS-486-211, NRS-484B-780 | one hand on the handlebar; articles preventing it | pose | same |
| LVMC-11-40-150, LVMC-11-38-040 | attaching to or holding a moving vehicle | yes (relation to another vehicle) | keep: this one *is* a traffic interaction |
| LVMC-11-40-185-B | stunts, wheelies, riding on handlebars | partly | keep as rider conduct, tier S/Q mixed |

Recommendation: create `laws/example/excluded.jsonl` with the three apparel lines and the seven
equipment-legality lines, each with a one-line reason, so the exclusion is recorded and
reversible. That leaves 312 lines, of which 145 form the first-run driver set.

### 4b. Other lines whose value for driving evaluation is doubtful (kept, flagged)

- **Permissions rather than obligations**: NRS-484B-700-1 (emergency-vehicle privileges),
  NRS-484B-307-2a first sentence ("may proceed"), NRS-484B-403-1 ("may be made … with safety"),
  LVMC-11-40-185 (A, not a line). 700-1 should be reclassified as an *applicability* record: it
  switches other rules off for a responding emergency vehicle. Not a rule to monitor.
- **Weight- and length-class rules**: LVMC-11-48-030/-050/-060 (8,000 lb unladen), LVMC-11-16-110,
  LVMC-11-52-305-A (24 ft / 8,000 lb). The class is not observable; the rules are truck-route
  administration. Candidates for exclusion in a driving evaluation; keep as `truck_driver`
  subject, out of the first run.
- **Region-only rules**: LVMC-11-68-030 (Pedestrian Mall), LVMC-11-41-020 (golf carts on
  scheduled streets), LVMC-11-16-050 (park grounds), NRS-484B-637-2b (low-speed vehicle on
  roads posted above 35 mph). The obligation is "not here"; the region is a reading assumption.
  Formalizable but low value; keep, flag.
- **Purpose-of-stop rules**: the loading-zone and bus/taxi stand lines (§3 Tier Q, "expeditious
  loading"). Keep as parking.
- **Processions**: NRS-484B-703-1, -707-1, -707-2. Rare in any dataset; keep, flag.
- **Fire hose** NRS-484B-913, **flooding** (not included), **compression brakes** NRS-484D-285-1
  (audible only): keep, flag as source-dependent.

### 4c. What the first run should contain

`subject == driver` ∧ `scope == driving` ∧ `tier ∈ {C, Q}` ∧ not excluded ⇒ **145 lines**, plus
the pedestrian lines that the signal rules compose (NRS-484B-283-1d1…1d4, 287-1a/1b via LVMC
survivors, 307-*b) as *supporting* rules that are formalized but not counted.

---

## 5. Summary of proposed corpus changes (not applied)

| change | lines affected | mechanism |
|---|---|---|
| ~~append missing exception/definition subsections (§1b)~~ | 11 | **done** 2026-09-19 (`references.py` APP_MORE / XAPP) |
| ~~add `refs` field resolving references to ids, following `supersedes` (§1a, §2a)~~ | 75 | **done** 2026-09-19 (`references.py` REFS) |
| ~~add `definitions.jsonl` (§1c)~~ | 123 definitions | **done** 2026-09-19; all term definitions of the definition chapters plus 8 cited provisions; rendered after the laws by `format_definitions` in `scripts/phases/plan.py` |
| ~~add `tier` field C/Q/S (§3)~~ | all | **done** 2026-09-19 (`tiers.py`) |
| ~~move Tier S to `standards.jsonl` (§3)~~ | 37 | **superseded** 2026-09-20: tier S stays in the pipeline corpus; the planner operationalizes it and the rule is marked surrogate (`ATOMS.md` §8) |
| ~~add `drv.forced_halt`, `drv.officer_directed` to `ATOMS.md` §9 (§2c)~~ | 29 | **done** 2026-09-20 |
| add `scope` field driving/parking/equipment (§4) | all | open; `theme` = stopping_standing_parking serves for parking |
| ~~move apparel and equipment-legality lines to `excluded.jsonl` (§4a)~~ | 11 | **done** 2026-09-19/20; `laws.jsonl` no longer contains them |
| ~~reclassify NRS-484B-700-1 as an applicability record (§4b)~~ | 1 | **done**: in `excluded.jsonl` with that reason |
| ~~retrieve LVMC 6.47.100(C) (§1c)~~ | — | **done** 2026-09-19 |
| mark unresolved references on the line (§1e) | 39 marks | **done** 2026-09-19 (`references.py` UNRESOLVED); on 2026-09-20 every marked line was moved to `unresolvable.jsonl` (31 lines; 4 more are in `excluded.jsonl`) |
