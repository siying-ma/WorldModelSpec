/-
  NRS_484B_257_1_o1 — NRS-484B-257-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal
    s2 (trigger): When proper signs have been erected
    s3 (subject): the driver of a vehicle
    s4 (obligation): shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection
    s5 (standard): where the driver has a view of approaching traffic on the through highway
    s6 (sibling): After having stopped or, in the event of a yield sign, slowed or stopped
    s7 (sibling): the driver shall yield the right-of-way to other vehicles which have entered the intersection from such through highway
    s8 (sibling): or which are approaching so closely on such through highway as to constitute an immediate hazard
    s9 (sibling): during the time such driver is moving across or within the intersection

  Elements (span → atoms, derived):
    s1: atoms ['dev.human_direction', 'dev.traffic_signal', 'dev.inoperative', 'dev.governs', 'st.intersection', 'st.lane', 'st.turn_lane', 'st.reserved_lane', 'st.centre_turn_lane', 'st.bicycle_lane_or_path', 'st.roadway', 'st.one_way_roadway', 'st.shoulder', 'rel.occupies'], derived []
    s2: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.intersection', 'st.lane_enters', 'st.on_way', 'st.highway', 'st.lane', 'st.turn_lane', 'st.reserved_lane', 'st.centre_turn_lane', 'st.bicycle_lane_or_path', 'st.roadway', 'st.one_way_roadway', 'st.shoulder', 'rel.occupies', 'kin.path_length'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s4: atoms ['st.stop_line', 'st.crosswalk', 'st.intersection', 'st.region_geometry', 'rel.occupies', 'kin.path_length', 'kin.speed', 'st.on_way', 'st.highway', 'dev.yield_sign', 'dev.governs', 'st.lane', 'st.turn_lane', 'st.reserved_lane', 'st.centre_turn_lane', 'st.roadway', 'st.one_way_roadway', 'st.shoulder', 'st.bicycle_lane_or_path'], derived ['drv.motion.ceased_movement']

  How each span is written:

    s3 — `clsV`, the binder's class: `ru_aggregate v "DEF-NRS-484A-320::vehicle"`, the admitted
      aggregate id and nothing else. The duty-bearer is the vehicle, read through its controlled
      motion; no person at the controls is read.

    The eight travel kinds `dev.governs` names are one disjunction, `someTravel`: a travel region
      is a region of kind lane, turn_lane, reserved_lane, centre_turn_lane, bicycle_lane_or_path,
      roadway, one_way_roadway or shoulder, and the contract admits each of them equally, so every
      place the record says "a travel region" is written as the same body under each of the eight
      `existsRegion` kinds. `st.lane` and its seven fellows are read there, and nowhere else.

    s2 — `applicability`, the positive part, inside `existsRegion "intersection" i` and
      `someTravel "a"`:
        · `trafficOf` — the subject is one of the traffic of `a`: its footprint overlaps `a`
          (rel.occupies), or it overlaps the junction `i` now and overlapped `a` at some
          observation within p.stop_approach_lookback of path behind. "At some observation in the
          window behind" is `not (holdsFor .path … (not …))`, the language's past existential, and
          the window is measured in path travelled (kin.path_length), as the record says.
        · `approachTo` — `a` is an approach to `i`: `st_lane_enters a i`, or `a` and `i` lie on one
          way (st.on_way over st.highway) while the subject's footprint overlaps `i`, so the
          junction read is the one the subject is at.
        · `signed` — a stop sign or a yield sign governs `a` or `i` (dev.stop_sign, dev.yield_sign,
          dev.governs). Presence is the erection; no legal status is assessed.
    s1 — `applicability`, the negative part: a person directing traffic whose role is police
      officer (dev.human_direction with its role), or a signal head that is neither inoperative
      (dev.inoperative) nor showing 'dark' (dev.traffic_signal with its indication), governing the
      junction, the approach, or any travel region the subject's footprint overlaps.
      `controlledOnOccupied` — the limb that reads the regions the subject is upon — names neither
      `i` nor `a`, so it is written once, conjoined at the top of the applicability; the limbs that
      name `i` and `a` are written in their scopes. `¬(A ∨ B)` distributed over the two
      existentials is the same formula as the record's, leaf for leaf, and is what is written.
    s4 — `obligation`: for every intersection region the subject's footprint overlaps
      (`forallRegion "intersection" i`, so a body overlapping two junctions is judged for each),
      there is an observation within p.stop_approach_lookback of path behind at which
      `conductOnApproach` holds:
        · `outsideJunction` — the footprint overlaps no intersection region of the scene;
        · `conduct` — the subject was halted (drv.motion.ceased_movement at p.halt_speed_tolerance),
          or a yield sign governs the junction or a travel region its footprint overlapped there
          and kin.speed was at most p.yield_approach_speed;
        · and, on a way `w` (st.highway) that the junction and some travel region its footprint
          overlapped there both lie on (st.on_way), `atPlace`: the three places in the words' own
          order. `atLine` is a stop line of this junction (st.stop_line, on that way, the body
          within p.junction_approach_reach of it and of the junction by st.region_geometry's ground
          distance) with that distance within p.stop_place_tolerance; else, where this junction
          carries no such line, `atCrossing` is such a crosswalk (st.crosswalk) with the ground
          distance within p.stop_place_tolerance, the footprint not overlapping it and not having
          overlapped it within p.crossing_entry_lookback of path behind; else, where it carries
          neither, `atNearestPoint`.
    s5 — `atNearestPoint`, the operationalization: the ground distance from the intersection region
      within p.intersection_edge_tolerance and the view along a way the junction lies on other than
      the one the place is read on (st.sight_along_way) at least p.intersection_view_distance.

  Readings I chose, declared in `narrowings` (the record's own narrowings are the plan's and are
  not restated here):
    1. s5 — "a way the intersection lies on other than the one its approach lies on" is read as a
       way region other than the one the place limbs are read on, not as a way the approach region
       does not lie on.
    2. s4 — where this junction carries several stop lines (or several crossings) of its own, the
       conduct at any one of them answers the words: the place limbs are existential over the lines
       and the crossings of the junction, as the record's narrowing already reads the crossings.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The quantifier variables: the junction, any intersection region of the scene, the approach,
    a travel region the subject is upon, the way of the place, the intersecting way, a stop line,
    a crosswalk, a sign, a device that is controlling traffic. -/
