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
 "node_id": "NRS_484B_253_o2",
 "law_refs": [
  "NRS-484B-253"
 ],
 "subject": {
  "binder": "ego",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-320::vehicle"
  ]
 },
 "segmentation": [
  {
   "id": "f1",
   "text": "The driver of a vehicle",
   "role": "condition"
  },
  {
   "id": "f2",
   "text": "within an intersection",
   "role": "condition"
  },
  {
   "id": "f3",
   "text": "intending to turn to the left",
   "role": "condition"
  },
  {
   "id": "f4",
   "text": "shall yield",
   "role": "sibling"
  },
  {
   "id": "f5",
   "text": "the right-of-way",
   "role": "sibling"
  },
  {
   "id": "f6",
   "text": "to any vehicle approaching from the opposite direction",
   "role": "sibling"
  },
  {
   "id": "f7",
   "text": "which is within the intersection",
   "role": "sibling"
  },
  {
   "id": "f8",
   "text": "or so close thereto as to constitute an immediate hazard,",
   "role": "sibling"
  },
  {
   "id": "f9",
   "text": "but such driver,",
   "role": "boilerplate"
  },
  {
   "id": "f10",
   "text": "having so yielded",
   "role": "condition"
  },
  {
   "id": "f11",
   "text": "and having given a signal when and as required,",
   "role": "condition"
  },
  {
   "id": "f12",
   "text": "may make such left turn",
   "role": "condition"
  },
  {
   "id": "f13",
   "text": "and the drivers of all other vehicles approaching the intersection from the opposite direction",
   "role": "subject"
  },
  {
   "id": "f14",
   "text": "shall yield",
   "role": "obligation"
  },
  {
   "id": "f15",
   "text": "the right-of-way",
   "role": "standard"
  },
  {
   "id": "f16",
   "text": "to the vehicle making the left turn.",
   "role": "condition"
  }
 ],
 "elements": [
  {
   "span": "f1",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ],
   "derived": [],
   "justification": "\"a vehicle\": the left-turning road user t, other than ego, of the admitted aggregate DEF-NRS-484A-320::vehicle; \"The driver\" read through its controlled motion."
  },
  {
   "span": "f2",
   "atoms": [
    "st.intersection",
    "rel.occupies"
   ],
   "derived": [],
   "justification": "\"within an intersection\": t's footprint overlaps (rel.occupies) the intersection i (st.intersection); i is the region t's intention is declared at."
  },
  {
   "span": "f11",
   "atoms": [
    "sig.turn_indicator",
    "sig.hand_signal"
   ],
   "derived": [],
   "justification": "\"having given a signal\": t showed a left signal, its turn indicator state left (sig.turn_indicator, 'the turn indicator state ... left') or an arm signal of meaning left (sig.hand_signal), at some observation since t occupied its approach carrier into i; the signal itself, not a declared intention, and not the turn. \"when and as required\": the timing and manner another statute sets, outside this corpus; the signal is read as given before the judged observation."
  },
  {
   "span": "f12",
   "atoms": [],
   "derived": [
    "drv.motion.turning_left"
   ],
   "justification": "\"may make such left turn\": t is making the left turn it intends, drv.motion.turning_left (moving with its heading turning to the left at or above the yaw tolerance), a turn under way rather than one completed."
  },
  {
   "span": "f13",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle",
    "st.lane_enters",
    "st.lane_direction",
    "st.travel_region",
    "rel.occupies"
   ],
   "derived": [],
   "justification": "\"the drivers of all other vehicles\": ego, a vehicle (admitted aggregate DEF-NRS-484A-320::vehicle) other than t, its driver read through its controlled motion. \"approaching the intersection\": ego occupies a carrier c_e whose entrance end is i and does not overlap i, or enters i from it (st.lane_enters, rel.occupies). \"from the opposite direction\": c_e and the carrier from which t entered i carry opposed designated directions (st.lane_direction), as rel.oncoming's contract directs, not the current headings."
  },
  {
   "span": "f14",
   "atoms": [],
   "derived": [
    "drv.motion.at_rest"
   ],
   "justification": "\"shall yield\": granting precedence (DEF-NRS-484A-210 \"unless one grants precedence to the other\"): ego is at rest (drv.motion.at_rest) or not in conflict with t (operationalization of f15)."
  },
  {
   "span": "f16",
   "atoms": [],
   "derived": [
    "drv.motion.turning_left"
   ],
   "justification": "\"the vehicle making the left turn\": the same t, turning left (drv.motion.turning_left) at the judged observation."
  }
 ],
 "operationalizations": [
  {
   "span": "f15",
   "standard": "the right-of-way: DEF-NRS-484A-210 \"approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other\"",
   "concepts": [
    "prim.closest_approach_within",
    "prim.closest_approach_distance"
   ],
   "params": [
    "p.conflict_horizon",
    "p.conflict_clearance"
   ],
   "convention": "Traffic-conflict technique: two road users are in conflict where, projected at their current velocities, their centres approach within the time-to-collision horizon and their closest-approach centre distance is below the clearance at which their bodies would touch. Direction, speed and proximity enter by degree through the projected velocities and positions.",
   "surrogate": false
  }
 ],
 "assumptions": [],
 "intentions": [
  {
   "span": "f3",
   "id": "int.left_turn",
   "meaning": "The road user's current plan includes turning left at the target region."
  }
 ],
 "compositions": [
  {
   "span": "f10",
   "rule": "NRS_484B_253_o1",
   "map": {
    "ego": "t"
   },
   "as": "compliance"
  }
 ],
 "residues": [],
 "binders": [
  {
   "name": "ego",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ]
  }
 ],
 "applicability": "Ego is a vehicle (driven: agency reading) approaching an intersection i (on a carrier c_e whose entrance end is i, not overlapping i, or entering i from it), and some vehicle t other than ego overlaps i, declares int.left_turn at i, is turning left (drv.motion.turning_left, p.turn_yaw_tolerance, p.rest_speed_tolerance), showed a left signal (sig.turn_indicator left or sig.hand_signal left) at some observation since it occupied its approach carrier into i, has complied with NRS_484B_253_o1 (t as its ego) at every observation since it entered i, and entered i from a carrier c_t whose direction and c_e's have a dot product below minus p.opposite_direction_tolerance (st.lane_direction).",
 "obligation": "Ego is at rest (drv.motion.at_rest, p.rest_speed_tolerance) or not in conflict with t: not both prim.closest_approach_within(ego, t) with horizon p.conflict_horizon and prim.closest_approach_distance(ego, t) with the same horizon below p.conflict_clearance.",
 "params": [
  "p.rest_speed_tolerance",
  "p.conflict_horizon",
  "p.conflict_clearance",
  "p.opposite_direction_tolerance",
  "p.turn_yaw_tolerance"
 ],
 "narrowings": [
  {
   "span": "f13",
   "why": "'the drivers' are read through the vehicles' controlled motion.",
   "kind": "observable_reading",
   "category": "agency"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "Vehicle t, within the intersection with int.left_turn and its left indicator on since its approach, waited while no oncoming vehicle was close and now turns left. Ego approaches from the opposite direction and keeps moving; their projected closest approach lies within p.conflict_horizon below p.conflict_clearance."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "Same scene; ego slows and comes to rest at the edge of the intersection until t completes its turn."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "t crosses the intersection straight ahead (no int.left_turn, not turning left); ego approaches from the opposite direction."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "Scene of forbid, but the source declares sig.turn_indicator and sig.hand_signal absent: whether t signalled cannot be read.",
   "masked": [
    "sig.turn_indicator",
    "sig.hand_signal"
   ]
  },
  {
   "name": "branch_1",
   "expected": "not_applicable",
   "narrative": "As forbid, but t's indicator stayed off and it gave no arm signal: t gave no signal, so the opposing drivers' duty does not arise."
  },
  {
   "name": "branch_2",
   "expected": "not_applicable",
   "narrative": "As forbid, but t began its turn while ego was already within the immediate-hazard distance of the intersection: t did not yield as NRS_484B_253_o1 requires, so the duty to yield to it does not arise."
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.rest_speed_tolerance",
   "unit": "m/s",
   "value": 0.1,
   "convention": "Stop-detection noise floor: the speed at or below which a sampled speed counts as no movement, set at the resolution of the speed measurement so that a complete cessation from movement is recognized despite sensor jitter.",
   "source": "Naturalistic-driving and simulator stop-detection practice (SHRP 2 event coding; CARLA ground-truth velocity resolution)."
  },
  {
   "name": "p.conflict_horizon",
   "unit": "s",
   "value": 3.0,
   "convention": "Time-to-collision horizon of the traffic-conflict technique: a projected approach of the centres within this time counts toward the danger of a crash.",
   "source": "Hayward (1972) time-to-collision; Hyden (1987) Swedish Traffic Conflict Technique; van der Horst (1990) TTC thresholds."
  },
  {
   "name": "p.conflict_clearance",
   "unit": "m",
   "value": 3.0,
   "convention": "Centre-to-centre distance at the projected closest approach below which the bodies of two passenger vehicles would touch or nearly touch (about a half-length plus a half-width of a design passenger car).",
   "source": "AASHTO Green Book, design vehicle P dimensions."
  },
  {
   "name": "p.opposite_direction_tolerance",
   "unit": "ratio",
   "value": 0.866,
   "convention": "Cosine of the largest angle off exactly opposed at which two approach directions still count as opposite (thirty degrees), covering skewed approaches.",
   "source": "Trajectory-processing conventions for opposing-movement classification at intersections (inD)."
  },
  {
   "name": "p.turn_yaw_tolerance",
   "unit": "deg/s",
   "value": 5.0,
   "convention": "Yaw rate below which a change of heading counts as none: above lane-keeping yaw noise, below the yaw rates of turning at a junction.",
   "source": "Vehicle-dynamics practice for turn-onset detection from yaw-rate sensors."
  }
 ],
 "gaps": [],
 "gap_resolutions": [],
 "planned_on": {}
}


