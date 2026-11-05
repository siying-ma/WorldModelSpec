/-
  Witnesses for NRS_484B_257_2_o2.

  The map, the same in every scene of every witness: a four-way junction of two minor streets.
  The junction region (10) is the square from (−5, −5) to (5, 5). The south leg's northbound lane
  (11) runs from y = −40 to the junction's south edge, x ∈ [0, 5], its direction north and its
  entrance end the junction. The west leg's eastbound lane (12) runs from x = −60 to the junction's
  west edge, y ∈ [−5, 0], its direction east and its entrance end the junction.

  The subject (track 1) is a car 4.4 m long and 1.8 m wide travelling north along x = 2; the other
  car (track 2) is its twin travelling east along y = −2. A body straddling the junction's edge
  overlaps both the junction and its approach lane, which is how the scenes are written: the
  subject's centre at y = −9 leaves its nose 1.8 m short of the junction, at y = −7 and y = −5 it
  overlaps the junction and still overlaps its lane.

  Stop signs and yield signs govern a lane; the police officer and the traffic signal govern the
  junction itself. Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_2_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_2_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- Half-length, half-width, half-height of a passenger car. -/
def halfCar : Q × Q × Q := (cm 220, cm 90, cm 75)

def halted : Q := Q.zero
def creep : Q := Units.ratio 1 5              -- 0.2 m/s, below the motion tolerance
def slow : Q := Units.metresPerSecond 2
def brisk : Q := Units.metresPerSecond 3
def fast : Q := Units.metresPerSecond 8
def rushing : Q := Units.metresPerSecond 14

def junctionId : RegionId := 10
def laneSouthId : RegionId := 11
def laneWestId : RegionId := 12

def junction : Structure := Build.rect junctionId .intersection (m (-5)) (m (-5)) (m 5) (m 5)
def laneSouth : Structure :=
  Build.lane laneSouthId [(m 0, m (-40)), (m 5, m (-40)), (m 5, m (-5)), (m 0, m (-5))]
    Build.north (enters := some junctionId)
def laneWest : Structure :=
  Build.lane laneWestId [(m (-60), m (-5)), (m (-5), m (-5)), (m (-5), m 0), (m (-60), m 0)]
    Build.east (enters := some junctionId)

/-- The map of every scene below. -/
def streets : List Structure := [junction, laneSouth, laneWest]

def stopSignSouth : Device := Build.sign 20 .stopSign [laneSouthId]
def stopSignWest : Device := Build.sign 21 .stopSign [laneWestId]
def yieldSignSouth : Device := Build.sign 22 .yieldSign [laneSouthId]
def officerAtJunction : Device :=
  { Build.device 23 .humanDirection [junctionId] with
      humanRole := some .policeOfficer, humanIndication := some .stop }
def signalAtJunction : Device := Build.signal 24 [junctionId] [.circularGreen]

/-- The subject, northbound along x = 2. -/
def subjAt (y : Q) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 2, y) Build.north speed halfCar
/-- The other car, eastbound along y = −2. -/
def crossAt (x : Q) (speed : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] (x, m (-2)) Build.east speed halfCar

def subjLane : List (TrackId × RegionId) := [(1, laneSouthId)]
def subjEntering : List (TrackId × RegionId) := [(1, laneSouthId), (1, junctionId)]
def subjJunction : List (TrackId × RegionId) := [(1, junctionId)]
def crossLane : List (TrackId × RegionId) := [(2, laneWestId)]
def crossEntering : List (TrackId × RegionId) := [(2, laneWestId), (2, junctionId)]

def sceneAt (t : Timestamp) (users : List RoadUser) (occ : List (TrackId × RegionId))
    (devices : List Device) : Scene :=
  Build.scene t (some 1) users streets devices (some occ)

/-- `forbid` (violated): A car halts at the stop line of a four-way junction of two minor streets where stop signs stand at the two entrances of its own street only, then moves into the junction at 3 m/s. A car on the crossing street, whose approach segment has no stop or yield sign recorded as governing it, is already within the junction; under the two velocities the centres approach within the horizon to below the minimum clearance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t [subjAt (m (-9)) slow, crossAt (m (-10)) brisk]
             (subjLane ++ crossLane) [stopSignSouth]
    | 1 => sceneAt t [subjAt (m (-7)) slow, crossAt (m (-7)) brisk]
             (subjEntering ++ crossEntering) [stopSignSouth]
    | _ => sceneAt t [subjAt (m (-5)) slow, crossAt (m (-4)) brisk]
             (subjEntering ++ crossEntering) [stopSignSouth]

