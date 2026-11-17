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
 "node_id": "NRS_484B_270_2b_o3",
 "law_refs": [
  "NRS-484B-270-2b"
 ],
 "segmentation": [
  {
   "id": "b1",
   "text": "When overtaking or passing",
   "role": "trigger"
  },
  {
   "id": "b2",
   "text": "a bicycle, an electric bicycle or an electric scooter",
   "role": "trigger"
  },
  {
   "id": "b3",
   "text": "proceeding in the same direction,",
   "role": "trigger"
  },
  {
   "id": "b4",
   "text": "the driver of a motor vehicle",
   "role": "subject"
  },
  {
   "id": "b5",
   "text": "shall exercise due care and:",
   "role": "sibling"
  },
  {
   "id": "b6",
   "text": "If there is only one lane for traffic proceeding in the same direction,",
   "role": "condition"
  },
  {
   "id": "b7",
   "text": "pass to the left of the bicycle, electric bicycle or electric scooter",
   "role": "sibling"
  },
  {
   "id": "b8",
   "text": "at a safe distance, which must be not less than 3 feet between any portion of the vehicle and the bicycle, electric bicycle or electric scooter,",
   "role": "sibling"
  },
  {
   "id": "b9",
   "text": "and shall not move again to the right side of the highway",
   "role": "obligation"
  },
  {
   "id": "b10",
   "text": "until the vehicle is safely clear of the overtaken bicycle, electric bicycle or electric scooter.",
   "role": "standard"
  },
  {
   "id": "b11",
   "text": "Except as otherwise provided in NRS 484B.213 and 484B.217 [NRS-484B-213-1, NRS-484B-213-2a, NRS-484B-213-2b, NRS-484B-213-2c, NRS-484B-217-2],",
   "role": "reference"
  },
  {
   "id": "b12",
   "text": "when passing to the left of a bicycle, electric bicycle or electric scooter at a safe distance of not less than 3 feet between any portion of the vehicle and the bicycle, electric bicycle or electric scooter, this paragraph authorizes the driver, if it is safe, to pass: (1) To the left of the center of the highway. (2) In a no-passing zone.",
   "role": "exception"
  }
 ],
 "subject": {
  "binder": "subject",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-130::motor_vehicle"
  ]
 },
 "elements": [
  {
   "span": "b1",
   "atoms": [
    "rel.longitudinal_overlap"
   ],
   "derived": [
    "drv.interaction.overtake_pass"
   ],
   "justification": "'overtaking or passing' a road user proceeding the same way is drv.interaction.overtake_pass(subject, r): 'a, travelling in the same direction as b, comes from having b ahead of it to having b behind it'; it denotes the relative motion only. Here the pass is read while under way - the bodies side by side (rel.longitudinal_overlap at or above zero; a projection, not a contact or a distance) after the rider was ahead within the window - and once completed, from the observation at which the concept rises, within the window."
  },
  {
   "span": "b2",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-025::bicycle",
    "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
    "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
   ],
   "derived": [],
   "justification": "'a bicycle' is DEF-NRS-484A-025::bicycle ('a device propelled by human power upon which a person may ride'), 'an electric bicycle' DEF-NRS-484B-017::electric_bicycle, 'an electric scooter' DEF-NRS-484B-018::electric_scooter ('a vehicle with handlebars and an electric motor that is designed to be ridden on'); each admitted aggregate claimed whole."
  },
  {
   "span": "b3",
   "atoms": [
    "rel.same_direction",
    "kin.speed"
   ],
   "derived": [],
   "justification": "'proceeding' is the overtaken road user moving (kin.speed above the halt tolerance); 'in the same direction' is rel.same_direction ('headings aligned') between the subject and it."
  },
  {
   "span": "b4",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-130::motor_vehicle"
   ],
   "derived": [],
   "justification": "'a motor vehicle' is DEF-NRS-484A-130::motor_vehicle ('every vehicle which is self-propelled but not operated upon rails'). 'the driver' is read through the vehicle's controlled motion."
  },
  {
   "span": "b6",
   "atoms": [
    "rel.occupies",
    "st.lane",
    "st.lane_adjacency"
   ],
   "derived": [],
   "justification": "'only one lane for traffic proceeding in the same direction' is the count of lanes in the direction of a lane (st.lane) the overtaken rider occupies (rel.occupies) being the stated one (st.lane_adjacency, 'the count of lanes in that direction'). 'traffic' names the users of the lane; no membership is read."
  },
  {
   "span": "b9",
   "atoms": [
    "rel.occupies",
    "st.lane",
    "rel.bearing"
   ],
   "derived": [
    "drv.lane.heading_right_of_carrier"
   ],
   "justification": "'move again to the right side of the highway': having moved out to the left of the rider (rel.bearing from the subject, lateral component negative: the rider on its right), the subject turns back toward the side the rider keeps: drv.lane.heading_right_of_carrier(subject, L) for a lane L (st.lane) the rider occupies (rel.occupies) - 'a, moving, points to the right of the designated direction of travel of carrier region r by more than a tolerance'. The concept says nothing of whether the subject occupies L, so it reads a move back toward the rider's lane from the opposing lane or from the left part of the rider's lane alike. 'again' fixes the order: the subject first had the rider on its right."
  }
 ],
 "operationalizations": [
  {
   "span": "b10",
   "standard": "until the vehicle is safely clear of the overtaken bicycle",
   "concepts": [
    "rel.surface_gap",
    "rel.bearing",
    "rel.longitudinal_overlap",
    "kin.speed",
    "env.ice_or_snow",
    "env.wet_road",
    "env.precipitation"
   ],
   "params": [
    "p.following_headway_dry",
    "p.following_headway_wet",
    "p.following_headway_ice"
   ],
   "convention": "time headway: the subject (the vehicle) is safely clear of the overtaken rider where the rider is behind it (rel.bearing longitudinal component negative, rel.longitudinal_overlap negative) with a gap between the bodies (rel.surface_gap) of at least the rider's speed times the following headway for the surface - ice or snow, else wet road or precipitation, else dry - so that the rider, following, keeps the headway a following road user keeps",
   "surrogate": false
  }
 ],
 "assumptions": [],
 "intentions": [],
 "compositions": [
  {
   "span": "b11",
   "rule": "NRS_484B_213_1",
   "map": {
    "subject": "subject"
   },
   "as": "unless",
   "scopes": "b12"
  },
  {
   "span": "b11",
   "rule": "NRS_484B_213_2a",
   "map": {
    "subject": "subject"
   },
   "as": "unless",
   "scopes": "b12"
  },
  {
   "span": "b11",
   "rule": "NRS_484B_213_2b",
   "map": {
    "subject": "subject"
   },
   "as": "unless",
   "scopes": "b12"
  },
  {
   "span": "b11",
   "rule": "NRS_484B_213_2c",
   "map": {
    "subject": "subject"
   },
   "as": "unless",
   "scopes": "b12"
  },
  {
   "span": "b11",
   "rule": "NRS_484B_217_2",
   "map": {
    "subject": "subject"
   },
   "as": "unless",
   "scopes": "b12"
  }
 ],
 "residues": [
  {
   "span": "b12",
   "why": "the authorization lets a driver passing a rider at the stated clearance pass left of the center or in a no-passing zone, conduct other rules (NRS 484B.213, 484B.217) forbid; it relaxes those rules and leaves the duty not to move back right before being clear unchanged",
   "scope": "none"
  }
 ],
 "binders": [
  {
   "name": "subject",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-130::motor_vehicle"
   ]
  }
 ],
 "applicability": "The subject is a member of DEF-NRS-484A-130::motor_vehicle. Some road user r, not the subject, a member of DEF-NRS-484A-025::bicycle, DEF-NRS-484B-017::electric_bicycle or DEF-NRS-484B-018::electric_scooter, moving (kin.speed above p.halt_speed_tolerance) with its heading aligned with the subject's (rel.same_direction, p.overtake_same_direction_cos), is being overtaken by the subject: at some observation of the window behind of length p.overtake_window r was ahead of the subject (rel.bearing longitudinal component positive, rel.longitudinal_overlap negative) with aligned headings, and either r is not yet behind the subject or drv.interaction.overtake_pass(subject, r) (window p.overtake_window, same_dir_cos p.overtake_same_direction_cos) has risen at some observation of that window; r lies on the subject's right (rel.bearing lateral component negative); and r occupies a st.lane whose count of lanes in its direction (st.lane_adjacency count) is the literal one.",
 "obligation": "For every such r (re-bound with its whole selection), where r is not safely clear behind the subject - that is, not (r behind the subject, rel.bearing longitudinal component negative and rel.longitudinal_overlap negative, with rel.surface_gap at least r's kin.speed times the headway: p.following_headway_ice where env.ice_or_snow holds, else p.following_headway_wet where env.wet_road or env.precipitation holds, else p.following_headway_dry) - the subject does not move to the right: drv.lane.heading_right_of_carrier(subject, L) with sin_tol p.course_departure_sin_tol and speed_tol p.halt_speed_tolerance holds for no st.lane L that r occupies (rel.occupies).",
 "params": [
  "p.overtake_window",
  "p.overtake_same_direction_cos",
  "p.halt_speed_tolerance",
  "p.course_departure_sin_tol",
  "p.following_headway_dry",
  "p.following_headway_wet",
  "p.following_headway_ice"
 ],
 "narrowings": [
  {
   "span": "b4",
   "why": "'the driver' of a motor vehicle is read through the vehicle's controlled motion",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "b9",
   "why": "'move again to the right side of the highway' is read as the subject's heading turned to the right of the rider's lane direction beyond the course tolerance, after it has the rider on its right; a gradual drift within that tolerance is not read",
   "kind": "reading"
  },
  {
   "span": "b10",
   "why": "'safely clear' is read as the rider behind the subject at a time-headway gap at the rider's speed; the rider's own braking ability is not otherwise read",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "Road with one lane in the subject's direction; the subject car moves out left and overtakes a bicycle; while the bicycle is still beside it, the subject car steers back to the right, its heading turning right of the lane's direction beyond the course tolerance."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "Same pass; the subject car keeps its course until the bicycle is behind it at a gap above the bicycle's speed times the dry headway, then steers back right."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "The subject car drives alone on a road with one lane in its direction and steers to the right; no other road user is in the scene, so no bicycle, electric bicycle or electric scooter is being overtaken. The duty binds the subject alone."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "As in forbid, but the source does not observe the lanes' designated direction of travel, so whether the subject's heading turned right of the rider's lane is unknown while the rider, still beside it, is decided not clear.",
   "masked": [
    "st.lane_direction"
   ]
  },
  {
   "name": "branch_1",
   "expected": "violated",
   "narrative": "The subject car completes the pass of a bicycle on a road with one lane in its direction and steers back right at once, as the pass is recognized, the bicycle behind it at a gap below its speed times the dry headway."
  },
  {
   "name": "branch_2",
   "expected": "not_applicable",
   "narrative": "The road has two lanes in the subject's direction; the subject passes a bicycle and steers back right while beside it."
  }
 ],
 "literals": [
  {
   "span": "b6",
   "text": "one",
   "value": 1,
   "unit": "count"
  }
 ],
 "param_proposals": [],
 "gaps": [],
 "gap_resolutions": [],
 "planned_on": {
  "NRS_484B_213_1": "b43650250eba37f8cc8111b748ea7fcea5f58cef4346c0ab29cf5ea3b9138ba8",
  "NRS_484B_213_2a": "00e8ee383ecb3afe034de960c1b57acbdb597dffacaf09c66a6ef5d7daadbc53",
  "NRS_484B_213_2b": "9285adfb21c2aeab68f58a2ab797b2f96b227256a5bceb8c7bfa6a6c47953398",
  "NRS_484B_213_2c": "0035d2544bb42d2ad6302a5f6f7a07606513c991e54d4cd3015e3340ce4cf5cf",
  "NRS_484B_217_2": "23f721897da9ef9047a0e759beb58a1ef7b111f13211b17875d68c402f5aab54"
 }
}


