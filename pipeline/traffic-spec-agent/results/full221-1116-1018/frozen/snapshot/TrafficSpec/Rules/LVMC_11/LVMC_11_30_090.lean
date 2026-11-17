/-
  LVMC_11_30_090 — LVMC-11-30-090

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): Where sidewalks are provided
    s2 (subject): it shall be unlawful for any pedestrian
    s3 (obligation): to walk along and upon an adjacent roadway

  Elements (span → atoms, derived):
    s1: atoms ['st.sidewalk', 'st.on_way', 'st.highway'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s3: atoms ['rel.occupies', 'st.roadway', 'st.lane', 'st.on_way', 'st.highway'], derived ['drv.motion.moving_across_carrier', 'drv.motion.complete_halt']

  How each span is written:
    s2: the binder class `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`, the aggregate id
        as the literal, never expanded into classes.
    s1 + s3 (selection, `roadwayWithSidewalk r h`): the subject occupies a roadway `r`
        (`rel_occupies`, quantifier kind `roadway`), `r` lies on a highway `h` (`st_on_way r h`,
        quantifier kind `highway`), and some sidewalk `w` (quantifier kind `sidewalk`) lies on
        the same `h` (`st_on_way w h`). The applicability is "some such r, h"; the obligation
        re-binds the whole selection and states the duty for every such r, h.
    s3 (duty): compliant where the subject is at rest (`drv_motion_complete_halt` with
        p.halt_speed_tolerance) or is moving across a carrier of r: r itself
        (`drv_motion_moving_across_carrier subject r`) or a lane `c` (quantifier kind `lane`) the
        subject occupies (`rel_occupies`) lying on the same highway (`st_on_way c h`); otherwise
        (moving, and not across any such carrier) it is violated.

  Choice the record left open (declared as a narrowing on s3): the record says "for a lane or
  roadway carrier c of r that it occupies (st.lane on the same highway, or r itself), it is not
  moving across c" without fixing whether crossing one of those carriers suffices or all are
  needed. I read it existentially for compliance: moving across any one occupied carrier
  (the roadway or an occupied lane on the same highway) is crossing, not walking along; the walk
  "along" is violated only where the motion is along every such carrier the source decides.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_30_090

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCrossingMotionCos : Term := .param "p.crossing_motion_cos"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- s1 + s3 selection: the subject occupies roadway `r`, which lies on highway `h`, on which a
    sidewalk also lies. -/
def roadwayWithSidewalk (r h : String) : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var r] [])
    (.and (.atom "st_on_way" [.var r, .var h] [])
      (.existsRegion (.lit "sidewalk") "w" (.atom "st_on_way" [.var "w", .var h] [])))

/-- Applicability: s1 (condition): Where sidewalks are provided — the subject is upon a roadway
    lying on a highway on which a sidewalk lies. -/
def applicability : Formula :=
  .existsRegion (.lit "roadway") "r"
    (.existsRegion (.lit "highway") "h" (roadwayWithSidewalk "r" "h"))

/-- At rest. -/
def atRest : Formula :=
  .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- Moving across carrier `c`. -/
def acrossCarrier (c : String) : Formula :=
  .derived "drv_motion_moving_across_carrier" [vSubject, .var c] [pHaltSpeedTolerance, pCrossingMotionCos]

/-- Not walking along roadway `r` (on highway `h`): at rest, or moving across r itself or across
    an occupied lane lying on the same highway. -/
def notWalkingAlong (r h : String) : Formula :=
  .or atRest
    (.or (acrossCarrier r)
      (.existsRegion (.lit "lane") "c"
        (.and (.atom "rel_occupies" [vSubject, .var "c"] [])
          (.and (.atom "st_on_way" [.var "c", .var h] []) (acrossCarrier "c")))))

/-- Obligation: s3 (obligation): to walk along and upon an adjacent roadway — prohibited for
    every selected roadway. -/
def obligation : Formula :=
  .forallRegion (.lit "roadway") "r"
    (.forallRegion (.lit "highway") "h"
      (.implies (roadwayWithSidewalk "r" "h") (notWalkingAlong "r" "h")))

def rule : Rule :=
  { id := "LVMC_11_30_090"
    laws := ["LVMC-11-30-090"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s3"
          why := "The carriers of r (r itself, or an occupied st.lane on the same highway) are read existentially for compliance: moving across any one of them (drv.motion.moving_across_carrier) is crossing, not walking along; a moving pedestrian violates only where its motion is along every such carrier."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_30_090
