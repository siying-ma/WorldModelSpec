/-
  Witnesses for NRS_484B_227_1_o2.

  Geometry (the witness's own figures, nowhere in the rule): a highway (region 10) along +x,
  x ∈ [0, 200], y ∈ [-14, 14]. A median (region 20) x ∈ [0, 90], y ∈ [-2, 2], lies on it
  (`ways := [10]`); the eastbound roadway is y < -2, the westbound y > 2. In `branch_2` an
  intersection (region 30) x ∈ [90, 110], y ∈ [-14, 14], lies on the highway beyond the median's
  nose. The subject (track 1, a motor vehicle, half-extent 2.5 m × 1 m) is sampled three times at
  1 s spacing. Occupancy is stated per instant from the footprint (a body may straddle two
  regions): crossing north at x = 50 from y = -6 to y = 6, the footprint (y ± 2.5) overlaps the
  median at y = 0 only.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_227_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_227_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def hwy : Structure := Build.rect 10 .highway (m 0) (m (-14)) (m 200) (m 14)
def median (opening : Bool) : Structure :=
  { Build.rect 20 .medianOrDivider (m 0) (m (-2)) (m 90) (m 2) with
      ways := some [10], opening := some opening }
def junction : Structure :=
  { Build.rect 30 .intersection (m 90) (m (-14)) (m 110) (m 14) with ways := some [10] }

def body : Q × Q × Q := (cm 250, cm 100, cm 75)

/-- The subject crossing north over the median at x = 50: y = -6, 0, 6. -/
def crosser (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 50, m (-6 + 6 * (k : Int))) Build.north (m 6) body

/-- Its occupancy: the median only at the middle instant. -/
def crosserOcc (k : Nat) : List (TrackId × RegionId) :=
  if k == 1 then [(1, 10), (1, 20)] else [(1, 10)]

/-- `forbid` (violated): A st.median_or_divider m without the opening attribute lies on highway h; the subject's footprint overlaps m as it drives across it away from any intersection. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ crosser k ]
      [ hwy, median false ]
      [ ]
      (occupies := some (crosserOcc k))

/-- `permit` (compliant): The subject drives along its roadway of h; its footprint never overlaps the divider. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (30 + 15 * (k : Int)), m (-7)) Build.east (m 15) body ]
      [ hwy, median false ]
      [ ]
      (occupies := some [(1, 10)])

/-- `idle` (not_applicable): The subject drives over a painted island on a highway on which no st.median_or_divider lies. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ crosser k ]
      [ hwy ]
      [ ]
      (occupies := some [(1, 10)])

/-- `blind` (unknown): The subject drives on h next to the divider; rel.occupies is absent on the source, so whether its footprint overlaps the divider is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (30 + 15 * (k : Int)), m (-4)) Build.east (m 15) body ]
      [ hwy, median false ]
      [ ]
      (occupies := some [(1, 10)])

/-- `branch_1` (compliant): The subject crosses the divider where the divider region it overlaps carries the opening attribute (a crossover). -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ crosser k ]
      [ hwy, median true ]
      [ ]
      (occupies := some (crosserOcc k))

/-- `branch_2` (not_applicable): The subject's footprint overlaps the nose of the divider while it also overlaps an intersection lying on h. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (88 + (k : Int)), m (-1)) Build.east (m 1) body ]
      [ hwy, median false, junction ]
      [ ]
      (occupies := some [(1, 10), (1, 20), (1, 30)])

/-- `branch_3` (compliant): the subject straddles two highways: on highway 10 it overlaps the nose
    of that highway's median inside an intersection lying on highway 10 only; highway 11
    (x ∈ [80, 200]) is divided by median 21 (x ∈ [150, 200]) which the subject is clear of. The
    intersection exception lifts the duty on highway 10 only; on highway 11 it is kept and met. -/
def hwy2 : Structure := Build.rect 11 .highway (m 80) (m (-14)) (m 200) (m 14)
def median2 : Structure :=
  { Build.rect 21 .medianOrDivider (m 150) (m (-2)) (m 200) (m 2) with
      ways := some [11], opening := some false }

def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (88 + (k : Int)), m (-1)) Build.east (m 1) body ]
      [ hwy, hwy2, median false, median2, junction ]
      [ ]
      (occupies := some [(1, 10), (1, 11), (1, 20), (1, 30)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_227_1_o2"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant ]

end TrafficSpecWitness.NRS_484B_227_1_o2
