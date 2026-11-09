/-
  NRS_484B_127_1 — NRS-484B-127-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (obligation): shall not follow another vehicle
    s3 (standard): more closely than is reasonable and prudent, having due regard for the speed of such vehicles and the traffic upon and the condition of the highway.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.interaction.following']

  How each span is written:

  s1 is the binder's class alone: `ru_aggregate v "DEF-NRS-484A-320::vehicle"`, the aggregate claimed
  whole and never expanded into classes. The record's own narrowing carries "the driver" into the
  vehicle whose motion is controlled, so the span adds nothing beyond membership.

  s2 is the prohibition, and it binds no second road user: `obligation` forbids that there be any
  road user `w` of the scene, distinct from `v` (`same`, negated) and itself a member of the same
  aggregate, which `v` is following — `drv.interaction.following v w` with the reading's cosine
  tolerance — and whose longitudinal surface gap from `v` is below the bound s3 sets. Where the
  scene holds no such road user the quantifier is false and the duty is complied with; the duty
  therefore exists, and is judged, without a leader in the scene.

  s3 is the bound, written as the operationalization's convention states it:
      longitudinal rel.surface_gap (v, w)  <  H · kin.speed(v) + R + T
  with H the headway time selected by the conditions read at the observation
  (`p.following_headway_time_ice` where env.ice_or_snow, else `…_wet` where env.wet_road or
  env.precipitation, else `…_adverse_geometry` where the magnitude of st.grade exceeds
  `p.following_grade_threshold` or st.curvature exceeds `p.following_curvature_threshold`, else
  `…_dry`), R the closing-speed term `p.following_reaction_time · (kin.speed(v) − kin.speed(w))`
  where that excess is positive and zero otherwise, and T the dense-traffic increment
  `p.following_dense_traffic_gap_increment` where the count of road users occupying the highway the
  subject is on reaches `p.following_dense_traffic_count`, zero otherwise. Each selection is written
  with `Term.cond`, so a bound both selections agree on is still decided where the condition is not.

  Applicability is `.tt`: the node states no trigger beyond the binder's class ("The duty has no
  further trigger: it bites at any observation at which the vehicle is following another vehicle,
  which the obligation quantifies"), so nothing else conditions engagement.

  Readings chosen here and declared as narrowings on s3 (the record's own narrowings are the
  plan's and are not restated):
  - the condition of the highway and the traffic upon it are read at a highway the subject occupies
    (`existsRegion highway` with `st_highway` and `rel_occupies`), that being the only way the
    node's claimed names tie a way to the subject; where the subject occupies more than one
    highway region, the adverse-geometry selection and the traffic count are read at some such
    region rather than at all of them;
  - the traffic upon the highway counts every road user occupying that highway, the subject
    included, the posted definition of traffic covering every road user using the way for travel
    and naming no exception for the one whose duty is judged.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_127_1

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"
/-- The road user the obligation quantifies: the vehicle followed. -/
def wV : Arg := .var "w"
/-- A highway the subject occupies, bound inside the standard. -/
def hV : Arg := .var "h"
/-- A road user of the traffic upon that highway, bound by the count. -/
def uV : Arg := .var "u"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pFollowingCurvatureThreshold : Term := .param "p.following_curvature_threshold"
def pFollowingDenseTrafficCount : Term := .param "p.following_dense_traffic_count"
def pFollowingDenseTrafficGapIncrement : Term := .param "p.following_dense_traffic_gap_increment"
def pFollowingGradeThreshold : Term := .param "p.following_grade_threshold"
def pFollowingHeadwayTimeAdverseGeometry : Term := .param "p.following_headway_time_adverse_geometry"
def pFollowingHeadwayTimeDry : Term := .param "p.following_headway_time_dry"
def pFollowingHeadwayTimeIce : Term := .param "p.following_headway_time_ice"
def pFollowingHeadwayTimeWet : Term := .param "p.following_headway_time_wet"
def pFollowingReactionTime : Term := .param "p.following_reaction_time"
def pSameDirectionCosineTolerance : Term := .param "p.same_direction_cosine_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The vehicle followed is a member of the same aggregate (s2: "another vehicle"). -/
def followedIsVehicle : Formula := .atom "ru_aggregate" [wV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- "the speed of such vehicles": the subject's measured speed. -/
def speedOfSubject : Term := .measure "kin_speed" [vV]
/-- "the speed of such vehicles": the followed vehicle's measured speed. -/
def speedOfFollowed : Term := .measure "kin_speed" [wV]
/-- How closely the subject follows: the longitudinal component of the gap between the two bodies. -/
def longitudinalGap : Term := .measure "rel_surface_gap" [vV, wV, .lit "longitudinal"]

/-- `φ` read at a highway the subject occupies: the way whose condition and traffic s3 has regard
    for. The region is tied to the binder by `rel_occupies`. -/
def atSubjectHighway (φ : Formula) : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.and (.atom "st_highway" [hV] []) (.atom "rel_occupies" [vV, hV] [])) φ)

/-- "the condition of the highway": a stretch steep or curved enough to lengthen the stopping
    distance or shorten the view of the vehicle ahead. -/
def adverseGeometry : Formula :=
  atSubjectHighway
    (.or (.cmp (.abs (.measure "st_grade" [hV])) .gt pFollowingGradeThreshold)
         (.cmp (.measure "st_curvature" [hV]) .gt pFollowingCurvatureThreshold))

