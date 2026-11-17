/-
  NRS_484B_127_2 — NRS-484B-127-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    g1 (subject): The driver of any truck or combination of vehicles 80 inches or more in overall width,
    g2 (trigger): which is following a truck, or combination of vehicles 80 inches or more in overall width,
    g3 (standard): shall, whenever conditions permit,
    g4 (obligation): leave a space of 500 feet so that an overtaking vehicle may enter and occupy such space without danger,
    g5 (exception): but this shall not prevent a truck or combination of vehicles from overtaking and passing any vehicle or combination of vehicles.
    g6 (exception): This subsection does not apply to any vehicle or combination of vehicles while moving on a highway on which there are two or more lanes available for traffic moving in the same direction.

  Elements (span → atoms, derived):
    g1: atoms ['ru.aggregate=DEF-NRS-484A-305::truck', 'ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles', 'kin.extent'], derived []
    g2: atoms ['ru.aggregate=DEF-NRS-484A-305::truck', 'ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles', 'kin.extent', 'rel.ahead_behind_in_lane'], derived []
    g4: atoms ['rel.surface_gap'], derived []
    g5: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles'], derived ['drv.interaction.overtake_pass']
    g6: atoms ['rel.occupies', 'st.lane', 'st.lane_adjacency'], derived []

  How each is written:
    g1 — binder class: ru_aggregate(subject, truck) ∨ ru_aggregate(subject, combination_of_vehicles);
         the width is in the applicability: kin_extent(subject, "width") ≥ 80 in (full width).
    g6 — applicability: no lane r (existsRegion "lane", the kind st.lane names) that the subject
         occupies (rel_occupies) counts two or more lanes in its direction
         (st_lane_adjacency(r, "count") ≥ 2).
    g2 — antecedent of the obligation, for every road user b other than the subject: b is a truck or
         a combination of vehicles of full width ≥ 80 in, b is ahead of the subject in a shared lane
         (rel_ahead_behind_in_lane(b, subject): first argument ahead of the second), and no road
         user c (other than the subject and b) is ahead of the subject and behind b in a lane
         (rel_ahead_behind_in_lane(c, subject) ∧ rel_ahead_behind_in_lane(b, c)). A rule that has
         no such b is complied with (the subject drives alone).
    g3 — operationalization: conditions permit where, at every observation of the window behind of
         length p.truck_space_open_time (holdsFor .time, subject), b was so the subject's immediate
         leader and neither the subject nor b was at rest (not drv_motion_complete_halt with
         p.halt_speed_tolerance). The duty is excused where it is not so.
    g5 — exception inside the duty: within the window ahead of length p.overtake_window some road
         user o that is a vehicle or a combination of vehicles (admitted aggregates) is overtaken
         and passed by the subject (drv_interaction_overtake_pass(subject, o), p.overtake_window,
         p.overtake_same_direction_cos).
    g4 — the longitudinal component of rel_surface_gap(subject, b) ≥ 500 ft.
    Obligation: ∀ b, g2(b) → (¬g3(b) ∨ g5 ∨ g4(b)).

  Choices the record left open: none beyond the record's own narrowings; the immediate-leader
  condition is read with the same atom in both the trigger and the standard, as the record states.

  Literals the text states (each written through its Units constructor):
    g1: 80 in — 80 inches
    g2: 80 in — 80 inches
    g4: 500 ft — 500 feet
    g6: 2 count — two

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_127_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables. -/
def vB : Arg := .var "b"
def vC : Arg := .var "c"
def vO : Arg := .var "o"
def vR : Arg := .var "r"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"
def pTruckSpaceOpenTime : Term := .param "p.truck_space_open_time"

def zeroMetres : Term := .lit Q.zero .metre

/-- The text's literals. -/
def eightyInches : Term := .lit (Units.inches 80) .metre
def fiveHundredFeet : Term := .lit (Units.feet 500) .metre
def twoLanes : Term := .lit (Units.ratio 2 1) .count

