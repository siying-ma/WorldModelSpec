/-
  Witnesses for NRS_484B_227_1_o2.

  Geometry (the witness's own figures, none in the rule): a highway (region 10) running east–west,
  x ∈ [-100, 100], y ∈ [-20, 20]. On a divided highway a median (region 11, `ways = [10]`) runs
  along y ∈ [-1, 1]; the eastbound (right-hand) roadway lies south of it. The car (track 1, a
  motor vehicle, half-extent 2 m × 1 m × 75 cm) is observed at three instants 1 s apart. Where a
  body spans two regions its occupancy is stated; otherwise it follows from its position.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_227_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_227_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def carExtent : Q × Q × Q := (m 2, m 1, cm 75)

def car (pos : Vec) (heading : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] pos heading (Units.metresPerSecond 5) carExtent

def highway : Structure := Build.rect 10 .highway (m (-100)) (m (-20)) (m 100) (m 20)

/-- A median section on highway 10, with its opening attribute. -/
def median (id : RegionId) (x0 x1 : Q) (opening : Bool) : Structure :=
  { Build.rect id .medianOrDivider x0 (m (-1)) x1 (m 1) with
      ways := some [10], opening := some opening }

/-- `forbid` (violated): A car drives across a raised median section without an opening, between intersections: its footprint overlaps a st.median_or_divider region whose opening attribute is false, and no intersection. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m 0, m ((k : Int) * 2 - 2)) Build.north ]
      [ highway, median 11 (m (-100)) (m 100) false ]
      [ ]
      (occupies := some [(1, 10), (1, 11)])

/-- `permit` (compliant): A car moves along the right-hand roadway; its footprint overlaps no median or divider region. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m ((k : Int) * 5 - 5), m (-8)) Build.east ]
      [ highway, median 11 (m (-100)) (m 100) false ]
      [ ]
      (occupies := some [(1, 10)])

/-- `idle` (not_applicable): A car on an undivided highway (no st.median_or_divider on it) crosses its painted centre line. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m 0, m ((k : Int) * 2 - 2)) Build.north ]
      [ highway, { Build.rect 12 .centreLine (m (-100)) (cm (-10)) (m 100) (cm 10) with ways := some [10] } ]
      [ ]
      (occupies := some [(1, 10), (1, 12)])

/-- `blind` (unknown): A car moves next to the median; rel.occupies is declared absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m ((k : Int) * 5 - 5), m (-3)) Build.east ]
      [ highway, median 11 (m (-100)) (m 100) false ]
      [ ]
      (occupies := some [(1, 10)])

/-- `branch_1` (compliant): A car crosses the median through a crossover: its footprint overlaps a median region whose opening attribute is true. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m 0, m ((k : Int) * 2 - 2)) Build.north ]
      [ highway
      , median 11 (m (-100)) (m (-5)) false
      , median 13 (m (-5)) (m 5) true
      , median 14 (m 5) (m 100) false ]
      [ ]
      (occupies := some [(1, 10), (1, 13)])

/-- `branch_2` (compliant): A car turning at an intersection of the divided highway clips the median nose: its footprint overlaps the median and the st.intersection region. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m (-9), m (-2)) Build.north ]
      [ highway
      , median 11 (m (-100)) (m (-10)) false
      , median 14 (m 10) (m 100) false
      , { Build.rect 12 .intersection (m (-10)) (m (-20)) (m 10) (m 20) with ways := some [10] } ]
      [ ]
      (occupies := some [(1, 10), (1, 11), (1, 12)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_227_1_o2"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant ]

end TrafficSpecWitness.NRS_484B_227_1_o2
