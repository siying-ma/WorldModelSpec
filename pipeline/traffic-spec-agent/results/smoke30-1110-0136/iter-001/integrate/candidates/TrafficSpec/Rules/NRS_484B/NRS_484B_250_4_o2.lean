/-
  NRS_484B_250_4_o2 — NRS-484B-250-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): When a vehicle
    s2 (trigger): enters an intersection
    s3 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered,
    s4 (condition): but is inoperative at the time the vehicle enters the intersection,
    s5 (subject): the driver of the vehicle
    s6 (sibling): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    s7 (condition): After making such a stop,
    s8 (subject): the driver
    s9 (obligation): shall proceed
    s10 (standard): cautiously,
    s11 (condition): yielding to vehicles which have previously completed a stop or are within the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.intersection'], derived []
    s3: atoms ['dev.traffic_signal', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    s4: atoms ['dev.inoperative'], derived []
    s5: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s7: atoms ['rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'st.stop_line', 'st.crosswalk', 'st.entrance_of', 'st.region_geometry', 'prim.region_offset_along', 'st.sight_along_way', 'st.highway', 'st.on_way'], derived ['drv.motion.stopped']
    s8: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s9: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.moving']
    s11: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived ['drv.motion.stopped']

  How each span is written:
    s1, s5, s8: `ru_aggregate x DEF-NRS-484A-320::vehicle` (the class of x).
    s2, s9: judged at each observation at which x occupies an intersection i (`rel_occupies`, the
      `intersection` quantifier) and is moving (`drv_motion_moving`). The entry is the observation
      at which `rel_occupies x i` last rose: the entry conditions are read there through
      `since (occupies x i) (rises (occupies x i) ∧ …)`, so they hold for the whole of the current
      occupancy and for no earlier one.
    s3, s4 (`signalInoperativeAtEntry`), read at the entry: some traffic signal head (`traffic_signal`
      quantifier) is uncovered (`dev_traffic_signal_uncovered`) and governs i or a travel region c2
      entering i (`st_lane_enters c2 i`, `dev_governs`); and every uncovered head governing i or x's
      approach carrier c is `dev_inoperative` (which itself denotes an installed, uncovered head).
    s7 (`stopMade`), read at the entry: x's approach carrier c is a travel region entering i
      (`st_lane_enters c i`); x was halted (`drv_motion_stopped`) on c at the governing place at some
      observation j and, from j to the entry, occupied c or i at every observation (so c is the
      carrier x occupied at the observation before the entry, and the halt belongs to this approach,
      not to an earlier pass). The governing place (`governingPlace`), as o1 reads it:
        the stop line marking c (`st_entrance_of`), else
        before the crosswalk marking c, its footprint not overlapping it, else
        outside i at c's entrance end, where the sight along a through highway reaches the bound;
      each within `p.stop_point_tolerance` of the body (`st_region_geometry_distance`) on its
      upstream side (`prim_region_offset_along` along c's direction, at least zero).
      "The through highway" is read as a highway on which i lies (`st_on_way i h`) and c does not
      (`¬ st_on_way c h`): the way crossed, not the way x travels; the view is
      `st_sight_along_way x h ≥ p.approach_view_sight_distance`.
    s11 (`yieldedTo`): a vehicle y other than x (`same`, `ru_aggregate`) that (a) occupies i, or
      (b) occupies a travel region cy entering i, outside i, has halted on cy since it came onto it
      (`since (occupies y cy) (stopped y ∧ occupies y cy)`), and whose halt on cy began earlier than
      x's halt on c (`sinceRise` of y's halt on cy greater than `sinceRise` of x's halt on c).
    s10 (the operationalization): no such y has its centre and x's approach within
      `p.conflict_time_horizon` (`prim_closest_approach_within`) to a centre distance below
      `p.conflict_centre_clearance` (`prim_closest_approach_distance`).
    The obligation re-binds i, c and y with the applicability's whole selection (`selection`), so
    it speaks of the same intersection, the same approach and the same vehicles.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_4_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pApproachViewSightDistance : Term := .param "p.approach_view_sight_distance"
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictTimeHorizon : Term := .param "p.conflict_time_horizon"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The vehicle aggregate the node admits. -/
def vehicle (a : String) : Formula := .atom "ru_aggregate" [.var a, .lit "DEF-NRS-484A-320::vehicle"] []

def occupies (a r : String) : Formula := .atom "rel_occupies" [.var a, .var r] []
def entersInto (c i : String) : Formula := .atom "st_lane_enters" [.var c, .var i] []
def governs (d r : String) : Formula := .atom "dev_governs" [.var d, .var r] []
def marksEntrance (l c : String) : Formula := .atom "st_entrance_of" [.var l, .var c] []
def onWay (r h : String) : Formula := .atom "st_on_way" [.var r, .var h] []
def stopped (a : String) : Formula := .derived "drv_motion_stopped" [.var a] [pMotionSpeedTolerance]
def moving (a : String) : Formula := .derived "drv_motion_moving" [.var a] [pMotionSpeedTolerance]

/-- x's body within the stop-point tolerance of region `r`. -/
def nearTo (r : String) : Formula :=
  .cmp (.measure "st_region_geometry_distance" [vX, .var r]) .le pStopPointTolerance

/-- x's reference point on the upstream side of region `r` along carrier `c`'s direction. -/
def upstreamOf (r c : String) : Formula :=
  .cmp (.quantity "prim_region_offset_along" [vX, .var r, .var c] []) .ge zeroMetres

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := vehicle "x"

/-- s3, s4 at the entry: an uncovered head governs i or a carrier entering it, and every uncovered
    head governing i or x's approach carrier c is inoperative. -/
def signalInoperativeAtEntry : Formula :=
  .and
    (.existsDevice (.lit "traffic_signal") "d"
      (.and (.atom "dev_traffic_signal_uncovered" [.var "d"] [])
        (.or (governs "d" "i")
          (.existsRegion (.lit "travel_region") "c2" (.and (entersInto "c2" "i") (governs "d" "c2"))))))
    (.forallDevice (.lit "traffic_signal") "e"
      (.implies
        (.and (.atom "dev_traffic_signal_uncovered" [.var "e"] []) (.or (governs "e" "i") (governs "e" "c")))
        (.atom "dev_inoperative" [.var "e"] [])))

/-- s7: the stop line marking c. -/
def atStopLine : Formula :=
  .existsRegion (.lit "stop_line") "s"
    (.and (marksEntrance "s" "c") (.and (nearTo "s") (upstreamOf "s" "c")))

def hasStopLine : Formula :=
  .existsRegion (.lit "stop_line") "s2" (marksEntrance "s2" "c")

/-- s7: before entering the crosswalk marking c. -/
def beforeCrosswalk : Formula :=
  .existsRegion (.lit "crosswalk") "w"
    (.and (marksEntrance "w" "c")
      (.and (.not (occupies "x" "w")) (.and (nearTo "w") (upstreamOf "w" "c"))))

def hasCrosswalk : Formula :=
  .existsRegion (.lit "crosswalk") "w2" (marksEntrance "w2" "c")

/-- s7: outside i at c's entrance end, with a view along a through highway. -/
def atEntranceEnd : Formula :=
  .and (.not (occupies "x" "i"))
    (.and (nearTo "i")
      (.and (upstreamOf "i" "c")
        (.existsRegion (.lit "highway") "h"
          (.and (onWay "i" "h")
            (.and (.not (onWay "c" "h"))
              (.cmp (.measure "st_sight_along_way" [vX, .var "h"]) .ge pApproachViewSightDistance))))))

def governingPlace : Formula :=
  .or atStopLine
    (.and (.not hasStopLine)
      (.or beforeCrosswalk (.and (.not hasCrosswalk) atEntranceEnd)))

/-- s7 at the entry: x halted on c at the governing place, and has been on c or in i since. -/
def stopMade : Formula :=
  .since (.or (occupies "x" "c") (occupies "x" "i"))
    (.and (stopped "x") (.and (occupies "x" "c") governingPlace))

/-- s2, s3, s4, s7: the conditions at the entry of x's current occupancy of i. -/
def entryConditions : Formula :=
  .since (occupies "x" "i")
    (.and (.rises (occupies "x" "i")) (.and signalInoperativeAtEntry stopMade))

/-- s11: the vehicles y yielded to. -/
def yieldedTo : Formula :=
  .and (.not (.same vX (.var "y")))
    (.and (vehicle "y")
      (.or (occupies "y" "i")
        (.existsRegion (.lit "travel_region") "cy"
          (.and (entersInto "cy" "i")
            (.and (occupies "y" "cy")
              (.and (.not (occupies "y" "i"))
                (.and (.since (occupies "y" "cy") (.and (stopped "y") (occupies "y" "cy")))
                  (.cmp (.sinceRise (.and (stopped "y") (occupies "y" "cy"))) .gt
                        (.sinceRise (.and (stopped "x") (occupies "x" "c")))))))))))

/-- s10: a predicted conflict between x and y. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, .var "y"] [pConflictTimeHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, .var "y"] [pConflictTimeHorizon]) .lt
          pConflictCentreClearance)

