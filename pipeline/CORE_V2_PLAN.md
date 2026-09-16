# Core v2: a law-facing ontology, with CARLA as one adapter among several

Date: 2026-09-15, revised the same day after review. Status: agreed direction; nothing here is implemented.
Resolved in review: the atom set is universal across jurisdictions (§2.5); CARLA captures will be
re-recorded once the collector exists; `unknown` is a required verdict; the RL reward is deferred and
the near-term objective is evaluation accuracy on synthetic and recorded driving (§4.4).
Builds on `ALIGNMENT_AUDIT_2026-09-14.md`, which established how far the current Core is shaped by
the CARLA scene-graph generator rather than by traffic law.

## 0. The diagnosis, stated precisely

The current contract is written into `CLAUDE.md` and `Core/Scene.lean`: *"The 18 entity types and 18
relation labels in Core/Scene.lean are exactly what the generator emits"* and *"the vocabulary is the
CARLA compatibility boundary."* That is a sound rule for a monitor whose only input is `carla_sgg`
output. It is the wrong rule for a pipeline whose target is traffic law, for three reasons the audit
made concrete:

1. **Absence in the data became absence in the language.** No stop-line position, no crosswalk, no
   lane marking, no non-ego velocity, no yield sign, no arrow or flashing signal state exist in the
   RSV, so no predicate exists for them, so the plan agent is told the clause is a "gap" and the
   coding agent reaches for a proxy. G4 (curvature → steering), the trigger-volume-as-stop-line
   residue on every stop rule, and junction-occupancy-as-arrival on both junction rules are the
   same failure: a statutory element was *re-expressed* in whatever the graph happened to carry.
2. **Absence reads as compliance.** Every `Pred.*` is `Scene → Bool`, and an unreadable attribute is
   `false`. A rule whose antecedent needs an unavailable atom is silently always-satisfied. For an
   RL reward this is the worst direction: the policy is rewarded for situations the monitor could
   not see.
3. **Time is a frame count.** `captureHz = 20` is frozen in Core and every duration is
   `secondsToFrames n`. Real video has variable, often unknown, sampling; even one CARLA route on
   disk runs at a different rate.

None of this is a defect of `carla_sgg`; it is the consequence of letting the data source define the
vocabulary. The redirection the project now wants — law defines the atoms, sources declare what
they can supply — is the standard shape for runtime verification over perception (a specification
ontology plus per-sensor grounding with declared coverage), and it is the right one for a reward
signal that must survive the move from simulation to recorded driving.

**What must be kept.** The current repository got several hard things right and they transfer
unchanged: finite-trace LTL with bounded operators (`Formula`, `Semantics`, `Monitor`); grounding
by binders with distinctness and co-presence (`Grounding`); decidable integer arithmetic instead
of `Float` (`Decimal`); the gate that rejects hand-rolled `Scene → Bool` tests; the frozen,
law-free artifacts with a doctor that holds descriptions to the things described; the derived label
pipeline (`evalkit` L0–L3). Core v2 is a re-founding of `Scene.lean`, `Vocab.lean` and `Builders.lean`
on a different authority, not a rewrite of the monitor.

## 1. Is the redirection reasonable? Where it can go wrong

Reasonable, and overdue. Two risks a top-down ontology carries, with the mitigation for each:

| Risk | What it looks like | Mitigation built into this plan |
|---|---|---|
| **Unverifiable abstraction.** An ontology written from the statute alone grows atoms no source will ever supply, every rule reads `unknown`, and the reward is empty. | Dozens of atoms, most `unknown` on every dataset. | Every atom carries a *grounding record* naming at least one concrete source that supplies it today (CARLA API call, or a perception task with a known error class) or it is filed as a **declared-absent** atom with no rule allowed to depend on it alone. The portability ledger already has this vocabulary (`origins`); it becomes normative. |
| **Ontology design as an open-ended project.** | Months of debate over what a "roadway" is. | The atom set is *enumerated* from statute text, not invented: every noun and verb in BC MVA Part 3 that appears in an obligation, cross-checked against the Vienna Convention on Road Traffic (1968) Art. 1 definitions so the set is jurisdiction-neutral. Anything not reached by either list is out. |

