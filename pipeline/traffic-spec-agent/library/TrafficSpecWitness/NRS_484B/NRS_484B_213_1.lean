/-
  Witnesses for NRS 484B.213(1).

  One undivided two-lane, two-directional carriageway running east–west: a `roadway` 2 km long
  and 7.2 m wide carrying the sight distance, an eastbound lane south of the origin and a
  westbound lane north of it (each the other's left neighbour, neither with a neighbour to its
  right), and a `centre_line` at the origin carrying the carriageway's direction — the rule's
  "left" is the left of that direction. The `divided` scene adds a `median_or_divider`.

  Three vehicles, each 3 m long and 1.8 m wide: `a` the subject (track 1), `b` the vehicle
  overtaken (track 2), `c` the third party (track 3). Lane centres are 1.8 m either side of the
  line. Occupancy is stated rather than derived, because a reference point lies in one polygon
  and the spans this rule reads are about a body lying across two.

  Every figure here is the witness's own geometry and appears nowhere in the rule.

  The four witnesses the plan names, and one more the plan does not: `divided`, without which no
  scenario exercises the undivided-highway limb of s3 — no scene would carry a
  `median_or_divider` region at all, and the leaf could not matter. It is reported in
  task_result.md.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_213_1
import TrafficSpec.Core.Builders

namespace TrafficSpecWitness.NRS_484B_213_1

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n

/-- `x0` metres, advancing `v` metres each second. -/
private def xAt (x0 v : Int) (k : Nat) : Q := Units.metres (x0 + v * (Int.ofNat k))

-- The carriageway. Region 1 the roadway, 2 the eastbound lane, 3 the westbound lane,
-- 4 the centre line, 5 the median of the `divided` scene.
private def roadwayWith (sd : Q) : Structure :=
  { Build.rect 1 .roadway (m (-1000)) (cm (-360)) (m 1000) (cm 360) with sightDistance := some sd }
private def eastLane : Structure :=
  Build.lane 2 [(m (-1000), cm (-360)), (m 1000, cm (-360)), (m 1000, Q.zero), (m (-1000), Q.zero)]
    Build.east (some 3) none
private def westLane : Structure :=
  Build.lane 3 [(m (-1000), Q.zero), (m 1000, Q.zero), (m 1000, cm 360), (m (-1000), cm 360)]
    Build.west (some 2) none
/-- The dividing line, with the carriageway's direction: the rule's "left" is the left of it. -/
private def centreLine : Structure :=
  { Build.point 4 .centreLine (Q.zero, Q.zero) with lane := some { direction := some Build.east } }
private def median : Structure :=
  Build.rect 5 .medianOrDivider (m (-1000)) (cm (-10)) (m 1000) (cm 10)

private def carriageway (sd : Q) : List Structure :=
  [roadwayWith sd, eastLane, westLane, centreLine]

-- The bodies: half-length, half-width, half-height.
private def body : Q × Q × Q := (cm 150, cm 90, cm 75)
private def veh (track : TrackId) (x y : Q) (heading : Vec) (speed : Int) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) heading (Units.metresPerSecond speed) body

-- Lane centres, and the straddling offset of the `forbid` scene: a's reference point 0.6 m right
-- of the line, its 0.9 m half-width reaching 0.3 m across it.
private def eastCentre : Q := cm (-180)
private def westCentre : Q := cm 180
private def straddleY : Q := cm (-60)

-- Occupancy of b (always its own lane) and of c.
private def bOcc : List (TrackId × RegionId) := [(2, 2), (2, 1)]
private def cEast : List (TrackId × RegionId) := [(3, 2), (3, 1)]
private def cWest : List (TrackId × RegionId) := [(3, 3), (3, 1)]

/-- The pass: a starts 40 m behind b at 26 m/s against b's 14 m/s, moves into the westbound lane
    for the four instants 2…5, draws level and past, and is back in its own lane from 6 on. The
    lane change happens between observations, so a never occupies two lanes here. c runs 300 m
    behind at a's own speed: same direction, never oncoming, never closing. -/
private def aLeftOfLine (k : Nat) : Bool := 2 ≤ k && k ≤ 5
private def passTrace (sd : Q) : Trace :=
  Build.trace 9 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ veh 1 (xAt (-40) 26 k) (if aLeftOfLine k then westCentre else eastCentre) Build.east 26
      , veh 2 (xAt 0 14 k) eastCentre Build.east 14
      , veh 3 (xAt (-300) 26 k) eastCentre Build.east 26 ]
      (carriageway sd) []
      (some ((if aLeftOfLine k then [(1, 3), (1, 1)] else [(1, 2), (1, 1)]) ++ bOcc ++ cEast))

/-- The same pass begun and held across the line: a straddles both lanes throughout, the sight
    distance ahead is 30 m on a rising crest, and c comes the other way at 20 m/s so that the two
    are one second from conflict by the instant a has drawn past b. -/
private def straddleTrace (extra : List Structure) : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ veh 1 (xAt (-40) 26 k) straddleY Build.east 26
      , veh 2 (xAt 0 14 k) eastCentre Build.east 14
      , veh 3 (xAt 190 (-20) k) westCentre Build.west 20 ]
      (carriageway (m 30) ++ extra) []
      (some ([(1, 2), (1, 3), (1, 1)] ++ bOcc ++ cWest))

/-- a follows b 60 m back at b's own speed and never draws level: the trigger never holds. -/
private def followTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ veh 1 (xAt (-60) 14 k) eastCentre Build.east 14
      , veh 2 (xAt 0 14 k) eastCentre Build.east 14
      , veh 3 (xAt (-300) 14 k) eastCentre Build.east 14 ]
      (carriageway (m 400)) []
      (some ([(1, 2), (1, 1)] ++ bOcc ++ cEast))

private def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_213_1"
    trace := τ
    reading := {}
    manifest := Build.manifest absent
    grounding := [("a", 1), ("b", 2), ("c", 3)]
    expected := expected }

def scenarios : List Scenario :=
  [ -- s2 with s5 and s8 broken: a is across the line on a short sight distance with c closing.
    witness "forbid" (straddleTrace []) .violated
    -- the same pass with the sight distance long, no one oncoming and every gap kept.
  , witness "permit" (passTrace (m 400)) .compliant
    -- a never overtakes: s4 never holds.
  , witness "idle" followTrace .notApplicable
    -- the `permit` scene with the sight distance unobserved: s5 and s7 cannot be decided.
  , witness "blind" (passTrace (m 400)) (.unknown []) ["st.sight_distance"]
    -- s3's other limb: the same carriageway divided — there is no "centre" to be left of.
  , witness "divided" (straddleTrace [median]) .notApplicable ]

end TrafficSpecWitness.NRS_484B_213_1
