/-
  Witnesses for NRS_484B_257_1_o2.

  One crossroads in every scene. Two highway regions meet: the east–west way (region 1,
  x ∈ [-120, 120], y ∈ [-8, 8]) the subject approaches on, and the north–south through highway
  (region 2, x ∈ [-8, 8], y ∈ [-120, 120]); the junction they form is the intersection region 3,
  x ∈ [-8, 8], y ∈ [-8, 8]. The subject's approach is region 4 — a lane from the west,
  x ∈ [-120, -8], y ∈ [-8, 0], which runs into region 3 and lies on way 1 — carried as a region of
  kind roadway instead in `branch_8`. The crossing way's approaches are region 5 from the south
  (x ∈ [0, 8], y ∈ [-120, -8], a lane, a reserved bus lane in `branch_7`) and region 6 from the
  north (x ∈ [-8, 0], y ∈ [8, 120]), both running into region 3 and lying on way 2. `branch_6` adds
  region 7, a roadway covering the whole east–west corridor, which the subject's footprint overlaps
  throughout; `branch_9` carries a neighbouring junction (region 8, x ∈ [-40, -24]) with its own
  signed approach (region 7, x ∈ [-120, -40]) and an unsigned second approach (region 4,
  x ∈ [-24, -8]).

  The subject is track 1, a passenger car 4 m long and 1.8 m wide (half-extents 2 m, 0.9 m,
  0.75 m); every other car is the same body and the bus of `branch_7` is 12 m long and 2.6 m wide.
  Each scene is observed six times, three seconds apart. On the standard approach the subject runs
  due east at y = -4 m, at 10 m/s from x = -108 m to x = -48 m (observations 0 to 2), stands halted
  at x = -18 m clear of the junction (observation 3), and enters at the entry speed its scene
  names, so that it stands inside the junction at observations 4 and 5; its cumulative path length
  is 30 m per observation to 90 m at the halt, so that at every instant a witness speaks about the
  halt and the whole of the signed approach lie within the sixty metres of path behind and the
  twelve seconds of time behind reach back to an observed instant. `branch_2` turns north inside
  the junction, `branch_3` never halts but slows to 2 m/s on its approach, and `branch_9` passes
  the neighbouring junction between the second and third observations.

  Every figure here is the witness's own and appears nowhere in the rule; the geometry is built to
  break or keep each bound of the run's reading by a clear margin (p.halt_speed_tolerance 0.2 m/s,
  p.speed_resolution 0.2 m/s, p.yield_approach_speed 4 m/s, p.stop_approach_lookback 60 m,
  p.stop_approach_window 12 s, p.yield_horizon 4 s, p.yield_clearance 6 m, p.hazard_horizon 5 s,
  p.hazard_clearance 8 m).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

/-- The observation index as a quantity. -/
def step (k : Nat) : Q := Q.ofInt (Int.ofNat k)
/-- The three seconds between two observations. -/
def tick : Q := Units.seconds 3

/-- A passenger car's half-extents: a body 4 m long and 1.8 m wide. -/
def carBody : Q × Q × Q := (m 2, cm 90, cm 75)
/-- A bus's half-extents: a body 12 m long and 2.6 m wide. -/
def busBody : Q × Q × Q := (m 6, cm 130, cm 160)

-- ---------------------------------------------------------------------------------------------
-- The ground
-- ---------------------------------------------------------------------------------------------

/-- A travel region of a kind: rectangular, running into the junction it is an approach to, and
    lying on one way. -/
def travelRect (id : RegionId) (kind : StructureKind) (x0 y0 x1 y1 : Q) (dir : Vec)
    (into : Option RegionId) (way : RegionId) : Structure :=
  { Build.rect id kind x0 y0 x1 y1 with
      lane := some { direction := some dir, entersIntersection := into }
      ways := some [way] }

/-- The east–west way the subject approaches on. -/
def wayEW : Structure := Build.rect 1 .highway (m (-120)) (m (-8)) (m 120) (m 8)
/-- The north–south through highway. -/
def wayNS : Structure := Build.rect 2 .highway (m (-8)) (m (-120)) (m 8) (m 120)
/-- The junction the two ways form. -/
def junction : Structure := Build.rect 3 .intersection (m (-8)) (m (-8)) (m 8) (m 8)
/-- The subject's approach, a lane from the west. -/
def approachLane : Structure :=
  travelRect 4 .lane (m (-120)) (m (-8)) (m (-8)) Q.zero Build.east (some 3) 1
