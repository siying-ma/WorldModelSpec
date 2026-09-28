/-
  Witnesses for NRS_484B_213_1.

  One carriageway for every scene: a roadway 7.2 m wide about y = 0, an eastbound lane south of
  the centre (region 11, direction east, left neighbour 12), a westbound lane north of it
  (region 12, direction west, left neighbour 11), and a centre line 0.4 m wide over y = 0
  (region 13). Every lane and the roadway carry a recorded sight distance of 600 m, well beyond
  the 154 m the subject's speed asks of the stopping-distance model.

  Three bodies, each 3.4 m by 1.7 m: the subject (track 1, eastbound at 25 m/s), the vehicle it
  passes (track 2, eastbound at 15 m/s in the eastbound lane at y = −2.7 m) and, in the `forbid`
  scene only, a vehicle closing head-on (track 3, westbound at 25 m/s in the westbound lane).

  The pass runs over six observations one second apart. At k = 0 the subject is behind, right of
  the centre; from k = 1 to k = 4 it rides at y = +0.9 m, its body over the centre line and in
  the westbound lane; at k = 5 it is back in its own lane. The overtaking trigger holds from
  k = 4, the first observation at which the passed vehicle is behind, so k = 4 is the instant at
  which both standards are asked, and every figure here is the witness's own.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_213_1
import TrafficSpec.Core.Builders

namespace TrafficSpecWitness.NRS_484B_213_1

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: v ↦ 1, overtaken ↦ 2

/-- Half-length, half-width, half-height of every body in these scenes. -/
private def body : Q × Q × Q := (cm 170, cm 85, cm 75)

/-- The visible distance recorded for the carriageway. -/
private def sight : Q := m 600

private def roadway : Structure :=
  { Build.rect 10 .roadway (m (-200)) (cm (-360)) (m 400) (cm 360) with sightDistance := some sight }
private def eastboundLane : Structure :=
  { Build.lane 11 [(m (-200), cm (-360)), (m 400, cm (-360)), (m 400, Q.zero), (m (-200), Q.zero)]
      Build.east (some 12) none with sightDistance := some sight }
private def westboundLane : Structure :=
  { Build.lane 12 [(m (-200), Q.zero), (m 400, Q.zero), (m 400, cm 360), (m (-200), cm 360)]
      Build.west (some 11) none with sightDistance := some sight }
private def centreLine : Structure :=
  Build.rect 13 .centreLine (m (-200)) (cm (-20)) (m 400) (cm 20)

private def carriageway : List Structure := [roadway, eastboundLane, westboundLane, centreLine]

/-- The subject: right of the centre at the first and last observation, over the line between. -/
private def subject (k : Nat) : RoadUser :=
  let y := if k == 0 || k == 5 then cm (-180) else cm 90
  Build.user 1 [.motorVehicle] (m (25 * (k : Int)), y) Build.east (Units.metresPerSecond 25) body
    (some (m (25 * (k : Int))))

/-- The vehicle passed, in the eastbound lane throughout. -/
private def passed (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (30 + 15 * (k : Int)), cm (-270)) Build.east
    (Units.metresPerSecond 15) body (some (m (15 * (k : Int))))

/-- The vehicle closing head-on in the westbound lane: 40 m ahead of the subject at k = 4. -/
private def closing (k : Nat) : RoadUser :=
  Build.user 3 [.motorVehicle] (m (240 - 25 * (k : Int)), cm 180) Build.west
    (Units.metresPerSecond 25) body (some (m (25 * (k : Int))))

private def passOccupancy (k : Nat) (oncoming : Bool) : List (TrackId × RegionId) :=
  (if k == 0 || k == 5 then [(1, 11)] else [(1, 12), (1, 13)])
    ++ [(1, 10), (2, 10), (2, 11)] ++ (if oncoming then [(3, 10), (3, 12)] else [])

private def passScene (oncoming : Bool) (k : Nat) (t : Timestamp) : Scene :=
  Build.scene t (some 1)
    ([subject k, passed k] ++ (if oncoming then [closing k] else []))
    carriageway [] (some (passOccupancy k oncoming))

/-- `forbid` (violated): A two-lane two-way highway. The subject pulls left of the centre line to
    pass a slower vehicle while an oncoming vehicle closes head-on, 40 m ahead at k = 4 and
    0.8 s from conflict — far inside the horizon, so the left side is not free of oncoming
    traffic. The node's narrative also has the visible distance short; here it is kept adequate,
    so that the oncoming traffic alone decides the episode (see `task_result.md`). -/
private def forbidTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) (passScene true)

/-- `permit` (compliant): The same highway, straight and empty far ahead: the subject crosses the centre line, passes the slower vehicle and returns, with no oncoming user within the projection horizon and every time to conflict above the bound. -/
private def permitTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) (passScene false)

/-- `idle` (not_applicable): The same highway; the subject stays right of the centre line for the whole trace and never comes alongside the vehicle ahead, so the overtaking trigger never holds. -/
private def idleTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (20 * (k : Int)), cm (-180)) Build.east
          (Units.metresPerSecond 20) body (some (m (20 * (k : Int))))
      , Build.user 2 [.motorVehicle] (m (100 + 15 * (k : Int)), cm (-270)) Build.east
          (Units.metresPerSecond 15) body (some (m (15 * (k : Int)))) ]
      carriageway [] (some [(1, 10), (1, 11), (2, 10), (2, 11)])

/-- `blind` (unknown): The pass of the `permit` scene with the source declaring `st.sight_distance` absent: how far ahead the road is visible from the subject's position is not observed, so the sufficient-distance limb of a6 cannot be decided and the rule reports unknown rather than compliance. -/
private def blindTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) (passScene false)

private def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_213_1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1), ("overtaken", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.sight_distance"] ]

end TrafficSpecWitness.NRS_484B_213_1