def iV : Arg := .var "i"
def jV : Arg := .var "j"
def aV : Arg := .var "a"
def cV : Arg := .var "c"
def wV : Arg := .var "w"
def w2V : Arg := .var "w2"
def slV : Arg := .var "sl"
def cwV : Arg := .var "cw"
def dV : Arg := .var "d"
def cdV : Arg := .var "cd"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCrossingEntryLookback : Term := .param "p.crossing_entry_lookback"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pIntersectionEdgeTolerance : Term := .param "p.intersection_edge_tolerance"
def pIntersectionViewDistance : Term := .param "p.intersection_view_distance"
def pJunctionApproachReach : Term := .param "p.junction_approach_reach"
def pStopApproachLookback : Term := .param "p.stop_approach_lookback"
def pStopPlaceTolerance : Term := .param "p.stop_place_tolerance"
def pYieldApproachSpeed : Term := .param "p.yield_approach_speed"

/-- The travel regions `dev.governs` names, each admitted equally by the contract. -/
def travelKinds : List String :=
  ["lane", "turn_lane", "reserved_lane", "centre_turn_lane", "bicycle_lane_or_path",
   "roadway", "one_way_roadway", "shoulder"]

/-- "Some travel region `x`": the same body under each of the eight kinds. -/
def someTravel (x : String) (φ : Formula) : Formula :=
  travelKinds.foldr (fun k acc => Formula.or (Formula.existsRegion (Arg.lit k) x φ) acc) Formula.ff

