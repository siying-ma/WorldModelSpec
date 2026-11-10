/-
  NRS_484B_450_1c — NRS-484B-450-1c

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    c1 (obligation): A person shall not stop, stand or park
    c2 (subject): a vehicle,
    c3 (exception): except when necessary to avoid conflict with other traffic
    c4 (exception): or in compliance with law
    c5 (exception): or the directions of a police officer
    c6 (exception): or official traffic-control device,
    c7 (boilerplate): in any of the following places:
    c8 (condition): Within an intersection.

  Elements (span → atoms, derived):
    c1: atoms [], derived ['drv.motion.stopped']
    c2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    c3: atoms ['prim.closest_approach_within', 'prim.closest_approach_distance', 'rel.surface_gap', 'rel.bearing', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    c5: atoms ['dev.human_direction', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    c6: atoms ['dev.traffic_signal', 'dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    c8: atoms ['rel.occupies', 'st.intersection'], derived []

  How each span is written:
    c2: the class of x is `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
    c8: the applicability: some region of kind intersection that x occupies (`rel_occupies`).
    c1: the obligation forbids a halt there: `drv_motion_stopped x p.motion_speed_tolerance`, read at
        the judged observation (the concept reads one observation; the record states no window).
        The exceptions c3 to c6 are carried in the obligation, as the record's obligation states
        ("violated where x is halted and none of the exceptions holds"), so a halt the exceptions
        excuse is compliant, not out of scope.
    c3: some road user z, not x (`same`), member of `DEF-NRS-484A-285::traffic`, either in a predicted
        conflict (`prim_closest_approach_within x z` over p.conflict_time_horizon and the centre
        distance at that approach below p.conflict_centre_clearance) or ahead of x (`rel_bearing x z
        "ahead"`, the longitudinal component of the bearing positive) with the surface gap between
        the bodies (`rel_surface_gap x z`, read without a component: the distance) below
        p.queue_standstill_gap.
    c4: `asm.halt_required_by_law`.
    c5: a device of kind human_direction, role police_officer, indication stop, governing a travel
        region x occupies.
    c6: a traffic_signal showing circular_red, a red_arrow (any of its four directions) or
        flashing_red, a stop_sign or a yield_sign, governing a travel region x occupies.
    c5, c6: "a travel region x occupies or i" is written as the travel regions x occupies: the
        intersection i of the applicability is an intersection x occupies, and an intersection
        refines travel_region, so the quantifier over travel regions x occupies already ranges over i
        with its whole selection (kind intersection, occupied by x); no separate disjunct for i.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_450_1c

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictTimeHorizon : Term := .param "p.conflict_time_horizon"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pQueueStandstillGap : Term := .param "p.queue_standstill_gap"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantifier variables. -/
def vZ : Arg := .var "z"
def vR : Arg := .var "r"
def vI : Arg := .var "i"
def vD : Arg := .var "d"

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- c8: x's footprint overlaps an intersection. -/
def withinIntersection : Formula :=
  .existsRegion (.lit "intersection") "i" (.atom "rel_occupies" [vX, vI] [])

/-- Applicability: c8 (condition): Within an intersection. The exceptions c3 to c6 are carried in
    the obligation, where the record's obligation places them. -/
def applicability : Formula := withinIntersection

/-- c1: x is halted. -/
def halted : Formula := .derived "drv_motion_stopped" [vX] [pMotionSpeedTolerance]

/-- c3, first limb: z in a predicted conflict with x. -/
def predictedConflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, vZ] [pConflictTimeHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, vZ] [pConflictTimeHorizon]) .lt
      pConflictCentreClearance)

/-- c3, second limb: z stands ahead of x within the queue standstill gap of x's body. -/
def queuedAhead : Formula :=
  .and (.atom "rel_bearing" [vX, vZ, .lit "ahead"] [])
    (.cmp (.measure "rel_surface_gap" [vX, vZ]) .lt pQueueStandstillGap)

/-- c3: necessary to avoid conflict with other traffic. -/
def avoidConflict : Formula :=
  .existsUser "z"
    (.and (.not (.same vZ vX))
      (.and (.atom "ru_aggregate" [vZ, .lit "DEF-NRS-484A-285::traffic"] [])
        (.or predictedConflict queuedAhead)))

/-- c4: in compliance with law. -/
def requiredByLaw : Formula := .asm "asm.halt_required_by_law"

/-- c5: a police officer's stop direction governing region `r`. -/
def officerStop : Formula :=
  .existsDevice (.lit "human_direction") "d"
    (.and (.atom "dev_governs" [vD, vR] [])
      (.and (.atom "dev_human_direction_role" [vD, .lit "police_officer"] [])
        (.atom "dev_human_direction_indication" [vD, .lit "stop"] [])))

/-- The halt indications of a signal head: circular red, a red arrow, flashing red. -/
def showsHalt : Formula :=
  .or (.atom "dev_traffic_signal_shows" [vD, .lit "circular_red"] [])
    (.or (.atom "dev_traffic_signal_shows" [vD, .lit "red_arrow(left)"] [])
      (.or (.atom "dev_traffic_signal_shows" [vD, .lit "red_arrow(right)"] [])
        (.or (.atom "dev_traffic_signal_shows" [vD, .lit "red_arrow(straight)"] [])
          (.or (.atom "dev_traffic_signal_shows" [vD, .lit "red_arrow(u_turn)"] [])
            (.atom "dev_traffic_signal_shows" [vD, .lit "flashing_red"] [])))))

/-- c6: an official traffic-control device directing a halt governing region `r`. -/
def deviceHalt : Formula :=
  .or (.existsDevice (.lit "traffic_signal") "d" (.and (.atom "dev_governs" [vD, vR] []) showsHalt))
    (.or (.existsDevice (.lit "stop_sign") "d" (.atom "dev_governs" [vD, vR] []))
      (.existsDevice (.lit "yield_sign") "d" (.atom "dev_governs" [vD, vR] [])))

/-- c5, c6: a direction governing a travel region x occupies (the intersection i among them). -/
def directedHalt (dir : Formula) : Formula :=
  .existsRegion (.lit "travel_region") "r" (.and (.atom "rel_occupies" [vX, vR] []) dir)

/-- Obligation: c1 (obligation): A person shall not stop, stand or park — unless c3, c4, c5 or c6. -/
def obligation : Formula :=
  .not (.and halted
    (.and (.not avoidConflict)
      (.and (.not requiredByLaw)
        (.and (.not (directedHalt officerStop))
          (.not (directedHalt deviceHalt))))))

def rule : Rule :=
  { id := "NRS_484B_450_1c"
    laws := ["NRS-484B-450-1c"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.halt_required_by_law"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_450_1c
