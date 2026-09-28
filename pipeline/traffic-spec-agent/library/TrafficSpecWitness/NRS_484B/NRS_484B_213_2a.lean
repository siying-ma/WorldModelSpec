/-
  Witnesses for NRS_484B_213_2a.

  The carriageway runs east (+x) at y = 0. Two-way scenes (`forbid`, `permit`, `blind`) carry a
  highway 1 over [0, 200] m, an eastbound lane 2 over y ∈ [-4, 0], a westbound lane 3 over
  y ∈ [0, 4], a centre line 4 as the 20 cm strip about y = 0, and a roadway 5 over x ∈ [100, 140]
  — the crest, which records the grade, the curvature and the sight distance of the summit.
  The subject is track 1, 5 m long and 2 m wide, running east at 20 m/s; instants are 0.5 s apart,
  so it covers 10 m a step. Occupancy is stated from the footprint in `forbid` (a body that meets
  the centre-line strip occupies it, though its reference point is still in its own lane) and taken
  from the geometry elsewhere.

  Every figure here is the witness's own and appears nowhere in the rule. The two that are chosen
  against the run's reading: the stopping-sight-distance model at 20 m/s asks about 109 m, so a
  recorded sight distance of 30 m breaks the bound by a wide margin and one of 150 m keeps it by
  one; and `p.approach_distance` is 100 ft ≈ 30.5 m, so a body 25.5 m short of the crest is running
  up to it and one inside it is not.

  `permit` departs from the node's narrative twice, and deliberately: the crest it drives over
  records the sight distance the model requires, and a vehicle is in fact coming the other way
  within `p.ttc_bound`. That is the only place the operationalization's second limb
  (`drv.time_to_conflict`) can do any work — in `forbid` the sight-distance limb already decides —
  and it is still a scene in which the subject, keeping right of the centre line, complies.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_213_2a
import TrafficSpec.Core.Builders

namespace TrafficSpecWitness.NRS_484B_213_2a

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n

/-- An axis-aligned rectangle as a boundary polygon. -/
private def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

private def halfExtent : Q × Q × Q := (cm 250, m 1, cm 75)
private def cruise : Q := Units.metresPerSecond 20
private def sightShort : Q := m 30
private def sightAmple : Q := m 150
private def grade : Q := Units.ratio 6 100
private def curvature : Q := Units.ratio 2 100

-- Binders ↦ tracks: v ↦ 1

/-- The two-way carriageway; `sight` is the figure recorded for the lanes and for the crest. -/
private def twoWay (sight : Q) : List Structure :=
  [ Build.rect 1 .highway (m 0) (m (-8)) (m 200) (m 8)
  , { Build.lane 2 (box (m 0) (m (-4)) (m 200) (m 0)) Build.east with sightDistance := some sight }
  , { Build.lane 3 (box (m 0) (m 0) (m 200) (m 4)) Build.west with sightDistance := some sight }
  , Build.rect 4 .centreLine (m 0) (cm (-10)) (m 200) (cm 10)
  , { Build.rect 5 .roadway (m 100) (m (-4)) (m 140) (m 4) with
        grade := some grade, curvature := some curvature, sightDistance := some sight } ]

/-- `forbid` (violated): A two-way highway climbing to a crest, sight distance from the subject's position far short of what the model requires. The subject crosses the centre line and drives on the left half as it approaches the crest. -/
private def forbidTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    let lateral : Q := match k with | 0 => m (-2) | 1 => cm (-50) | _ => cm 60
    let occupies : List (TrackId × RegionId) :=
      match k with | 0 => [(1, 1), (1, 2)] | _ => [(1, 1), (1, 2), (1, 3), (1, 4)]
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (72 + 10 * (k : Int)), lateral) Build.east cruise halfExtent ]
      (twoWay sightShort)
      []
      (some occupies)

/-- `permit` (compliant): The same crest; the subject keeps its footprint entirely right of the centre line throughout the approach and over the crest. -/
private def permitTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (105 + 10 * (k : Int)), m (-2)) Build.east cruise halfExtent
      , Build.user 2 [.motorVehicle] (m (145 - 10 * (k : Int)), m 2) Build.west cruise halfExtent ]
      (twoWay sightAmple)
      []

/-- `idle` (not_applicable): A one-way highway with three lanes: the subject drives in the leftmost lane throughout. The saving clause of b5 holds, so the rule does not judge it. -/
private def idleTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (105 + 10 * (k : Int)), m 2) Build.east cruise halfExtent ]
      [ Build.rect 1 .highway (m 0) (m (-8)) (m 200) (m 4)
      , { Build.lane 2 (box (m 0) (m 0) (m 200) (m 4)) Build.east with sightDistance := some sightShort }
      , { Build.lane 3 (box (m 0) (m (-4)) (m 200) (m 0)) Build.east with sightDistance := some sightShort }
      , { Build.lane 4 (box (m 0) (m (-8)) (m 200) (m (-4))) Build.east with sightDistance := some sightShort }
      , { Build.rect 5 .roadway (m 100) (m (-8)) (m 140) (m 4) with
            grade := some grade, curvature := some curvature, sightDistance := some sightShort }
      , Build.rect 6 .oneWayRoadway (m 0) (m (-8)) (m 200) (m 4) ]
      []

/-- `blind` (unknown): The forbid scene with the source declaring `st.sight_distance` absent: how far ahead is visible from the subject's position is not observed, so the obstructed-view operationalization cannot be decided and the rule reports unknown rather than compliance. -/
private def blindTrace : Trace := forbidTrace

private def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_213_2a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.sight_distance"] ]

end TrafficSpecWitness.NRS_484B_213_2a
