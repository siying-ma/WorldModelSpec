# Niche vocabulary survey — which atoms describe long-tail situations, and what dropping them does to the law

Date: 2026-10-02. Scope: the 272 lines of `pipeline/traffic-spec-agent/laws/full_list/laws.jsonl`
and the atom tables (§1–§7) of `pipeline/traffic-spec-agent/ontology/ATOMS.md`. This survey
recommends; it changes nothing. `ATOMS.md` is frozen, and the corpus is posted law that is never
edited.

## 1. Question and method

The question has two parts:

1. Which situations named by the vocabulary are rare in real Las Vegas driving? This is answered
   only from external documents: government statistics and inventories, dataset papers and
   official dataset documentation, peer-reviewed or agency research. No document written for
   this project counts as evidence.
2. For each rare item, what role does it play in the lines that use it? Is it the reason the
   line exists, or an exception or branch of an everyday duty? And does removing it change what
   the line requires?

**How the evidence was gathered.** Every figure in §2 was read from a page, PDF or official
data API fetched on 2026-10-02. Each figure carries its source id (§9), which gives the URL,
publisher, title and year. Some ratios are derived; those show their inputs.

**What was re-checked against the live source.** Five figures were fetched a second time:
- FHWA VM-1 2024 VMT by class [S1];
- the FRA count of 62 public at-grade crossings in Clark County [S17];
- the NOAA count of 25.8 precipitation days [S27];
- the Argoverse 2 class order [S37];
- the Waymo WOD-E2E 0.03% long-tail rate [S38].

**Which sources are weaker.** News reports [S11, S44, S47, S48] are used only where no agency
document could be reached. dot.nv.gov, rtcsnv.com and files.clarkcountynv.gov refused automated
fetching, so some Nevada-specific figures are missing (§8).

**How roles were assigned.** Every line was read in full. Each (line, item) pair got exactly one
role:

| role | meaning | what removing the item does |
|---|---|---|
| **KEY** | the line exists because of the item (its subject class, trigger, or the object of the duty) | the line has no content left |
| **EXCEPTION** | a carve-out from a general duty ("shall not apply to", "except", "unless", "other than") | the core duty is unchanged; the rule over-applies only in the excepted situation |
| **ALTERNATIVE** | one item of a list of alternative triggers, places or objects | one branch is lost; the other branches keep their meaning |
| **QUALIFIER** | narrows when or how a general duty applies, without being a separate exception | depends on the line (see §5) |
| **REFERENCE** | appears only in a cross-reference, an appended definition or an equipment specification | nothing the rule reads |

Every quote below was checked by script to be a verbatim substring of the line.

## 2. External evidence: how often each situation occurs

### 2.1 Road users and vehicle classes

| item | evidence | tier for Las Vegas |
|---|---|---|
| passenger cars and light trucks | 88.8% of US VMT in 2024 (2,924,108 of 3,294,031 million) [S1]; 96–97% of Nevada urban arterial and local VMT [S2] | everyday |
| heavy trucks | 10.0% of US VMT [S1]; Nevada urban: 24.2% of Interstate VMT, 3.5% of other arterial, 2.3% of local [S2] | everyday (freeways) |
| motorcycles | 0.68% of US VMT [S1]; 0.34–1.53% of Nevada urban VMT [S2]; 3.7% of Nevada registrations [S3] | everyday, low share |
| buses (transit, school) | 0.55% of US VMT [S1]; RTC bus 52.2 M trips and 18.2 M revenue miles in 2024 [S14]; CCSD runs 1,922 buses, 31,437 bus stops, 140,000+ miles per school day [S4] | everyday on school days and transit corridors |
| taxicabs | 12,859,604 trips in 2025, 3,530 medallions [S15] | everyday (Strip and airport) |
| pedestrians | 6.9% of US person trips are walking [S16]; present in every nuPlan Las Vegas crosswalk tag family [S33, S35] | everyday |
| bicycles, e-scooters | bike 0.7% of commute trips; 10.5% of people 16+ rode a bike and 1.9% an e-scooter in the past 30 days [S16]; Clark County banned e-bikes and e-scooters from resort-corridor sidewalks in 2025 [S44] | occasional |
| emergency vehicles responding | 63,635,893 US EMS activations in 2025 [S5], i.e. about 19 per million VMT (derived from [S5], [S1]); "ambulance is the least frequent" nuScenes category [S36]; Waymo groups emergency vehicles that require a pull-over into its long-tail clusters, which as a whole occur at "less than 0.03%" of daily driving [S38] | long tail |
| police officer or flagger directing traffic | AV2 OFFICIAL_SIGNALER ranks 28 of 30 classes by frequency [S37]; Waymo's long-tail Construction cluster includes "Uniformed pedestrians directing traffic" [S38] | long tail |
| school bus as a road user | AV2 SCHOOL_BUS ranks 20 of 30 [S37]; 213,800 illegal passes of stopped school buses per day nationally [S41] | occasional (school days) |
| tow trucks and roadside incidents | 13 M AAA tows in 2024 [S9], about 3.9 per million VMT (derived) | long tail as an encounter |
| armored cars, coroner vehicles, incident-management vehicles | Brink's reports 3,838 vehicles of all types in North America [S49]; no count found for the rest | long tail; no data |
| funeral processions | 3,072,666 US deaths in 2024 [S7]; projected 2025 burial rate 31.6% [S8], which bounds burials at about 0.97 M a year (derived); no source gives the share of funerals with a road procession; no dataset, crash typology or scenario taxonomy has a procession category [S33, S35, S36, S37, S38, S39, S40] | long tail; no direct data |
| golf carts, low-speed vehicles | Nevada allows golf carts only in permitted residential developments of large counties [S10]; no registration count | long tail |
| personal delivery devices | confined to streets around UNLV; 3,300 deliveries in two years [S11] | long tail |
| blind pedestrians (white cane, guide animal) | 2.2% of US adults aged 18–64 and 6.1% of those 65+ report vision difficulty [S12]; no white-cane or street-crossing exposure measure; 18,978 working guide dogs worldwide [S50] | long tail as an encounter |
| wheelchairs, strollers | AV2 ranks 26 and 22 of 30 [S37]; dropped from the nuScenes benchmark for fewer than 10,000 annotations [S36] | long tail |
| animals, animal-drawn vehicles | AV2 ANIMAL ranks 30 of 30 [S37]; animal crashes are 5.2% of US police-reported crashes in 2022 [S39], a national and largely rural figure; no Las Vegas figure; no data on animal-drawn vehicles | long tail in Las Vegas |
| rail vehicles on streets | the Las Vegas Monorail is elevated [S13]; FTA NTD lists only bus and demand-response modes for the Las Vegas urbanized area [S14] | none at grade except freight (§2.2) |
| ice-cream / vending trucks | no data found | long tail; no data |