- rule: `/local-scratch2/sma407/smoke32-run/pipeline/traffic-spec-agent/library/TrafficSpec/Rules/NRS_484B/NRS_484B_253_o2.lean` — `namespace TrafficSpec.Rules.NRS_484B_253_o2`, `def rule : Rule`
- witness: `/local-scratch2/sma407/smoke32-run/pipeline/traffic-spec-agent/library/TrafficSpecWitness/NRS_484B/NRS_484B_253_o2.lean` — `namespace TrafficSpecWitness.NRS_484B_253_o2`, `def scenarios : List Scenario`
- imports: the rule file imports `TrafficSpec.Core.Language.Rule` only; the witness file imports `TrafficSpec.Rules.NRS_484B.NRS_484B_253_o2` and `TrafficSpec.Core.Evidence.Builders`
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

### Concept catalogue (accepted concepts; call by Lean name = id with `.` → `_`)
| id | kind | contract | definition | args | params | reads | calls |
|---|---|---|---|---|---|---|---|
| `drv.motion.at_rest` | formula | A road user is at rest at an observation: the observable form of a stop where one is required, "complete cessation from movement". It holds at each observation at which the road user's speed (kin.speed, m/s) is at or below the speed tolerance, the speed at or below which a sampled measurement counts as no movement, and at no other. Not a stand-in for the brake lamp or the brake input, which are actuations and not motion, or for a halt at a particular place, which a caller states with its own relations. | DEF-NRS-484A-255 | a:track | speed_tolerance (m/s) | kin.speed | no concept |
| `drv.motion.turning_left` | formula | Road user a is turning to the left at an observation: it moves and its heading turns to the left. Measured as a not at rest (drv.motion.at_rest with the speed tolerance does not hold) and its yaw rate (kin.yaw_rate, deg/s, left positive) at or above the yaw tolerance, the rate below which a change of heading counts as none. A state at each observation while a turn is under way, not a completed manoeuvre: it does not say how far the turn goes, and it holds alike where the road user follows a bend of the road to the left. Not a stand-in for the turn indicator or for a declared intention to turn. |  | a:track | yaw_tolerance (deg/s), speed_tolerance (m/s) | kin.speed, kin.yaw_rate | `drv.motion.at_rest` |

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
def kin_position (s : Scene) (x : TrackId) : Option Vec := (s.user x).bind (·.kin.position)
def kin_velocity (s : Scene) (x : TrackId) : Option Vec := (s.user x).bind (·.kin.velocity)
def kin_speed (s : Scene) (x : TrackId) : Option Q := (s.user x).bind (·.kin.speed)
def kin_yaw_rate (s : Scene) (x : TrackId) : Option Q := (s.user x).bind (·.kin.yawRate)
def isKind (s : Scene) (r : RegionId) (k : StructureKind) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def st_travel_region (s : Scene) (r : RegionId) : Option Bool := isKind s r .travelRegion
def st_lane_direction (s : Scene) (r : RegionId) : Option Vec := (s.structure? r).bind (·.lane) |>.bind (·.direction)
def st_lane_enters (s : Scene) (r : RegionId) : Option RegionId := (st_lane_adjacency s r).bind (·.entersIntersection)
def st_intersection (s : Scene) (r : RegionId) : Option Bool := isKind s r .intersection
def footprint (s : Scene) (x : TrackId) : Option (List Vec) := do
def regionsOfKind (s : Scene) (k : StructureKind) : List RegionId :=  -- (body continues in Vocab/Atoms.lean)
def regionCandidates (s : Scene) (k : StructureKind) : List RegionId :=  -- (body continues in Vocab/Atoms.lean)
def rel_occupies (s : Scene) (x : TrackId) (r : RegionId) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def rel_occupies_regions (s : Scene) (x : TrackId) : Option (List RegionId) :=  -- (body continues in Vocab/Atoms.lean)
def devKind (s : Scene) (d : DeviceId) (k : DeviceKind) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def devicesOfKind (s : Scene) (k : DeviceKind) : List DeviceId :=  -- (body continues in Vocab/Atoms.lean)
def deviceCandidates (s : Scene) (k : DeviceKind) : List DeviceId :=  -- (body continues in Vocab/Atoms.lean)
def sig_turn_indicator (s : Scene) (x : TrackId) : Option TurnIndicatorState := (s.user x).bind (·.sig.turnIndicator)
def sig_hand_signal (s : Scene) (x : TrackId) : Option HandSignal := (s.user x).bind (·.sig.handSignal)
```

(The accessor and primitive tables are cut to what the record claims and what its concepts read; every other name is off limits for this task, and the whole tables are in the files named.)

### Primitives (`Vocab/Primitives.lean`): Lean signature (the parameters after the tracks are the formula's `params`, in order), contract, formula arity
```lean
def prim_closest_approach_within (c : Ctx) (a b : TrackId) (horizon : Q) : Array R
    -- The centres approach each other within the horizon.
    -- formula form: args [a, b] params [h]
