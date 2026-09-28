/-
  Witnesses for NRS_484B_213_2b.

  One carriageway for every scene, in the world frame (+x east, +y north): a roadway 14 m wide
  from x = -200 m to x = 200 m, its centre line a 30 cm strip on y = 0 that stops at x = 93 m,
  and a junction box from x = 93 m to x = 107 m across the full width — an intersection in
  `forbid`, `permit` and `idle`, a railroad grade crossing in `blind`. The subject (track 1) is a
  motor vehicle 4 m long and 1.8 m wide driving east at 5 m/s; three instants one second apart, so
  it advances 5 m per instant. Occupancy is stated rather than taken from the reference point,
  because a body astride the centre line lies in two regions at once.

  Geometry against the reading: the approach distance is measured from the body to the boundary of
  the junction box. In `forbid` and `blind` the subject's nose stands 20.5 m, 15.5 m and 10.5 m
  short of it — inside 100 ft (30.48 m) by a clear margin; in `permit` and `idle` the subject is
  inside the box, where that distance is zero.

  `forbid`: the subject sits astride the centre line, its body from 30 cm right of it to 1.5 m
  left, having pulled out to pass the slower vehicle (track 2) in the right half, and is still
  there through the whole approach.
  `permit`: the pass is over before the trace starts; the subject traverses the intersection
  wholly in the right half, 3.5 m right of the centre line.
  `idle`: a one-way roadway with no centre line; the subject drives its leftmost part through the
  intersection, and the saving clause withholds the duty.
  `blind`: the `forbid` body and speed, approaching a railroad grade crossing with no intersection
  in the scene, and the source declaring `st.region_geometry` absent — the crossing is mapped
  without its outline, so the distance from the body to it, and the approach with it, cannot be
  decided.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_213_2b
import TrafficSpec.Core.Builders

namespace TrafficSpecWitness.NRS_484B_213_2b

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: v ↦ 1

/-- The subject: a motor vehicle driving east at 5 m/s, 4 m by 1.8 m. -/
private def subject (pos : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] pos Build.east (Units.metresPerSecond 5) (m 2, cm 90, cm 75)

/-- The roadway and its centre line, which stops at the near edge of the junction box. -/
private def carriageway : List Structure :=
  [ Build.rect 1 .roadway (m (-200)) (m (-7)) (m 200) (m 7)
  , Build.rect 2 .centreLine (m (-200)) (cm (-15)) (m 93) (cm 15) ]

private def intersection : Structure := Build.rect 3 .intersection (m 93) (m (-7)) (m 107) (m 7)
private def railwayCrossing : Structure := Build.rect 4 .railwayCrossing (m 93) (m (-7)) (m 107) (m 7)

/-- The subject's position while approaching the junction box: 70 m, 75 m, 80 m. -/
private def approachX (k : Nat) : Q := m (70 + 5 * Int.ofNat k)
/-- The subject's position while inside the junction box: 95 m, 100 m, 105 m. -/
private def insideX (k : Nat) : Q := m (95 + 5 * Int.ofNat k)

/-- `forbid` (violated): A two-way highway with a signalised cross street. The subject crosses the centre line to pass a slower vehicle and is still left of the centre line well inside the stated distance before the intersection and through it. -/
private def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (approachX k, cm 60)
      , Build.user 2 [.motorVehicle] (m (74 + 3 * Int.ofNat k), cm (-350)) Build.east
          (Units.metresPerSecond 3) (m 2, cm 90, cm 75) ]
      (carriageway ++ [intersection])
      [ Build.signal 1 [3] [.circularGreen] ]
      (some [(1, 1), (1, 2), (2, 1)])

/-- `permit` (compliant): The same approach; the subject completes its pass and is back right of the centre line more than the stated distance before the intersection, staying right through the crossing. -/
private def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (insideX k, cm (-350)) ]
      (carriageway ++ [intersection])
      [ Build.signal 1 [3] [.circularGreen] ]
      (some [(1, 1), (1, 3)])

/-- `idle` (not_applicable): A one-way highway: the subject drives in the leftmost lane through an intersection. The saving clause of b4 holds, so the rule does not judge it. -/
private def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (insideX k, cm 350) ]
      [ Build.rect 1 .oneWayRoadway (m (-200)) (m (-7)) (m 200) (m 7), intersection ]
      [ Build.signal 1 [3] [.circularGreen] ]
      (some [(1, 1), (1, 3)])

/-- `blind` (unknown): The forbid scene with the source declaring `st.region_geometry` absent: the intersection is mapped without its boundary outline, so the distance from the subject's body to it is unknown, the approach cannot be decided and the rule reports unknown rather than compliance. -/
private def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (approachX k, cm 60) ]
      (carriageway ++ [railwayCrossing])
      [ ]
      (some [(1, 1), (1, 2)])

private def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_213_2b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"] ]

end TrafficSpecWitness.NRS_484B_213_2b
