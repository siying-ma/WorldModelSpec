# Core v2: a law-facing ontology, with CARLA as one adapter among several

> **2026-09-18 update.** The target corpus is now the Nevada Revised Statutes (Las Vegas), not BC
> MVA Part 3, and the atom set was re-derived from it (`traffic-spec-agent/ontology/ATOMS.md`, second
> draft; provenance in `ontology_provenance/nrs_atoms_provenance.md`). §2.5 ("the atom set is
> universal") is **superseded**: atoms are law-independent in *contract* but enumerated from the
> target jurisdiction, with a `local` flag where an element exists only under its taxonomy or device
> catalogue; no cross-jurisdiction (Vienna/UVC) comparison is required. The concrete Lean design and
> the validate/diagnosis pipeline are in `CORE_V2_LEAN_DESIGN.md`, which uses only §2.8 and §3 of
> this document.

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
   it additionally rejects a rule whose atoms are used against their
   atom contracts (§2.3), and the review phase (§2.6) judges the mapping.
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

### 2.3 The termination rule, and how a clause reaches it

> A clause is formalized only from atoms and Core-defined derived concepts, and an atom may express
> only what its contract says. If a statutory element has no atom, the plan records the element by
> name and the clause is `blocked` (an ontology change request, the one human gate this pipeline
> keeps). If the element has an atom that the evaluation source declares absent, the clause is
> `unsupported on this source` and is still formalized. In neither case may a different atom stand
> in.

The termination rule is the closed atom set plus the "not a stand-in for" clauses of the atom
contracts, frozen in `ontology/ATOMS.md`. It contains no statute, no clause and no source, so it
holds for any jurisdiction. Mapping clause elements onto atoms is the **planning session's** work;
whether that mapping is faithful is decided by a **review phase**, not by a whitelist and not by a
human. Enforcement, all mechanical:

- **Deterministic (gate).** Every atom a rule uses exists; every predicate in Core corresponds to an
  atom or a derived concept (a bijection the doctor checks); no numeric time literal in a rule; the
  run's mapping claims are consistent — each planned node records its clause element → atoms claims
  in its `elements` field, the same element maps to the same atoms in every node, a contradiction is
  rejected, and the harness derives the run's mapping index from the accepted nodes. No agent writes
  a shared file and no review state is stored.
- **Semantic (review phase, §2.6).** An independent session judges each mapping claim and the
  rule's logical shape against the atom contracts and the clause, and can only reject.
- **Bounded (§2.6).** Rejection returns the node to planning at most K times; after that the node
  is `disputed`, recorded with both positions and excluded from the library.

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

### 2.6 The review phase

**Why an agent and not a table.** The failure the review phase guards against is semantic: a
clause element expressed by an atom whose contract does not cover it (steering angle for a curve,
a device's governance region for a stop line). A pre-enumerated element → atom whitelist would catch
it, but it is corpus-derived, pre-decides the mapping the planner is supposed to make, and leaks
the evaluation corpus into a frozen artifact. The review is therefore done by an independent
session against the frozen contracts only.

**Decorrelating reviewer and planner.** Both are probabilistic and, if drawn from one model family,
share blind spots. The levers, in order of effect:

1. *Blind review.* The reviewer sees the clause, the mapping claims and the atom contracts; it does
   not see the planner's justification, nor the witness scenarios the same session wrote.
2. *Back-translation.* Given only the atoms and the formula, the reviewer writes in plain language
   the obligation they encode, without the clause; a separate call compares that text with the
   clause. This removes anchoring on the clause's wording and is the strongest single lever.
3. *Burden of proof.* The task is to find the weakest claim; the default under uncertainty is
   reject-with-question; every acceptance must quote the contract text it rests on, and the harness
   rejects a verdict that quotes nothing.
4. *Decomposition.* Per claim, four machine-checkable questions: what in the world does the element
   denote; which contract covers it, quoted; does any "not a stand-in for" clause name this use; is
   there a closer atom. Per rule, the logical shape: which elements form the situation and which the
   obligation; is the temporal shape (persistence, eventuality, precedence) the clause's; do the
   binders play the roles the clause assigns.
5. *A second model family*, only if the calibration below shows residual misses; disagreement
   between the two is then itself a signal. The choice is made on measured recall, not assumed.

**Calibration without ground truth (mutation testing).** The reviewer's recall is measured on
mutants generated from the ontology's own structure, so no human key is needed:

| operator | example | what it tests |
|---|---|---|
| same-family substitution | a road-geometry atom for another | discrimination within a family |
| proxy substitution, derived from the "not a stand-in for" clauses (X is not a stand-in for Y ⇒ mutate Y → X) | steering angle for curvature; governance region for a stop line | the historical failure class |
| atom deletion from a multi-atom mapping | a crossing expressed by occupancy alone | completeness |
| relation swap | centre distance for surface gap; device position for governance | relations that share a family |
| formula mutants | antecedent/consequent swap; consequent negated; □ ↔ ◇; a conjunct dropped; a relation reversed | logical fidelity |

Originals and mutants are presented blind and interleaved. Reported per run: **recall** (mutants
rejected / mutants), **stability** (originals re-accepted on repeated calls), both against thresholds
in the run configuration; a run whose reviewer misses the thresholds fails at the review phase, and
what is changed is the prompt or the model, never a rule. Two honest limits: recall is measured only
on failure classes the operators enumerate, so it is an upper-bound estimate; and a substitution
between two atoms whose contracts carry no clause against each other may be equivalent, so such
mutants are not scored. Results land in `results/<run>/review_calibration.json` and in the summary.

**Bounded retry and the terminal state.** A rejection returns the node to planning with the
reviewer's reasons. A resubmission must, for each reason, either change the claim or state a
rebuttal; a resubmission whose mapping is unchanged and carries no rebuttal does not consume a
round and terminates at once. After **K** rounds (default two) the node becomes **`disputed`**: the
planner's mapping and the reviewer's objections are both recorded, the node is excluded from the
library, and the summary surfaces it to the operator. No automatic acceptance, no further retry.
`disputed` is added to the coverage vocabulary, which the doctor already holds the prompts and the
progress template to.

**What the reviewer cannot do.** It cannot add an atom or amend a contract; an element with no atom
is an ontology change request, the one place a human decides. It cannot accept; it can only fail to
reject, and its failures to reject are what the calibration measures.

### 2.7 What Core v2 has to express, atom by atom

Counted on `ontology/ATOMS.md` as drafted (118 identifiers: 89 atoms, 8 judgement standards,
21 derived concepts). "v1" is the archived CARLA-first Core.

| class | count | in Core v2 as | v1 counterpart | handling |
|---|---|---|---|---|
| **scene atoms** — road users 16, kinematics 9, structure 27 + occupancy 1, devices 16, signals 10, environment 4, relations 6 | 89 | a predicate or measurement over `Scene`, three-valued; structure and device atoms as entity kinds with adapter-computed relations (occupies, distance-to, leads-to, adjacent-to, governs) and attributes (direction, width, marking per side, curvature, grade, state), never raw geometry, so every comparison stays integer and decidable | 43 (8 road-user classes, 8 kinematic channels but ego-only, 6 structure, 7 device, 7 signal, 7 relation); 46 are new, most of them structure and device kinds | all expressible; the 46 new ones are the Scene extension list for Phase 1 |
| — of which **no source supplies today** | ≈15 (human direction, hand signals, audible warning, pedestrian and lane-control signals, arrow and flashing indications, railway crossing and its devices, rail vehicles, school-bus and transit devices, animal-drawn, mopeds, mobility devices, official vehicles) | the same — kept for type completeness, so a rule can be written once and evaluated wherever a source appears | 0 | every manifest declares them `absent`; a rule reading one reports `unknown` and is listed as unsupported on that source, never dropped and never approximated |
| **judgement standards** | 8 | not predicates: parameters of a rule, supplied by the reading (a bound over kinematic or relational atoms); the same reading drives the label | 0 (v1 hard-coded them per rule) | Core gets a parameter record type; the gate rejects a numeric literal in a rule where a parameter is expected |
| **derived concepts** | 21 | definitions in Core over atoms and timestamps, with exposed parameters (stopped, standing, moving off, turning, U-turn, lane change, overtaking, passing side, entering / in / approaching an intersection, crossing a line, backing, following, meeting, yielding, arrival order, wrong way, straddling a marking, responding emergency, vulnerable road user, laned roadway, priority roadway, time gap) | 0 as definitions (v1 rules re-derived them per rule) | all definable in metric LTLf; `arrival_order`, `yields_to` and `meeting` need the intersection-boundary crossing instant and a time-gap bound, both available from the atoms |

Nothing in the ontology is inexpressible in Core; the two non-predicate classes are handled by
type, not by omission: judgement standards become parameters, source-less atoms become `unknown`.
The Phase 1 Scene extension is the 46 new scene atoms; the Phase 1 vocabulary is the bijection
atoms ↔ predicates plus the 21 derived definitions, and the doctor holds both to `ATOMS.md`.

### 2.8 The archived Core, file by file: what survives Core v2

| file | what it is | verdict | why |
|---|---|---|---|
| `Decimal.lean` | parses decimal *strings* into milli-unit integers and compares them | **retire the parsing; keep the unit arithmetic** | it exists because v1 stored every attribute as a string. Core v2 types its attributes at the boundary — `Option Int` in milli-units, `Option Bool`, inductive enumerations — and the adapter does the parsing in Python. What survives is exact integer unit conversion (km/h, mph → m/s) and the milli-unit convention, moved into a small `Units.lean`; `parseMilli`, `leMilli` and the tuple-string scanner go |
| `Formula.lean` | finite-trace LTL AST with a frame-count `bounded` operator | **keep the shape, change three things** | atoms become three-valued (`Scene → Option Bool`), so the AST needs no change but its evaluation does; the frame-counted `bounded n` is replaced by metric `holdsFor d` / `within d` over timestamps; `next` (◯) is frame-relative and ill-defined under irregular sampling — redefined as "at the next observation" or dropped. `frameSpan` becomes a time span |
| `Semantics.lean` | two-valued evaluation with fuel loops | **keep the structure, re-found the value** | evaluation returns a three-valued verdict with Kleene propagation (an unobserved atom makes the formula `unknown` unless the connective decides without it); the metric operators read `kin.time` and report `unknown` where the sampling gap exceeds what the duration needs. The unfolding lemmas are re-proved on the new evaluator |
| `Monitor.lean` | satisfied / violated | **extend** | four verdicts: violated, compliant, not_applicable, unknown |
| `Grounding.lean` | binders as `EntityType` lists, the cross product with distinctness and co-presence, liveness, the tab-separated report | **keep the architecture; replace the binder vocabulary and the identity assumption** | what stays: a schema is a formula over binders, groundings are distinct co-present tuples, `check` is ∀ groundings, liveness separates engaged from vacuous. What goes: `vehicleTypes` / `proximityTypes` / `proximateVehicleBinder` and `sharesDistanceWithEgo`, all transcriptions of the CARLA proximity table — binders in v2 range over ontology classes (`ru.*`, structure and device kinds) with no source-shaped restriction; `unboundEntityTypes` (a CARLA flag and an adapter bucket). What changes: liveness and the report become four-valued (an `UNKNOWN` column); and identity — v1 binds one id for the whole trace, which is right for a simulator and wrong for a tracker, so grounding must bind *tracks* and tolerate a bounded re-identification gap. The quadratic cost of the cross product is unchanged and is the Phase 4 efficiency item |
| `Scene.lean` | `EntityType` / `RelLabel` transcribed from the generator, string attributes, `captureHz`, `distanceBands` | **rewrite** | every enumeration is CARLA's. v2: entity kinds from the ontology (road-user classes, structure kinds, device kinds), relations from the ontology (occupies, governs, leads-to, adjacent-to, and the measured relations), typed attributes, a timestamp per scene, no rate and no bands |
| `Builders.lean` | constructors mirroring the adapter's attribute sets | **rewrite on the new Scene** | the idea survives (a scenario must be indistinguishable from adapter output to a predicate); `padTo` becomes time-based |
| `Vocab.lean` | 1,148 lines of predicates, most reading CARLA keys, band labels, landmark codes and the lane-id sign | **rewrite as the atom ↔ predicate bijection plus the 21 derived definitions** | reusable in substance: the exact-geometry family (squared separation, extents, heading dot products), the landmark-orientation logic, the unit-checked speed comparison. Everything keyed on a generator spelling or a band goes; the doctor holds the new file to `ATOMS.md` in both directions |
| `Tests/CoreArith.lean` | kernel guards for the arithmetic | **rewrite** | same role, new definitions; adds guards for Kleene propagation and the metric operators at a sampling boundary |

Cross-cutting: v1 reads every absent attribute as `false`. In v2 an absent attribute is `none`, which is
the whole of the three-valued semantics; every predicate is rewritten under that rule, so none of
the 1,148 lines is copied unchanged.

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
| **0. Ontology** | `ontology/ATOMS.md` (atom, contract, unit, frame, "not a stand-in for" clauses), enumerated from Part 3 and checked against Vienna Art. 1 and the UVC, with provenance kept outside the agent's reach | 2 weeks, one author + one reviewer | human review; agent-facing file law-free and source-free (doctor `ontology neutral`); every atom has ≥ 1 grounding in provenance or is declared absent |
| **1. Core v2** | `Scene.lean` (timestamped scenes, sources-neutral entity/structure types, three-valued atoms), `Time.lean` (metric operators, sampling adequacy), `Atoms.lean` (the closed set), `Derived.lean` (manoeuvres with parameters), `Capability.lean`; `Formula/Semantics/Monitor/Grounding/Decimal` kept, semantics extended to `Option Bool`; kernel tests | 3 weeks | `lake build`; every atom reachable from a binder or declared not; doctor re-pointed at the ontology |
| **2. CARLA collector + adapter v2** | `carlaspec` collector; adapter merges RSV + atoms; `capabilities.json` for CARLA; re-record the scenario set; L1 facts from atoms | 3 weeks | doctor: manifest complete; converted capture type-checks; audit tables §3a rows move from "gap" to supported |
| **3. Pipeline** | planning session records element → atom claims on each node (`elements`), the harness validates and indexes them; review phase (§2.6) with blind review, back-translation, mutation calibration and K-bounded retry ending in `disputed`; gate: atom/predicate bijection, ledger consistency, unknown-aware vacuity, no time literals; gap ledger becomes ontology-change requests; readings carry parameters the rules consume | 3 weeks | `run_spec verify`; the U-turn/curvature substitution is rejected by the review phase on a deliberate mutant, with the run's recall and stability reported |
| **4. Transfer** | video capability manifest; perception adapter over a public dataset; per-rule support report; the §4.4 metrics computed on both sources | 3 weeks | monitor runs on one video sequence; accuracy and completeness reported with `unknown` separated |

Roughly one quarter for one strong engineer with a reviewer for Phase 0 and the Core freeze; the
ontology review is the critical path and should not be compressed. Phases 1 and 2 can overlap once
the atom list is frozen.

## 6. Difficulty, honestly

- **Hard:** the three-valued semantics touches every predicate, the vacuity logic, the report format
  and the gate; getting the `unknown` propagation right without making everything unknown is the
  technical core of the work. Ontology minimality is a design judgement no tool settles.
- **Medium:** timestamps and metric operators; the collector (CARLA API is rich and documented);
  the review phase's calibration operators.
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
