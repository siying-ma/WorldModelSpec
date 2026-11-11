/-
  Witnesses for NRS_484B_227_1_o2.

  The divided highway (region 10) runs east–west, x 0…200 m, y −20…20 m. Its eastbound roadway
  (11, designated east) is y −10…−1, its westbound roadway (12, designated west) y 1…10; the
  dividing section between them (y −1…1) is four regions: 13 (x 0…90, no opening), 14 (x 90…100,
  an opening), 16 (x 100…140, no opening) and 17 (x 160…200, no opening). A north–south highway
  (30, x 140…160) crosses it; their intersection (15) is x 140…160, y −10…10, lying on both ways.
  Every part of the divided highway lies on 10. The idle scene is an undivided two-way highway
  (20, y −10…10) with one roadway (21, y −6…6) carrying no designated direction.
  The car (track 1, a motor vehicle, half-extents 2.25 × 0.90 × 0.75 m) is sampled at 1 s; its
  speed is 4–10 m/s, well above p.speed_resolution, and its motion against a roadway is at
  cosine −1 or −0.8, well beyond −p.opposed_direction_cosine; crossing motion is at cosine 0.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_227_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_227_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

/-- The car at a position, heading and speed. -/
def car (p : Vec) (h : Vec) (v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] p h v (cm 225, cm 90, cm 75)

/-- North-west, turning back across the eastbound roadway: (−0.8, 0.6). -/
def northWest : Vec := (Units.ratio (-4) 5, Units.ratio 3 5)

def hw : RegionId := 10

def onHw (s : Structure) : Structure := { s with ways := some [hw] }

def roadway (id : RegionId) (y0 y1 : Q) (dir : Vec) : Structure :=
  onHw { Build.rect id .roadway (m 0) y0 (m 200) y1 with lane := some { direction := some dir } }

def median (id : RegionId) (x0 x1 : Q) (opening : Bool) : Structure :=
  onHw { Build.rect id .medianOrDivider x0 (m (-1)) x1 (m 1) with opening := some opening }

/-- The divided highway, its crossing highway and their intersection. -/
def dividedHighway : List Structure :=
  [ Build.rect hw .highway (m 0) (m (-20)) (m 200) (m 20)
  , roadway 11 (m (-10)) (m (-1)) Build.east
  , roadway 12 (m 1) (m 10) Build.west
  , median 13 (m 0) (m 90) false
  , median 14 (m 90) (m 100) true
  , median 16 (m 100) (m 140) false
  , median 17 (m 160) (m 200) false
  , Build.rect 30 .highway (m 140) (m (-100)) (m 160) (m 100)
  , { Build.rect 15 .intersection (m 140) (m (-10)) (m 160) (m 10) with ways := some [hw, 30] } ]

/-- An undivided two-way highway: one roadway, no dividing section. -/
def undividedHighway : List Structure :=
  [ Build.rect 20 .highway (m 0) (m (-10)) (m 200) (m 10)
  , { Build.rect 21 .roadway (m 0) (m (-6)) (m 200) (m 6) with ways := some [20] } ]

def sceneOn (structures : List Structure) (u : RoadUser) (t : Timestamp) : Scene :=
  Build.scene t (some 1) [u] structures []

/-- `forbid` (violated): On a highway divided by a grass median, a car drives across the median at a place where the median region carries no opening and no intersection lies. -/
def forbidCar : Nat → RoadUser
  | 0 => car (m 50, m (-5)) Build.north (m 4)
  | 1 => car (m 50, m 0) Build.north (m 4)     -- on median 13, no opening
  | _ => car (m 50, m 5) Build.north (m 4)

def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneOn dividedHighway (forbidCar k) t

/-- `permit` (compliant): On the same divided highway, a car turns left across the median through a median region that carries the opening attribute and then drives in the designated direction of the opposite roadway. -/
def permitCar : Nat → RoadUser
  | 0 => car (m 95, m (-5)) Build.north (m 4)
  | 1 => car (m 95, m 0) Build.north (m 4)     -- in opening 14
  | 2 => car (m 92, m 5) Build.west (m 4)
  | _ => car (m 80, m 5) Build.west (m 8)

def permitTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t => sceneOn dividedHighway (permitCar k) t

/-- `idle` (not_applicable): A car makes a U-turn on an undivided two-way highway: no median or dividing section lies on the way. -/
def idleCar : Nat → RoadUser
  | 0 => car (m 50, m (-3)) Build.east (m 4)
  | 1 => car (m 54, m 0) Build.north (m 4)
  | _ => car (m 50, m 3) Build.west (m 4)

def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneOn undividedHighway (idleCar k) t

/-- `blind` (unknown): A car drives near the median of a divided highway; the source declares rel.occupies absent, so whether it is on the median, an opening or a roadway is not observed. -/
def blindCar (k : Nat) : RoadUser :=
  car (m (60 + 10 * Int.ofNat k), m (-2)) Build.east (m 10)

def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneOn dividedHighway (blindCar k) t

/-- `branch_1` (violated): On a wide roadway of a divided highway, away from any opening and intersection, a car makes a U-turn without touching the median and drives on against the roadway's designated direction. -/
def branch_1Car : Nat → RoadUser
  | 0 => car (m 50, m (-8)) Build.east (m 4)
  | 1 => car (m 54, m (-5)) Build.north (m 4)
  | _ => car (m 50, m (-3)) Build.west (m 4)   -- on eastbound roadway 11, moving west

def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneOn dividedHighway (branch_1Car k) t

/-- `branch_2` (compliant): A car makes a U-turn inside an intersection of the divided highway and leaves on the opposite roadway in its designated direction. -/
def branch_2Car : Nat → RoadUser
  | 0 => car (m 130, m (-5)) Build.east (m 4)
  | 1 => car (m 150, m (-7)) Build.north (m 4)   -- in intersection 15 and roadway 11
  | 2 => car (m 152, m (-4)) northWest (m 4)     -- in 15 and 11, moving against 11
  | 3 => car (m 147, m 0) northWest (m 4)        -- in 15 between the roadways
  | 4 => car (m 145, m 5) Build.west (m 4)       -- in 15 and roadway 12
  | _ => car (m 130, m 5) Build.west (m 8)

def branch_2Trace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t => sceneOn dividedHighway (branch_2Car k) t

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_227_1_o2"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant ]

end TrafficSpecWitness.NRS_484B_227_1_o2