### 2.2 Road features, devices and conditions

| item | evidence | tier for Las Vegas |
|---|---|---|
| signalized intersections | 1,700+ traffic signals in the RTC FAST system [S25]; about 10 traffic-light scenario tags in nuPlan [S35]; 2,621,590 of 10,528,849 vehicles in 2022 US crashes were at a traffic signal [S39] | everyday |
| stop signs | about 8 stop-sign scenario tags in nuPlan [S35]; STOP_SIGN ranks 6 of 30 in AV2 [S37] | everyday |
| pick-up / drop-off curbs | "In Las Vegas, most routes start and end in PUDOs" [S33] | everyday (for ride-hail driving) |
| freeways (controlled access), overpasses | 1,145 bridges in Clark County [S22], mostly freeway structures; 76 ramp meters and 169 message-sign / active-traffic-management gantries [S25] | everyday |
| school zones | 368 CCSD schools, 499 campuses county-wide [S29, S31]; 180 school days [S30]; 15 mph zones with beacons on arterials and collectors, flashing 30 minutes around bell times [S31] | occasional (time-bound) |
| work zones | 20% of the National Highway System is under construction in summer, 7% in winter [S26b]; 2.1% of US fatal crashes [S43]; 1,179 Nevada work-zone crashes from July 2017 to July 2018 [S47] | occasional |
| rain, wet road | 25.8 days a year with ≥0.01 in of precipitation and 11.0 with ≥0.10 in [S27], i.e. about 7% of days | occasional |
| roundabouts | 131 existing in Nevada; 26 matched to Las Vegas and 20 to Henderson [S20], against 1,700+ signals (about 1 per 37); about 0.4% of US intersections (11,900 roundabouts [S20] ÷ 3 M intersections [S21], inputs from different years) | occasional, clustered in master-planned areas |
| flashing yellow arrows | Clark County switches them off 6–9 a.m. and 4–7 p.m. on weekdays [S48, news]; no official count reached | everyday off-peak; count missing |
| HOV lanes | weekday peaks only: 6–8 a.m. and 4–6 p.m. on I-15, US-95 and SR-613 since 2023 [S48b, news] | occasional (time-bound) |
| highway-rail grade crossings | 62 public at-grade crossings in Clark County, 2 of them in the City of Las Vegas [S17]; only 2 valley crossings are on the mainline (7 day and 7 night through trains); most others see 0–2 trains a day or switching only [S17]; 13 collisions in Clark County 2015–2025 [S18]; 1,291 of 5,930,496 US crashes in 2022 [S39] | long tail |
| fog, low visibility | 0.7 days a year with visibility ≤ ¼ mile; 3.7 days ≤ ⅝ mile (1971–2000) [S28] | long tail |
| snow, ice | 0.2 in of snowfall a year; 0.2 days with ≥ 0.1 in [S27]; "Measurable snow … typically occurs once every four or five years" [S24] | long tail |
| tunnels | 6 in all of Nevada [S23]; none confirmed in the valley | long tail |
| mountain roads, crests, sharp curves | the valley "slop[es] gradually upwards on each side towards the surrounding mountains" [S24]; no grade or curve statistic | long tail inside the urban area (qualitative only) |
| fire hydrants | 44,000+ in the Las Vegas Valley Water District service area [S32] | everyday (as a parking constraint) |
| pedestrian bridges | 4 bridges at Las Vegas Blvd and Flamingo Road alone [S51]; no total reached | long tail, Strip only |
| alleys, painted safety zones, two-way centre turn lanes | no inventory found | no data |