/-- `permit` (compliant): The same junction and the same unobligated crossing car, but the subject creeps into the junction at 1.5 m/s and holds back until the crossing car has passed, so no predicted closest approach within the horizon falls below the minimum clearance while it is moving in the junction. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t [subjAt (m (-9)) slow, crossAt (m (-4)) halted]
             (subjLane ++ crossEntering) [stopSignSouth]
    | 1 => sceneAt t [subjAt (m (-7)) slow, crossAt (m (-4)) halted]
             (subjEntering ++ crossEntering) [stopSignSouth]
    | _ => sceneAt t [subjAt (m (-5)) slow, crossAt (m (-4)) halted]
             (subjEntering ++ crossEntering) [stopSignSouth]

/-- `idle` (not_applicable): The subject halts at the stop line, moves into the junction and crosses it with no other road user anywhere in the scene, so no unobligated vehicle is within or approaching the junction; the verdict is decided with the subject alone. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t [subjAt (m (-9)) slow] subjLane [stopSignSouth]
    | 1 => sceneAt t [subjAt (m (-7)) slow] subjEntering [stopSignSouth]
    | _ => sceneAt t [subjAt (m (-5)) slow] subjEntering [stopSignSouth]

/-- `blind` (unknown): The same junction and crossing car, but the source declares no footprint overlap for any region, so neither the subject's being within the junction nor the other car's presence there can be decided and the rule reports unknown. The crossing car is far up its street at 3 m/s, further than its speed times the arrival time, so the approaching limb of the condition is decided by its distance and the only question left open is the footprint overlap the mask hides. The first observation, where the subject is alone on the street, is decided (not applicable) by the absence of any other vehicle. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t [subjAt (m (-9)) slow] subjLane [stopSignSouth]
    | 1 => sceneAt t [subjAt (m (-7)) slow, crossAt (m (-40)) brisk]
             (subjEntering ++ crossLane) [stopSignSouth]
    | _ => sceneAt t [subjAt (m (-5)) slow, crossAt (m (-37)) brisk]
             (subjEntering ++ crossLane) [stopSignSouth]

/-- `branch_1` (violated): The subject is moving within the junction at 3 m/s and an unobligated car is 25 m from the junction at 14 m/s on the crossing street, so it would reach the junction within the arrival time (the approaching branch of the condition rather than the within-the-junction branch); the predicted centre closest approach within the horizon falls below the minimum clearance. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t [subjAt (m (-9)) slow, crossAt (m (-46)) rushing]
             (subjLane ++ crossLane) [stopSignSouth]
    | 1 => sceneAt t [subjAt (m (-7)) slow, crossAt (m (-32)) rushing]
             (subjEntering ++ crossLane) [stopSignSouth]
    | _ => sceneAt t [subjAt (m (-5)) slow, crossAt (m (-18)) rushing]
             (subjEntering ++ crossLane) [stopSignSouth]

/-- `branch_2` (not_applicable): The subject is moving within the junction at 3 m/s and the only other car within the junction approached through a segment on which a stop sign is recorded as governing it, so that car is itself obligated to stop and the clause lays no duty on the subject toward it. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t [subjAt (m (-9)) slow, crossAt (m (-10)) brisk]
             (subjLane ++ crossLane) [stopSignSouth, stopSignWest]
    | 1 => sceneAt t [subjAt (m (-7)) slow, crossAt (m (-7)) brisk]
             (subjEntering ++ crossEntering) [stopSignSouth, stopSignWest]
    | _ => sceneAt t [subjAt (m (-5)) slow, crossAt (m (-4)) brisk]
             (subjEntering ++ crossEntering) [stopSignSouth, stopSignWest]

/-- `branch_3` (violated): The same unobligated crossing car within the junction, and the subject enters at 8 m/s, above the cautious-entry speed, so the duty to proceed cautiously is breached even though it steers clear and no predicted closest approach falls below the minimum clearance. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t [subjAt (m (-15)) fast, crossAt (m (-4)) halted]
             (subjLane ++ crossEntering) [stopSignSouth]
    | 1 => sceneAt t [subjAt (m (-7)) fast, crossAt (m (-4)) halted]
             (subjEntering ++ crossEntering) [stopSignSouth]
    | _ => sceneAt t [subjAt (m 1) fast, crossAt (m (-4)) halted]
             (subjJunction ++ crossEntering) [stopSignSouth]

