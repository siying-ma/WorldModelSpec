/-
  NRS_484B_297_6_o1 — NRS-484B-297-6

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A pedestrian
    s2 (condition): walking or otherwise traveling on a sidewalk
    s3 (condition): who encounters an obstruction to his or her mobility on the sidewalk,
    s4 (condition): including, without limitation, a short section of the sidewalk that is missing or impassable,
    s5 (obligation): may proceed
    s6 (standard): with due care
    s7 (condition): on the immediately adjacent highway to move around such an obstruction.
    s8 (subject): Such a pedestrian:
    s9 (sibling): (a) Must walk or otherwise travel as far to the side of the highway near the sidewalk
    s10 (sibling): as possible;
    s11 (condition): (b) May walk or otherwise travel on the highway in the direction he or she was walking or traveling on the sidewalk, regardless of the direction of traffic;
    s12 (sibling): (c) May walk or otherwise travel in a lane provided for bicycles, electric bicycles or electric scooters
    s13 (sibling): if the area between the lane and the sidewalk is impassable;
    s14 (boilerplate): and
    s15 (sibling): (d) Must return to the sidewalk
    s16 (sibling): as soon as practicable.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s2: atoms ['rel.occupies', 'st.sidewalk', 'kin.speed'], derived ['drv.motion.moving']
    s3: atoms ['st.obstruction', 'st.region_geometry'], derived []
    s4: atoms ['st.obstruction', 'st.sidewalk', 'st.region_geometry'], derived []
    s5: atoms ['rel.occupies', 'st.highway', 'st.sidewalk', 'st.on_way'], derived ['drv.motion.moving']
    s7: atoms ['rel.occupies', 'st.highway', 'st.sidewalk', 'st.on_way'], derived []
    s8: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []

  How each is written:
    s1/s8: binder class `ru_aggregate x "DEF-NRS-484A-165::pedestrian"`.
    s2: `rel_occupies x w` for a sidewalk `w`, with drv.motion.moving at p.speed_resolution.
    s3: some obstruction `o` with `st_region_geometry_distance x o ≤ p.obstruction_encounter_reach`,
        at the same observation at which s2 holds.
    s4: the record carries a gap: a missing or impassable section of sidewalk is no object, and
        st.obstruction ('a physical object … that is not a road user') does not carry it; s3's
        formula covers only the blocked-by-an-object case. Declared `no_atom` below.
    s5/s7: a highway `h` with `st_on_way w h`; `x` occupies `h` and no sidewalk now, and has done
        so at every observation since one at which s2–s3 held (`since`), the record's
        observable reading of 'to move around such an obstruction'.
    s6: where `x` moves, for every road user `z` other than `x`, not both
        prim.closest_approach_within x z p.immediate_hazard_gap and
        prim.closest_approach_distance x z p.immediate_hazard_gap < p.conflict_clearance.
    s11: residue (the node's).
  Choices: the "on no sidewalk" clause ranges over every sidewalk of the scene, as the record says
  ('no sidewalk'); "since" is the past strong since, so the onset at the sidewalk must be recorded.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_297_6_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictClearance : Term := .param "p.conflict_clearance"
def pImmediateHazardGap : Term := .param "p.immediate_hazard_gap"
def pObstructionEncounterReach : Term := .param "p.obstruction_encounter_reach"
def pSpeedResolution : Term := .param "p.speed_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- drv.motion.moving of `x`, at the source's speed resolution (s2, s5). -/
def moving : Formula := .derived "drv_motion_moving" [vX] [pSpeedResolution]

/-- s3/s4: an obstruction `o` within the encounter reach of `x`'s body. -/
def encountersObstruction : Formula :=
  .existsRegion (.lit "obstruction") "o"
    (.cmp (.measure "st_region_geometry_distance" [vX, .var "o"]) .le pObstructionEncounterReach)

/-- s2–s4: `x` on sidewalk `w`, moving, at an obstruction. -/
def atObstructionOnSidewalk : Formula :=
  .and (.atom "rel_occupies" [vX, .var "w"] [])
    (.and moving encountersObstruction)

/-- s7: `x` on highway `h` and on no sidewalk. -/
def offSidewalkOnHighway : Formula :=
  .and (.atom "rel_occupies" [vX, .var "h"] [])
    (.forallRegion (.lit "sidewalk") "s" (.not (.atom "rel_occupies" [vX, .var "s"] [])))

/-- Applicability: for a sidewalk `w` lying on a highway `h`, `x` is on `h` and on no sidewalk
    now, and has been at every observation since one at which it was on `w`, moving, within the
    encounter reach of an obstruction (s2, s3, s4, s7). -/
def applicability : Formula :=
  .existsRegion (.lit "sidewalk") "w"
    (.existsRegion (.lit "highway") "h"
      (.and (.atom "st_on_way" [.var "w", .var "h"] [])
        (.and offSidewalkOnHighway
          (.since offSidewalkOnHighway atObstructionOnSidewalk))))

/-- s6: road user `z` in predicted conflict with `x`: closest approach within the hazard gap,
    at a centre distance below the conflict clearance. -/
def predictedConflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, .var "z"] [pImmediateHazardGap])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, .var "z"] [pImmediateHazardGap])
      .lt pConflictClearance)

/-- Obligation: where `x` proceeds (moves), no other road user is in predicted conflict with it
    (s5, s6). -/
def obligation : Formula :=
  .implies moving
    (.forallUser "z" (.implies (.not (.same (.var "z") vX)) (.not predictedConflict)))

def rule : Rule :=
  { id := "NRS_484B_297_6_o1"
    laws := ["NRS-484B-297-6"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "due care"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.immediate_hazard_gap", "p.conflict_clearance"]
          convention := "Surrogate safety conflict (FHWA SSAM): while proceeding on the highway, the pedestrian creates no predicted conflict: no other road user's centre is predicted, under constant velocities, to come within p.conflict_clearance of the pedestrian's within p.immediate_hazard_gap. Due care is a standard of care, so the reading is a surrogate."
          surrogate := true } ]
    residues := ["A permission to travel against the direction of traffic; no duty of this node concerns the pedestrian's direction, so the duty is the same whichever way the pedestrian walks."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s4"
          why := "'a short section of the sidewalk that is missing or impassable' is no physical object: st.obstruction ('a physical object on or beside the roadway that is not a road user') covers a section blocked by an object only, and no atom of the surface denotes a missing or untraversable stretch of sidewalk; the record's gap (st.impassable_section) stands."
          kind := "no_atom" } ]
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_297_6_o1