### 2.3 What scenario datasets say about the long tail as a whole

- **Waymo, 6.39 M miles.** Waymo mined 6,391,012 miles of its own driving. Its criteria found
  "only 6,888 miles (0.1%)" of long-tail scenarios, and manual review reduced that to 0.03%
  [S38]. The long-tail clusters include construction rerouting, uniformed persons directing
  traffic, emergency vehicles, animals and debris.
- **nuPlan, Las Vegas.** nuPlan collected 1282 h of driving in four cities, Las Vegas among
  them [S33]. It excluded "heavy rain and night data" [S33]. None of its 73 scenario types
  covers emergency vehicles, school zones or school buses, rail crossings, police or flaggers,
  processions or animals [S35].
- **Crash typology.** The NHTSA pre-crash typology (5.9 M crashes) is dominated by everyday
  manoeuvres [S40]:
  - lead vehicle stopped, 16.41%;
  - turning at non-signalized junctions, 7.32%;
  - lead vehicle decelerating, 7.20%;
  - changing lanes, 5.69%;
  - running a red light, 4.27%.

  Animal crashes are 5.13%, while running a stop sign (0.81%) and pedestrian crashes (0.66% +
  0.29%) are rare as crashes. The report leaves emergency vehicles out entirely.
- **Curation bias.** These datasets are curated: nuScenes hand-picked scenes with rare
  classes, AV2 mined for interesting scenes, and nuPlan's tags are high-precision and
  low-recall. Their class orderings are therefore relative rarity, not real-world rates. The
  only real-world rate for long-tail situations as a group is Waymo's 0.03%.

## 3. Lines that are niche as a whole (KEY)

Each of these lines exists because of a rare item. Leaving them out of a first pass loses no
everyday duty. The groups below are ordered by the evidence tier in §2. "(test)" marks a
test-split line.

| item (tier) | lines |
|---|---|
| funeral procession (long tail, no data) | NRS-484B-703-1, NRS-484B-707-1, NRS-484B-707-2; caravan or motorcade: NRS-484B-127-3 |
| emergency vehicle, fire apparatus (long tail) | NRS-484B-267-1a/1b/1c, NRS-484B-267-2a–2f, NRS-484B-710, NRS-484D-400-5, NRS-484B-913 (fire hose) |
| police officer or flagger directing (long tail) | NRS-484B-100, NRS-484B-330-1 (flagger in a temporary traffic control zone) |
| rail crossing (long tail) | NRS-484B-553-1, -553-2, -557, -560-3, -560-6, -560-7a, -560-7b, NRS-484B-450-1i, LVMC-11-16-030, LVMC-11-30-080 |
| rare geometry (long tail in the valley) | NRS-484B-120 (defiles, canyons, mountain highways), NRS-484B-213-2a (crest, curve), NRS-484B-213-2c (bridge, viaduct, tunnel), NRS-484B-407 (U-turn on a curve or crest), NRS-484B-450-1m (test), NRS-484B-633-2 (test), NRS-484B-533 (test) |
| roundabout (occasional, clustered) | NRS-484B-220-2, LVMC-11-43-010-A, -B, -C1, -C2 (all test) |
| school bus (occasional) | NRS-484B-353-1, NRS-484B-360-1 (test; its subject is the school bus) |
| ice-cream truck, low-speed vehicle, small devices (long tail) | LVMC-11-22-150-A/B, NRS-484B-637-2b, NRS-484B-787-2a/b/c, NRS-484B-790-2a/b/c, LVMC-11-22-130-A/B/C (all test); NRS-484B-785-1a (e-scooter, train); NRS-486-351-4 (moped) |
| blind pedestrian (long tail) | LVMC-11-30-140-B |
| horse (long tail) | LVMC-11-12-090 |
| trucks by size or weight (everyday on freeways, rare as a subject of these lines) | NRS-484B-127-2, LVMC-11-48-050, LVMC-11-48-060, LVMC-11-52-305-A, LVMC-11-52-300 |
| lane-control signals (count missing) | NRS-484B-307-12a/12b, LVMC-11-42-030 (test) |
| darkness (everyday, so not niche) | NRS-484D-100-1, NRS-484D-215-1/2, NRS-484D-165-3, NRS-484B-473-2, LVMC-11-38-120-B |

The last row is listed only because darkness is KEY in those lines. Night is a daily condition,
and those lines are everyday. Driving at night is everyday, but nuPlan's released data excludes
it [S33], so a nuPlan-based evaluation cannot exercise those lines.

Also KEY but everyday by §2 (do not defer):
- controlled-access highway: NRS-484B-208-1, -263, -587-1, -587-2a/2b, -627-1c;
- two-way centre turn lane: NRS-484B-223-3a/3b/3c, LVMC-11-12-100-C;
- school zones: NRS-484B-363-1..4, LVMC-11-18-020, LVMC-11-46-030;
- flashing yellow arrow: NRS-484B-307-7a;
- curb and pick-up items: NRS-484B-517 (bus stop / taxicab stand), NRS-484B-503, -507-1,
  -510 (loading zones), LVMC-11-52-030-A/B (red and yellow curbs), LVMC-11-52-130-A4
  (hydrant), NRS-484B-153-2/3 (doors, test).

