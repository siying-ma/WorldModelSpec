/-
  Witnesses for NRS 484B.223(2), second obligation.

  One straight east–west carriageway, 900 m long, mapped as a `roadway` (region 1) with three
  3.6 m lanes inside it: region 2 the extreme left (ordinal 0, recorded westbound), region 3 the
  centre (ordinal 1) and region 4 the extreme right (ordinal 2, eastbound). Each lane records the
  census of three, its neighbours, a marking on each side (the outer edges solid, the two lines
  between the lanes broken, all white) and a sight distance of 300 m. Region 5 is the centre line
  the carriageway carries. `idle` swaps in the same carriageway with two lanes only (regions 2 and
  3, ordinals 0 and 1, a census of two).

  The subject `a` (track 1) and the vehicle `b` (track 2) are 4 m long and 1.8 m wide and record a
  yaw rate at every instant, so that `drv.turning` is decided rather than unknown. Seven
  observations three seconds apart: a six-second window (the reading's `p.turn_window`) is then
  both covered and adequately sampled from the third observation on, and each witness names the
  instants it speaks about.

  Occupancy is derived from the geometry, so the lane a is in is the lane its reference point
  lies in. Every figure here is the witness's own geometry and appears nowhere in the rule.

  Two witnesses beyond the four the node names carry the exceptions the node's own narratives
  leave untried — (c) in `permit_allocated`, (b) in `permit_turn` — and one, `forbid_gap`, puts a
  user in the centre lane so that the reach of s11's gap test is shown. See task_result.md.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_223_2_o2
import TrafficSpec.Core.Builders

namespace TrafficSpecWitness.NRS_484B_223_2_o2

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n

/-- A lane's markings, white on both sides. -/
private def marked (st : Structure) (ml mr : MarkingType) : Structure :=
  { st with lane := st.lane.map fun l =>
      { l with markingLeft := some (ml, MarkingColour.white)
               markingRight := some (mr, MarkingColour.white) } }

/-- The sight distance recorded for a region. -/
private def seeing (st : Structure) (d : Q) : Structure := { st with sightDistance := some d }

/-- A 900 m strip of lane between `y0` and `y1`, with its recorded direction, its neighbours, its
    ordinal from the left of the carriageway and the census of the division it belongs to. -/
private def strip (id : RegionId) (y0 y1 : Q) (dir : Vec) (left right : Option RegionId)
    (ordinal count : Nat) : Structure :=
  Build.lane id [(m (-200), y0), (m 700, y0), (m 700, y1), (m (-200), y1)] dir
    left right (some ordinal) (some count)

/-- The carriageway the statute speaks of: three clearly marked lanes about a centre line.
    `centreDir` is the direction recorded for the centre lane. -/
private def threeLaneRoad (centreDir : Vec) : List Structure :=
  [ Build.rect 1 .roadway (m (-200)) (cm (-540)) (m 700) (cm 540)
  , Build.rect 5 .centreLine (m (-200)) (cm (-10)) (m 700) (cm 10)
  , seeing (marked (strip 2 (cm 180) (cm 540) Build.west none (some 3) 0 3) .solid .broken) (m 300)
  , seeing (marked (strip 3 (cm (-180)) (cm 180) centreDir (some 2) (some 4) 1 3) .broken .broken) (m 300)
  , seeing (marked (strip 4 (cm (-540)) (cm (-180)) Build.east (some 3) none 2 3) .broken .solid) (m 300) ]

/-- The same road marked into two lanes: the census is two, and the trigger never holds. -/
private def twoLaneRoad : List Structure :=
  [ Build.rect 1 .roadway (m (-200)) (cm (-360)) (m 700) (cm 360)
  , Build.rect 5 .centreLine (m (-200)) (cm (-10)) (m 700) (cm 10)
  , seeing (marked (strip 2 Q.zero (cm 360) Build.west none (some 3) 0 2) .solid .broken) (m 300)
  , seeing (marked (strip 3 (cm (-360)) Q.zero Build.east (some 2) none 1 2) .broken .solid) (m 300) ]

-- The body: half-length, half-width, half-height.
private def body : Q × Q × Q := (m 2, cm 90, cm 75)

/-- A vehicle whose yaw rate is recorded at every instant. -/
private def vehicle (track : TrackId) (pos : Vec) (h : Vec) (speed yaw : Q) : RoadUser :=
  Build.withKin (Build.user track [.motorVehicle] pos h speed body)
    fun k => { k with yawRate := some yaw }

/-- The same, with the left indicator showing. -/
private def signallingLeft (u : RoadUser) : RoadUser :=
  Build.withSignals u fun s => { s with turnIndicator := some .left }

-- The lane centres, and the speeds and tracks the witnesses run.
private def centreY : Q := Q.zero
private def rightY : Q := cm (-360)
private def rightOfTwo : Q := cm (-180)
private def fast : Q := Units.metresPerSecond 25
private def slow : Q := Units.metresPerSecond 5
private def middling : Q := Units.metresPerSecond 20
private def straight : Q := Units.degrees 0
private def turningLeft : Q := Units.degrees 20

/-- a at 25 m/s, from 64 m behind the origin. -/
private def aX (k : Nat) : Q := m (75 * Int.ofNat k - 64)
/-- b at 5 m/s, always well ahead of a. -/
private def bAheadX (k : Nat) : Q := m (15 * Int.ofNat k + 500)
/-- b at 5 m/s, overtaken by a between the second and the third observation. -/
private def bPassedX (k : Nat) : Q := m (15 * Int.ofNat k)

private def scenes (n : Nat) (f : Nat → Timestamp → Scene) : Trace :=
  Build.trace n 0 (Units.seconds 3) f

/-- a cruises in the centre lane; b is far ahead in the right lane, so nothing is overtaken. -/
private def cruiseTrace (road : List Structure) (devices : List Device) : Trace :=
  scenes 7 fun k t =>
    Build.scene t (some 1)
      [ vehicle 1 (aX k, centreY) Build.east fast straight
      , vehicle 2 (bAheadX k, rightY) Build.east slow straight ]
      road devices

/-- a leaves the right lane, passes b and runs on in the centre lane. -/
private def passTrace (extra : Nat → List RoadUser) : Trace :=
  scenes 7 fun k t =>
    Build.scene t (some 1)
      ([ vehicle 1 (aX k, if k = 0 then rightY else centreY) Build.east fast straight
       , vehicle 2 (bPassedX k, rightY) Build.east slow straight ] ++ extra k)
      (threeLaneRoad Build.west) []

/-- a idles along the right lane of a two-lane carriageway. -/
private def twoLaneTrace : Trace :=
  scenes 7 fun k t =>
    Build.scene t (some 1)
      [ vehicle 1 (aX k, rightOfTwo) Build.east fast straight
      , vehicle 2 (bAheadX k, rightOfTwo) Build.east slow straight ]
      twoLaneRoad []

-- a signals left in the centre lane and swings out of it after the instant the witness names.
private def turnPos (k : Nat) : Vec :=
  if k ≤ 4 then (m (15 * Int.ofNat k), centreY)
  else if k = 5 then (m 80, m 3)
  else (m 82, m 10)
private def turnHeading (k : Nat) : Vec :=
  if k ≤ 4 then Build.east else if k = 5 then (Q.ofInt 1, Q.ofInt 1) else Build.north
private def turnYaw (k : Nat) : Q := if k ≤ 4 then straight else turningLeft

private def turnTrace : Trace :=
  scenes 7 fun k t =>
    Build.scene t (some 1)
      [ signallingLeft (vehicle 1 (turnPos k) (turnHeading k) slow (turnYaw k))
      , vehicle 2 (bAheadX k, rightY) Build.east slow straight ]
      (threeLaneRoad Build.west) []

/-- The third user of `forbid_gap`: in the centre lane ahead of a, closing to within the bound. -/
private def inTheWay (k : Nat) : List RoadUser :=
  [ vehicle 3 (m (60 * Int.ofNat k + 2), centreY) Build.east middling straight ]

private def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (w : Timestamp × Timestamp := (6000, 12000)) : Scenario :=
  { name := name
    rule := "NRS_484B_223_2_o2"
    trace := τ
    reading := {}
    manifest := Build.manifest absent
    grounding := [("a", 1), ("b", 2)]
    expected := expected
    window := some w }

def scenarios : List Scenario :=
  [ -- a holds the centre lane of three with nothing to excuse it: no pass, no signalled left
    -- turn, and a centre lane recorded against a's direction with no sign allocating it.
    witness "forbid" (cruiseTrace (threeLaneRoad Build.west) []) .violated
    -- the same carriageway; a is in the centre lane only after it has passed b, the lane records
    -- a sight distance the model finds adequate, and no user is in the centre lane.
  , witness "permit" (passTrace (fun _ => [])) .compliant
    -- two marked lanes, not three: the division the trigger names never arises.
  , witness "idle" twoLaneTrace .notApplicable
    -- the `forbid` scene with `rel.occupies` unobserved: whether a's footprint overlaps the
    -- centre lane, and whether a is upon a roadway at all, cannot be decided.
  , witness "blind" (cruiseTrace (threeLaneRoad Build.west) []) (.unknown []) ["rel.occupies"]
    -- the pass of `permit`, but a third vehicle in the centre lane closes to within the bound
    -- `p.ttc_bound`: the lane is not clear of traffic and the exception does not hold.
  , witness "forbid_gap" (passTrace inTheWay) .violated
    -- the centre lane is recorded in a's direction and a regulatory sign governs it: (c).
  , witness "permit_allocated"
      (cruiseTrace (threeLaneRoad Build.east) [Build.sign 1 .regulatorySign [3]]) .compliant
    -- a shows the left indicator in the centre lane and turns left within `p.turn_window`: (b).
  , witness "permit_turn" turnTrace .compliant [] (12000, 12000) ]

end TrafficSpecWitness.NRS_484B_223_2_o2
