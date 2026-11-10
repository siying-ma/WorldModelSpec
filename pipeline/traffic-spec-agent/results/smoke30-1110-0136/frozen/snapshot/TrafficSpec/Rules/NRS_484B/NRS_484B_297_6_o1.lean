/-
  NRS_484B_297_6_o1 — NRS-484B-297-6

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A pedestrian
    s2 (trigger): walking or otherwise traveling on a sidewalk
    s3 (trigger): who encounters an obstruction to his or her mobility on the sidewalk,
    s4 (trigger): including, without limitation, a short section of the sidewalk that is missing or impassable,
    s5 (condition): may proceed
    s6 (condition): with due care
    s7 (condition): on the immediately adjacent highway
    s8 (condition): to move around such an obstruction.
    s9 (subject): Such a pedestrian:
    s10 (obligation): (a) Must walk or otherwise travel as far to the side of the highway near the sidewalk
    s11 (standard): as possible;
    s12 (exception): (b) May walk or otherwise travel on the highway in the direction he or she was walking or traveling on the sidewalk, regardless of the direction of traffic;
    s13 (exception): (c) May walk or otherwise travel in a lane provided for bicycles, electric bicycles or electric scooters
    s14 (exception): if the area between the lane and the sidewalk is impassable;
    s15 (sibling): and (d) Must return to the sidewalk as soon as practicable.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s2: atoms ['rel.occupies', 'st.sidewalk'], derived ['drv.motion.moving']
    s3: atoms ['st.obstruction', 'st.region_geometry', 'rel.occupies', 'st.sidewalk'], derived []
    s5: atoms [], derived ['drv.motion.moving']
    s7: atoms ['rel.occupies', 'st.highway', 'st.on_way', 'st.sidewalk'], derived []
    s8: atoms ['st.obstruction', 'st.region_geometry'], derived []
    s9: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s10: atoms ['rel.occupies', 'st.highway', 'st.sidewalk', 'st.region_geometry'], derived []
    s13: atoms ['rel.occupies', 'st.bicycle_lane_or_path'], derived []

  How each is written:
    s1/s9: `ru_aggregate x DEF-NRS-484A-165::pedestrian` (the binder's class).
    s2/s5: at the departure observation, x occupies the sidewalk w and is moving
      (`drv_motion_moving` with p.motion_speed_tolerance).
    s3/s4/s8: at that same observation, an obstruction region o lies within
      p.obstruction_encounter_reach of x's body (`st_region_geometry_distance`), or
      asm.sidewalk_section_missing_or_impassable holds.
    s7: now, x occupies a highway region h on which w lies (`st_on_way w h`) and occupies no
      sidewalk; and x has occupied no sidewalk at every observation since the departure
      (`since`, non-strict: the departure observation itself is the one on w).
    s13/s14: the exception (c): x occupies a bicycle lane or path and
      asm.area_beside_bicycle_lane_impassable holds; its negation is conjoined into the applicability.
    s10/s11: for every sidewalk w selected by the whole detour selection above (written again in
      the obligation, so it denotes the same region), x's body is within
      p.pedestrian_detour_side_distance of w (`st_region_geometry_distance x w`).
    s6, s12: residues (the node's).
  No choice beyond the record's wording was needed; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_297_6_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pObstructionEncounterReach : Term := .param "p.obstruction_encounter_reach"
def pPedestrianDetourSideDistance : Term := .param "p.pedestrian_detour_side_distance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- s7: x's footprint overlaps no sidewalk (the sidewalk variable named `v`). -/
def offSidewalks (v : String) : Formula :=
  .forallRegion (.lit "sidewalk") v (.not (.atom "rel_occupies" [vX, .var v] []))

/-- s2/s5: x is moving. -/
def moving : Formula := .derived "drv_motion_moving" [vX] [pMotionSpeedTolerance]

/-- s3/s4/s8: an obstruction within reach of x's body, or the sidewalk section missing or impassable. -/
def encounter : Formula :=
  .or
    (.existsRegion (.lit "obstruction") "o"
      (.cmp (.measure "st_region_geometry_distance" [vX, .var "o"]) .le pObstructionEncounterReach))
    (.asm "asm.sidewalk_section_missing_or_impassable")

/-- The departure observation: x on the sidewalk `w`, moving, at an encountered obstruction. -/
def departsFrom (w : String) : Formula :=
  .and (.atom "rel_occupies" [vX, .var w] []) (.and moving encounter)

/-- s7/s8: x is on its detour from the sidewalk `w`: now on a highway region h that w lies on and on
    no sidewalk, and on no sidewalk at every observation since it left `w` at an obstruction. -/
def detourFrom (w : String) : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "st_on_way" [.var w, .var "h"] [])
      (.and (.atom "rel_occupies" [vX, .var "h"] [])
        (.and (offSidewalks "v")
          (.since (offSidewalks "u") (departsFrom w)))))

/-- s13/s14: exception (c), in a bicycle lane or path where the area beside it is impassable. -/
def inBicycleLaneException : Formula :=
  .and
    (.existsRegion (.lit "bicycle_lane_or_path") "b" (.atom "rel_occupies" [vX, .var "b"] []))
    (.asm "asm.area_beside_bicycle_lane_impassable")

/-- Applicability: s2 (trigger): walking or otherwise traveling on a sidewalk; s3 (trigger): who encounters an obstruction to his or her mobility on the sidewalk,; s4 (trigger): including, without limitation, a short section of the sidewalk that is missing or impassable,; s5 (condition): may proceed; s6 (condition): with due care; s7 (condition): on the immediately adjacent highway; s8 (condition): to move around such an obstruction.; s12 (exception): (b) May walk or otherwise travel on the highway in the direction he or she was walking or traveling on the sidewalk, regardless of the direction of traffic;; s13 (exception): (c) May walk or otherwise travel in a lane provided for bicycles, electric bicycles or electric scooters; s14 (exception): if the area between the lane and the sidewalk is impassable; -/
def applicability : Formula :=
  .and (.existsRegion (.lit "sidewalk") "w" (detourFrom "w")) (.not inBicycleLaneException)

/-- Obligation: s10 (obligation): (a) Must walk or otherwise travel as far to the side of the highway near the sidewalk; s11 (standard): as possible; -/
def obligation : Formula :=
  .forallRegion (.lit "sidewalk") "w"
    (.implies (detourFrom "w")
      (.cmp (.measure "st_region_geometry_distance" [vX, .var "w"]) .le pPedestrianDetourSideDistance))

def rule : Rule :=
  { id := "NRS_484B_297_6_o1"
    laws := ["NRS-484B-297-6"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.sidewalk_section_missing_or_impassable", "asm.area_beside_bicycle_lane_impassable"]
    intentions := []
    operationalizations :=
      [ { standard := "as far to the side of the highway near the sidewalk as possible"
          concepts := ["st.region_geometry"]
          params := ["p.pedestrian_detour_side_distance"]
          convention := "Pedestrian facility design: a detouring pedestrian keeps as close to the sidewalk as possible where its body stays within one pedestrian width plus a shy distance of the sidewalk (st.region_geometry distance)."
          surrogate := false } ]
    residues := ["'With due care' qualifies the permission to leave the sidewalk; the duty to keep to the side applies to such a pedestrian whether or not care was taken, so the words add no restriction to this duty.", "Permission (b) concerns the direction of travel on the highway; the duty to keep to the side near the sidewalk is the same in either direction, so the words add no restriction to this duty."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_297_6_o1
