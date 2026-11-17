/-
  Witnesses for NRS_484B_400_2b.

  Geometry (all figures the witness's own). Highway 100 runs north–south (x −9..9, y −60..60),
  highway 101 east–west (x −60..60, y −9..9); they meet in intersection 10, the square
  x, y ∈ (−7 m, 7 m), which lies on both. Highway 100's south arm: lane 20 (x 0..7, northbound)
  and lane 21 (x −7..0, southbound), or in branch_4 the directed roadway segments 24 (northbound)
  and 25 (southbound), or in branch_5 lane 20 with roadway segment 25. Highway 101's west arm:
  lane 30 (y 0..7, westbound) and lane 31 (y −7..0, eastbound). branch_1 adds highway 100's north
  arm, lanes 22 (x 0..7, northbound) and 23 (x −7..0, southbound). idle adds median 40 on
  highway 101's west arm (y −0.5..0.5).

  The subject (track 1, a motor vehicle, 4.5 m × 1.8 m) is sampled every 50 ms (the reading's
  step), 58 scenes. It approaches north at x = 3.5 m and enters the intersection at k = 4, at
  (3.5, −6.9). It then turns left at a constant yaw rate over N scenes (k = 5 .. 4 + N), a total
  heading change of exactly 90° (band 45° .. 135°), and drives straight west until it leaves the
  intersection. Each heading is an exact unit vector at the angle the yaw rate reaches (the rate
  at a scene held over the interval before it; the half-angle tangent rounded to 10⁻⁶), each
  position the previous one plus the velocity over 50 ms, rounded to the micrometre.
    violated scenes: 5 m/s, N = 20 (90 °/s), turn radius ≈ 3.2 m; it reaches heading west at
      about (0.32, −3.72) and leaves the intersection near k = 54 into lane 31, moving west at
      5 m/s against its eastbound direction (−5 m/s ≪ −0.1 m/s);
    permit: 10 m/s, N = 32 (56.25 °/s), radius ≈ 10.2 m; heading west at about (−6.69, 3.29),
      leaves at k = 37 into lane 30, along its westbound direction.
  branch_1 goes straight north at x = −3.5 m, 10 m/s, no yaw (0° ≪ 45°), and leaves at k = 32
  into lane 23 (southbound) against its direction. Opposed directions are exactly opposite
  (dot −1 ≤ −0.9). The scenes are judged from 50 ms on (the exit edge needs a previous
  observation).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_400_2b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_400_2b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def hNS : RegionId := 100
def hEW : RegionId := 101
def iX : RegionId := 10

def laneRect (id : RegionId) (x0 y0 x1 y1 : Q) (dir : Vec) (way : RegionId) : Structure :=
  { Build.lane id [(x0, y0), (x1, y0), (x1, y1), (x0, y1)] dir with ways := some [way] }

def roadwayRect (id : RegionId) (x0 y0 x1 y1 : Q) (dir : Vec) (way : RegionId) : Structure :=
  { Build.rect id .roadway x0 y0 x1 y1 with lane := some { direction := some dir }, ways := some [way] }

def highways : List Structure :=
  [ Build.rect hNS .highway (m (-9)) (m (-60)) (m 9) (m 60)
  , Build.rect hEW .highway (m (-60)) (m (-9)) (m 60) (m 9) ]
def intersection : Structure :=
  { Build.rect iX .intersection (m (-7)) (m (-7)) (m 7) (m 7) with ways := some [hNS, hEW] }

def southLanes : List Structure :=
  [ laneRect 20 (m 0) (m (-60)) (m 7) (m (-7)) Build.north hNS
  , laneRect 21 (m (-7)) (m (-60)) (m 0) (m (-7)) Build.south hNS ]
def southRoadways : List Structure :=
  [ roadwayRect 24 (m 0) (m (-60)) (m 7) (m (-7)) Build.north hNS
  , roadwayRect 25 (m (-7)) (m (-60)) (m 0) (m (-7)) Build.south hNS ]
def southMixed : List Structure :=
  [ laneRect 20 (m 0) (m (-60)) (m 7) (m (-7)) Build.north hNS
  , roadwayRect 25 (m (-7)) (m (-60)) (m 0) (m (-7)) Build.south hNS ]
def northLanes : List Structure :=
  [ laneRect 22 (m 0) (m 7) (m 7) (m 60) Build.north hNS
  , laneRect 23 (m (-7)) (m 7) (m 0) (m 60) Build.south hNS ]
def westLanes : List Structure :=
  [ laneRect 30 (m (-60)) (m 0) (m (-7)) (m 7) Build.west hEW
  , laneRect 31 (m (-60)) (m (-7)) (m (-7)) (m 0) Build.east hEW ]
def median : Structure :=
  { Build.rect 40 .medianOrDivider (m (-60)) (cm (-50)) (m (-7)) (cm 50) with ways := some [hEW] }

def ext : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The number of scenes of every trace, and the sampling interval. -/
def nScenes : Nat := 58
def dt : Q := Units.milliseconds 50

-- Exact unit headings for a left turn from north: the half-angle tangent t (rounded to 10⁻⁶)
-- gives (−2t, 1 − t²) / (1 + t²), a unit vector exactly.
def one : Q := Units.ratio 1 1
def piQ : Q := Units.ratio 355 113
def um (q : Q) : Q := Units.micrometres (q.num * 1000000 / (q.den : Int))
def sinT (x : Q) : Q :=
  let x2 := x * x
  x * (one - x2 * Units.ratio 1 6 * (one - x2 * Units.ratio 1 20 * (one - x2 * Units.ratio 1 42 *
    (one - x2 * Units.ratio 1 72 * (one - x2 * Units.ratio 1 110)))))
def cosT (x : Q) : Q :=
  let x2 := x * x
  one - x2 * Units.ratio 1 2 * (one - x2 * Units.ratio 1 12 * (one - x2 * Units.ratio 1 30 *
    (one - x2 * Units.ratio 1 56 * (one - x2 * Units.ratio 1 90))))
/-- tan of half of 90°·j/n. -/
def tanHalf (j n : Nat) : Q :=
  if j = 0 then Q.zero
  else if n ≤ j then one
  else
    let h := Q.mul (Units.ratio j (4 * n)) piQ
    um (Q.div (sinT h) (cosT h))
/-- The heading after turning left from north by 90°·j/n. -/
def headingAt (j n : Nat) : Vec :=
  let t := tanHalf j n
  let d := one + t * t
  (Q.neg (Q.div (t + t) d), Q.div (one - t * t) d)

/-- The yaw rate at scene k of a turn over n scenes from k = 5 (held over the interval before). -/
def yawAt (n k : Nat) : Q :=
  if 5 ≤ k ∧ k ≤ 4 + n then Units.millidegrees ((1800000 : Int) / (n : Int)) else Q.zero

/-- Position and heading at every scene of a left turn at speed v over n scenes. -/
def turnPath (v : Q) (n : Nat) : List (Vec × Vec) :=
  let step := Q.mul v dt
  let start : Vec := (cm 350, cm (-690) - (step + step + step + step))
  let acc := (List.range (nScenes - 1)).foldl (fun (acc : List (Vec × Vec)) j =>
      let k := j + 1
      let h := headingAt (min (k - 4) n) n
      match acc with
      | (p, _) :: _ => ((um (p.1 + h.1 * step), um (p.2 + h.2 * step)), h) :: acc
      | [] => acc) [(start, Build.north)]
  acc.reverse

def againstSpeed : Q := Units.metresPerSecond 5
def againstN : Nat := 20
def againstPath : List (Vec × Vec) := turnPath againstSpeed againstN
def alongSpeed : Q := Units.metresPerSecond 10
def alongN : Nat := 32
def alongPath : List (Vec × Vec) := turnPath alongSpeed alongN

def turnUser (path : List (Vec × Vec)) (v : Q) (n k : Nat) : RoadUser :=
  let (p, h) := path.getD k ((m 0, m 0), Build.north)
  Build.withKin (Build.user 1 [.motorVehicle] p h v ext) (fun kn => { kn with yawRate := some (yawAt n k) })

/-- The subject leaving into the opposing lane 31. -/
def turner (k : Nat) : RoadUser := turnUser againstPath againstSpeed againstN k
/-- The subject leaving into its own lane 30. -/
def turnerAlong (k : Nat) : RoadUser := turnUser alongPath alongSpeed alongN k

/-- The straight-through subject at scene k (x = −3.5 m, heading north, 10 m/s, no yaw). -/
def straight (k : Nat) : RoadUser :=
  let ki : Int := k
  Build.withKin (Build.user 1 [.motorVehicle] (cm (-350), cm (-890 + 50 * ki)) Build.north alongSpeed ext)
    (fun kn => { kn with yawRate := some Q.zero })

def intentAt (b : Bool) : List DeclaredIntent :=
  [{ vehicle := 1, target := iX, values := [("int.left_turn", b)] }]

/-- A scene generator: the subject, the structures, and the intention declared per scene. -/
def gen (u : Nat → RoadUser) (structs : List Structure) (intent : Nat → Bool) : Trace :=
  Build.trace nScenes 0 dt fun k t =>
    Build.scene t (some 1) [u k] structs [] (intents := intentAt (intent k))

def baseStructures : List Structure := highways ++ [intersection] ++ southLanes ++ westLanes

/-- `forbid` (violated): Two two-way undivided highways meet; the subject, with int.left_turn declared at the intersection, enters it, turns left (heading change in the band) and at its exit overlaps the receiving highway's lane whose designated direction its velocity runs against. -/
def forbidTrace : Trace := gen turner baseStructures (fun _ => true)

/-- `permit` (compliant): Same layout and intention; at its exit the subject overlaps only the receiving lane whose designated direction its velocity runs along. -/
def permitTrace : Trace := gen turnerAlong baseStructures (fun _ => true)

/-- `idle` (not_applicable): Same as forbid, but the receiving highway is one-way (its lanes carry no opposed directions) or divided by a median: the condition fails. -/
def idleTrace : Trace := gen turner (baseStructures ++ [median]) (fun _ => true)

/-- `blind` (unknown): Same as forbid, but the source declares kin.yaw_rate absent, so the left turn through the intersection is not decided. -/
def blindTrace : Trace := gen turner baseStructures (fun _ => true)

/-- `branch_1` (not_applicable): The subject passes straight through the intersection (heading change below the turn band) and exits into a lane against its direction: no left turn is recognized. -/
def branch_1Trace : Trace := gen straight (baseStructures ++ northLanes) (fun _ => true)

/-- `branch_2` (violated): int.left_turn is declared true at the entry and at the first observations inside the intersection, then false (the source's plan marks the turn completed) before the exit; the subject exits into an opposing lane: the intention held while the turn was under way. -/
def branch_2Trace : Trace := gen turner baseStructures (fun k => k ≤ 8)

/-- `branch_3` (not_applicable): int.left_turn is declared true on the approach only and false from the entry onwards (the plan changed to straight through), yet the subject turns left and exits into an opposing lane: no intention to turn at the intersection is declared while the turn is under way. -/
def branch_3Trace : Trace := gen turner baseStructures (fun k => k < 4)

/-- `branch_4` (violated): as forbid, but the north–south highway is mapped as two opposed directed
    roadway segments (no lanes): it is two-directional through the roadway pair. -/
def branch_4Trace : Trace :=
  gen turner (highways ++ [intersection] ++ southRoadways ++ westLanes) (fun _ => true)

/-- `branch_5` (violated): as forbid, but the north–south highway carries one northbound lane and an
    opposed southbound roadway segment: two-directional through the lane–roadway pair. -/
def branch_5Trace : Trace :=
  gen turner (highways ++ [intersection] ++ southMixed ++ westLanes) (fun _ => true)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_400_2b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (50, 2850)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_400_2b
