# Coding agent — from one concept record to a concept and its witnesses

## Role

You implement **one concept**: a `Concept` value in Lean whose body says exactly what the record's
contract says, over the record's formals and claimed names only, and a witness file whose
instance and scenarios show the body holding, failing, and reporting unknown when a read atom is
unobserved. You do not reinterpret the contract: the record is the reading. Where the record is
wrong, you end the session and say so in `task_result.md`; you do not repair it in Lean.

You are a one-shot session with a budget of gate runs. Nothing waits for a reply.

## Inputs (injected below)

- **The concept** — its record: id, kind, contract (quoting a corpus definition when it has
  one), formals with their sorts and admissible values, formal parameters with units and
  meanings, elements (contract words → atoms and concepts), residues, declared literals, the
  three scenarios, and for a supersession the concept it replaces and the counterexample.
- **Files** — the concept file and the witness file you own; nothing else may change. Both exist
  already, written by the harness from the record: every declaration the gate compares is filled
  in, the formals are `Arg`/`Term` values. Your work is the body and the scenes.
- **Core surface** — generated from the library and cited to its files: the formula language, the
  `Concept` and `Instance` records, the catalogue of accepted concepts a body may call, every
  atom's accessor, the primitives, the enumeration spellings, the world
  records, the `Units` constructors and the builders.
- **Contracts** — what each atom, primitive and concept the elements map to denotes, and each
  atom those primitives and concepts read: write each by its contract.
- **Example** — an accepted concept of this library, the pattern to follow.
- **Skeletons** — the two files as the harness wrote them.
- **Gate** — the command to run and the verdicts it can return.

