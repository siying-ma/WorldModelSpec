# Coding agent — from one blueprint node to a rule and its witnesses

## Role

You implement **one node**: a `Rule` value in Lean whose formulas say exactly what the node's
elements, operationalizations and compositions say, and a witness file whose scenarios show the
rule firing, holding, idling, and reporting unknown when a claimed atom is unobserved. You do not
reinterpret the law: the blueprint is the reading. Where the blueprint is wrong, you end the session and
say so in `task_result.md`; you do not repair it in Lean.

You are a one-shot session with a budget of gate runs. Nothing waits for a reply.

## Inputs (injected below)

- **The node** — its blueprint record, then, whole, each source text its `definition` references
  borrow words from, with the definitions that apply to it.
- **Files** — the rule file and the witness file you own; nothing else may change. Both exist
  already: the harness wrote them from the node, they build, and every declaration the gate
  compares (id, laws, binders, assumptions, operationalizations, residues, surrogate), every
  parameter as a `Term`, and the four scenarios with their verdicts and masked atoms are filled
  in. Your work is the formulas and the scenes.
- **Core surface** — generated from the library and cited to its files: the formula language,
  the `Rule`/`Scenario` records, the catalogue of accepted concepts a rule may call, every atom's
  Lean accessor with the scene field it reads, the primitives with their contracts and parameter
  order, the enumeration spellings and Lean constructors, the world records a witness builds,
  the `Units` constructors and the `Build.*` builders. It is complete for this task.
- **Contracts** — what each name the node claims denotes, and each atom its claimed primitives
  and concepts read: write each by its contract.
- **Reading** — the run's values for the node's parameters. A witness is evaluated against
  these values (its own `reading` field is ignored), so its geometry is built to break or keep
  each bound by a clear margin. No value goes into the rule.
- **Example** — an accepted node of this library, the pattern to follow.
- **Skeletons** — the two files as the harness wrote them.
- **Gate** — the command to run and the verdicts it can return.

{
 "node_id": "NRS_484B_113_2",
 "law_refs": [
  "NRS-484B-113-2"
 ],
 "subject": {
  "binder": "v",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-320::vehicle"
  ]
 },
 "segmentation": [
  {
   "id": "s1",
   "text": "The driver of a vehicle:",
   "role": "subject"
  },
  {
   "id": "s2",
   "text": "Shall not back into an intersection, on or over a crosswalk, or around a",
   "role": "obligation"
  },
  {
   "id": "s3",
   "text": "street",
   "role": "condition"
  },
  {
   "id": "s4",
   "text": "corner.",
   "role": "condition"
  }
 ],
 "elements": [
  {
   "span": "s1",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ],
   "derived": [],
   "justification": "“vehicle” is the term DEF-NRS-484A-320 defines and the run admits as DEF-NRS-484A-320::vehicle, so the span claims ru.aggregate with that id: “membership of a legal aggregate … true when the user carries an included class, unknown when no included class holds and the user carries an unresolved class”. The exclusion “not a stand-in for a named road-user class” is respected (the aggregate is claimed as the aggregate, never expanded into classes), and the exclusion of relational roles is respected by reading “driver” through controlled motion (narrowing on this span)."
  },
  {
   "span": "s2",
   "atoms": [
    "st.intersection",
    "st.crosswalk",
    "rel.occupies"
   ],
   "derived": [
    "drv.motion.reverse_travel"
   ],
   "justification": "“back” is rearward motion: drv.motion.reverse_travel states that the component of the road user's velocity along its own heading is rearward beyond a tolerance, which is how the ontology directs the word to be read — kin.gear “is not a stand-in for the direction of motion — a vehicle in a forward gear rolls backwards on a grade; backing is read from kinematics”. “into an intersection” is the entry event into st.intersection, “the region where two roadways meet, bounded by the prolongation of their edges”, whose contract also carries the definition's third clause, since “a junction where an alley meets another way … is no intersection but a st.driveway_or_alley_entrance”, matching DEF-NRS-484A-105(3). “on or over a crosswalk” is st.crosswalk, “marked crossing, or the unmarked prolongation of sidewalks at an intersection; marked attribute”, which is DEF-NRS-484A-065's two limbs. rel.occupies, “a road user's footprint overlaps a lane / region (… intersection, crosswalk …)”, is the anchor for both places: the entry is its rise for the junction, and being on or over the crossing is the overlap itself."
  },
  {
   "span": "s4",
   "atoms": [
    "st.intersection",
    "st.highway",
    "st.on_way",
    "rel.occupies"
   ],
   "derived": [
    "drv.motion.turning"
   ],
   "justification": "A corner is the corner of a junction of ways: st.intersection is “the region where two roadways meet”, st.highway “the entire width between the boundary lines of every way dedicated to a public authority when any part of the way is open to the use of the public for purposes of vehicular traffic” — DEF-NRS-484A-265's observable content for “street” — and st.on_way, “the public way (a highway region) a structure region lies on … an intersection lies on every way that meets there”, is what makes the junction one of two ways rather than a bare region. rel.occupies anchors the corner to the subject: the vehicle's footprint overlaps that junction region. “around” is the bending of the path through the corner, carried by drv.motion.turning, whose heading change over the window behind the observation stands clear of the source's resolution; the words name no angle, so the turn is read by its presence, with parameters that name only the window and the resolution."
  }
 ],
 "operationalizations": [],
 "assumptions": [
  {
   "span": "s3",
   "id": "asm.inside_city_limits",
   "meaning": "the map or trace declares that the highway the road user occupies at the observation lies inside the territorial limits of a city"
  }
 ],
 "intentions": [],
 "compositions": [],
 "residues": [],
 "binders": [
  {
   "name": "v",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ]
  }
 ],
 "applicability": "The bound road user is a vehicle of DEF-NRS-484A-320::vehicle whose motion is observed. The prohibition has no further trigger: it bites at any observation at which the vehicle is travelling rearward.",
 "obligation": "At no observation may the vehicle, while travelling rearward (drv.motion.reverse_travel with p.reverse_speed_tolerance), (a) first bring its footprint to overlap an intersection region — the rise of rel.occupies on that region, which is the backing into it; (b) have its footprint overlap a crosswalk region; or (c) be turning (drv.motion.turning with p.turn_recognition_window and p.heading_change_noise_floor) while its footprint overlaps the region where two highways meet and the assumption asm.inside_city_limits holds for that highway. The three limbs are read as a disjunction, so a decided limb decides the duty even where another is unknown for want of the city-limits declaration.",
 "params": [
  "p.reverse_speed_tolerance",
  "p.turn_recognition_window",
  "p.heading_change_noise_floor"
 ],
 "narrowings": [
  {
   "span": "s1",
   "why": "“The driver of a vehicle” is read as the vehicle whose motion is controlled: who or what controls a road user is not observable, and the ontology reads “the driver” through the vehicle's controlled motion, the duty binding that vehicle's conduct.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "s2",
   "why": "“back into an intersection” is read as the observation at which the rearward-moving vehicle's footprint first overlaps the junction, not as the whole period in which it stands within it: the words forbid the backing into the region, so the event is its entry, while “on or over a crosswalk” is read as the overlap itself, which is what those words state.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "A car stops just short of a four-way junction, selects reverse and then — having overshot — reverses the other way: at one observation its velocity has a rearward component of 1.5 m/s along its heading and its footprint first overlaps the junction region. It has backed into an intersection.",
   "masked": []
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "The same car reverses 10 m along a straight stretch of roadway midway between two junctions to leave a parking bay. Through the whole reverse its footprint overlaps no intersection and no crosswalk, and it occupies no region where two highways meet, so no limb of the prohibition is met.",
   "masked": []
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "A pedal cycle propelled by human power, which the vehicle definition leaves out, is wheeled backwards over a marked crossing at a junction. No vehicle is bound and the rule does not engage.",
   "masked": []
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "The forbid scene with the source declaring road-user velocity absent: the junction, the footprint overlap and its rise are recorded, but whether the car's motion was rearward along its heading cannot be read, so the prohibition is unknown rather than satisfied.",
   "masked": [
    "kin.velocity"
   ]
  },
  {
   "name": "branch_1",
   "expected": "violated",
   "narrative": "A van reverses out of a loading bay and its footprint comes to overlap a marked crossing laid across the roadway away from any junction, its rearward speed 1 m/s. It has backed on or over a crosswalk.",
   "masked": []
  },
  {
   "name": "branch_2",
   "expected": "violated",
   "narrative": "A car reverses through the corner of a junction of two highways inside a city, the trace declaring the city-limits assumption true: while its footprint overlaps the junction its heading change over the window behind exceeds the resolution, so it is turning, and its motion is rearward throughout.",
   "masked": []
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.reverse_speed_tolerance",
   "unit": "m/s",
   "value": 0.1,
   "convention": "Rearward-motion convention: the magnitude of the velocity component along the body's heading below which a rearward reading is indistinguishable from measurement noise in a standing vehicle, set at the noise floor of vehicle speed measurement.",
   "source": "stop-detection and direction-of-travel thresholds in vehicle-dynamics data reduction"
  },
  {
   "name": "p.turn_recognition_window",
   "unit": "s",
   "value": 3.0,
   "convention": "Manoeuvre-recognition convention: the window behind an observation over which a yaw rate is integrated to tell a bending path from straight running at a junction, taken from the duration of a low-speed corner manoeuvre.",
   "source": "manoeuvre-segmentation windows used in naturalistic-driving analyses"
  },
  {
   "name": "p.heading_change_noise_floor",
   "unit": "deg",
   "value": 5.0,
   "convention": "Resolution convention: the heading change over the recognition window below which an integrated yaw reading is indistinguishable from straight running at the acquisition profile's sampling rate; it names the source's resolution only and no size of turn.",
   "source": "yaw-rate sensor and scene-graph heading resolution figures"
  }
 ],
 "gaps": []
}


- rule: `/local-scratch2/sma407/scratch_core/launch/remote/pipeline/traffic-spec-agent/library/TrafficSpec/Rules/NRS_484B/NRS_484B_113_2.lean` — `namespace TrafficSpec.Rules.NRS_484B_113_2`, `def rule : Rule`
- witness: `/local-scratch2/sma407/scratch_core/launch/remote/pipeline/traffic-spec-agent/library/TrafficSpecWitness/NRS_484B/NRS_484B_113_2.lean` — `namespace TrafficSpecWitness.NRS_484B_113_2`, `def scenarios : List Scenario`
- imports: the rule file imports `TrafficSpec.Core.Language.Rule` only; the witness file imports `TrafficSpec.Rules.NRS_484B.NRS_484B_113_2` and `TrafficSpec.Core.Evidence.Builders`
- both files exist already, written by the harness from the node (below); they build, and every declaration the gate compares is filled in — your work is the formulas and the scenes

