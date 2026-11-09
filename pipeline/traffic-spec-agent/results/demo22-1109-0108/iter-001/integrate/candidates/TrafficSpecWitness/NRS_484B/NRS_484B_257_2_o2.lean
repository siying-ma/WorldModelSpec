/-
  Witnesses for NRS_484B_257_2_o2.

  The geometry (every figure here is the witness's own and appears nowhere in the rule):

  A plus-shaped junction, region 10, a 16 m square from (-8, -8) to (8, 8). Three approach
  carriers run into it, each recorded as entering region 10:
    - region 11, the subject's lane: northbound, x in [0, 4], y in [-60, -8];
    - region 14, the second northbound lane of the same leg: x in [4, 8], y in [-60, -8];
    - region 12, the crossing street's westbound lane: x in [8, 88], y in [0, 4].
  The subject (track 1) is a 4 m by 2 m car heading north; the other vehicle (track 2) is a van
  heading west on region 12 or north on region 14. Signs govern carriers, never the junction:
  device 20 is a stop sign on 11, device 21 a yield sign on 11, device 22 a stop sign on 12,
  device 25 a yield sign on 12; device 23 is a traffic signal governing 11 and device 24 a police
  officer directing the junction itself.

  Each trace is three observations one second apart with the scene held still, so that every
  instant carries the same verdict; the rule looks back over no window, so no scenario names one.
  Occupancy is read from the polygons where a body's reference point settles it, and stated where a
  body straddles two regions (a van partly in the junction and partly on its own carrier).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_2_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_2_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: v ↦ 1

/-- The junction: a 16 m square. -/
def junction : Structure := Build.rect 10 .intersection (m (-8)) (m (-8)) (m 8) (m 8)

/-- The subject's approach carrier: the right-hand northbound lane of the south leg. -/
def southLane : Structure :=
  Build.lane 11 [(m 0, m (-60)), (m 4, m (-60)), (m 4, m (-8)), (m 0, m (-8))]
    Build.north (enters := some 10)

/-- The second northbound lane of the south leg. -/
def southLane2 : Structure :=
  Build.lane 14 [(m 4, m (-60)), (m 8, m (-60)), (m 8, m (-8)), (m 4, m (-8))]
    Build.north (enters := some 10)

/-- The crossing street's westbound approach carrier. -/
def eastLane : Structure :=
  Build.lane 12 [(m 8, m 0), (m 88, m 0), (m 88, m 4), (m 8, m 4)]
    Build.west (enters := some 10)

def roads : List Structure := [junction, southLane, southLane2, eastLane]


def stopForSubject : Device := Build.sign 20 .stopSign [11]
def yieldForSubject : Device := Build.sign 21 .yieldSign [11]
def stopForCross : Device := Build.sign 22 .stopSign [12]
def yieldForCross : Device := Build.sign 25 .yieldSign [12]
def signalForSubject : Device := Build.signal 23 [11] [.circularGreen]
def officerAtJunction : Device :=
  { Build.device 24 .humanDirection [10] with
      humanRole := some .policeOfficer
      humanIndication := some .proceed }

/-- The subject: a 4 m by 2 m car heading north at `speed`. -/
def car (pos : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] pos Build.north speed (m 2, m 1, cm 75)

/-- A van of the crossing street, heading west, `2 · halfLen` long. -/
def vanWest (pos : Vec) (speed : Q) (halfLen : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] pos Build.west speed (halfLen, m 1, m 1)

/-- A van of the crossing street whose outline and pose the source maps and whose motion it does
    not report. -/
def vanWestUnobservedMotion (pos : Vec) (halfLen : Q) : RoadUser :=
  Build.withKin (vanWest pos (mps 0) halfLen)
    (fun k => { k with speed := none, velocity := none })

/-- A van on the south leg's second lane, heading north, 5 m long. -/
def vanNorth (pos : Vec) (speed : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] pos Build.north speed (cm 250, m 1, m 1)

/-- The subject in the junction and a van straddling the junction and its own carrier. -/
def straddleOccupancy : List (TrackId × RegionId) := [(1, 10), (2, 10), (2, 12)]

/-- `forbid` (violated): A stop sign governs the car's entrance to a junction where the crossing street's entrances carry no sign. The car halts, then pulls across the junction at 9 m/s while a van whose entrance carries no sign is within the junction, and the two bodies touch. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 2, m 2) (mps 9), vanWest (m 6, m 2) (mps 5) (m 4) ]
      roads
      [ stopForSubject ]
      (some straddleOccupancy)

/-- `permit` (compliant): The same junction and stop sign. The car crosses the junction at 3 m/s and no other road user is in the scene at any observation: nothing is owed precedence, and the verdict is decided with the subject alone. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 2, m 2) (mps 3) ]
      roads
      [ stopForSubject ]

/-- `idle` (not_applicable): The car crosses a junction at which no stop sign and no yield sign is erected at any entrance: the condition fails and the rule is not engaged. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 2, m 2) (mps 3) ]
      roads
      [ ]

/-- `blind` (unknown): The car crosses the junction while a van is within it, but the source does not report which travel regions the signs of the junction govern, so whether the van's approach was obligated to stop or yield is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 2, m (-2)) (mps 3), vanWest (cm 650, m 2) (mps 3) (cm 250) ]
      roads
      [ stopForSubject ]
      (some straddleOccupancy)