/-- The same approach carried as a roadway region. -/
def approachRoadway : Structure :=
  travelRect 4 .roadway (m (-120)) (m (-8)) (m (-8)) Q.zero Build.east (some 3) 1
/-- The crossing way's approach from the south. -/
def southLane : Structure :=
  travelRect 5 .lane Q.zero (m (-120)) (m 8) (m (-8)) Build.north (some 3) 2
/-- The same approach carried as a reserved bus lane. -/
def southBusLane : Structure :=
  { travelRect 5 .reservedLane Q.zero (m (-120)) (m 8) (m (-8)) Build.north (some 3) 2 with
      reservedClass := some .bus }
/-- The crossing way's approach from the north. -/
def northLane : Structure :=
  travelRect 6 .lane (m (-8)) (m 8) Q.zero (m 120) Build.south (some 3) 2
/-- A roadway covering the whole east–west corridor, junction included. -/
def officerRoadway : Structure :=
  travelRect 7 .roadway (m (-120)) (m (-8)) (m 120) (m 8) Build.east (some 3) 1
/-- The neighbouring junction of `branch_9`. -/
def firstJunction : Structure := Build.rect 8 .intersection (m (-40)) (m (-8)) (m (-24)) (m 8)
/-- Its signed approach. -/
def firstLane : Structure :=
  travelRect 7 .lane (m (-120)) (m (-8)) (m (-40)) Q.zero Build.east (some 8) 1
/-- The unsigned approach to the second junction of `branch_9`. -/
def secondLane : Structure :=
  travelRect 4 .lane (m (-24)) (m (-8)) (m (-8)) Q.zero Build.east (some 3) 1

/-- The standard ground: the two ways, the junction and two approaches. -/
def ground : List Structure := [wayEW, wayNS, junction, approachLane, southLane]

-- ---------------------------------------------------------------------------------------------
-- The devices
-- ---------------------------------------------------------------------------------------------

/-- A stop sign governing the subject's approach region. -/
def stopSign : Device := Build.sign 11 .stopSign [4]
/-- A stop sign governing the approach to the neighbouring junction. -/
def stopSignFirst : Device := Build.sign 11 .stopSign [7]
/-- A yield sign governing the junction region itself. -/
def yieldSign : Device := Build.sign 12 .yieldSign [3]
/-- A signal head over the subject's approach, uncovered, not inoperative, showing a green ball. -/
def greenHead : Device :=
  { Build.signal 13 [4] [.circularGreen] with uncovered := some true, inoperative := some false }
/-- A signal head over the subject's approach whose faces are covered: the uncovered attribute is
    false of it, it is not reported inoperative, and no indication — `dark` included — is shown. -/
def coveredHead : Device := { Build.signal 15 [4] [] with uncovered := some false }
/-- A police officer directing traffic, governing the roadway region the subject is on. -/
def officer : Device :=
  { Build.device 14 .humanDirection [7] with
      humanRole := some .policeOfficer, humanIndication := some .proceed }

-- ---------------------------------------------------------------------------------------------
-- The bodies
-- ---------------------------------------------------------------------------------------------

/-- The subject on the standard approach: 10 m/s to x = -48 m, halted at x = -18 m, then the entry
    at `entry` m/s from the fourth observation. -/
def stdSubject (entry : Q) (k : Nat) : RoadUser :=
  let x := if k ≤ 2 then Q.add (m (-108)) (Q.mul (m 30) (step k))
           else if k ≤ 3 then m (-18)
           else Q.add (m (-18)) (Q.mul entry (Q.mul tick (step (k - 3))))
  let speed := if k ≤ 2 then mps 10 else if k ≤ 3 then Q.zero else entry
  let path := if k ≤ 2 then Q.mul (m 30) (step k)
              else if k ≤ 3 then m 90
              else Q.add (m 90) (Q.mul entry (Q.mul tick (step (k - 3))))
  Build.user 1 [.motorVehicle] (x, m (-4)) Build.east speed carBody (some path)

/-- A body in uniform motion: at `p0` at the first observation, advancing along `heading` at
    `speed` through the three seconds between observations. -/
