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
 "node_id": "NRS_484B_307_9b",
 "law_refs": [
  "NRS-484B-307-9b"
 ],
 "subject": {
  "binder": "subject",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-135::motorcycle",
   "ru.aggregate=DEF-NRS-484A-125::moped",
   "ru.motorcycle",
   "ru.aggregate=DEF-NRS-484A-025::bicycle",
   "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
   "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
  ]
 },
 "segmentation": [
  {
   "id": "s1",
   "text": "Where the signal is a steady red with a green turn arrow:",
   "role": "trigger"
  },
  {
   "id": "s2",
   "text": "A person driving a motorcycle, moped or trimobile or riding a bicycle, an electric bicycle or an electric scooter",
   "role": "subject"
  },
  {
   "id": "s3",
   "text": "facing the signal",
   "role": "trigger"
  },
  {
   "id": "s4",
   "text": "may proceed straight through or turn in the direction opposite that indicated by the green turn arrow",
   "role": "trigger"
  },
  {
   "id": "s5",
   "text": "if:",
   "role": "boilerplate"
  },
  {
   "id": "s6",
   "text": "(1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection; (2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter; (3) No other device at the place prohibits the turn, if applicable; and (4) The person yields",
   "role": "obligation"
  },
  {
   "id": "s7",
   "text": "the right-of-way",
   "role": "standard"
  },
  {
   "id": "s8",
   "text": "to pedestrians lawfully within an adjacent crosswalk",
   "role": "condition"
  },
  {
   "id": "s9",
   "text": "and to other traffic lawfully using the intersection.",
   "role": "condition"
  }
 ],
 "elements": [
  {
   "span": "s1",
   "atoms": [
    "dev.traffic_signal"
   ],
   "derived": [],
   "justification": "dev.traffic_signal: 'a signal head; state in {... circular_red, green_arrow(dir) ...}; several states may be displayed at once'. A steady red with a green turn arrow is the head displaying circular_red together with green_arrow(dir), dir left or right (a turn arrow with an opposite turn), and no circular_green, read at the observation of the subject's entry into the intersection, which 'may proceed' fixes."
  },
  {
   "span": "s2",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-135::motorcycle",
    "ru.aggregate=DEF-NRS-484A-125::moped",
    "ru.motorcycle",
    "ru.aggregate=DEF-NRS-484A-025::bicycle",
    "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
    "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
   ],
   "derived": [],
   "justification": "Reuses the index mapping of the same words (NRS_484B_307_8d). Motorcycle, moped, bicycle, electric bicycle and electric scooter are admitted aggregates for this law and are claimed by id. 'Trimobile' has no applicable definition; ru.motorcycle, 'motor vehicle on two or three wheels ridden astride, including three-wheeled variants', denotes it, used for the undefined word only."
  },
  {
   "span": "s3",
   "atoms": [
    "dev.governs",
    "rel.occupies",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [],
   "justification": "Facing the signal: the subject occupies (rel.occupies) a carrier c of kind st.travel_region that runs into intersection i at its entrance end (st.lane_enters), and the head governs c or i (dev.governs, 'the travel regions whose traffic the device controls'). Governance is control, not a position, as its exclusion requires."
  },
  {
   "span": "s4",
   "atoms": [
    "dev.traffic_signal",
    "rel.occupies",
    "st.intersection"
   ],
   "derived": [
    "drv.motion.left_turn_through_region",
    "drv.motion.right_turn_through_region",
    "drv.motion.u_turn_through_region"
   ],
   "justification": "The passage through i (rel.occupies of st.intersection, from entry to exit) is straight through or a turn opposite the arrow exactly when it is neither a turn in the arrow's direction nor a reversal: for green_arrow(left), drv.motion.left_turn_through_region (a heading change 'in the band from turn_min inclusive to u_turn_min exclusive') does not hold at the exit and drv.motion.u_turn_through_region ('so as to proceed in the opposite direction') does not; for green_arrow(right), the same with drv.motion.right_turn_through_region. The arrow's direction is read from dev.traffic_signal's green_arrow(dir)."
  },
  {
   "span": "s6",
   "atoms": [
    "drv.motion.complete_halt",
    "prim.region_offset_along",
    "rel.occupies",
    "st.crosswalk",
    "st.entrance_of",
    "st.intersection",
    "st.lane_direction",
    "st.lane_enters",
    "st.region_geometry",
    "st.stop_line",
    "dev.governs",
    "dev.traffic_signal",
    "st.travel_region",
    "dev.regulatory_sign",
    "kin.speed",
    "rel.contact",
    "ru.aggregate=DEF-NRS-484A-135::motorcycle",
    "ru.aggregate=DEF-NRS-484A-125::moped",
    "ru.motorcycle",
    "ru.aggregate=DEF-NRS-484A-025::bicycle",
    "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
    "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
   ],
   "derived": [
    "drv.motion.complete_halt",
    "drv.motion.left_turn_through_region",
    "drv.motion.right_turn_through_region"
   ],
   "justification": "(1) Reuses the index mapping of the stop-before words (NRS_484B_307_8a_o1): a stop is drv.motion.complete_halt ('complete cessation from movement', DEF-NRS-484A-255); the marking that indicates where the stop must be made is a st.stop_line ('the transverse line marking where vehicles halt'), the crosswalk a st.crosswalk, each the one recorded as marking the approach carrier's entrance (st.entrance_of, 'exactly that carrier's entrance'), the carrier entering i (st.lane_enters); the side of the mark is read along the carrier's direction (st.lane_direction, prim.region_offset_along), the distance through st.region_geometry, and a halt overlapping the mark or i (rel.occupies) is not before entering it. (2) Reuses the index mapping of the parallel words (NRS_484B_307_8d): the applicable device is the head governing c (dev.governs, st.travel_region); a complete cycle is counted by the display steady red with the green turn arrow coming on again (a rising edge of that dev.traffic_signal state combination) while the subject waits at rest at the place (drv.motion.complete_halt); the signal not changing is the head displaying no circular_green through the wait; the cause (malfunction, non-detection of the subject of its class) is the device's status, read through those displays; the classes named are the subject's own. (3) Reuses the index mapping (NRS_484B_307_8d): another device prohibiting the turn is a dev.regulatory_sign, 'a point regulation by catalogue code', with code no_left_turn or no_right_turn matching the turn, governing c or i; 'if applicable' is where the passage is a turn, drv.motion.left_turn_through_region or drv.motion.right_turn_through_region at the exit; the sign is the condition and the turn is read by the concepts, as the sign's 'not a stand-in for a manoeuvre' clause requires. (4) Reuses the index mapping of '(3) The person yields' (NRS_484B_307_8d): yielding is read in the subject's motion (kin.speed) and in the absence of contact (rel.contact, 'the bodies ... touch or overlap (a collision)')."
  },
  {
   "span": "s8",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian",
    "rel.occupies",
    "st.crosswalk",
    "st.entrance_of",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [],
   "justification": "Reuses the index mappings of 'to pedestrians' and 'lawfully within an adjacent crosswalk' (NRS_484B_307_3a). Pedestrians are the admitted aggregate DEF-NRS-484A-165::pedestrian. An adjacent crosswalk is a st.crosswalk recorded as marking the entrance (st.entrance_of) of a carrier (st.travel_region) entering i (st.lane_enters): a crosswalk of this intersection, tied to it by relations, not distance; within it is rel.occupies."
  },
  {
   "span": "s9",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "rel.occupies",
    "st.intersection"
   ],
   "derived": [],
   "justification": "Reuses the index mappings of 'and to other traffic' and 'lawfully using the intersection' (NRS_484B_307_3a): other road users of the admitted aggregate DEF-NRS-484A-285::traffic whose footprint overlaps i (rel.occupies, st.intersection)."
  }
 ],
 "operationalizations": [
  {
   "span": "s7",
   "standard": "the right-of-way",
   "concepts": [
    "prim.closest_approach_within",
    "prim.closest_approach_distance",
    "rel.contact",
    "kin.speed"
   ],
   "params": [
    "p.conflict_horizon",
    "p.conflict_centre_clearance",
    "p.halt_speed_tolerance"
   ],
   "convention": "Traffic-conflict technique: the right-of-way (DEF-NRS-484A-210: precedence where 'direction, speed and proximity' give 'danger of a crash') is not yielded where the subject, moving (kin.speed above p.halt_speed_tolerance) within the intersection, is on a closest approach to a road user it must yield to within the horizon p.conflict_horizon at a centre distance below p.conflict_centre_clearance, or touches it (rel.contact).",
   "surrogate": false
  }
 ],
 "assumptions": [],
 "intentions": [],
 "compositions": [],
 "residues": [],
 "binders": [
  {
   "name": "subject",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-135::motorcycle",
    "ru.aggregate=DEF-NRS-484A-125::moped",
    "ru.motorcycle",
    "ru.aggregate=DEF-NRS-484A-025::bicycle",
    "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
    "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
   ]
  }
 ],
 "applicability": "The subject is of one of the named classes (motorcycle, moped, bicycle, electric bicycle or electric scooter aggregates, or ru.motorcycle for a trimobile). Judged at the observation at which the subject exits an intersection i (its footprint ceases to overlap i, having overlapped it at the previous observation). At the observation of its latest entry into i (footprint came to overlap i, not having overlapped it at the observation before), read by a past operator, it occupied a carrier c entering i (st.lane_enters) governed, as c or as i, by a traffic signal head displaying circular_red together with green_arrow(dir), dir left or right, and no circular_green. The passage is not a turn in the arrow's direction (for dir left, drv.motion.left_turn_through_region(subject, i) does not hold at the exit; for dir right, drv.motion.right_turn_through_region does not) and not a reversal (drv.motion.u_turn_through_region does not hold): it went straight through or turned opposite the arrow. Turn concepts take step p.heading_since_step_carla_scene_graph, turn_min p.turn_heading_min, u_turn_min p.u_turn_heading_min.",
 "obligation": "Re-binding i, c and the head by the same selection (the entry observation's carrier c entering i and its governing head displaying the red with the green arrow), all of: (1) Halt before the entry. Event: the subject's entry into i through c. Place: where a stop line or a crosswalk is recorded as marking c's entrance (st.entrance_of), a halt (drv.motion.complete_halt with speed_tol p.halt_speed_tolerance) with the subject's body within p.stop_point_tolerance of that mark (st.region_geometry), short of it along c's designated direction (sign of prim.region_offset_along along st.lane_direction) and not overlapping it nor i (rel.occupies); where several such marks mark c, a halt at any of them; where the marks' entrance lists are observed and none marks c, a halt within p.stop_point_tolerance of i's edge at c's entrance end, not overlapping i. History bound: the search runs back from the entry and ends only at the approach start (the last observation at which the subject, on a carrier the mark marks, is outside the mark's stopping zone upstream: off it, short of it and farther than p.stop_point_tolerance) or at the subject's previous entry into i; a halt found discharges, either end reached without one violates, reaching neither is unknown; an unobserved association of a mark with c makes the governing mark unknown only where the verdict depends on it. (2) Two cycles: at some observation before the entry since which the subject has not occupied i, the subject was at rest at that place, and since the start of its latest run at rest there the governing head's display circular_red with green_arrow(dir) had risen at least the literal two times (count of rising edges, op ge); unknown where that run's start lies before the recording. (3) At no observation of that run at rest did the head display circular_green (the signal does not change for the subject). (4) Where the passage is a turn (drv.motion.left_turn_through_region or drv.motion.right_turn_through_region at the exit), no dev.regulatory_sign with the code prohibiting that turn (no_left_turn, no_right_turn) governs c or i at the entry. (5) Yield: at every observation from the entry to the exit at which the subject's speed exceeds p.halt_speed_tolerance, for every pedestrian (ru.aggregate pedestrian) occupying a crosswalk recorded as marking the entrance of a carrier entering i, and for every other road user of the traffic aggregate occupying i, the subject is not on a closest approach to it within p.conflict_horizon (prim.closest_approach_within) at a centre distance below p.conflict_centre_clearance (prim.closest_approach_distance), and is not in contact with it (rel.contact).",
 "params": [
  "p.halt_speed_tolerance",
  "p.stop_point_tolerance",
  "p.conflict_horizon",
  "p.conflict_centre_clearance",
  "p.heading_since_step_carla_scene_graph",
  "p.turn_heading_min",
  "p.u_turn_heading_min"
 ],
 "narrowings": [
  {
   "span": "s6",
   "why": "The cause of the non-change (malfunction, failure to detect the subject) is the device's operational status, read through its displayed states: two completed cycles at rest at the place with no circular green for the waiting subject.",
   "kind": "observable_reading",
   "category": "status"
  },
  {
   "span": "s6",
   "why": "A complete cycle of the device's lights is counted as the steady red with the green turn arrow coming on again on the governing head while the subject waits at rest at the place.",
   "kind": "reading"
  },
  {
   "span": "s6",
   "why": "'lawfully' is not judged by composing the other road users' own rules: the yield is owed to every pedestrian within a crosswalk of the intersection and to every other road user of the traffic aggregate within it.",
   "kind": "reading"
  },
  {
   "span": "s2",
   "why": "'driving' and 'riding' are read through the road user's controlled motion, whoever is at the controls.",
   "kind": "observable_reading",
   "category": "agency"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "A motorcycle (ru.aggregate motorcycle) occupies approach lane c entering i, with a stop line recorded as marking c; the head governing c displays circular_red with green_arrow(left). The motorcycle halts at the stop line, waits while the red-with-arrow display comes on again once only, then enters i and exits straight ahead (no turn concept holds). No pedestrian or other road user is present."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "As in forbid, but the motorcycle remains at rest at the stop line while the red-with-arrow display rises twice, the head never displays circular_green, and it then proceeds straight through i. No other road user is in the scene, so the yield is decided on the subject alone."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "The head governing c displays circular_green at the motorcycle's entry; it proceeds straight through."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "As in forbid, but the state of the head governing c is never observed (dev.traffic_signal absent).",
   "masked": [
    "dev.traffic_signal"
   ]
  },
  {
   "name": "history_boundary",
   "expected": "unknown",
   "narrative": "The recording begins with the motorcycle already within the stop line's stopping zone on c, moving slowly, under red with green_arrow(left); it enters i and exits straight. No halt is recorded, the approach start and any earlier wait lie before the recording, and no earlier entry into i is recorded.",
   "boundary": "the motorcycle's approach to the stop line on c and any run at rest there before the recording began"
  },
  {
   "name": "branch_1",
   "expected": "violated",
   "narrative": "As in permit, but the motorcycle turns right (opposite the left arrow; drv.motion.right_turn_through_region at the exit) while a dev.regulatory_sign with code no_right_turn governs c."
  },
  {
   "name": "branch_2",
   "expected": "violated",
   "narrative": "As in permit, but a pedestrian occupies the crosswalk recorded as marking the entrance of the opposite carrier; the moving motorcycle's closest approach to it lies within the horizon at a centre distance below the clearance."
  },
  {
   "name": "occasion_s1",
   "expected": "violated",
   "narrative": "The head displays circular_red with green_arrow(left) at the motorcycle's entry into i, made without any halt; it changes to circular_green while the motorcycle is in i; it exits straight ahead."
  },
  {
   "name": "occasion_s1_outside",
   "expected": "not_applicable",
   "narrative": "The head displays red with the green arrow while the motorcycle approaches, and circular_green from before its entry into i; it proceeds straight without halting."
  },
  {
   "name": "occasion_s3",
   "expected": "violated",
   "narrative": "At its entry the motorcycle's footprint overlaps c (governed by the red-with-arrow head) and i; afterwards only i; it did not halt and exits straight."
  },
  {
   "name": "occasion_s3_outside",
   "expected": "not_applicable",
   "narrative": "The motorcycle occupied c while c's head showed red with the green arrow, then moved into an adjacent approach lane c2 whose governing head displays circular_green, and entered i from c2 only, exiting straight."
  },
  {
   "name": "occasion_s8",
   "expected": "violated",
   "narrative": "As in permit, but for part of the passage a pedestrian occupies a crosswalk of i on a converging course; the moving motorcycle's closest approach to it lies within the horizon below the clearance while the pedestrian is in the crosswalk."
  },
  {
   "name": "occasion_s8_outside",
   "expected": "compliant",
   "narrative": "As in permit, but a pedestrian occupied a crosswalk of i only before the motorcycle's entry and has left it before the entry; no other road user is present during the passage."
  },
  {
   "name": "occasion_s9",
   "expected": "violated",
   "narrative": "As in permit, but for part of the passage another car occupies i on a converging course; the moving motorcycle's closest approach to it lies within the horizon below the clearance."
  },
  {
   "name": "occasion_s9_outside",
   "expected": "compliant",
   "narrative": "As in permit, but another car occupied i only before the motorcycle's entry and left it before the entry."
  }
 ],
 "occasion": {
  "act": [
   "drv.motion.left_turn_through_region",
   "drv.motion.right_turn_through_region"
  ],
  "boundary": "event",
  "onset": {
   "words": "may proceed straight through",
   "atoms": [
    "rel.occupies",
    "st.intersection"
   ],
   "derived": [],
   "justification": "The passage begins at the observation at which the subject's footprint comes to overlap i (rel.occupies), not having overlapped it at the previous observation: its entry, the onset each through-region concept states."
  },
  "recognition": "the observation at which the subject's footprint ceases to overlap the intersection, having overlapped it at the previous observation: its exit, where the through-region concepts are recognized",
  "under_way": {
   "words": "proceed straight through or turn",
   "atoms": [
    "rel.occupies",
    "kin.yaw_rate"
   ],
   "derived": [],
   "justification": "An observation inside the passage is one since the subject's entry into i over which its heading change is being integrated from kin.yaw_rate; before the entry it did not overlap i and no integration has begun."
  },
  "spans": {
   "s1": "some_moment",
   "s3": "some_moment",
   "s4": "at_recognition",
   "s8": "some_moment",
   "s9": "some_moment"
  }
 },
 "literals": [
  {
   "span": "s6",
   "text": "two",
   "value": 2,
   "unit": "count"
  }
 ],
 "param_proposals": [
  {
   "name": "p.halt_speed_tolerance",
   "unit": "m/s",
   "value": 0.1,
   "convention": "the speed at or below which a sampled speed counts as no movement: the source's speed resolution",
   "source": "speed resolution of automotive perception and simulator scene-graph sources"
  },
  {
   "name": "p.stop_point_tolerance",
   "unit": "m",
   "value": 2.0,
   "convention": "the body-to-mark gap within which a halt counts as at the mark: a stop line's set-back before a crossing plus a placement margin",
   "source": "MUTCD stop line placement (4 ft before the crosswalk) plus a placement margin"
  },
  {
   "name": "p.conflict_horizon",
   "unit": "s",
   "value": 3.0,
   "convention": "time-to-collision threshold of the traffic-conflict technique: a closest approach later than this is not a present danger of a crash",
   "source": "traffic-conflict technique literature (time-to-collision thresholds)"
  },
  {
   "name": "p.conflict_centre_clearance",
   "unit": "m",
   "value": 3.0,
   "convention": "centre-to-centre distance at the closest approach below which the bodies of a passenger car and another road user are taken to collide or nearly collide: about a car's half-length plus half a body width",
   "source": "passenger-car design dimensions (AASHTO design vehicle P)"
  },
  {
   "name": "p.turn_heading_min",
   "unit": "deg",
   "value": 45.0,
   "convention": "the smallest heading change over the turn window at which a change of course counts as a turn rather than a lane change or a drift",
   "source": "intersection turning geometry; lane-change heading changes stay well below it"
  },
  {
   "name": "p.u_turn_heading_min",
   "unit": "deg",
   "value": 135.0,
   "convention": "the smallest heading change magnitude over the turn window at which a turn counts as a reversal of direction",
   "source": "intersection turning geometry"
  }
 ],
 "gaps": [],
 "gap_resolutions": [],
 "planned_on": {}
}


