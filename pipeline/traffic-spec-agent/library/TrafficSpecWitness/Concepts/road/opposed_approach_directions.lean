/-
  Witnesses for drv.road.opposed_approach_directions.

  One junction, mapped and nothing else: an intersection region 102, a 20 m × 10 m box from
  (-5, -5) to (5, 5), and two lane regions that are its approach segments — region 100 west of it,
  from (-25, -5) to (-5, 5), and region 101 east of it, from (5, -5) to (25, 5), each carrying the
  intersection it enters. No road user is built and no device: the concept reads the two regions'
  designated directions of travel alone — not the presence of any road user on either region, not
  the heading or the travel of any body, not which region lies left or right of the other, not the
  junction either runs into. Each trace is three instants a second apart (t = 0, 1000, 2000 ms);
  the map is the same in every scene and the concept reads the observation itself, with no window
  behind or ahead, so every instant decides on its own and no scenario needs a `window`.

  The instance's own figure: an opposition tolerance of 0.9, the cosine of the largest angle off
  exactly opposed (here about 26°) at which two designated directions are still read as opposed.

    holds — region 100 carries the designated direction [1, 0] and region 101 carries [-1, 0]: the
            sum of the products of the components is -1, below -0.9, so the two are opposed.
    fails — region 100 carries [1, 0] and region 101 carries [0, 1]: the sum of the products is 0,
            above -0.9, so the two are not opposed.
    blind — region 100 carries [1, 0] and the source declares no designated direction for region
            101 (`lane.direction` is `none` and the manifest declares `st.lane_direction` absent),
            so whether the two are opposed is unknown.
-/
import TrafficSpec.Concepts.road.opposed_approach_directions
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.road.opposed_approach_directions

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: (no track formal)
-- Formals ↦ regions: a ↦ 100, b ↦ 101

/-- The instance every scenario speaks about: the opposition tolerance the caller sets, 0.9, the
    cosine of the largest angle off exactly opposed still read as opposed. -/
def inst : Concept.Instance :=
  { name := "drv.road.opposed_approach_directions@w"
    concept := "drv.road.opposed_approach_directions"
    literals := []
    nats := []
    params := [("opposition_tolerance", .lit (Units.ratio 9 10) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The corners of an axis-aligned box, counter-clockwise. -/
def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

/-- The junction itself: a 10 m × 10 m intersection at the origin. -/
def junction : Structure := Build.region 102 .intersection (box (m (-5)) (m (-5)) (m 5) (m 5))

/-- The western approach segment, region 100: a lane running up to the junction, carrying the
    designated direction given. -/
def approachA (dir : Vec) : Structure :=
  Build.lane 100 (box (m (-25)) (m (-5)) (m (-5)) (m 5)) dir (enters := some 102)

/-- The eastern approach segment, region 101: a lane running up to the junction, carrying the
    designated direction given. -/
def approachB (dir : Vec) : Structure :=
  Build.lane 101 (box (m 5) (m (-5)) (m 25) (m 5)) dir (enters := some 102)

/-- The eastern approach segment as the source records it where it declares no designated
    direction for it: the lane is mapped and its `direction` is `none`. -/
def approachBBlind : Structure :=
  { Build.region 101 .lane (box (m 5) (m (-5)) (m 25) (m 5)) with
    lane := some { direction := none, entersIntersection := some 102 } }

/-- Three instants a second apart; the same map in each: the junction and its two approach
    segments, the first carrying `dirA`, the second the structure given. -/
def junctionTrace (dirA : Vec) (b : Structure) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t none
      [ ]  -- no road user is read
      [ junction, approachA dirA, b ]
      [ ]  -- devices

/-- `holds` (compliant): Two approach segments of one junction are mapped, one carrying the
    designated direction [1, 0] and the other [-1, 0]; the sum of the products of the components
    is -1, below the negative of the tolerance, so the directions are opposed. -/
def holdsTrace : Trace := junctionTrace Build.east (approachB Build.west)

/-- `fails` (violated): Two approach segments of one junction are mapped, one carrying the
    designated direction [1, 0] and the other [0, 1]; the sum of the products of the components is
    zero, above the negative of the tolerance, so the directions are not opposed. -/
def failsTrace : Trace := junctionTrace Build.east (approachB Build.north)

/-- `blind` (unknown): Two approach segments of one junction are mapped and the first carries the
    designated direction [1, 0], but the source declares no designated direction for the second,
    so whether the two are opposed is unknown. -/
def blindTrace : Trace := junctionTrace Build.east approachBBlind

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := []
    regions := [("a", 100), ("b", 101)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"] ]

end TrafficSpecWitness.Concepts.road.opposed_approach_directions
