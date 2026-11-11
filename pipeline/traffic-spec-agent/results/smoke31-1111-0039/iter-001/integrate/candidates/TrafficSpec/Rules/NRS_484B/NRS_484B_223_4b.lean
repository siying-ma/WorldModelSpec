/-
  NRS_484B_223_4b — NRS-484B-223-4b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (condition): If a highway has been designed to provide
    e2 (condition): a single right lane to be used only for turning
    e3 (subject): a vehicle must
    e4 (condition): While being driven in the right turn lane
    e5 (obligation): not travel through an intersection

  Elements (span → atoms, derived):
    e1: atoms ['st.highway', 'st.on_way'], derived []
    e2: atoms ['st.turn_lane', 'st.lane', 'st.lane_adjacency'], derived []
    e3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    e4: atoms ['st.turn_lane', 'rel.occupies'], derived []
    e5: atoms ['st.intersection', 'st.lane_enters', 'rel.occupies', 'kin.yaw_rate'], derived ['drv.motion.heading_change_since_entry']

  How each span is written:
    e3: the class of `x` is `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
    e1: the turn lane L lies (`st_on_way`) on some region of kind `highway`; the mapped lane is the
        design (the record's status reading).
    e2: L is a region of kind `turn_lane` whose side is `right` (`st_turn_lane_side`); "single" is
        no region of kind `lane` that is L's left or right neighbour (`st_lane_adjacency` with the
        side as its literal) and is itself a `turn_lane` of side right. The neighbour is quantified
        as a lane (any lane may neighbour L) and its being a right turn lane is read by a second
        quantifier over `turn_lane` regions bound to the same region (`same`), so that a through
        neighbour, whose turn side is no field of it, decides "not a right turn lane" by its kind.
    e4: x occupies L here or at an earlier observation: `since tt (rel_occupies x L)` ("once").
    e5: for every intersection I that L enters (`st_lane_enters`), x does not, at the observation,
        leave I (`rises (not (rel_occupies x I))`: not in I here, in I at the previous observation)
        having made its latest entry into I (`rises (rel_occupies x I)`, no later entry since) at
        an observation at which it occupied L, with its heading change since that entry
        (`drv_motion_heading_change_since_entry x I`, step the acquisition profile's reviewed step)
        greater than minus `p.turn_recognition_angle`. The obligation re-binds L with the
        applicability's whole selection (e1, e2, e4) and states the duty for every such L.

  No choice beyond the record's: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_223_4b

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pTurnRecognitionAngle : Term := .param "p.turn_recognition_angle"

def zeroMetres : Term := .lit Q.zero .metre

/-- The turn lane and the intersection it enters, as quantifier variables. -/
def vL : Arg := .var "L"
def vI : Arg := .var "I"

/-- x's footprint overlaps region `r`. -/
def occupies (r : Arg) : Formula := .atom "rel_occupies" [vX, r] []

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- e1: L lies on a highway. -/
def onHighway : Formula :=
  .existsRegion (.lit "highway") "H" (.atom "st_on_way" [vL, .var "H"] [])

/-- e2: a lane neighbouring L on either side that is itself a right turn lane. -/
def rightTurnNeighbour : Formula :=
  .existsRegion (.lit "lane") "N"
    (.and (.or (.atom "st_lane_adjacency" [vL, .lit "left", .var "N"] [])
               (.atom "st_lane_adjacency" [vL, .lit "right", .var "N"] []))
          (.existsRegion (.lit "turn_lane") "M"
            (.and (.same (.var "M") (.var "N"))
                  (.atom "st_turn_lane_side" [.var "M", .lit "right"] []))))

/-- e1, e2: L (bound as a `turn_lane`) is a single right turn lane on a highway. -/
def singleRightTurnLane : Formula :=
  .and (.atom "st_turn_lane_side" [vL, .lit "right"] [])
    (.and onHighway (.not rightTurnNeighbour))

/-- e4: x occupies L here or occupied it at an earlier observation. -/
def drivenInLane : Formula := .since .tt (occupies vL)

/-- The whole selection of L (e1, e2, e4), written once and read in both formulas. -/
def selection : Formula := .and singleRightTurnLane drivenInLane

/-- Applicability: e1 (condition): If a highway has been designed to provide; e2 (condition): a single right lane to be used only for turning; e4 (condition): While being driven in the right turn lane -/
def applicability : Formula := .existsRegion (.lit "turn_lane") "L" selection

/-- e5: x stops here occupying I. -/
def leavesIntersection : Formula := .rises (.not (occupies vI))

/-- e5: x's latest entry into I was made at an observation at which it occupied L. -/
def enteredFromLane : Formula :=
  .since (.not (.rises (occupies vI))) (.and (.rises (occupies vI)) (occupies vL))

/-- e5: the heading change since that entry, left positive. -/
def headingChange : Term :=
  .quantity "drv_motion_heading_change_since_entry" [vX, vI] [pHeadingSinceStepCarlaSceneGraph]

/-- e5: the passage is no right turn: the change does not reach minus the recognition angle. -/
def noRightTurn : Formula := .cmp headingChange .gt (.neg pTurnRecognitionAngle)

/-- e5: travel through I from L. -/
def travelsThrough : Formula := .and leavesIntersection (.and enteredFromLane noRightTurn)

/-- Obligation: e5 (obligation): not travel through an intersection -/
def obligation : Formula :=
  .forallRegion (.lit "turn_lane") "L"
    (.implies selection
      (.forallRegion (.lit "intersection") "I"
        (.implies (.atom "st_lane_enters" [vL, vI] []) (.not travelsThrough))))

def rule : Rule :=
  { id := "NRS_484B_223_4b"
    laws := ["NRS-484B-223-4b"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_223_4b