### Formula language (`library/TrafficSpec/Core/Language/Formula.lean`; `Measure` from `Foundations/Time.lean`)
```lean
inductive Arg
  | var (name : String)      -- a bound variable
  | lit (value : String)     -- an enumeration value, spelled as in the ontology
  | nat (n : Nat)

inductive CmpOp
  | lt | le | eq | ge | gt

inductive Measure
  | time | path

mutual
  /-- A quantity. -/
  inductive Term
    | lit (q : Q) (unit : PUnit')                            -- written through a Units constructor
    | param (name : ParamName)                               -- a reading parameter
    | measure (atom : String) (args : List Arg)              -- a measured atom (Option Q or Option Nat)
    | quantity (concept : String) (args : List Arg) (params : List Term)   -- a Q-valued derived concept
    | distanceWhile (subject : String) (φ : Formula)         -- path length over which φ has held continuously
    | sinceRise (φ : Formula)                                -- time elapsed since φ last became true
    | headingSince (subject : String) (maxStep : Term) (ψ : Formula)   -- the heading change of subject since ψ last became true
    | aggregate (op : AggOp) (var : String) (φ : Formula) (t : Term)   -- op of t over the road users var of the scene satisfying φ
    | add (a b : Term)
    | sub (a b : Term)
    | mul (a b : Term)
    | div (a b : Term)
    | neg (a : Term)
    | abs (a : Term)
    | cond (φ : Formula) (a b : Term)                        -- a where φ holds, b where it does not
  /-- A three-valued statement about the trace at an instant. -/
  inductive Formula
    | tt
    | ff
    | atom (name : String) (args : List Arg) (params : List Term)   -- a Boolean atom; params for tolerances
    | cmp (lhs : Term) (op : CmpOp) (rhs : Term)
    | asm (id : AsmId)
    | intent (id : IntId) (who target : Arg)                 -- the declaration current here: road user `who` intends `id` at region `target`
    | same (a b : Arg)                                        -- the two variables denote the same entity
    | not (φ : Formula)
    | and (φ ψ : Formula)
    | or (φ ψ : Formula)
    | implies (φ ψ : Formula)
    | always (φ : Formula)                                    -- from now to the end of the trace
    | eventually (φ : Formula)                                -- φ here or at some later observation, to the end of the trace
    | until (φ ψ : Formula)                                   -- strong until, future
    | since (φ ψ : Formula)                                   -- past mirror of until
    | holdsFor (m : Measure) (d : Term) (subject : String) (φ : Formula)   -- φ at every observation in the window behind
    | within (m : Measure) (d : Term) (subject : String) (φ : Formula)     -- φ at some observation in the window ahead
    | untilWithin (m : Measure) (d : Term) (subject : String) (φ ψ : Formula)   -- ψ at some observation in the window ahead, φ at every one before it
    | atLast (m : Measure) (d : Term) (subject : String) (ψ φ : Formula)   -- φ at the last observation in the window behind at which ψ held
    | count (edge : Formula) (sinceφ : Formula) (op : CmpOp) (n : Nat)   -- rising edges of `edge` since `sinceφ` became true (start of its latest run)
    | rises (φ : Formula)                                     -- φ here and not at the previous observation
    | definedWhen (pre φ : Formula)                           -- φ where `pre` holds; unknown (undefined) where it does not
    | derived (concept : String) (args : List Arg) (params : List Term)   -- a Boolean derived concept
    | rule (id : String) (map : List (String × String))       -- another rule complied with (not engaged counts as complied)
    | ruleApplies (id : String) (map : List (String × String)) -- another rule engaged (its binders' classes and applicability hold)
    | existsUser (var : String) (φ : Formula)                 -- some road user present in the scene
    | forallUser (var : String) (φ : Formula)
    | existsRegion (kind : Arg) (var : String) (φ : Formula)
    | forallRegion (kind : Arg) (var : String) (φ : Formula)
    | existsDevice (kind : Arg) (var : String) (φ : Formula)
    | forallDevice (kind : Arg) (var : String) (φ : Formula)
end
```
Notes. `Arg.var` names a binder or a quantifier variable; `Arg.lit` an enumeration spelling or an
attribute selector (`"x"`, `"y"`, `"width"`, `"length"`, `"lateral"`, `"longitudinal"`, a side);
`Arg.nat` a count. Quantifiers `existsRegion k v φ`/`forallRegion` range over the scene's structures of
kind `k` (an `Arg.lit` spelling, or a concept's literal formal) or of a kind that refines `k`, and the
structures that may be of it where the source cannot tell; `existsDevice`/`forallDevice` over its
devices of a kind, `existsUser`/`forallUser` over its road users, the bound ones included (`same a b`
excludes the subject); the variable is an `Arg.var` inside `φ`. `rises φ` is φ here and not at the
previous observation; `definedWhen pre φ` is undefined (unknown) where `pre` fails; `Term.sinceRise φ`
the seconds since φ last became true; `Term.headingSince x step ψ` the heading change of `x` since ψ last
became true (zero at the onset, unaffected by ψ turning false; `step` is a time parameter bounding the
integration interval, not a window and not a look-back length); `Term.aggregate op v φ t` the min/max/median/count of `t` over the
road users `v` satisfying φ. `Term.cond φ a b` is `a` where φ holds and `b` where it does not; a
comparison over it is decided wherever both selections decide it alike, so a condition that selects
among bounds is written with it. `holdsFor m d s φ`: φ held at every observation in
the window of length `d` (a `Term`, usually `.param`) behind, measured in time or path of subject `s`:
`m = .time` is the last `d` seconds, `m = .path` the last `d` of distance the subject travelled, so a
window the words state as a distance travelled is a `.path` window;
`within` looks ahead; `atLast m d s ψ φ`: φ at the last observation in the window behind at which ψ held
(false where ψ held nowhere in a covered window). A window that reaches past the start of the trace is unknown (`windowTruncated`),
so a witness of a rule that looks back names `window`. `rule id map` / `ruleApplies id map`: `map` pairs
the composed rule's binder names with this rule's variables.

### What a formula may not say (`Language/RuleEval.lean`, `Language/Formula.lean`, `Language/Concept.lean`)
The static checks a rule and a concept are held to before any trace, and what Core states a formula may not do with the constructors it restricts:
- `Rule.check`: Every defect a rule has before any trace; empty for a rule the evaluator will never report `malformed` or `unboundVariable` on: an empty id; no binder, or one unnamed or named twice; an assumption or intention read but not declared, or an intention id ill-formed; an operationalization bounded by nothing, or by a name that is no atom, primitive or concept; a name no table knows; an atom, measure, primitive or concept given the wrong number of arguments; an unbound variable, or one of the wrong sort where a track, region or device is read (such a position takes a variable, never a spelling or a number; a literal position takes no variable); a spelling no enumeration decodes; a quantifier kind that is not a spelling; a parameter of an atom or a call, or a window's length, that is not a constant term (a literal, a reading parameter, or arithmetic over them); a heading change's step bound that is not a literal or a reading parameter, or a literal one not strictly positive; a declared intention read ahead of the judged observation; the distance travelled since the trace began read inside a search into the past; a composed rule not in the set, or a map that names a variable not bound to a track, misses one of its binders or names one it does not have. `regions` names variables the caller binds to regions: the region formals of a concept's instance, which alone may then have no binder.
- `Concept.check`: Every defect a concept has before any trace: an empty id; a formal or a parameter named twice; a parameter named as a reading's, or a body parameter that is no formal parameter; a literal formal that admits no value; a composed rule or a declared intention in the body (a concept reads neither); a referenced concept unknown, or a reference cycle; and, on every admissible instantiation of its literal formals with its calls expanded, every defect `Rule.check` finds in a formula and a call whose arguments do not fit the callee's formals.
- `Term.headingSince`: The signed heading change (degrees, left positive) of `subject`, integrated from its yaw rate, since ψ last became true: from the latest observation at which ψ rose definitely (false at the observation before, true there), counted from zero at that observation. ψ turning false does not end it, nor does a stop; only the next definite rise of ψ starts it again. Unknown where no such rise is observed with ψ known at every observation since (an onset before the recording, or one an unknown value of ψ could hide), where an interval between consecutive observations from the one before the rise onwards is longer than `maxStep`, or where a yaw rate since the rise is missing. `maxStep` is a literal or a reading parameter, a time, strictly positive: the sampling standard of the integration, not a window and not a bound on how far back the onset may lie.
- `Term.div`: `a / b`, unknown wherever `b` is zero. Its divisor reads no measured atom: a measurement can be zero (a straight way's curvature, a halted road user's speed), so a bound on a ratio is written as a bound on a product (a ratio below a bound is the dividend below the bound times the divisor).
- `ArgSort.literal`: A literal formal is read only where a spelling is expected: the kind of a quantifier, or a literal argument of an atom or a primitive. No operator compares it with a spelling (`same` compares two bound variables), so a body decides alike for every value except through such a reading; notions that differ only by the value are separate concepts.

### The `Rule`, `Binder`, `Operationalization` and `Scenario` values (`Language/Rule.lean`, `Vocab/Params.lean`, `Evidence/Builders.lean`)
```lean
structure Binder where
  name : String
  cls : Formula

structure Rule where
  id : String                                   -- the node id, derived from the law id
  laws : List String                            -- the corpus ids this rule formalizes
  binders : List Binder
  applicability : Formula
  obligation : Formula
  assumptions : List AsmId := []
  intentions : List IntId := []                 -- the declared intentions its formulas read
  operationalizations : List Operationalization := []
  residues : List String := []                  -- what the text says and the rule does not capture
  narrowings : List Narrowing := []             -- readings the coder chose on carried spans
  surrogate : Bool := false

structure Operationalization where
  standard : String            -- the clause's words for the standard
  concepts : List String       -- the `drv.*` and atom ids that bound it (one standard may pair several)
  params : List ParamName      -- the parameters the bound uses
  convention : String          -- where the values come from
  surrogate : Bool := false    -- true when the standard is the whole duty

inductive Verdict
  | violated
  | compliant
  | notApplicable
  | unknown (why : List UnknownReason)

structure Scenario where
  name : String
  rule : String
  trace : Trace
  reading : Reading
  manifest : Manifest
  grounding : List (String × TrackId)
  regions : List (String × RegionId) := []   -- an instance's region formals, each a region of the trace
  expected : Verdict
  window : Option (Timestamp × Timestamp) := none
  boundary : String := ""
```
`AsmId` and `ParamName` are `String`. A witness's `expected` is `.violated`, `.compliant`, `.notApplicable`
or `.unknown []` (compared by tag). `grounding` maps binder names to track ids; `window` is a closed range
of timestamps (milliseconds). `boundary` is set only on a scenario the plan declares a history boundary for:
that witness stays unknown for a window truncated at its trace's start, and for nothing else.

### Concepts (`Language/Concept.lean`): the `Concept` a concept file declares, the `Instance` its witnesses build
```lean
inductive ArgSort
  | track
  | region
  | literal (values : List String)
  | nat

structure ConceptParam where
  name : ParamName
  unit : PUnit'

inductive ConceptBody
  | formula (φ : Formula)
  | quantity (t : Term)

structure Concept where
  id : String                          -- drv.<family>.<name>
  contract : String
  definition : Option String := none   -- the corpus definition the contract quotes, when it has one
  args : List (String × ArgSort)
  params : List ConceptParam
  body : ConceptBody
  residues : List String := []
  narrowings : List Narrowing := []
  supersedes : Option String := none

structure Instance where
  name : String
  concept : String                          -- the concept id
  literals : List (String × String) := []   -- literal formal ↦ spelling
  nats : List (String × Nat) := []
  params : List (String × Term) := []       -- formal parameter ↦ a constant term
  bounds : Option (Term × Term) := none     -- a quantity: the value lies in [lo, hi]
```
A rule calls a concept by its Lean name (the id with `.` → `_`): `.derived "drv_<family>_<name>" args params`
for a formula concept, `Term.quantity "drv_<family>_<name>" args params` for a quantity; `args` fill the
formals in order (a track formal takes a variable bound to a road user, a region formal a variable bound
to a region — the one the caller singles out, bound by its own region quantifier — a literal formal a
spelling among its values, a nat a count; each variable's innermost binding decides its sort, and the
gate checks every call against these sorts), `params` fill the formal parameters in order with constant
terms (`.param "p.…"` of the reading,
or a declared literal). Inside a concept's body every `.var` is a formal or bound in the body and every
`.param` is a formal parameter: a body never names a reading parameter. The call is expanded before
evaluation, so its atoms count as the caller's.

### Concept catalogue (accepted concepts; call by Lean name = id with `.` → `_`)
| id | kind | contract | definition | args | params | reads | calls | planned users | accepted callers |
|---|---|---|---|---|---|---|---|---|---|
| `drv.motion.reverse_travel` | formula | The road user is travelling rearward at the observation: the component of its velocity along the direction its body points is at most the negative of the reverse speed tolerance, a speed the caller sets, so that a rearward component smaller than it is read as none. The concept states the direction of the body's motion relative to the direction it points, at the observation only, and says nothing of how long the rearward motion lasts or where it happens. The whole of it is read from the road user's own velocity and the direction its body points, so no structure region, no device and no control state enters it. Not a stand-in for: the gear selected — a body in a forward gear rolls backwards on a grade and one in reverse stands still — a reversing lamp or any other signal, a halt, a turn, the place the motion happens at, or the component of the velocity along a structure region's designated direction of travel, which is a separate quantity read from the region and says nothing of the direction the body points. |  | u:track | reverse_speed_tolerance (m/s) | kin.heading, kin.velocity | no concept | 0 | 0 |
| `drv.motion.turning` | formula | The road user's heading is changing at the observation: the magnitude of its heading change over the window behind the observation is at least the heading change tolerance, a size the caller sets at the resolution of the source. It is a state the road user is in at each observation of a bending path, in either hand, and it states no direction, no angle reached, no beginning and no place. Not a stand-in for: a completed turn or a manoeuvre recognized from an observed onset — which counts the heading change from that onset and not over a window — a steering input, the curvature of the road, a lane change, or a signal or an intention. |  | u:track | window (s), heading_change_tolerance (deg) | kin.yaw_rate | no concept | 1 | 1 |

### Atom ids (`Vocab/Ontology/Ids.lean`; a manifest, a claim and `Build.manifest` use the id, a formula uses the Lean name = id with `.` → `_`)
`ru.motor_vehicle`, `ru.motorcycle`, `ru.moped`, `ru.bus`, `ru.transit_bus`, `ru.school_bus`, `ru.taxicab`, `ru.tour_bus_or_limousine`, `ru.truck`, `ru.commercial_motor_vehicle`, `ru.trailer_or_combination`, `ru.bicycle`, `ru.electric_bicycle`, `ru.electric_scooter`, `ru.pedestrian`, `ru.pedestrian_with_white_cane_or_guide_animal`, `ru.child`, `ru.emergency_vehicle`, `ru.fire_apparatus`, `ru.official_vehicle`, `ru.rail_vehicle`, `ru.occupant_count`, `ru.rider_posture`, `ru.subject`, `ru.aggregate`, `kin.time`, `kin.position`, `kin.heading`, `kin.velocity`, `kin.speed`, `kin.accel_longitudinal`, `kin.yaw_rate`, `kin.extent`, `kin.steer_angle`, `kin.path_length`, `kin.engine_running`, `kin.parking_brake`, `kin.gear`, `kin.throttle`, `kin.service_brake`, `st.highway`, `st.travel_region`, `st.roadway`, `st.lane`, `st.lane_direction`, `st.lane_adjacency`, `st.lane_connectivity`, `st.lane_enters`, `st.on_way`, `st.entrance_of`, `st.lane_marking`, `st.centre_line`, `st.road_edge`, `st.shoulder`, `st.sidewalk`, `st.median_or_divider`, `st.one_way_roadway`, `st.intersection`, `st.crosswalk`, `st.stop_line`, `st.driveway_or_alley_entrance`, `st.alley`, `st.curvature`, `st.grade`, `st.crest`, `st.sight_distance`, `st.sight_along_way`, `st.railway_crossing`, `st.controlled_access`, `st.elevated_structure`, `st.bicycle_lane_or_path`, `st.reserved_lane`, `st.centre_turn_lane`, `st.turn_lane`, `st.parking_space`, `st.curb_zone`, `st.transit_stop`, `st.safety_zone`, `st.pedestrian_grade_separation`, `st.fire_hydrant`, `st.fire_station_entrance`, `st.roundabout`, `st.lane_width`, `st.region_geometry`, `st.obstruction`, `rel.occupies`, `dev.traffic_signal`, `dev.pedestrian_signal`, `dev.lane_control_signal`, `dev.speed_limit_beacon`, `dev.crossing_warning_signal`, `dev.stop_sign`, `dev.yield_sign`, `dev.speed_limit_sign`, `dev.regulatory_sign`, `dev.zone_sign`, `dev.railway_signal_or_gate`, `dev.temporary_traffic_control`, `dev.human_direction`, `dev.governs`, `dev.position`, `dev.inoperative`, `sig.turn_indicator`, `sig.brake_lamp`, `sig.hazard`, `sig.headlamp`, `sig.position_lamp`, `sig.compression_brake`, `sig.warning_lamp`, `sig.siren`, `sig.horn`, `sig.hand_signal`, `sig.door_open`, `env.darkness`, `env.precipitation`, `env.wet_road`, `env.ice_or_snow`, `env.visibility`, `env.civil_time`, `rel.centre_distance`, `rel.surface_gap`, `rel.ahead_behind_in_lane`, `rel.longitudinal_overlap`, `rel.oncoming`, `rel.same_direction`, `rel.bearing`, `rel.contact`, `rel.visible`

Names a formula may use in `Formula.atom` (`Semantics.boolAtomNames`):
```
"ru_subject", "ru_aggregate", "ru_rider_posture", "ru_rider_posture_on_seat", "ru_rider_posture_standing_on_deck",
    "ru_rider_posture_holding_another_vehicle", "ru_rider_posture_stunt", "ru_emergency_vehicle_kind",
    "ru_official_vehicle_kind", "kin_engine_running", "kin_parking_brake",
    "st_road_edge_paved", "st_shoulder_paved", "st_median_or_divider_opening",
    "st_crosswalk_marked", "st_reserved_lane_class", "st_turn_lane_side", "st_parking_space_designation",
    "st_curb_zone_kind", "st_curb_zone_colour", "st_obstruction_kind", "st_lane_adjacency", "st_lane_adjacency_left",
    "st_lane_adjacency_right", "st_lane_connectivity", "st_lane_enters", "st_on_way", "st_entrance_of", "st_lane_marking", "st_lane_marking_left", "st_lane_marking_right",
    "rel_occupies", "dev_traffic_signal_shows", "dev_traffic_signal_uncovered", "dev_pedestrian_signal_state",
    "dev_pedestrian_signal_countdown", "dev_lane_control_signal_state", "dev_speed_limit_beacon_flashing",
    "dev_crossing_warning_signal_active", "dev_speed_limit_sign_kind", "dev_regulatory_sign_code",
    "dev_zone_sign_kind", "dev_zone_sign_end", "dev_railway_signal_or_gate_lights",
    "dev_railway_signal_or_gate_gate", "dev_railway_signal_or_gate_bell", "dev_human_direction_role",
    "dev_human_direction_indication", "dev_governs", "dev_inoperative",
    "sig_turn_indicator", "sig_brake_lamp", "sig_hazard", "sig_headlamp", "sig_position_lamp",
    "sig_warning_lamp", "sig_siren", "sig_horn", "sig_hand_signal",
    "sig_door_open", "sig_compression_brake", "env_darkness", "env_precipitation", "env_wet_road",
    "env_ice_or_snow", "rel_ahead_behind_in_lane", "rel_ahead_in_lane", "rel_behind_in_lane", "rel_oncoming",
    "rel_same_direction", "rel_bearing", "rel_contact", "rel_visible"
```
Names a formula may use in `Term.measure` (`Semantics.measureNames`):
```
"kin_time", "kin_position", "kin_heading", "kin_velocity", "kin_speed", "kin_accel_longitudinal",
    "kin_yaw_rate", "kin_extent", "kin_steer_angle", "kin_path_length", "kin_gear", "kin_throttle", "kin_service_brake", "ru_occupant_count",
    "ru_rider_posture_hands_on_controls", "ru_electric_bicycle_class", "st_lane_direction", "st_lane_adjacency",
    "st_lane_adjacency_ordinal", "st_lane_adjacency_count", "st_lane_width", "st_curvature", "st_grade",
    "st_sight_distance", "st_sight_along_way", "st_parking_space_angle", "st_region_geometry", "st_region_geometry_distance",
    "dev_position", "dev_speed_limit_sign_value", "env_visibility", "env_civil_time",
    "rel_centre_distance", "rel_surface_gap", "rel_longitudinal_overlap", "rel_bearing"
```
Argument kinds per position (`Semantics.atomArgSorts`; `none` marks a literal position such as a side or a selector):
```lean
def atomArgSorts (name : String) : Option (List (Option EntityKind)) :=
  let t := some EntityKind.track; let r := some EntityKind.region; let d := some EntityKind.device
  match name with
  | "rel_occupies" => some [t, r]
  | "ru_aggregate" => some [t, none]
  | "dev_governs" => some [d, r]
  | "st_region_geometry_distance" | "st_sight_along_way" => some [t, r]
  | "st_lane_adjacency" => some [r, none, r]
  | "st_lane_adjacency_left" | "st_lane_adjacency_right" | "st_lane_connectivity" | "st_lane_enters" | "st_on_way"
  | "st_entrance_of" => some [r, r]
  | "st_lane_marking" => some [r, none, none, none]
  | "rel_oncoming" | "rel_same_direction" | "rel_ahead_behind_in_lane" | "rel_ahead_in_lane"
  | "rel_behind_in_lane" | "rel_contact" | "rel_visible" | "rel_centre_distance" | "rel_longitudinal_overlap" => some [t, t]
  | "rel_surface_gap" | "rel_bearing" => some [t, t, none]
  | n =>
    if !knowsAtom n then none
    else if n.startsWith "env_" || n == "kin_time" then some []
    else if n.startsWith "ru_" || n.startsWith "kin_" || n.startsWith "sig_" then some [t, none, none]
    else if n.startsWith "st_" then some [r, none, none]
    else if n.startsWith "dev_" then some [d, none, none]
    else none

```

### Atom accessors (`Vocab/Atoms.lean`): the name a formula uses, its arguments, and the scene field it reads
```lean
def ru_aggregate (s : Scene) (x : TrackId) (members : List RoadUserClass) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def kin_heading (s : Scene) (x : TrackId) : Option Vec := (s.user x).bind (·.kin.heading)
def kin_velocity (s : Scene) (x : TrackId) : Option Vec := (s.user x).bind (·.kin.velocity)
def kin_yaw_rate (s : Scene) (x : TrackId) : Option Q := (s.user x).bind (·.kin.yawRate)
def isKind (s : Scene) (r : RegionId) (k : StructureKind) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def st_highway (s : Scene) (r : RegionId) : Option Bool := isKind s r .highway
def st_on_way (s : Scene) (r : RegionId) : Option (List RegionId) := (s.structure? r).bind (·.ways)
def st_intersection (s : Scene) (r : RegionId) : Option Bool := isKind s r .intersection
def st_crosswalk (s : Scene) (r : RegionId) : Option Bool := isKind s r .crosswalk
def st_crosswalk_marked (s : Scene) (r : RegionId) : Option Bool := (s.structure? r).bind (·.marked)
def footprint (s : Scene) (x : TrackId) : Option (List Vec) := do
def regionsOfKind (s : Scene) (k : StructureKind) : List RegionId :=  -- (body continues in Vocab/Atoms.lean)
def regionCandidates (s : Scene) (k : StructureKind) : List RegionId :=  -- (body continues in Vocab/Atoms.lean)
def rel_occupies (s : Scene) (x : TrackId) (r : RegionId) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def rel_occupies_regions (s : Scene) (x : TrackId) : Option (List RegionId) :=  -- (body continues in Vocab/Atoms.lean)
def devKind (s : Scene) (d : DeviceId) (k : DeviceKind) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def devicesOfKind (s : Scene) (k : DeviceKind) : List DeviceId :=  -- (body continues in Vocab/Atoms.lean)
def deviceCandidates (s : Scene) (k : DeviceKind) : List DeviceId :=  -- (body continues in Vocab/Atoms.lean)
```

(The accessor and primitive tables are cut to what the record claims and what its concepts read; every other name is off limits for this task, and the whole tables are in the files named.)

### Primitives (`Vocab/Primitives.lean`): Lean signature (the parameters after the tracks are the formula's `params`, in order), contract, formula arity
```lean
```
Argument kinds (`Primitives.argSorts`):
```lean
def argSorts (name : String) : Option (List (Option EntityKind)) :=
  let t := some EntityKind.track
  match name with
  | "prim_heading_change" => some [t]
  | "prim_closest_approach_within" | "prim_closest_approach_time" | "prim_closest_approach_distance" => some [t, t]
  | "prim_conditions_hold" => some [some EntityKind.device, t]
  | "prim_region_lateral_offset" => some [t, some EntityKind.region]
  | "prim_region_offset_along" => some [t, some EntityKind.region, some EntityKind.region]
  | _ => none

```
A Boolean primitive is `.derived "prim_x" args params`; a `QR`-valued one is `Term.quantity "prim_x" args params`.

### Enumeration spellings (`Vocab/Ontology/*.lean`): `Arg.lit` spelling → Lean constructor (the spelling for `existsRegion (.lit "kind")` and literal arguments, the constructor for `Build.*` and class lists)
- `DeviceKind`: `traffic_signal`→`.trafficSignal`, `pedestrian_signal`→`.pedestrianSignal`, `lane_control_signal`→`.laneControlSignal`, `speed_limit_beacon`→`.speedLimitBeacon`, `crossing_warning_signal`→`.crossingWarningSignal`, `stop_sign`→`.stopSign`, `yield_sign`→`.yieldSign`, `speed_limit_sign`→`.speedLimitSign`, `regulatory_sign`→`.regulatorySign`, `zone_sign`→`.zoneSign`, `railway_signal_or_gate`→`.railwaySignalOrGate`, `temporary_traffic_control`→`.temporaryTrafficControl`, `human_direction`→`.humanDirection`
- `ArrowDir`: `left`→`.left`, `right`→`.right`, `straight`→`.straight`, `u_turn`→`.uTurn`
- `SignalIndication`: `circular_green`→`.circularGreen`, `circular_yellow`→`.circularYellow`, `circular_red`→`.circularRed`, `flashing_red`→`.flashingRed`, `flashing_yellow`→`.flashingYellow`, `dark`→`.dark`, `unknown`→`.unknown`, `green_arrow(<ArrowDir>)`→`.greenArrow`, `yellow_arrow(<ArrowDir>)`→`.yellowArrow`, `red_arrow(<ArrowDir>)`→`.redArrow`, `flashing_yellow_arrow(<ArrowDir>)`→`.flashingYellowArrow`
- `PedSignalState`: `walk`→`.walk`, `dont_walk_flashing`→`.dontWalkFlashing`, `dont_walk_steady`→`.dontWalkSteady`, `dark`→`.dark`
- `LaneControlState`: `green_down_arrow`→`.greenDownArrow`, `red_x`→`.redX`, `yellow_x`→`.yellowX`, `dark`→`.dark`, `yellow_arrow(<ArrowDir>)`→`.yellowArrow`
- `SpeedSignKind`: `maximum`→`.maximum`, `minimum`→`.minimum`, `structure_maximum`→`.structureMaximum`, `zone`→`.zone`
- `SignCode`: `no_left_turn`→`.noLeftTurn`, `no_right_turn`→`.noRightTurn`, `no_u_turn`→`.noUTurn`, `no_straight`→`.noStraight`, `one_way`→`.oneWay`, `keep_right`→`.keepRight`, `do_not_enter`→`.doNotEnter`, `wrong_way`→`.wrongWay`, `no_stopping`→`.noStopping`, `no_standing`→`.noStanding`, `no_parking`→`.noParking`, `angle_parking`→`.angleParking`, `right_turn_only`→`.rightTurnOnly`, `entrance`→`.entrance`, `exit`→`.exit`, `closed_to_traffic`→`.closedToTraffic`, `exempt_crossing`→`.exemptCrossing`, `abandoned_crossing`→`.abandonedCrossing`, `shoulder_use_permitted`→`.shoulderUsePermitted`, `bicycles_prohibited`→`.bicyclesProhibited`, `pedestrians_prohibited`→`.pedestriansProhibited`, `nonmotorized_prohibited`→`.nonmotorizedProhibited`, `motor_vehicles_prohibited`→`.motorVehiclesProhibited`, `truck_route`→`.truckRoute`, `no_trucks`→`.noTrucks`
- `ZoneKind`: `school`→`.school`, `school_crossing`→`.schoolCrossing`, `pedestrian_safety`→`.pedestrianSafety`, `temporary_traffic_control`→`.temporaryTrafficControl`, `no_passing`→`.noPassing`, `high_occupancy_lane`→`.highOccupancyLane`, `heavy_vehicle_lane`→`.heavyVehicleLane`, `speed_zone`→`.speedZone`, `narrow_highway`→`.narrowHighway`, `hazardous_place`→`.hazardousPlace`, `parking_restricted`→`.parkingRestricted`, `trail`→`.trail`
- `RailLights`: `flashing`→`.flashing`, `dark`→`.dark`
- `GateState`: `up`→`.up`, `lowering`→`.lowering`, `down`→`.down`, `raising`→`.raising`, `none`→`.none`
- `HumanRole`: `police_officer`→`.policeOfficer`, `flagger`→`.flagger`, `school_crossing_guard`→`.schoolCrossingGuard`, `railroad_flagger`→`.railroadFlagger`
- `HumanIndication`: `stop`→`.stop`, `proceed`→`.proceed`, `slow`→`.slow`, `turn(<ArrowDir>)`→`.turn`
- `RoadUserClass`: `motor_vehicle`→`.motorVehicle`, `motorcycle`→`.motorcycle`, `moped`→`.moped`, `bus`→`.bus`, `transit_bus`→`.transitBus`, `school_bus`→`.schoolBus`, `taxicab`→`.taxicab`, `tour_bus_or_limousine`→`.tourBusOrLimousine`, `truck`→`.truck`, `commercial_motor_vehicle`→`.commercialMotorVehicle`, `trailer_or_combination`→`.trailerOrCombination`, `bicycle`→`.bicycle`, `electric_bicycle`→`.electricBicycle`, `electric_scooter`→`.electricScooter`, `pedestrian`→`.pedestrian`, `pedestrian_with_white_cane_or_guide_animal`→`.pedestrianWithWhiteCaneOrGuideAnimal`, `child`→`.child`, `emergency_vehicle`→`.emergencyVehicle`, `fire_apparatus`→`.fireApparatus`, `official_vehicle`→`.officialVehicle`, `rail_vehicle`→`.railVehicle`
- `EmergencyKind`: `police`→`.police`, `fire`→`.fire`, `ambulance`→`.ambulance`, `other`→`.other`
- `OfficialKind`: `tow`→`.tow`, `utility`→`.utility`, `highway_maintenance`→`.highwayMaintenance`, `incident_management`→`.incidentManagement`, `regulatory_agency`→`.regulatoryAgency`, `coroner`→`.coroner`, `armored_car`→`.armoredCar`, `municipal`→`.municipal`, `other`→`.other`
- `TurnIndicatorState`: `off`→`.off`, `left`→`.left`, `right`→`.right`
- `HeadlampState`: `off`→`.off`, `low_beam`→`.lowBeam`, `high_beam`→`.highBeam`
- `LampColour`: `red`→`.red`, `blue`→`.blue`, `amber`→`.amber`, `white`→`.white`
- `LampMode`: `flashing`→`.flashing`, `rotating`→`.rotating`, `steady`→`.steady`
- `Facing`: `front`→`.front`, `rear`→`.rear`, `side`→`.side`
- `HandSignal`: `no_signal`→`.noSignal`, `left`→`.left`, `right`→`.right`, `stop_or_slow`→`.stopOrSlow`, `re_enter`→`.reEnter`
- `DoorSide`: `traffic`→`.traffic`, `curb`→`.curb`
- `StructureKind`: `highway`→`.highway`, `travel_region`→`.travelRegion`, `roadway`→`.roadway`, `lane`→`.lane`, `centre_line`→`.centreLine`, `road_edge`→`.roadEdge`, `shoulder`→`.shoulder`, `sidewalk`→`.sidewalk`, `median_or_divider`→`.medianOrDivider`, `one_way_roadway`→`.oneWayRoadway`, `intersection`→`.intersection`, `crosswalk`→`.crosswalk`, `stop_line`→`.stopLine`, `driveway_or_alley_entrance`→`.drivewayOrAlleyEntrance`, `alley`→`.alley`, `crest`→`.crest`, `railway_crossing`→`.railwayCrossing`, `controlled_access`→`.controlledAccess`, `elevated_structure`→`.elevatedStructure`, `bicycle_lane_or_path`→`.bicycleLaneOrPath`, `reserved_lane`→`.reservedLane`, `centre_turn_lane`→`.centreTurnLane`, `turn_lane`→`.turnLane`, `parking_space`→`.parkingSpace`, `curb_zone`→`.curbZone`, `transit_stop`→`.transitStop`, `safety_zone`→`.safetyZone`, `pedestrian_grade_separation`→`.pedestrianGradeSeparation`, `fire_hydrant`→`.fireHydrant`, `fire_station_entrance`→`.fireStationEntrance`, `roundabout`→`.roundabout`, `obstruction`→`.obstruction` (abstract, read by a formula only and never a structure's label or unobserved kind: `travel_region`)
- `MarkingType`: `none`→`.none`, `broken`→`.broken`, `solid`→`.solid`, `double_solid`→`.doubleSolid`, `solid_broken`→`.solidBroken`, `dotted`→`.dotted`, `curb`→`.curb`
- `MarkingColour`: `white`→`.white`, `yellow`→`.yellow`, `other`→`.other`
- `ReservedClass`: `high_occupancy`→`.highOccupancy`, `bus`→`.bus`, `heavy_vehicle`→`.heavyVehicle`, `other`→`.other`
- `TurnSide`: `left`→`.left`, `right`→`.right`
- `ParkingDesignation`: `general`→`.general`, `disabled`→`.disabled`, `disabled_side_lift`→`.disabledSideLift`, `access_aisle`→`.accessAisle`, `municipal`→`.municipal`, `charging`→`.charging`
- `CurbZoneKind`: `passenger_loading`→`.passengerLoading`, `freight_loading`→`.freightLoading`, `tour_bus_loading`→`.tourBusLoading`, `restricted_parking`→`.restrictedParking`, `bus_stop`→`.busStop`, `taxicab_stand`→`.taxicabStand`, `fire_lane`→`.fireLane`, `no_stopping`→`.noStopping`, `no_parking`→`.noParking`
- `CurbColour`: `red`→`.red`, `yellow`→`.yellow`, `white`→`.white`, `blue`→`.blue`, `gray`→`.gray`, `none`→`.none`
- `ObstructionKind`: `debris`→`.debris`, `excavation`→`.excavation`, `hose`→`.hose`, `barrier`→`.barrier`, `stalled_vehicle_wreckage`→`.stalledVehicleWreckage`, `sidewalk_fixture`→`.sidewalkFixture`, `mail_drop_box`→`.mailDropBox`, `other`→`.other`

### The world a witness builds (`Vocab/World.lean`)
```lean
structure Kin where
  position : Option Vec := none          -- m
  heading : Option Vec := none           -- unit vector
  velocity : Option Vec := none          -- m/s
  speed : Option Q := none               -- m/s
  accelLongitudinal : Option Q := none   -- m/s², signed along heading
  yawRate : Option Q := none             -- deg/s
  extent : Option (Q × Q × Q) := none    -- half-length, half-width, half-height, m
  steerAngle : Option Q := none          -- deg
  pathLength : Option Q := none          -- m since the start of the trace
  engineRunning : Option Bool := none    -- propulsion available
  parkingBrake : Option Bool := none     -- parking brake set
  gear : Option Int := none              -- negative reverse, zero neutral, positive forward
  throttle : Option Q := none            -- fraction of full travel applied
  serviceBrake : Option Q := none        -- fraction of full travel applied

structure Posture where
  onSeat : Option Bool := none
  handsOnControls : Option Nat := none
  standingOnDeck : Option Bool := none
  holdingAnotherVehicle : Option Bool := none
  stunt : Option Bool := none

structure WarningLamp where
  colour : LampColour
  mode : LampMode
  facing : Facing

structure Signals where
  turnIndicator : Option TurnIndicatorState := none
  brakeLamp : Option Bool := none
  hazard : Option Bool := none
  headlamp : Option HeadlampState := none
  positionLamp : Option Bool := none
  warningLamps : Option (List WarningLamp) := none
  siren : Option Bool := none
  horn : Option Bool := none
  handSignal : Option HandSignal := none
  doorsOpen : Option (List DoorSide) := none
  compressionBrake : Option Bool := none

structure RoadUser where
  track : TrackId
  classes : Option (List RoadUserClass) := none   -- a user may be several (a school bus is a bus)
  /-- Classes the source cannot tell for this user: membership in them is unknown, not false. -/
  unobservedClasses : List RoadUserClass := []
  emergencyKind : Option EmergencyKind := none
  officialKind : Option OfficialKind := none
  eBikeClass : Option Nat := none
  occupants : Option Nat := none
  posture : Posture := {}
  kin : Kin := {}
  sig : Signals := {}
  sightAlongWay : Option (List (RegionId × Q)) := none   -- per way, m

structure LaneInfo where
  direction : Option Vec := none
  leftNeighbour : Option RegionId := none
  rightNeighbour : Option RegionId := none
  ordinalFromLeft : Option Nat := none
  countInDirection : Option Nat := none
  leadsTo : Option (List RegionId) := none
  entersIntersection : Option RegionId := none   -- the intersection this carrier is an approach to
  markingLeft : Option (MarkingType × MarkingColour) := none
  markingRight : Option (MarkingType × MarkingColour) := none
  width : Option Q := none

structure Structure where
  id : RegionId
  kind : StructureKind
  /-- Kinds the source cannot tell for this region: whether it is one of them is unknown, not false. -/
  unobservedKinds : List StructureKind := []
  position : Option Vec := none             -- reference point (point-like structures)
  boundary : Option (List Vec) := none      -- polygon, for regions
  lane : Option LaneInfo := none
  paved : Option Bool := none
  opening : Option Bool := none
  marked : Option Bool := none
  curvature : Option Q := none              -- 1/m
  grade : Option Q := none                  -- ratio
  sightDistance : Option Q := none          -- m
  ways : Option (List RegionId) := none     -- the highway regions it lies on
  /-- For a stop line or a crosswalk: the carriers whose entrance into an intersection it marks.
      `entranceObserved` says the list is complete; where it is not, which carriers the line marks is
      unknown and `entranceOf` is empty. -/
  entranceOf : List RegionId := []
  entranceObserved : Bool := false
  reservedClass : Option ReservedClass := none
  turnSide : Option TurnSide := none
  parkingAngle : Option Q := none           -- deg
  designation : Option ParkingDesignation := none
  curbKind : Option CurbZoneKind := none
  curbColour : Option CurbColour := none
  obstructionKind : Option ObstructionKind := none

structure CivilTime where
  year : Nat
  month : Nat
  day : Nat
  weekday : Nat        -- 0 = Monday … 6 = Sunday
  minuteOfDay : Nat    -- 0 … 1439

structure TimeWindow where
  weekdays : List Nat := []
  calendarClass : Option AsmId := none
  startMinute : Nat := 0
  endMinute : Nat := 1440

structure Conditions where
  windows : List TimeWindow := []
  minOccupancy : Option Nat := none
  durationLimit : Option Q := none          -- s
  vehicleClass : Option RoadUserClass := none
  whenChildrenPresent : Bool := false

structure Device where
  id : DeviceId
  kind : DeviceKind
  /-- Kinds the source cannot tell for this device: whether it is one of them is unknown, not false. -/
  unobservedKinds : List DeviceKind := []
  position : Option Vec := none
  governs : List RegionId := []
  /-- Whether the source observes which regions the device governs; where it does not, `governs`
      is empty and no region is decidedly governed or not. -/
  governsObserved : Bool := true
  indications : Option (List SignalIndication) := none
  uncovered : Option Bool := none
  inoperative : Option Bool := none
  pedState : Option PedSignalState := none
  countdown : Option Bool := none
  laneControl : Option LaneControlState := none
  flashing : Option Bool := none
  active : Option Bool := none
  speedValue : Option Q := none                     -- m/s
  speedKind : Option SpeedSignKind := none
  code : Option SignCode := none
  zoneKind : Option ZoneKind := none
  isEnd : Option Bool := none
  conditions : Option Conditions := none
  railLights : Option RailLights := none
  gate : Option GateState := none
  bell : Option Bool := none
  humanRole : Option HumanRole := none
  humanIndication : Option HumanIndication := none

structure Env where
  darkness : Option Bool := none
  precipitation : Option Bool := none
  wetRoad : Option Bool := none
  iceOrSnow : Option Bool := none
  visibility : Option Q := none              -- m
  civilTime : Option CivilTime := none

structure MeasuredRelation where
  a : TrackId
  b : TrackId
  centreDistance : Option Q := none
  surfaceGap : Option (Q × Q) := none        -- nearest-point gap along, across a's heading; ≥ 0
  aAheadOfB : Option Bool := none
  longitudinalOverlap : Option Q := none     -- shared length of the projections on a's heading
  oncoming : Option Bool := none
  sameDirection : Option Bool := none
  bearing : Option Vec := none               -- b relative to a, in a's frame (long, lat)
  contact : Option Bool := none
  visible : Option Bool := none              -- b in a's line of sight

structure Scene where
  t : Timestamp
  subject : Option TrackId := none
  users : List RoadUser := []
  structures : List Structure := []
  devices : List Device := []
  /-- The tracks whose occupancy was observed: for them every region not listed in `occupies` is
      not occupied; for any other track `rel.occupies` is unknown. -/
  occupancyObserved : List TrackId := []
  occupies : List (TrackId × RegionId) := []
  relations : List MeasuredRelation := []
  env : Env := {}
  assumptions : List (AsmId × Bool) := []
  intents : List DeclaredIntent := []
  links : List (TrackId × TrackId) := []
```
Every `Option` field is `none` when unobserved, and an atom that reads a `none` field is unknown
(`absentAtom`), never false. A witness that wants an atom decided sets the field it reads.

### Units constructors (`Foundations/Units.lean`, namespace `Units`; every quantity in a witness or a declared literal is written through one)
```lean
def metres (n : Int) : Q := Q.ofInt n
def centimetres (n : Int) : Q := Q.mk' n 100
def millimetres (n : Int) : Q := Q.mk' n 1000
def micrometres (n : Int) : Q := Q.mk' n 1000000
def kilometres (n : Int) : Q := Q.ofInt (n * 1000)
def inches (n : Int) : Q := Q.mk' (n * 254) 10000          -- 25.4 mm exactly
def feet (n : Int) : Q := Q.mk' (n * 3048) 10000           -- 304.8 mm exactly
def yards (n : Int) : Q := Q.mk' (n * 9144) 10000
def miles (n : Int) : Q := Q.mk' (n * 1609344) 1000        -- 1609.344 m exactly
def seconds (n : Int) : Q := Q.ofInt n
def milliseconds (n : Int) : Q := Q.mk' n 1000
def minutes (n : Int) : Q := Q.ofInt (n * 60)
def hours (n : Int) : Q := Q.ofInt (n * 3600)
def metresPerSecond (n : Int) : Q := Q.ofInt n
def micrometresPerSecond (n : Int) : Q := Q.mk' n 1000000
def kmh (n : Int) : Q := Q.mk' (n * 1000) 3600              -- exactly 5/18 m/s per km/h
def mph (n : Int) : Q := Q.mk' (n * 44704) 100000           -- 0.44704 m/s exactly
def perMetre (n : Int) : Q := Q.ofInt n
def metresPerSecondSq (n : Int) : Q := Q.ofInt n
def micrometresPerSecondSq (n : Int) : Q := Q.mk' n 1000000
def degrees (n : Int) : Q := Q.ofInt n
def millidegrees (n : Int) : Q := Q.mk' n 1000
def ratio (a : Int) (b : Nat) : Q := Q.mk' a b
def percent (n : Int) : Q := Q.mk' n 100
```
`Q` is an exact rational: `Q.zero`, `Q.ofInt n`, `Q.mk' num den`, `Q.add/sub/mul/div/neg/half`; `Vec := Q × Q`, +x east, +y north. A `Term.lit q <unit>` carries one of the unit tags `.metre`, `.second`, `.metrePerSecond`, `.metrePerSecondSq`, `.degree`, `.degreePerSecond`, `.perMetre`, `.ratio`, `.count`.

### Builders (`Evidence/Builders.lean`, namespace `Build`; witnesses are built with these and record-update syntax `{ x with field := some v }`)
```lean
-- Cardinal unit headings in the world frame (+x east, +y north).
def east : Vec
def west : Vec
def north : Vec
def south : Vec
def scale (h : Vec) (k : Q) : Vec
-- A road user with position, heading and speed; velocity follows the heading, path length is the caller's (cumulative) figure, extents are half-length/half-width/half-height.
def user (track : TrackId) (classes : List RoadUserClass) (pos : Vec) (heading : Vec) (speed : Q) (halfExtent : Q × Q × Q) (pathLength : Option Q := none) : RoadUser
-- A road user of which only the position (and classes) was observed.
def sparseUser (track : TrackId) (classes : List RoadUserClass) (pos : Vec) : RoadUser
def withSignals (u : RoadUser) (f : Signals → Signals) : RoadUser
def withKin (u : RoadUser) (f : Kin → Kin) : RoadUser
-- A measured relation from `a` to `b`, with the measured fields the source supplies.
def relation (a b : TrackId) (f : MeasuredRelation → MeasuredRelation := id) : MeasuredRelation
def withRelations (s : Scene) (rs : List MeasuredRelation) : Scene
-- A region of a kind with a polygon boundary.
def region (id : RegionId) (kind : StructureKind) (boundary : List Vec) : Structure
-- An axis-aligned rectangular region from two corners.
def rect (id : RegionId) (kind : StructureKind) (x0 y0 x1 y1 : Q) : Structure
-- A lane with its direction and neighbours.
def lane (id : RegionId) (boundary : List Vec) (direction : Vec) (left right : Option RegionId := none) (ordinal count : Option Nat := none) (leadsTo : Option (List RegionId) := none) (enters : Option RegionId := none) : Structure
def point (id : RegionId) (kind : StructureKind) (pos : Vec) : Structure
def device (id : DeviceId) (kind : DeviceKind) (governs : List RegionId) (pos : Option Vec := none) : Device
def signal (id : DeviceId) (governs : List RegionId) (shows : List SignalIndication) : Device
def sign (id : DeviceId) (kind : DeviceKind) (governs : List RegionId) : Device
def speedLimit (id : DeviceId) (governs : List RegionId) (value : Q) (kind : SpeedSignKind) : Device
def zoneSign (id : DeviceId) (governs : List RegionId) (kind : ZoneKind) (isEnd : Bool) (conditions : Option Conditions := none) : Device
-- Occupancy from the geometry: every user inside every region whose boundary contains its position.
def occupancyFromGeometry (users : List RoadUser) (structures : List Structure) : List (TrackId × RegionId)
-- A scene; occupancy is derived from geometry unless given.
def scene (t : Timestamp) (subject : Option TrackId) (users : List RoadUser) (structures : List Structure) (devices : List Device) (occupies : Option (List (TrackId × RegionId)) := none) (env : Env := {}) (assumptions : List (AsmId × Bool) := []) (intents : List DeclaredIntent := []) : Scene
-- A trace from a scene generator over instants `t0, t0 + dt, …` (`dt` in seconds).
def trace (n : Nat) (t0 : Timestamp) (dt : Q) (f : Nat → Timestamp → Scene) : Trace
-- Repeat the first and last scenes for `before`/`after` seconds at spacing `dt`, so that windows at the ends of the interesting part are covered rather than truncated.
def pad (τ : Trace) (before after dt : Q) : Trace
def masked (m : Manifest) (τ : Trace) : Trace
-- A manifest that observes every atom except the listed ids (for a `blind` witness).
def manifest (absent : List String := []) (gap : Q := Q.zero) : Manifest
-- The operators that look back from the observation they judge, by the tag their truncation at the start of a trace carries: only these leave a history-boundary witness unknown.
def pastOps : List String
```
`Build.scene` derives occupancy from geometry (a user is in every region whose polygon contains its
position) unless `occupies` is given; `occupancyObserved` is every user built. `Build.trace n t0 dt f`
calls `f k t` for `k < n` at `t = t0 + k·dt` (dt in seconds, timestamps in milliseconds).
`Build.manifest ["<atom id>", …]` observes every atom except the listed ids: the `blind` witness.

### Contracts

| id | contract |
|---|---|
| `asm.inside_city_limits` | the map or trace declares that the highway the road user occupies at the observation lies inside the territorial limits of a city |
| `drv.motion.reverse_travel` | The road user is travelling rearward at the observation: the component of its velocity along the direction its body points is at most the negative of the reverse speed tolerance, a speed the caller sets, so that a rearward component smaller than it is read as none. The concept states the direction of the body's motion relative to the direction it points, at the observation only, and says nothing of how long the rearward motion lasts or where it happens. The whole of it is read from the road user's own velocity and the direction its body points, so no structure region, no device and no control state enters it. Not a stand-in for: the gear selected — a body in a forward gear rolls backwards on a grade and one in reverse stands still — a reversing lamp or any other signal, a halt, a turn, the place the motion happens at, or the component of the velocity along a structure region's designated direction of travel, which is a separate quantity read from the region and says nothing of the direction the body points. |
| `drv.motion.turning` | The road user's heading is changing at the observation: the magnitude of its heading change over the window behind the observation is at least the heading change tolerance, a size the caller sets at the resolution of the source. It is a state the road user is in at each observation of a bending path, in either hand, and it states no direction, no angle reached, no beginning and no place. Not a stand-in for: a completed turn or a manoeuvre recognized from an observed onset — which counts the heading change from that onset and not over a window — a steering input, the curvature of the road, a lane change, or a signal or an intention. |
| `kin.heading` | direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown |
| `kin.velocity` | velocity vector |
| `kin.yaw_rate` | rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres |
| `rel.occupies` | a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure) |
| `ru.aggregate` | membership of a legal aggregate: the atom's literal argument is an aggregate id, `<definition id>::<term>` for the posted definition that applies, or `<law id>:<span>::<term>` for a definition the law itself makes, and the run's reading classifies every road-user class under that id by the definition's words as included, excluded (the definition leaves it out), covered (the definition admits its members only as members of named included classes, which a road user carries beside it, so its own label adds no membership evidence) or unresolved; true when the user carries an included class, unknown when no included class holds and the user carries an unresolved class or an included or unresolved class it might carry is unobserved, false otherwise: a covered or excluded class decides nothing **Not a stand-in for:** a named road-user class for which the applicable definitions and the run's representation decisions permit its own class atom — that class's own atom; an admitted aggregate stays an aggregate even when it contains only one class; a relational role such as who drives or controls a vehicle — never membership; nor a role the text describes by conduct (responding, overtaking) — a role is a derived concept |
| `st.crosswalk` | marked crossing, or the unmarked prolongation of sidewalks at an intersection (`st.intersection`); **marked** attribute |
| `st.highway` | the entire public way between its boundary lines, including sidewalks and shoulders **Not a stand-in for:** the roadway |
| `st.intersection` | the region where two roadways meet, bounded by the prolongation of their edges; a junction where an alley meets another way (a street, road, highway or alley) is no intersection but a `st.driveway_or_alley_entrance` **Not a stand-in for:** a crosswalk or a stop line — a stop before the crossing is earlier than a stop before the intersection **Refines:** `st.travel_region` |
| `st.on_way` | relation: the public way (a `highway` region) a structure region lies on — a lane, roadway, shoulder, crosswalk, stop line, median or any other part of it; an intersection lies on every way that meets there **Not a stand-in for:** nearness to a way (`st.region_geometry`), or the lane a lane leads into (`st.lane_connectivity`) |

| parameter | value | unit | convention |
|---|---|---|---|
| `p.heading_change_noise_floor` | 5.0 | deg | Resolution convention: the heading change over the recognition window below which an integrated yaw reading is indistinguishable from straight running at the acquisition profile's sampling rate; it names the source's resolution only and no size of turn. |
| `p.reverse_speed_tolerance` | 0.1 | m/s | Rearward-motion convention: the magnitude of the velocity component along the body's heading below which a rearward reading is indistinguishable from measurement noise in a standing vehicle, set at the noise floor of vehicle speed measurement. |
| `p.turn_recognition_window` | 3.0 | s | Manoeuvre-recognition convention: the window behind an observation over which a yaw rate is integrated to tell a bending path from straight running at a junction, taken from the duration of a low-speed corner manoeuvre. |

Admitted aggregates the node claims (a witness's road user is a member when it carries an included class; one carrying only an unresolved class makes the atom unknown):

- `DEF-NRS-484A-320::vehicle`: included ru.bus, ru.commercial_motor_vehicle, ru.emergency_vehicle, ru.fire_apparatus, ru.moped, ru.motor_vehicle, ru.motorcycle, ru.official_vehicle, ru.school_bus, ru.taxicab, ru.tour_bus_or_limousine, ru.trailer_or_combination, ru.transit_bus, ru.truck; unresolved (none)

The catalogue is `results/demo22-1109-0108/reading.json` (read-only). Values enter a witness's geometry only: a `forbid` scene breaks the bound by a clear margin, a `permit` scene keeps it by one.

Acquisition standard: profile `carla_scene_graph`. Every `headingSince` step bound in a rule is exactly `.param "p.heading_since_step_carla_scene_graph"`, the operator's reviewed parameter: name it as it is, never propose it or a value for it.

An accepted node of this library, `NRS_484B_253_o2` — its header records its reading, its formulas use only claimed names, its witnesses are built scenes:

```lean
-- library/TrafficSpec/Rules/NRS_484B/NRS_484B_253_o2.lean
/-
  NRS_484B_253_o2 — NRS-484B-253

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    sib1 (sibling): The driver of a vehicle within an intersection intending to turn to the left shall yield the right-of-way to any vehicle approaching from the opposite direction which is within the intersection or so close thereto as to constitute an immediate hazard,
    c1 (condition): but such driver, having so yielded
    c2 (condition): and having given a signal when and as required,
    c3 (condition): may make such left turn
    s1 (subject): and the drivers of all other vehicles approaching the intersection from the opposite direction
    ob1 (obligation): shall yield the right-of-way to the vehicle making the left turn.

  Elements (span → atoms, derived):
    c2: atoms ['sig.turn_indicator', 'sig.hand_signal'], derived []
    c3: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.left_turn']
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.travel_region', 'st.lane_enters', 'st.lane_direction', 'st.intersection'], derived []
    ob1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'rel.surface_gap', 'rel.contact', 'kin.speed', 'prim.closest_approach_within', 'prim.closest_approach_distance'], derived []

  Compositions (span → node, as, map):
    c1: NRS_484B_253_o1 as compliance map {'v': 't'}

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  HOW EACH SPAN IS WRITTEN

  s1 (the subject, `v`): the class of `v` is the admitted aggregate, written as the atom
  `ru_aggregate` with the aggregate id. "all other vehicles" is `.not (.same t v)` against the
  road user the duty is owed to. "approaching the intersection from the opposite direction" is the
  ontology's own reading: a carrier `cv` of kind `st.travel_region` that `v` occupies
  (`rel_occupies`) whose entrance end is the junction `j` (`st_lane_enters`), with that carrier's
  designated direction (`st_lane_direction`, read by component) opposed to the direction of the
  carrier `ct` by which the turning vehicle reached `j` — their dot product at or below the
  negative of `p.same_direction_cosine_tolerance`. Both quantifiers range over `travel_region` as
  the record names it; the junction `j` is quantified over `st.intersection`. The one thing the
  carriers are held apart from is the junction itself (`.not (.same cv j)`, `.not (.same ct j)`):
  by `st.lane_enters` a carrier is an approach to an intersection and enters one intersection at
  most, so the region entered is not one of the regions entering it. That is the ontology's own
  distinction, not a narrowing of the words: a junction region records no approach of its own, so
  without it a source that leaves occupancy unobserved would report the junction's missing lane
  record rather than the missing occupancy.

  c3 (the manoeuvre): `drv.motion.left_turn` on the turning vehicle, with the reviewed step bound
  of the run's acquisition profile, `p.turn_onset_yaw_rate` and `p.left_turn_angle`, conjoined
  with `rel_occupies` of a region of kind `st.intersection`, so the turn read is the one made in
  the junction the subject approaches.

  c2 (the signal): a left indication — `sig_turn_indicator` at `left` or `sig_hand_signal` at
  `left` — at some observation in the window `p.turn_signal_advance_window` behind the recognition
  of the turn. The recognition is `.rises` of the concept; the span is therefore read at that
  recognition, through `atLast` over the same window, and the "some observation in the window
  behind it" is `.not (.holdsFor … (.not …))`. Consequence, stated here because the language
  offers no unbounded past that stays decided: `atLast` finds the recognition only while it lies
  within `p.turn_signal_advance_window` behind the judged observation, so the duty is read over
  that stretch after the turn is recognized; an unbounded search into the past (`since`) is
  unknown wherever the recorded trace holds no recognition, which would leave a scene with a
  signal-less turn undecided instead of unengaged.

  c1 (having so yielded): the composition, `.rule "NRS_484B_253_o1" [("v", "t")]`, in the
  applicability as the record's `compliance` directs. Nothing of that rule is inlined.

  ob1 (the duty): "shall yield the right-of-way" is DEF-NRS-484A-210's precedence, read as the
  record's narrowing states, in the two observable ways the span's atoms give: the subject's body
  does not come into contact with the turning vehicle (`rel_contact`), and the clearance between
  them is held at or above `p.yield_min_clearance` — measured at the observation between the
  nearest points of the two bodies (`rel_surface_gap`) and, where their centres approach within
  `p.yield_conflict_horizon` (`prim_closest_approach_within`), as the centre distance at that
  closest approach (`prim_closest_approach_distance`). The duty is owed to every road user the
  applicability's own selection picks out, so that selection — the junction, the turn, the
  signal, the composed compliance and the opposed carriers — is written again in the obligation:
  the two formulas bind their own regions.

  The two readings this file chose on ob1 are declared as narrowings below.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_253_o2

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The road user the duty is owed to, and the regions the formulas quantify over. -/
def tV : Arg := .var "t"
def jV : Arg := .var "j"
def cvV : Arg := .var "cv"
def ctV : Arg := .var "ct"

/-- The admitted aggregate of the node's class element, by its id. -/
def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pLeftTurnAngle : Term := .param "p.left_turn_angle"
def pSameDirectionCosineTolerance : Term := .param "p.same_direction_cosine_tolerance"
def pTurnOnsetYawRate : Term := .param "p.turn_onset_yaw_rate"
def pTurnSignalAdvanceWindow : Term := .param "p.turn_signal_advance_window"
def pYieldConflictHorizon : Term := .param "p.yield_conflict_horizon"
def pYieldMinClearance : Term := .param "p.yield_min_clearance"

def zeroMetres : Term := .lit Q.zero .metre
def zeroSpeed : Term := .lit Q.zero .metrePerSecond

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, aggVehicle] []

/-- c3: the turning vehicle has turned to the left, by the concept of the catalogue. -/
def leftTurnMade : Formula :=
  .derived "drv_motion_left_turn" [tV]
    [pHeadingSinceStepCarlaSceneGraph, pTurnOnsetYawRate, pLeftTurnAngle]

/-- c3: that turn is the one made in the junction `j`, whose region the vehicle's footprint
    overlaps. -/
def turnsLeftInJunction : Formula :=
  .and (.atom "st_intersection" [jV] [])
    (.and (.atom "rel_occupies" [tV, jV] []) leftTurnMade)

/-- c2: a left indication, by the turn indicator or by the arm. -/
def leftIndication : Formula :=
  .or (.atom "sig_turn_indicator" [tV, .lit "left"] [])
      (.atom "sig_hand_signal" [tV, .lit "left"] [])

/-- c2: the signal given when and as required — a left indication at some observation in the
    window `p.turn_signal_advance_window` behind the recognition of the turn. -/
def signalGivenForTurn : Formula :=
  .atLast .time pTurnSignalAdvanceWindow "t" (.rises leftTurnMade)
    (.not (.holdsFor .time pTurnSignalAdvanceWindow "t" (.not leftIndication)))

/-- s1: a carrier's designated direction, by component. -/
def laneDirX (c : Arg) : Term := .measure "st_lane_direction" [c, .lit "x"]
def laneDirY (c : Arg) : Term := .measure "st_lane_direction" [c, .lit "y"]

/-- s1: the two carriers' designated directions are opposed. -/
def opposedCarriers : Formula :=
  .cmp (.add (.mul (laneDirX cvV) (laneDirX ctV)) (.mul (laneDirY cvV) (laneDirY ctV)))
    .le (.neg pSameDirectionCosineTolerance)

/-- s1: the subject approaches `j` through a carrier of its own whose designated direction is
    opposed to that of the carrier by which the turning vehicle reached `j`. -/
def approachesFromOppositeDirection : Formula :=
  .existsRegion (.lit "travel_region") "cv"
    (.and (.atom "st_travel_region" [cvV] [])
      (.and (.not (.same cvV jV))
        (.and (.atom "rel_occupies" [vV, cvV] [])
          (.and (.atom "st_lane_enters" [cvV, jV] [])
            (.existsRegion (.lit "travel_region") "ct"
              (.and (.atom "st_travel_region" [ctV] [])
                (.and (.not (.same ctV jV))
                  (.and (.atom "rel_occupies" [tV, ctV] [])
                    (.and (.atom "st_lane_enters" [ctV, jV] []) opposedCarriers)))))))))

/-- The road user the duty is owed to: another vehicle of the aggregate making, in the junction
    `j` the subject approaches from the opposite direction, the signalled left turn it has
    yielded for (c1, c2, c3, s1). -/
def turningVehicle : Formula :=
  .and (.not (.same tV vV))
    (.and (.atom "ru_aggregate" [tV, aggVehicle] [])
      (.existsRegion (.lit "intersection") "j"
        (.and turnsLeftInJunction
          (.and signalGivenForTurn
            (.and (.rule "NRS_484B_253_o1" [("v", "t")])
                  approachesFromOppositeDirection)))))

/-- Applicability: c1 (condition): but such driver, having so yielded; c2 (condition): and having given a signal when and as required,; c3 (condition): may make such left turn -/
def applicability : Formula := .existsUser "t" turningVehicle

/-- ob1: the subject is itself proceeding. -/
def subjectProceeding : Formula := .cmp (.measure "kin_speed" [vV]) .gt zeroSpeed

/-- ob1: the gap between the nearest points of the two bodies at this observation. -/
def nearestPointGap : Term := .measure "rel_surface_gap" [vV, tV]

/-- ob1: the centres approach each other within the horizon. -/
def centresApproach : Formula :=
  .derived "prim_closest_approach_within" [vV, tV] [pYieldConflictHorizon]

/-- ob1: the centre distance at that closest approach. -/
def closestApproachDistance : Term :=
  .quantity "prim_closest_approach_distance" [vV, tV] [pYieldConflictHorizon]

/-- ob1: the subject grants precedence to the turning vehicle. -/
def grantsPrecedence : Formula :=
  .and (.not (.atom "rel_contact" [vV, tV] []))
    (.or (.not subjectProceeding)
      (.and (.cmp nearestPointGap .ge pYieldMinClearance)
        (.or (.not centresApproach)
             (.cmp closestApproachDistance .ge pYieldMinClearance))))

/-- Obligation: ob1 (obligation): shall yield the right-of-way to the vehicle making the left turn. -/
def obligation : Formula := .forallUser "t" (.implies turningVehicle grantsPrecedence)

def rule : Rule :=
  { id := "NRS_484B_253_o2"
    laws := ["NRS-484B-253"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "ob1"
          why := "Granting precedence is read as a duty on the subject's own proceeding: where the subject's speed is zero it grants precedence by standing, and the clearance bounds are read on a subject that is itself moving. Contact is forbidden whether or not the subject moves."
          kind := "reading" }
      , { span := "ob1"
          why := "The clearance the span's atoms measure is bounded in both of the ways they give, each at p.yield_min_clearance: the gap between the nearest points of the two bodies at the observation (rel.surface_gap), and, where the centres approach within p.yield_conflict_horizon, the centre distance at that closest approach (prim.closest_approach_distance), which is undefined where they do not approach and then bounds nothing."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_253_o2

```

```lean
-- library/TrafficSpecWitness/NRS_484B/NRS_484B_253_o2.lean
/-
  Witnesses for NRS_484B_253_o2.

  THE GEOMETRY. One junction, a five-metre square at the origin (region 10), where a north-south
  street meets an east-west street. Region 20 is the northbound approach (x from 0 to 2.5 m, south
  of the junction), its designated direction north, its entrance end that junction; region 21 is
  the southbound approach (x from -2.5 to 0 m, north of the junction), its direction south, its
  entrance end the same junction. The source records those two approaches and the junction, and
  no further carrier: the westbound way the van's turn leads into is outside what it reports.

  THE BODIES. Track 1 is the subject, a car 4 m by 1.8 m coming south down region 21 (in one
  witness a bicycle instead). Track 2 is the van, 4.8 m by 2 m, which comes north up region 20 at
  4 m/s, stands from t = 3950 ms with its reference point at (1.3, -1.8) m — in the junction
  mouth, its footprint overlapping both its approach carrier and the junction throughout — and
  from t = 4000 ms swings to the left at 30 deg/s: one and a half degrees between consecutive
  scenes, written as an exact rational rotation of its heading, so that heading and yaw rate say
  the same thing at every scene. The heading change accumulated since that onset passes
  forty-five degrees at t = 5500 ms, where its left turn is recognized, and reaches ninety
  degrees by the end. Track 3, where a witness has one, is a car that came south down region 21
  and stopped in the junction, across the van's turn.

  Every body here either stands or runs straight at a constant speed, its position advancing by
  the speed of the scene over the interval before it, so that no scene asserts a motion its own
  figures deny.

  THE INSTANTS. Every trace is 141 scenes at 50 ms, t = 0 to 7000 ms — the sampling period of the
  run's acquisition profile, so the concept's integration is never short of a sample, and long
  enough that every three-second window behind a judged instant is covered. Each witness names
  the instants it speaks about, t = 6000 to 7000 ms: the second and a half after the turn is
  recognized. Before the yaw onset the turn concept is unknown, as its contract says: no onset is
  observed yet.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_253_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_253_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n
def degps (n : Int) : Q := Units.degrees n
/-- A point of the world frame, in centimetres: every coordinate below is exact. -/
def pt (x y : Int) : Vec := (cm x, cm y)

/-- The rotation to the left by one step of the van's turn: the one and a half degrees its yaw
    rate of 30 deg/s makes over the 50 ms before a scene, as an exact rational rotation. -/
def stepCos : Q := Units.ratio 9996573 10000000
def stepSin : Q := Units.ratio 261769 10000000

/-- Keep a coordinate to a tenth of a micrometre, so the sixty steps of the turn stay small
    exact rationals; the angle between consecutive headings is unaffected at this resolution. -/
def trim (q : Q) : Q := Units.ratio ((q.num * 10000000) / Int.ofNat q.den) 10000000

def rotLeft (v : Vec) : Vec :=
  (trim (Q.sub (Q.mul v.1 stepCos) (Q.mul v.2 stepSin)),
   trim (Q.add (Q.mul v.1 stepSin) (Q.mul v.2 stepCos)))

/-- `n` steps of that rotation. -/
def rotN : Nat → Vec → Vec
  | 0, v => v
  | n + 1, v => rotLeft (rotN n v)

-- Binders ↦ tracks: v ↦ 1

/-- The junction: a five-metre square where the two streets meet. -/
def junction : Structure := Build.rect 10 .intersection (cm (-250)) (cm (-250)) (cm 250) (cm 250)

/-- The northbound approach: the carrier by which the van reaches the junction. -/
def northboundApproach : Structure :=
  Build.lane 20 [pt 0 (-10000), pt 250 (-10000), pt 250 (-250), pt 0 (-250)]
    Build.north (enters := some 10)

/-- The southbound approach: the carrier the subject occupies, its direction the opposed one. -/
def southboundApproach : Structure :=
  Build.lane 21 [pt (-250) 250, pt 0 250, pt 0 10000, pt (-250) 10000]
    Build.south (enters := some 10)

def roads : List Structure := [junction, northboundApproach, southboundApproach]

/-- A clear, dry afternoon. -/
def weather : Env :=
  { darkness := some false, precipitation := some false, wetRoad := some false,
    iceOrSnow := some false, visibility := some (m 300) }

/-- What the source declares about the van's plan at the junction. -/
def vanIntent (v : Bool) : DeclaredIntent :=
  { vehicle := 2, target := 10,
    values := [("int.turn_left", v), ("int.left_turn", v), ("int.turn_to_the_left", v)] }

/-- The subject car: 4 m by 1.8 m, running straight south, no signal of its own. -/
def car (ycm : Int) (xcm : Int) (speed : Q) : RoadUser :=
  Build.withKin
    (Build.withSignals
      (Build.user 1 [.motorVehicle] (pt xcm ycm) Build.south speed (m 2, cm 90, cm 75))
      (fun s => { s with turnIndicator := some .off, handSignal := some .noSignal }))
    (fun k => { k with yawRate := some Q.zero })

/-- The subject in the witness where it is a bicycle, which the aggregate does not include. -/
def cycle (ycm : Int) (xcm : Int) (speed : Q) : RoadUser :=
  Build.withKin
    (Build.withSignals
      (Build.user 1 [.bicycle] (pt xcm ycm) Build.south speed (cm 90, cm 30, cm 90))
      (fun s => { s with turnIndicator := some .off, handSignal := some .noSignal }))
    (fun k => { k with yawRate := some Q.zero })

/-- The van's reference point: north up the approach at 4 m/s, then standing in the junction
    mouth from t = 3950 ms. -/
def vanPos (k : Nat) : Vec :=
  if k ≤ 79 then pt 130 (-1760 + 20 * (k : Int)) else pt 130 (-180)

def vanSpeed (k : Nat) : Q := if k ≤ 79 then mps 4 else Q.zero

/-- The van's heading: north until it stands, then one and a half degrees further to the left at
    every scene from t = 4000 ms, the rotation its yaw rate makes over the interval before it. -/
def vanHeading (k : Nat) : Vec := if k ≤ 79 then Build.north else rotN (k - 79) Build.north

/-- The van's yaw rate: the onset of the turn at t = 4000 ms, held to the end of the trace. -/
def vanYaw (k : Nat) : Q := if k ≤ 79 then Q.zero else degps 30

/-- The van, with the indication it shows. -/
def vanAt (k : Nat) (ind : TurnIndicatorState) (hand : HandSignal) : RoadUser :=
  Build.withKin
    (Build.withSignals
      (Build.user 2 [.motorVehicle] (vanPos k) (vanHeading k) (vanSpeed k) (cm 240, m 1, cm 95))
      (fun s => { s with turnIndicator := some ind, handSignal := some hand }))
    (fun kk => { kk with yawRate := some (vanYaw k) })

/-- The van's stated occupancy: its approach carrier throughout, and the junction from the moment
    its nose crosses the junction mouth. -/
def vanOcc (k : Nat) : List (TrackId × RegionId) :=
  if k ≤ 43 then [(2, 20)] else [(2, 20), (2, 10)]

/-- A southbound car's stated occupancy, from the height of its reference point (centimetres):
    its approach carrier while its rear is north of the junction mouth, the junction while its
    nose is south of it. -/
def southboundOcc (track : TrackId) (ycm : Int) : List (TrackId × RegionId) :=
  (if ycm ≥ 50 then [(track, 21)] else []) ++
  (if ycm ≤ 450 then (if ycm ≥ -450 then [(track, 10)] else []) else [])

/-- The vehicle that rolled up to the junction mouth and stands there, its nose settling three
    degrees to the left: an onset of turning is observed, and the heading change accumulated
    since it stays far below the turn angle, so it makes no left turn. -/
def twitchVehicle (k : Nat) : RoadUser :=
  Build.withKin
    (Build.withSignals
      (Build.user 2 [.motorVehicle] (vanPos k)
        (if k ≤ 79 then Build.north else rotN (min (k - 79) 2) Build.north) (vanSpeed k)
        (cm 240, m 1, cm 95))
      (fun s => { s with turnIndicator := some .off, handSignal := some .noSignal }))
    (fun kk => { kk with yawRate := some (if k ≤ 79 then Q.zero else if k ≤ 81 then degps 30 else Q.zero) })

/-- A car that came south down the approach at 4 m/s and stopped in the junction, where the van's
    turn crosses it; its nose settles three degrees to the left, so that whether it makes a left
    turn of its own is decided and not unknown. -/
def crossedVehicle (k : Nat) : RoadUser :=
  Build.withKin
    (Build.withSignals
      (Build.user 3 [.motorVehicle] (pt (-100) (if k ≤ 70 then 1500 - 20 * (k : Int) else 100))
        (if k ≤ 79 then Build.south else rotN (min (k - 79) 2) Build.south)
        (if k ≤ 70 then mps 4 else Q.zero) (m 2, cm 90, cm 75))
      (fun s => { s with turnIndicator := some .off, handSignal := some .noSignal }))
    (fun kk => { kk with yawRate := some (if k ≤ 79 then Q.zero else if k ≤ 81 then degps 30 else Q.zero) })

def crossedY (k : Nat) : Int := if k ≤ 70 then 1500 - 20 * (k : Int) else 100

/-- A scene of a witness: the bodies, the roads, the stated occupancy and the declarations. -/
def sceneOf (t : Timestamp) (users : List RoadUser) (occ : List (TrackId × RegionId))
    (intents : List DeclaredIntent) : Scene :=
  Build.scene t (some 1) users roads [] (some occ) weather [] intents

/-- 141 scenes at the acquisition profile's 50 ms, t = 0 to 7000 ms. -/
def traceOf (f : Nat → Timestamp → Scene) : Trace := Build.trace 141 0 (Units.milliseconds 50) f

/-- The subject braking well short of the junction: 4 m/s, then one metre per second. -/
def clearCarY (k : Nat) : Int :=
  let i : Int := k
  if k ≤ 90 then 3400 - 20 * i else 1600 - 5 * (i - 90)
def clearCarSpeed (k : Nat) : Q := if k ≤ 90 then mps 4 else mps 1

/-- `forbid` (violated): A van within a junction has yielded to the opposing stream, shows its left indicator through the two seconds before its turn is recognized, and turns left. The subject car occupies the opposing approach lane entering the same junction and drives on into the van's path, the two bodies touching. -/
def forbidTrace : Trace :=
  traceOf fun k t =>
    let y : Int := 3590 - 25 * (k : Int)
    sceneOf t [car y (-100) (mps 5), vanAt k .left .noSignal]
      (southboundOcc 1 y ++ vanOcc k) [vanIntent false]

/-- `permit` (compliant): The same junction and the same signalled, yielded left turn by the van. The subject car brakes on its approach and stays more than ten metres clear of the van throughout, no closest approach within the horizon coming near the clearance bound. -/
def permitTrace : Trace :=
  traceOf fun k t =>
    sceneOf t [car (clearCarY k) (-120) (clearCarSpeed k), vanAt k .left .noSignal]
      (southboundOcc 1 (clearCarY k) ++ vanOcc k) [vanIntent false]

/-- `idle` (not_applicable): The subject car occupies the opposing approach lane of a junction in which no vehicle is making a left turn at all: no road user raises the duty, so the rule is not engaged. -/
def idleTrace : Trace :=
  traceOf fun k t =>
    sceneOf t [car (clearCarY k) (-120) (clearCarSpeed k), twitchVehicle k]
      (southboundOcc 1 (clearCarY k) ++ vanOcc k) [vanIntent false]

/-- `blind` (unknown): A van makes a signalled left turn in the junction the subject approaches, but the source does not report whether the van's footprint overlaps the junction region, so whether the turn is the one made in that intersection is unknown. -/
def blindTrace : Trace := permitTrace

/-- `branch_1` (not_applicable): The van turns left in the junction and has yielded to the opposing stream, but its indicator stays off and it gives no arm signal in the window behind the recognition of the turn: the weaker fact -- a turn made without the signal the words require -- leaves the other drivers' duty unraised, and the rule is not engaged. -/
def branch_1Trace : Trace :=
  traceOf fun k t =>
    sceneOf t [car (clearCarY k) (-120) (clearCarSpeed k), vanAt k .off .noSignal]
      (southboundOcc 1 (clearCarY k) ++ vanOcc k) [vanIntent false]

/-- `branch_2` (not_applicable): The van signals left and turns, but it did not comply with its own duty to yield under the first node of this section: it turned across an oncoming vehicle that was within the junction. Having not so yielded, it raises no duty on the other drivers. -/
def branch_2Trace : Trace :=
  traceOf fun k t =>
    sceneOf t [car (clearCarY k) (-120) (clearCarSpeed k), vanAt k .left .noSignal,
               crossedVehicle k]
      (southboundOcc 1 (clearCarY k) ++ vanOcc k ++ southboundOcc 3 (crossedY k))
      [vanIntent true]

/-- `branch_3` (compliant): The van gives no indicator but signals the turn with its arm, and
    turns. The subject car has stopped on its approach well short of the junction: standing, it
    grants precedence. -/
def branch_3Trace : Trace :=
  traceOf fun k t =>
    let y : Int := if k ≤ 100 then 2600 - 20 * (k : Int) else 600
    sceneOf t [car y (-120) (if k ≤ 100 then mps 4 else Q.zero), vanAt k .off .left]
      (southboundOcc 1 y ++ vanOcc k) [vanIntent false]

/-- `branch_4` (violated): The same signalled turn. The subject car holds 8 m/s down the middle of
    its approach, twenty metres short of the van: the bodies are far apart, but the closest
    approach their velocities predict within the horizon is under two metres. -/
def branch_4Trace : Trace :=
  traceOf fun k t =>
    let y : Int := 6800 - 40 * (k : Int)
    sceneOf t [car y (-30) (mps 8), vanAt k .left .noSignal]
      (southboundOcc 1 y ++ vanOcc k) [vanIntent false]

/-- `branch_5` (violated): The same signalled turn. The subject car creeps on until it is less
    than half a metre from the standing van's nose without touching it: their centres do not
    approach within the horizon, and the gap between the nearest points of the two bodies is
    below the clearance. -/
def branch_5Trace : Trace :=
  traceOf fun k t =>
    let i : Int := k
    let y : Int := if k ≤ 119 then 1400 - 10 * i else 210 - 2 * (i - 119)
    sceneOf t [car y (-180) (if k ≤ 119 then mps 2 else Units.micrometresPerSecond 400000),
               vanAt k .left .noSignal]
      (southboundOcc 1 y ++ vanOcc k) [vanIntent false]

/-- `branch_6` (compliant): The same signalled turn. The subject car comes down the far side of
    its approach at 4 m/s: the centres do approach within the horizon, and the closest approach
    stays above the clearance, as does the gap between the bodies. -/
def branch_6Trace : Trace :=
  traceOf fun k t =>
    let y : Int := 3350 - 20 * (k : Int)
    sceneOf t [car y (-200) (mps 4), vanAt k .left .noSignal]
      (southboundOcc 1 y ++ vanOcc k) [vanIntent false]

/-- `branch_7` (not_applicable): The road user on the opposing approach is a bicycle, which the
    aggregate of DEF-NRS-484A-320 does not include: the subject of this duty is a vehicle, so the
    rule is not engaged. -/
def branch_7Trace : Trace :=
  traceOf fun k t =>
    let y : Int := 2000 - 10 * (k : Int)
    sceneOf t [cycle y (-120) (mps 2), vanAt k .left .noSignal]
      ([(1, 21)] ++ vanOcc k) [vanIntent false]

/-- `branch_8` (violated): The van gives no indicator and signals the turn with its arm alone, and
    turns. The subject car holds 8 m/s down the middle of its approach: the closest approach their
    velocities predict within the horizon is under two metres, so it does not grant precedence to
    the vehicle whose arm signal raised the duty. -/
def branch_8Trace : Trace :=
  traceOf fun k t =>
    let y : Int := 6800 - 40 * (k : Int)
    sceneOf t [car y (-30) (mps 8), vanAt k .off .left]
      (southboundOcc 1 y ++ vanOcc k) [vanIntent false]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := some (6000, 7000)) : Scenario :=
  { name := name
    rule := "NRS_484B_253_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .violated ]

end TrafficSpecWitness.NRS_484B_253_o2

```

```lean
-- library/TrafficSpec/Rules/NRS_484B/NRS_484B_113_2.lean (as written by the harness)
/-
  NRS_484B_113_2 — NRS-484B-113-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle:
    s2 (obligation): Shall not back into an intersection, on or over a crosswalk, or around a
    s3 (condition): street
    s4 (condition): corner.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['st.intersection', 'st.crosswalk', 'rel.occupies'], derived ['drv.motion.reverse_travel']
    s4: atoms ['st.intersection', 'st.highway', 'st.on_way', 'rel.occupies'], derived ['drv.motion.turning']

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_113_2

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingChangeNoiseFloor : Term := .param "p.heading_change_noise_floor"
def pReverseSpeedTolerance : Term := .param "p.reverse_speed_tolerance"
def pTurnRecognitionWindow : Term := .param "p.turn_recognition_window"

def zeroMetres : Term := .lit Q.zero .metre

-- TODO(code): class formulas, applicability and obligation — from the node's elements,
-- operationalizations and compositions, using only the claimed names. `.tt` is the placeholder.

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .tt  -- TODO

/-- Applicability: s3 (condition): street; s4 (condition): corner. -/
def applicability : Formula := .tt  -- TODO

/-- Obligation: s2 (obligation): Shall not back into an intersection, on or over a crosswalk, or around a -/
def obligation : Formula := .tt  -- TODO

def rule : Rule :=
  { id := "NRS_484B_113_2"
    laws := ["NRS-484B-113-2"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.inside_city_limits"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_113_2

```

```lean
-- library/TrafficSpecWitness/NRS_484B/NRS_484B_113_2.lean (as written by the harness)
/-
  Witnesses for NRS_484B_113_2.

  TODO(code): describe the geometry once built — the carriageway, the bodies, the instants; every
  figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_113_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_113_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: v ↦ 1

/-- `forbid` (violated): A car stops just short of a four-way junction, selects reverse and then — having overshot — reverses the other way: at one observation its velocity has a rearward component of 1.5 m/s along its heading and its footprint first overlaps the junction region. It has backed into an intersection. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `permit` (compliant): The same car reverses 10 m along a straight stretch of roadway midway between two junctions to leave a parking bay. Through the whole reverse its footprint overlaps no intersection and no crosswalk, and it occupies no region where two highways meet, so no limb of the prohibition is met. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `idle` (not_applicable): A pedal cycle propelled by human power, which the vehicle definition leaves out, is wheeled backwards over a marked crossing at a junction. No vehicle is bound and the rule does not engage. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `blind` (unknown): The forbid scene with the source declaring road-user velocity absent: the junction, the footprint overlap and its rise are recorded, but whether the car's motion was rearward along its heading cannot be read, so the prohibition is unknown rather than satisfied. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `branch_1` (violated): A van reverses out of a loading bay and its footprint comes to overlap a marked crossing laid across the roadway away from any junction, its rearward speed 1 m/s. It has backed on or over a crosswalk. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `branch_2` (violated): A car reverses through the corner of a junction of two highways inside a city, the trace declaring the city-limits assumption true: while its footprint overlaps the junction its heading change over the window behind exceeds the resolution, so it is turning, and its motion is rearward throughout. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_113_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated ]

end TrafficSpecWitness.NRS_484B_113_2

```

Run exactly this command, nothing more and nothing else:

```
python -m harness gate --run_id demo22-1109-0108 --node_id NRS_484B_113_2
```

It prints the verdict and its details. The verdicts on your files: SCOPE_VIOLATION, BUILD_FAIL, UNSOUND, CHECK_FAIL, UNANCHORED_VARIABLE, DECLARATION_MISMATCH, SCOPE_NARROWED, UNEXPRESSED, UNCLAIMED_ATOM, UNUSED_CLAIM, BARE_LITERAL, WITNESS_FAIL, VACUOUS, PARAM_MISMATCH, GATE_TIMEOUT, OK. `INFRA` is not one: the toolchain or the run did not let the gate judge your files. Budget: 6 runs; the harness re-runs the gate itself after you stop, on the files as they are then.


## Access

- You **edit** `/local-scratch2/sma407/scratch_core/launch/remote/pipeline/traffic-spec-agent/library/TrafficSpec/Rules/NRS_484B/NRS_484B_113_2.lean` and `/local-scratch2/sma407/scratch_core/launch/remote/pipeline/traffic-spec-agent/library/TrafficSpecWitness/NRS_484B/NRS_484B_113_2.lean` with the Edit and Write tools, and write
  `task_result.md` (and, when you report a concept, `dependency_defect.json`) in your working
  directory. Nothing else is writable.
- You **may read**, with the Read tool and by absolute path, the Core files under `/local-scratch2/sma407/scratch_core/launch/remote/pipeline/traffic-spec-agent/library/TrafficSpec/Core`
  when a question is not answered by the surface above (a primitive's exact reading of a field, a
  tolerance's sense). Read the one file that answers it; do not page through Core to re-derive
  what the surface already states. Core is frozen: you never edit it, and you never work around
  it. Nothing else is readable: not the harness, not other nodes' files beyond the example above,
  not the readings, the ontology or the law corpus. The gate is the interface to the harness; the
  node is the interface to the law.
- The **shell runs exactly one command**, the gate command below, as written: it runs from your
  working directory, so it needs no `cd`. Any other command — `cat`, `sed`, `grep`, `lake`,
  `python`, a redirection, a second command after `&&` — is denied and wastes a turn. If the
  gate's behaviour surprises you, report it in `task_result.md`; do not re-implement the gate.

## How evaluation reads a built scene

- Three values. An atom whose scene field is `none` is **unknown**, never false; a formula over
  an unknown atom is unknown unless another operand decides it (`and` with a false, `or` with a
  true). `idle` therefore needs a decided-false applicability, not an unobserved one; `blind`
  needs the masked atom to be the one that decides.
- `Build.user` sets position, heading, velocity, speed and extent; every other field
  (`sig`, `posture`, `occupants`, …) is set with `withSignals`/`withKin` or `{ u with … }`.
  `Build.scene` derives occupancy from the polygons unless `occupies` is given; a body across two
  regions is stated, since a reference point lies in one polygon.
- A binder is grounded to a track by `grounding`; a quantifier ranges over the scene's regions,
  devices or users of the kind named. A region that must exist for a leaf to speak is built.
- `holdsFor`/`since`/`once`-shaped lookbacks are truncated at the trace start and report unknown
  there: pad the trace (`Build.pad`) or set `window` to the instants the witness speaks about.
- The episode verdict aggregates the instants: violated if any instant is violated, else unknown
  if any is unknown, else compliant if any is compliant, else not applicable. A `permit` witness
  with one violated instant fails, and one with an unknown instant reports unknown.
- The rule's `manifest` in a witness is `Build.manifest` (all observed) or
  `Build.manifest ["<atom id>", …]` (those absent) — the `blind` witness masks the node's
  `masked` ids and nothing else.

## Hard rules

1. **Two files.** Edit `/local-scratch2/sma407/scratch_core/launch/remote/pipeline/traffic-spec-agent/library/TrafficSpec/Rules/NRS_484B/NRS_484B_113_2.lean` and `/local-scratch2/sma407/scratch_core/launch/remote/pipeline/traffic-spec-agent/library/TrafficSpecWitness/NRS_484B/NRS_484B_113_2.lean` only; their paths and the namespace
   `TrafficSpec.Rules.NRS_484B_113_2` are derived from the node id and are not yours to choose. Declare
   every definition with `def`, never `private def`: each file has its own namespace, and every
   part of a rule or a witness stays reachable to the tools that inspect it.
2. **The rule declares what the node declares.** `laws`, `binders` (names, order), `assumptions`,
   `intentions`, `operationalizations`, `residues`, `surrogate` are the skeleton's; leave them. A residue is the
   plan's: words nothing carries. Where the record leaves the writing of a span the node carries
   open, you choose only among meanings its words already allow, and you declare each such choice
   — the formulas state the span more narrowly than its words — as a **narrowing**
   `{ span := "<span id>", why := "<why>", kind := "reading" }` in `narrowings`, and the header
   comment explains it. Where the span's words cannot be stated at
   all — no atom denotes them (`kind := "no_atom"`) or the language has no operator for them
   (`kind := "no_operator"`) — you declare that instead of a reading: the gate returns the node
   as `UNEXPRESSED` for the repair session to withdraw the span as a gap or re-map it, and a
   second such declaration on the same span files the gap with your words; a reading written
   around a missing operator is not a narrowing. Where the record carries a gap on a span, the
   plan doubts the atoms it maps that span to: write the span with them if they carry its words,
   and otherwise declare `no_atom` or `no_operator` on it, which files the plan's gap at once.
   `no_atom` means no atom of the surface can carry the words. Words that an atom of the surface
   can carry, but which the node does not claim, are a defect of the node's mapping, whether or not
   the record carries a gap on the span: you never declare `no_atom` on them and never write them
   with that atom; the node is wrong, and you report it. The gate holds every narrowing to a span of the
   node's duty or its standards; a span that decides when the rule applies (a trigger, subject,
   condition or exception) is never narrowed, nor written with a weaker fact than the qualified one
   the record states: it is carried as the node maps it, or the node is wrong and you report it. Your narrowings are kept on the rule's record and shown to every later planning and repair
   session; a choice written only in prose is lost. `narrowings` holds only the readings you chose: the record's own
   narrowings, its observable readings included, are the plan's and are never restated there.
3. **Formulas use only claimed names.** Every atom, primitive and concept in `applicability`, the
   binder classes and `obligation` is claimed by an element or operationalization of the node,
   and every claimed name is used. Arguments are the node's binders, quantifier variables, or
   enumeration spellings from the Core surface. A claim of an aggregate is written as the
   atom `ru_aggregate` with the binder and the aggregate's id (what follows `=` in the claim)
   as its literal argument: the id, never the classes it covers.
3b. **Every quantified variable is anchored.** A region, device or user the rule quantifies over
   must be related to a binder through the formula — an anchoring relation (`rel_occupies` (a road user's footprint overlaps a lane / region) or `st_region_geometry` (the reference point and the boundary polygon of a structure region in the world frame) (or an accessor of one)) between a
   binder and the variable, a relation to a variable that is itself anchored, a relation to a
   binder, or a comparison that reads both. A quantifier with no such tie asks whether any entity
   of the scene qualifies, and the gate returns `UNANCHORED_VARIABLE`. If the node claims no
   anchoring atom, the node is wrong: report it. A region kind the record names is written as
   named: where a kind is refined by others, a quantifier over it covers them, and no exclusion the
   record does not state is added.
3c. **One region across formulas.** The applicability and the obligation are separate formulas: a
   region bound in one is not in scope in the other. Where the obligation speaks of the region the
   applicability selected, write in it the record's whole selection of that region again, with
   every relation and declared intention that fixed it, so that it denotes the same region; a shared
   variable name alone never makes two regions the same, and a quantifier over the kind alone never
   replaces the record's whole selection. Keep the quantifier the record states over the selected
   regions: where the record requires the duty at each region selected, write it for every selected
   region; where it allows a choice among them, keep the choice. A record that leaves either open
   is the record's defect: report it.
4. **Parameters, not values.** A quantity enters as `.param "<name>"` from the node's `params`.
   The only literals are zero, enumeration spellings, and the node's declared `literals`, each
   written through the `Units` constructor of its unit (`Units.<unit> <figure>`). What a formula
   may not say is listed with the formula language; the gate returns `CHECK_FAIL` on it.
   For `headingSince`, a shared concept takes the step bound through its own time formal; a rule
   uses exactly the reviewed step parameter named by the run's acquisition profile. Do not
   introduce a literal, alias, or expression for that bound.
5. **Standards are the node's operationalizations**, nothing else: the concept and parameters
   named there, no substitute.
6. **Compositions follow the node's `as`.** `exception`: `.not (.ruleApplies "<id>" map)` in the
   applicability; `condition`: `.ruleApplies "<id>" map` in the applicability; `compliance`:
   `.rule "<id>" map` where the node places it; `unless`: `.not (.ruleApplies "<id>" map)`
   conjoined into the formula of the span named in `scopes` (an exception or condition), so that
   span's content does not hold where that rule applies and the applicability as a whole is
   untouched. `map` binds every binder of the composed rule; a
   binder the node has no variable for is bound by `.existsUser "<var>" (…)` around the
   composition. You never inline another rule's content. A `definition` composition is no call:
   it records words borrowed from a source text, shown whole below the node, and the elements
   naming its span in `source_spans` write their meaning with their own atoms; never write
   `.rule` or `.ruleApplies` for it.
6a. **Observable readings.** A span the node reads through conduct (`kind: "observable_reading"`
   in its narrowings) is written from its element's atoms as any span is. It is the plan's
   narrowing, already on record: you do not restate it, and you never declare one the node does not.
   A declared intention the node carries (`intentions`) is the formula `intent` of the road user and
   the region the element of its place's span binds, read at the judged observation or in a window
   behind it, never in a window ahead.
6b. **The occasion of an act.** Where the node declares `occasion`, write a span read
   `at_recognition` at the declared recognition point. For `boundary: "window"`, write one read
   `some_moment` as `.not (.holdsFor .time W s (.not (.and U φ)))`, and one read `throughout` as
   `.holdsFor .time W s (.implies U φ)`, with `W` the occasion's `window` parameter, `s` the subject
   and `U` the formula of the `under_way` element, written from its atoms like any element and never
   `.tt`. For `boundary: "event"`, write the onset formula from the record's `onset` element and
   read `some_moment` or `throughout` over the declared act stretch from its observed onset to the
   recognition being judged, respecting the concept contract's extent. Use the declared onset of
   that occurrence; a fixed-length window, an unrelated edge, or an earlier occurrence is no
   substitute. Use the available operators only where their semantics express that boundary and
   quantification. Spans joined by `.and` and read at the same occasion are read together, so a
   `some_moment` reading requires one common observation for their conjunction, not different
   observations for its parts. Read `U` only as the record maps it. The contract states how long the
   act concept holds and what ends it; do not infer an event act's extent from a window. Where the
   record uses the act as an event, judge it once at its declared recognition, using
   `.rises (<act>)` for recognition represented by the concept becoming true. Missing required
   history leaves the dependent expression unknown where Core cannot decide it; other branches may
   still decide the verdict. Where the declared boundary or quantification cannot be expressed,
   report `no_operator` on its words instead of inventing a window. A named occasion `gap` follows
   that same route. A concept declaring `act` must implement the boundary its record states: its
   window formal is the actual look-back length for a window boundary, and its declared onset
   supplies the boundary for an event act. The `occasion_<span>_outside` witness places the span
   only outside the declared act stretch.
6c. **A duty with a history bound.** Where the node's `obligation` states a history bound, a search
   into the past ends exactly where the record says and nowhere else. Do not invent a history
   boundary from the recording's start, a subject's first observation, or a cumulative quantity
   whose origin is the recording's start. Preserve any event, time or distance window the record
   requires. A path length since the trace began is refused inside a search into the past. Each atom
   and primitive is used only as its contract states. Where the plan declares a history-boundary
   scenario, its witness is a trace in which the duty arises, the history the bound needs begins
   before the recording, the act is unrecorded, and no recorded act or visible end of the search
   decides the verdict; its `boundary` names the history the trace lacks, and it expects unknown. No
   other witness is unknown for a window truncated at the start of its trace.
7. **Witnesses are built, not described.** Each scenario is a `Scenario` built with the `Build.*`
   constructors from the node's narrative: `forbid` expects violated, `permit` compliant, `idle`
   not applicable, `blind` unknown with the masked atoms absent in its manifest. A scenario
   names the instants it speaks about (`window`) when the rule looks back in time. The planned
   scenarios are the minimum, not the set: the gate's adequacy rule fails the rule when a leaf
   moves no decided witness, and a duty with alternatives (two devices, two ways to comply, an
   exception with two limbs) has leaves the planned scenes never reach. Add `branch_<n>`
   witnesses, each expecting `violated` or `compliant`, or `not_applicable` where it shows a
   situation the words exclude from the duty, with a one-line narrative in a comment, until every
   leaf is exercised; they are the rule's tests, yours to write, not evidence of the reading. Every
   scenario the node plans (`branch_<n>`, `occasion_<span>`) is a witness of that name with the
   planned verdict. A fact the source does not observe is unknown, never made false to reach
   `not_applicable`. Literal values of one atom's enumeration tested in separate disjuncts count as
   one leaf: one scene exercises them.
8. **No history of your own.** The trace is a list of built scenes; you do not read captures,
   and you do not import anything but `TrafficSpec.Core.Language.Rule` in the rule file and the rule plus
   `TrafficSpec.Core.Evidence.Builders` in the witness file. A sign whose legend states no
   restriction carries `conditions := some {}`; `none` is a legend not read, on which every
   condition is unknown. A relation Core computes from the scene is never supplied; supply only one
   it cannot compute (the gate fails a witness that supplies one Core computes).
9. **Closed, total values.** No `sorry`, `admit`, `axiom`, `unsafe`, `partial`, `opaque`,
   `implemented_by`, `extern`, `native_decide`, `panic!`, `#eval`, `run_cmd`, `initialize` or `elab`
   anywhere in the two files; the rule is
   data and the gate checks its axioms.
10. **The gate decides.** Run it after each edit. Its verdict is the only acceptance signal; your
   own reading of your code is not.

## Procedure

Decide from the surface, then write; the surface is the API, the example is the style.

1. Read the node. List the atoms, primitives and concepts it claims and the parameters it names;
   pair each with the accessor, primitive or catalogue line of the surface that carries it.
2. Write the rule in one pass: binders → class formulas from `class_elements`; applicability from
   the trigger/condition elements; obligation from the obligation elements and
   operationalizations; compositions as `.rule`/`.ruleApplies`. Replace every `TODO` and `.tt`.
3. Write the four witnesses from the narratives, against the reading's values.
4. Run the gate. On `BUILD_FAIL`, `UNSOUND` or `CHECK_FAIL`, fix the Lean. On
   `UNANCHORED_VARIABLE`, tie the variable to a binder with a claimed anchoring atom, or report
   that the node claims none. On
   `DECLARATION_MISMATCH`, `UNCLAIMED_ATOM`, `UNUSED_CLAIM` or `BARE_LITERAL`, fix the rule
   against the node once; if the verdict persists, the node and the blueprint disagree — end the session
   and report it. On `WITNESS_FAIL`, first decide whether the witness or the formula is wrong
   against the node's narrative, then fix that one. On `VACUOUS`, a leaf does no work in any
   witness: either a witness must exercise it or the formula carries an atom the node should not
   have claimed — report the second case, do not delete the atom.
5. Finish on `OK`, or when the budget is spent, or when the node itself is wrong.

## Output

The two files, and `task_result.md` with: the final verdict; each gate run's verdict and what
changed after it; every choice the node left open and what you chose; **Why I finished**. If the
node is wrong, say which span, why, and what the plan agent must change.

**A concept that is wrong.** If a concept the node calls, directly or through another concept,
computes on a situation what its own contract excludes, write `dependency_defect.json`: the JSON object `{"concept_id": "<id>", "contract_words": "<its contract's words that decide it, verbatim>",
"kind": "holds_wrongly | fails_wrongly | undecided" (a quantity: "value_wrongly | undecided"), "situation": "<one sentence>",
"contract_verdict": "holds | fails"` (a quantity: `"contract_value": {"lo": [<value>, "<unit>"], "hi": [<value>, "<unit>"]}`)`,
"instance": {"literals": {...}, "nats": {...}, "params": {"<parameter>": [<value>, "<unit>"]}}, "grounding": {"<track formal>": <track id>},
"regions": {"<region formal>": <region id>},
"trace": {"scenes": [...]}, "at": <timestamp of a scene, ms>}`
— and finish. The harness runs the concept on your trace and an adjudicator judges the report by
the concept's contract before anything is charged; a report it does not uphold is your session's
defect, and the gate's verdict stands.

## Finish

Finish on `OK` with `task_result.md` written, or when the budget is spent, or when the node is
wrong. Never edit the blueprint, the ontology, Core, or another node's files.


## Where to write

Working directory: `/local-scratch2/sma407/scratch_core/launch/remote/pipeline/traffic-spec-agent/results/demo22-1109-0108/iter-002/code/NRS_484B_113_2`. Write `task_result.md` there.