/-- A road user's footprint overlaps a region. -/
def occupies (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []
/-- A structure region lies on a way. -/
def onWay (r w : Arg) : Formula := .atom "st_on_way" [r, w] []
/-- A device controls the traffic of a region. -/
def governs (d r : Arg) : Formula := .atom "dev_governs" [d, r] []
/-- The ground distance from the subject's body outline to a region. -/
def groundDistance (r : Arg) : Term := .measure "st_region_geometry_distance" [vV, r]

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

-- ---------------------------------------------------------------------------------------------
-- s2 (trigger): the subject's traffic, its approach, and the signs erected for it
-- ---------------------------------------------------------------------------------------------

/-- s2: the subject is one of the traffic of the travel region `a` — its footprint overlaps `a`,
    or it overlaps the junction `i` and overlapped `a` within the look-back of path behind. -/
def trafficOf : Formula :=
  .or (occupies vV aV)
      (.and (occupies vV iV)
            (.not (.holdsFor .path pStopApproachLookback "v" (.not (occupies vV aV)))))

/-- s2: `a` is an approach to the junction `i` — it runs into it, or both lie on one way while
    the subject's footprint overlaps that junction. -/
def approachTo : Formula :=
  .or (.atom "st_lane_enters" [aV, iV] [])
      (.and (occupies vV iV)
            (.existsRegion (.lit "highway") "w" (.and (onWay aV wV) (onWay iV wV))))

/-- s2: a stop sign or a yield sign erected over the approach or over the junction. -/
def signed : Formula :=
  .or (.existsDevice (.lit "stop_sign") "d" (.or (governs dV aV) (governs dV iV)))
      (.existsDevice (.lit "yield_sign") "d" (.or (governs dV aV) (governs dV iV)))

-- ---------------------------------------------------------------------------------------------
-- s1 (exception): traffic being controlled by a police officer or a traffic-control signal
-- ---------------------------------------------------------------------------------------------

/-- s1: a person directing traffic, of the role police officer. -/
def officer : Formula := .atom "dev_human_direction_role" [cdV, .lit "police_officer"] []

/-- s1: a signal head that is displaying an indication — not inoperative and not showing 'dark'. -/
def liveHead : Formula :=
  .and (.not (.atom "dev_inoperative" [cdV] []))
       (.not (.atom "dev_traffic_signal_shows" [cdV, .lit "dark"] []))

/-- s1: an officer or a live head governs the region `r`. -/
def controlledOver (r : Arg) : Formula :=
  .or (.existsDevice (.lit "human_direction") "cd" (.and officer (governs cdV r)))
      (.existsDevice (.lit "traffic_signal") "cd" (.and liveHead (governs cdV r)))

/-- s1: an officer or a live head governs a travel region the subject's footprint overlaps. This
    limb names neither the junction nor the approach, so it is written once, outside them. -/
def controlledOnOccupied : Formula :=
  .or (.existsDevice (.lit "human_direction") "cd"
        (.and officer (someTravel "c" (.and (occupies vV cV) (governs cdV cV)))))
      (.existsDevice (.lit "traffic_signal") "cd"
        (.and liveHead (someTravel "c" (.and (occupies vV cV) (governs cdV cV)))))

/-- Applicability: s1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal; s2 (trigger): When proper signs have been erected -/
def applicability : Formula :=
  .and (.not controlledOnOccupied)
    (.existsRegion (.lit "intersection") "i"
      (.and (.not (controlledOver iV))
        (someTravel "a"
          (.and trafficOf (.and approachTo (.and signed (.not (controlledOver aV))))))))

-- ---------------------------------------------------------------------------------------------
-- s4 (obligation) and s5 (standard): the conduct, and the place it is performed at
-- ---------------------------------------------------------------------------------------------

/-- s4: the subject's footprint overlaps no intersection region of the scene. -/
def outsideJunction : Formula :=
  .forallRegion (.lit "intersection") "j" (.not (occupies vV jV))

/-- s4: halted — the road user at or below the halt tolerance. -/
def halted : Formula := .derived "drv_motion_ceased_movement" [vV] [pHaltSpeedTolerance]

/-- s4: the yield the sign admits — a yield sign governing the junction or a travel region the
    footprint overlaps there, and a speed at or below the yield-approach speed. -/
def yielded : Formula :=
  .and (.existsDevice (.lit "yield_sign") "d"
         (.or (governs dV iV) (someTravel "a" (.and (occupies vV aV) (governs dV aV)))))
       (.cmp (.measure "kin_speed" [vV]) .le pYieldApproachSpeed)

/-- s4: "stop or yield". -/
def conduct : Formula := .or halted yielded

/-- s4: the region `r` is a line or a crossing of this junction — it lies on the way the place is
    read on, and the body is within the entrance reach of it and of the junction. -/
def ofThisJunction (r : Arg) : Formula :=
  .and (onWay r wV)
    (.and (.cmp (groundDistance r) .le pJunctionApproachReach)
          (.cmp (groundDistance iV) .le pJunctionApproachReach))

def hasLine : Formula := .existsRegion (.lit "stop_line") "sl" (ofThisJunction slV)

/-- s4: at a clearly marked stop line of this junction. -/
def atLine : Formula :=
  .existsRegion (.lit "stop_line") "sl"
    (.and (ofThisJunction slV) (.cmp (groundDistance slV) .le pStopPlaceTolerance))

def hasCrossing : Formula := .existsRegion (.lit "crosswalk") "cw" (ofThisJunction cwV)

/-- s4: before entering the crosswalk on the near side — at its near edge, the footprint not
    overlapping it and not having overlapped it within the crossing look-back of path behind. -/
def atCrossing : Formula :=
  .existsRegion (.lit "crosswalk") "cw"
    (.and (ofThisJunction cwV)
      (.and (.cmp (groundDistance cwV) .le pStopPlaceTolerance)
        (.and (.not (occupies vV cwV))
              (.holdsFor .path pCrossingEntryLookback "v" (.not (occupies vV cwV))))))

/-- s4 and s5: at the point nearest the intersection, where the view along a way the junction lies
    on other than the one the place is read on reaches the intersection view distance. -/
def atNearestPoint : Formula :=
  .and (.cmp (groundDistance iV) .le pIntersectionEdgeTolerance)
    (.existsRegion (.lit "highway") "w2"
      (.and (.not (.same w2V wV))
        (.and (onWay iV w2V)
              (.cmp (.measure "st_sight_along_way" [vV, w2V]) .ge pIntersectionViewDistance))))

/-- s4: the places in the words' own order — the line, else the crossing, else the nearest point. -/
def atPlace : Formula :=
  .or atLine
      (.and (.not hasLine)
            (.or atCrossing (.and (.not hasCrossing) atNearestPoint)))

/-- s4: the conduct performed, before the junction, at the place the words name on the way the
    subject's approach lies on. -/
def conductOnApproach : Formula :=
  .and outsideJunction
    (.and conduct
      (.existsRegion (.lit "highway") "w"
        (.and (onWay iV wV)
          (.and (someTravel "a" (.and (occupies vV aV) (onWay aV wV)))
                atPlace))))

/-- Obligation: s4 (obligation): shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection; s5 (standard): where the driver has a view of approaching traffic on the through highway -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies (occupies vV iV)
      (.not (.holdsFor .path pStopApproachLookback "v" (.not conductOnApproach))))

