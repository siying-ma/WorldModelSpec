/-
  Witnesses for NRS_484B_213_2a.

  Geometry (all figures the witness's own): a two-way highway (region 10) runs east–west, the
  rectangle x ∈ [−1000, 1000] m, y ∈ [−20, 20] m; its centre line (region 11) is the strip
  y ∈ [−0.1, 0.1] m lying on it. The subject (track 1, a motor vehicle, half-extents 2.5 × 1 × 1 m)
  drives east at 20 m/s, at x = 20·k m for the instants k = 0, 1, 2 (one second apart), at
  y = +2 m (left of the centre line: the line's lateral offset is −1.9 m) or y = −2 m (right of
  it: +1.9 m). Under the run's reading (11 s) the hazard distance is 220 m.
  - A crest (region 12) is a 20 m long rectangle across the road with its reference point at its
    middle: 100 m ahead (ground distance below 100 m), 100 m behind (receding), or 400 m ahead
    (ground distance above 350 m).
  - The highway's sight distance is 100 m (short) or 2000 m (long); its curvature 0 (straight)
    or 0.01 1/m (a 100 m radius curve, twenty times the resolution).
  - A one-way roadway (region 13), y ∈ [−15, 15] m, carries the subject in branch_2.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_213_2a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_213_2a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- Where a crest lies, if any: its western edge's x (m). -/
def crestRegion (x0 : Int) : Structure :=
  { Build.rect 12 .crest (m x0) (m (-10)) (m (x0 + 20)) (m 10) with
    position := some (m (x0 + 10), m 0) }

def highway (sight : Option Q) (curv : Q) : Structure :=
  { Build.rect 10 .highway (m (-1000)) (m (-20)) (m 1000) (m 20) with
    sightDistance := sight
    curvature := some curv }

def centreLine : Structure :=
  { Build.rect 11 .centreLine (m (-1000)) (cm (-10)) (m 1000) (cm 10) with
    ways := some [10] }

def oneWay : Structure :=
  { Build.rect 13 .oneWayRoadway (m (-1000)) (m (-15)) (m 1000) (m 15) with
    ways := some [10] }

/-- A three-instant drive east at 20 m/s on the highway. -/
def drive (left : Bool) (sight : Option Q) (curv : Q) (crest : Option Int) (oneWayRoad : Bool) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (20 * (k : Int)), if left then m 2 else m (-2)) Build.east
          (Units.metresPerSecond 20) (cm 250, m 1, m 1) ]
      ([highway sight curv, centreLine]
        ++ (match crest with | some x0 => [crestRegion x0] | none => [])
        ++ (if oneWayRoad then [oneWay] else []))
      [ ]

def straight : Q := Units.perMetre 0
def curved : Q := Units.ratio 1 100   -- 0.01 1/m
def shortSight : Option Q := some (m 100)
def longSight : Option Q := some (m 2000)

/-- `forbid` (violated): The subject moves toward an st.crest whose ground distance is below its speed times p.passing_sight_time; st.sight_distance at its point is below that distance; its reference point lies left of the centre line of the highway it occupies. -/
def forbidTrace : Trace := drive true shortSight straight (some 100) false

/-- `permit` (compliant): The same approach to the crest with the subject right of the centre line (prim.region_lateral_offset to the line positive). -/
def permitTrace : Trace := drive false shortSight straight (some 100) false

/-- `idle` (not_applicable): On a straight, level two-way highway (curvature at resolution, no crest ahead, sight distance far above the bound), the subject drives left of the centre line. -/
def idleTrace : Trace := drive true longSight straight none false

/-- `blind` (unknown): The subject is left of the centre line approaching a crest; st.sight_distance is not observed. -/
def blindTrace : Trace := drive true none straight (some 100) false

/-- `branch_1` (violated): On a curve (st.curvature above p.curvature_resolution) with st.sight_distance below the subject's speed times p.passing_sight_time and no crest, the subject is left of the centre line. -/
def branch_1Trace : Trace := drive true shortSight curved none false

/-- `branch_2` (not_applicable): The subject approaches a crest with short sight distance on an st.one_way_roadway, left of the roadway's geometric centre. -/
def branch_2Trace : Trace := drive true shortSight straight (some 100) true

/-- `branch_3` (not_applicable): short sight, straight road, left of the centre line, a crest
    100 m behind the subject (its velocity points away from it): not approaching. -/
def branch_3Trace : Trace := drive true shortSight straight (some (-120)) false

/-- `branch_4` (not_applicable): short sight, straight road, left of the centre line, a crest
    ahead but 400 m away, beyond the hazard distance. -/
def branch_4Trace : Trace := drive true shortSight straight (some 400) false

/-- `branch_5` (not_applicable): left of the centre line approaching a crest within the hazard
    distance, but the sight distance (2000 m) is not short of it: the view is not obstructed. -/
def branch_5Trace : Trace := drive true longSight straight (some 100) false

/-- `branch_6` (compliant): on a curve with short sight, the subject keeps right of the centre line. -/
def branch_6Trace : Trace := drive false shortSight curved none false

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_213_2a"
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
  , witness "blind" blindTrace (.unknown []) ["st.sight_distance"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .compliant ]

end TrafficSpecWitness.NRS_484B_213_2a