**Structural consequence.** 27 of the 28 test lines are KEY for a rare item; the exception is
NRS-484D-205-4. This is by design: the split chose test lines that introduce atoms no training
line uses. Excluding long-tail items wholesale would therefore empty the test set. The two
decisions must be taken together.

## 4. Lines whose core is everyday and whose rare item is an exception or a branch

In these lines the rare item can be set aside and the everyday duty formalized. The funeral
procession exception in LVMC 11.12.080 is the type case.

| line | rare item set aside (role) | everyday core duty |
|---|---|---|
| LVMC-11-12-080-A | "The provisions of this Section shall not apply to funeral processions." (EXCEPTION) | do not follow another vehicle more closely than is reasonable and prudent |
| NRS-484B-213-2b | "or railroad grade crossing" (ALTERNATIVE) | do not drive on the left side within 100 ft of, or through, an intersection |
| NRS-484B-210-1 | emergency, tow, coroner, incident-management and transit-bus vehicles on a signed shoulder (EXCEPTION) | pass on the right only under (a)–(d); on unmarked pavement, at most 200 ft and through no intersection |
| NRS-484B-587-2a/2b | the same vehicle list on signed shoulders; "required by an emergency" (EXCEPTION) | on a controlled-access highway, stay within the marked lanes and do not cross the solid entrance/exit line |
| NRS-484B-117-1 | three-wheeled electric vehicles used by emergency, police or security services (EXCEPTION) | do not drive on a sidewalk except at a driveway or alley entrance |
| NRS-484B-270-3 | official duties, police direction (EXCEPTION) | yield to riders in a bicycle lane; do not enter or stop in it except at an alley or driveway, when disabled, or to avoid conflict |
| NRS-484B-450-1a/c/e/g/l/o, LVMC-11-52-130-A11/A12 | "or the directions of a police officer" (EXCEPTION, one half of a bundled clause; see §5.2) | the no-stopping places: sidewalk, intersection, crosswalk, near a side signal, double parking, where a device prohibits, near an intersection or crosswalk |
| LVMC-11-52-130-A7 | United States Postal Service vehicle (EXCEPTION) | no parking within 5 ft of a driveway |
| LVMC-11-52-030-A | tour bus, limousine, RTC bus, armored car, emergency vehicle, mail drop box (EXCEPTION) | no stopping, standing or parking at a red curb |
| LVMC-11-22-100 | "horse"; paving employees (ALTERNATIVE, EXCEPTION) | do not drive over barricaded new pavement or a street signed closed |
| NRS-484B-603-1 | curve, hill crest, narrow or winding road (ALTERNATIVE) | reduce speed approaching an intersection and for pedestrian or traffic hazards |
| NRS-484B-257-1/2 | "controlled by a police officer" (EXCEPTION, the police half only) | stop or yield at a stop or yield sign, then yield to through traffic |
| NRS-484B-300-1, LVMC-11-40-070 | "unless … otherwise directed by a police officer" (EXCEPTION) | obey official traffic-control devices |
| NRS-484B-413-1 | "by sounding the horn if any pedestrian may be affected" (ALTERNATIVE) | turn only when safe and after an appropriate signal |
| NRS-484B-207-2 | "or hearing a signal" (ALTERNATIVE) | an overtaken driver gives way to the right and does not speed up |
| NRS-484B-280-1c | "bus stop or bench, shelter or transit stop", "school zone" (ALTERNATIVE) | proper caution on seeing a pedestrian on or near the road; the first branch already covers the others |
| NRS-486-341, -351-1, -351-2 | moped, trimobile; the police exemption (ALTERNATIVE, EXCEPTION) | the motorcycle lane duties |
| LVMC-11-20-060, LVMC-11-40-140 | "an alley … or building" (ALTERNATIVE) | when emerging from a driveway, stop before the sidewalk and yield |
| NRS-484B-777-1 | "animals" in the list of impediments (ALTERNATIVE) | a cyclist rides near the right edge, with the stated exceptions |
| NRS-484D-100-1, LVMC-11-38-120-B | "unfavorable atmospheric conditions" (ALTERNATIVE) | headlamps on from half an hour after sunset to half an hour before sunrise |
| NRS-484B-283-1d3/1d4 | "safety zone if one is provided" (ALTERNATIVE) | a pedestrian who started lawfully finishes crossing to a curb or sidewalk |

## 5. Does setting the rare item aside change the law's semantics?

### 5.1 Exceptions

What the rule *requires* is unchanged: the core duty means what it meant. What changes is
*where it applies*. A rule without the exception applies in the excepted situation too, so it
would call a funeral procession's close following a violation where the law calls it lawful.

For a long-tail exception, that over-application happens at most as often as the excepted
situation itself, which is the frequency evidenced in §2 (for processions, no data beyond an
upper bound on burials).

Two consequences follow:
- The rule is not reformulated, and the posted text cannot be edited.
- Within the pipeline's own rules, the exception span cannot simply be dropped. Its validator
  rejects a residue or a narrowing on an exception span
  (`pipeline/traffic-spec-agent/harness/checks/validate_a.py:317-329, 347`). Such a span must be
  an atom, a trace assumption (`asm.<name>`), or a gap.