/-- "the traffic upon the highway": the road users occupying the highway the subject is on. -/
def trafficOnHighway : Term :=
  .aggregate .count "u" (atSubjectHighway (.atom "rel_occupies" [uV, hV] [])) zeroMetres

/-- The stream is dense enough to call for the added gap. -/
def denseTraffic : Formula := .cmp trafficOnHighway .ge pFollowingDenseTrafficCount

/-- H: the headway time the conditions read at the observation select. -/
def headwayTime : Term :=
  .cond (.atom "env_ice_or_snow" [] [])
    pFollowingHeadwayTimeIce
    (.cond (.or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] []))
      pFollowingHeadwayTimeWet
      (.cond adverseGeometry pFollowingHeadwayTimeAdverseGeometry pFollowingHeadwayTimeDry))

/-- R: the gap the closing speed demands, where the subject is the faster of the two. -/
def closingTerm : Term :=
  .cond (.cmp speedOfSubject .gt speedOfFollowed)
    (.mul pFollowingReactionTime (.sub speedOfSubject speedOfFollowed))
    zeroMetres

/-- T: the gap dense traffic demands. -/
def trafficTerm : Term :=
  .cond denseTraffic pFollowingDenseTrafficGapIncrement zeroMetres

/-- The bound s3 sets at the observation: H · speed + R + T. -/
def reasonableGap : Term :=
  .add (.add (.mul headwayTime speedOfSubject) closingTerm) trafficTerm

/-- s2: the subject is following that road user. -/
def isFollowing : Formula :=
  .derived "drv_interaction_following" [vV, wV] [pSameDirectionCosineTolerance]

/-- Applicability: (no trigger/condition span) — the class of `v` is the whole of engagement. -/
def applicability : Formula := .tt

/-- Obligation: s2 (obligation): shall not follow another vehicle; s3 (standard): more closely than is reasonable and prudent, having due regard for the speed of such vehicles and the traffic upon and the condition of the highway. -/
def obligation : Formula :=
  .not (.existsUser "w"
    (.and
      (.and (.not (.same vV wV)) followedIsVehicle)
      (.and isFollowing (.cmp longitudinalGap .lt reasonableGap))))

def rule : Rule :=
  { id := "NRS_484B_127_1"
    laws := ["NRS-484B-127-1"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "more closely than is reasonable and prudent, having due regard for the speed of such vehicles and the traffic upon and the condition of the highway"
          concepts := ["drv.interaction.following", "env.ice_or_snow", "env.precipitation", "env.wet_road", "kin.speed", "rel.occupies", "rel.surface_gap", "st.curvature", "st.grade", "st.highway"]
          params := ["p.following_headway_time_dry", "p.following_headway_time_wet", "p.following_headway_time_ice", "p.following_headway_time_adverse_geometry", "p.following_reaction_time", "p.following_grade_threshold", "p.following_curvature_threshold", "p.following_dense_traffic_count", "p.following_dense_traffic_gap_increment"]
          convention := "Time-headway and stopping-distance convention (the two-second-rule family with surface-dependent multipliers, over AASHTO perception-reaction time and stopping-distance figures). Following is closer than the bound where the longitudinal component of rel.surface_gap, “the distance between the nearest points of two bodies … its longitudinal and lateral components … along and across the subject's heading”, is less than H × kin.speed of the subject + p.following_reaction_time × the excess of the subject's speed over the followed vehicle's speed where that excess is positive + T. Each named factor is read by its degree. “the speed of such vehicles”: the subject's measured speed scales the whole headway term, so the bound grows with it, and the followed vehicle's measured speed enters through the closing speed, so a bound that is adequate behind a vehicle running at the same speed is not adequate behind a slower one. “the condition of the highway”: H is selected among bounds by the conditions read at the observation — p.following_headway_time_ice where env.ice_or_snow (“road surface icy or snow-covered”), else p.following_headway_time_wet where env.wet_road (“road surface wet, standing water”) or env.precipitation, else p.following_headway_time_adverse_geometry where the magnitude of st.grade exceeds p.following_grade_threshold or st.curvature, “horizontal curvature of the roadway at a point, as a magnitude”, exceeds p.following_curvature_threshold, else p.following_headway_time_dry. “the traffic upon the highway”: T adds p.following_dense_traffic_gap_increment where the count of road users occupying the highway the subject is on (rel.occupies with st.highway) reaches p.following_dense_traffic_count — the posted definition of traffic covering “pedestrians, ridden or herded animals, vehicles and other conveyances either singly or together using any highway for purposes of travel”, so every road user on the way is counted and no class narrows the stream — and is zero otherwise, so the density of the stream moves the bound. drv.interaction.following fixes which pair the bound is applied to. Every magnitude is a named parameter of the reading; the law states none."
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s3"
          why := "“the condition of the highway” and “the traffic upon … the highway” are read at a highway the subject occupies: the standard is written `existsRegion highway` with `st_highway` and `rel_occupies` of the binder, that being the only tie the node's claimed names give between a way and the subject. Where the subject occupies more than one highway region, the adverse-geometry selection and the traffic count are read at some such region and not at all of them."
          kind := "reading" }
      , { span := "s3"
          why := "“the traffic upon … the highway” counts every road user occupying that highway, the subject included: the posted definition of traffic covers every road user using the way for travel and names no exception for the one whose duty is judged, so the count is not reduced by one for the subject."
          kind := "reading" } ]
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_127_1