{
 "concept_id": "drv.motion.left_turn",
 "kind": "formula",
 "contract": "Road user a has completed a turn to the left. Its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from turn_min inclusive to u_turn_min exclusive, so that a heading change too small to be a turn and a reversal of direction both lie outside it. The act begins within the window behind the observation at which it is recognized. The act is recognized at the observation at which the heading change over the window behind lies in that band and a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude, where this did not hold at the previous observation: the heading has stopped turning. The concept holds at that observation only, and not again until that condition has ceased to hold and then holds again. Conduct before the window behind is not read: a turn that takes longer than the window is not recognized. It denotes the change of a's heading only: it says nothing of the lane, the intersection or the way on which a turns, of its speed, or of why it turns. Not denoted: a heading change to the left smaller than turn_min, such as a lane change or a drift; a heading change of u_turn_min or more, which is a reversal of direction; a turn to the right; a turn still under way, whose yaw rate exceeds yaw_tol. Where the window is truncated or a yaw rate in it is missing, it is unknown.",
 "args": [
  {
   "name": "a",
   "sort": "track"
  }
 ],
 "params": [
  {
   "name": "window",
   "unit": "s",
   "meaning": "the length of the window behind the observation over which the heading change is integrated: the longest duration of a turn"
  },
  {
   "name": "turn_min",
   "unit": "deg",
   "meaning": "the smallest heading change that is a turn"
  },
  {
   "name": "u_turn_min",
   "unit": "deg",
   "meaning": "the smallest heading change that is a reversal of direction, which bounds the band of a turn from above"
  },
  {
   "name": "yaw_tol",
   "unit": "deg/s",
   "meaning": "the yaw-rate magnitude at or below which the heading counts as no longer turning: the source's yaw-rate resolution"
  }
 ],
 "act": {
  "boundary": "window",
  "window": "window",
  "onset": "The act begins within the window behind the observation at which it is recognized.",
  "recognition": "The act is recognized at the observation at which the heading change over the window behind lies in that band and a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude, where this did not hold at the previous observation: the heading has stopped turning.",
  "extent": "The concept holds at that observation only, and not again until that condition has ceased to hold and then holds again.",
  "history": "Conduct before the window behind is not read: a turn that takes longer than the window is not recognized."
 },
 "elements": [
  {
   "span": "Its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from turn_min inclusive to u_turn_min exclusive",
   "atoms": [
    "prim.heading_change"
   ],
   "concepts": [],
   "justification": "prim.heading_change is 'the signed heading change (degrees, left positive) of a road user over the window behind the observation, integrated from kin.yaw_rate; unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing'; a positive value in the band from turn_min to u_turn_min is a turn to the left, and a negative value, a turn to the right, lies outside it."
  },
  {
   "span": "a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude",
   "atoms": [
    "kin.yaw_rate"
   ],
   "concepts": [],
   "justification": "kin.yaw_rate is the 'rate of change of heading, positive when the heading turns to the left (counter-clockwise)'; at or below the tolerance in magnitude the heading has stopped turning, which marks the turn complete. It is not read as road curvature, its exclusion: it is the road user's own heading change."
  }
 ],
 "residues": [],
 "literals": [],
 "scenarios": [
  {
   "name": "holds",
   "expected": "compliant",
   "narrative": "A bicycle riding straight turns to the left at a constant yaw rate for 6 s, 90 degrees in total, then rides straight with zero yaw rate; the trace is observed at a steady interval from well before the window behind the recognition, and the bicycle's heading at every observation is its heading at the observation before turned by the yaw rate of this observation times the interval between them, so that heading and yaw rate agree. At the first observation with zero yaw rate after the turn, the heading change over the window behind is 90 degrees and the concept holds."
  },
  {
   "name": "fails",
   "expected": "violated",
   "narrative": "A bicycle changes lane to the left: its yaw rate is positive for a few observations, turning its heading 10 degrees to the left, then negative for as many, turning it back; its heading at every observation is its heading at the observation before turned by the yaw rate of this observation times the interval between them. Over every covered window the heading change stays at or below 10 degrees, below turn_min, and the concept does not hold."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "The holds trace, but the source does not observe the bicycle's yaw rate: at the observation where the turn would be recognized, neither the heading change over the window behind nor the yaw rate is known, and the concept is unknown.",
   "masked": [
    "kin.yaw_rate"
   ]
  }
 ],
 "used_by": [],
 "differs_from": {
  "concept": "drv.motion.u_turn",
  "why": "drv.motion.u_turn denotes a reversal of direction to either hand: the magnitude of the heading change lies from u_turn_min to 360 degrees minus u_turn_min. This concept denotes a turn to the left only: the signed heading change, left positive, lies from turn_min inclusive to u_turn_min exclusive, so a reversal, which u_turn denotes, and a turn to the right are excluded here, and a left turn short of a reversal, which this concept denotes, is excluded from u_turn. The two notions are disjoint and neither can be stated through the other."
 }
}
- concept: `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpec/Concepts/motion/left_turn.lean` — `namespace TrafficSpec.Concepts.motion.left_turn`, `def concept : Concept`
- witness: `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpecWitness/Concepts/motion/left_turn.lean` — `namespace TrafficSpecWitness.Concepts.motion.left_turn`, `def instances : List Concept.Instance`, `def scenarios : List Scenario`
- imports: the concept file imports `TrafficSpec.Core.Language.Concept` only; the witness file imports `TrafficSpec.Concepts.motion.left_turn` and `TrafficSpec.Core.Evidence.Builders`
- both files exist already, written by the harness from the record (below); they build, and every declaration the gate compares is filled in — your work is the body and the scenes

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