- rule: `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpec/Rules/NRS_484B/NRS_484B_270_2b_o3.lean` — `namespace TrafficSpec.Rules.NRS_484B_270_2b_o3`, `def rule : Rule`
- witness: `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpecWitness/NRS_484B/NRS_484B_270_2b_o3.lean` — `namespace TrafficSpecWitness.NRS_484B_270_2b_o3`, `def scenarios : List Scenario`
- imports: the rule file imports `TrafficSpec.Core.Language.Rule` only; the witness file imports `TrafficSpec.Rules.NRS_484B.NRS_484B_270_2b_o3` and `TrafficSpec.Core.Evidence.Builders`
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
| `drv.interaction.overtake_pass` | formula | Road user a overtakes and passes road user b from the rear: a, travelling in the same direction as b, comes from having b ahead of it to having b behind it. b is ahead of a where the longitudinal component of b's bearing in a's frame, the component along a's heading (kin.heading) of the vector from a's position to b's position (kin.position), is positive and the two bodies' projections on a's heading share no length (rel.longitudinal_overlap negative); b is behind a where that component is negative and the projections share no length. The act begins at the last observation of the window behind at which b was ahead of a with their headings aligned within same_dir_cos (rel.same_direction). The act is recognized at the observation at which b is behind a and was not behind a at the previous observation, where b was ahead of a with headings aligned at some observation of the window behind. The concept holds at that observation only, and not again until b has again been ahead of a and then comes to be behind it. Conduct before the window behind is not read: a pass that takes longer than the window is not recognized. It denotes the relative motion of the two road users only: it says nothing of the lanes they occupy, of whether b moves, or of why a passes. Not denoted: a drawing alongside b that does not clear b; b ahead of a only while their headings are not aligned (a road user met head-on or crossing); b behind a at every observation of the window. Where the positions of a and b are unobserved, it is unknown. **Review notes (not confirmed differences):** Tested a pass recognized one second after the recording begins, within a two-second window. The observed aligned-ahead and first-behind observations suffice: the body holds, agreeing with the contract despite the truncated history. |  | a:track, b:track | window (s), same_dir_cos (ratio) | kin.heading, kin.position, kin.time, rel.longitudinal_overlap, rel.same_direction | no concept |
| `drv.lane.heading_right_of_carrier` | formula | Road user a, moving, points to the right of the designated direction of travel of carrier region r by more than a tolerance: its heading has turned off r's direction toward the right. With h a's heading (kin.heading) and d r's designated direction (st.lane_direction), both as a formula reads them normalised, the dot product of d and h is positive, so that a points along d rather than against it, and the cross product d_x times h_y minus d_y times h_x is below minus sin_tol, so that h lies to the right of d, clockwise in the world frame, by more than the angle whose sine is sin_tol; and a's speed (kin.speed) is above speed_tol. It is a state at one observation: it says nothing of whether a occupies r, of how long its heading has been so, of the path a will follow, or of why it turns. Not denoted: a road user at rest or moving at or below speed_tol; a heading within that angle of d, or turned to its left; a heading that points against d, the dot product being at or below zero. Where r carries no designated direction, or a's heading or speed is unobserved, it is unknown. |  | a:track, r:region | sin_tol (ratio), speed_tol (m/s) | kin.heading, kin.speed, st.lane_direction | no concept |

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
def kin_time (s : Scene) : Timestamp := s.t
def kin_position (s : Scene) (x : TrackId) : Option Vec := (s.user x).bind (·.kin.position)
def kin_heading (s : Scene) (x : TrackId) : Option Vec := (s.user x).bind (·.kin.heading)
def kin_speed (s : Scene) (x : TrackId) : Option Q := (s.user x).bind (·.kin.speed)
def isKind (s : Scene) (r : RegionId) (k : StructureKind) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def st_lane (s : Scene) (r : RegionId) : Option Bool := isKind s r .lane
def st_lane_direction (s : Scene) (r : RegionId) : Option Vec := (s.structure? r).bind (·.lane) |>.bind (·.direction)
def st_lane_adjacency (s : Scene) (r : RegionId) : Option LaneInfo := (s.structure? r).bind (·.lane)
def st_lane_adjacency_left (s : Scene) (r : RegionId) : Option RegionId := (st_lane_adjacency s r).bind (·.leftNeighbour)
def st_lane_adjacency_right (s : Scene) (r : RegionId) : Option RegionId := (st_lane_adjacency s r).bind (·.rightNeighbour)
def st_lane_adjacency_ordinal (s : Scene) (r : RegionId) : Option Nat := (st_lane_adjacency s r).bind (·.ordinalFromLeft)
def st_lane_adjacency_count (s : Scene) (r : RegionId) : Option Nat := (st_lane_adjacency s r).bind (·.countInDirection)
def st_lane_left_of (s : Scene) (r r' : RegionId) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def st_lane_right_of (s : Scene) (r r' : RegionId) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def footprint (s : Scene) (x : TrackId) : Option (List Vec) := do
def regionsOfKind (s : Scene) (k : StructureKind) : List RegionId :=  -- (body continues in Vocab/Atoms.lean)
def regionCandidates (s : Scene) (k : StructureKind) : List RegionId :=  -- (body continues in Vocab/Atoms.lean)
def rel_occupies (s : Scene) (x : TrackId) (r : RegionId) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def rel_occupies_regions (s : Scene) (x : TrackId) : Option (List RegionId) :=  -- (body continues in Vocab/Atoms.lean)
def devKind (s : Scene) (d : DeviceId) (k : DeviceKind) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def devicesOfKind (s : Scene) (k : DeviceKind) : List DeviceId :=  -- (body continues in Vocab/Atoms.lean)
def deviceCandidates (s : Scene) (k : DeviceKind) : List DeviceId :=  -- (body continues in Vocab/Atoms.lean)
def env_precipitation (s : Scene) : Option Bool := s.env.precipitation
def env_wet_road (s : Scene) : Option Bool := s.env.wetRoad
def env_ice_or_snow (s : Scene) : Option Bool := s.env.iceOrSnow
def rel_surface_gap (s : Scene) (a b : TrackId) : Option (Q × Q) :=  -- (body continues in Vocab/Atoms.lean)
def rel_surface_gap_longitudinal (s : Scene) (a b : TrackId) : Option Q := (rel_surface_gap s a b).map (·.1)
def rel_surface_gap_lateral (s : Scene) (a b : TrackId) : Option Q := (rel_surface_gap s a b).map (·.2)
def rel_surface_gap_distance (s : Scene) (a b : TrackId) : Option Q := (rel_surface_gap s a b).map Geom.norm
def rel_longitudinal_overlap (s : Scene) (a b : TrackId) : Option Q :=  -- (body continues in Vocab/Atoms.lean)
def rel_same_direction (s : Scene) (a b : TrackId) (cosTol : Q) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def rel_bearing (s : Scene) (a b : TrackId) : Option Vec :=  -- (body continues in Vocab/Atoms.lean)
def rel_bearing_right (s : Scene) (a b : TrackId) : Option Bool := (rel_bearing s a b).map fun v => Q.lt v.2 Q.zero
def rel_bearing_left (s : Scene) (a b : TrackId) : Option Bool := (rel_bearing s a b).map fun v => Q.gt v.2 Q.zero
def rel_bearing_ahead (s : Scene) (a b : TrackId) : Option Bool := (rel_bearing s a b).map fun v => Q.gt v.1 Q.zero
def rel_bearing_behind (s : Scene) (a b : TrackId) : Option Bool := (rel_bearing s a b).map fun v => Q.lt v.1 Q.zero
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
| `NRS_484B_213_1` | another rule of the library; its verdict, or whether it applies, is read here |
| `NRS_484B_213_2a` | another rule of the library; its verdict, or whether it applies, is read here |
| `NRS_484B_213_2b` | another rule of the library; its verdict, or whether it applies, is read here |
| `NRS_484B_213_2c` | another rule of the library; its verdict, or whether it applies, is read here |
| `NRS_484B_217_2` | another rule of the library; its verdict, or whether it applies, is read here |
| `drv.interaction.overtake_pass` | Road user a overtakes and passes road user b from the rear: a, travelling in the same direction as b, comes from having b ahead of it to having b behind it. b is ahead of a where the longitudinal component of b's bearing in a's frame, the component along a's heading (kin.heading) of the vector from a's position to b's position (kin.position), is positive and the two bodies' projections on a's heading share no length (rel.longitudinal_overlap negative); b is behind a where that component is negative and the projections share no length. The act begins at the last observation of the window behind at which b was ahead of a with their headings aligned within same_dir_cos (rel.same_direction). The act is recognized at the observation at which b is behind a and was not behind a at the previous observation, where b was ahead of a with headings aligned at some observation of the window behind. The concept holds at that observation only, and not again until b has again been ahead of a and then comes to be behind it. Conduct before the window behind is not read: a pass that takes longer than the window is not recognized. It denotes the relative motion of the two road users only: it says nothing of the lanes they occupy, of whether b moves, or of why a passes. Not denoted: a drawing alongside b that does not clear b; b ahead of a only while their headings are not aligned (a road user met head-on or crossing); b behind a at every observation of the window. Where the positions of a and b are unobserved, it is unknown. |
| `drv.lane.heading_right_of_carrier` | Road user a, moving, points to the right of the designated direction of travel of carrier region r by more than a tolerance: its heading has turned off r's direction toward the right. With h a's heading (kin.heading) and d r's designated direction (st.lane_direction), both as a formula reads them normalised, the dot product of d and h is positive, so that a points along d rather than against it, and the cross product d_x times h_y minus d_y times h_x is below minus sin_tol, so that h lies to the right of d, clockwise in the world frame, by more than the angle whose sine is sin_tol; and a's speed (kin.speed) is above speed_tol. It is a state at one observation: it says nothing of whether a occupies r, of how long its heading has been so, of the path a will follow, or of why it turns. Not denoted: a road user at rest or moving at or below speed_tol; a heading within that angle of d, or turned to its left; a heading that points against d, the dot product being at or below zero. Where r carries no designated direction, or a's heading or speed is unobserved, it is unknown. |
| `env.ice_or_snow` | road surface icy or snow-covered |
| `env.precipitation` | rain or snow falling |
| `env.wet_road` | road surface wet, standing water |
| `kin.heading` | direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown |
| `kin.position` | position of the body's reference point |
| `kin.speed` | magnitude of velocity |
| `kin.time` | instant of observation of a scene |
| `rel.bearing` | direction of b from a in a's frame (for "on the right of", "immediately to the rear") |
| `rel.longitudinal_overlap` | the bodies overlap along the subject's heading (side by side): the length the two footprints' projections on that axis share, negative for the gap between the projections; a projection, so neither a contact nor a distance between the bodies |
| `rel.occupies` | a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure) |
| `rel.same_direction` | headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1 |
| `rel.surface_gap` | distance between the nearest points of two bodies, each body's footprint read with its own heading and extent: zero when they touch or overlap, never negative; its longitudinal and lateral components are the lengths of the vector between those nearest points along and across the subject's heading, and a read without a component is the distance; a supplied gap with a negative component reads unknown, never as its magnitude, as zero or as contact |
| `ru.aggregate` | membership of a legal aggregate: the atom's literal argument is an aggregate id, `<definition id>::<term>` for the posted definition that applies, or `<law id>:<span>::<term>` for a definition the law itself makes, and the run's reading classifies every road-user class under that id by the definition's words as included, excluded (the definition leaves it out), covered (the definition admits its members only as members of named included classes, which a road user carries beside it, so its own label adds no membership evidence) or unresolved; true when the user carries an included class, unknown when no included class holds and the user carries an unresolved class or an included or unresolved class it might carry is unobserved, false otherwise: a covered or excluded class decides nothing **Not a stand-in for:** a named road-user class for which the applicable definitions and the run's representation decisions permit its own class atom — that class's own atom; an admitted aggregate stays an aggregate even when it contains only one class; a relational role such as who drives or controls a vehicle — never membership; nor a role the text describes by conduct (responding, overtaking) — a role is a derived concept |
| `st.lane` | a longitudinal strip of roadway for one line of vehicles **Not a stand-in for:** a half of the roadway or a lateral position within a lane — lane membership is not an offset from the edge, and lane ordinal equals roadway half only on a two-lane road **Refines:** `st.travel_region` |
| `st.lane_adjacency` | left / right neighbouring lane of the same direction; lane ordinal within the carriageway and the count of lanes in that direction; ordinal 1 is the leftmost lane, looking along the lane's direction **Not a stand-in for:** the marking between two lanes |
| `st.lane_direction` | direction of travel designated for a structure a vehicle travels in — a lane, reserved lane, turn lane, bicycle lane or path, or a roadway, one-way roadway or shoulder; a centre turn lane carries none. The direction is local to its carrier (a bend or a loop is written as segments), carriers that overlap or cross may carry different directions, and a place no carrier covers has none (unknown). It is written at any length; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown |

| parameter | value | unit | convention |
|---|---|---|---|
| `p.course_departure_sin_tol` | 0.035 | ratio | sine of the largest angle (about two degrees) between a moving vehicle's heading and its lane's designated direction at which it counts as keeping its course: lane-keeping heading wander plus the source's heading noise, below the few degrees of heading a lane change takes |
| `p.following_headway_dry` | 2.0 | s | time headway a following driver keeps on a dry surface: the two-second rule of driver manuals |
| `p.following_headway_ice` | 6.0 | s | time headway a following driver keeps on an icy or snow-covered surface: the tripled following time driver manuals advise |
| `p.following_headway_wet` | 3.0 | s | time headway a following driver keeps on a wet surface or in rain: the two-second rule lengthened by a second |
| `p.halt_speed_tolerance` | 0.1 | m/s | the speed at or below which a sampled speed counts as no movement: the source's speed resolution |
| `p.overtake_same_direction_cos` | 0.9 | ratio | cosine of the largest heading difference (about 25 degrees) at which two vehicles count as travelling in the same direction while one moves out to pass the other |
| `p.overtake_window` | 10.0 | s | the longest duration of an overtaking manoeuvre on an urban street, from having the overtaken vehicle ahead to having it behind |

Admitted aggregates the node claims (a witness's road user is a member when it carries an included class; one carrying only an unresolved class makes the atom unknown):

- `DEF-NRS-484A-025::bicycle`: included ru.bicycle; unresolved (none)
- `DEF-NRS-484A-130::motor_vehicle`: included ru.bus, ru.moped, ru.motor_vehicle, ru.motorcycle, ru.school_bus, ru.transit_bus, ru.truck; unresolved ru.tour_bus_or_limousine, ru.trailer_or_combination
- `DEF-NRS-484B-017::electric_bicycle`: included ru.electric_bicycle; unresolved ru.bicycle, ru.bus, ru.commercial_motor_vehicle, ru.emergency_vehicle, ru.fire_apparatus, ru.motor_vehicle, ru.motorcycle, ru.official_vehicle, ru.rail_vehicle, ru.school_bus, ru.taxicab, ru.tour_bus_or_limousine, ru.trailer_or_combination, ru.transit_bus, ru.truck
- `DEF-NRS-484B-018::electric_scooter`: included (none); unresolved ru.bus, ru.child, ru.commercial_motor_vehicle, ru.electric_scooter, ru.emergency_vehicle, ru.fire_apparatus, ru.motor_vehicle, ru.motorcycle, ru.official_vehicle, ru.pedestrian, ru.pedestrian_with_white_cane_or_guide_animal, ru.rail_vehicle, ru.school_bus, ru.taxicab, ru.tour_bus_or_limousine, ru.trailer_or_combination, ru.transit_bus, ru.truck

The catalogue is `results/full221-1116-1018/reading.json` (read-only). Values enter a witness's geometry only: a `forbid` scene breaks the bound by a clear margin, a `permit` scene keeps it by one.

Acquisition standard: profile `carla_scene_graph`. Every `headingSince` step bound in a rule is exactly `.param "p.heading_since_step_carla_scene_graph"`, the operator's reviewed parameter: name it as it is, never propose it or a value for it.

(no node accepted yet in this library; the skeletons below are the pattern, the Core surface the vocabulary)

```lean
-- library/TrafficSpec/Rules/NRS_484B/NRS_484B_270_2b_o3.lean (as written by the harness)
/-
  NRS_484B_270_2b_o3 — NRS-484B-270-2b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (trigger): When overtaking or passing
    b2 (trigger): a bicycle, an electric bicycle or an electric scooter
    b3 (trigger): proceeding in the same direction,
    b4 (subject): the driver of a motor vehicle
    b5 (sibling): shall exercise due care and:
    b6 (condition): If there is only one lane for traffic proceeding in the same direction,
    b7 (sibling): pass to the left of the bicycle, electric bicycle or electric scooter
    b8 (sibling): at a safe distance, which must be not less than 3 feet between any portion of the vehicle and the bicycle, electric bicycle or electric scooter,
    b9 (obligation): and shall not move again to the right side of the highway
    b10 (standard): until the vehicle is safely clear of the overtaken bicycle, electric bicycle or electric scooter.
    b11 (reference): Except as otherwise provided in NRS 484B.213 and 484B.217 [NRS-484B-213-1, NRS-484B-213-2a, NRS-484B-213-2b, NRS-484B-213-2c, NRS-484B-217-2],
    b12 (exception): when passing to the left of a bicycle, electric bicycle or electric scooter at a safe distance of not less than 3 feet between any portion of the vehicle and the bicycle, electric bicycle or electric scooter, this paragraph authorizes the driver, if it is safe, to pass: (1) To the left of the center of the highway. (2) In a no-passing zone.

  Elements (span → atoms, derived):
    b1: atoms ['rel.longitudinal_overlap'], derived ['drv.interaction.overtake_pass']
    b2: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    b3: atoms ['rel.same_direction', 'kin.speed'], derived []
    b4: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    b6: atoms ['rel.occupies', 'st.lane', 'st.lane_adjacency'], derived []
    b9: atoms ['rel.occupies', 'st.lane', 'rel.bearing'], derived ['drv.lane.heading_right_of_carrier']

  Compositions (span → node, as, map):
    b11: NRS_484B_213_1 as unless map {'subject': 'subject'} scopes b12
    b11: NRS_484B_213_2a as unless map {'subject': 'subject'} scopes b12
    b11: NRS_484B_213_2b as unless map {'subject': 'subject'} scopes b12
    b11: NRS_484B_213_2c as unless map {'subject': 'subject'} scopes b12
    b11: NRS_484B_217_2 as unless map {'subject': 'subject'} scopes b12

  Literals the text states (each written through its Units constructor):
    b6: 1 count — one

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_2b_o3

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCourseDepartureSinTol : Term := .param "p.course_departure_sin_tol"
def pFollowingHeadwayDry : Term := .param "p.following_headway_dry"
def pFollowingHeadwayIce : Term := .param "p.following_headway_ice"
def pFollowingHeadwayWet : Term := .param "p.following_headway_wet"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"

def zeroMetres : Term := .lit Q.zero .metre

-- TODO(code): class formulas, applicability and obligation — from the node's elements,
-- operationalizations and compositions, using only the claimed names. `.tt` is the placeholder.

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula := .tt  -- TODO

/-- Applicability: b1 (trigger): When overtaking or passing; b2 (trigger): a bicycle, an electric bicycle or an electric scooter; b3 (trigger): proceeding in the same direction,; b6 (condition): If there is only one lane for traffic proceeding in the same direction,; b12 (exception): when passing to the left of a bicycle, electric bicycle or electric scooter at a safe distance of not less than 3 feet between any portion of the vehicle and the bicycle, electric bicycle or electric scooter, this paragraph authorizes the driver, if it is safe, to pass: (1) To the left of the center of the highway. (2) In a no-passing zone. -/
def applicability : Formula := .tt  -- TODO

/-- Obligation: b9 (obligation): and shall not move again to the right side of the highway; b10 (standard): until the vehicle is safely clear of the overtaken bicycle, electric bicycle or electric scooter. -/
def obligation : Formula := .tt  -- TODO

def rule : Rule :=
  { id := "NRS_484B_270_2b_o3"
    laws := ["NRS-484B-270-2b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "until the vehicle is safely clear of the overtaken bicycle"
          concepts := ["env.ice_or_snow", "env.precipitation", "env.wet_road", "kin.speed", "rel.bearing", "rel.longitudinal_overlap", "rel.surface_gap"]
          params := ["p.following_headway_dry", "p.following_headway_wet", "p.following_headway_ice"]
          convention := "time headway: the subject (the vehicle) is safely clear of the overtaken rider where the rider is behind it (rel.bearing longitudinal component negative, rel.longitudinal_overlap negative) with a gap between the bodies (rel.surface_gap) of at least the rider's speed times the following headway for the surface - ice or snow, else wet road or precipitation, else dry - so that the rider, following, keeps the headway a following road user keeps"
          surrogate := false } ]
    residues := ["the authorization lets a driver passing a rider at the stated clearance pass left of the center or in a no-passing zone, conduct other rules (NRS 484B.213, 484B.217) forbid; it relaxes those rules and leaves the duty not to move back right before being clear unchanged"]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_270_2b_o3

```

```lean
-- library/TrafficSpecWitness/NRS_484B/NRS_484B_270_2b_o3.lean (as written by the harness)
/-
  Witnesses for NRS_484B_270_2b_o3.

  TODO(code): describe the geometry once built — the carriageway, the bodies, the instants; every
  figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_2b_o3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_2b_o3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): Road with one lane in the subject's direction; the subject car moves out left and overtakes a bicycle; while the bicycle is still beside it, the subject car steers back to the right, its heading turning right of the lane's direction beyond the course tolerance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `permit` (compliant): Same pass; the subject car keeps its course until the bicycle is behind it at a gap above the bicycle's speed times the dry headway, then steers back right. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `idle` (not_applicable): The subject car drives alone on a road with one lane in its direction and steers to the right; no other road user is in the scene, so no bicycle, electric bicycle or electric scooter is being overtaken. The duty binds the subject alone. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `blind` (unknown): As in forbid, but the source does not observe the lanes' designated direction of travel, so whether the subject's heading turned right of the rider's lane is unknown while the rider, still beside it, is decided not clear. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `branch_1` (violated): The subject car completes the pass of a bicycle on a road with one lane in its direction and steers back right at once, as the pass is recognized, the bicycle behind it at a gap below its speed times the dry headway. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `branch_2` (not_applicable): The road has two lanes in the subject's direction; the subject passes a bicycle and steers back right while beside it. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_270_2b_o3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_270_2b_o3

```

Run exactly this command, nothing more and nothing else:

```
python -m harness gate --run_id full221-1116-1018 --node_id NRS_484B_270_2b_o3
```

It prints the verdict and its details. The verdicts on your files: SCOPE_VIOLATION, BUILD_FAIL, UNSOUND, CHECK_FAIL, UNANCHORED_VARIABLE, DECLARATION_MISMATCH, SCOPE_NARROWED, UNEXPRESSED, UNCLAIMED_ATOM, UNUSED_CLAIM, BARE_LITERAL, WITNESS_FAIL, VACUOUS, PARAM_MISMATCH, GATE_TIMEOUT, OK. `INFRA` is not one: the toolchain or the run did not let the gate judge your files. Budget: 6 runs; the harness re-runs the gate itself after you stop, on the files as they are then.


## Access

- You **edit** `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpec/Rules/NRS_484B/NRS_484B_270_2b_o3.lean` and `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpecWitness/NRS_484B/NRS_484B_270_2b_o3.lean` with the Edit and Write tools, and write
  `task_result.md` (and, when you report a concept, `dependency_defect.json`) in your working
  directory. Nothing else is writable.
- You **may read**, with the Read tool and by absolute path, the Core files under `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpec/Core`
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

1. **Two files.** Edit `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpec/Rules/NRS_484B/NRS_484B_270_2b_o3.lean` and `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpecWitness/NRS_484B/NRS_484B_270_2b_o3.lean` only; their paths and the namespace
   `TrafficSpec.Rules.NRS_484B_270_2b_o3` are derived from the node id and are not yours to choose. Declare
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

Working directory: `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/results/full221-1116-1018/iter-007/code/NRS_484B_270_2b_o3`. Write `task_result.md` there.