Two further points of judgement:

- **CARLA remains the RL environment.** The VLM is trained in simulation; recorded driving is for
  evaluation and pre-training. So the CARLA adapter is not "just one adapter" in effort terms: it must
  become complete against the ontology, and it can be, because the CARLA API exposes almost
  everything the RSV lacks (§3b of the audit). For online RL it should read the live API each tick,
  not round-trip through `.pkl`.
- **Law compliance and risk are different signals.** "Risky but legal" (small time-to-collision,
  hard braking) is not a statute. Keep a second, small layer of *risk atoms* over the same kinematic
  atoms, and never let a rule file smuggle one in as a legal residue.

## 2. Atoms: the closed set the agent may not decompose further

### 2.1 Principles

1. **An atom is an observable of the world, with a semantic contract.** Each atom states what it
   denotes physically, its unit, its reference frame, and what an observation of it *means* on a
   given source (exact / estimate with error class / unavailable). It never states how any dataset
   produces it.
2. **Atoms are three-valued.** `Atom : Scene → Option Bool` (and `Scene → Option Int` for
   measurements). `none` means *not observed on this source*, and it propagates: a formula is
   `unknown` unless every atom it touched at every frame that mattered was observed. `unknown` is
   never `compliant`. This single change is what makes proxy-substitution unprofitable: an agent
   cannot make an unavailable atom "work".
3. **Derived concepts are defined once, in Core, from atoms**, with their parameters exposed
   (`stopped ε`, `laneChange`, `overtaking`, `uTurn`, `enteringIntersection`). A rule may use them
   and may not redefine them. This is where every threshold the statute does not state lives, and
   it lives as a *parameter*, not a literal in a rule.
4. **A rule may use only atoms and derived concepts.** The gate already rejects raw `Scene → Bool`;
   it additionally rejects a rule whose declared statutory elements map to atoms outside the
   *concept-to-atom whitelist* (§2.4).
5. **Judgement standards are atoms of a special kind.** "Reasonable and prudent", "safe distance",
   "when practicable" are not observable. They are `Judgement` atoms that a *reading* must quantify
   (e.g. "safe distance" → a time gap of at least *g* seconds, *g* supplied by the reading). The
   reading is the only human input, exactly as in `evalkit/readings`, and the spec and the label
   read the same quantification.

### 2.2 The atom families, enumerated from Part 3

Enumerated from ss.119–214 as read for the audit, with the Vienna Convention as the neutrality
check. Counts are of *kinds*, not of predicates; each kind becomes a handful of atoms.

