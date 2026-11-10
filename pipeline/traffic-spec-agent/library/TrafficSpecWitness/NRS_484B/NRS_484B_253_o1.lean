/-
  Witnesses for NRS_484B_253_o1.

  Geometry (world frame, +x east, +y north, metres): the intersection i (region 10) is the square
  (-10,-10)–(10,10). Three approach carriers enter it:
    cx (11): the southern leg's northbound lane, x 0…5, y -60…-10, direction north;
    cy (12): the northern leg's southbound lane, x -5…0, y 10…300, direction south (opposed to cx);
    ce (13): the eastern leg's westbound lane, x 10…300, y 0…5, direction west (crossing cx).
  x is track 1 (a motor vehicle), the other road user track 2; both bodies are 4 m × 2 m. Scenes are
  1 s apart. Occupancy is the reference point's region, plus the carrier a body still overlaps at
  the observation at which its occupancy of i begins (stated, since the reference point lies in one
  polygon). x enters i from cx at (1,-9) in every scene set; the declaration states int.turn_left
  for x at i (false in `idle`).
  Against the reading (gap 4 s, horizon 3 s, clearance 4 m, cosine 0.7, speed floor 0.2 m/s):
  forbid's y is 20 m from i at 14 m/s (bound 56 m) and closes to 2 m in 2.4 s.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_253_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_253_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

def iId : RegionId := 10
def cxId : RegionId := 11
def cyId : RegionId := 12
def ceId : RegionId := 13

def world : List Structure :=
  [ Build.rect iId .intersection (m (-10)) (m (-10)) (m 10) (m 10)
  , Build.lane cxId (box (m 0) (m (-60)) (m 5) (m (-10))) Build.north (enters := some iId)
  , Build.lane cyId (box (m (-5)) (m 10) (m 0) (m 300)) Build.south (enters := some iId)
  , Build.lane ceId (box (m 10) (m 0) (m 300) (m 5)) Build.west (enters := some iId) ]

def body : Q × Q × Q := (m 2, m 1, cm 75)

def car (track : TrackId) (x y : Int) (heading : Vec) (speed : Int) : RoadUser :=
  Build.user track [.motorVehicle] (m x, m y) heading (Units.metresPerSecond speed) body

/-- One observation: the road users and the occupancies stated beyond the reference points'. -/
structure Frame where
  users : List RoadUser
  extra : List (TrackId × RegionId) := []

def frameScene (turnLeft : Bool) (t : Timestamp) (f : Frame) : Scene :=
  Build.scene t (some 1) f.users world []
    (occupies := some (Build.occupancyFromGeometry f.users world ++ f.extra))
    (intents := [{ vehicle := 1, target := iId, values := [("int.turn_left", turnLeft)] }])

def play (frames : List Frame) (turnLeft : Bool := true) : Trace :=
  Build.trace frames.length 0 (Units.seconds 1) fun k t =>
    frameScene turnLeft t (frames.getD k { users := [] })

/-- x on cx short of i, then entering i (still overlapping cx), then turning left (west) in i. -/
def xApproachAt (k : Nat) : RoadUser :=
  match k with
  | 0 => car 1 1 (-12) Build.north 3
  | 1 => car 1 1 (-9) Build.north 3
  | _ => car 1 (-1) (-6) Build.west 3

/-- `forbid` (violated): x occupies i with int.turn_left x i, entered from lane cx heading north. y approaches on cy heading south (directions opposed), 20 m from i at 14 m/s. x moves into its left turn; predicted closest approach 1.5 m in 1.4 s. -/
def forbidFrames : List Frame :=
  [ { users := [xApproachAt 0, car 2 (-1) 46 Build.south 14] }
  , { users := [xApproachAt 1, car 2 (-1) 32 Build.south 14], extra := [(1, cxId)] }
  , { users := [xApproachAt 2, car 2 (-1) 18 Build.south 14] } ]

def forbidTrace : Trace := play forbidFrames

/-- `permit` (compliant): Same, but x stays halted within i until y has passed through, then turns. -/
def permitTrace : Trace :=
  play
    [ { users := [car 1 1 (-12) Build.north 2, car 2 (-1) 40 Build.south 14] }
    , { users := [car 1 1 (-9) Build.north 0, car 2 (-1) 26 Build.south 14], extra := [(1, cxId)] }
    , { users := [car 1 1 (-9) Build.north 0, car 2 (-1) 11 Build.south 14], extra := [(2, iId)] }
    , { users := [car 1 1 (-9) Build.north 0, car 2 (-1) (-3) Build.south 14] }
    , { users := [car 1 (-1) (-6) Build.west 3, car 2 (-1) (-17) Build.south 14] } ]