**A way to set an exception aside without losing its meaning.** Carry the exception as the
pipeline already requires: a class atom such as `ru.procession_vehicle`, or a trace assumption
such as `asm.funeral_procession`. Then let the data source declare it:
- In a scripted simulation the operator knows no procession is present, so every scene
  declares it false and the rule decides normally.
- On recorded data with no such declaration, the rule is `unknown` wherever the exception could
  matter (`pipeline/traffic-spec-agent/library/TrafficSpec/Core/Language/Rule.lean:79-87`). It
  never wrongly reports a violation.

This keeps the law's semantics exact. It moves "processions are rare" out of the rule and into
the data source's declaration, where a reviewer can see it and a source that does observe
processions can say so. Deleting the span instead would make the rare-case error invisible.

### 5.2 Exceptions that look rare but are not

These must not be set aside, because they hold in everyday driving:

- **NRS-484B-208-1 (e):** "To a driver operating a motor vehicle within the geographical limits
  of a city or town." Most Las Vegas driving is inside city limits, so this exception switches
  the left-lane rule off in the common case.
- **NRS-484B-450-1\*, LVMC-11-52-130-\*:** the police clause sits inside "except when necessary
  to avoid conflict with other traffic or in compliance with law or the directions of a police
  officer or official traffic-control device". The conflict-avoidance and device halves fire in
  ordinary queues: a car stopped on a crosswalk or inside an intersection while waiting. Only
  the police half is rare.
- **NRS-484B-257-1/2:** "Except when traffic is being controlled by a police officer or a
  traffic-control signal". The signal half is everyday; it hands the case to the signal rules.
- **NRS-484B-363-1..4:** the speed-limit beacon is branch (c), the in-effect test of every
  beacon-equipped school zone. Clark County uses beacons on arterials and collectors [S31].
- **Electric bicycles and electric scooters:** they are paired with bicycles in 18 lines.
  Setting them aside is safe only if the reading's "bicycle" class set does not need them;
  otherwise the rules under-apply to devices residents do use [S16, S44].

### 5.3 Branches (ALTERNATIVE)

Removing a branch narrows the rule. The remaining branches are formalized exactly, and the
lost branch is a recorded residue of coverage, not an error in the rule. NRS-484B-213-2b
without "railroad grade crossing" still states the intersection duty exactly.

### 5.4 Qualifiers

Weather terms inside a standard are QUALIFIERS, e.g. NRS-484B-600-1a, "having due regard for
… the weather". Rain is occasional in Las Vegas (about 7% of days [S27]), not rare, so the
qualifier stays. Fog and ice are long tail [S27, S28]; a standard can name them without
changing anything on the 93% of days that are dry.

## 6. The vocabulary, item by item

Columns:
- **lines:** corpus lines whose evaluation record (`laws/evaluation_scenario/scenarios.jsonl`)
  requires the atom.
- **roles:** what the text shows.
- **suggested status:** a recommendation only; the frozen ontology is not changed by this
  survey.

