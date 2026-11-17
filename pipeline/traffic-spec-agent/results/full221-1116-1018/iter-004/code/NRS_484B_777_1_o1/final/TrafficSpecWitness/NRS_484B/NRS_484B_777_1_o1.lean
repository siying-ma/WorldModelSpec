/-
  Witnesses for NRS_484B_777_1_o1.

  The carriageway (`road w`): highway 10 spanning y ∈ [−6, 2w + 6] m; roadway 11 spanning
  y ∈ [0, 2w], designated direction east, on highway 10; two eastbound lanes 12 (y ∈ [0, w], the
  outside lane) and 13 (y ∈ [w, 2w]), each of width w; the right road edge 14, a 20 cm strip
  y ∈ [−0.2, 0] on highway 10; a sidewalk 15, y ∈ [−6, −0.2]. Every region runs x ∈ [−100, 200].

  The subject (track 1) is a bicycle (half extents 0.9 × 0.3 × 0.6 m) heading east at 5 m/s, its
  reference point at x = 2.5·k m at the k-th of three instants 0.5 s apart. At y = 2.8 m its body
  is 2.5 m from the edge (forbid); at y = 0.9 m, 0.6 m (permit). Against the reading
  (p.bicycle_keep_right_gap 1.0 m): 2.5 m breaks the bound, 0.6 m keeps it.

  The car (track 2, half extents 2.3 × 0.9 × 0.75 m) travels east at 13 m/s on y = 2.8 m, its body
  20 m, 16 m and 12 m behind the bicycle: within p.nearby_traffic_reach (30 m), and faster than
  5 + p.commensurate_speed_margin (7.2 m/s), so exception (a) fails; behind, so it impedes nothing.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_777_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_777_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- An abscissa (cm) moving by `step` cm per instant. -/
def xAt (x0 step : Int) (k : Nat) : Q := cm (x0 + step * (k : Int))

/-- The carriageway with outside lanes of width `w`. -/
def road (w : Q) : List Structure :=
  let top := Q.add w w
  [ Build.rect 10 .highway (m (-100)) (m (-6)) (m 200) (Q.add top (m 6))
  , { Build.rect 11 .roadway (m (-100)) (m 0) (m 200) top with
        ways := some [10], lane := some { direction := some Build.east } }
  , { Build.rect 12 .lane (m (-100)) (m 0) (m 200) w with
        ways := some [10], lane := some { direction := some Build.east, width := some w } }
  , { Build.rect 13 .lane (m (-100)) w (m 200) top with
        ways := some [10], lane := some { direction := some Build.east, width := some w } }
  , { Build.rect 14 .roadEdge (m (-100)) (cm (-20)) (m 200) (m 0) with ways := some [10] }
  , { Build.rect 15 .sidewalk (m (-100)) (m (-6)) (m 200) (cm (-20)) with ways := some [10] } ]

/-- The bicycle at lateral position `y` cm, 5 m/s east. -/
def bike (k : Nat) (y : Int) : RoadUser :=
  Build.user 1 [.bicycle] (xAt 0 250 k, cm y) Build.east (Units.metresPerSecond 5) (cm 90, cm 30, cm 60)

/-- The car behind, 13 m/s east (6.5 m per instant). -/
def carBehind (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (xAt (-2320) 650 k, cm 280) Build.east (Units.metresPerSecond 13)
    (cm 230, cm 90, cm 75)

def fiveMetres : Q := m 5

/-- `forbid` (violated): A bicycle rides at 5 m/s on a roadway whose outside lane is 5.0 m wide, its body 2.5 m from the right road edge; a car of the vehicle and traffic aggregates travels the same way at 13 m/s with a body gap of 20 m behind it; no obstruction or other road user is on its right, no intersection or driveway entrance is in the scene, so no left turn is declared. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ bike k 280, carBehind k ]
      (road fiveMetres)
      [ ]

/-- `permit` (compliant): As forbid, but the bicycle rides with its body 0.6 m from the right road edge. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ bike k 90, carBehind k ]
      (road fiveMetres)
      [ ]

/-- `idle` (not_applicable): A bicycle rides on a sidewalk, its footprint overlapping no roadway. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ bike k (-300) ]
      (road fiveMetres)
      [ ]

/-- `blind` (unknown): As forbid, but the source maps regions without their outlines, so the road edge's lateral offset from the bicycle is unobserved. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): A bicycle rides alone at 5 m/s in the middle of a 5.0 m outside lane; no other road user is in the scene, so exception (a) holds vacuously: the duty binds the subject alone and is decided. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ bike k 250 ]
      (road fiveMetres)
      [ ]

/-- `branch_2` (compliant): As forbid, but the outside lane is 3.5 m wide, below the shared-lane width (exception (c), s14). -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ bike k 280, carBehind k ]
      (road (cm 350))
      [ ]

/-- `branch_3` (compliant): As forbid, but a parked car of the vehicle aggregate stands 10 m ahead of the bicycle on its right, at the curb (exception (c), s13). -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ bike k 280, carBehind k
      , Build.user 3 [.motorVehicle] (cm 1320, cm 100) Build.east (Units.metresPerSecond 0)
          (cm 230, cm 90, cm 75) ]
      (road fiveMetres)
      [ ]

/-- `branch_4` (compliant): As forbid, but an intersection lies ahead and the source declares int.left_turn for the bicycle at it (exception (b)). -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ bike k 280, carBehind k ]
      (road fiveMetres ++
        [ { Build.rect 16 .intersection (m 40) (m 0) (m 60) (m 10) with ways := some [10] } ])
      [ ]
      (intents := [ { vehicle := 1, target := 16, values := [("int.left_turn", true)] } ])

/-- `branch_5` (violated): An electric scooter rides at 8 m/s, above the speed NRS_484B_785_1a allows it, 2.5 m from the right edge of a 5.0 m lane; a car travels the same way at 9 m/s 20 m behind it: its speed is commensurate but not lawful, so exception (a) fails. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.electricScooter] (xAt 0 400 k, cm 280) Build.east (Units.metresPerSecond 8)
          (cm 60, cm 30, cm 90)
      , Build.user 2 [.motorVehicle] (xAt (-2300) 450 k, cm 280) Build.east (Units.metresPerSecond 9)
          (cm 230, cm 90, cm 75) ]
      (road fiveMetres)
      [ ]

/-- `branch_6` (not_applicable, own): As forbid, but a driveway entrance lies ahead on the left and
    the source declares int.left_turn for the bicycle at it (exception (b), its second limb). -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ bike k 280, carBehind k ]
      (road fiveMetres ++
        [ { Build.rect 17 .drivewayOrAlleyEntrance (m 30) (m 10) (m 36) (m 16) with ways := some [10] } ])
      [ ]
      (intents := [ { vehicle := 1, target := 17, values := [("int.left_turn", true)] } ])

/-- `branch_7` (not_applicable, own): As forbid, but debris lies 10 m ahead of the bicycle on its
    right, 1.5 m to the right of its line (exception (c), s13, its object limb). -/
def branch_7Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ bike k 280, carBehind k ]
      (road fiveMetres ++
        [ { Build.rect 18 .obstruction (m 10) (cm 30) (m 12) (cm 130) with
              obstructionKind := some .debris, ways := some [10] } ])
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_777_1_o1"
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
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_777_1_o1