/-- Admitted aggregates. -/
def isTruck (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-305::truck"] []
def isCombination (x : Arg) : Formula :=
  .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-050::combination_of_vehicles"] []
def isVehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Full width (kin.extent) at least 80 inches. -/
def wide (x : Arg) : Formula :=
  .cmp (.measure "kin_extent" [x, .lit "width"]) .ge eightyInches

/-- `a` ahead of `b` in a shared lane. -/
def aheadInLane (a b : Arg) : Formula := .atom "rel_ahead_behind_in_lane" [a, b] []

/-- g2: b is ahead of the subject in its lane with no other road user ahead of the subject and
    behind b in that lane. -/
def immediateLeader : Formula :=
  .and (aheadInLane vB vSubject)
    (.not (.existsUser "c"
      (.and (.not (.same vC vSubject))
        (.and (.not (.same vC vB))
          (.and (aheadInLane vC vSubject) (aheadInLane vB vC))))))

/-- At rest (drv.motion.complete_halt). -/
def atRest (x : Arg) : Formula := .derived "drv_motion_complete_halt" [x] [pHaltSpeedTolerance]

/-- g3: conditions permit the space. -/
def conditionsPermit : Formula :=
  .holdsFor .time pTruckSpaceOpenTime "subject"
    (.and immediateLeader (.and (.not (atRest vSubject)) (.not (atRest vB))))

/-- g5: the subject overtakes and passes a vehicle or combination of vehicles, recognized within the
    window ahead. -/
def overtakingAndPassing : Formula :=
  .within .time pOvertakeWindow "subject"
    (.existsUser "o"
      (.and (.or (isVehicle vO) (isCombination vO))
        (.derived "drv_interaction_overtake_pass" [vSubject, vO]
          [pOvertakeWindow, pOvertakeSameDirectionCos])))

/-- g4: the space of 500 feet, the longitudinal component of the body gap to b. -/
def spaceLeft : Formula :=
  .cmp (.measure "rel_surface_gap" [vSubject, vB, .lit "longitudinal"]) .ge fiveHundredFeet

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-305::truck, ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles -/
def clsSubject : Formula := .or (isTruck vSubject) (isCombination vSubject)

/-- Applicability: g1 width; g6 (exception): not on a highway whose lane, occupied by the subject,
    counts two or more lanes in its direction. -/
def applicability : Formula :=
  .and (wide vSubject)
    (.not (.existsRegion (.lit "lane") "r"
      (.and (.atom "rel_occupies" [vSubject, vR] [])
        (.cmp (.measure "st_lane_adjacency" [vR, .lit "count"]) .ge twoLanes))))

/-- Obligation: g2 → (not g3 ∨ g5 ∨ g4), for every followed wide truck or combination. -/
def obligation : Formula :=
  .forallUser "b"
    (.implies
      (.and (.not (.same vB vSubject))
        (.and (.or (isTruck vB) (isCombination vB))
          (.and (wide vB) immediateLeader)))
      (.or (.not conditionsPermit) (.or overtakingAndPassing spaceLeft)))

def rule : Rule :=
  { id := "NRS_484B_127_2"
    laws := ["NRS-484B-127-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "whenever conditions permit"
          concepts := ["drv.motion.complete_halt", "rel.ahead_behind_in_lane"]
          params := ["p.truck_space_open_time", "p.halt_speed_tolerance"]
          convention := "Conditions permit the space where the followed vehicle has been the subject's immediate leader in its lane (rel.ahead_behind_in_lane, no other road user between) and neither vehicle has been at rest (not drv.motion.complete_halt) at every observation of the window behind of length p.truck_space_open_time: the time a heavy vehicle needs to open the space behind a leader by easing off a few miles per hour. A leader that has just come ahead of the subject, or a queue at rest, does not yet permit it."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_127_2
