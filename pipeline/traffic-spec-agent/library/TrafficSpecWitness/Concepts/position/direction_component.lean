/-
  Witnesses for drv.position.direction_component.

  The geometry (every figure here is the witness's own).
    The map, the same in all three traces: one structure, region 100, a one-way roadway — the
    rectangle from (−60, −60) to (60, 60) m, carrying the designated direction of travel (3, 4) m.
    The atom reads that direction normalised: divided by its larger component, 4, it is (3/4, 1),
    whose length is exactly 1.25 m, so the vector read is exactly the unit vector (0.6, 0.8),
    pointing north-east. The direction is deliberately off-axis so that both components of the
    projection do work.
    The body, track 1: a car, half-extents (2, 1, 1) m, travelling at 8 m/s. Three observations a
    second apart, the car moving by 8 m between them along its heading.
      holds — heading (3/5, 4/5), the way the roadway is designated, so its velocity is
        (4.8, 6.4) m/s and the projection is 4.8·0.6 + 6.4·0.8 = +8 m/s exactly. Positions
        (0, 0), (4.8, 6.4), (9.6, 12.8) m.
      fails — heading (−3/5, −4/5), the other way along the same roadway: velocity (−4.8, −6.4) m/s
        and the projection is −8 m/s exactly. Positions (0, 0), (−4.8, −6.4), (−9.6, −12.8) m.
      blind — the `holds` scene with the source declaring st.lane_direction absent: there is no
        direction to project onto, so each product and the sum are unknown.
    The instance's bounds, the caller's own figures: [+4, +12] m/s, an interval that holds travel
    with the designation at 8 m/s and excludes the −8 m/s of travel against it.
    The concept takes no formal parameter, so the instance gives none.
-/
import TrafficSpec.Concepts.position.direction_component
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.position.direction_component

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: r ↦ 100

/-- The designated direction of travel of region 100, written at length 5 m; the atom reads it
    normalised as the unit vector (0.6, 0.8). -/
def designated : Vec := (m 3, m 4)

/-- The unit vector along `designated`: the heading of a car travelling with the designation. -/
def withWay : Vec := (Units.ratio 3 5, Units.ratio 4 5)

/-- The unit vector against the designation. -/
def againstWay : Vec := (Units.ratio (-3) 5, Units.ratio (-4) 5)

def carSpeed : Q := Units.metresPerSecond 8

/-- Half-length, half-width, half-height of the car. -/
def carExtent : Q × Q × Q := (m 2, m 1, m 1)

/-- Region 100: the one-way roadway, carrying the designated direction of travel. -/
def roadway : Structure :=
  { Build.rect 100 .oneWayRoadway (m (-60)) (m (-60)) (m 60) (m 60) with
      lane := some { direction := some designated } }

/-- The car's position at observation `k`, travelling at 8 m/s along `heading` from the origin. -/
def carAt (heading : Vec) (k : Nat) : Vec :=
  Build.scale heading (Q.mul carSpeed (Q.ofInt (Int.ofNat k)))

def carTrace (heading : Vec) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (carAt heading k) heading carSpeed carExtent ]
      [ roadway ]
      [ ]

/-- The instance every scenario speaks about: no literal or nat formal, no formal parameter, and
    the interval the caller sets for travel with the designation at about 8 m/s. -/
def inst : Concept.Instance :=
  { name := "drv.position.direction_component@w"
    concept := "drv.position.direction_component"
    literals := []
    nats := []
    params := []
    bounds := some (.lit (Units.metresPerSecond 4) .metrePerSecond,
                    .lit (Units.metresPerSecond 12) .metrePerSecond)
  }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A car travels at 8 m/s along a one-way roadway whose designated direction runs the same way: the quantity reads about plus 8 m/s, within bounds the caller sets for travel with the designation. -/
def holdsTrace : Trace := carTrace withWay

/-- `fails` (violated): The same car travels at 8 m/s the other way along that roadway: the quantity reads about minus 8 m/s, outside those bounds. -/
def failsTrace : Trace := carTrace againstWay

/-- `blind` (unknown): The same roadway with the source declaring the designated direction of travel of structures absent: the quantity has no direction to project onto and is unknown. -/
def blindTrace : Trace := carTrace withWay

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    regions := [("r", 100)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"] ]

end TrafficSpecWitness.Concepts.position.direction_component
