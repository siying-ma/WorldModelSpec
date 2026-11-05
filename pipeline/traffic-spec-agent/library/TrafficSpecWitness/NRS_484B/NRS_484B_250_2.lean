/-
  Witnesses for NRS_484B_250_2.

  The geometry. Two crossroads are built, both with the junction region 1, the square
  (-6, -6) … (6, 6) metres, and both in the world frame (+x east, +y north).

  * `crossroads` — two mapped highways meeting: highway 10 running east-west and highway 11
    running north-south. The subject comes in east-bound on lane 2 (the stretch west of the
    junction, direction east, entrance end the junction, lying on highway 10); the second vehicle
    comes in north-bound on lane 3 (south of the junction, direction north, highway 11), or
    south-bound on lane 4 (north of the junction, highway 11), or west-bound on lane 5 (east of
    the junction, highway 10, the one segment that lies on the subject's own highway).
  * `headOnJunction` — the junction where two different highways meet head-on: highway 11 ends at
    it from the south, highway 12 continues from the north. The subject comes in north-bound on
    lane 7 (west half, highway 11), the other south-bound on lane 8 (east half, highway 12), so
    the two carriers lie on different highways and carry opposed designated directions.

  The bodies are passenger cars, 4 m by 2 m (half-extents 2 m, 1 m, 1 m), with yaw rate observed
  as zero: none of them changes course. Occupancy is stated rather than taken from the reference
  point, since a car at the junction edge overlaps both its approach and the junction.

  The instants. Each trace is three to nine observations one second apart from 30 s, padded with
  twelve seconds of the first scene and four of the last, so that the window behind an entry (the
  simultaneity window, and the ten seconds a change of course is read over) is covered rather than
  truncated, and the window ahead of it likewise. The subject's entry into the junction is the
  second observation of the unpadded part in every trace but `branch_7`, where it is the third.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

/-- A point of the world frame, in centimetres. -/
def pt (x y : Int) : Vec := (cm x, cm y)

-- Binders ↦ tracks: subject ↦ 1

/-- A passenger car whose course is observed as unchanging. -/
def car (track : TrackId) (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.withKin (Build.user track [.motorVehicle] pos heading speed (m 2, m 1, m 1))
    (fun k => { k with yawRate := some Q.zero })

-- The crossroads of highway 10 (east-west) and highway 11 (north-south).
def junctionOfTwoHighways : Structure :=
  { Build.rect 1 .intersection (m (-6)) (m (-6)) (m 6) (m 6) with ways := some [10, 11] }
def laneWestbound : Structure :=
  { Build.lane 2 [(m (-200), m (-6)), (m (-6), m (-6)), (m (-6), m 0), (m (-200), m 0)]
      Build.east (enters := some 1) with ways := some [10] }
def laneFromSouth : Structure :=
  { Build.lane 3 [(m 0, m (-200)), (m 6, m (-200)), (m 6, m (-6)), (m 0, m (-6))]
      Build.north (enters := some 1) with ways := some [11] }
def laneFromNorth : Structure :=
  { Build.lane 4 [(m (-6), m 6), (m 0, m 6), (m 0, m 200), (m (-6), m 200)]
      Build.south (enters := some 1) with ways := some [11] }
def laneFromEast : Structure :=
  { Build.lane 5 [(m 6, m 0), (m 200, m 0), (m 200, m 6), (m 6, m 6)]
      Build.west (enters := some 1) with ways := some [10] }
def highwayEastWest : Structure := Build.rect 10 .highway (m (-200)) (m (-6)) (m 200) (m 6)
def highwayNorthSouth : Structure := Build.rect 11 .highway (m (-6)) (m (-200)) (m 6) (m 200)

def crossroads : List Structure :=
  [junctionOfTwoHighways, laneWestbound, laneFromSouth, highwayEastWest, highwayNorthSouth]
def crossroadsFromNorth : List Structure :=
  [junctionOfTwoHighways, laneWestbound, laneFromNorth, highwayEastWest, highwayNorthSouth]
def crossroadsOneHighway : List Structure :=
  [junctionOfTwoHighways, laneWestbound, laneFromEast, highwayEastWest, highwayNorthSouth]

-- The junction where highway 11 (from the south) meets highway 12 (from the north) head-on.
def junctionHeadOn : Structure :=
  { Build.rect 1 .intersection (m (-6)) (m (-6)) (m 6) (m 6) with ways := some [11, 12] }
def laneNorthbound : Structure :=
  { Build.lane 7 [(m (-6), m (-200)), (m 0, m (-200)), (m 0, m (-6)), (m (-6), m (-6))]
      Build.north (enters := some 1) with ways := some [11] }
def laneSouthbound : Structure :=
  { Build.lane 8 [(m 0, m 6), (m 6, m 6), (m 6, m 200), (m 0, m 200)]
      Build.south (enters := some 1) with ways := some [12] }
def highwayFromSouth : Structure := Build.rect 11 .highway (m (-6)) (m (-200)) (m 6) (m 0)
def highwayFromNorth : Structure := Build.rect 12 .highway (m (-6)) (m 0) (m 6) (m 200)

def headOnJunction : List Structure :=
  [junctionHeadOn, laneNorthbound, laneSouthbound, highwayFromSouth, highwayFromNorth]

/-- The source's plan for the vehicle at the junction: no turn to the left there. -/
def noTurn (track : TrackId) : DeclaredIntent :=
  { vehicle := track, target := 1, values := [("int.left_turn", false)] }
/-- The source's plan for the vehicle at the junction: a turn to the left there. -/
def turnsLeft (track : TrackId) : DeclaredIntent :=
  { vehicle := track, target := 1, values := [("int.left_turn", true)] }

def neitherTurns : List DeclaredIntent := [noTurn 1, noTurn 2]
def otherTurnsLeft : List DeclaredIntent := [noTurn 1, turnsLeft 2]

def sceneOf (structures : List Structure) (devices : List Device) (intents : List DeclaredIntent)
    (t : Timestamp) (users : List RoadUser) (occupies : List (TrackId × RegionId)) : Scene :=
  Build.scene t (some 1) users structures devices (occupies := some occupies) (intents := intents)

/-- Twelve seconds of the first scene before and four of the last after. -/
def padded (τ : Trace) : Trace := Build.pad τ (Units.seconds 12) (Units.seconds 4) (Units.seconds 1)

-- ------------------------------------------------------------------------------------------
-- The crossroads: the subject east-bound at 10 m/s, the other north-bound at 10 m/s, both
-- footprints first overlapping the junction at the second observation.
-- ------------------------------------------------------------------------------------------
def crossTrace (devices : List Device) : Trace :=
  padded <| Build.trace 3 30000 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf crossroads devices neitherTurns t
             [car 1 (pt (-1750) (-300)) Build.east (mps 10),
              car 2 (pt 200 (-1750)) Build.north (mps 10)]
             [(1, 2), (1, 10), (2, 3), (2, 11)]
    | 1 => sceneOf crossroads devices neitherTurns t
             [car 1 (pt (-750) (-300)) Build.east (mps 10),
              car 2 (pt 200 (-750)) Build.north (mps 10)]
             [(1, 2), (1, 1), (1, 10), (2, 3), (2, 1), (2, 11)]
    | _ => sceneOf crossroads devices neitherTurns t
             [car 1 (pt 250 (-300)) Build.east (mps 10),
              car 2 (pt 200 250) Build.north (mps 10)]
             [(1, 1), (1, 10), (2, 1), (2, 11)]

/-- `forbid` (violated): Two cars reach an unsignalised crossroads of two mapped highways. The subject comes in on the segment of the east-west highway, the other on the segment of the north-south highway; both footprints first overlap the junction region at the same observation. The other car bears to the subject's right. Neither approach carries an opposed direction to the other and no left-turn intention is declared. The subject holds 10 m/s straight on, and under the two velocities the centres approach within the horizon to a distance below the minimum clearance. -/
def forbidTrace : Trace := crossTrace []

/-- `permit` (compliant): The same crossroads and the same two entries within the window, the other car again on the subject's right, but the subject has braked to 1 m/s at the junction edge: under the velocities observed the centres' closest approach within the horizon stays well above the minimum clearance, and the other car passes in front of it. -/
def permitTrace : Trace :=
  padded <| Build.trace 3 30000 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf crossroads [] neitherTurns t
             [car 1 (pt (-850) (-300)) Build.east (mps 1),
              car 2 (pt 200 (-1750)) Build.north (mps 10)]
             [(1, 2), (1, 10), (2, 3), (2, 11)]
    | 1 => sceneOf crossroads [] neitherTurns t
             [car 1 (pt (-750) (-300)) Build.east (mps 1),
              car 2 (pt 200 (-750)) Build.north (mps 10)]
             [(1, 2), (1, 1), (1, 10), (2, 3), (2, 1), (2, 11)]
    | _ => sceneOf crossroads [] neitherTurns t
             [car 1 (pt (-650) (-300)) Build.east (mps 1),
              car 2 (pt 200 250) Build.north (mps 10)]
             [(1, 2), (1, 1), (1, 10), (2, 1), (2, 11)]

/-- `idle` (not_applicable): The subject enters the same junction with no other road user anywhere in the scene, so no second vehicle enters within the window and the duty does not arise; the verdict is decided although the only party present is the subject. -/
def idleTrace : Trace :=
  padded <| Build.trace 3 30000 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf crossroads [] [noTurn 1] t
             [car 1 (pt (-1750) (-300)) Build.east (mps 10)] [(1, 2), (1, 10)]
    | 1 => sceneOf crossroads [] [noTurn 1] t
             [car 1 (pt (-750) (-300)) Build.east (mps 10)] [(1, 2), (1, 1), (1, 10)]
    | _ => sceneOf crossroads [] [noTurn 1] t
             [car 1 (pt 250 (-300)) Build.east (mps 10)] [(1, 1), (1, 10)]

/-- `blind` (unknown): Two cars approach the same crossroads as in the forbid scenario, but the source declares no footprint overlap for any region, so neither the subject's entry into the junction nor the other car's can be decided and the rule reports unknown. -/
def blindTrace : Trace := crossTrace []

/-- `branch_1` (not_applicable): The same simultaneous entry from different highways, but the other vehicle bears to the subject's left, so the subject is the vehicle on the right and this subsection lays no duty on it. -/
def branch_1Trace : Trace :=
  padded <| Build.trace 3 30000 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf crossroadsFromNorth [] neitherTurns t
             [car 1 (pt (-1750) (-300)) Build.east (mps 10),
              car 2 (pt (-300) 1750) Build.south (mps 10)]
             [(1, 2), (1, 10), (2, 4), (2, 11)]
    | 1 => sceneOf crossroadsFromNorth [] neitherTurns t
             [car 1 (pt (-750) (-300)) Build.east (mps 10),
              car 2 (pt (-300) 750) Build.south (mps 10)]
             [(1, 2), (1, 1), (1, 10), (2, 4), (2, 1), (2, 11)]
    | _ => sceneOf crossroadsFromNorth [] neitherTurns t
             [car 1 (pt 250 (-300)) Build.east (mps 10),
              car 2 (pt (-300) (-250)) Build.south (mps 10)]
             [(1, 1), (1, 10), (2, 1), (2, 11)]

/-- `branch_2` (not_applicable): Two cars enter the same junction at the same observation on two segments of one highway that carry opposed designated directions, and the other car has a declared intention to turn left at that junction; the exception for vehicles approaching each other from opposite directions applies and no signal, sign or lane-control device is recorded as governing the junction, so the duty does not arise. (The oncoming car also bears to the subject's left, as an oncoming car on a two-way highway does.) -/
def branch_2Trace : Trace :=
  padded <| Build.trace 3 30000 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf crossroadsOneHighway [] otherTurnsLeft t
             [car 1 (pt (-1750) (-300)) Build.east (mps 10),
              car 2 (pt 1750 300) Build.west (mps 10)]
             [(1, 2), (1, 10), (2, 5), (2, 10)]
    | 1 => sceneOf crossroadsOneHighway [] otherTurnsLeft t
             [car 1 (pt (-750) (-300)) Build.east (mps 10),
              car 2 (pt 750 300) Build.west (mps 10)]
             [(1, 2), (1, 1), (1, 10), (2, 5), (2, 1), (2, 10)]
    | _ => sceneOf crossroadsOneHighway [] otherTurnsLeft t
             [car 1 (pt 250 (-300)) Build.east (mps 10),
              car 2 (pt (-250) 300) Build.west (mps 10)]
             [(1, 1), (1, 10), (2, 1), (2, 10)]

-- The head-on junction of two highways: the subject north-bound, the other south-bound and to
-- its right, both entering at the second observation, their centres passing 3 m apart.
def headOnTrace (intents : List DeclaredIntent) : Trace :=
  padded <| Build.trace 3 30000 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf headOnJunction [] intents t
             [car 1 (pt (-150) (-1750)) Build.north (mps 10),
              car 2 (pt 150 1750) Build.south (mps 10)]
             [(1, 7), (1, 11), (2, 8), (2, 12)]
    | 1 => sceneOf headOnJunction [] intents t
             [car 1 (pt (-150) (-750)) Build.north (mps 10),
              car 2 (pt 150 750) Build.south (mps 10)]
             [(1, 7), (1, 1), (1, 11), (2, 8), (2, 1), (2, 12)]
    | _ => sceneOf headOnJunction [] intents t
             [car 1 (pt (-150) 250) Build.north (mps 10),
              car 2 (pt 150 (-250)) Build.south (mps 10)]
             [(1, 1), (1, 12), (2, 1), (2, 11)]

/-- `branch_3` (not_applicable): Two different highways meet head-on; the subject comes in
    north-bound, the other south-bound and bearing to the subject's right, both entering at the
    same observation. The two approach carriers carry opposed designated directions and the other
    car has a declared intention to turn left at the junction, so the exception applies. -/
def branch_3Trace : Trace := headOnTrace otherTurnsLeft

/-- `branch_4` (violated): The same head-on junction and the same opposed approach directions, but
    neither car intends a left turn there and neither is changing course: the exception does not
    apply, the duty arises, and the centres approach within the horizon to 3 m, below the minimum
    clearance. -/
def branch_4Trace : Trace := headOnTrace neitherTurns

/-- `branch_5` (not_applicable): The forbid scenario with a traffic signal recorded as governing
    the junction itself: the section does not apply at an intersection controlled by an official
    traffic-control device, neither node of subsection 4 applying to the subject. -/
def branch_5Trace : Trace :=
  crossTrace [{ Build.signal 20 [1] [.circularGreen] with
                  uncovered := some true, inoperative := some false }]

/-- `branch_6` (not_applicable): The subject enters the junction as before, but the other car is
    still 10 m short of it and crawling at 2 m/s: it enters five seconds later, outside the
    simultaneity window, so the two entries are not made at approximately the same time. -/
def branch_6Trace : Trace :=
  padded <| Build.trace 9 30000 (Units.seconds 1) fun k t =>
    let subjectX : Int := -1750 + 1000 * (Int.ofNat k)
    let otherY : Int := -1950 + 200 * (Int.ofNat k)
    let subject := car 1 (pt subjectX (-300)) Build.east (mps 10)
    let other := car 2 (pt 200 otherY) Build.north (mps 2)
    let occ : List (TrackId × RegionId) :=
      (if k == 0 then [(1, 2), (1, 10)]
       else if k == 1 then [(1, 2), (1, 1), (1, 10)]
       else if k == 2 then [(1, 1), (1, 10)]
       else [(1, 10)])
      ++ (if k ≤ 5 then [(2, 3), (2, 11)]
          else if k ≤ 7 then [(2, 3), (2, 1), (2, 11)]
          else [(2, 1), (2, 11)])
    sceneOf crossroads [] neitherTurns t [subject, other] occ

/-- `branch_7` (violated): The other car entered the junction one second before the subject, so
    its entry lies in the simultaneity window behind the subject's; it is crossing slowly (3 m/s)
    and still bears to the subject's right, and the centres approach within the horizon to about
    1.3 m. -/
def branch_7Trace : Trace :=
  padded <| Build.trace 6 30000 (Units.seconds 1) fun k t =>
    let subjectX : Int := -2750 + 1000 * (Int.ofNat k)
    let otherY : Int := -1050 + 300 * (Int.ofNat k)
    let subject := car 1 (pt subjectX (-300)) Build.east (mps 10)
    let other := car 2 (pt 200 otherY) Build.north (mps 3)
    let occ : List (TrackId × RegionId) :=
      (if k ≤ 1 then [(1, 2), (1, 10)]
       else if k == 2 then [(1, 2), (1, 1), (1, 10)]
       else if k == 3 then [(1, 1), (1, 10)]
       else [(1, 10)])
      ++ (if k == 0 then [(2, 3), (2, 11)]
          else if k ≤ 2 then [(2, 3), (2, 1), (2, 11)]
          else [(2, 1), (2, 11)])
    sceneOf crossroads [] neitherTurns t [subject, other] occ

/-- `branch_8` … `branch_12` (violated): the forbid scenario with a traffic signal, a stop sign, a
    yield sign, a regulatory sign and a lane-control signal, each recorded as governing the
    subject's approach lane and not the junction. A device governs the junction itself or nothing
    of it, so none of these suspends the section and the duty arises as in `forbid`. -/
def branch_8Trace : Trace :=
  crossTrace [{ Build.signal 20 [2] [.circularGreen] with
                  uncovered := some true, inoperative := some false }]
def branch_9Trace : Trace := crossTrace [Build.sign 21 .stopSign [2]]
def branch_10Trace : Trace := crossTrace [Build.sign 22 .yieldSign [2]]
def branch_11Trace : Trace :=
  crossTrace [{ Build.sign 23 .regulatorySign [2] with code := some .keepRight, conditions := some {} }]
def branch_12Trace : Trace :=
  crossTrace [{ Build.device 24 .laneControlSignal [2] with laneControl := some .greenDownArrow }]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_250_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
      (window := some (30000, 32000))
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .violated
  , witness "branch_11" branch_11Trace .violated
  , witness "branch_12" branch_12Trace .violated ]

end TrafficSpecWitness.NRS_484B_250_2
