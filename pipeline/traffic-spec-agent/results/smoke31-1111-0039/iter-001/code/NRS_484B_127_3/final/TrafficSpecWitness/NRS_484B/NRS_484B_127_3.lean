/-
  Witnesses for NRS_484B_127_3.

  Geometry: a highway region (id 100) from x = −200 m to 1000 m, y = −20 m to 20 m, and inside it one
  eastbound lane (id 101), y = −2 m to 2 m. Cars are 4.5 m long and 1.8 m wide (half-extents 2.25,
  0.9, 0.75 m), on the lane's centre line, heading east. The subject x is track 1. In a column,
  the car ahead (track 2) and the car behind (track 3) keep a bumper-to-bumper gap `g` to x, so
  centres are `g + 4.5 m` apart. Three instants one second apart; every car advances by its speed.
  Against the reading (22.4 m + 2 s · v + 2 s · v):
    at 25 m/s the bound is 122.4 m; forbid keeps 15 m (below the entering length alone),
    branch_5 keeps 60 m (above the length, below length plus headways), permit keeps 150 m;
    at 10 m/s (branch_2) the bound is 62.4 m, and the bicycle ahead is 8 m away.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_127_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_127_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def asmId : AsmId := "asm.outside_business_district"

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)
def bikeExtent : Q × Q × Q := (cm 90, cm 30, cm 90)
def highwaySpeed : Q := Units.metresPerSecond 25

/-- The public way, and the lane on it. -/
def highway : Structure := Build.rect 100 .highway (m (-200)) (m (-20)) (m 1000) (m 20)
def laneOf (id : RegionId) (y0 y1 : Q) : Structure :=
  Build.lane id [(m (-200), y0), (m 1000, y0), (m 1000, y1), (m (-200), y1)] Build.east
def lane : Structure := laneOf 101 (m (-2)) (m 2)

/-- Distance covered at speed `v` after `k` seconds. -/
def along (k : Nat) (v : Q) : Q := Q.mul (Q.ofInt (Int.ofNat k)) v

def car (id : TrackId) (pos : Q) (v : Q) : RoadUser :=
  Build.user id [.motorVehicle] (pos, Q.zero) Build.east v carExtent

/-- A three-car column at highway speed: track 2 ahead of x, track 3 behind, each `centre` apart. -/
def column (k : Nat) (centre : Q) : List RoadUser :=
  let px := along k highwaySpeed
  [ car 1 px highwaySpeed
  , car 2 (Q.add px centre) highwaySpeed
  , car 3 (Q.sub px centre) highwaySpeed ]

def columnScene (t : Timestamp) (k : Nat) (centre : Q) (outside : Bool) : Scene :=
  Build.scene t (some 1) (column k centre) [highway, lane] [] (assumptions := [(asmId, outside)])

/-- `forbid` (violated): On a rural highway declared outside every business district, three cars travel as a funeral motorcade in one lane at highway speed; the second car keeps a longitudinal gap to the first shorter than the length of an entering tractor-trailer combination. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => columnScene t k (cm 1950) true

/-- `permit` (compliant): The same motorcade, each follower keeping a gap to the car ahead longer than an entering combination plus a time headway at its speed on each side. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => columnScene t k (cm 15450) true

/-- `idle` (not_applicable): The same tightly spaced motorcade travels through a place declared a business district. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => columnScene t k (cm 1950) false

/-- `blind` (unknown): The rural motorcade as in forbid; the source declares rel.surface_gap absent, so the gap the follower keeps is not observed.
    The source tracks the lead car's position and heading but not its body outline, so the gap
    cannot be computed from the bodies either (the mask drops a measured gap only); without an
    outline its occupancy is not observed, and the source supplies its order in the lane (ahead
    of x) as a measured relation, which Core cannot compute here. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let s := columnScene t k (cm 1950) true
    let s := { s with
      users := s.users.map fun u =>
        if u.track == 2 then Build.withKin u fun kn => { kn with extent := none } else u
      occupancyObserved := s.occupancyObserved.filter (· != 2)
      occupies := s.occupies.filter (·.1 != 2) }
    Build.withRelations s [Build.relation 2 1 fun r => { r with aAheadOfB := some true }]

/-- `branch_1` (compliant): The lead car of a rural motorcade has no vehicle of any kind ahead of it in the scene: there is no space for it to keep, and it binds alone. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let px := along k highwaySpeed
    Build.scene t (some 1)
      [ car 1 px highwaySpeed
      , car 2 (Q.sub px (cm 1950)) highwaySpeed
      , car 3 (Q.sub px (cm 3900)) highwaySpeed ]
      [highway, lane] [] (assumptions := [(asmId, true)])

/-- `branch_2` (compliant): a car follows a bicycle 8 m ahead in its lane at 10 m/s; a bicycle is
    neither a vehicle nor a combination of vehicles, so no space is owed to it. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let v := Units.metresPerSecond 10
    let px := along k v
    Build.scene t (some 1)
      [ car 1 px v
      , Build.user 2 [.bicycle] (Q.add px (cm 1115), Q.zero) Build.east v bikeExtent ]
      [highway, lane] [] (assumptions := [(asmId, true)])

/-- `branch_3` (compliant): the car ahead in x's lane, 12 m centre to centre, is turned 53° off the
    lane (heading 0.6 east, 0.8 north): it does not travel x's way, so no gap to it is owed. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let px := along k highwaySpeed
    Build.scene t (some 1)
      [ car 1 px highwaySpeed
      , Build.user 2 [.motorVehicle] (Q.add px (m 12), Q.zero) (Units.ratio 3 5, Units.ratio 4 5)
          (Units.metresPerSecond 5) carExtent ]
      [highway, lane] [] (assumptions := [(asmId, true)])

/-- `branch_4` (not_applicable): the tight column drives on a private road (a lane not on the
    public way); the highway region lies elsewhere and x does not occupy it. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (column k (cm 1950))
      [ Build.rect 100 .highway (m (-200)) (m 100) (m 1000) (m 140), lane ] []
      (assumptions := [(asmId, true)])

/-- `branch_5` (violated): the motorcade at 25 m/s with a 60 m gap: room for the entering
    combination's length, not for it plus a time headway on each side at that speed. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => columnScene t k (cm 6450) true

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_127_3"
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
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_127_3
