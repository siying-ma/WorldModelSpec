/-
  NRS_484B_400_2b — NRS-484B-400-2b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): If the driver of a vehicle
    s2 (condition): intends to turn
    s3 (condition): at an intersection and:
    s4 (condition): Both intersecting highways are two-directional:
    s5 (condition): After entering the intersection,
    s6 (condition): the left turn
    s7 (obligation): must be made so as to leave the intersection to the right of the centerline of the highway being entered.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s4: atoms ['rel.occupies', 'st.highway', 'st.intersection', 'st.lane_direction', 'st.lane_enters', 'st.median_or_divider', 'st.on_way', 'st.roadway', 'st.travel_region'], derived []
    s5: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.region_entry']
    s6: atoms [], derived ['drv.motion.left_turn']
    s7: atoms ['prim.region_lateral_offset', 'rel.occupies', 'st.centre_line', 'st.highway', 'st.intersection', 'st.on_way'], derived ['drv.motion.region_exit']

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  HOW EACH SPAN IS WRITTEN (this session's record):

  s1 — `clsV`: the one atom `ru_aggregate` with the binder and the admitted aggregate id
    `DEF-NRS-484A-320::vehicle` as its literal argument. 'the driver of' is carried by the
    vehicle's controlled motion (the record's observable reading, not restated here).

  s3 — `approaches`: the junction is singled out by a carrier the subject is on whose entrance end
    is that junction: a region quantifier over `travel_region` (the kind the record names for the
    carrier, so every kind refining it is covered), `rel_occupies` of the subject on it, and
    `st_lane_enters` from it to the `intersection` region the junction quantifier binds.
    TEMPORAL READING (this session's): the selection is read as holding at the judged observation
    or at an earlier one (`since .tt …`). A carrier whose entrance end is the junction is an
    approach to it, and the subject is no longer on such a carrier once its footprint has left the
    junction — which is the very observation at which s7 judges the departure. Read strictly at the
    judged observation the duty of s7 could never be judged on a compliant departure (the plan's
    own `permit` scene leaves the junction on the far side of the junction from its approach), so
    the words 'intends to turn at an intersection', which speak of the approach, are read as the
    approach having been observed at or before the observation judged. Nothing else about the
    selection is relaxed: the carrier, its entrance end and the junction are the record's.

  s2 — the declared intention `int.turn` of the subject at the junction region s3 singles out,
    read at the judged observation (never ahead of it).

  s4 — `bothWaysTwoDirectional` / `twoDirectional`: every carrier whose entrance end is that
    junction (`st_lane_enters`, quantified over `travel_region`) lies only on ways that are
    two-directional (`st_on_way` to a `highway` region). A way is two-directional when no
    `median_or_divider` region lies on it (DEF-NRS-484B-073's 'undivided', read by the absence of
    such a region on the way) and two `roadway` carriers on it carry designated directions
    (`st_lane_direction`) that point against each other.
    READING (this session's): 'proceed in opposite directions' is written as a negative dot product
    of the two designated directions — two carriers of the way whose directions point against each
    other. The reading admits every obtuse pair, not antiparallel pairs alone: a direction is read
    normalised only up to a factor below 1 + 2·10⁻⁶ and the node's reading carries no cosine
    tolerance for an exact antiparallel test, so no stricter test can be written without a
    magnitude this file has no right to.

  s5 — `hasEntered`: `drv.motion.region_entry` of the subject on the junction region s3 binds, at
    the judged observation or at an earlier one, as the record states.

  s6 — `hasTurnedLeft`: `drv.motion.left_turn` of the subject, with the reading's step bound of the
    acquisition profile, the onset yaw rate and the turn angle, in the concept's parameter order.

  s7 — `obligation`: at the observation at which the subject's footprint ceases to overlap the
    junction (`drv.motion.region_exit` on the junction region, the selection of s3 and the
    declaration of s2 restated so that the region is the one the applicability selects), the
    centre line of the way it then occupies lies to its left: for a `highway` region the subject
    occupies (`rel_occupies`) a `centre_line` region on that way (`st_on_way`) whose signed lateral
    offset from the subject (`prim.region_lateral_offset`, left positive) is at least
    `p.lateral_offset_resolution`. Where no centre line is observed on that way the duty is
    undefined there rather than broken (`definedWhen`), as the record states.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_400_2b

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pLateralOffsetResolution : Term := .param "p.lateral_offset_resolution"
def pLeftTurnAngle : Term := .param "p.left_turn_angle"
def pTurnOnsetYawRate : Term := .param "p.turn_onset_yaw_rate"

def zeroMetres : Term := .lit Q.zero .metre
def zeroRatio : Term := .lit Q.zero .ratio

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s4: the designated direction of a carrier, component by component. -/
def dirX (r : String) : Term := .measure "st_lane_direction" [.var r, .lit "x"]
def dirY (r : String) : Term := .measure "st_lane_direction" [.var r, .lit "y"]

/-- s4: the two carriers' designated directions point against each other. -/
def opposed (r1 r2 : String) : Formula :=
  .cmp (.add (.mul (dirX r1) (dirX r2)) (.mul (dirY r1) (dirY r2))) .lt zeroRatio

/-- s4: the way `w` is two-directional — undivided, and carrying opposed designated directions. -/
def twoDirectional (w : String) : Formula :=
  .and
    (.forallRegion (.lit "median_or_divider") "md"
      (.not (.atom "st_on_way" [.var "md", .var w] [])))
    (.existsRegion (.lit "roadway") "r1"
      (.and (.atom "st_on_way" [.var "r1", .var w] [])
        (.existsRegion (.lit "roadway") "r2"
          (.and (.atom "st_on_way" [.var "r2", .var w] []) (opposed "r1" "r2")))))

/-- s3: the subject is on, or has been on, a carrier whose entrance end is the junction `i`. -/
def approaches (i : String) : Formula :=
  .since .tt
    (.existsRegion (.lit "travel_region") "c"
      (.and (.atom "rel_occupies" [vV, .var "c"] [])
            (.atom "st_lane_enters" [.var "c", .var i] [])))

/-- s4: both highways that meet at the junction `i` are two-directional. -/
def bothWaysTwoDirectional (i : String) : Formula :=
  .forallRegion (.lit "travel_region") "c2"
    (.implies (.atom "st_lane_enters" [.var "c2", .var i] [])
      (.forallRegion (.lit "highway") "w"
        (.implies (.atom "st_on_way" [.var "c2", .var "w"] []) (twoDirectional "w"))))

/-- s5: the subject has entered the junction `i`, now or at an earlier observation. -/
def hasEntered (i : String) : Formula :=
  .since .tt (.derived "drv_motion_region_entry" [vV, .var i] [])

/-- s6: the subject has turned to the left. -/
def hasTurnedLeft : Formula :=
  .derived "drv_motion_left_turn" [vV]
    [pHeadingSinceStepCarlaSceneGraph, pTurnOnsetYawRate, pLeftTurnAngle]

/-- Applicability: s2 (condition): intends to turn; s3 (condition): at an intersection and:; s4 (condition): Both intersecting highways are two-directional:; s5 (condition): After entering the intersection,; s6 (condition): the left turn -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and
      (.and
        (.and (.and (approaches "i") (.intent "int.turn" vV (.var "i")))
              (bothWaysTwoDirectional "i"))
        (hasEntered "i"))
      hasTurnedLeft)

/-- s7: the subject lies to the right of the centre line of every way it then occupies. -/
def rightOfCentreLine : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies (.atom "rel_occupies" [vV, .var "h"] [])
      (.definedWhen
        (.existsRegion (.lit "centre_line") "cl" (.atom "st_on_way" [.var "cl", .var "h"] []))
        (.existsRegion (.lit "centre_line") "cl"
          (.and (.atom "st_on_way" [.var "cl", .var "h"] [])
            (.cmp (.quantity "prim_region_lateral_offset" [vV, .var "cl"] [])
                  .ge pLateralOffsetResolution)))))

/-- Obligation: s7 (obligation): must be made so as to leave the intersection to the right of the centerline of the highway being entered. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies
      (.and (.and (approaches "i") (.intent "int.turn" vV (.var "i")))
            (.derived "drv_motion_region_exit" [vV, .var "i"] []))
      rightOfCentreLine)

def rule : Rule :=
  { id := "NRS_484B_400_2b"
    laws := ["NRS-484B-400-2b"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.turn"]
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s7"
          why := "The junction whose departure the duty judges is the one the applicability selects, and that selection is restated in the obligation as having held at the judged observation or at an earlier one: the carrier whose entrance end is the junction, the subject's presence on it, and the declaration of a turn at that junction. A carrier is an approach to the junction, so the subject is no longer on it at the observation at which its footprint leaves the junction, which is the observation this duty judges."
          kind := "reading" }
      , { span := "s7"
          why := "'the highway being entered' is read for every highway region the subject occupies at the departure, not for one of them: where the subject's footprint lies on more than one way at that observation, the centre line of each must lie to its left, so no way is picked in the subject's favour."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_400_2b