/-- `branch_4` (violated): a yield sign, and no stop sign, is recorded as governing the subject's
    approach; the unobligated crossing car is within the junction and the velocities predict a
    closest approach below the minimum clearance. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t [subjAt (m (-9)) slow, crossAt (m (-10)) brisk]
             (subjLane ++ crossLane) [yieldSignSouth]
    | 1 => sceneAt t [subjAt (m (-7)) slow, crossAt (m (-7)) brisk]
             (subjEntering ++ crossEntering) [yieldSignSouth]
    | _ => sceneAt t [subjAt (m (-5)) slow, crossAt (m (-4)) brisk]
             (subjEntering ++ crossEntering) [yieldSignSouth]

/-- `branch_5` (not_applicable): the conflict of `forbid`, but a police officer is recorded
    directing traffic at the junction, so the exception holds and the duty does not apply. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t [subjAt (m (-9)) slow, crossAt (m (-10)) brisk]
             (subjLane ++ crossLane) [stopSignSouth, officerAtJunction]
    | 1 => sceneAt t [subjAt (m (-7)) slow, crossAt (m (-7)) brisk]
             (subjEntering ++ crossEntering) [stopSignSouth, officerAtJunction]
    | _ => sceneAt t [subjAt (m (-5)) slow, crossAt (m (-4)) brisk]
             (subjEntering ++ crossEntering) [stopSignSouth, officerAtJunction]

/-- `branch_6` (not_applicable): the conflict of `forbid`, but a traffic-control signal is recorded
    as governing the junction, so the exception holds and the duty does not apply. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t [subjAt (m (-9)) slow, crossAt (m (-10)) brisk]
             (subjLane ++ crossLane) [stopSignSouth, signalAtJunction]
    | 1 => sceneAt t [subjAt (m (-7)) slow, crossAt (m (-7)) brisk]
             (subjEntering ++ crossEntering) [stopSignSouth, signalAtJunction]
    | _ => sceneAt t [subjAt (m (-5)) slow, crossAt (m (-4)) brisk]
             (subjEntering ++ crossEntering) [stopSignSouth, signalAtJunction]

/-- `branch_7` (not_applicable): the unobligated car is on the crossing street but far from the
    junction at 3 m/s — further than its speed times the arrival time — so it is neither within the
    junction nor approaching so closely as to constitute an immediate hazard. -/
def branch_7Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t [subjAt (m (-9)) slow, crossAt (m (-40)) brisk]
             (subjLane ++ crossLane) [stopSignSouth]
    | 1 => sceneAt t [subjAt (m (-7)) slow, crossAt (m (-37)) brisk]
             (subjEntering ++ crossLane) [stopSignSouth]
    | _ => sceneAt t [subjAt (m (-5)) slow, crossAt (m (-34)) brisk]
             (subjEntering ++ crossLane) [stopSignSouth]

/-- `branch_8` (compliant): the subject breaks the junction's boundary at 0.2 m/s, below the motion
    tolerance, so the stretch of time the duty covers begins at the entry observation and not at an
    overlap in motion; the halted unobligated car within the junction is never approached within
    the conflict horizon. -/
def branch_8Trace : Trace :=
  Build.trace 3 0 (Units.seconds 5) fun k t =>
    match k with
    | 0 => sceneAt t [subjAt (m (-8)) creep, crossAt (m (-4)) halted]
             (subjLane ++ crossEntering) [stopSignSouth]
    | 1 => sceneAt t [subjAt (m (-7)) creep, crossAt (m (-4)) halted]
             (subjEntering ++ crossEntering) [stopSignSouth]
    | _ => sceneAt t [subjAt (m (-6)) creep, crossAt (m (-4)) halted]
             (subjEntering ++ crossEntering) [stopSignSouth]

/-- `branch_9` (violated): the unobligated car reaches the junction only after the subject has
    entered it, so the duty is broken at an observation at which the subject is within the junction
    in motion rather than at its entry. -/
def branch_9Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t [subjAt (m (-9)) slow] subjLane [stopSignSouth]
    | 1 => sceneAt t [subjAt (m (-7)) slow] subjEntering [stopSignSouth]
    | _ => sceneAt t [subjAt (m (-5)) slow, crossAt (m (-4)) brisk]
             (subjEntering ++ crossEntering) [stopSignSouth]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_257_2_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .violated ]

end TrafficSpecWitness.NRS_484B_257_2_o2
