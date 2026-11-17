/-
  Witnesses for NRS_484B_280_1c.

  Geometry (the witness's own figures; none appears in the rule). +x east, +y north, 1 s between
  observations. The subject (track 1) is a car (half-extents 2.25 × 0.90 m) heading east along
  y = 0. The pedestrian (track 2) has half-extents 0.25 × 0.25 m.
  - Crossing scenes (forbid, blind, idle, branch_2): the car runs at 10 m/s from x = 0; the
    pedestrian crosses northbound at 1 m/s at x = 27 (from y = −1, or southbound from y = 1). Under
    constant velocities their centres pass 1.69 m apart about 2.7 s, 1.7 s and 0.7 s ahead: within
    the 3 s horizon and below the 3 m clearance. The crosswalk spans x 25…29, y −6…6.
  - Permit: the car slows (5, 4, 3, 1 m/s) and halts at x = 22.5 (front at 24.75, short of the
    crosswalk) while the pedestrian waits 5 m to its right at x = 25.3; while the car moves their
    centres never come nearer than 5 m. Only once it is halted does the pedestrian walk across in
    front of it (centres 2.8 m apart), when the duty is not read.
  - Static-pedestrian scenes (branch_3 … branch_9): the car runs at 10 m/s from x = 0; the
    pedestrian stands at (28, −2.2): closest approach 2.2 m, 2.8 s / 1.8 s / 0.8 s ahead; the bodies
    never touch. Each scene places the pedestrian at most at one of the places, by nearness only
    (a region whose edge lies at y = −2 or a shelter 0.15 m away, the pedestrian's reference point
    outside it) or beside a halted vehicle (body y −5.3 … −2.7 or −4.9 … −3.1) with a door open.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_280_1c
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_280_1c

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n
def pick (xs : List Q) (k : Nat) : Q := xs.getD k Q.zero

def carExt : Q × Q × Q := (cm 225, cm 90, cm 75)
def pedExt : Q × Q × Q := (cm 25, cm 25, cm 90)

-- Binders ↦ tracks: subject ↦ 1

/-- The subject car at `x` on y = 0, heading east at `v`. -/
def car (x v : Q) : RoadUser := Build.user 1 [.motorVehicle] (x, Q.zero) Build.east v carExt

/-- The pedestrian. -/
def ped (x y : Q) (h : Vec) (v : Q) : RoadUser := Build.user 2 [.pedestrian] (x, y) h v pedExt

/-- Whether the pedestrian is in the car's line of sight (supplied: Core never computes it). -/
def seen (vis : Bool) (sc : Scene) : Scene :=
  Build.withRelations sc [Build.relation 1 2 (fun r => { r with visible := some vis })]

def crosswalk : Structure := { Build.rect 20 .crosswalk (m 25) (m (-6)) (m 29) (m 6) with marked := some true }
def highway : Structure := Build.rect 10 .highway (m (-10)) (m (-6)) (m 100) (m 6)

/-- `forbid` (violated): A pedestrian visible from a moving car steps from the curb into a marked crosswalk; the car does not slow and their closest approach falls within p.conflict_horizon and below p.conflict_centre_clearance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    seen true <| Build.scene t (some 1)
      [ car (m (10 * Int.ofNat k)) (mps 10)
      , ped (m 27) (m (-1 + Int.ofNat k)) Build.north (mps 1) ]
      [ crosswalk ]
      [ ]

/-- `permit` (compliant): The car slows and halts short of the crosswalk while the visible pedestrian crosses; while it moves there is no contact and no conflicting closest approach. -/
def permitTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    seen true <| Build.scene t (some 1)
      [ car (pick [m 10, m 15, m 19, cm 2150, cm 2250, cm 2250, cm 2250] k)
            (pick [mps 5, mps 4, mps 3, mps 1, mps 0, mps 0, mps 0] k)
      , ped (cm 2530) (pick [m (-5), m (-5), m (-5), m (-5), m (-5), cm (-350), cm (-200)] k) Build.north
            (pick [mps 0, mps 0, mps 0, mps 0, cm 150, cm 150, cm 150] k) ]
      [ crosswalk ]
      [ ]

/-- `idle` (not_applicable): The subject is an electric scooter (not a member of the motor vehicle aggregate) passing a pedestrian at a crosswalk. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    seen true <| Build.scene t (some 1)
      [ Build.user 1 [.electricScooter] (m (10 * Int.ofNat k), Q.zero) Build.east (mps 10) (cm 60, cm 30, cm 90)
      , ped (m 27) (m (-1 + Int.ofNat k)) Build.north (mps 1) ]
      [ crosswalk ]
      [ ]

/-- `blind` (unknown): A moving car closes on a pedestrian at a crosswalk with a conflicting closest approach; whether the pedestrian is in the car's line of sight is not observed on this source. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): A moving car drives on a street with no pedestrian in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (10 * Int.ofNat k)) (mps 10) ]
      [ highway ]
      [ ]

/-- `branch_2` (compliant): A pedestrian hidden behind a parked van (not visible from the car) steps into the roadway; the car's closest approach to it is in conflict but there is no contact: the duty arises only upon observing. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    seen false <| Build.scene t (some 1)
      [ car (m (10 * Int.ofNat k)) (mps 10)
      , ped (m 27) (m (1 - Int.ofNat k)) Build.south (mps 1)
      , Build.user 3 [.motorVehicle] (m 22, cm 350) Build.east (mps 0) (cm 250, cm 100, cm 120) ]
      [ highway ]
      [ ]

/-- The static-pedestrian scene: the car at 10 m/s, the visible pedestrian at (28, −2.2), with the
    other users, structures, devices and (where stated) occupancy given. -/
def staticTrace (others : List RoadUser) (structures : List Structure) (devices : List Device)
    (occ : Option (List (TrackId × RegionId)) := none) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    seen true <| Build.scene t (some 1)
      ([ car (m (10 * Int.ofNat k)) (mps 10)
       , ped (m 28) (cm (-220)) Build.north (mps 0) ] ++ others)
      structures devices occ

/-- A halted vehicle beside the pedestrian (body y −5.3 … −2.7), a door open. -/
def halted (track : TrackId) (classes : List RoadUserClass) (ext : Q × Q × Q) : RoadUser :=
  Build.withSignals (Build.user track classes (m 28, m (-4)) Build.east (mps 0) ext)
    fun s => { s with doorsOpen := some [.traffic] }

/-- `branch_3` (violated): A visible pedestrian stands beside a halted transit bus whose door is open, boarding it; a moving car passes the bus with a conflicting closest approach to the pedestrian. -/
def branch_3Trace : Trace :=
  staticTrace [halted 3 [.bus, .transitBus, .motorVehicle] (cm 600, cm 130, cm 160)] [] []

/-- `branch_4` (violated): the pedestrian stands on the edge of a highway (near, not on it); the car's closest approach conflicts. -/
def branch_4Trace : Trace :=
  staticTrace [] [Build.rect 10 .highway (m (-10)) (m (-2)) (m 100) (m 10)] []

/-- `branch_5` (violated): the pedestrian waits beside a bus shelter (a transit stop, near, not on it); the car's closest approach conflicts. -/
def branch_5Trace : Trace :=
  staticTrace [] [Build.rect 40 .transitStop (m 27) (cm (-350)) (m 29) (cm (-260))] []

/-- `branch_6` (violated): the pedestrian stands at the kerb end of a crosswalk (near, reference point outside it); the car's closest approach conflicts. -/
def branch_6Trace : Trace :=
  staticTrace [] [Build.rect 20 .crosswalk (m 25) (m (-2)) (m 29) (m 6)] []

/-- `branch_7` (violated): the pedestrian stands at the edge of a lane governed by a school zone sign beginning the zone (near the lane); the car's closest approach conflicts. -/
def branch_7Trace : Trace :=
  staticTrace [] [Build.rect 21 .lane (m (-10)) (m (-2)) (m 100) (m 2)]
    [Build.zoneSign 30 [21] .school false (some {})]

/-- `branch_8` (compliant): the lane beside the pedestrian is governed only by a sign that ends the school zone; the school zone that begins is on a lane 50 m away: the pedestrian is in no school zone, and at no other place. -/
def branch_8Trace : Trace :=
  staticTrace []
    [Build.rect 21 .lane (m (-10)) (m (-2)) (m 100) (m 2), Build.rect 22 .lane (m (-10)) (m 50) (m 100) (m 54)]
    [Build.zoneSign 30 [21] .school true (some {}), Build.zoneSign 31 [22] .school false (some {})]

/-- `branch_9` (compliant): the pedestrian boards a halted taxicab with a door open (a taxicab is no bus and no transit vehicle), at no other place; the car's closest approach conflicts. -/
def branch_9Trace : Trace :=
  staticTrace [halted 3 [.taxicab] (cm 240, cm 90, cm 75)] [] []

/-- `branch_10` (compliant): the car crosses an off-street lot where the pedestrian stands; the nearest highway, bus shelter and crosswalk lie 50 m north, out of reach: the pedestrian is at none of the places, though the car's closest approach conflicts. -/
def branch_10Trace : Trace :=
  staticTrace []
    [ Build.rect 10 .highway (m (-10)) (m 50) (m 100) (m 70)
    , Build.rect 40 .transitStop (m 27) (m 71) (m 29) (m 73)
    , Build.rect 20 .crosswalk (m 25) (m 50) (m 29) (m 70) ] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_280_1c"
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
  , witness "blind" blindTrace (.unknown []) ["rel.visible"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .compliant ]

end TrafficSpecWitness.NRS_484B_280_1c
