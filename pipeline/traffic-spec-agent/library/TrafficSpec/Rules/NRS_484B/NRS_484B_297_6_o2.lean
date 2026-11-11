/-
  NRS_484B_297_6_o2 — NRS-484B-297-6

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A pedestrian
    s2 (condition): walking or otherwise traveling on a sidewalk
    s3 (condition): who encounters an obstruction to his or her mobility on the sidewalk,
    s4 (condition): including, without limitation, a short section of the sidewalk that is missing or impassable,
    s5 (condition): may proceed
    s6 (sibling): with due care
    s7 (condition): on the immediately adjacent highway to move around such an obstruction.
    s8 (subject): Such a pedestrian:
    s9 (obligation): (a) Must walk or otherwise travel as far to the side of the highway near the sidewalk
    s10 (standard): as possible;
    s11 (condition): (b) May walk or otherwise travel on the highway in the direction he or she was walking or traveling on the sidewalk, regardless of the direction of traffic;
    s12 (exception): (c) May walk or otherwise travel in a lane provided for bicycles, electric bicycles or electric scooters
    s13 (exception): if the area between the lane and the sidewalk is impassable;
    s14 (boilerplate): and
    s15 (sibling): (d) Must return to the sidewalk
    s16 (sibling): as soon as practicable.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s2: atoms ['rel.occupies', 'st.sidewalk', 'kin.speed'], derived ['drv.motion.moving']
    s3: atoms ['st.obstruction', 'st.region_geometry'], derived []
    s4: atoms ['st.obstruction', 'st.sidewalk', 'st.region_geometry'], derived []
    s5: atoms ['rel.occupies', 'st.highway', 'st.sidewalk', 'st.on_way'], derived []
    s7: atoms ['rel.occupies', 'st.highway', 'st.sidewalk', 'st.on_way'], derived []
    s8: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s9: atoms ['st.region_geometry', 'st.sidewalk', 'rel.occupies', 'st.highway'], derived []
    s12: atoms ['st.bicycle_lane_or_path', 'rel.occupies'], derived []
    s13: atoms ['st.obstruction', 'st.region_geometry'], derived []

  How each is written:
    s1, s8: the binder class, `ru_aggregate x "DEF-NRS-484A-165::pedestrian"`.
    s2, s3, s4: the moment x left the sidewalk at the obstruction (`leftAtObstruction w`): x occupies
      the sidewalk w (`rel_occupies`, w ranging over `sidewalk`), is moving (`drv_motion_moving`
      with p.speed_resolution, reading kin.speed) and some region of kind `obstruction` lies within
      p.obstruction_encounter_reach of x's body (`st_region_geometry_distance`). The missing or
      impassable section is read through the same obstruction (the record's gap).
    s5, s7: x occupies a highway h (`rel_occupies`, h ranging over `highway`) on which w lies
      (`st_on_way w h`) and no sidewalk (`forallRegion sidewalk`, not `rel_occupies`), now and at
      every observation since the moment of s2–s4 (`since`); the plan's observable reading of
      'to move around such an obstruction'.
    s12, s13 (exception (c)): x occupies a region of kind `bicycle_lane_or_path` while some
      obstruction lies within p.obstruction_encounter_reach of x's body; the applicability holds
      only where this does not.
    s9, s10: for every sidewalk w and highway h of that same selection (re-stated whole in the
      obligation), x's body lies within p.pedestrian_detour_offset of w (`st_region_geometry_distance`).
    s11: the record's residue; s6, s15, s16 are siblings, not this node's.

  No choice beyond the record's own was made: no narrowing of this file's own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_297_6_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pObstructionEncounterReach : Term := .param "p.obstruction_encounter_reach"
def pPedestrianDetourOffset : Term := .param "p.pedestrian_detour_offset"
def pSpeedResolution : Term := .param "p.speed_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- s3, s4, s13: some obstruction (bound as `o`) lies within the encounter reach of x's body. -/
def obstructionWithinReach (o : String) : Formula :=
  .existsRegion (.lit "obstruction") o
    (.cmp (.measure "st_region_geometry_distance" [vX, .var o]) .le pObstructionEncounterReach)

/-- s5, s7: x occupies the highway `h` and no sidewalk. -/
def onHighwayOffSidewalk : Formula :=
  .and (.atom "rel_occupies" [vX, .var "h"] [])
    (.forallRegion (.lit "sidewalk") "s" (.not (.atom "rel_occupies" [vX, .var "s"] [])))

/-- s2–s4: x on the sidewalk `w`, moving, with an obstruction within the encounter reach. -/
def leftAtObstruction : Formula :=
  .and (.atom "rel_occupies" [vX, .var "w"] [])
    (.and (.derived "drv_motion_moving" [vX] [pSpeedResolution]) (obstructionWithinReach "o"))

/-- s5, s7: the selection of the sidewalk `w` and the highway `h` it lies on: x on `h` off every
    sidewalk now and at every observation since it left `w` at an obstruction. -/
def detour : Formula :=
  .and (.atom "st_on_way" [.var "w", .var "h"] [])
    (.and onHighwayOffSidewalk (.since onHighwayOffSidewalk leftAtObstruction))

/-- s12, s13 (exception (c)): x in a bicycle lane or path with an obstruction within the reach. -/
def inBicycleLaneBesideImpassable : Formula :=
  .existsRegion (.lit "bicycle_lane_or_path") "b"
    (.and (.atom "rel_occupies" [vX, .var "b"] []) (obstructionWithinReach "q"))

/-- Applicability: s2 (condition): walking or otherwise traveling on a sidewalk; s3 (condition): who encounters an obstruction to his or her mobility on the sidewalk,; s4 (condition): including, without limitation, a short section of the sidewalk that is missing or impassable,; s5 (condition): may proceed; s7 (condition): on the immediately adjacent highway to move around such an obstruction.; s11 (condition): (b) May walk or otherwise travel on the highway in the direction he or she was walking or traveling on the sidewalk, regardless of the direction of traffic;; s12 (exception): (c) May walk or otherwise travel in a lane provided for bicycles, electric bicycles or electric scooters; s13 (exception): if the area between the lane and the sidewalk is impassable; -/
def applicability : Formula :=
  .and (.existsRegion (.lit "sidewalk") "w" (.existsRegion (.lit "highway") "h" detour))
    (.not inBicycleLaneBesideImpassable)

/-- Obligation: s9 (obligation): (a) Must walk or otherwise travel as far to the side of the highway near the sidewalk; s10 (standard): as possible; -/
def obligation : Formula :=
  .forallRegion (.lit "sidewalk") "w" (.forallRegion (.lit "highway") "h"
    (.implies detour
      (.cmp (.measure "st_region_geometry_distance" [vX, .var "w"]) .le pPedestrianDetourOffset)))

def rule : Rule :=
  { id := "NRS_484B_297_6_o2"
    laws := ["NRS-484B-297-6"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "as far to the side as possible"
          concepts := ["st.region_geometry"]
          params := ["p.pedestrian_detour_offset"]
          convention := "Pedestrian detour width (HCM pedestrian space plus shy distance): the pedestrian's body stays within p.pedestrian_detour_offset of the sidewalk it left (st.region_geometry distance), one pedestrian width beside the sidewalk edge."
          surrogate := false } ]
    residues := ["A permission to travel against the direction of traffic; the duty to keep to the side near the sidewalk is the same whichever way the pedestrian walks."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_297_6_o2
