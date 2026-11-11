/-
  NRS_484B_270_3_o2 — NRS-484B-270-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (sibling): The driver of a motor vehicle
    s2 (sibling): shall yield
    s3 (sibling): the right-of-way
    s4 (sibling): to any person riding a bicycle, an electric bicycle or an electric scooter
    s5 (sibling): or a pedestrian
    s6 (sibling): as provided in subsection 6 of NRS 484B.297 [NRS-484B-297-6]
    s7 (sibling): on the pathway or lane.
    s8 (subject): The driver of a motor vehicle
    s9 (obligation): shall not enter, stop, stand, park or drive within
    s10 (condition): a pathway or lane provided for bicycles, electric bicycles or electric scooters
    s11 (exception): except: (a) When entering or exiting an alley or driveway;
    s12 (exception): (b) When operating or parking a disabled vehicle;
    s13 (exception): (c) To avoid conflict with other traffic;
    s14 (exception): (d) In the performance of official duties;
    s15 (exception): (e) In compliance with the directions of a police officer;
    s16 (boilerplate): or
    s17 (exception): (f) In an emergency.

  Elements (span → atoms, derived):
    s8: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    s9: atoms ['rel.occupies', 'kin.speed'], derived ['drv.motion.entering_region', 'drv.motion.halted', 'drv.motion.moving']
    s10: atoms ['st.bicycle_lane_or_path', 'rel.occupies'], derived []
    s11: atoms ['st.driveway_or_alley_entrance', 'st.region_geometry', 'kin.speed'], derived ['drv.motion.moving']
    s12: atoms ['sig.hazard', 'kin.engine_running'], derived []
    s13: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.occupies', 'st.bicycle_lane_or_path', 'prim.closest_approach_within', 'prim.closest_approach_distance'], derived ['drv.motion.entering_region']
    s14: atoms ['ru.official_vehicle', 'ru.emergency_vehicle'], derived []
    s15: atoms ['dev.human_direction', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    s17: atoms ['sig.hazard', 'ru.emergency_vehicle'], derived []

  How each span is written:
    s8  — the class of x: ru_aggregate x DEF-NRS-484A-130::motor_vehicle.
    s9 + s10 — the obligation: for every region b of kind bicycle_lane_or_path, x is not entering b
          (drv_motion_entering_region x b), not halted on it (rel_occupies x b ∧ drv_motion_halted x),
          and not moving within it (rel_occupies x b ∧ drv_motion_moving x), the floor of both being
          p.speed_resolution. Halted and moving together cover every observed speed, so the duty is
          "x's footprint overlaps no bicycle lane or path".
    s11 — exception (a): x moving and some driveway_or_alley_entrance r with
          st_region_geometry_distance x r ≤ p.access_crossing_reach ("within" read as at most).
    s12 — exception (b) "a disabled vehicle": no atom of the surface denotes a vehicle unable to move
          under its own power; sig.hazard and kin.engine_running do not carry it (the record's own
          gap). Declared `no_atom`; the exception is not written.
    s13 — exception (c): some bicycle lane or path b with rel_occupies x b, and
          `since (rel_occupies x b) (entering x b ∧ ∃ z ≠ x, traffic(z) ∧ ¬ rel_occupies z b ∧
          prim_closest_approach_within x z ∧ prim_closest_approach_distance x z < p.conflict_clearance)`,
          horizon p.immediate_hazard_gap: the current overlap began at an entry at which other traffic
          not on b was in predicted conflict with x, and has held at every observation since.
    s14 — exception (d): ru_official_vehicle x ∨ ru_emergency_vehicle x.
    s15 — exception (e): some human_direction device d with role police_officer governing a
          travel_region r that x occupies (the bicycle lane is a travel region, so it is covered).
    s17 — exception (f) "an emergency": no atom denotes an emergency situation; sig.hazard and
          ru.emergency_vehicle do not carry it (the record's own gap). Declared `no_atom`; not written.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_3_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pAccessCrossingReach : Term := .param "p.access_crossing_reach"
def pConflictClearance : Term := .param "p.conflict_clearance"
def pImmediateHazardGap : Term := .param "p.immediate_hazard_gap"
def pSpeedResolution : Term := .param "p.speed_resolution"

def zeroMetres : Term := .lit Q.zero .metre

def vB : Arg := .var "b"
def vR : Arg := .var "r"
def vZ : Arg := .var "z"
def vD : Arg := .var "d"

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-130::motor_vehicle"] []

def moving : Formula := .derived "drv_motion_moving" [vX] [pSpeedResolution]
def halted : Formula := .derived "drv_motion_halted" [vX] [pSpeedResolution]
def occupiesB : Formula := .atom "rel_occupies" [vX, vB] []
def enteringB : Formula := .derived "drv_motion_entering_region" [vX, vB] []

/-- s11 (a): x moving within the access reach of a driveway or alley entrance. -/
def excDriveway : Formula :=
  .and moving
    (.existsRegion (.lit "driveway_or_alley_entrance") "r"
      (.cmp (.measure "st_region_geometry_distance" [vX, vR]) .le pAccessCrossingReach))

/-- s13 (c): some road user z other than x, a member of traffic not on b, in predicted conflict
    with x. -/
def conflictWithOther : Formula :=
  .existsUser "z"
    (.and (.not (.same vZ vX))
      (.and (.atom "ru_aggregate" [vZ, .lit "DEF-NRS-484A-285::traffic"] [])
        (.and (.not (.atom "rel_occupies" [vZ, vB] []))
          (.and (.derived "prim_closest_approach_within" [vX, vZ] [pImmediateHazardGap])
            (.cmp (.quantity "prim_closest_approach_distance" [vX, vZ] [pImmediateHazardGap])
              .lt pConflictClearance)))))

/-- s13 (c): x's current overlap of b began at an entry made in predicted conflict with other
    traffic, and has continued at every observation since. The search into the past is read only
    where the current overlap is observed (`definedWhen`): where it is false the conjunction is
    false anyway, and where it is unobserved the exception is unknown for that atom alone. -/
def excConflict : Formula :=
  .existsRegion (.lit "bicycle_lane_or_path") "b"
    (.and occupiesB
      (.definedWhen occupiesB (.since occupiesB (.and enteringB conflictWithOther))))

/-- s14 (d): the vehicle's official or emergency class. -/
def excOfficial : Formula :=
  .or (.atom "ru_official_vehicle" [vX] []) (.atom "ru_emergency_vehicle" [vX] [])

/-- s15 (e): a police officer directing traffic governs a travel region x occupies. -/
def excPolice : Formula :=
  .existsDevice (.lit "human_direction") "d"
    (.and (.atom "dev_human_direction_role" [vD, .lit "police_officer"] [])
      (.existsRegion (.lit "travel_region") "r"
        (.and (.atom "rel_occupies" [vX, vR] []) (.atom "dev_governs" [vD, vR] []))))

/-- Applicability: none of the exceptions holds (s11, s13, s14, s15; s12 and s17 have no atom). -/
def applicability : Formula :=
  .not (.or excDriveway (.or excConflict (.or excOfficial excPolice)))

/-- Obligation (s9, s10): x neither enters, nor halts on, nor drives within any bicycle lane or path. -/
def obligation : Formula :=
  .forallRegion (.lit "bicycle_lane_or_path") "b"
    (.not (.or enteringB (.or (.and occupiesB halted) (.and occupiesB moving))))

def rule : Rule :=
  { id := "NRS_484B_270_3_o2"
    laws := ["NRS-484B-270-3"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s12"
          why := "'a disabled vehicle': no atom of the surface denotes a vehicle's inability to move under its own power; sig.hazard (both indicators flashing) and kin.engine_running (propulsion available, not a stand-in for motion) are evidence at most and do not carry the words."
          kind := "no_atom" }
      , { span := "s17"
          why := "'In an emergency': no atom of the surface denotes an emergency situation at the observation; sig.hazard and ru.emergency_vehicle (not a stand-in for a responding emergency vehicle) do not carry the words."
          kind := "no_atom" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_270_3_o2