| atom | lines | roles in the text | evidence tier | suggested status |
|---|---|---|---|---|
| `ru.procession_vehicle` | 4 | KEY 4, EXCEPTION 1 | long tail, no data | defer the KEY lines; default-false in exceptions |
| `ru.official_vehicle` | 10 | ALTERNATIVE 9 (alongside emergency), EXCEPTION 8, KEY 1 | long tail | default-false in exceptions |
| `ru.emergency_vehicle`, `ru.fire_apparatus` | 10, 2 | KEY 12, EXCEPTION 9 | long tail | defer the KEY lines; default-false in exceptions |
| `ru.school_bus`, `dev.school_bus_signal` | 2, 1 | KEY 2 (test) | occasional | keep for the test set |
| `ru.transit_bus`, `ru.tour_bus_or_limousine`, `ru.taxicab` | 5, 3, 4 | KEY 7 (subject is the bus or taxi operator), EXCEPTION 4, ALTERNATIVE 2 | everyday road users; rare as a subject for a car | out of scope for a car ego; default-false in exceptions |
| `ru.vending_vehicle`, `sig.signal_arm` | 2, 2 | KEY 2 (test) | no data | defer |
| `ru.low_speed_vehicle` | 1 | KEY 1 (test) | long tail | defer |
| `ru.electric_bicycle`, `ru.electric_scooter` | 21, 22 | ALTERNATIVE 24, KEY 11, REFERENCE 3, EXCEPTION 2 | occasional | keep (paired with bicycles; §5.2) |
| `ru.moped`, `ru.other_conveyance`, `ru.personal_delivery_device`, `ru.mobile_carrying_device` | 7, 4, 3, 3 | KEY (mostly test), ALTERNATIVE | long tail | defer |
| `ru.pedestrian_with_white_cane_or_guide_animal` | 1 | KEY 1, REFERENCE 9 | long tail | defer |
| `ru.animal_or_animal_drawn` | 5 | KEY 1, ALTERNATIVE 6 | long tail in Las Vegas | defer the KEY line; drop the branches |
| `ru.rail_vehicle`, `st.railway_crossing`, `dev.railway_signal_or_gate` | 4, 11, 5 | KEY 10, ALTERNATIVE 1 | long tail | defer |
| `ru.trailer_or_combination`, `ru.commercial_motor_vehicle`, `ru.truck` | 5, 5, 3 | KEY 5, ALTERNATIVE 2, QUALIFIER 1 | everyday road users | keep the classes; the KEY lines judge the truck as subject |
| `st.elevated_structure`, `st.curvature`, `st.grade` | 4, 6, 6 | KEY 7, ALTERNATIVE 2 | long tail in the valley | defer |
| `st.sight_distance` | 13 | KEY or condition in everyday lines (the third stopping place of NRS-484A-450-2) | everyday | keep |
| `st.roundabout` | 5 | KEY 5 (test) | occasional | keep for the test set |
| `st.controlled_access` | 6 | KEY 6 | everyday | keep |
| `st.reserved_lane` (HOV) | 1 | EXCEPTION 1 | occasional (peak hours) | keep |
| `st.centre_turn_lane` | 4 | KEY 4 | no count, but on arterials | keep |
| `st.safety_zone`, `st.pedestrian_grade_separation`, `st.turnout`, `st.fire_station_entrance` | 5, 1, 2, 2 | KEY | long tail or no data | defer |
| `st.fire_hydrant`, `st.curb_zone`, `st.parking_space`, `st.transit_stop`, `st.alley` | 1, 16, 7, 3, 6 | KEY (parking and loading lines) | everyday for pick-up and drop-off | keep |
| `st.obstruction` | 16 | KEY and ALTERNATIVE | occasional (work zones) | keep |
| `dev.lane_control_signal` | 4 | KEY 3 | freeway gantries; no count | keep, low priority |
| `dev.speed_limit_beacon` | 4 | QUALIFIER in school-zone lines | occasional | keep (§5.2) |
| `dev.crossing_warning_signal` | 1 | KEY 1 | no data | defer |
| `dev.zone_sign` | 11 | KEY (school, work zone, no-passing) | occasional | keep |
| `dev.human_direction` | 28 | EXCEPTION 39 (pairs across 43 lines), KEY 2, ALTERNATIVE 3 | long tail | default-false in exceptions; defer the KEY lines |
| `dev.temporary_traffic_control` | 6 | KEY | occasional | keep |
| `sig.siren`, `sig.horn` | 2, 5 | KEY 1, ALTERNATIVE 4, QUALIFIER | no audio on either planned source | as already decided in the observability audit |
| `sig.compression_brake` | 0 | no corpus line | — | nothing reads it |
| `sig.warning_lamp` | 7 | QUALIFIER of the emergency lines | long tail | follows the emergency lines |
| `sig.hand_signal`, `sig.door_open` | 7, 13 | KEY 1 and 2, REFERENCE | occasional | keep |
| `env.ice_or_snow`, `env.visibility` | 2, 8 | QUALIFIER (inferred, no corpus word "ice" or "fog") | long tail | keep as qualifiers |
| `env.precipitation`, `env.wet_road` | 8, 5 | QUALIFIER, EXCEPTION | occasional | keep |
| `env.darkness` | 3 | KEY | everyday | keep |

**Scope labels that do not match frequency.** `st.centre_turn_lane` and the flashing yellow
arrow state are scoped `local` in `ATOMS.md`. That label means specific to the jurisdiction, not
rare. Both appear on everyday Las Vegas arterials.

## 7. Text oddities met on the way

- **LVMC-11-30-140-B** reads "or being assisted by a person with wisdom". This wording is in
  the Municode text as scraped (`nrs_tools/sources/lvmc.json`, section 11.30.140), so it is the
  posted text, not a transcription error. Whether the enacted ordinance says the same should be
  checked against the City's official copy.
- **Vocabulary with no corpus line at all:** `sig.compression_brake`, a school-bus stop arm, golf
  carts, wreckers or tow trucks by those names, utility vehicles, "carpool", "freeway",
  streetcars, fog, smoke, dust, ice, handicapped or charging spaces, "pedestrian safety zone".
- **`scenarios.jsonl` departs from the text in a few places:**
  - NRS-484B-127-3 (caravan) does not list `ru.procession_vehicle`.
  - NRS-484B-710 lists `sig.siren`, although its text has no siren.
  - LVMC-11-12-080-A and NRS-484B-600-1a list `env.ice_or_snow` by inference.
  - NRS-484B-270-4 and -270-7b do not list the e-bike and e-scooter atoms their text names.

## 8. Gaps in the evidence

- **No published encounter rate per driving hour or mile** for responding emergency vehicles,
  school buses, work zones or processions. No source gives the share of funerals with a road
  procession.
- **No machine-readable per-class or per-city counts** for nuScenes, AV2, CODA, WOD-E2E or
  nuPlan's per-city scenario distribution (figures only). Las Vegas hours in the full nuPlan
  release are not stated.
- **Nevada and Clark County sources that could not be fetched** (dot.nv.gov, rtcsnv.com,
  files.clarkcountynv.gov): flashing-yellow-arrow and HOV-mile counts, school-zone and
  school-bus-stop counts, lane-miles by functional class in Clark County, the Nevada cremation
  rate, and the status of RTC Bike Share and shared scooters. A manual download or a records
  request would close these.
- **No inventory found** of alleys, painted safety zones or two-way centre turn lanes.

