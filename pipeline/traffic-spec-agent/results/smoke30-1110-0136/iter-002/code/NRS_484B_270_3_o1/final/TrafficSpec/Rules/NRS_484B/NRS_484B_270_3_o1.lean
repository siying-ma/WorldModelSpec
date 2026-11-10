/-
  NRS_484B_270_3_o1 — NRS-484B-270-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a motor vehicle
    s2 (obligation): shall yield
    s3 (standard): the right-of-way
    s4 (condition): to any person riding a bicycle,
    s5 (condition): an electric bicycle
    s6 (condition): or an electric scooter
    s7 (condition): or a pedestrian
    s8 (reference): as provided in subsection 6 of NRS 484B.297 [NRS-484B-297-6]
    s9 (condition): on the pathway or lane.
    s10 (sibling): The driver of a motor vehicle shall not enter, stop, stand, park or drive within a pathway or lane provided for bicycles, electric bicycles or electric scooters except: (a) When entering or exiting an alley or driveway; (b) When operating or parking a disabled vehicle; (c) To avoid conflict with other traffic; (d) In the performance of official duties; (e) In compliance with the directions of a police officer; or (f) In an emergency.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.bicycle_lane_or_path'], derived ['drv.motion.moving']
    s4: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle'], derived []
    s5: atoms ['ru.aggregate=DEF-NRS-484B-017::electric_bicycle'], derived []
    s6: atoms ['ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    s7: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s9: atoms ['rel.occupies', 'st.bicycle_lane_or_path'], derived []

  Compositions (span → node, as, map):
    s8: NRS_484B_297_6_o2 as condition map {'x': 'y'}

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_3_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictTimeHorizon : Term := .param "p.conflict_time_horizon"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    s1: `ru_aggregate x "DEF-NRS-484A-130::motor_vehicle"` is the class of x.
    s2: the occasion of the duty — x's footprint on a bicycle lane or path b
        (`existsRegion "bicycle_lane_or_path" b`, `rel_occupies x b`) while x moves
        (`drv_motion_moving x` with p.motion_speed_tolerance).
    s4–s7: the protected road user y is a member of DEF-NRS-484A-025::bicycle,
        DEF-NRS-484B-017::electric_bicycle or DEF-NRS-484B-018::electric_scooter, or of
        DEF-NRS-484A-165::pedestrian where s8 holds; y is not x (`same`).
    s8: `ruleApplies "NRS_484B_297_6_o2" [("x", "y")]`, conjoined to the pedestrian limb only.
    s9: y's footprint on the same b (`rel_occupies y b`).
    s3: the danger of a crash is a predicted closest approach of the centres of x and y within
        p.conflict_time_horizon (`prim_closest_approach_within`) at a centre distance below
        p.conflict_centre_clearance (`prim_closest_approach_distance`); the distance is read only
        under the approach, where it is defined.
    Obligation: for every b and y of the applicability's selection (b a bicycle lane or path x
    occupies, y a protected road user other than x occupying b), no such conflict.
  No choice beyond the record's was made.
-/

def vY : Arg := .var "y"
def vB : Arg := .var "b"

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- s2: x moves. -/
def xMoving : Formula := .derived "drv_motion_moving" [vX] [pMotionSpeedTolerance]

/-- s4–s8: y is a road user the duty protects. -/
def protectedY : Formula :=
  .or (.atom "ru_aggregate" [vY, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [vY, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
      (.or (.atom "ru_aggregate" [vY, .lit "DEF-NRS-484B-018::electric_scooter"] [])
        (.and (.atom "ru_aggregate" [vY, .lit "DEF-NRS-484A-165::pedestrian"] [])
          (.ruleApplies "NRS_484B_297_6_o2" [("x", "y")]))))

/-- s4–s9: y, other than x, protected, with its footprint on b. -/
def selY : Formula :=
  .and (.not (.same vY vX)) (.and (.atom "rel_occupies" [vY, vB] []) protectedY)

/-- s3: the predicted closest approach of x and y is a conflict. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, vY] [pConflictTimeHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, vY] [pConflictTimeHorizon]) .lt
      pConflictCentreClearance)

/-- Applicability: s4 (condition): to any person riding a bicycle,; s5 (condition): an electric bicycle; s6 (condition): or an electric scooter; s7 (condition): or a pedestrian; s9 (condition): on the pathway or lane. -/
def applicability : Formula :=
  .and xMoving
    (.existsRegion (.lit "bicycle_lane_or_path") "b"
      (.and (.atom "rel_occupies" [vX, vB] []) (.existsUser "y" selY)))

/-- Obligation: s2 (obligation): shall yield; s3 (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "bicycle_lane_or_path") "b"
    (.implies (.atom "rel_occupies" [vX, vB] [])
      (.forallUser "y" (.implies selY (.not conflict))))

def rule : Rule :=
  { id := "NRS_484B_270_3_o1"
    laws := ["NRS-484B-270-3"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the right-of-way (DEF-NRS-484A-210: 'circumstances of direction, speed and proximity as to give rise to the danger of a crash')"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_time_horizon", "p.conflict_centre_clearance"]
          convention := "Traffic-conflict technique: the danger of a crash is a predicted closest approach of the two centres under constant velocities within the time-to-collision horizon at a centre distance below the clearance."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_270_3_o1