| Family | Atoms (kind) | Statute sources | Notes on grounding |
|---|---|---|---|
| **Road users** | vehicle, motor vehicle, cycle, pedestrian, emergency vehicle (responding), bus, school bus, commercial vehicle, motorcycle, animal-drawn | s.119 defs, 122, 149, 162(2), 169.1, 183, 194 | class + `responding` (beacon/siren) + subject-vs-other; the ego is a vehicle with a known class |
| **Kinematics** | position, heading, velocity vector, speed, longitudinal acceleration, yaw rate, body extents, *time* | throughout | every one on every road user, not only the ego; measured or estimated with error class |
| **Road structure** | roadway, lane, laned roadway, lane count and ordinal, direction of travel of a lane, centre line, lane marking type (solid/broken/double) per side, shoulder, sidewalk/boulevard, median/divided highway, one-way, intersection region, crosswalk (marked/unmarked), stop line, driveway/alley, curve, grade, railway crossing, controlled-access highway | 119, 150–168, 176, 179, 185, 186–190 | map-level; exact in CARLA via OpenDRIVE + `get_crosswalks`/`get_stop_waypoints`; estimated from video via lane/line detection with an HD-map-free error class |
| **Control devices** | traffic control signal with state {red, yellow, green, red arrow, yellow arrow, green arrow, flashing red, flashing yellow, flashing green, off, inoperative}, pedestrian signal, lane control signal, stop sign, yield sign, speed sign (value, unit), turn/movement prohibition sign, lane designation (HOV/bus), school/playground zone sign, U-turn prohibition, flagger/officer direction | 125–134, 140–141.1, 146–147, 152–153.2, 161, 168, 173, 186 | each with a *governs(lane)* relation and a *position* (so "before the signal" is expressible). Arrow, flashing, pedestrian and lane-control states are **declared-absent on CARLA** and stay atoms. |
| **Signals emitted by road users** | turn indicator L/R, brake lamp, hazard, headlamps/high beam, emergency beacon, siren/horn (audible), hand signals | 151(c), 169–172, 177, 183(17) | siren and hand signals declared-absent on CARLA; audible atoms exist for video-with-audio |
| **Relations** | occupies(lane), in(region), ahead-of/behind in lane, oncoming, same direction, lateral clearance (surface), longitudinal gap (surface), time gap, on-the-right-of at an intersection, arrival order at an intersection | 150–162, 173–175, 179 | derived from kinematics and structure with stated frames |
| **Environment** | daylight/darkness, precipitation, road wetness, fog/visibility distance, business/residence district, municipality, school day | 144, 147, 162(2), 176, 183(6), 187, 207 | environment atoms from a per-trace manifest; district/municipality/school-day are **declared-absent everywhere** and can only enter through a reading assumption, never a rule |
| **Manoeuvres (derived)** | stopped, moving off, turning L/R, U-turn, lane change, overtaking, passing on right/left, entering/leaving intersection, backing, yielding (gave way to X), following | 150–175, 193 | Core definitions over atoms with exposed parameters; the *only* place a heading-reversal or a lane-change is defined |

Deliberately not atoms: anything named after a dataset field (`controls` edge, `mayAffect`,
`laneChange` edge, `trigger volume`, `render distance`, band labels). Those are *how CARLA grounds* an
atom, and belong in the adapter.

### 2.3 The termination rule, stated for the agent and for the gate

> A clause is formalized only from atoms and Core-defined derived concepts. If a statutory element
> has no atom, the plan records the element by name as **missing from the ontology** and the clause
> is `blocked` (an ontology-change request, human-gated). If the element has an atom that the
> evaluation source declares absent, the clause is `unsupported on this source` and still gets
> formalized, because another source may supply it. In neither case may a different atom stand in.

Mechanical enforcement, all in the gate and the doctor, none in prose:

- **Concept whitelist.** `ontology/concepts.jsonl`: statutory element (e.g. "on a curve", "marked
  stop line", "signalled an intention") → the atoms allowed to express it. A rule file declares
  which elements it formalizes; the gate checks every atom it uses is whitelisted for some declared
  element. `steer` is not whitelisted for "on a curve"; the rule is rejected, not accepted with a
  residue.
- **Unknown-aware vacuity.** The gate's liveness count becomes three-valued: engaged-and-observed,
  engaged-and-unknown, never engaged. A rule whose antecedent is `unknown` on every scenario fails
  the gate as before, and a capture report counts `unknown` verdicts separately from compliant ones.
- **No durations in rules.** A rule file may not contain a numeric time literal; durations come from
  the reading parameters (§3).
- **Ontology change is the only route to a new atom**, with the same freeze discipline Core has
  today: reviewed, cited to a statute element and to at least one grounding, versioned.

### 2.4 What "atom" does not mean

Atoms are not "everything a sensor can output" and not "the smallest physical quantity". A lane's
*direction of travel* is an atom even though it is derivable from waypoint headings, because the
statute refers to it directly and every source must supply it or declare it absent. Conversely
`steer` is not an atom of traffic law — no clause in Part 3 refers to a steering angle — and it
should exist, if at all, in the risk layer.

### 2.5 The atom set is universal; the rules are not

Traffic law across jurisdictions is written over one physical world: the same road users, the same
kinematics, the same kinds of road structure and control device, the same manoeuvres. What differs
between British Columbia, Germany and Japan is the *obligations* — whether a right turn on red is
permitted, which side to drive on, what a flashing green means — and those are rules, not atoms.
The Vienna Convention Art. 1 definitions and the near-identical definition sections of every
national code are the evidence: the vocabulary converges, the duties do not. So the foundation is
fixed once and does not change when the corpus changes from Part 3 to Part 3 plus regulations, or
to another jurisdiction. Enumerating from Part 3 is how the first complete draft is obtained, not
what bounds the set; the Vienna cross-check is what keeps it from being a BC ontology.

Two places where jurisdiction does reach the atom layer, and how each is kept out of Core:

- **Device states and legends have a long tail.** A red arrow, a flashing green, a lane-control
  signal, a school-bus lamp, a "no right turn on red" plate are all *instances* of universal kinds
  (signal state, sign class with a legend). Core fixes the kinds and an open value space (a state
  enumeration that can be extended, a sign class plus a catalogue code and legend, exactly as
  `landmark_type` works today); a jurisdiction adds values in `ontology/extensions/<jurisdiction>.jsonl`
  under the same freeze discipline. Core itself never gains a BC-specific constructor.
- **Legal region classes are not observable.** "Municipality", "business district", "school day",
  "through highway" are categories the law defines, not features of the road. They enter only as
  reading assumptions (declared per trace or per map), never as atoms a rule reads from a scene.

## 3. Time without a frame rate

- **Every `Scene` carries a timestamp** (`t : Int`, milliseconds), supplied by the adapter: simulator
  tick × Δt for CARLA (from the manifest, which already exists), presentation timestamps for video.
  `captureHz` and `secondsToFrames` are removed from Core.
- **Bounded operators are metric.** `holdsFor d φ` (φ observed true on every frame of some span
  whose endpoints are at least *d* apart), `within d φ` (φ observed true at some frame no more than
  *d* after now), `since`, `untilWithin`. Semantics are defined on the sampled sequence with
  timestamps; no interpolation is asserted beyond "observed at these instants".
- **Sampling adequacy is a precondition, not an assumption.** A rule using `holdsFor d` reports
  `unknown` on any span where consecutive timestamps are more than *d/2* apart (the monitor cannot
  tell a one-second stop from a one-frame stop). This replaces the frozen-rate refusal in the
  adapter with a per-rule, per-trace check, and it is what makes variable-rate video usable at all.
- **Rates are atoms with provenance.** Speed and acceleration are supplied measured where the source
  has them (CARLA, instrumented ego) and estimated from position and timestamp otherwise, with the
  error class recorded in the capability manifest. Rules do not care which.
- **Durations the statute does not state are reading parameters.** "Complete stop" → `stopped ε d`
  with ε (rest speed) and d (dwell) from the reading; the same reading drives the label. This closes
  the "second formalization" concern in `CLAUDE.md`: spec and label share one quantification.

## 4. Sources as adapters to Core, not the other way round

### 4.1 The capability manifest

Each source ships `capabilities.json`: for every atom, one of `exact`, `estimate(error_class)`,
`absent`. The doctor requires it to be complete over the ontology. The monitor reads it to decide
which atoms are `none` before a single frame is read, and the report states per rule: *supported /
partially supported (which atoms unknown) / unsupported on this source*. The `perception/portability.json`
of today is the video manifest's first draft.

### 4.2 CARLA: a collector, not a bigger `.pkl` reader

`carla_sgg` is byte-frozen and its abstraction folds the waypoint detail away, so the RSV cannot be
made Core-complete by any adapter change (audit §1B, §3b). The honest architecture is a
**capture-time collector** in `carlaspec/` that reads the CARLA API on the same tick the generator
runs and writes `atoms/<frame>.json`, with the adapter merging RSV + atoms into a trace. What the
collector adds, in priority order (each unblocks the audit §3a rows it names):

1. non-ego `get_velocity` / `get_acceleration`; the ego's own `get_light_state`; the ego's
   `type_id` and attributes;
2. `TrafficLight.get_stop_waypoints`, `Map.get_crosswalks`, `traffic.yield` actors, per-waypoint
   lane markings / width / type (`Sidewalk`, `Shoulder`, `Median`, `OnRamp`), curvature and grade
   from the OpenDRIVE geometry;
3. `World.get_weather`, `sun_altitude_angle` (already in the manifest the scripts write);
4. door state, walker attributes, `TrafficLight` timing and grouping.

For online RL the same collector runs live and skips the `.pkl` round trip entirely; the RSV is
then a debugging view, not the data path. Existing captures cannot supply most of these and will
have to be re-recorded once the collector exists; the label pipeline (L1 facts) should be built on
the collector's atoms too, so labels and specs see one world.

### 4.3 Video: the same manifest, mostly `estimate` and `absent`

A perception stack (detector + tracker + lane/line + signal-state + ego odometry) fills the atoms it
can and declares the rest. Identity is a tracker output and *will* switch ids (audit §3c); the
grounding layer must tolerate re-identification (bind on tracks, tolerate one gap) rather than
assume simulator-grade identity. Map-derived atoms (lane identity, governs) are `absent` without a
registered HD map and `estimate` with one.

### 4.4 The near-term objective: evaluation accuracy on both sources

The RL reward is deferred; what the pipeline must first establish is that it detects unlawful
driving **accurately, completely and efficiently** on synthetic captures and on recorded video. That
fixes the verdict lattice and the metrics now, and the reward inherits them later.

Verdicts are four-valued, and the four are not interchangeable:

| verdict | meaning | counts toward |
|---|---|---|
| `violated` | every atom the formula touched was observed, and the obligation was breached | true/false positive against the derived label |
| `compliant` | antecedent observed true, consequent observed and met | true/false negative |
| `not_applicable` | antecedent observed **false** — the situation did not arise | engagement (the rule was testable, and was not engaged) |
| `unknown` | an atom the verdict depended on was not observed on this source | coverage only; **never** a negative, never in the accuracy denominator |

Reading `unknown` as compliance, which the two-valued Core does today, is what produces the wrong
signal on video: a rule whose atoms a camera cannot supply would report every recording lawful.

Metrics, per rule and per source, computed against the derived labels of `evalkit`:

- **accuracy**: precision and recall of `violated` over frames and over episodes where the verdict is
  observed (`unknown` excluded from the denominator and reported beside it);
- **completeness**: the fraction of obligations in the corpus whose rule is *supported* on the
  source (no atom `absent` in the capability manifest), and of those, the fraction *engaged* on the
  evaluation set — this is the "第二行" of today's monitor report made source-relative;
- **coverage of unsafe situations**: recall over the scenario set labelled unsafe, split by whether
  the miss was a wrong verdict or an `unknown`; the second is a perception or ontology gap, the first
  a formalization defect, and they are fixed by different people;
- **efficiency**: monitor cost per frame and per rule (grounding count × trace length); the current
  cross-product grounding is quadratic in frames and will not scale to hour-long video without
  incremental (automaton-style) monitoring — flagged as Phase 4 work, not needed for correctness.

"Unsafe" and "unlawful" are kept distinct. The rule library detects the second; a small risk layer
(time-to-collision, hard braking, lateral clearance) over the same kinematic atoms can detect the
first later, and nothing in this plan prevents it — the kinematic atoms are deliberately specified
on every road user, not only the ego, for that reason.

## 5. Work plan

| Phase | Deliverable | Effort | Gate |
|---|---|---|---|
| **0. Ontology** | `ontology/ATOMS.md` (atom, contract, unit, frame, statute sources, groundings) and `ontology/concepts.jsonl` (statutory element → allowed atoms), enumerated from Part 3 and checked against Vienna Art. 1 | 2 weeks, one author + one reviewer | human review; every atom has ≥ 1 grounding or is marked declared-absent |
| **1. Core v2** | `Scene.lean` (timestamped scenes, sources-neutral entity/structure types, three-valued atoms), `Time.lean` (metric operators, sampling adequacy), `Atoms.lean` (the closed set), `Derived.lean` (manoeuvres with parameters), `Capability.lean`; `Formula/Semantics/Monitor/Grounding/Decimal` kept, semantics extended to `Option Bool`; kernel tests | 3 weeks | `lake build`; every atom reachable from a binder or declared not; doctor re-pointed at the ontology |
| **2. CARLA collector + adapter v2** | `carlaspec` collector; adapter merges RSV + atoms; `capabilities.json` for CARLA; re-record the scenario set; L1 facts from atoms | 3 weeks | doctor: manifest complete; converted capture type-checks; audit tables §3a rows move from "gap" to supported |
| **3. Pipeline** | plan prompt maps statutory elements → atoms via the whitelist; gate: whitelist check, unknown-aware vacuity, no time literals; gap ledger becomes ontology-change requests; readings carry parameters the rules consume | 2 weeks | `run_spec verify`; the U-turn/curvature substitution is rejected by the gate on a deliberate test |
| **4. Transfer** | video capability manifest; perception adapter over a public dataset; per-rule support report; the §4.4 metrics computed on both sources | 3 weeks | monitor runs on one video sequence; accuracy and completeness reported with `unknown` separated |

Roughly one quarter for one strong engineer with a reviewer for Phase 0 and the Core freeze; the
ontology review is the critical path and should not be compressed. Phases 1 and 2 can overlap once
the atom list is frozen.

## 6. Difficulty, honestly

- **Hard:** the three-valued semantics touches every predicate, the vacuity logic, the report format
  and the gate; getting the `unknown` propagation right without making everything unknown is the
  technical core of the work. Ontology minimality is a design judgement no tool settles.
- **Medium:** timestamps and metric operators; the collector (CARLA API is rich and documented);
  the concept whitelist.
- **Costly but mechanical:** re-recording captures; regenerating the 15 rules and 30 witnesses
  against the new atoms; re-deriving labels.
- **The thing most likely to be under-estimated:** identity on video. The grounding architecture
  assumes one id per entity per trace; a tracker does not provide that, and a rule's verdict over a
  spliced track is wrong in both directions. Phase 4 must include track-tolerant grounding, not just
  a manifest.

## 7. Decisions taken in review, and what follows from each

1. **The atom set is universal** (§2.5). Phase 0 enumerates from Part 3 for completeness and checks
   against Vienna Art. 1 for neutrality; jurisdiction-specific device values live in extensions, and
   legal region classes are reading assumptions. Adding the regulations Part 3 points to changes the
   rule corpus, not the atom set.
2. **CARLA captures will be re-recorded once the collector exists.** Phase 2 therefore builds the
   collector *before* the adapter, records the scenario set against it, and derives L1 facts and
   labels from the collector's atoms so labels and specs see one world. Captures on disk are used
   only for regression of the RSV path.
3. **`unknown` is a required verdict**, distinct from `not_applicable` (§4.4). Phase 1 makes atoms
   three-valued and the report four-valued; Phase 3 makes the gate and the monitor report count them
   separately.
4. **The reward is deferred.** Phase 4 is re-scoped from reward shaping to evaluation on recorded
   video with the metrics of §4.4; the reward design is a later document that consumes those verdicts.