## 9. Sources

All accessed 2026-10-02.

| id | publisher, title, year | URL |
|---|---|---|
| S1 | FHWA, Highway Statistics 2024, Table VM-1 | https://www.fhwa.dot.gov/policyinformation/statistics/2024/vm1.cfm |
| S2 | FHWA, Highway Statistics 2024, Table VM-4 | https://www.fhwa.dot.gov/policyinformation/statistics/2024/vm4.cfm |
| S3 | FHWA, Highway Statistics 2024, Table MV-1 | https://www.fhwa.dot.gov/policyinformation/statistics/2024/mv1.cfm |
| S4 | Clark County School District Newsroom, "Navigating America's Largest School Bus Fleet", 2023, updated 2024 (read from the Wayback Machine snapshot 20251206113932) | https://newsroom.ccsd.net/navigating-americas-largest-school-bus-fleet/ |
| S5 | NEMSIS Technical Assistance Center, 2025 Public-Release Dataset press release, May 2026 | https://nemsis.org/wp-content/uploads/2026/05/Press-Release-NEMSIS-2025-Public-Release-Dataset.pdf |
| S6 | Clark County Fire Department, 2025 one-page summary | https://www.clarkcountynv.gov/adobe/assets/urn:aaid:aem:8bd041f0-8d57-46cf-b43f-2d3f570b9845/original/as/One-Page-CC-Fire-Dept-2025-Summary---FINAL.pdf |
| S7 | CDC NCHS, Data Brief No. 548, January 2026 | https://www.cdc.gov/nchs/data/databriefs/db548.pdf |
| S8 | National Funeral Directors Association, 2025 Cremation & Burial Report release | https://www.nfda.org/nfda-releases-2025-cremation-burial-report-comprehensive-insights-to-guide-the-future-of-funeral-service/ |
| S9 | AAA Newsroom, April 2025 | https://newsroom.aaa.com/2025/04/aaa-urges-drivers-to-stay-proactive-on-auto-repair-and-maintenance/ |
| S10 | LTRC / LaDOTD / FHWA, *Golf Carts on Public Roads*, FHWA/LA.17/19-02TA-SA, 2020 | https://rosap.ntl.bts.gov/view/dot/63072/dot_63072_DS1.pdf |
| S11 | FOX5 Las Vegas (news), September 2024 | https://www.fox5vegas.com/2024/09/03/food-delivery-robots-can-now-deliver-off-unlvs-campus/ |
| S12 | American Foundation for the Blind, vision-difficulty demographics (ACS 2024) | https://afb.org/research-and-initiatives/statistics/demographics-americans-vision-difficulty |
| S13 | Las Vegas Monorail (LVCVA), May 2021 | https://www.lvmonorail.com/las-vegas-monorail-reopens/ |
| S14 | FTA National Transit Database, 2022–2024 Annual Data – Metrics (official open-data API) | https://data.transportation.gov/resource/ekg5-frzt.json |
| S15 | Nevada Taxicab Authority, December 2025 statistics | https://taxi.nv.gov/uploadedFiles/taxinvgov/content/About_Us/ALL/Statistics/2025_Monthly_Statistics/December-2025-Statistics.pdf |
| S16 | FHWA, *Summary of Travel Trends: 2022 NHTS*, FHWA-HPL-24-009, 2024 | https://rosap.ntl.bts.gov/view/dot/73764/dot_73764_DS1.pdf |
| S17 | FRA, Crossing Inventory Data (Form 71) – Current, dataset m2f8-22s6 | https://data.transportation.gov/resource/m2f8-22s6.json |
| S18 | FRA, Highway-Rail Grade Crossing Incident Data (Form 57), dataset 7wn6-i5b9 | https://data.transportation.gov/resource/7wn6-i5b9.json |
| S19 | FHWA, Highway Statistics 2023, Table HM-20 | https://www.fhwa.dot.gov/policyinformation/statistics/2023/hm20.cfm |
| S20 | Kittelson & Associates, Roundabouts Database | https://roundabouts.kittelson.com/ |
| S21 | FHWA Resource Center, Intersection Safety fact sheet, 2004 | https://www.fhwa.dot.gov/resourcecenter/teams/safety/saf_3IST.pdf |
| S22 | FHWA, National Bridge Inventory, Bridge Condition by County 2024 | https://www.fhwa.dot.gov/bridge/nbi/no10/county24.cfm |
| S23 | FHWA, National Tunnel Inventory, 2025 Tunnel Counts by State | https://www.fhwa.dot.gov/bridge/inspection/tunnel/inventory/tunnelsbystate2025.cfm |
| S24 | NOAA National Weather Service Las Vegas, "Climate of Las Vegas" | https://www.weather.gov/vef/ClimateofLasVegas |
| S25 | RTC of Southern Nevada (FAST), Western District ITE annual meeting presentation, 2026 | https://www.westernite.org/annualmeetings/26_Bellevue/9B_Ehlinger_Implementing%20a%20Modern%20Open%20System%20Based%20Traffic%20Signal%20System.pdf |
| S26 | FHWA Work Zone Management Program, Facts and Statistics | https://ops.fhwa.dot.gov/wz/resources/facts_stats.htm |
| S26b | FHWA Office of Operations, work-zone one-pager (about 2004) | https://ops.fhwa.dot.gov/aboutus/one_pagers/wz.htm |
| S27 | NOAA NCEI, U.S. Climate Normals 1991–2020, station USW00023169 (data service) | https://www.ncei.noaa.gov/access/services/data/v1?dataset=normals-annualseasonal-1991-2020&stations=USW00023169&dataTypes=ANN-PRCP-AVGNDS-GE001HI,ANN-PRCP-AVGNDS-GE010HI,ANN-SNOW-NORMAL,ANN-SNOW-AVGNDS-GE001TI&format=json |
| S28 | NOAA Technical Memorandum NWS WR-271, *Climate of Las Vegas, Nevada*, rev. 2005 | https://www.weather.gov/media/wrh/online_publications/TMs/TM-271.pdf |
| S29 | NCES Common Core of Data, Clark County School District, 2024-25 | https://nces.ed.gov/ccd/districtsearch/district_detail.asp?ID2=3200060 |
| S30 | CCSD 2026-27 student calendar | https://resources.finalsite.net/images/v1767641305/ccsdnet/ano6uzxheee9tby6g8ta/2026-2027-school-calendar-students-updated-final.pdf |
| S31 | Clark County Office of Traffic Safety / Kimley-Horn, Final Report for School Traffic Safety Working Group, June 2026 | https://clark.legistar.com/View.ashx?M=F&ID=15663139&GUID=7EB98625-E903-4626-9A41-C835A3B8D0ED |
| S32 | Las Vegas Valley Water District, "How water gets to you" | https://www.lvvwd.com/water-system/how-water-gets-to-you/index.html |
| S33 | Karnchanachari et al. (Motional), "Towards learning-based planning: The nuPlan benchmark for real-world autonomous driving", arXiv 2403.04133, 2024 | https://arxiv.org/pdf/2403.04133 |
| S34 | Caesar et al., "NuPlan: A closed-loop ML-based planning benchmark for autonomous vehicles", arXiv 2106.11810, 2021–22 | https://arxiv.org/abs/2106.11810 |
| S35 | Motional, nuplan-devkit scenario mapping (73 scenario types) | https://raw.githubusercontent.com/motional/nuplan-devkit/master/nuplan/planning/script/config/common/scenario_builder/scenario_mapping/nuplan_scenario_mapping.yaml |
| S36 | Caesar et al., "nuScenes: A multimodal dataset for autonomous driving", arXiv 1903.11027 | https://arxiv.org/pdf/1903.11027 |
| S37 | Argo AI, Argoverse 2 Sensor Dataset user guide (classes "in order of frequency") | https://argoverse.github.io/user-guide/datasets/sensor.html |
| S38 | Xu et al. (Waymo), "WOD-E2E: Waymo Open Dataset for End-to-End Driving in Challenging Long-tail Scenarios", arXiv 2510.26125 v2, 2025 | https://arxiv.org/html/2510.26125v2 |
| S39 | NHTSA, Traffic Safety Facts 2022, DOT HS 813 656 | https://crashstats.nhtsa.dot.gov/Api/Public/ViewPublication/813656 |
| S40 | Najm, Smith, Yanagisawa (Volpe / NHTSA), *Pre-Crash Scenario Typology for Crash Avoidance Research*, DOT HS 810 767, 2007 | https://rosap.ntl.bts.gov/view/dot/6281/dot_6281_DS1.pdf |
| S41 | NASDPTS, 2026 illegal-passing survey press release | https://nasdpts.org/resources/IllegalPassing/2026/2026%20Press%20Release.pdf |
| S43 | National Work Zone Safety Information Clearinghouse, crash trends and statistics | https://www.workzonesafety.org/work-zone-data/work-zone-traffic-crash-trends-and-statistics/ |
| S44 | The Nevada Independent (news), e-bikes and e-scooters on Strip sidewalks | https://thenevadaindependent.com/article/are-e-bikes-and-e-scooters-allowed-on-las-vegas-strip-sidewalks |
| S47 | NDOT news release republished by CarsonNow (news), April 2019 | https://carsonnow.org/story/04/08/2019/nevada-notes-grim-stat-safety-reminder-1179-work-zone-crashes-resulted-12-fatalitie |
| S48 | FOX5 Las Vegas (news), flashing yellow arrows, May 2022 | https://www.fox5vegas.com/2022/05/27/clark-county-makes-changes-left-turns-flashing-yellow-arrows/ |
| S48b | FOX5 Las Vegas (news), HOV hours, April 2023 | https://www.fox5vegas.com/2023/04/24/ndot-announces-new-hours-southern-nevada-hov-lanes-begin-tuesday/ |
| S49 | The Brink's Company, Form 10-K FY2025 (SEC EDGAR) | https://www.sec.gov/Archives/edgar/data/78890/000007889026000010/bco-20251231.htm |
| S50 | International Guide Dog Federation, Facts & Figures | https://www.igdf.org.uk/?p=573 |
| S51 | Clark County, Invitation to Bid 607991-26 (pedestrian bridges), 2026 | https://www.clarkcountynv.gov/assets/documents/business/business_opportunities/607991-26-sdj.pdf |