/-- The whole selection of i, c and y; with `withConflict`, only the y in conflict with x. -/
def selection (withConflict : Bool) : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (occupies "x" "i")
      (.existsRegion (.lit "travel_region") "c"
        (.and (entersInto "c" "i")
          (.and entryConditions
            (.existsUser "y" (if withConflict then .and yieldedTo conflict else yieldedTo))))))

/-- Applicability: s2 (trigger): enters an intersection; s3 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered,; s4 (condition): but is inoperative at the time the vehicle enters the intersection,; s7 (condition): After making such a stop,; s11 (condition): yielding to vehicles which have previously completed a stop or are within the intersection. -/
def applicability : Formula := .and (moving "x") (selection false)

/-- Obligation: s9 (obligation): shall proceed; s10 (standard): cautiously, -/
def obligation : Formula := .not (selection true)

def rule : Rule :=
  { id := "NRS_484B_250_4_o2"
    laws := ["NRS-484B-250-4"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "cautiously (proceeding, yielding)"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_time_horizon", "p.conflict_centre_clearance"]
          convention := "Traffic-conflict technique: the subject proceeds cautiously, yielding, where it moves without creating a conflict with a vehicle it must yield to - no such vehicle whose centre and the subject's, under constant velocities, approach within the time-to-collision horizon (prim.closest_approach_within) to a centre distance below the clearance (prim.closest_approach_distance)."
          surrogate := false } ]
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_4_o2