def mover (track : TrackId) (classes : List RoadUserClass) (body : Q × Q × Q)
    (p0 : Vec) (heading : Vec) (speed : Q) (k : Nat) : RoadUser :=
  let d := Q.mul speed (Q.mul tick (step k))
  Build.user track classes (Q.add p0.1 (Q.mul heading.1 d), Q.add p0.2 (Q.mul heading.2 d))
    heading speed body

/-- The crossing car of the `forbid` scene: due north at 1 m/s on the southern approach, reaching
    the subject's course inside the junction at the last observation. -/
def crossingCar (k : Nat) : RoadUser :=
  mover 2 [.motorVehicle] carBody (m 4, cm (-1950)) Build.north (mps 1) k

/-- The bus of `branch_7`, on the same course. -/
def crossingBus (k : Nat) : RoadUser :=
  mover 2 [.bus] busBody (m 4, cm (-1950)) Build.north (mps 1) k

/-- The car of `branch_1`: due north at 15 m/s, forty metres short of the junction when the subject
    enters it. -/
def hazardCar (k : Nat) : RoadUser :=
  mover 2 [.motorVehicle] carBody (m 4, m (-224)) Build.north (mps 15) k

/-- The car of `branch_2`: due north at 3 m/s, through the junction and out beyond it. -/
def departedCar (k : Nat) : RoadUser :=
  mover 2 [.motorVehicle] carBody (m 4, cm (-3550)) Build.north (mps 3) k

/-- The car of `branch_3`: due south at 3 m/s on the northern approach. -/
def southboundCar (k : Nat) : RoadUser :=
  mover 2 [.motorVehicle] carBody (m (-4), cm 4050) Build.south (mps 3) k

/-- The car of `branch_4`: due north at 10 m/s, in the junction as the subject enters it and
    drawing away. -/
def departingCar (k : Nat) : RoadUser :=
  mover 2 [.motorVehicle] carBody (m 4, m (-114)) Build.north (mps 10) k

/-- The car of `blind`: due north at 4 m/s, in the far side of the junction when the subject
    enters. Its outline is observed while it comes up the crossing way, and from the fourth
    observation the source has its centre and its velocity but no outline. -/
def offCourseCar (k : Nat) : RoadUser :=
  let u := mover 2 [.motorVehicle] carBody (m 4, m (-42)) Build.north (mps 4) k
  if k ≤ 3 then u else Build.withKin u fun kin => { kin with extent := none }

/-- The car of `branch_5`: halted at the entrance of the crossing way, moving off into the junction
    at 5 m/s at the fifth observation. -/
def waitingCar (k : Nat) : RoadUser :=
  if k ≤ 3 then
    Build.user 2 [.motorVehicle] (m 4, cm (-2150)) Build.north Q.zero carBody
  else
    Build.user 2 [.motorVehicle]
      (m 4, Q.add (cm (-2150)) (Q.mul (mps 5) (Q.mul tick (step (k - 3))))) Build.north (mps 5)
      carBody

/-- The subject of `branch_2`: the standard approach and halt, then the entry at 6 m/s and a turn
    north inside the junction, its footprint still overlapping it at the last observation. -/
def turningSubject (k : Nat) : RoadUser :=
  if k ≤ 3 then stdSubject (mps 6) k
  else if k ≤ 4 then
    Build.user 1 [.motorVehicle] (m (-6), m (-4)) Build.east (mps 6) carBody (some (m 102))
  else
    Build.user 1 [.motorVehicle] (m 4, m 6) Build.north (mps 6) carBody (some (m 120))

/-- The subject of `branch_3`: 10 m/s to x = -48 m, then 2 m/s the rest of the way, with no halt. -/
def slowingSubject (k : Nat) : RoadUser :=
  let x := if k ≤ 2 then Q.add (m (-108)) (Q.mul (m 30) (step k))
           else Q.add (m (-18)) (Q.mul (m 6) (step (k - 3)))
  let speed := if k ≤ 2 then mps 10 else mps 2
  let path := if k ≤ 2 then Q.mul (m 30) (step k)
              else Q.add (m 90) (Q.mul (m 6) (step (k - 3)))
  Build.user 1 [.motorVehicle] (x, m (-4)) Build.east speed carBody (some path)

-- ---------------------------------------------------------------------------------------------
-- The instants
-- ---------------------------------------------------------------------------------------------

/-- Six observations, three seconds apart. -/
def traceOf (structures : List Structure) (devices : List Device)
    (users : Nat → List RoadUser) : Trace :=
  Build.trace 6 0 tick fun k t => Build.scene t (some 1) (users k) structures devices

