/-
  NRS_484B_270_3_o2 — NRS-484B-270-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (sibling): The driver of a motor vehicle shall yield the right-of-way to any person riding a bicycle, an electric bicycle or an electric scooter or a pedestrian as provided in subsection 6 of NRS 484B.297 [NRS-484B-297-6] on the pathway or lane.
    s2 (subject): The driver of a motor vehicle
    s3 (obligation): shall not enter, stop, stand, park or drive within a pathway or lane provided for bicycles, electric bicycles or electric scooters
    s4 (boilerplate): except:
    s5 (exception): (a) When entering or exiting an alley or driveway;
    s6 (exception): (b) When operating or parking a disabled vehicle;
    s7 (exception): (c) To avoid conflict with other traffic;
    s8 (exception): (d) In the performance of official duties;
    s9 (exception): (e) In compliance with the directions of a police officer;
    s10 (exception): or (f) In an emergency.

  Elements (span → atoms, derived):
    s2: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    s3: atoms ['rel.occupies', 'st.bicycle_lane_or_path'], derived []
    s5: atoms ['rel.occupies', 'st.driveway_or_alley_entrance', 'st.alley'], derived []
    s7: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'prim.closest_approach_within', 'prim.closest_approach_distance'], derived []
    s9: atoms ['dev.human_direction', 'dev.governs', 'st.travel_region'], derived []

  How each span is written:
    s2: the class of x is `ru_aggregate x "DEF-NRS-484A-130::motor_vehicle"`.
    s3: the obligation is that x occupies (`rel_occupies`) no region of kind `bicycle_lane_or_path`.
    Applicability: for every bicycle lane or path b that x occupies, no exception holds for b; where x
    occupies none, the implication is vacuous and the rule applies (the record's applicability).
    s5: x's current stay on b is the run of observations at which `rel_occupies x b` holds. "Exiting":
      `since (occ x b) (occ x b ∧ E)` — an observation of the stay up to now at which E held;
      "entering": `until (occ x b) (occ x b ∧ E)` — one from now on in the stay. E is x occupying a
      region of kind `driveway_or_alley_entrance` or of kind `alley`.
    s6, s8, s10: the declared assumptions, each read at the observation.
    s7: `since (occ x b) (rises (occ x b) ∧ C)` — C at the observation at which the current stay on b
      began (the rise of the occupancy). C: some road user z, not x (`same`), of the aggregate
      DEF-NRS-484A-285::traffic, not occupying b, with `prim_closest_approach_within x z
      [p.conflict_time_horizon]` and `prim_closest_approach_distance x z [p.conflict_time_horizon]`
      below `p.conflict_centre_clearance`.
    s9: some device of kind `human_direction` with role `police_officer` governs (`dev_governs`) a
      region of kind `travel_region` that x occupies.
  No choice beyond the record's own narrowings was made.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_3_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictTimeHorizon : Term := .param "p.conflict_time_horizon"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- `x` occupies the bicycle lane or path bound to `b`. -/
def onLane : Formula := .atom "rel_occupies" [vX, .var "b"] []

/-- s5: x's footprint overlaps a driveway or alley entrance, or an alley. -/
def onDrivewayOrAlley : Formula :=
  .or (.existsRegion (.lit "driveway_or_alley_entrance") "d" (.atom "rel_occupies" [vX, .var "d"] []))
      (.existsRegion (.lit "alley") "a" (.atom "rel_occupies" [vX, .var "a"] []))

/-- s5 (a): at some observation of the current stay on b, before (exiting) or after (entering). -/
def excDriveway : Formula :=
  .or (.since onLane (.and onLane onDrivewayOrAlley))
      (.until onLane (.and onLane onDrivewayOrAlley))

/-- s7: some other road user that is traffic, not on b, has a predicted closest approach to x
    within the horizon at a centre distance below the clearance. -/
def conflict : Formula :=
  .existsUser "z"
    (.and (.not (.same (.var "z") vX))
      (.and (.atom "ru_aggregate" [.var "z", .lit "DEF-NRS-484A-285::traffic"] [])
        (.and (.not (.atom "rel_occupies" [.var "z", .var "b"] []))
          (.and (.derived "prim_closest_approach_within" [vX, .var "z"] [pConflictTimeHorizon])
            (.cmp (.quantity "prim_closest_approach_distance" [vX, .var "z"] [pConflictTimeHorizon])
              .lt pConflictCentreClearance)))))

/-- s7 (c): the conflict held at the observation at which the current stay on b began. -/
def excConflict : Formula :=
  .since onLane (.and (.rises onLane) conflict)

/-- s9 (e): a police officer's direction governs a travel region x occupies. -/
def excOfficer : Formula :=
  .existsDevice (.lit "human_direction") "h"
    (.and (.atom "dev_human_direction_role" [.var "h", .lit "police_officer"] [])
      (.existsRegion (.lit "travel_region") "r"
        (.and (.atom "rel_occupies" [vX, .var "r"] [])
          (.atom "dev_governs" [.var "h", .var "r"] []))))

/-- Any of the six exceptions, for the bicycle lane or path `b`. -/
def exceptions : Formula :=
  .or excDriveway
    (.or (.asm "asm.vehicle_disabled")
      (.or excConflict
        (.or (.asm "asm.performing_official_duties")
          (.or excOfficer (.asm "asm.emergency")))))

/-- Applicability: s5 (exception): (a) When entering or exiting an alley or driveway;; s6 (exception): (b) When operating or parking a disabled vehicle;; s7 (exception): (c) To avoid conflict with other traffic;; s8 (exception): (d) In the performance of official duties;; s9 (exception): (e) In compliance with the directions of a police officer;; s10 (exception): or (f) In an emergency. -/
def applicability : Formula :=
  .forallRegion (.lit "bicycle_lane_or_path") "b" (.implies onLane (.not exceptions))

/-- Obligation: s3 (obligation): shall not enter, stop, stand, park or drive within a pathway or lane provided for bicycles, electric bicycles or electric scooters -/
def obligation : Formula :=
  .forallRegion (.lit "bicycle_lane_or_path") "b" (.not onLane)

def rule : Rule :=
  { id := "NRS_484B_270_3_o2"
    laws := ["NRS-484B-270-3"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.vehicle_disabled", "asm.performing_official_duties", "asm.emergency"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_270_3_o2
