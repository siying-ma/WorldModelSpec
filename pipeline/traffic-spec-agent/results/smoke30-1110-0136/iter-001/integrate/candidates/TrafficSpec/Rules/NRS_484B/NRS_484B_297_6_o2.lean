/-
  NRS_484B_297_6_o2 — NRS-484B-297-6

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
    s10 (sibling): (a) Must walk or otherwise travel as far to the side of the highway near the sidewalk as possible; (b) May walk or otherwise travel on the highway in the direction he or she was walking or traveling on the sidewalk, regardless of the direction of traffic; (c) May walk or otherwise travel in a lane provided for bicycles, electric bicycles or electric scooters if the area between the lane and the sidewalk is impassable;
    s11 (obligation): and (d) Must return to the sidewalk
    s12 (standard): as soon as practicable.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s2: atoms ['rel.occupies', 'st.sidewalk'], derived ['drv.motion.moving']
    s3: atoms ['st.obstruction', 'st.region_geometry', 'rel.occupies', 'st.sidewalk'], derived []
    s5: atoms [], derived ['drv.motion.moving']
    s7: atoms ['rel.occupies', 'st.highway', 'st.on_way', 'st.sidewalk'], derived []
    s8: atoms ['st.obstruction', 'st.region_geometry'], derived []
    s9: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s11: atoms ['rel.occupies', 'st.sidewalk'], derived []

  How each is written:
    s1, s9: `ru_aggregate x "DEF-NRS-484A-165::pedestrian"` (the binder class).
    s2: at the observation x leaves the sidewalk, `drv_motion_moving x` with
        p.motion_speed_tolerance and `rel_occupies x w` for a sidewalk `w`.
    s3, s8: an obstruction `o` with `st_region_geometry_distance x o ≤ p.obstruction_encounter_reach`
        at that observation (s8's purpose read through the conduct, the record's narrowing).
    s4: the declared assumption asm.sidewalk_section_missing_or_impassable, the alternative to s3.
    s5, s7: `rel_occupies x h` for a highway `h` and no sidewalk occupied now, and off every sidewalk
        continuously `since` the encounter on a sidewalk `w` with `st_on_way w h`.
    s6: residue (the node's).
    s11, s12: the obligation is `not (holdsFor .time p.sidewalk_return_time x (off every sidewalk and
        st_region_geometry_distance > p.obstruction_encounter_reach for every obstruction))`; a window
        reaching before the recording is unknown (Core's truncation).
  No choice beyond the record's applicability and obligation text was needed: no narrowing declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_297_6_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pObstructionEncounterReach : Term := .param "p.obstruction_encounter_reach"
def pSidewalkReturnTime : Term := .param "p.sidewalk_return_time"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- s2, s3, s11: x's footprint overlaps sidewalk region `w` (rel.occupies). -/
def onSidewalk (w : String) : Formula := .atom "rel_occupies" [vX, .var w] []

/-- s7, s11, s12: x's footprint overlaps no sidewalk (st.sidewalk, rel.occupies). -/
def offEverySidewalk (w : String) : Formula :=
  .forallRegion (.lit "sidewalk") w (.not (onSidewalk w))

/-- s3, s8: x's body within the encounter reach of obstruction `o` (st.region_geometry). -/
def atObstruction (o : String) : Formula :=
  .cmp (.measure "st_region_geometry_distance" [vX, .var o]) .le pObstructionEncounterReach

/-- s2–s4 at the observation x leaves the sidewalk: moving (drv.motion.moving) on a sidewalk `w`
    lying on highway `h` (st.on_way), with an obstruction within the encounter reach of its body or
    the declared missing or impassable section. -/
def encounter (h : String) : Formula :=
  .existsRegion (.lit "sidewalk") "w"
    (.and (onSidewalk "w")
      (.and (.atom "st_on_way" [.var "w", .var h] [])
        (.and (.derived "drv_motion_moving" [vX] [pMotionSpeedTolerance])
          (.or (.existsRegion (.lit "obstruction") "o" (atObstruction "o"))
               (.asm "asm.sidewalk_section_missing_or_impassable")))))

/-- Applicability: s2 (trigger): walking or otherwise traveling on a sidewalk; s3 (trigger): who encounters an obstruction to his or her mobility on the sidewalk,; s4 (trigger): including, without limitation, a short section of the sidewalk that is missing or impassable,; s5 (condition): may proceed; s6 (condition): with due care; s7 (condition): on the immediately adjacent highway; s8 (condition): to move around such an obstruction.
    x's footprint overlaps a highway `h` and no sidewalk now, and x has been off every sidewalk
    continuously since an encounter on a sidewalk lying on `h`. -/
def applicability : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "rel_occupies" [vX, .var "h"] [])
      (.and (offEverySidewalk "w0")
        (.since (offEverySidewalk "w1") (encounter "h"))))

/-- s12: clear of the obstruction — x's body farther than the encounter reach from every
    obstruction (st.region_geometry). -/
def clearOfObstructions : Formula :=
  .forallRegion (.lit "obstruction") "o"
    (.cmp (.measure "st_region_geometry_distance" [vX, .var "o"]) .gt pObstructionEncounterReach)

/-- Obligation: s11 (obligation): and (d) Must return to the sidewalk; s12 (standard): as soon as practicable.
    Not: off every sidewalk and clear of every obstruction at every observation of the
    p.sidewalk_return_time window behind (kin.time). -/
def obligation : Formula :=
  .not (.holdsFor .time pSidewalkReturnTime "x"
    (.and (offEverySidewalk "w2") clearOfObstructions))

def rule : Rule :=
  { id := "NRS_484B_297_6_o2"
    laws := ["NRS-484B-297-6"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.sidewalk_section_missing_or_impassable"]
    intentions := []
    operationalizations :=
      [ { standard := "as soon as practicable"
          concepts := ["kin.time", "rel.occupies", "st.obstruction", "st.region_geometry", "st.sidewalk"]
          params := ["p.sidewalk_return_time", "p.obstruction_encounter_reach"]
          convention := "Walking-time convention: once clear of the obstruction (farther than the encounter reach from every obstruction, st.region_geometry), a pedestrian can step back onto the sidewalk within the time needed to walk a few metres at the design walking speed; staying off the sidewalk (rel.occupies of st.sidewalk false) and clear of every obstruction for longer than that time (a .time window, kin.time) is not as soon as practicable."
          surrogate := false } ]
    residues := ["'With due care' qualifies the permission to leave the sidewalk; the duty to return applies to such a pedestrian whether or not care was taken, so the words add no restriction to this duty."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_297_6_o2