-- Binders ↦ tracks: v ↦ 1

/-- `forbid` (violated): A stop sign governs the subject's approach lane, which runs into an intersection; no officer and no signal head at all is in the scene. The subject halts at its entrance, its footprint overlapping no intersection region, then enters at 4 m/s. Another car came to the junction on a lane of the crossing way and is within the intersection region, and at the last observation the two bodies touch. The subject has not yielded the right-of-way to a vehicle which has entered the intersection from the through highway. -/
def forbidTrace : Trace :=
  traceOf ground [stopSign] fun k => [stdSubject (mps 4) k, crossingCar k]

/-- `permit` (compliant): The same stop-signed approach and the same halt at its entrance, and no other road user is present in the scene at all. The subject enters at 4 m/s and crosses the junction. There is no vehicle that has entered from the through highway and none approaching on it, so the duty is kept. This is the scene with no second party, and the rule decides it without one. -/
def permitTrace : Trace :=
  traceOf ground [stopSign] fun k => [stdSubject (mps 4) k]

/-- `idle` (not_applicable): The same approach and the same crossing car within the junction, but a signal head that is uncovered and is not inoperative displays a circular green over the subject's approach lane, and the subject enters at 4 m/s and strikes the other car. Traffic is being controlled by a traffic-control signal, so this duty does not apply. -/
def idleTrace : Trace :=
  traceOf ground [stopSign, greenHead] fun k => [stdSubject (mps 4) k, crossingCar k]

/-- `blind` (unknown): The subject halts at its stop-signed entrance, enters at 4 m/s, and a car that came in on the crossing way is within the intersection region well off the subject's course, the two centres not approaching within the conflict horizon, on a source that reports nothing of the bodies' contact. It mapped that car's occupancy and its outline while the car came up the crossing way and into the junction - which is what the window behind reads - and from the moment the subject enters it has the car's centre and velocity but neither its outline nor its occupancy, so the contact between the two bodies is not computed from them either. Whether the subject's body has met the other's is therefore unobserved, and the rule reports unknown rather than compliance. -/
def blindTrace : Trace :=
  Build.trace 6 0 tick fun k t =>
    let users := [stdSubject (mps 4) k, offCourseCar k]
    let observed := if k ≤ 3 then users else [stdSubject (mps 4) k]
    { Build.scene t (some 1) users ground [stopSign]
        (occupies := some (Build.occupancyFromGeometry observed ground)) with
      occupancyObserved := observed.map (·.track) }

/-- `branch_1` (violated): The same stop-signed approach and halt. The subject enters at 4 m/s while a car approaches at 15 m/s on a lane of the crossing way, forty metres off and not yet in the junction; under constant velocities the two centres close to under a metre within the hazard horizon and within the conflict horizon. The approaching car is so close as to constitute an immediate hazard and the subject has taken its precedence. -/
def branch_1Trace : Trace :=
  traceOf ground [stopSign] fun k => [stdSubject (mps 4) k, hazardCar k]

/-- `branch_2` (violated): A car came in on the crossing way, passed through the junction and now lies just beyond it on that way at 3 m/s; its footprint no longer overlaps the intersection region or any region of its approach, but it overlapped both within the window behind. The subject, which halted at its stop-signed entrance, turns into the crossing way at 6 m/s while its own footprint still overlaps the junction and strikes that car. The vehicle has entered the intersection from the through highway, and the subject has not yielded. -/
def branch_2Trace : Trace :=
  traceOf ground [stopSign] fun k => [turningSubject k, departedCar k]

/-- `branch_3` (violated): A yield sign governs the intersection region itself rather than the subject's approach lane. The subject does not halt but slows to 2 m/s on its approach, at or below the yield-approach speed, while its footprint overlaps no intersection region, then enters at 2 m/s and strikes a car that came in on the crossing way from the north and is within the junction. The slowing answers 'in the event of a yield sign, slowed or stopped', so the duty is engaged, and it is broken. -/
def branch_3Trace : Trace :=
  traceOf [wayEW, wayNS, junction, approachLane, northLane] [yieldSign]
    fun k => [slowingSubject k, southboundCar k]

