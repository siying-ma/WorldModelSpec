/-
  Witnesses for NRS_484B_307_6a.

  Geometry (the witness's own figures; none appears in the rule). Travel is eastbound (+x).
  - Intersection i (id 10): x ∈ [0, 20], y ∈ [-10, 10].
  - Lane c (id 11): x ∈ [-100, 0], y ∈ [-4, 0], direction east, entrance end at i; its left neighbour is d.
  - Lane d (id 13): x ∈ [-100, 0], y ∈ [0, 4], direction east, enters i (an adjacent approach).
  - Intersection i0 (id 14, branch_9 only): x ∈ [-120, -100], at the exit (far) end of c.
  - Head s (id 20) governs c (branch_6: d only); head s2 (id 21, branch_7) governs d.
  - The subject (track 1) is a car (branch_3: a bicycle), half-extent 2.5 × 1 × 0.75 m, centred
    on y = -2. Its occupancy is the region containing its centre (stated in addition where the
    footprint straddles c and i).
  - Nine observations, 0.5 s apart (0 … 4000 ms). Each witness speaks about 500 … 4000 ms: the
    first observation has no previous one, so "at the previous observation" is unknown there.
  forbid: yellow alone 0–2.5 s with the car 30 m short of i, red alone from 3.0 s; the car's
    footprint comes to overlap i at 3.5 s (no longer in c).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_6a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_6a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def iId : RegionId := 10
def cId : RegionId := 11
def dId : RegionId := 13
def i0Id : RegionId := 14
def sId : DeviceId := 20
def s2Id : DeviceId := 21

def Y : List SignalIndication := [.circularYellow]
def R : List SignalIndication := [.circularRed]
def G : List SignalIndication := [.circularGreen]

/-- `a` at the observations up to `n`, `b` after. -/
def upTo (n : Nat) (a b : List SignalIndication) : Nat → List SignalIndication :=
  fun k => if k ≤ n then a else b

structure Setup where
  cls : List RoadUserClass := [.motorVehicle]
  xs : List Int                                  -- the car's centre x per observation, m
  speed : Int := 12                              -- m/s
  backing : Bool := false
  sigS : Nat → List SignalIndication
  sGoverns : List RegionId := [11]
  sig2 : Option (Nat → List SignalIndication) := none
  cEnters : RegionId := 10
  withI0 : Bool := false
  straddle : Nat → Bool := fun _ => false        -- the footprint also overlaps c at this observation

def structuresOf (u : Setup) : List Structure :=
  [ Build.rect iId .intersection (m 0) (m (-10)) (m 20) (m 10)
  , Build.lane cId [(m (-100), m (-4)), (m 0, m (-4)), (m 0, m 0), (m (-100), m 0)] Build.east
      (left := some dId) (enters := some u.cEnters)
  , Build.lane dId [(m (-100), m 0), (m 0, m 0), (m 0, m 4), (m (-100), m 4)] Build.east
      (right := some cId) (enters := some iId) ] ++
  (if u.withI0 then [Build.rect i0Id .intersection (m (-120)) (m (-10)) (m (-100)) (m 10)] else [])

def carAt (u : Setup) (k : Nat) : RoadUser :=
  let base := Build.user 1 u.cls (m (u.xs.getD k 0), m (-2)) Build.east
    (Units.metresPerSecond u.speed) (cm 250, cm 100, cm 75)
  if u.backing then
    Build.withKin base (fun kn => { kn with velocity := some (Build.scale Build.west (Units.metresPerSecond u.speed)) })
  else base

def devicesAt (u : Setup) (k : Nat) : List Device :=
  [Build.signal sId u.sGoverns (u.sigS k)] ++
  (match u.sig2 with
   | some f => [Build.signal s2Id [dId] (f k)]
   | none => [])

def traceOf (u : Setup) : Trace :=
  Build.trace 9 0 (Units.milliseconds 500) fun k t =>
    let car := carAt u k
    let sts := structuresOf u
    let occ := Build.occupancyFromGeometry [car] sts ++ (if u.straddle k then [(1, cId)] else [])
    Build.scene t (some 1) [car] sts (devicesAt u k) (occupies := some occ)

/-- The approach of `forbid`: 30 m short of i at the yellow, overlapping i 0.5 s after the red. -/
def forbidXs : List Int := [-32, -26, -20, -15, -11, -8, -5, 4, 12]
/-- An approach that starts upstream of c, outside every region. -/
def upstreamXs : List Int := [-110, -60, -40, -25, -12, -5, 4, 12, 18]

/-- `forbid` (violated): A car occupies lane c, which enters i and is governed by head s; s displays circular_yellow alone while the car is 30 m short of i at 14 m/s; s changes to circular_red alone 3 s later, and the car's footprint comes to overlap i 0.5 s after the red appears. -/
def forbidSetup : Setup := { xs := forbidXs, speed := 14, sigS := upTo 5 Y R }
def forbidTrace : Trace := traceOf forbidSetup

/-- `permit` (compliant): Same yellow; the car's footprint comes to overlap i while s still displays circular_yellow alone. -/
def permitTrace : Trace :=
  traceOf { xs := [-20, -14, -8, -3, 3, 9, 15, 25, 35], speed := 14, sigS := upTo 5 Y R }

/-- `idle` (not_applicable): s displays circular_green alone at every observation while the car occupies c; the car enters i. -/
def idleTrace : Trace :=
  traceOf { xs := upstreamXs, sigS := fun _ => G }

/-- `blind` (unknown): As forbid, but the source does not record which intersection lane c enters: whether the car faces a signal of this intersection is unknown. -/
def blindTrace : Trace := traceOf forbidSetup

/-- branch_1 (not_applicable): s shows circular_yellow with a green left arrow beside it (not a
    yellow alone), then red alone; the car enters i on the red. -/
def branch1Trace : Trace :=
  traceOf { xs := upstreamXs, sigS := upTo 5 [.circularYellow, .greenArrow .left] R }

/-- branch_2 (compliant): yellow alone, then circular_red with a green left arrow beside it; the
    car enters i under the arrow's signal, which this duty does not read. -/
def branch2Trace : Trace :=
  traceOf { xs := forbidXs, sigS := upTo 5 Y [.circularRed, .greenArrow .left] }

/-- branch_3 (not_applicable): as forbid, but the subject is a bicycle — traffic, not a vehicle. -/
def branch3Trace : Trace :=
  traceOf { forbidSetup with cls := [.bicycle], speed := 6 }

/-- branch_4 (violated): as forbid, but at the entry the footprint straddles c and i. -/
def branch4Trace : Trace :=
  traceOf { xs := [-32, -26, -20, -15, -11, -8, -5, 1, 12], speed := 14, sigS := upTo 5 Y R,
            straddle := fun k => k == 7 }

/-- branch_5 (not_applicable): s shows the yellow alone while the car is still upstream of c; the
    car enters c after the red has appeared and enters i on the red: it did not face the yellow on
    this approach. -/
def branch5Trace : Trace :=
  traceOf { xs := [-130, -120, -110, -60, -40, -20, -5, 4, 12], sigS := upTo 2 Y R }

/-- branch_6 (not_applicable): the only head governs the adjacent lane d, not c; it shows yellow
    alone then red, and the car in c enters i on that red. -/
def branch6Trace : Trace :=
  traceOf { forbidSetup with sGoverns := [dId] }

/-- branch_7 (compliant): s, governing c, shows yellow alone throughout; s2, governing d, shows
    yellow alone then red; the car in c enters i on s's yellow while s2 shows red. -/
def branch7Trace : Trace :=
  traceOf { forbidSetup with sigS := fun _ => Y, sig2 := some (upTo 5 Y R) }

/-- The backing approach of branch_9: the car in c backs out of c's exit end into i0. -/
def backingSetup : Setup :=
  { xs := [-80, -83, -86, -89, -92, -94, -96, -104, -108], speed := 1, backing := true,
    sigS := upTo 2 Y R, withI0 := true }

/-- branch_9 (compliant): c enters i; the car in c faced yellow alone then red, and backs out of
    c's exit end into intersection i0 on the red: reaching a carrier's far end is no entry through
    it, and i0 is not the intersection c enters. -/
def branch9Trace : Trace := traceOf backingSetup

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_6a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (500, 4000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_enters"]
  , witness "branch_1" branch1Trace .notApplicable
  , witness "branch_2" branch2Trace .compliant
  , witness "branch_3" branch3Trace .notApplicable
  , witness "branch_4" branch4Trace .violated
  , witness "branch_5" branch5Trace .notApplicable
  , witness "branch_6" branch6Trace .notApplicable
  , witness "branch_7" branch7Trace .compliant
  , witness "branch_9" branch9Trace .compliant ]

end TrafficSpecWitness.NRS_484B_307_6a
