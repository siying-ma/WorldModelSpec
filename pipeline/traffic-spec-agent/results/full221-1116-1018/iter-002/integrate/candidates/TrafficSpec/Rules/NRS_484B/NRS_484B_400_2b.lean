/-
  NRS_484B_400_2b — NRS-484B-400-2b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): If the driver of a vehicle
    s2 (trigger): intends to turn
    s3 (trigger): at an intersection and:
    s4 (condition): Both intersecting highways are two-directional:
    s5 (obligation): After entering the intersection, the left turn must be made so as to leave the intersection to the right of the centerline of the highway being entered.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['st.intersection', 'rel.occupies'], derived []
    s4: atoms ['st.highway', 'st.on_way', 'st.intersection', 'st.median_or_divider', 'st.lane', 'st.roadway', 'st.lane_direction'], derived []
    s5: atoms ['rel.occupies', 'st.lane', 'st.intersection'], derived ['drv.motion.left_turn_through_region', 'drv.motion.moving_against_carrier']

  How each span is written.
    s1: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"` (the binder class).
    s3 + occasion: an intersection `i` (quantifier over kind `intersection`) at which
        `drv_motion_left_turn_through_region(subject, i)` holds: the concept holds only at the
        exit after the entry, so the judged observation is the act's recognition (event boundary).
        s3 and s4 are read at that recognition.
    s2: `int.left_turn(subject, i)` declared true at some observation while the act is under way,
        read behind the judged observation with `since`: ψ = the intention together with the
        under-way formula U, φ = no new entry into i (`not (rises (rel_occupies subject i))`), so
        the search into the past ends at the entry of this passage and never reaches an earlier
        passage or the approach. U is the occasion's under_way element from its atoms: the subject
        overlaps i (rel.occupies) and its heading change since its entry into i, integrated from
        kin.yaw_rate (`headingSince` with the reviewed step parameter, ψ = rel_occupies subject i,
        so the onset is the entry), is not to the right (≥ 0): an observation inside the left turn,
        as against one on the approach (where no entry has been observed). The sign is the choice
        this file makes for the record's "moving through it and turning".
    s4: every highway h that i lies on (`st_on_way i h`) is two-directional: no median_or_divider
        lies on h, and two carriers lying on h (a lane or a roadway segment each) carry designated
        directions whose normalised dot product is at or below minus p.lane_opposed_direction_cos.
        The pairs are written unordered (lane–lane, lane–roadway, roadway–roadway), the dot
        product being symmetric.
    s5: at the recognition, every lane l the subject overlaps carries no designated direction its
        motion runs against: `not drv_motion_moving_against_carrier(subject, l; p.halt_speed_tolerance)`
        (the record's own reading of "to the right of the centerline"). The obligation names no
        intersection: the lanes it reads are those the subject overlaps at the judged observation.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_400_2b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pLaneOpposedDirectionCos : Term := .param "p.lane_opposed_direction_cos"
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"

def zeroMetres : Term := .lit Q.zero .metre
def zeroDegrees : Term := .lit Q.zero .degree

def vI : Arg := .var "i"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The subject's footprint overlaps the intersection `i`. -/
def occI : Formula := .atom "rel_occupies" [vSubject, vI] []

/-- The left turn through `i`, recognized at the exit (the occasion). -/
def leftTurnThroughI : Formula :=
  .derived "drv_motion_left_turn_through_region" [vSubject, vI]
    [pHeadingSinceStepCarlaSceneGraph, pTurnHeadingMin, pUTurnHeadingMin]

/-- Under way (occasion): inside i, the heading change since the entry not to the right. -/
def underWay : Formula :=
  .and occI
    (.cmp (.headingSince "subject" pHeadingSinceStepCarlaSceneGraph occI) .ge zeroDegrees)

/-- s2: int.left_turn(subject, i) declared at some observation of the act stretch, from the entry
    of this passage up to the judged observation. -/
def intendedDuringAct : Formula :=
  .since (.not (.rises occI)) (.and (.intent "int.left_turn" vSubject vI) underWay)

/-- Carrier `c` lies on highway `h`. -/
def onH (c : String) : Formula := .atom "st_on_way" [.var c, .var "h"] []

/-- The designated directions of carriers `a` and `b` are opposed. -/
def opposed (a b : String) : Formula :=
  .cmp (.add (.mul (.measure "st_lane_direction" [.var a, .lit "x"]) (.measure "st_lane_direction" [.var b, .lit "x"]))
             (.mul (.measure "st_lane_direction" [.var a, .lit "y"]) (.measure "st_lane_direction" [.var b, .lit "y"])))
    .le (.neg pLaneOpposedDirectionCos)

/-- Two carriers of kinds `k1`, `k2` lying on h with opposed designated directions. -/
def opposedPair (k1 k2 : String) : Formula :=
  .existsRegion (.lit k1) "c1" (.and (onH "c1")
    (.existsRegion (.lit k2) "c2" (.and (onH "c2") (opposed "c1" "c2"))))

/-- s4: h is two-directional: undivided, and traffic allowed in opposite directions. -/
def twoDirectional : Formula :=
  .and (.not (.existsRegion (.lit "median_or_divider") "d" (onH "d")))
    (.or (opposedPair "lane" "lane") (.or (opposedPair "lane" "roadway") (opposedPair "roadway" "roadway")))

/-- s4: both (every) intersecting highways of i are two-directional. -/
def bothTwoDirectional : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies (.atom "st_on_way" [vI, .var "h"] []) twoDirectional)

/-- Applicability: s2 (trigger): intends to turn; s3 (trigger): at an intersection and:; s4 (condition): Both intersecting highways are two-directional: -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and leftTurnThroughI (.and intendedDuringAct bothTwoDirectional))

/-- Obligation: s5 (obligation): After entering the intersection, the left turn must be made so as to leave the intersection to the right of the centerline of the highway being entered. -/
def obligation : Formula :=
  .forallRegion (.lit "lane") "l"
    (.implies (.atom "rel_occupies" [vSubject, .var "l"] [])
      (.not (.derived "drv_motion_moving_against_carrier" [vSubject, .var "l"] [pHaltSpeedTolerance])))

def rule : Rule :=
  { id := "NRS_484B_400_2b"
    laws := ["NRS-484B-400-2b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_400_2b
