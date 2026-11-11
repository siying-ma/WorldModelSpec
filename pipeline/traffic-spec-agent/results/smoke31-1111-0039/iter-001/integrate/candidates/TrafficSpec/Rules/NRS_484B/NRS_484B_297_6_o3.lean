/-
  NRS_484B_297_6_o3 — NRS-484B-297-6

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
    s9 (sibling): (a) Must walk or otherwise travel as far to the side of the highway near the sidewalk
    s10 (sibling): as possible;
    s11 (condition): (b) May walk or otherwise travel on the highway in the direction he or she was walking or traveling on the sidewalk, regardless of the direction of traffic;
    s12 (sibling): (c) May walk or otherwise travel in a lane provided for bicycles, electric bicycles or electric scooters
    s13 (sibling): if the area between the lane and the sidewalk is impassable;
    s14 (boilerplate): and
    s15 (obligation): (d) Must return to the sidewalk
    s16 (standard): as soon as practicable.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s2: atoms ['rel.occupies', 'st.sidewalk', 'kin.speed'], derived ['drv.motion.moving']
    s3: atoms ['st.obstruction', 'st.region_geometry'], derived []
    s4: atoms ['st.obstruction', 'st.sidewalk', 'st.region_geometry'], derived []
    s5: atoms ['rel.occupies', 'st.highway', 'st.sidewalk', 'st.on_way'], derived []
    s7: atoms ['rel.occupies', 'st.highway', 'st.sidewalk', 'st.on_way'], derived []
    s8: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s15: atoms ['rel.occupies', 'st.sidewalk'], derived []

  How they are written:
    s1/s8: `ru_aggregate x "DEF-NRS-484A-165::pedestrian"`.
    s2: at an earlier observation, `rel_occupies x w` for a sidewalk w, and
        `drv_motion_moving x` at p.speed_resolution.
    s3/s4: at that same observation, some `obstruction` region o with
        `st_region_geometry_distance x o ≤ p.obstruction_encounter_reach`.
    s5/s7: w lies on a highway h (`st_on_way w h`); x occupies h and no sidewalk now and at every
        observation since that encounter (`since`, the past mirror of strong until).
    s16 (applicability side): now every obstruction is farther than p.obstruction_encounter_reach.
    s15/s16 (obligation): `within .time p.sidewalk_return_time` ahead, x occupies some sidewalk.
  Choices: none beyond the record's; the returned-to sidewalk is any sidewalk, as the record's
  obligation states (w2 of kind st.sidewalk).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_297_6_o3

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pObstructionEncounterReach : Term := .param "p.obstruction_encounter_reach"
def pSidewalkReturnTime : Term := .param "p.sidewalk_return_time"
def pSpeedResolution : Term := .param "p.speed_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- `x` occupies a region `r`. -/
def occupies (r : String) : Formula := .atom "rel_occupies" [vX, .var r] []

/-- s5/s7: `x` is on the highway `h` and on no sidewalk. -/
def onHighwayOffSidewalk : Formula :=
  .and (occupies "h")
    (.forallRegion (.lit "sidewalk") "v" (.not (occupies "v")))

/-- s3/s4: some obstruction lies within the encounter reach of `x`. -/
def obstructionWithinReach : Formula :=
  .existsRegion (.lit "obstruction") "o"
    (.cmp (.measure "st_region_geometry_distance" [vX, .var "o"]) .le pObstructionEncounterReach)

/-- s2–s4: `x` on the sidewalk `w`, moving, with an obstruction within reach. -/
def encounterOnSidewalk : Formula :=
  .and (occupies "w")
    (.and (.derived "drv_motion_moving" [vX] [pSpeedResolution]) obstructionWithinReach)

/-- s16: no obstruction lies within the encounter reach of `x` (it has been passed). -/
def obstructionPassed : Formula :=
  .forallRegion (.lit "obstruction") "o2"
    (.cmp (.measure "st_region_geometry_distance" [vX, .var "o2"]) .gt pObstructionEncounterReach)

/-- Applicability: s2 (condition): walking or otherwise traveling on a sidewalk; s3 (condition): who encounters an obstruction to his or her mobility on the sidewalk,; s4 (condition): including, without limitation, a short section of the sidewalk that is missing or impassable,; s5 (condition): may proceed; s7 (condition): on the immediately adjacent highway to move around such an obstruction.; s11 (condition): (b) May walk or otherwise travel on the highway in the direction he or she was walking or traveling on the sidewalk, regardless of the direction of traffic; -/
def applicability : Formula :=
  .and
    (.existsRegion (.lit "sidewalk") "w"
      (.existsRegion (.lit "highway") "h"
        (.and (.atom "st_on_way" [.var "w", .var "h"] [])
          (.and onHighwayOffSidewalk
            (.since onHighwayOffSidewalk encounterOnSidewalk)))))
    obstructionPassed

/-- Obligation: s15 (obligation): (d) Must return to the sidewalk; s16 (standard): as soon as practicable. -/
def obligation : Formula :=
  .within .time pSidewalkReturnTime "x"
    (.existsRegion (.lit "sidewalk") "w2" (occupies "w2"))

def rule : Rule :=
  { id := "NRS_484B_297_6_o3"
    laws := ["NRS-484B-297-6"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "as soon as practicable"
          concepts := ["st.obstruction", "st.region_geometry"]
          params := ["p.obstruction_encounter_reach", "p.sidewalk_return_time"]
          convention := "Return time (a few steps at the HCM design walking speed): once no obstruction lies within p.obstruction_encounter_reach of the pedestrian (st.region_geometry distance to every st.obstruction), the return to the sidewalk is made within p.sidewalk_return_time."
          surrogate := false } ]
    residues := ["A permission to travel against the direction of traffic; the duty to return to the sidewalk is the same whichever way the pedestrian walks."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_297_6_o3
