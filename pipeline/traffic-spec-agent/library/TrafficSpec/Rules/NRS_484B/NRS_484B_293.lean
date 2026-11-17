/-
  NRS_484B_293 — NRS-484B-293

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Pedestrians
    s2 (condition): shall move
    s3 (standard): whenever practicable
    s4 (obligation): upon the right half of crosswalks.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s2: atoms [], derived ['drv.motion.complete_halt']
    s4: atoms ['rel.occupies', 'st.crosswalk', 'st.region_geometry', 'kin.position', 'kin.velocity', 'kin.speed'], derived []

  How each span is written:
    s1: the binder class is `ru_aggregate` with the admitted id DEF-NRS-484A-165::pedestrian.
    s2: applicability conjoins `not (drv_motion_complete_halt subject [p.halt_speed_tolerance])`.
    s4: applicability selects a crosswalk by `existsRegion crosswalk cw (rel_occupies subject cw)`;
        the obligation re-binds the same selection with `forallRegion crosswalk cw (rel_occupies
        subject cw → …)`, so the duty holds at every crosswalk the subject occupies. The right half
        is the record's cross-product test over kin.velocity, kin.position, st.region_geometry's
        reference point and kin.speed, against −p.pedestrian_lateral_tolerance · speed.
    s3: the operationalization's two limbs, as a disjunction with the right-half test: another road
        user (not the subject) occupying cw, ahead (rel_bearing "ahead": longitudinal > 0) and on
        the right (rel_bearing "right": lateral < 0), at a rel_surface_gap at or below
        p.pedestrian_near_reach; or an obstruction region with prim_region_lateral_offset below
        zero and st_region_geometry_distance at or below p.pedestrian_near_reach.
  No choice beyond the record's own narrowings was needed: `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_293

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pPedestrianLateralTolerance : Term := .param "p.pedestrian_lateral_tolerance"
def pPedestrianNearReach : Term := .param "p.pedestrian_near_reach"

def zeroMetres : Term := .lit Q.zero .metre

/-- The crosswalk variable (bound by a region quantifier of kind `crosswalk` in each formula), the
    other road user and the obstruction of the practicability standard. -/
def vCw : Arg := .var "cw"
def vOther : Arg := .var "other"
def vObs : Arg := .var "obs"

/-- s1: the subject is a member of the admitted aggregate DEF-NRS-484A-165::pedestrian. -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- s4 (selection): the subject's footprint overlaps crosswalk `cw` (rel.occupies). -/
def occupiesCw : Formula := .atom "rel_occupies" [vSubject, vCw] []

/-- s2: the subject moves — drv.motion.complete_halt with p.halt_speed_tolerance does not hold. -/
def moves : Formula := .not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])

/-- Applicability: the subject occupies some crosswalk and moves. -/
def applicability : Formula :=
  .and (.existsRegion (.lit "crosswalk") "cw" occupiesCw) moves

/-- s4: the subject moves on the right half of `cw`: with v its velocity, p its position and r the
    crosswalk's reference point, v_x (r_y − p_y) − v_y (r_x − p_x) ≥ −(lateral tolerance · speed),
    i.e. r does not lie to the right of the direction of movement by more than the tolerance. -/
def onRightHalf : Formula :=
  let vx : Term := .measure "kin_velocity" [vSubject, .lit "x"]
  let vy : Term := .measure "kin_velocity" [vSubject, .lit "y"]
  let px : Term := .measure "kin_position" [vSubject, .lit "x"]
  let py : Term := .measure "kin_position" [vSubject, .lit "y"]
  let rx : Term := .measure "st_region_geometry" [vCw, .lit "x"]
  let ry : Term := .measure "st_region_geometry" [vCw, .lit "y"]
  let speed : Term := .measure "kin_speed" [vSubject]
  .cmp (.sub (.mul vx (.sub ry py)) (.mul vy (.sub rx px))) .ge
       (.neg (.mul pPedestrianLateralTolerance speed))

/-- s3, first limb: another road user occupying `cw` lies ahead of the subject on its right
    (rel.bearing longitudinal > 0, lateral < 0) at a surface gap at or below the near reach. -/
def otherUserAheadRight : Formula :=
  .existsUser "other"
    (.and (.not (.same vOther vSubject))
      (.and (.atom "rel_occupies" [vOther, vCw] [])
        (.and (.atom "rel_bearing" [vSubject, vOther, .lit "ahead"] [])
          (.and (.atom "rel_bearing" [vSubject, vOther, .lit "right"] [])
            (.cmp (.measure "rel_surface_gap" [vSubject, vOther]) .le pPedestrianNearReach)))))

/-- s3, second limb: an obstruction lies on the subject's right (prim.region_lateral_offset below
    zero) at a ground distance (st.region_geometry) at or below the near reach. -/
def obstructionRight : Formula :=
  .existsRegion (.lit "obstruction") "obs"
    (.and (.cmp (.quantity "prim_region_lateral_offset" [vSubject, vObs] []) .lt zeroMetres)
      (.cmp (.measure "st_region_geometry_distance" [vSubject, vObs]) .le pPedestrianNearReach))

/-- Obligation: for every crosswalk the subject occupies (the applicability's selection again), it
    moves on the right half, or keeping to the right half is not practicable. -/
def obligation : Formula :=
  .forallRegion (.lit "crosswalk") "cw"
    (.implies occupiesCw
      (.or onRightHalf (.or otherUserAheadRight obstructionRight)))

def rule : Rule :=
  { id := "NRS_484B_293"
    laws := ["NRS-484B-293"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "whenever practicable"
          concepts := ["prim.region_lateral_offset", "rel.bearing", "rel.occupies", "rel.surface_gap", "st.obstruction", "st.region_geometry"]
          params := ["p.pedestrian_near_reach"]
          convention := "pedestrian stride and shy distance: keeping to the right half is impracticable where the right half ahead of the pedestrian is taken up within about two strides, by another road user occupying the same crosswalk ahead on its right (rel.bearing: positive longitudinal and negative lateral component; rel.surface_gap at or below the reach) or by an obstruction on its right (prim.region_lateral_offset below zero; st.region_geometry distance at or below the reach)"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_293