/-- `branch_1` (compliant): The car crosses the junction at 3 m/s while a van whose own entrance also carries a stop sign is within the junction: the van is itself obligated to stop, so it is not among the road users this duty protects, and no unobligated vehicle is near. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 2, m (-2)) (mps 3), vanWest (cm 650, m 2) (mps 3) (cm 250) ]
      roads
      [ stopForSubject, stopForCross ]
      (some straddleOccupancy)

/-- `branch_2` (violated): The car crosses the junction at 3 m/s, below the cautious bound, while a van on the unsigned crossing street is twenty metres from the junction at 20 m/s -- within its speed times the headway bound -- and their closest approach under constant velocities within the horizon falls to a metre. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 2, m (-3)) (mps 3), vanWest (cm 3050, m 2) (mps 20) (cm 250) ]
      roads
      [ stopForSubject ]

/-- `branch_3` (violated): No other road user is near, but the car crosses the junction at 12 m/s after halting at its stop sign: the cautious-proceeding bound is exceeded on its own. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 2, m 2) (mps 12) ]
      roads
      [ stopForSubject ]

/-- `branch_4` (violated): a yield sign, not a stop sign, is erected at the car's entrance, and the
    car crosses the junction at 12 m/s: the condition is met through the yield-sign limb and the
    cautious-proceeding bound is exceeded. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 2, m 2) (mps 12) ]
      roads
      [ yieldForSubject ]

/-- `branch_5` (not_applicable): a police officer is directing the traffic of the junction itself
    while the car crosses it at 3 m/s: the exception holds and the duty does not apply. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 2, m 2) (mps 3) ]
      roads
      [ stopForSubject, officerAtJunction ]

/-- `branch_6` (not_applicable): a traffic-control signal governs the car's own approach carrier,
    which the car still straddles as it enters the junction at 3 m/s: the exception holds through
    its approach-carrier limb. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 2, m (-7)) (mps 3) ]
      roads
      [ stopForSubject, signalForSubject ]
      (some [(1, 10), (1, 11)])

/-- `branch_7` (compliant): as `branch_1`, except that the van's own entrance carries a yield sign:
    it is obligated to yield, so it is not among the road users this duty protects. -/
def branch_7Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 2, m (-2)) (mps 3), vanWest (cm 650, m 2) (mps 3) (cm 250) ]
      roads
      [ stopForSubject, yieldForCross ]
      (some straddleOccupancy)

/-- `branch_8` (violated): the van on the unsigned crossing street is forty metres from the
    junction at 20 m/s, further than its speed times the headway bound, but the two centres' closest
    approach within the horizon falls to a quarter of a metre: it is an immediate hazard through the
    conflict limb alone, and the car crosses at 3 m/s without granting it precedence. -/
def branch_8Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 2, m (-5)) (mps 3), vanWest (cm 5050, m 2) (mps 20) (cm 250) ]
      roads
      [ stopForSubject ]

/-- `branch_9` (violated): a van creeps up the second northbound lane at 1 m/s, half a metre short
    of the junction -- within its own speed times the headway bound, so it is an immediate hazard
    through the distance limb alone -- and the car, crossing at 3 m/s, is in contact with it while
    the two centres draw apart, so the clearance is not breached and the contact alone breaks the
    duty. -/
def branch_9Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 3, m (-7)) (mps 3), vanNorth (cm 480, m (-11)) (mps 1) ]
      roads
      [ stopForSubject ]

/-- `branch_10` (compliant): a van stands halted within the junction, having entered from the
    unsigned crossing street, so it is a vehicle this duty protects; the car crosses at 3 m/s well
    clear of it, the two centres' closest approach within the horizon staying at eight metres and
    their bodies never touching. -/
def branch_10Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 2, m (-2)) (mps 3), vanWest (m 10, m 2) (mps 0) (cm 250) ]
      roads
      [ stopForSubject ]
      (some straddleOccupancy)

/-- `branch_11` (violated): a 7 m van stands within the junction, having entered from the unsigned
    crossing street, and the source maps its outline but not its motion: its own speed is
    unobserved, so the headway bound of the hazard convention and the drawing-together of the two
    centres are both unknown, and it is a vehicle this duty protects only because it lies within the
    junction. The car, crossing at 3 m/s, is in contact with it. -/
def branch_11Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 2, m 2) (mps 3), vanWestUnobservedMotion (m 6, m 2) (cm 350) ]
      roads
      [ stopForSubject ]
      (some straddleOccupancy)

/-- `branch_12` (violated): a van creeps up the second northbound lane at 4 m/s and draws level
    with the car crossing at 3 m/s: their centres never come closer than three metres, so the
    conflict figure is clear, but the nearest points of the two bodies are one metre apart while
    they draw together, and the clearance of the duty is breached. -/
def branch_12Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 3, m (-7)) (mps 3), vanNorth (m 6, m (-9)) (mps 4) ]
      roads
      [ stopForSubject ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_257_2_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .compliant
  , witness "branch_11" branch_11Trace .violated
  , witness "branch_12" branch_12Trace .violated ]

end TrafficSpecWitness.NRS_484B_257_2_o2