def rule : Rule :=
  { id := "NRS_484B_257_1_o1"
    laws := ["NRS-484B-257-1"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations :=
      [ { standard := "where the driver has a view of approaching traffic on the through highway"
          concepts := ["rel.occupies", "st.highway", "st.intersection", "st.on_way", "st.region_geometry", "st.sight_along_way"]
          params := ["p.intersection_view_distance", "p.intersection_edge_tolerance"]
          convention := "Intersection (approach) sight-distance model: the along-way view needed to see traffic approaching on the intersecting way at its design speed, from the place at which a driver may proceed. The view is st.sight_along_way, 'the distance along a way, in each direction from the point of that way nearest a road user, within which another vehicle on that way could be seen from the road user's eye at the observation ... the smaller of the two directions', taken of a way the intersection lies on (st.highway with st.on_way and st.intersection) other than the one the subject's own approach lies on. A place satisfies the standard where that view is at least p.intersection_view_distance and the body's ground distance from the intersection region (st.region_geometry) is within p.intersection_edge_tolerance, the nearest place at which a vehicle can stand without entering the junction, rel.occupies anchoring the subject's own junction and its not having entered it. The view enters the bound as a measured magnitude, so the place the standard admits moves as the view along the way moves."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s5"
          why := "'the through highway' - the way the view is taken along - is read as a way region the intersection lies on other than the way region the place limbs are read on, and not as a way the subject's approach region does not lie on. The convention says 'other than the one the subject's own approach lies on' and the place limbs already fix one such way: the way that both the junction and a travel region the footprint overlapped there lie on. Any other way of the junction, taken by the identity of the region, answers the standard; where the approach lies on several ways, a view of at least p.intersection_view_distance along any way of the junction other than the one the place was read on satisfies it."
          kind := "reading" }
      , { span := "s4"
          why := "'a clearly marked stop line' and 'the crosswalk on the near side' are read existentially over the lines and the crossings of this junction: where the junction carries several lines (or several crossings) of its own on the way the place is read on, the conduct within p.stop_place_tolerance of any one of them answers the words, and 'if there is none' is the absence of any line (crossing) of this junction at all. The record reads the crossings this way; the lines are read the same way, so a halt at one line of an entrance is not defeated by a second line of the same entrance lying elsewhere under the body."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_1_o1