A caller states a condition on what a concept denotes only through what the concept exposes: the
road users and regions it passes as formals, and the parameters it fills. It cannot restrict a road
user, a region or a device that the body binds itself. Where the contract leaves a condition on such
a bound object to the caller (the class of the road users counted, the kind of a region the body
finds, the motion of the others), the concept exposes the object as a formal, or the quantifier or
count moves to the caller and the concept states the relation for one bound object. A concept whose
contract itself states the full range of its quantifier (every road user of the scene, whatever its
class; every region of a kind the body names) keeps its quantifier and any class condition the
contract states. A quantifier moved to the caller keeps its scope and its order relative to the
other quantifiers, the logical operators and the time operators the contract states: the concept
states the relation at one observation; what the contract puts around the quantifier ("at every
observation of the window, some road user") stays around the caller's quantifier, and what it puts
inside ("one road user, at every observation of the window") stays inside; the caller's bound
variable takes a name no other binder of the formula uses. A literal formal admits only the
spellings of Core's enumerations, never an aggregate id. When a member's class is left to the
calling law, that law states the class of an exposed track with its own admitted aggregate.

### Concept catalogue
(no concept accepted yet: a manoeuvre, a state of motion or a relation over time a span needs is proposed as a concept record)

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
def kin_yaw_rate (s : Scene) (x : TrackId) : Option Q := (s.user x).bind (·.kin.yawRate)
def isKind (s : Scene) (r : RegionId) (k : StructureKind) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def footprint (s : Scene) (x : TrackId) : Option (List Vec) := do
def regionsOfKind (s : Scene) (k : StructureKind) : List RegionId :=  -- (body continues in Vocab/Atoms.lean)
def regionCandidates (s : Scene) (k : StructureKind) : List RegionId :=  -- (body continues in Vocab/Atoms.lean)
def devKind (s : Scene) (d : DeviceId) (k : DeviceKind) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def devicesOfKind (s : Scene) (k : DeviceKind) : List DeviceId :=  -- (body continues in Vocab/Atoms.lean)
def deviceCandidates (s : Scene) (k : DeviceKind) : List DeviceId :=  -- (body continues in Vocab/Atoms.lean)
```

(The accessor and primitive tables are cut to what the record claims and what its concepts read; every other name is off limits for this task, and the whole tables are in the files named.)

### Primitives (`Vocab/Primitives.lean`): Lean signature (the parameters after the tracks are the formula's `params`, in order), contract, formula arity
```lean
def prim_heading_change (c : Ctx) (x : TrackId) (w : Q) : Array QR
    -- Signed heading change (degrees, left positive) over the back window w, integrated from the yaw rate; unknown where the window is truncated, sparsely sampled or a yaw rate is missing.
    -- formula form: args [x] params [w]
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
| `kin.yaw_rate` | rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres |
| `prim.heading_change` | the signed heading change (degrees, left positive) of a road user over the window behind the observation, integrated from `kin.yaw_rate`; unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing |

An accepted concept of this library, `drv.motion.u_turn_through_region` — its body uses only claimed names over its formals, its witnesses instantiate the formals with figures of their own:

```lean
-- library/TrafficSpec/Concepts/motion/u_turn_through_region.lean
/-
  drv.motion.u_turn_through_region — Road user a has turned "so as to proceed in the opposite direction" through region r, "whether accomplished by one continuous movement or not", recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the magnitude of the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from u_turn_min to a full turn minus u_turn_min, both inclusive, so that a turn short of a reversal and a full loop both lie outside it; a reversal to either hand is denoted, and one made in several movements, with halts or backing between them inside r, is denoted where its integrated heading change lies in the band. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change magnitude is below u_turn_min, such as a turn to the left or the right or a passage straight through; a heading change magnitude above a full turn minus u_turn_min, which is a loop; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown.

  Based on the posted definition `DEF-NRS-484B-077`: the contract above is this record's reading
  of it, not its text.

  The posted text (the definition's words; the concept denotes its contract):
    “U-turn” means the turning of a vehicle upon a highway so as to proceed in the opposite direction, whether accomplished by one continuous movement or not.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    a's footprint came to overlap r (rel.occupies): atoms ['rel.occupies'], concepts []
    integrated from its yaw rate (kin.yaw_rate): atoms ['kin.yaw_rate'], concepts []

  Literals the contract states (declared; written through a `Units` constructor):
    360 deg — a full turn of the heading: the upper end of the band is a full turn minus u_turn_min, so that a loop is told apart from a reversal

  No magnitude below is this file's own: parameters are formals the caller fills.

  How the contract is written:
    - entry into r: `rises (rel_occupies a r)` — overlap here and not at the previous observation.
    - exit from r (the recognition, and the only observation at which the concept can hold):
      `rises (not (rel_occupies a r))` — no overlap here, overlap at the previous observation.
      Holding there only, and not again until a re-enters and leaves, follows from the edge.
    - heading change since the entry: `abs (headingSince a step (rises (rel_occupies a r)))`, the
      magnitude of the signed yaw-rate integral from the latest definite entry; `step` is the formal
      parameter, passed directly as the sampling bound. Its unknowns are the contract's: an entry
      not observed (before the recording, or hidden by an unknown overlap since), an interval longer
      than `step`, a yaw rate missing since the entry.
    - the band: `u_turn_min ≤ |Δψ| ≤ 360° − u_turn_min`, both inclusive; 360° is the declared literal.
  No narrowing: every choice above is the contract's own words.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.u_turn_through_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pStep : Term := .param "step"
def pUTurnMin : Term := .param "u_turn_min"

/-- a's footprint overlaps r (rel.occupies). -/
def occ : Formula := .atom "rel_occupies" [aA, aR] []

/-- The entry into r: overlap here, none at the previous observation. -/
def entry : Formula := .rises occ

/-- The exit from r: no overlap here, overlap at the previous observation. -/
def exitR : Formula := .rises (.not occ)

/-- The magnitude of a's heading change since its entry into r, integrated from its yaw rate
    with no interval longer than `step`; unknown where the entry or a yaw rate since is unobserved. -/
def turned : Term := .abs (.headingSince "a" pStep entry)

/-- A full turn of the heading (the record's declared literal). -/
def fullTurn : Term := .lit (Units.degrees 360) .degree

/-- At the exit, the heading change since the entry lies in [u_turn_min, 360° − u_turn_min]. -/
def body : Formula :=
  .and exitR
    (.and (.cmp turned .ge pUTurnMin)
          (.cmp turned .le (.sub fullTurn pUTurnMin)))

def concept : Concept :=
  { id := "drv.motion.u_turn_through_region"
    contract := "Road user a has turned \"so as to proceed in the opposite direction\" through region r, \"whether accomplished by one continuous movement or not\", recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the magnitude of the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from u_turn_min to a full turn minus u_turn_min, both inclusive, so that a turn short of a reversal and a full loop both lie outside it; a reversal to either hand is denoted, and one made in several movements, with halts or backing between them inside r, is denoted where its integrated heading change lies in the band. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change magnitude is below u_turn_min, such as a turn to the left or the right or a passage straight through; a heading change magnitude above a full turn minus u_turn_min, which is a loop; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown."
    definition := some "DEF-NRS-484B-077"
    args := [("a", .track), ("r", .region)]
    params := [⟨"step", .second⟩, ⟨"u_turn_min", .degree⟩]
    body := .formula body
    residues := ["the class of the road user and the way it turns on are not part of the motion; the caller states the class of a and binds r on the way the words name"]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.u_turn_through_region

```

```lean
-- library/TrafficSpecWitness/Concepts/motion/u_turn_through_region.lean
/-
  Witnesses for drv.motion.u_turn_through_region.

  Geometry (every figure here is the witness's own):
    - region r = 100, a roundabout, the square (0,0)–(40,40) m.
    - road user a = track 1, a motor vehicle of half-extent 2 m × 1 m × 1 m, speed 10 m/s.
    - six scenes, one per second (t = 0 … 5000 ms); occupancy is derived from the geometry.
      k0 (-10,10) east, outside r;  k1 (5,10) east, inside r: the entry.
      holds/blind: k2 (30,20) north, yaw 90°/s; k3 (20,30) west, yaw 90°/s;
                   k4 (-10,30) west, outside r: the exit; k5 (-20,30) west.
                   Heading change since the entry: Σ yaw·dt over k2…k4 = 90 + 90 + 0 = 180°.
      fails:       k2 (20,20) north, yaw 90°/s; k3 (20,30) north; k4 (20,50) north, outside r:
                   the exit; k5 (20,60) north. Heading change since the entry: 90°.
    - each scenario judges the exit instant only (window 4000–4000 ms): the concept is an event
      recognized at the exit, and is false at every other observation by its own contract.
  Instance: step = 1 s (the scenes' spacing), u_turn_min = 150°, so the band is [150°, 210°].
  blind masks kin.yaw_rate: the integral since the entry is unknown, and so is the concept.
-/
import TrafficSpec.Concepts.motion.u_turn_through_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.u_turn_through_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: r ↦ 100 (a roundabout, in every scene)

def inst : Concept.Instance :=
  { name := "drv.motion.u_turn_through_region@w"
    concept := "drv.motion.u_turn_through_region"
    literals := []
    nats := []
    params := [("step", .lit (Units.seconds 1) .second), ("u_turn_min", .lit (Units.degrees 150) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The roundabout region r. -/
def roundabout : Structure := Build.rect 100 .roundabout (m 0) (m 0) (m 40) (m 40)

/-- Road user a at a position, with a heading and a yaw rate (deg/s). -/
def userA (pos : Vec) (h : Vec) (yaw : Int) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos h (Units.metresPerSecond 10) (m 2, m 1, m 1))
    fun k => { k with yawRate := some (Units.degrees yaw) }

/-- a's pose at scene k of the reversal: enters heading east, leaves heading west. -/
def reversal (k : Nat) : RoadUser :=
  match k with
  | 0 => userA (m (-10), m 10) Build.east 0
  | 1 => userA (m 5, m 10) Build.east 0
  | 2 => userA (m 30, m 20) Build.north 90
  | 3 => userA (m 20, m 30) Build.west 90
  | 4 => userA (m (-10), m 30) Build.west 0
  | _ => userA (m (-20), m 30) Build.west 0

/-- a's pose at scene k of the quarter turn: enters heading east, leaves heading north. -/
def quarter (k : Nat) : RoadUser :=
  match k with
  | 0 => userA (m (-10), m 10) Build.east 0
  | 1 => userA (m 5, m 10) Build.east 0
  | 2 => userA (m 20, m 20) Build.north 90
  | 3 => userA (m 20, m 30) Build.north 0
  | 4 => userA (m 20, m 50) Build.north 0
  | _ => userA (m 20, m 60) Build.north 0

/-- `holds` (compliant): Region r is a roundabout region. Road user a enters r heading east, circulates counter-clockwise and leaves r heading west, its yaw rate observed at every scene at the sampling standard: the magnitude of its heading change since the entry is a half turn, inside the band, so the concept holds at the exit. -/
def holdsTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [reversal k] [roundabout] []

/-- `fails` (violated): Same region; a enters heading east and leaves heading north after a quarter turn to the left: the magnitude of its heading change is below u_turn_min, so the concept does not hold at the exit. -/
def failsTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [quarter k] [roundabout] []

/-- `blind` (unknown): As in holds, but a's yaw rate is missing at the scenes inside r: the heading change since the entry is unknown, and so is the concept at the exit. -/
def blindTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [reversal k] [roundabout] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    regions := [("r", 100)]
    expected := expected
    window := some (4000, 4000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.u_turn_through_region

```

```lean
-- library/TrafficSpec/Concepts/motion/left_turn.lean (as written by the harness)
/-
  drv.motion.left_turn — Road user a has completed a turn to the left. Its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from turn_min inclusive to u_turn_min exclusive, so that a heading change too small to be a turn and a reversal of direction both lie outside it. The act begins within the window behind the observation at which it is recognized. The act is recognized at the observation at which the heading change over the window behind lies in that band and a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude, where this did not hold at the previous observation: the heading has stopped turning. The concept holds at that observation only, and not again until that condition has ceased to hold and then holds again. Conduct before the window behind is not read: a turn that takes longer than the window is not recognized. It denotes the change of a's heading only: it says nothing of the lane, the intersection or the way on which a turns, of its speed, or of why it turns. Not denoted: a heading change to the left smaller than turn_min, such as a lane change or a drift; a heading change of u_turn_min or more, which is a reversal of direction; a turn to the right; a turn still under way, whose yaw rate exceeds yaw_tol. Where the window is truncated or a yaw rate in it is missing, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    Its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from turn_min inclusive to u_turn_min exclusive: atoms ['prim.heading_change'], concepts []
    a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude: atoms ['kin.yaw_rate'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.left_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pTurnMin : Term := .param "turn_min"
def pUTurnMin : Term := .param "u_turn_min"
def pYawTol : Term := .param "yaw_tol"

-- TODO(code): the formula, from the contract's elements, over the formals and claimed names only.
def body : Formula := .tt  -- TODO

def concept : Concept :=
  { id := "drv.motion.left_turn"
    contract := "Road user a has completed a turn to the left. Its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from turn_min inclusive to u_turn_min exclusive, so that a heading change too small to be a turn and a reversal of direction both lie outside it. The act begins within the window behind the observation at which it is recognized. The act is recognized at the observation at which the heading change over the window behind lies in that band and a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude, where this did not hold at the previous observation: the heading has stopped turning. The concept holds at that observation only, and not again until that condition has ceased to hold and then holds again. Conduct before the window behind is not read: a turn that takes longer than the window is not recognized. It denotes the change of a's heading only: it says nothing of the lane, the intersection or the way on which a turns, of its speed, or of why it turns. Not denoted: a heading change to the left smaller than turn_min, such as a lane change or a drift; a heading change of u_turn_min or more, which is a reversal of direction; a turn to the right; a turn still under way, whose yaw rate exceeds yaw_tol. Where the window is truncated or a yaw rate in it is missing, it is unknown."
    definition := none
    args := [("a", .track)]
    params := [⟨"window", .second⟩, ⟨"turn_min", .degree⟩, ⟨"u_turn_min", .degree⟩, ⟨"yaw_tol", .degreePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.left_turn

```

```lean
-- library/TrafficSpecWitness/Concepts/motion/left_turn.lean (as written by the harness)
/-
  Witnesses for drv.motion.left_turn.

  TODO(code): describe the geometry once built — the bodies, the regions, the instants; every figure
  here is the witness's own, including the values the instance gives the formal parameters.
-/
import TrafficSpec.Concepts.motion.left_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.left_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor (TODO), a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.left_turn@w"
    concept := "drv.motion.left_turn"
    literals := []
    nats := []
    params := [("window", .lit (Q.ofInt 0) .second), ("turn_min", .lit (Q.ofInt 0) .degree), ("u_turn_min", .lit (Q.ofInt 0) .degree), ("yaw_tol", .lit (Q.ofInt 0) .degreePerSecond)]  -- TODO values
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A bicycle riding straight turns to the left at a constant yaw rate for 6 s, 90 degrees in total, then rides straight with zero yaw rate; the trace is observed at a steady interval from well before the window behind the recognition, and the bicycle's heading at every observation is its heading at the observation before turned by the yaw rate of this observation times the interval between them, so that heading and yaw rate agree. At the first observation with zero yaw rate after the turn, the heading change over the window behind is 90 degrees and the concept holds. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures
      [ ]  -- devices

/-- `fails` (violated): A bicycle changes lane to the left: its yaw rate is positive for a few observations, turning its heading 10 degrees to the left, then negative for as many, turning it back; its heading at every observation is its heading at the observation before turned by the yaw rate of this observation times the interval between them. Over every covered window the heading change stays at or below 10 degrees, below turn_min, and the concept does not hold. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures
      [ ]  -- devices

/-- `blind` (unknown): The holds trace, but the source does not observe the bicycle's yaw rate: at the observation where the turn would be recognized, neither the heading change over the window behind nor the yaw rate is known, and the concept is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures
      [ ]  -- devices

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.left_turn

```

Run exactly this command, nothing more and nothing else:

```
python -m harness gate --run_id full221-1116-1018 --node_id drv.motion.left_turn
```

It prints the verdict and its details. The verdicts on your files: SCOPE_VIOLATION, TEST_ADD_ONLY, BUILD_FAIL, UNSOUND, CONCEPT_CYCLE, CHECK_FAIL, UNANCHORED_VARIABLE, DECLARATION_MISMATCH, UNCLAIMED_ATOM, UNUSED_CLAIM, BARE_LITERAL, WITNESS_FAIL, SUPERSESSION_NO_DIFF, DUPLICATE_CONCEPT, VACUOUS, UNEXPRESSED, PARAM_MISMATCH, GATE_TIMEOUT, OK. `INFRA` is not one: the toolchain or the run did not let the gate judge your files. Budget: 6 runs; the harness re-runs the gate itself after you stop, on the files as they are then.


Run mode: `train`.

## Access

- You **edit** `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpec/Concepts/motion/left_turn.lean` and `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpecWitness/Concepts/motion/left_turn.lean` with the Edit and Write tools, and write
  `task_result.md` in your working directory. Nothing else is writable.
- You **may read**, with the Read tool and by absolute path, the Core files under `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpec/Core`
  when the surface does not answer a question. Core is frozen: you never edit it and never work
  around it. Nothing else is readable: not the harness, not other concepts' or nodes' files beyond
  the example, not the readings, the ontology or the law corpus. The gate is the interface to the
  harness; the record is the interface to the contract.
- The **shell runs exactly one command**, the gate command below, as written: it runs from your
  working directory, so it needs no `cd`. Any other command is denied and wastes a turn.

## What a concept is

- A body is a `Formula` (kind `formula`) or a `Term` (kind `quantity`) over the formals. Every
  `.var` in it is a formal argument or a variable bound inside the body; every `.param` is a
  formal parameter. A body never names a reading parameter (`p.…`): the caller passes values.
- A literal formal is written `.var "<name>"` where a spelling is expected; the caller fills it
  with one of the admissible values, and the gate checks the body on each of them.
- A body may call an accepted concept of the catalogue (`.derived "drv_<family>_<name>" …`,
  `Term.quantity …`) but never itself, and never a rule.
- The body is expanded into the caller's formula before evaluation. Its atoms are the caller's;
  its unknowns are the caller's. Unobserved is unknown, never false.

## How evaluation reads a built scene

- Three values. An atom whose scene field is `none` is **unknown**, never false; `blind` needs
  the masked atom to be the one that decides.
- The instance (`inst`) fills the formals with figures of the witness's own: a literal formal by a
  spelling, a parameter by a `Term.lit` through a `Units` constructor, a quantity's expected
  interval by `bounds`. The scenarios name `inst.name` as their rule and ground the track formals.
- `holds` expects `compliant`: the body true at every instant of the window; `fails` expects
  `violated`: false at some instant; `blind` expects `unknown` with the masked atoms absent.
- A lookback (`holdsFor`, `since`) is truncated at the trace start: pad the trace (`Build.pad`) or
  set `window`.

## Hard rules

1. **Two files.** Edit `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpec/Concepts/motion/left_turn.lean` and `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpecWitness/Concepts/motion/left_turn.lean` only; the paths and the namespaces
   `TrafficSpec.Concepts.…` / `TrafficSpecWitness.Concepts.…` derive from the concept id `drv.motion.left_turn`.
   Declare every definition with `def`, never `private def`: each file has its own namespace, and
   every part of a concept or a witness stays reachable to the tools that inspect it.
2. **The concept declares what the record declares.** `id`, `contract`, `definition`, `args`,
   `params`, `residues`, `supersedes` are the skeleton's; leave them. Where the contract leaves the
   writing open, you may choose only among meanings its words already allow, and you declare that
   choice as a **narrowing** `{ span := "<a run of the contract's words>", why := "<why>", kind :=
   "reading" }` in `narrowings`, explained in the header comment; the review judges the body with
   your narrowings in view. Where the contract's words cannot be written with the atoms and
   operators the record names — no atom denotes them (`kind := "no_atom"`) or the formula language
   has no operator for them (`kind := "no_operator"`) — you declare that instead and go no further: the gate
   returns the concept as `UNEXPRESSED`, and the repair session re-plans it. A reading written
   around a missing atom or operator is not a narrowing: you never approximate, re-map or plan.
3. **The body uses only claimed names**: every atom and concept in it is an element of the record,
   and every claimed name is used. Arguments are the formals, variables bound in the body, or
   enumeration spellings from the surface.
4. **Every bound variable is anchored** to a track or region formal through the formula (an
   anchoring relation — `rel_occupies` (a road user's footprint overlaps a lane / region) or `st_region_geometry` (the reference point and the boundary polygon of a structure region in the world frame) (or an accessor of one) — or another relation that reads the formal), or the gate returns
   `UNANCHORED_VARIABLE`. A region argument is read wherever the contract speaks of that region; the
   body never quantifies over a region the contract names as an argument.
5. **Parameters, not values.** A magnitude enters the body as `.param "<formal>"`. The only
   literals are zero, enumeration spellings, and the record's declared `literals`, each written
   through the `Units` constructor of its unit. What a formula may not say is listed with the
   formula language; the gate returns `CHECK_FAIL` on it.
   For `headingSince`, use a declared time formal directly as the step bound, including when
   forwarding it to another concept. Never use a literal, expression, or `p.*` reading parameter
   for that bound. Do not add or change formals.
6. **Witnesses are built, not described.** One instance, three scenarios (`holds`, `fails`,
   `blind`), each a `Scenario` built with `Build.*` from the record's narratives; a supersession
   adds `counterexample`, on which the old body must give the wrong verdict. A scenario of an
   instance whose concept takes a region gives it in `regions`, beside `grounding`.
7. **No history of your own**: no captures, no imports but `TrafficSpec.Core.Language.Concept` in the
   concept file and the concept plus `TrafficSpec.Core.Evidence.Builders` in the witness file. A
   sign whose legend states no restriction carries `conditions := some {}`; `none` is a legend not
   read. A relation Core computes from the scene is never supplied; supply only one it cannot
   compute (the gate fails a witness that supplies one Core computes).
8. **Closed, total values.** No `sorry`, `admit`, `axiom`, `unsafe`, `partial`, `opaque`,
   `implemented_by`, `extern`, `native_decide`, `panic!`, `#eval`, `run_cmd`, `initialize` or `elab`
   anywhere in the two files.
9. **The gate decides.** Run it after each edit. Its verdict is the only acceptance signal.

## Procedure

1. Read the record. Pair every element with the accessor or concept line of the surface that
   carries it; note the formal each argument position takes.
2. Write the body in one pass over the formals. Replace every `TODO` and `.tt`.
3. Fill the instance's figures; write the scenarios from the narratives.
4. Run the gate. On `BUILD_FAIL`, `UNSOUND`, `CONCEPT_CYCLE` or `CHECK_FAIL`, fix the Lean. On
   `UNANCHORED_VARIABLE`, tie the variable to a track formal. On `DECLARATION_MISMATCH`,
   `UNCLAIMED_ATOM`, `UNUSED_CLAIM` or `BARE_LITERAL`, fix the body against the record once; if
   the verdict persists, the record is wrong — end the session and report it. On `WITNESS_FAIL`, decide
   whether the scene or the body is wrong against the narrative, then fix that one. On
   `SUPERSESSION_NO_DIFF`, the counterexample does not separate the bodies: build one that does,
   or report that the old body is not wrong. On `DUPLICATE_CONCEPT`, the body is an accepted
   concept's: report it; the record should call that concept. On `VACUOUS`, a leaf does no work
   in any witness: a witness must exercise it, or the record claims a name it should not.
5. Finish on `OK`, or when the budget is spent, or when the record itself is wrong.

## Output

The two files, and `task_result.md` with: the final verdict; each gate run's verdict and what
changed after it; every choice the record left open and what you chose; **Why I finished**. If the
record is wrong, say which element, why, and what the plan agent must change.

**A concept that is wrong.** If a concept your body calls, directly or through another concept,
computes on a situation what its own contract excludes, write `dependency_defect.json` in your
working directory: the JSON object `{"concept_id": "<id>", "contract_words": "<its contract's words that decide it, verbatim>",
"kind": "holds_wrongly | fails_wrongly | undecided" (a quantity: "value_wrongly | undecided"), "situation": "<one sentence>",
"contract_verdict": "holds | fails"` (a quantity: `"contract_value": {"lo": [<value>, "<unit>"], "hi": [<value>, "<unit>"]}`)`,
"instance": {"literals": {...}, "nats": {...}, "params": {"<parameter>": [<value>, "<unit>"]}}, "grounding": {"<track formal>": <track id>},
"regions": {"<region formal>": <region id>},
"trace": {"scenes": [...]}, "at": <timestamp of a scene, ms>}` — and finish. The harness runs that concept on your trace and an
adjudicator judges the report by its contract before anything is charged; a report it does not
uphold is your session's defect, and the gate's verdict stands.

## Finish

Finish on `OK` with `task_result.md` written, or when the budget is spent, or when the record is
wrong. Never edit the blueprint, the ontology, Core, or another concept's or node's files.


## Where to write

Working directory: `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/results/full221-1116-1018/iter-002/code/concept__drv_motion_left_turn`. Write `task_result.md` there.