/-- `idle` (not_applicable): x occupies i but the declaration states int.turn_left x i false (it plans to go straight). -/
def idleTrace : Trace := play forbidFrames (turnLeft := false)

/-- `blind` (unknown): As forbid, but st.lane_direction is not observed, so whether y approaches from the opposite direction is unknown. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): y approaches on the opposed carrier 150 m from i at 14 m/s (more than speed times the critical gap) and outside i; x turns: no vehicle within i or near enough to be an immediate hazard. -/
def branch_1Trace : Trace :=
  play
    [ { users := [xApproachAt 0, car 2 (-1) 176 Build.south 14] }
    , { users := [xApproachAt 1, car 2 (-1) 162 Build.south 14], extra := [(1, cxId)] }
    , { users := [xApproachAt 2, car 2 (-1) 148 Build.south 14] } ]

/-- `branch_2` (not_applicable): x turns left within i with no other road user in the scene. -/
def branch_2Trace : Trace :=
  play
    [ { users := [xApproachAt 0] }
    , { users := [xApproachAt 1], extra := [(1, cxId)] }
    , { users := [xApproachAt 2] } ]

/-- `branch_3` (violated): y, having entered i from the opposed carrier cy, is within i (its speed
    unobserved) as x enters i on a collision course: y within the intersection applies by itself. -/
def branch_3Trace : Trace :=
  play
    [ { users := [car 1 1 (-14) Build.north 2, car 2 (-1) 25 Build.south 8] }
    , { users := [car 1 1 (-12) Build.north 2, car 2 (-1) 11 Build.south 8], extra := [(2, iId)] }
    , { users := [car 1 1 (-9) Build.north 2,
                  Build.withKin (car 2 (-1) 3 Build.south 8) fun k => { k with speed := none }],
        extra := [(1, cxId)] } ]

/-- `branch_4` (compliant): y on cy 38 m from i at 14 m/s (an immediate hazard) while x moves into
    i; the centres' closest approach lies beyond the time horizon (3.5 s). -/
def branch_4Trace : Trace :=
  play
    [ { users := [xApproachAt 0, car 2 (-1) 64 Build.south 14] }
    , { users := [xApproachAt 1, car 2 (-1) 50 Build.south 14], extra := [(1, cxId)] } ]

/-- `branch_5` (compliant): y on cy 20 m from i at 14 m/s while x moves into i; the centres
    approach within the horizon but pass 8 m apart, above the clearance. -/
def branch_5Trace : Trace :=
  play
    [ { users := [car 1 4 (-12) Build.north 3, car 2 (-4) 46 Build.south 14] }
    , { users := [car 1 4 (-9) Build.north 3, car 2 (-4) 32 Build.south 14], extra := [(1, cxId)] } ]

/-- `branch_6` (not_applicable): x alone, deep in i, its body reaching into the entrance end of the
    opposed carrier cy: x is no vehicle other than itself. -/
def branch_6Trace : Trace :=
  play
    [ { users := [xApproachAt 0] }
    , { users := [xApproachAt 1], extra := [(1, cxId)] }
    , { users := [car 1 0 9 Build.north 3], extra := [(1, cyId)] } ]

/-- `branch_7` (not_applicable): the road user approaching on cy, 14 m from i at 6 m/s on a
    collision course, is a bicycle, which the vehicle aggregate does not include. -/
def branch_7Trace : Trace :=
  play
    [ { users := [xApproachAt 0, Build.user 2 [.bicycle] (m (-1), m 22) Build.south (Units.metresPerSecond 6) body] }
    , { users := [xApproachAt 1, Build.user 2 [.bicycle] (m (-1), m 16) Build.south (Units.metresPerSecond 6) body],
        extra := [(1, cxId)] } ]

/-- `branch_8` (not_applicable): y enters i from the crossing carrier ce (westbound) and is within i
    as x turns: it does not approach from the direction opposite x's approach. -/
def branch_8Trace : Trace :=
  play
    [ { users := [xApproachAt 0, car 2 25 2 Build.west 10] }
    , { users := [xApproachAt 1, car 2 11 2 Build.west 10], extra := [(1, cxId), (2, iId)] }
    , { users := [xApproachAt 2, car 2 1 2 Build.west 10] } ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_253_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_253_o1
