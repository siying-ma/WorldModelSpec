/-
  NRS_484B_227_1_o2 — NRS-484B-227-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Every vehicle driven upon a divided highway
    s2 (sibling): must be driven only upon the right-hand roadway
    s3 (obligation): and must not be driven over, across or within any dividing space, barrier or section or make any left turn, semicircular turn or U-turn,
    s4 (exception): except through an opening in the barrier or dividing section or space or at a crossover or intersection established by a public authority.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.highway', 'st.roadway', 'st.median_or_divider', 'st.on_way', 'rel.occupies'], derived ['drv.motion.standstill']
    s3: atoms ['st.median_or_divider', 'rel.occupies', 'st.highway', 'st.on_way'], derived ['drv.motion.left_turn', 'drv.motion.u_turn']
    s4: atoms ['st.median_or_divider', 'st.intersection', 'rel.occupies', 'st.on_way'], derived []

  How each span is written.

  s1 — the subject and the trigger (`clsV`, `applicability`).
    "vehicle" is the binder's class: `ru_aggregate` of `v` with the admitted aggregate id
    DEF-NRS-484A-320::vehicle, the id and never the classes it covers. "driven" is the controlled
    motion of the record's observable reading: the negation of `drv.motion.standstill` with
    p.standstill_speed_tolerance. "upon a divided highway" is `onDividedWay`: `rel.occupies` of a
    region `w` that `st.highway` decides is a way, on which (`st.on_way`) a `st.median_or_divider`
    region lies and two `st.roadway` regions lie that `same` tells apart — DEF-NRS-484A-070's
    "divided into two or more roadways by means of a physical barrier or dividing section", read
    through the roadway contract's "separate roadways of a divided highway are separate".

  s3 — the duty (`obligation`). The way is selected again, whole, inside the obligation (the
    applicability's `w` is not in scope here), and the duty is read at every way so selected:
      (a) "driven over, across or within any dividing space, barrier or section" is
          `clearOfDividerOn`: no `st.median_or_divider` region lying (`st.on_way`) on that way is
          overlapped by the vehicle's footprint (`rel.occupies`) — the record's reading of the
          three prepositions as one overlap;
      (b) "make any left turn, semicircular turn or U-turn" is `turnRecognized`: the observation at
          which `drv.motion.left_turn` (p.turn_onset_yaw_rate, p.left_turn_angle,
          p.heading_since_step_carla_scene_graph) or `drv.motion.u_turn` (the same onset rate and
          step bound with p.u_turn_reversal_angle) first becomes true — `.rises` of the concept,
          the recognition the occasion declares. "upon a highway" of DEF-NRS-484B-077 is the way
          already selected (`st.highway`, `st.on_way`, `rel.occupies`), on which the vehicle is.

  s4 — the exception (`excused`, in the applicability). "an opening in the barrier or dividing
    section or space" and "a crossover" are one fact: a `st.median_or_divider` region on that way
    whose opening attribute holds and whose region the vehicle's footprint overlaps
    (`atOpeningOn`); "or intersection" is `st.intersection` on that way, overlapped likewise
    (`atJunctionOn`). "established by a public authority" is the presence of the feature (the
    record's observable reading). The occasion's boundary is an event, so the span is read
    `throughout` the act: where a manoeuvre is under way at the observation judged — the occasion's
    own `under_way`, the rate of change of heading above the onset rate or the heading change
    accumulated since the onset clear of zero (`underWayV`, from `kin.yaw_rate`) — the act judged
    is that turn, and the exception excuses it only where it has held at every observation from the
    declared onset, the observation at which that rate rose above the onset rate (`onsetV`), to
    this one (`excusedThroughoutAct`, `.since` anchored on that onset, so the stretch walked is the
    act's own and no window is invented). Where no manoeuvre is under way the act is the driving
    over the dividing space, and the exception excuses it where the vehicle overlaps the opening,
    crossover or intersection at that observation.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_227_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pLeftTurnAngle : Term := .param "p.left_turn_angle"
def pStandstillSpeedTolerance : Term := .param "p.standstill_speed_tolerance"
def pTurnOnsetYawRate : Term := .param "p.turn_onset_yaw_rate"
def pUTurnReversalAngle : Term := .param "p.u_turn_reversal_angle"

def zeroMetres : Term := .lit Q.zero .metre
def zeroDegrees : Term := .lit Q.zero .degree

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- "driven": the vehicle's motion is not a complete cessation from movement. -/
def movingV : Formula := .not (.derived "drv_motion_standstill" [vV] [pStandstillSpeedTolerance])

/-- The vehicle's footprint overlaps the region `r`. -/
def occupiesV (r : String) : Formula := .atom "rel_occupies" [vV, .var r] []

/-- The region `r` lies on the way `w`. -/
def onWayOf (r w : String) : Formula := .atom "st_on_way" [.var r, .var w] []

/-- `r` is a dividing space, barrier or section lying on the way `w`. -/
def dividerOn (r w : String) : Formula :=
  .and (.atom "st_median_or_divider" [.var r] []) (onWayOf r w)

/-- A divided highway: a way divided into two or more roadways by a physical barrier or dividing
    section lying on it. -/
def dividedWay (w : String) : Formula :=
  .and (.atom "st_highway" [.var w] [])
    (.and (.existsRegion (.lit "median_or_divider") "dw" (dividerOn "dw" w))
      (.existsRegion (.lit "roadway") "rwa"
        (.and (.atom "st_roadway" [.var "rwa"] [])
          (.and (onWayOf "rwa" w)
            (.existsRegion (.lit "roadway") "rwb"
              (.and (.atom "st_roadway" [.var "rwb"] [])
                (.and (onWayOf "rwb" w)
                  (.not (.same (.var "rwa") (.var "rwb"))))))))))

/-- s1's way, selected whole: the divided highway the vehicle is driven upon. -/
def onDividedWay (w : String) : Formula := .and (occupiesV w) (dividedWay w)

/-- s4: the vehicle overlaps an opening in the barrier or dividing section — a crossover — on `w`. -/
def atOpeningOn (w : String) : Formula :=
  .existsRegion (.lit "median_or_divider") "op"
    (.and (.atom "st_median_or_divider" [.var "op"] [])
      (.and (.atom "st_median_or_divider_opening" [.var "op"] [])
        (.and (onWayOf "op" w) (occupiesV "op"))))

/-- s4: the vehicle overlaps an intersection established on `w`. -/
def atJunctionOn (w : String) : Formula :=
  .existsRegion (.lit "intersection") "jx"
    (.and (.atom "st_intersection" [.var "jx"] [])
      (.and (onWayOf "jx" w) (occupiesV "jx")))

/-- s4 at this observation. -/
def exceptionHere (w : String) : Formula := .or (atOpeningOn w) (atJunctionOn w)

/-- The occasion's reading of turning: the rate of change of heading stands above the onset rate. -/
def turningV : Formula := .cmp (.abs (.measure "kin_yaw_rate" [vV])) .gt pTurnOnsetYawRate

/-- The occasion's onset: the observation at which that rate first rose above the onset rate. -/
def onsetV : Formula := .rises turningV

/-- The heading change accumulated since that onset. -/
def headingSinceOnset : Term := .headingSince "v" pHeadingSinceStepCarlaSceneGraph turningV

/-- The occasion's `under_way`: the manoeuvre is in progress at this observation — the rate of
    change of heading stands above the onset rate, or the heading change accumulated since the
    onset stands clear of zero. -/
def underWayV : Formula :=
  .or turningV (.cmp (.abs headingSinceOnset) .gt zeroDegrees)

def leftTurnV : Formula :=
  .derived "drv_motion_left_turn" [vV]
    [pHeadingSinceStepCarlaSceneGraph, pTurnOnsetYawRate, pLeftTurnAngle]

def uTurnV : Formula :=
  .derived "drv_motion_u_turn" [vV]
    [pHeadingSinceStepCarlaSceneGraph, pTurnOnsetYawRate, pUTurnReversalAngle]

/-- The occasion's recognition: the observation at which a left turn or a reversal is first
    recognized. -/
def turnRecognized : Formula := .or (.rises leftTurnV) (.rises uTurnV)

/-- s4 throughout the act: the exception has held at every observation from the declared onset of
    this manoeuvre to this one. -/
def excusedThroughoutAct (w : String) : Formula :=
  .since (exceptionHere w) (.and onsetV (exceptionHere w))

/-- s4, excusing the act judged at this observation: the overlap here, and — where a manoeuvre is
    under way here, so that the act judged is that turn — the overlap throughout it, from its
    declared onset to this observation. -/
def excused (w : String) : Formula :=
  .and (exceptionHere w) (.or (.not underWayV) (excusedThroughoutAct w))

/-- No dividing space, barrier or section of `w` is overlapped by the vehicle's footprint. -/
def clearOfDividerOn (w : String) : Formula :=
  .not (.existsRegion (.lit "median_or_divider") "dv"
    (.and (dividerOn "dv" w) (occupiesV "dv")))

/-- Applicability: s1, with s4 (exception): except through an opening in the barrier or dividing section or space or at a crossover or intersection established by a public authority. -/
def applicability : Formula :=
  .and movingV
    (.existsRegion (.lit "highway") "w"
      (.and (onDividedWay "w") (.not (excused "w"))))

/-- Obligation: s3 (obligation): and must not be driven over, across or within any dividing space, barrier or section or make any left turn, semicircular turn or U-turn, -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "w"
    (.implies (onDividedWay "w")
      (.and (clearOfDividerOn "w") (.not turnRecognized)))

def rule : Rule :=
  { id := "NRS_484B_227_1_o2"
    laws := ["NRS-484B-227-1"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_227_1_o2
