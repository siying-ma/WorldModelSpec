/-
  NRS_484B_250_4_o1 — NRS-484B-250-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    c1 (trigger): When a vehicle enters an intersection
    c2 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, but is inoperative at the time the vehicle enters the intersection
    c3 (subject): the driver of the vehicle
    c4 (obligation): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway
    c5 (sibling): After making such a stop
    c6 (sibling): the driver shall proceed
    c7 (sibling): cautiously
    c8 (sibling): yielding
    c9 (sibling): to vehicles which have previously completed a stop or are within the intersection

  Elements (span → atoms, derived):
    c1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.intersection', 'rel.occupies'], derived []
    c2: atoms ['dev.traffic_signal', 'dev.inoperative', 'dev.governs', 'st.lane', 'st.lane_enters', 'st.intersection', 'rel.occupies'], derived ['drv.control.intersection_controlled']
    c3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    c4: atoms ['kin.speed', 'st.stop_line', 'st.region_geometry', 'st.crosswalk', 'rel.occupies', 'st.intersection', 'kin.path_length', 'st.sight_along_way', 'st.highway', 'st.on_way', 'st.lane', 'st.lane_enters', 'rel.visible', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived ['drv.motion.at_rest']

  How each span is written.

  c3 / the subject. `clsV` is the admitted aggregate alone: `ru_aggregate v
  DEF-NRS-484A-320::vehicle`. c1 and c3 name the same road user, so c3 adds nothing to the
  formulas beyond the binder's class.

  c1 / the trigger. `entersRegion i` is `rises (rel_occupies v i)` for a region `i` the
  applicability quantifies over the intersections of the scene: the entry is the rise of the
  anchoring relation, which the language writes directly. Nothing of where else the footprint lies
  is read.

  c2 / the condition. `headGoverns d i`, under `existsDevice traffic_signal d`, with
  `dev_traffic_signal_uncovered d` (installed head whose faces are not covered) and
  `dev_inoperative d` read at the entry observation. Which intersection the head controls is read
  through `dev_governs`: the head governs the entered intersection region itself, or a lane
  (`st_lane`) that runs into it at its end (`st_lane_enters`). The record's concept,
  drv.control.intersection_controlled, carries "controlled by" in the first of those two cases,
  conjoined with `dev_governs d i`: where the head governs the very intersection whose overlap by
  the vehicle's footprint begins at this observation, the concept's contract is satisfied by that
  overlap and that device, so the conjunct states the concept's configuration and narrows nothing.
  The lane case is written from the atoms alone, because the clause conditions on the intersection
  being controlled and not on where the vehicle's body lies: a vehicle whose footprint has cleared
  its approach lane as it crosses the boundary enters a controlled intersection all the same
  (the record's applicability, and its branch_4 scene). The two disjuncts together are the
  record's applicability word for word, and no span that decides when the rule applies is
  narrowed here.

  c4 / the obligation. `obligation` is read of every intersection whose overlap by the footprint
  begins at this observation (`forallRegion intersection i`, guarded by `entersRegion i`). For
  that intersection the cascade of the three limbs is searched over the stretch of path behind the
  entry (`holdsFor .path p.stop_approach_lookback`, so the window is distance travelled, which
  reads kin.path_length), and only at the observations of that stretch at which the vehicle's
  footprint overlapped a lane running into that same intersection — `onApproach i`, which is what
  makes the halt the one this clause requires and not a halt at another junction or on another
  approach.
    limb 1: at some such observation the vehicle was at rest (drv.motion.at_rest with
      p.halt_speed_tolerance, which reads kin.speed) with a clearly marked stop line
      (`st_stop_line`) within p.stop_place_tolerance of its body (`st_region_geometry` through the
      ground distance from the body outline to the region).
    limb 2: where no observation of that stretch on that approach put a stop line within that
      tolerance of its body, and the stretch does show a crossing on the near side (a
      `st_crosswalk` whose ground distance from the body is no greater than the distance to that
      intersection region), the vehicle was at rest at an observation at which, over
      p.crossing_entry_lookback of path behind it, its footprint had not yet overlapped
      (`rel_occupies`) such a near-side crossing.
    limb 3: where the stretch showed neither, the vehicle was at rest at the last observation of
      the stretch at which it was on that approach, not yet within that intersection, the view
      along the intersecting through highway reached p.intersection_view_distance
      (`st_sight_along_way`), and every road user of DEF-NRS-484A-285::traffic whose footprint
      overlapped that way stood in an unobstructed line of sight from the vehicle (`rel_visible`).
      The through highway is a `st_highway` the intersection lies on (`st_on_way`) and the
      vehicle's own approach lane does not.

  Readings chosen here on c4 and declared as narrowings below:
    (a) the halt is read as one observation of the searched stretch at which the vehicle was at
        rest at the place the limb names; no standstill of any duration and no second observation
        of continued rest is required, because a sampled trace shows a stop as the observations at
        which the speed is at or below the halt tolerance;
    (b) limb 2 reads the halt and "before entering the crosswalk" at the same observation: the
        observation at which the vehicle was at rest must itself be one at which the crossing had
        not been overlapped over the crossing look-back behind it.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_4_o1

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCrossingEntryLookback : Term := .param "p.crossing_entry_lookback"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pIntersectionViewDistance : Term := .param "p.intersection_view_distance"
def pStopApproachLookback : Term := .param "p.stop_approach_lookback"
def pStopPlaceTolerance : Term := .param "p.stop_place_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- c1: the vehicle's footprint begins to overlap the intersection region `i` at this observation. -/
def entersRegion (i : String) : Formula :=
  .rises (.atom "rel_occupies" [vV, .var i] [])

/-- c2: the head `d` controls the intersection `i` — it governs that region itself (the
    configuration drv.control.intersection_controlled states, the vehicle's footprint overlapping
    that region at the entry), or it governs a lane that runs into that intersection at its end. -/
def headGoverns (d i : String) : Formula :=
  .or
    (.and (.derived "drv_control_intersection_controlled" [vV] [])
          (.atom "dev_governs" [.var d, .var i] []))
    (.existsRegion (.lit "lane") "la"
      (.and (.atom "st_lane_enters" [.var "la", .var i] [])
            (.atom "dev_governs" [.var d, .var "la"] [])))

/-- Applicability: c1 (trigger): When a vehicle enters an intersection; c2 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, but is inoperative at the time the vehicle enters the intersection -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (entersRegion "i")
      (.existsDevice (.lit "traffic_signal") "d"
        (.and (.atom "dev_traffic_signal_uncovered" [.var "d"] [])
          (.and (.atom "dev_inoperative" [.var "d"] [])
                (headGoverns "d" "i")))))

/-- The vehicle is on its approach to `i`: its footprint overlaps a lane that runs into `i`. -/
def onApproach (i : String) : Formula :=
  .existsRegion (.lit "lane") "lo"
    (.and (.atom "rel_occupies" [vV, .var "lo"] [])
          (.atom "st_lane_enters" [.var "lo", .var i] []))

/-- The halt itself. -/
def atRest : Formula := .derived "drv_motion_at_rest" [vV] [pHaltSpeedTolerance]

/-- A clearly marked stop line within the placement tolerance of the body. -/
def atStopLine : Formula :=
  .existsRegion (.lit "stop_line") "sl"
    (.cmp (.measure "st_region_geometry_distance" [vV, .var "sl"]) .le pStopPlaceTolerance)

/-- A crossing on the near side of `i`: no farther from the body than that intersection. -/
def nearSideCrossing (i : String) : Formula :=
  .existsRegion (.lit "crosswalk") "cw"
    (.cmp (.measure "st_region_geometry_distance" [vV, .var "cw"]) .le
          (.measure "st_region_geometry_distance" [vV, .var i]))

/-- The footprint overlaps such a near-side crossing. -/
def inNearSideCrossing (i : String) : Formula :=
  .existsRegion (.lit "crosswalk") "cw"
    (.and (.atom "rel_occupies" [vV, .var "cw"] [])
          (.cmp (.measure "st_region_geometry_distance" [vV, .var "cw"]) .le
                (.measure "st_region_geometry_distance" [vV, .var i])))

/-- Over the crossing look-back behind this observation the near-side crossing had not been
    entered: the halt is made before entering the crosswalk. -/
def notYetInCrossing (i : String) : Formula :=
  .holdsFor .path pCrossingEntryLookback "v" (.not (inNearSideCrossing i))

/-- Nowhere in the searched stretch, at an observation on the approach to `i`, does `φ` hold. -/
def nowhereOnApproach (i : String) (φ : Formula) : Formula :=
  .holdsFor .path pStopApproachLookback "v" (.not (.and (onApproach i) φ))

/-- The view along the intersecting through highway from the vehicle on approach lane `l`. -/
def viewAlongThroughWay (i l : String) : Formula :=
  .existsRegion (.lit "highway") "w"
    (.and (.atom "st_on_way" [.var i, .var "w"] [])
      (.and (.not (.atom "st_on_way" [.var l, .var "w"] []))
        (.and (.cmp (.measure "st_sight_along_way" [vV, .var "w"]) .ge pIntersectionViewDistance)
              (.forallUser "u"
                (.implies
                  (.and (.atom "ru_aggregate" [.var "u", .lit "DEF-NRS-484A-285::traffic"] [])
                        (.atom "rel_occupies" [.var "u", .var "w"] []))
                  (.atom "rel_visible" [vV, .var "u"] []))))))

/-- An observation at which the vehicle is on its approach to `i`, not yet within it, and the view
    of approaching traffic on the through highway is afforded. -/
def viewPoint (i : String) : Formula :=
  .existsRegion (.lit "lane") "lv"
    (.and (.atom "rel_occupies" [vV, .var "lv"] [])
      (.and (.atom "st_lane_enters" [.var "lv", .var i] [])
        (.and (.not (.atom "rel_occupies" [vV, .var i] []))
              (viewAlongThroughWay i "lv"))))

/-- The cascade of the three limbs for the intersection `i` the vehicle enters. -/
def cascade (i : String) : Formula :=
  .or
    (.not (nowhereOnApproach i (.and atRest atStopLine)))
    (.or
      (.and (nowhereOnApproach i atStopLine)
        (.and (.not (nowhereOnApproach i (nearSideCrossing i)))
              (.not (nowhereOnApproach i (.and atRest (notYetInCrossing i))))))
      (.and (nowhereOnApproach i atStopLine)
        (.and (nowhereOnApproach i (nearSideCrossing i))
              (.atLast .path pStopApproachLookback "v" (viewPoint i) atRest))))

/-- Obligation: c4 (obligation): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies (entersRegion "i") (cascade "i"))

def rule : Rule :=
  { id := "NRS_484B_250_4_o1"
    laws := ["NRS-484B-250-4"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "c4"
          why := "The halt is read as one observation of the searched stretch at which the vehicle was at rest at the place the limb names: a sampled trace shows 'shall stop' as an observation whose speed is at or below the halt tolerance, and no standstill of any duration and no second observation of continued rest is required."
          kind := "reading" }
      , { span := "c4"
          why := "'shall stop ... before entering the crosswalk on the near side' is read at the halt itself: the observation at which the vehicle was at rest must be one at which, over the crossing look-back behind it, its footprint had not yet overlapped a near-side crossing, rather than the halt and the crossing being read at two observations."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_4_o1