def prim_closest_approach_distance (c : Ctx) (a b : TrackId) (horizon : Q) : Array QR
    -- The centre distance at closest approach; undefined when the centres do not approach within the horizon.
    -- formula form: args [a, b] params [h]
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
| `NRS_484B_253_o1` | another rule of the library; its verdict, or whether it applies, is read here |
| `drv.motion.at_rest` | A road user is at rest at an observation: the observable form of a stop where one is required, "complete cessation from movement". It holds at each observation at which the road user's speed (kin.speed, m/s) is at or below the speed tolerance, the speed at or below which a sampled measurement counts as no movement, and at no other. Not a stand-in for the brake lamp or the brake input, which are actuations and not motion, or for a halt at a particular place, which a caller states with its own relations. |
| `drv.motion.turning_left` | Road user a is turning to the left at an observation: it moves and its heading turns to the left. Measured as a not at rest (drv.motion.at_rest with the speed tolerance does not hold) and its yaw rate (kin.yaw_rate, deg/s, left positive) at or above the yaw tolerance, the rate below which a change of heading counts as none. A state at each observation while a turn is under way, not a completed manoeuvre: it does not say how far the turn goes, and it holds alike where the road user follows a bend of the road to the left. Not a stand-in for the turn indicator or for a declared intention to turn. |
| `int.left_turn` | The road user's current plan includes turning left at the target region. |
| `kin.position` | position of the body's reference point |
| `kin.speed` | magnitude of velocity |
| `kin.velocity` | velocity vector |
| `kin.yaw_rate` | rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres |
| `prim.closest_approach_distance` | the centre distance at that closest approach; undefined when they do not approach within the horizon **Not a stand-in for:** contact between bodies, the clearance between bodies, or the danger of a crash — it is computed from the centres under constant velocities, and alone establishes none of them |
| `prim.closest_approach_within` | under constant velocities, the centres of two road users approach each other at some time between the observation and the horizon **Not a stand-in for:** contact between bodies, the clearance between bodies, or the danger of a crash — it is computed from the centres under constant velocities, and alone establishes none of them |
| `rel.occupies` | a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure) |
| `ru.aggregate` | membership of a legal aggregate: the atom's literal argument is an aggregate id, `<definition id>::<term>` for the posted definition that applies, or `<law id>:<span>::<term>` for a definition the law itself makes, and the run's reading classifies every road-user class under that id by the definition's words as included, excluded (the definition leaves it out), covered (the definition admits its members only as members of named included classes, which a road user carries beside it, so its own label adds no membership evidence) or unresolved; true when the user carries an included class, unknown when no included class holds and the user carries an unresolved class or an included or unresolved class it might carry is unobserved, false otherwise: a covered or excluded class decides nothing **Not a stand-in for:** a named road-user class for which the applicable definitions and the run's representation decisions permit its own class atom — that class's own atom; an admitted aggregate stays an aggregate even when it contains only one class; a relational role such as who drives or controls a vehicle — never membership; nor a role the text describes by conduct (responding, overtaking) — a role is a derived concept |
| `sig.hand_signal` | a driver's or rider's arm signal; **meaning** ∈ {no_signal, left, right, stop_or_slow, re_enter}: no arm signal given, or the meaning of the one given |
| `sig.turn_indicator` | the turn indicator **state** ∈ {off, left, right}: neither indicator lit, or the left or the right one **Not a stand-in for:** the turn or lane change itself — the indicator is the signal that precedes a manoeuvre, judged separately from it |
| `st.intersection` | the region where two roadways meet, bounded by the prolongation of their edges; a junction where an alley meets another way (a street, road, highway or alley) is no intersection but a `st.driveway_or_alley_entrance` **Not a stand-in for:** a crosswalk or a stop line — a stop before the crossing is earlier than a stop before the intersection **Refines:** `st.travel_region` |
| `st.lane_direction` | direction of travel designated for a structure a vehicle travels in — a lane, reserved lane, turn lane, bicycle lane or path, or a roadway, one-way roadway or shoulder; a centre turn lane carries none. The direction is local to its carrier (a bend or a loop is written as segments), carriers that overlap or cross may carry different directions, and a place no carrier covers has none (unknown). It is written at any length; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown |
| `st.lane_enters` | relation: the intersection region a directed approach carrier runs into at its entrance end — the carrier is an approach to that intersection. A carrier is a lane or a kind refining it, or a roadway, one-way roadway, shoulder or bicycle lane or path that the source records as a directed approach segment: the stretch one direction of travel uses to reach one junction, its entrance end at that junction. A bicycle lane or path stays its own kind, not a lane, and a mark or a device's governance on it does not pass to an adjacent lane, nor theirs to it. A two-way road between two junctions is written, where the source can separate its directions, as one segment per direction, each entering the junction its direction reaches; each keeps its kind, and none is relabelled one-way for having a direction, nor is a lane written where the road has none. Writing the relation on a roadway, one-way roadway, shoulder or bicycle lane or path asserts that it is such a segment: a whole two-way roadway or bicycle path, with an end at each junction, carries none, and which junction it is an approach to stays unknown. A carrier enters one intersection at most. The relation is entry topology: it is decided where the source records it, whether or not the carrier's direction (`st.lane_direction`) is observed. It is the source's record, never inferred from distance, overlap or a road user's velocity, and a carrier never takes the entrance of a carrier it overlaps. **Which carrier a road user approaches through:** a road user's approach to an intersection is a carrier it occupies (`rel.occupies`) whose entrance end is that intersection, and the mark that governs that approach is one the source records as marking that carrier (`st.entrance_of`). The intersection is fixed by the event the rule reads (the intersection entered, or the one the words name), never by the road user's velocity or heading, by distance or by overlap. A road user occupying one such carrier approaches through it whatever its motion: forward, at rest, backing, or with its velocity or heading unobserved. Overlapping carriers that enter different intersections are told apart by the intersection, not by motion. Where it occupies several carriers entering the same intersection and the verdict differs between them (different marks, or one mark's association unobserved), which governs is unknown; where the verdict is the same through each, it is decided; a rule never picks the carrier that favours the road user. Travel against a carrier's direction does not change which intersection the carrier enters, and reaching a carrier's far (exit) end is no entry through it **Not a stand-in for:** the lane a lane leads into (`st.lane_connectivity`), the subject's presence in the intersection (`rel.occupies`), or the region a device governs (`dev.governs`) — a device governs a lane and the lane enters an intersection; which intersection a device controls is read through both, or directly where the device governs the intersection |
| `st.travel_region` | **Abstract.** the union of the kinds a device can govern (`dev.governs`): a lane and the kinds that refine it, a bicycle lane or path, a roadway and the kinds that refine it, a shoulder, or an intersection; a region is a travel region exactly when it is of one of them **Not a stand-in for:** the extent of a highway (`st.highway`, `st.on_way`) — a sidewalk, a crosswalk, a stop line or the way as a whole is no travel region; travel along or across a way, which the road user's motion and the region's direction state, never the kind of the region occupied; or which entry into an intersection a region is (`st.lane_enters`, `st.entrance_of`) |

| parameter | value | unit | convention |
|---|---|---|---|
| `p.conflict_clearance` | 3.0 | m | Centre-to-centre distance at the projected closest approach below which the bodies of two passenger vehicles would touch or nearly touch (about a half-length plus a half-width of a design passenger car). |
| `p.conflict_horizon` | 3.0 | s | Time-to-collision horizon of the traffic-conflict technique: a projected approach of the centres within this time counts toward the danger of a crash. |
| `p.opposite_direction_tolerance` | 0.866 | ratio | Cosine of the largest angle off exactly opposed at which two approach directions still count as opposite (thirty degrees), covering skewed approaches. |
| `p.rest_speed_tolerance` | 0.1 | m/s | Stop-detection noise floor: the speed at or below which a sampled speed counts as no movement, set at the resolution of the speed measurement so that a complete cessation from movement is recognized despite sensor jitter. |
| `p.turn_yaw_tolerance` | 5.0 | deg/s | Yaw rate below which a change of heading counts as none: above lane-keeping yaw noise, below the yaw rates of turning at a junction. |

Admitted aggregates the node claims (a witness's road user is a member when it carries an included class; one carrying only an unresolved class makes the atom unknown):

- `DEF-NRS-484A-320::vehicle`: included ru.bus, ru.commercial_motor_vehicle, ru.emergency_vehicle, ru.fire_apparatus, ru.moped, ru.motor_vehicle, ru.motorcycle, ru.official_vehicle, ru.school_bus, ru.taxicab, ru.tour_bus_or_limousine, ru.trailer_or_combination, ru.transit_bus, ru.truck; unresolved ru.rail_vehicle

The catalogue is `results/smoke32-1111-2102/reading.json` (read-only). Values enter a witness's geometry only: a `forbid` scene breaks the bound by a clear margin, a `permit` scene keeps it by one.

Acquisition standard: profile `carla_scene_graph`. Every `headingSince` step bound in a rule is exactly `.param "p.heading_since_step_carla_scene_graph"`, the operator's reviewed parameter: name it as it is, never propose it or a value for it.

(no node accepted yet in this library; the skeletons below are the pattern, the Core surface the vocabulary)

```lean
-- library/TrafficSpec/Rules/NRS_484B/NRS_484B_253_o2.lean (as written by the harness)
/-
  NRS_484B_253_o2 — NRS-484B-253

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    f1 (condition): The driver of a vehicle
    f2 (condition): within an intersection
    f3 (condition): intending to turn to the left
    f4 (sibling): shall yield
    f5 (sibling): the right-of-way
    f6 (sibling): to any vehicle approaching from the opposite direction
    f7 (sibling): which is within the intersection
    f8 (sibling): or so close thereto as to constitute an immediate hazard,
    f9 (boilerplate): but such driver,
    f10 (condition): having so yielded
    f11 (condition): and having given a signal when and as required,
    f12 (condition): may make such left turn
    f13 (subject): and the drivers of all other vehicles approaching the intersection from the opposite direction
    f14 (obligation): shall yield
    f15 (standard): the right-of-way
    f16 (condition): to the vehicle making the left turn.

  Elements (span → atoms, derived):
    f1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    f2: atoms ['st.intersection', 'rel.occupies'], derived []
    f11: atoms ['sig.turn_indicator', 'sig.hand_signal'], derived []
    f12: atoms [], derived ['drv.motion.turning_left']
    f13: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.lane_enters', 'st.lane_direction', 'st.travel_region', 'rel.occupies'], derived []
    f14: atoms [], derived ['drv.motion.at_rest']
    f16: atoms [], derived ['drv.motion.turning_left']

  Compositions (span → node, as, map):
    f10: NRS_484B_253_o1 as compliance map {'ego': 't'}

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_253_o2

/-- The binders, as arguments (order and names are the node's). -/
def vEgo : Arg := .var "ego"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictClearance : Term := .param "p.conflict_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pOppositeDirectionTolerance : Term := .param "p.opposite_direction_tolerance"
def pRestSpeedTolerance : Term := .param "p.rest_speed_tolerance"
def pTurnYawTolerance : Term := .param "p.turn_yaw_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

-- TODO(code): class formulas, applicability and obligation — from the node's elements,
-- operationalizations and compositions, using only the claimed names. `.tt` is the placeholder.

/-- Class of `ego`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsEgo : Formula := .tt  -- TODO

/-- Applicability: f1 (condition): The driver of a vehicle; f2 (condition): within an intersection; f3 (condition): intending to turn to the left; f10 (condition): having so yielded; f11 (condition): and having given a signal when and as required,; f12 (condition): may make such left turn; f16 (condition): to the vehicle making the left turn. -/
def applicability : Formula := .tt  -- TODO

/-- Obligation: f14 (obligation): shall yield; f15 (standard): the right-of-way -/
def obligation : Formula := .tt  -- TODO

def rule : Rule :=
  { id := "NRS_484B_253_o2"
    laws := ["NRS-484B-253"]
    binders :=
      [ { name := "ego", cls := clsEgo } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations :=
      [ { standard := "the right-of-way: DEF-NRS-484A-210 \"approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other\""
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_clearance"]
          convention := "Traffic-conflict technique: two road users are in conflict where, projected at their current velocities, their centres approach within the time-to-collision horizon and their closest-approach centre distance is below the clearance at which their bodies would touch. Direction, speed and proximity enter by degree through the projected velocities and positions."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_253_o2

```

```lean
-- library/TrafficSpecWitness/NRS_484B/NRS_484B_253_o2.lean (as written by the harness)
/-
  Witnesses for NRS_484B_253_o2.

  TODO(code): describe the geometry once built — the carriageway, the bodies, the instants; every
  figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_253_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_253_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: ego ↦ 1

/-- `forbid` (violated): Vehicle t, within the intersection with int.left_turn and its left indicator on since its approach, waited while no oncoming vehicle was close and now turns left. Ego approaches from the opposite direction and keeps moving; their projected closest approach lies within p.conflict_horizon below p.conflict_clearance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `permit` (compliant): Same scene; ego slows and comes to rest at the edge of the intersection until t completes its turn. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `idle` (not_applicable): t crosses the intersection straight ahead (no int.left_turn, not turning left); ego approaches from the opposite direction. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `blind` (unknown): Scene of forbid, but the source declares sig.turn_indicator and sig.hand_signal absent: whether t signalled cannot be read. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `branch_1` (not_applicable): As forbid, but t's indicator stayed off and it gave no arm signal: t gave no signal, so the opposing drivers' duty does not arise. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `branch_2` (not_applicable): As forbid, but t began its turn while ego was already within the immediate-hazard distance of the intersection: t did not yield as NRS_484B_253_o1 requires, so the duty to yield to it does not arise. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_253_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("ego", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["sig.turn_indicator", "sig.hand_signal"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_253_o2

```

Run exactly this command, nothing more and nothing else:

```
python -m harness gate --run_id smoke32-1111-2102 --node_id NRS_484B_253_o2
```

It prints the verdict and its details. The verdicts on your files: SCOPE_VIOLATION, BUILD_FAIL, UNSOUND, CHECK_FAIL, UNANCHORED_VARIABLE, DECLARATION_MISMATCH, SCOPE_NARROWED, UNEXPRESSED, UNCLAIMED_ATOM, UNUSED_CLAIM, BARE_LITERAL, WITNESS_FAIL, VACUOUS, PARAM_MISMATCH, GATE_TIMEOUT, OK. `INFRA` is not one: the toolchain or the run did not let the gate judge your files. Budget: 6 runs; the harness re-runs the gate itself after you stop, on the files as they are then.


## Access

- You **edit** `/local-scratch2/sma407/smoke32-run/pipeline/traffic-spec-agent/library/TrafficSpec/Rules/NRS_484B/NRS_484B_253_o2.lean` and `/local-scratch2/sma407/smoke32-run/pipeline/traffic-spec-agent/library/TrafficSpecWitness/NRS_484B/NRS_484B_253_o2.lean` with the Edit and Write tools, and write
  `task_result.md` (and, when you report a concept, `dependency_defect.json`) in your working
  directory. Nothing else is writable.
- You **may read**, with the Read tool and by absolute path, the Core files under `/local-scratch2/sma407/smoke32-run/pipeline/traffic-spec-agent/library/TrafficSpec/Core`
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

1. **Two files.** Edit `/local-scratch2/sma407/smoke32-run/pipeline/traffic-spec-agent/library/TrafficSpec/Rules/NRS_484B/NRS_484B_253_o2.lean` and `/local-scratch2/sma407/smoke32-run/pipeline/traffic-spec-agent/library/TrafficSpecWitness/NRS_484B/NRS_484B_253_o2.lean` only; their paths and the namespace
   `TrafficSpec.Rules.NRS_484B_253_o2` are derived from the node id and are not yours to choose. Declare
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
   around a missing operator is not a narrowing. `no_atom` means no atom of the surface can carry
   the words. Words that an atom of the surface can carry, but which the node does not claim, are a
   defect of the node's mapping: you never declare `no_atom` on them and never write them with that
   atom; the node is wrong, and you report it. The gate holds every narrowing to a span of the
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

Working directory: `/local-scratch2/sma407/smoke32-run/pipeline/traffic-spec-agent/results/smoke32-1111-2102/iter-001/code/NRS_484B_253_o2`. Write `task_result.md` there.