- rule: `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpec/Rules/NRS_484B/NRS_484B_307_9b.lean` — `namespace TrafficSpec.Rules.NRS_484B_307_9b`, `def rule : Rule`
- witness: `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpecWitness/NRS_484B/NRS_484B_307_9b.lean` — `namespace TrafficSpecWitness.NRS_484B_307_9b`, `def scenarios : List Scenario`
- imports: the rule file imports `TrafficSpec.Core.Language.Rule` only; the witness file imports `TrafficSpec.Rules.NRS_484B.NRS_484B_307_9b` and `TrafficSpec.Core.Evidence.Builders`
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
| `drv.motion.complete_halt` | formula | The road user is at rest at the observation — "complete cessation from movement" — observed as its speed (kin.speed) at or below a tolerance the caller sets for the source's speed resolution. It denotes a state at one observation: it says nothing of how long the road user stays at rest, where it is, or why. Not denoted: a slowing whose sampled speed stays above the tolerance. | DEF-NRS-484A-255 | a:track | speed_tol (m/s) | kin.speed | no concept |
| `drv.motion.left_turn_through_region` | formula | Road user a has made a turn to the left through region r, recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from turn_min inclusive to u_turn_min exclusive, so that a passage whose heading changes too little to be a turn and a reversal of direction both lie outside it. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change is below turn_min, such as one straight through or a turn to the right; a heading change of u_turn_min or more, which is a reversal of direction; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown. **Review notes (not confirmed differences):** The body agreed with the contract on both tested passages: a fully observed 90-degree left turn and the same entry-to-exit change preceded by a right turn before entry. Neither test established a defect. |  | a:track, r:region | step (s), turn_min (deg), u_turn_min (deg) | kin.time, kin.yaw_rate, rel.occupies | no concept |
| `drv.motion.right_turn_through_region` | formula | Road user a has made a turn to the right through region r, recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from minus u_turn_min exclusive to minus turn_min inclusive: a turn to the right by at least turn_min and by less than u_turn_min, so that a passage whose heading changes too little to be a turn and a reversal of direction both lie outside it. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change is above minus turn_min, such as one straight through or a turn to the left; a heading change of minus u_turn_min or less, which is a reversal of direction; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown. |  | a:track, r:region | step (s), turn_min (deg), u_turn_min (deg) | kin.time, kin.yaw_rate, rel.occupies | no concept |
| `drv.motion.u_turn_through_region` | formula | Road user a has turned "so as to proceed in the opposite direction" through region r, "whether accomplished by one continuous movement or not", recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the magnitude of the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from u_turn_min to a full turn minus u_turn_min, both inclusive, so that a turn short of a reversal and a full loop both lie outside it; a reversal to either hand is denoted, and one made in several movements, with halts or backing between them inside r, is denoted where its integrated heading change lies in the band. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change magnitude is below u_turn_min, such as a turn to the left or the right or a passage straight through; a heading change magnitude above a full turn minus u_turn_min, which is a loop; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown. **Review notes (not confirmed differences):** A tested 180-degree passage lasting longer than step, with every sampling interval equal to step, holds in both the contract and the body; step does not limit the total passage duration.; A tested 180-degree turn completed at entry, followed by zero heading change through exit, fails in both the contract and the body; the pre-entry turn is not counted. | DEF-NRS-484B-077 | a:track, r:region | step (s), u_turn_min (deg) | kin.time, kin.yaw_rate, rel.occupies | no concept |

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
def ru_motorcycle (s : Scene) (x : TrackId) : Option Bool := hasClass s x .motorcycle
def ru_aggregate (s : Scene) (x : TrackId) (members : List RoadUserClass) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def kin_time (s : Scene) : Timestamp := s.t
def kin_position (s : Scene) (x : TrackId) : Option Vec := (s.user x).bind (·.kin.position)
def kin_velocity (s : Scene) (x : TrackId) : Option Vec := (s.user x).bind (·.kin.velocity)
def kin_speed (s : Scene) (x : TrackId) : Option Q := (s.user x).bind (·.kin.speed)
def kin_yaw_rate (s : Scene) (x : TrackId) : Option Q := (s.user x).bind (·.kin.yawRate)
def isKind (s : Scene) (r : RegionId) (k : StructureKind) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def st_travel_region (s : Scene) (r : RegionId) : Option Bool := isKind s r .travelRegion
def st_lane_direction (s : Scene) (r : RegionId) : Option Vec := (s.structure? r).bind (·.lane) |>.bind (·.direction)
def st_lane_enters (s : Scene) (r : RegionId) : Option RegionId := (st_lane_adjacency s r).bind (·.entersIntersection)
def st_entrance_of (s : Scene) (l a : RegionId) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def st_intersection (s : Scene) (r : RegionId) : Option Bool := isKind s r .intersection
def st_crosswalk (s : Scene) (r : RegionId) : Option Bool := isKind s r .crosswalk
def st_crosswalk_marked (s : Scene) (r : RegionId) : Option Bool := (s.structure? r).bind (·.marked)
def st_stop_line (s : Scene) (r : RegionId) : Option Bool := isKind s r .stopLine
def st_region_geometry (s : Scene) (r : RegionId) : Option (Option Vec × Option (List Vec)) :=  -- (body continues in Vocab/Atoms.lean)
def st_region_geometry_position (s : Scene) (r : RegionId) : Option Vec := (s.structure? r).bind (·.position)
def st_region_geometry_boundary (s : Scene) (r : RegionId) : Option (List Vec) := (s.structure? r).bind (·.boundary)
def footprint (s : Scene) (x : TrackId) : Option (List Vec) := do
def st_region_geometry_distance (s : Scene) (x : TrackId) (r : RegionId) : Option Q := do
def regionsOfKind (s : Scene) (k : StructureKind) : List RegionId :=  -- (body continues in Vocab/Atoms.lean)
def regionCandidates (s : Scene) (k : StructureKind) : List RegionId :=  -- (body continues in Vocab/Atoms.lean)
def rel_occupies (s : Scene) (x : TrackId) (r : RegionId) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def rel_occupies_regions (s : Scene) (x : TrackId) : Option (List RegionId) :=  -- (body continues in Vocab/Atoms.lean)
def devKind (s : Scene) (d : DeviceId) (k : DeviceKind) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def dev_traffic_signal (s : Scene) (d : DeviceId) : Option Bool := devKind s d .trafficSignal
def dev_traffic_signal_indications (s : Scene) (d : DeviceId) : Option (List SignalIndication) := (s.device d).bind (·.indications)
def dev_traffic_signal_shows (s : Scene) (d : DeviceId) (i : SignalIndication) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def dev_traffic_signal_uncovered (s : Scene) (d : DeviceId) : Option Bool := (s.device d).bind (·.uncovered)
def dev_regulatory_sign (s : Scene) (d : DeviceId) : Option Bool := devKind s d .regulatorySign
def dev_regulatory_sign_code (s : Scene) (d : DeviceId) : Option SignCode := (s.device d).bind (·.code)
def dev_regulatory_sign_conditions (s : Scene) (d : DeviceId) : Option Conditions := (s.device d).bind (·.conditions)
def dev_governs (s : Scene) (d : DeviceId) (r : RegionId) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def dev_governs_regions (s : Scene) (d : DeviceId) : Option (List RegionId) :=  -- (body continues in Vocab/Atoms.lean)
def devicesOfKind (s : Scene) (k : DeviceKind) : List DeviceId :=  -- (body continues in Vocab/Atoms.lean)
def deviceCandidates (s : Scene) (k : DeviceKind) : List DeviceId :=  -- (body continues in Vocab/Atoms.lean)
def rel_contact (s : Scene) (a b : TrackId) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
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
def prim_region_offset_along (c : Ctx) (x : TrackId) (r l : RegionId) : Array QR
    -- The signed distance (m) from road user x's reference point to region r, along carrier l's designated direction, on the line through the reference point parallel to that direction. r is a closed set: a vertex the line only touches and an edge it runs along are points of r it meets. Zero where the reference point lies in r or on its boundary; where every point of r on the line lies ahead, the distance to the nearest of them; where every one lies behind, minus the distance to the nearest. Where the line does not meet r, the value comes from r's projection on the direction, the interval [lo, hi] of the signed distances of r's points along it: lo where lo > 0, hi where hi < 0. That value is a projection gap, not a distance along the line, so the value may jump where the line starts or stops meeting r; its sign gives the side in both cases. Undefined where the line meets r both ahead and behind, where it misses r and [lo, hi] spans or touches zero, and where r's boundary is not a simple polygon (an empty list, fewer than three vertices, zero area, or a boundary that crosses or touches itself); unknown where the position, the direction (a zero vector included) or the boundary is absent. Independent of the boundary's start vertex and orientation. The direction is normalised as `st_lane_direction` is read (`Geom.unit`, with Core's micrometre-rounded square root), and the distance is counted in lengths of that normalised vector, which lie between 1 and 1 + 2·10⁻⁶ m. The value is geometry only: it does not establish that x is on l, that r marks l's entrance, that x's whole body has crossed r, or that a crossing happened between observations, and a distance to r is read from `st_region_geometry_distance`.
    -- formula form: args [x, r, l] params []
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
| `dev.governs` | relation: the travel regions whose traffic the device controls — a lane, reserved lane, turn lane, centre turn lane, bicycle lane or path, roadway, one-way roadway or shoulder — or an intersection, read as control of the junction itself and of nothing else (no closure to the lanes that enter it); never a highway, a controlled-access region or a region no vehicle travels in. Unknown where the source does not observe what a device governs **Not a stand-in for:** a position — the region a device governs is not where a halt is required |
| `dev.regulatory_sign` | a point regulation by catalogue **code**, with the same structured **conditions** attribute as `dev.zone_sign`, read as that row says (unconditional when empty, unknown when absent), where the sign states hours, days, a duration or a class: no_left_turn, no_right_turn, no_u_turn, no_straight, one_way, keep_right, do_not_enter, wrong_way, no_stopping, no_standing, no_parking, angle_parking, right_turn_only, entrance, exit, closed_to_traffic, exempt_crossing, abandoned_crossing, shoulder_use_permitted, bicycles_prohibited, pedestrians_prohibited, nonmotorized_prohibited, motor_vehicles_prohibited, truck_route, no_trucks **Not a stand-in for:** a manoeuvre or a road feature — a prohibition sign is a condition, a warning sign is not the hazard it warns of, and a sign is not a signal |
| `dev.traffic_signal` | a signal head; **state** ∈ {circular_green, circular_yellow, circular_red, green_arrow(dir), yellow_arrow(dir), red_arrow(dir), flashing_yellow_arrow(dir), flashing_red, flashing_yellow, dark, unknown} with dir ∈ {left, right, straight, u_turn}; several states may be displayed at once; **uncovered** attribute for an installed head whose faces are not covered |
| `drv.motion.complete_halt` | The road user is at rest at the observation — "complete cessation from movement" — observed as its speed (kin.speed) at or below a tolerance the caller sets for the source's speed resolution. It denotes a state at one observation: it says nothing of how long the road user stays at rest, where it is, or why. Not denoted: a slowing whose sampled speed stays above the tolerance. |
| `drv.motion.left_turn_through_region` | Road user a has made a turn to the left through region r, recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from turn_min inclusive to u_turn_min exclusive, so that a passage whose heading changes too little to be a turn and a reversal of direction both lie outside it. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change is below turn_min, such as one straight through or a turn to the right; a heading change of u_turn_min or more, which is a reversal of direction; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown. |
| `drv.motion.right_turn_through_region` | Road user a has made a turn to the right through region r, recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from minus u_turn_min exclusive to minus turn_min inclusive: a turn to the right by at least turn_min and by less than u_turn_min, so that a passage whose heading changes too little to be a turn and a reversal of direction both lie outside it. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change is above minus turn_min, such as one straight through or a turn to the left; a heading change of minus u_turn_min or less, which is a reversal of direction; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown. |
| `drv.motion.u_turn_through_region` | Road user a has turned "so as to proceed in the opposite direction" through region r, "whether accomplished by one continuous movement or not", recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the magnitude of the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from u_turn_min to a full turn minus u_turn_min, both inclusive, so that a turn short of a reversal and a full loop both lie outside it; a reversal to either hand is denoted, and one made in several movements, with halts or backing between them inside r, is denoted where its integrated heading change lies in the band. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change magnitude is below u_turn_min, such as a turn to the left or the right or a passage straight through; a heading change magnitude above a full turn minus u_turn_min, which is a loop; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown. |
| `kin.position` | position of the body's reference point |
| `kin.speed` | magnitude of velocity |
| `kin.time` | instant of observation of a scene |
| `kin.velocity` | velocity vector |
| `kin.yaw_rate` | rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres |
| `prim.closest_approach_distance` | the centre distance at that closest approach; undefined when they do not approach within the horizon **Not a stand-in for:** contact between bodies, the clearance between bodies, or the danger of a crash — it is computed from the centres under constant velocities, and alone establishes none of them |
| `prim.closest_approach_within` | under constant velocities, the centres of two road users approach each other at some time between the observation and the horizon **Not a stand-in for:** contact between bodies, the clearance between bodies, or the danger of a crash — it is computed from the centres under constant velocities, and alone establishes none of them |
| `prim.region_offset_along` | the signed distance (m) from a road user's reference point (`kin.position`) to a structure region (`st.region_geometry`), measured along a carrier's designated direction (`st.lane_direction`) on the straight line through the reference point parallel to that direction. The region is a closed set: a vertex the line only touches and an edge it runs along are points of it the line meets. Zero where the reference point lies in the region or on its boundary; where every point of the region on that line lies ahead, the distance to the nearest of them (positive); where every one lies behind, minus the distance to the nearest (negative); where the line does not meet the region, the value comes from the region's projection on the direction, the interval [lo, hi] of the signed distances of its points along it: lo where lo > 0 (all of the region ahead), hi where hi < 0 (all behind) — a projection gap, not a distance along the line, so the value may jump where the line starts or stops meeting the region, while its sign gives the side in both cases; undefined where the line meets the region both ahead and behind (the reference point lies in an opening of the region), where it misses the region and [lo, hi] spans or touches zero, and where the boundary is not a simple polygon (empty, fewer than three vertices, zero area, or crossing or touching itself); unknown where the position, the direction (a zero vector included) or the boundary is absent; independent of the boundary's start vertex and orientation. The direction is read normalised as `st.lane_direction` is, with Core's micrometre-rounded square root, and the distance is counted in lengths of that normalised vector (between 1 and 1 + 2·10⁻⁶ m), so it carries that rounding. It is a geometric quantity only: it does not establish that the road user is on the carrier, that the region marks the carrier's entrance, that the whole body has crossed the region, or that a crossing happened between observations; a caller states those with its own relations, footprint occupancy and temporal formulas; a distance to the region is read from `st.region_geometry`, never from this value |
| `rel.contact` | the bodies of two road users, or a road user and a structure, touch or overlap (a collision) **Not a stand-in for:** a near miss; bodies that do not touch or overlap are not in contact. |
| `rel.occupies` | a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure) |
| `ru.aggregate` | membership of a legal aggregate: the atom's literal argument is an aggregate id, `<definition id>::<term>` for the posted definition that applies, or `<law id>:<span>::<term>` for a definition the law itself makes, and the run's reading classifies every road-user class under that id by the definition's words as included, excluded (the definition leaves it out), covered (the definition admits its members only as members of named included classes, which a road user carries beside it, so its own label adds no membership evidence) or unresolved; true when the user carries an included class, unknown when no included class holds and the user carries an unresolved class or an included or unresolved class it might carry is unobserved, false otherwise: a covered or excluded class decides nothing **Not a stand-in for:** a named road-user class for which the applicable definitions and the run's representation decisions permit its own class atom — that class's own atom; an admitted aggregate stays an aggregate even when it contains only one class; a relational role such as who drives or controls a vehicle — never membership; nor a role the text describes by conduct (responding, overtaking) — a role is a derived concept |
| `ru.motorcycle` | motor vehicle on two or three wheels ridden astride, including three-wheeled variants |
| `st.crosswalk` | marked crossing, or the unmarked prolongation of sidewalks at an intersection (`st.intersection`); **marked** attribute |
| `st.entrance_of` | relation: the carrier whose entrance into an intersection a stop line or a crosswalk marks — exactly that carrier's entrance, the line or crossing a vehicle approaching through that carrier halts at or before, and not a line near the carrier or on its way. The carriers are those `st.lane_enters` admits: a lane or a kind refining it, or a roadway, one-way roadway, shoulder or bicycle lane or path recorded as a directed approach segment; the intersection is the one that carrier enters, so a rule reads both relations on the same carrier. One line may mark several carriers (several lanes, or lanes and a segment or a bicycle lane beside them), and a carrier may have a stop line and a crosswalk. Where the source observes a line's entrances its list is complete, and the line marks no carrier it does not list; where it does not, which carriers the line marks is unknown, never "no line for this carrier". The association is the source's record, never inferred from distance, overlap or a road user's velocity; a carrier never takes the line, nor the governance of a device (`dev.governs`), of a carrier it overlaps. No region other than a stop line or a crosswalk marks an entrance **Not a stand-in for:** distance to the line (`st.region_geometry`), or the way the line lies on (`st.on_way`) |
| `st.intersection` | the region where two roadways meet, bounded by the prolongation of their edges; a junction where an alley meets another way (a street, road, highway or alley) is no intersection but a `st.driveway_or_alley_entrance` **Not a stand-in for:** a crosswalk or a stop line — a stop before the crossing is earlier than a stop before the intersection **Refines:** `st.travel_region` |
| `st.lane_direction` | direction of travel designated for a structure a vehicle travels in — a lane, reserved lane, turn lane, bicycle lane or path, or a roadway, one-way roadway or shoulder; a centre turn lane carries none. The direction is local to its carrier (a bend or a loop is written as segments), carriers that overlap or cross may carry different directions, and a place no carrier covers has none (unknown). It is written at any length; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown |
| `st.lane_enters` | relation: the intersection region a directed approach carrier runs into at its entrance end — the carrier is an approach to that intersection. A carrier is a lane or a kind refining it, or a roadway, one-way roadway, shoulder or bicycle lane or path that the source records as a directed approach segment: the stretch one direction of travel uses to reach one junction, its entrance end at that junction. A bicycle lane or path stays its own kind, not a lane, and a mark or a device's governance on it does not pass to an adjacent lane, nor theirs to it. A two-way road between two junctions is written, where the source can separate its directions, as one segment per direction, each entering the junction its direction reaches; each keeps its kind, and none is relabelled one-way for having a direction, nor is a lane written where the road has none. Writing the relation on a roadway, one-way roadway, shoulder or bicycle lane or path asserts that it is such a segment: a whole two-way roadway or bicycle path, with an end at each junction, carries none, and which junction it is an approach to stays unknown. A carrier enters one intersection at most. The relation is entry topology: it is decided where the source records it, whether or not the carrier's direction (`st.lane_direction`) is observed. It is the source's record, never inferred from distance, overlap or a road user's velocity, and a carrier never takes the entrance of a carrier it overlaps. **Which carrier a road user approaches through:** a road user's approach to an intersection is a carrier it occupies (`rel.occupies`) whose entrance end is that intersection, and the mark that governs that approach is one the source records as marking that carrier (`st.entrance_of`). The intersection is fixed by the event the rule reads (the intersection entered, or the one the words name), never by the road user's velocity or heading, by distance or by overlap. A road user occupying one such carrier approaches through it whatever its motion: forward, at rest, backing, or with its velocity or heading unobserved. Overlapping carriers that enter different intersections are told apart by the intersection, not by motion. Where it occupies several carriers entering the same intersection and the verdict differs between them (different marks, or one mark's association unobserved), which governs is unknown; where the verdict is the same through each, it is decided; a rule never picks the carrier that favours the road user. Travel against a carrier's direction does not change which intersection the carrier enters, and reaching a carrier's far (exit) end is no entry through it **Not a stand-in for:** the lane a lane leads into (`st.lane_connectivity`), the subject's presence in the intersection (`rel.occupies`), or the region a device governs (`dev.governs`) — a device governs a lane and the lane enters an intersection; which intersection a device controls is read through both, or directly where the device governs the intersection |
| `st.region_geometry` | the reference point and the boundary polygon of a structure region in the world frame, and the ground distance from a road user's body outline to it (zero when they overlap); a source that maps regions without their outline declares it absent, and every such distance is then unknown **Not a stand-in for:** occupancy — a footprint inside a boundary is `rel.occupies`, which a source may observe without geometry |
| `st.stop_line` | the transverse line marking where vehicles halt for a device |
| `st.travel_region` | **Abstract.** the union of the kinds a device can govern (`dev.governs`): a lane and the kinds that refine it, a bicycle lane or path, a roadway and the kinds that refine it, a shoulder, or an intersection; a region is a travel region exactly when it is of one of them **Not a stand-in for:** the extent of a highway (`st.highway`, `st.on_way`) — a sidewalk, a crosswalk, a stop line or the way as a whole is no travel region; travel along or across a way, which the road user's motion and the region's direction state, never the kind of the region occupied; or which entry into an intersection a region is (`st.lane_enters`, `st.entrance_of`) |

| parameter | value | unit | convention |
|---|---|---|---|
| `p.conflict_centre_clearance` | 3.0 | m | centre-to-centre distance at the closest approach below which the bodies of a passenger car and another road user are taken to collide or nearly collide: about a car's half-length plus half a body width |
| `p.conflict_horizon` | 3.0 | s | time-to-collision threshold of the traffic-conflict technique: a closest approach later than this is not a present danger of a crash |
| `p.halt_speed_tolerance` | 0.1 | m/s | the speed at or below which a sampled speed counts as no movement: the source's speed resolution |
| `p.heading_since_step_carla_scene_graph` | 50 | ms | The sampling period of the carla_scene_graph acquisition standard, 20 Hz (one scene every 50 ms): the step bound of headingSince, the largest gap between two consecutive scenes it integrates across; not a look-back window and not an action window. |
| `p.stop_point_tolerance` | 2.0 | m | the body-to-mark gap within which a halt counts as at the mark: a stop line's set-back before a crossing plus a placement margin |
| `p.turn_heading_min` | 45.0 | deg | the smallest heading change over the turn window at which a change of course counts as a turn rather than a lane change or a drift |
| `p.u_turn_heading_min` | 135.0 | deg | the smallest heading change magnitude over the turn window at which a turn counts as a reversal of direction |

Admitted aggregates the node claims (a witness's road user is a member when it carries an included class; one carrying only an unresolved class makes the atom unknown):

- `DEF-NRS-484A-025::bicycle`: included ru.bicycle; unresolved (none)
- `DEF-NRS-484A-125::moped`: included ru.moped; unresolved ru.bus, ru.commercial_motor_vehicle, ru.electric_scooter, ru.emergency_vehicle, ru.fire_apparatus, ru.motor_vehicle, ru.official_vehicle, ru.rail_vehicle, ru.school_bus, ru.taxicab, ru.tour_bus_or_limousine, ru.trailer_or_combination, ru.transit_bus, ru.truck
- `DEF-NRS-484A-135::motorcycle`: included ru.motorcycle; unresolved ru.bus, ru.commercial_motor_vehicle, ru.emergency_vehicle, ru.fire_apparatus, ru.motor_vehicle, ru.official_vehicle, ru.school_bus, ru.taxicab, ru.tour_bus_or_limousine, ru.trailer_or_combination, ru.transit_bus, ru.truck
- `DEF-NRS-484A-165::pedestrian`: included ru.child, ru.pedestrian, ru.pedestrian_with_white_cane_or_guide_animal; unresolved (none)
- `DEF-NRS-484A-285::traffic`: included ru.bicycle, ru.bus, ru.child, ru.commercial_motor_vehicle, ru.electric_bicycle, ru.electric_scooter, ru.emergency_vehicle, ru.fire_apparatus, ru.moped, ru.motor_vehicle, ru.motorcycle, ru.official_vehicle, ru.pedestrian, ru.pedestrian_with_white_cane_or_guide_animal, ru.rail_vehicle, ru.school_bus, ru.taxicab, ru.tour_bus_or_limousine, ru.trailer_or_combination, ru.transit_bus, ru.truck; unresolved (none)
- `DEF-NRS-484B-017::electric_bicycle`: included ru.electric_bicycle; unresolved ru.bicycle, ru.bus, ru.commercial_motor_vehicle, ru.emergency_vehicle, ru.fire_apparatus, ru.motor_vehicle, ru.motorcycle, ru.official_vehicle, ru.rail_vehicle, ru.school_bus, ru.taxicab, ru.tour_bus_or_limousine, ru.trailer_or_combination, ru.transit_bus, ru.truck
- `DEF-NRS-484B-018::electric_scooter`: included (none); unresolved ru.bus, ru.child, ru.commercial_motor_vehicle, ru.electric_scooter, ru.emergency_vehicle, ru.fire_apparatus, ru.motor_vehicle, ru.motorcycle, ru.official_vehicle, ru.pedestrian, ru.pedestrian_with_white_cane_or_guide_animal, ru.rail_vehicle, ru.school_bus, ru.taxicab, ru.tour_bus_or_limousine, ru.trailer_or_combination, ru.transit_bus, ru.truck

The catalogue is `results/full221-1116-1018/reading.json` (read-only). Values enter a witness's geometry only: a `forbid` scene breaks the bound by a clear margin, a `permit` scene keeps it by one.

Acquisition standard: profile `carla_scene_graph`. Every `headingSince` step bound in a rule is exactly `.param "p.heading_since_step_carla_scene_graph"`, the operator's reviewed parameter: name it as it is, never propose it or a value for it.

(no node accepted yet in this library; the skeletons below are the pattern, the Core surface the vocabulary)

```lean
-- library/TrafficSpec/Rules/NRS_484B/NRS_484B_307_9b.lean (as written by the harness)
/-
  NRS_484B_307_9b — NRS-484B-307-9b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a steady red with a green turn arrow:
    s2 (subject): A person driving a motorcycle, moped or trimobile or riding a bicycle, an electric bicycle or an electric scooter
    s3 (trigger): facing the signal
    s4 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow
    s5 (boilerplate): if:
    s6 (obligation): (1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection; (2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter; (3) No other device at the place prohibits the turn, if applicable; and (4) The person yields
    s7 (standard): the right-of-way
    s8 (condition): to pedestrians lawfully within an adjacent crosswalk
    s9 (condition): and to other traffic lawfully using the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-135::motorcycle', 'ru.aggregate=DEF-NRS-484A-125::moped', 'ru.motorcycle', 'ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    s3: atoms ['dev.governs', 'rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s4: atoms ['dev.traffic_signal', 'rel.occupies', 'st.intersection'], derived ['drv.motion.left_turn_through_region', 'drv.motion.right_turn_through_region', 'drv.motion.u_turn_through_region']
    s6: atoms ['drv.motion.complete_halt', 'prim.region_offset_along', 'rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.intersection', 'st.lane_direction', 'st.lane_enters', 'st.region_geometry', 'st.stop_line', 'dev.governs', 'dev.traffic_signal', 'st.travel_region', 'dev.regulatory_sign', 'kin.speed', 'rel.contact', 'ru.aggregate=DEF-NRS-484A-135::motorcycle', 'ru.aggregate=DEF-NRS-484A-125::moped', 'ru.motorcycle', 'ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived ['drv.motion.complete_halt', 'drv.motion.left_turn_through_region', 'drv.motion.right_turn_through_region']
    s8: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian', 'rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.lane_enters', 'st.travel_region'], derived []
    s9: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.occupies', 'st.intersection'], derived []

  Literals the text states (each written through its Units constructor):
    s6: 2 count — two

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"

def zeroMetres : Term := .lit Q.zero .metre

-- TODO(code): class formulas, applicability and obligation — from the node's elements,
-- operationalizations and compositions, using only the claimed names. `.tt` is the placeholder.

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.aggregate=DEF-NRS-484A-125::moped, ru.motorcycle, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsSubject : Formula := .tt  -- TODO

/-- Applicability: s1 (trigger): Where the signal is a steady red with a green turn arrow:; s3 (trigger): facing the signal; s4 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow; s8 (condition): to pedestrians lawfully within an adjacent crosswalk; s9 (condition): and to other traffic lawfully using the intersection. -/
def applicability : Formula := .tt  -- TODO

/-- Obligation: s6 (obligation): (1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection; (2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter; (3) No other device at the place prohibits the turn, if applicable; and (4) The person yields; s7 (standard): the right-of-way -/
def obligation : Formula := .tt  -- TODO

def rule : Rule :=
  { id := "NRS_484B_307_9b"
    laws := ["NRS-484B-307-9b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the right-of-way"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within", "rel.contact"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "Traffic-conflict technique: the right-of-way (DEF-NRS-484A-210: precedence where 'direction, speed and proximity' give 'danger of a crash') is not yielded where the subject, moving (kin.speed above p.halt_speed_tolerance) within the intersection, is on a closest approach to a road user it must yield to within the horizon p.conflict_horizon at a centre distance below p.conflict_centre_clearance, or touches it (rel.contact)."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9b

```

```lean
-- library/TrafficSpecWitness/NRS_484B/NRS_484B_307_9b.lean (as written by the harness)
/-
  Witnesses for NRS_484B_307_9b.

  TODO(code): describe the geometry once built — the carriageway, the bodies, the instants; every
  figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): A motorcycle (ru.aggregate motorcycle) occupies approach lane c entering i, with a stop line recorded as marking c; the head governing c displays circular_red with green_arrow(left). The motorcycle halts at the stop line, waits while the red-with-arrow display comes on again once only, then enters i and exits straight ahead (no turn concept holds). No pedestrian or other road user is present. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `permit` (compliant): As in forbid, but the motorcycle remains at rest at the stop line while the red-with-arrow display rises twice, the head never displays circular_green, and it then proceeds straight through i. No other road user is in the scene, so the yield is decided on the subject alone. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `idle` (not_applicable): The head governing c displays circular_green at the motorcycle's entry; it proceeds straight through. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `blind` (unknown): As in forbid, but the state of the head governing c is never observed (dev.traffic_signal absent). -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `history_boundary` (unknown): The recording begins with the motorcycle already within the stop line's stopping zone on c, moving slowly, under red with green_arrow(left); it enters i and exits straight. No halt is recorded, the approach start and any earlier wait lie before the recording, and no earlier entry into i is recorded. -/
def history_boundaryTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `branch_1` (violated): As in permit, but the motorcycle turns right (opposite the left arrow; drv.motion.right_turn_through_region at the exit) while a dev.regulatory_sign with code no_right_turn governs c. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `branch_2` (violated): As in permit, but a pedestrian occupies the crosswalk recorded as marking the entrance of the opposite carrier; the moving motorcycle's closest approach to it lies within the horizon at a centre distance below the clearance. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `occasion_s1` (violated): The head displays circular_red with green_arrow(left) at the motorcycle's entry into i, made without any halt; it changes to circular_green while the motorcycle is in i; it exits straight ahead. -/
def occasion_s1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `occasion_s1_outside` (not_applicable): The head displays red with the green arrow while the motorcycle approaches, and circular_green from before its entry into i; it proceeds straight without halting. -/
def occasion_s1_outsideTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `occasion_s3` (violated): At its entry the motorcycle's footprint overlaps c (governed by the red-with-arrow head) and i; afterwards only i; it did not halt and exits straight. -/
def occasion_s3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `occasion_s3_outside` (not_applicable): The motorcycle occupied c while c's head showed red with the green arrow, then moved into an adjacent approach lane c2 whose governing head displays circular_green, and entered i from c2 only, exiting straight. -/
def occasion_s3_outsideTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `occasion_s8` (violated): As in permit, but for part of the passage a pedestrian occupies a crosswalk of i on a converging course; the moving motorcycle's closest approach to it lies within the horizon below the clearance while the pedestrian is in the crosswalk. -/
def occasion_s8Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `occasion_s8_outside` (compliant): As in permit, but a pedestrian occupied a crosswalk of i only before the motorcycle's entry and has left it before the entry; no other road user is present during the passage. -/
def occasion_s8_outsideTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `occasion_s9` (violated): As in permit, but for part of the passage another car occupies i on a converging course; the moving motorcycle's closest approach to it lies within the horizon below the clearance. -/
def occasion_s9Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `occasion_s9_outside` (compliant): As in permit, but another car occupied i only before the motorcycle's entry and left it before the entry. -/
def occasion_s9_outsideTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9b"
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
  , witness "blind" blindTrace (.unknown []) ["dev.traffic_signal"]
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the motorcycle's approach to the stop line on c and any run at rest there before the recording began")
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "occasion_s1" occasion_s1Trace .violated
  , witness "occasion_s1_outside" occasion_s1_outsideTrace .notApplicable
  , witness "occasion_s3" occasion_s3Trace .violated
  , witness "occasion_s3_outside" occasion_s3_outsideTrace .notApplicable
  , witness "occasion_s8" occasion_s8Trace .violated
  , witness "occasion_s8_outside" occasion_s8_outsideTrace .compliant
  , witness "occasion_s9" occasion_s9Trace .violated
  , witness "occasion_s9_outside" occasion_s9_outsideTrace .compliant ]

end TrafficSpecWitness.NRS_484B_307_9b

```

Run exactly this command, nothing more and nothing else:

```
python -m harness gate --run_id full221-1116-1018 --node_id NRS_484B_307_9b
```

It prints the verdict and its details. The verdicts on your files: SCOPE_VIOLATION, BUILD_FAIL, UNSOUND, CHECK_FAIL, UNANCHORED_VARIABLE, DECLARATION_MISMATCH, SCOPE_NARROWED, UNEXPRESSED, UNCLAIMED_ATOM, UNUSED_CLAIM, BARE_LITERAL, WITNESS_FAIL, VACUOUS, PARAM_MISMATCH, GATE_TIMEOUT, OK. `INFRA` is not one: the toolchain or the run did not let the gate judge your files. Budget: 6 runs; the harness re-runs the gate itself after you stop, on the files as they are then.


## Access

- You **edit** `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpec/Rules/NRS_484B/NRS_484B_307_9b.lean` and `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpecWitness/NRS_484B/NRS_484B_307_9b.lean` with the Edit and Write tools, and write
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

1. **Two files.** Edit `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpec/Rules/NRS_484B/NRS_484B_307_9b.lean` and `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpecWitness/NRS_484B/NRS_484B_307_9b.lean` only; their paths and the namespace
   `TrafficSpec.Rules.NRS_484B_307_9b` are derived from the node id and are not yours to choose. Declare
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

Working directory: `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/results/full221-1116-1018/iter-002/code/NRS_484B_307_9b`. Write `task_result.md` there.
