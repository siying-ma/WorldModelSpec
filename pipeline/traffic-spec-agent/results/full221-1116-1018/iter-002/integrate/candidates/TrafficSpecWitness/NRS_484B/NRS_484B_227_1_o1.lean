/-
  Witnesses for NRS_484B_227_1_o1.

  Geometry (x east, y north, metres): highway 100 spans x ∈ [-100, 100], y ∈ [-20, 20]. On it lie
  the north roadway 10 (y ∈ [1, 12], designated direction west), the south roadway 11
  (y ∈ [-12, -1], designated direction east) and, between them, the median 20 (y ∈ [-1, 1], no
  opening). `branch_1` adds an intersection 30 (x ∈ [-10, 10], y ∈ [-12, 12]) lying on 100;
  `branch_2` adds a median section 21 (x ∈ [-5, 5], y ∈ [-1, 1]) carrying the opening attribute.
  The subject (track 1, a motor vehicle, half-extents 2 × 1 × 0.75 m) travels at 10 m/s, a hundred
  times the halt-speed tolerance, either east on the north roadway (against it) or east on the
  south roadway (with it). Three instants, one second apart; the rule looks at one instant at a time.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_227_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_227_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def highway : Structure := Build.rect 100 .highway (m (-100)) (m (-20)) (m 100) (m 20)

def northRoadway : Structure :=
  { Build.rect 10 .roadway (m (-100)) (m 1) (m 100) (m 12) with
    lane := some { direction := some Build.west }, ways := some [100] }

def southRoadway : Structure :=
  { Build.rect 11 .roadway (m (-100)) (m (-12)) (m 100) (m (-1)) with
    lane := some { direction := some Build.east }, ways := some [100] }

def median : Structure :=
  { Build.rect 20 .medianOrDivider (m (-100)) (m (-1)) (m 100) (m 1) with
    opening := some false, ways := some [100] }

def openingSection : Structure :=
  { Build.rect 21 .medianOrDivider (m (-5)) (m (-1)) (m 5) (m 1) with
    opening := some true, ways := some [100] }

def intersection : Structure :=
  { Build.rect 30 .intersection (m (-10)) (m (-12)) (m 10) (m 12) with ways := some [100] }

/-- The subject at `x` metres east, `y` north, driving east at 10 m/s. -/
def subjectAt (x y : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m y) Build.east (Units.metresPerSecond 10) (m 2, m 1, cm 75)

/-- `forbid` (violated): A st.median_or_divider lies on highway h; the subject occupies the roadway r of h on the far side of the divider and its kin.velocity runs against r's st.lane_direction: moving_against_carrier holds. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (-30 + 10 * (k : Int)) 6 ]
      [ highway, northRoadway, southRoadway, median ]
      [ ]

/-- `permit` (compliant): The subject occupies the roadway of h whose st.lane_direction its velocity follows; moving_against_carrier does not hold for any roadway it overlaps. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (-30 + 10 * (k : Int)) (-6) ]
      [ highway, northRoadway, southRoadway, median ]
      [ ]

/-- `idle` (not_applicable): The subject drives against a roadway's direction on a highway on which no st.median_or_divider lies: no divided highway. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (-30 + 10 * (k : Int)) 6 ]
      [ highway, northRoadway, southRoadway ]
      [ ]

/-- `blind` (unknown): The subject occupies a roadway of the divided highway h; st.lane_direction is absent on the source, so moving_against_carrier is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (-30 + 10 * (k : Int)) 6 ]
      [ highway, northRoadway, southRoadway, median ]
      [ ]

/-- `branch_1` (not_applicable): The subject crosses the opposing roadway's edge while its footprint overlaps an intersection lying on h: the exception for an intersection holds. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (-5 + 5 * (k : Int)) 6 ]
      [ highway, northRoadway, southRoadway, median, intersection ]
      [ ]

/-- `branch_2` (not_applicable): the subject, on the north roadway against its direction, overlaps
    the median section carrying the opening attribute: the exception for an opening holds. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (-2 + 2 * (k : Int)) 2 ]
      [ highway, northRoadway, southRoadway, median, openingSection ]
      [ ]
      (occupies := some [(1, 100), (1, 10), (1, 20), (1, 21)])

/-! An overpass: highway 200 crosses above highway 100 (x ∈ [-20, 20], y ∈ [-100, 100]); its own
    median 40 (x ∈ [4, 6]) lies on 200 only, its roadway 50 (x ∈ [6, 16], designated direction south)
    lies on 200 only. The subject drives north-east at 10 m/s (velocity (6, 8)) on the south
    roadway 11 of 100 (component +6 along east: with it), its footprint also over 200's roadway 50
    (component -8 along south: against it). 200 is excluded from the selection by an exception the
    subject's footprint meets on 200 alone, so only 100's roadways are judged. -/

def overpass : Structure := Build.rect 200 .highway (m (-20)) (m (-100)) (m 20) (m 100)

def overpassMedian : Structure :=
  { Build.rect 40 .medianOrDivider (m 4) (m (-100)) (m 6) (m 100) with
    opening := some false, ways := some [200] }

def overpassRoadway : Structure :=
  { Build.rect 50 .roadway (m 6) (m (-100)) (m 16) (m 100) with
    lane := some { direction := some Build.south }, ways := some [200] }

def overpassOpening : Structure :=
  { Build.rect 41 .medianOrDivider (m 4) (m (-10)) (m 6) (m 0) with
    opening := some true, ways := some [200] }

def overpassIntersection : Structure :=
  { Build.rect 60 .intersection (m 6) (m (-10)) (m 16) (m 0) with ways := some [200] }

def subjectNorthEast : RoadUser :=
  Build.user 1 [.motorVehicle] (m 6, m (-6)) (Units.ratio 3 5, Units.ratio 4 5)
    (Units.metresPerSecond 10) (m 2, m 1, cm 75)

/-- `branch_3` (compliant): with it on 100's south roadway; on overpass 200 it overlaps a median
    section of 200 carrying the opening attribute, so 200 is not selected and its roadway is not judged. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectNorthEast ]
      [ highway, northRoadway, southRoadway, median,
        overpass, overpassMedian, overpassRoadway, overpassOpening ]
      [ ]
      (occupies := some [(1, 100), (1, 11), (1, 200), (1, 40), (1, 41), (1, 50)])

/-- `branch_4` (compliant): as `branch_3`, but on 200 it overlaps an intersection lying on 200 only. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectNorthEast ]
      [ highway, northRoadway, southRoadway, median,
        overpass, overpassMedian, overpassRoadway, overpassIntersection ]
      [ ]
      (occupies := some [(1, 100), (1, 11), (1, 200), (1, 40), (1, 50), (1, 60)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_227_1_o1"
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant ]

end TrafficSpecWitness.NRS_484B_227_1_o1