/-- `branch_4` (compliant): The same stop-signed approach and halt. The subject enters at 4 m/s; a car that came in on the crossing way is within the intersection region but is drawing away on a divergent course, so the two bodies never touch and their centres, under constant velocities, never approach at all within the conflict horizon. The right-of-way has been yielded. -/
def branch_4Trace : Trace :=
  traceOf ground [stopSign] fun k => [stdSubject (mps 4) k, departingCar k]

/-- `branch_5` (violated): A stop sign governs the subject's approach lane and a car stands halted at the entrance of the crossing way. The subject halts, enters at 5 m/s, and the other car moves off into the junction from its own entrance: their bodies do not touch, but under constant velocities the two centres close to about three metres within the conflict horizon while the subject's footprint still overlaps the junction, and that car came in on a lane of the way the subject's approach does not lie on and is within the intersection region. The subject has taken a precedence it owed. -/
def branch_5Trace : Trace :=
  traceOf ground [stopSign] fun k => [stdSubject (mps 5) k, waitingCar k]

/-- `branch_6` (not_applicable): The forbid scene exactly - the stop-signed approach lane, the halt, the crossing car within the junction and the contact - with a police officer directing traffic who governs neither the approach lane nor the intersection region but the roadway region the subject's footprint overlaps throughout, giving it a 'proceed' indication. Traffic affecting this subject is being controlled by a police officer, so the duty does not arise, and the route of the exception that reads a travel region the subject occupies decides it. -/
def branch_6Trace : Trace :=
  traceOf (ground ++ [officerRoadway]) [stopSign, officer]
    fun k => [stdSubject (mps 4) k, crossingCar k]

/-- `branch_7` (violated): The subject halts at its stop-signed approach lane and enters the junction at 4 m/s. The other road user is a bus which came to the same junction on a reserved bus lane of the crossing way - a region of kind reserved lane that runs into the junction and lies on a way the subject's approach does not lie on - and which is within the intersection region when the two bodies touch. The bus has entered the intersection from the through highway, and the subject has not yielded; only the reading of the other vehicle's approach as a travel region of any kind reaches it. -/
def branch_7Trace : Trace :=
  traceOf [wayEW, wayNS, junction, approachLane, southBusLane] [stopSign]
    fun k => [stdSubject (mps 4) k, crossingBus k]

/-- `branch_8` (violated): The approach the subject comes to this junction on is carried by the scene as a roadway region rather than as a region of kind lane: that roadway runs into the intersection, the subject's footprint overlaps it throughout the approach, and the stop sign governs it. The subject halts clear of the junction, enters at 4 m/s and strikes a car that came in on a lane of the crossing way and is within the intersection region. Proper signs have been erected facing the traffic this approach carries, so the duty is engaged and broken; the reading of the approach as a travel region of any kind, and not of kind lane alone, decides it. -/
def branch_8Trace : Trace :=
  traceOf [wayEW, wayNS, junction, approachRoadway, southLane] [stopSign]
    fun k => [stdSubject (mps 4) k, crossingCar k]

/-- `branch_9` (not_applicable): The only stop sign of the scene governs a lane that runs into a neighbouring junction, through which the subject passed earlier on the stretch of path behind. The subject then halts on an approach to a second junction that no stop sign and no yield sign governs, enters that junction at 4 m/s and strikes a car which came to it on a lane of the crossing way. No proper signs have been erected for this approach - the sign the subject passed governs no region running into this junction and not this junction itself - so the duty does not arise here, although the subject occupied the signed region within the look-back. -/
def branch_9Trace : Trace :=
  traceOf [wayEW, wayNS, junction, secondLane, southLane, firstLane, firstJunction]
    [stopSignFirst] fun k => [stdSubject (mps 4) k, crossingCar k]

/-- `branch_10` (violated): The forbid scene exactly - the stop-signed approach lane, the halt, the crossing car within the junction and the contact - with the scene's only signal head governing that approach lane and its faces covered: the source reports the head's uncovered attribute false, does not report it inoperative, and reports no 'dark' state of it. A covered head shows no face to this traffic and alternately directs nothing, so traffic is not being controlled by a traffic-control signal; the duty arises and is broken. Only the reading that requires a head to be uncovered before it lifts the duty reaches this scene. -/
def branch_10Trace : Trace :=
  traceOf ground [stopSign, coveredHead] fun k => [stdSubject (mps 4) k, crossingCar k]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_257_1_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    window := window }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.contact"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .notApplicable
  , witness "branch_10" branch_10Trace .violated ]

end TrafficSpecWitness.NRS_484B_257_1_o2
