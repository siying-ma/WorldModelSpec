/-
  Witnesses for drv.road.two_directional_way.

  One stretch of road, mapped and nothing else: a highway region 100, a 120 m × 24 m box from
  (-60, -12) to (60, 12) — the way the caller singles out — and two roadway segments lying on it,
  region 101 the northern half from (-60, 1) to (60, 10) and region 102 the southern half from
  (-60, -10) to (60, -1), each carrying a designated direction of travel and recording region 100
  as the way it lies on. Where the stretch is divided, a median region 103 from (-60, -1) to
  (60, 1) lies on the way between the two segments. No road user is built and no device: the
  concept reads the configuration of the way alone — not the presence of any road user on it, not
  the number of its lanes or roadways, not which hand of it a road user keeps, not any junction it
  meets. Each trace is three instants a second apart (t = 0, 1000, 2000 ms); the map is the same in
  every scene and the concept reads the observation itself, with no window behind or ahead, so
  every instant decides on its own and no scenario needs a `window`.

  The instance's own figure: an opposition tolerance of 0.9, the cosine of the largest angle off
  exactly opposed (here about 26°) at which two designated directions are still read as opposite
  directions.

    holds — the northern segment carries the designated direction [-1, 0] and the southern one
            [1, 0], and no median or dividing section is mapped at all, so nothing divides the way
            and travel on it is designated in two opposed directions.
    fails — the median region 103 lies on the way between the two segments, so a structure divides
            the way and it is not two-directional. The two segments carry the opposed designated
            directions [-1, 0] and [1, 0], so the dividing section is the whole of the reason: the
            way is not two-directional exactly because that region lies on it.
    blind — the two segments carry opposed designated directions [-1, 0] and [1, 0] and the median
            region is mapped, but the source records no way for any of the three regions (`ways`
            is `none` and the manifest declares `st.on_way` absent), so whether a dividing section
            lies on the way, and whether two regions lying on it carry opposed directions, is
            unknown.
-/
import TrafficSpec.Concepts.road.two_directional_way
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.road.two_directional_way

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: (no track formal)
-- Formals ↦ regions: w ↦ 100

/-- The instance every scenario speaks about: the opposition tolerance the caller sets, 0.9, the
    cosine of the largest angle off exactly opposed still read as opposite directions. -/
def inst : Concept.Instance :=
  { name := "drv.road.two_directional_way@w"
    concept := "drv.road.two_directional_way"
    literals := []
    nats := []
    params := [("opposition_tolerance", .lit (Units.ratio 9 10) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The way itself, region 100: a mapped highway, a 120 m × 24 m box. -/
def way : Structure := Build.rect 100 .highway (m (-60)) (m (-12)) (m 60) (m 12)

/-- A roadway segment of the stretch, carrying the designated direction given and recording the
    ways it lies on (`none` where the source does not observe them). -/
def segment (id : RegionId) (y0 y1 : Q) (dir : Option Vec)
    (onWay : Option (List RegionId)) : Structure :=
  { Build.rect id .roadway (m (-60)) y0 (m 60) y1 with
    lane := some { direction := dir }
    ways := onWay }

/-- The northern roadway segment, region 101. -/
def northSegment (dir : Vec) (onWay : Option (List RegionId)) : Structure :=
  segment 101 (m 1) (m 10) (some dir) onWay

/-- The southern roadway segment, region 102. -/
def southSegment (dir : Vec) (onWay : Option (List RegionId)) : Structure :=
  segment 102 (m (-10)) (m (-1)) (some dir) onWay

/-- A median region, region 103: the dividing section between the two roadway segments. -/
def median (onWay : Option (List RegionId)) : Structure :=
  { Build.rect 103 .medianOrDivider (m (-60)) (m (-1)) (m 60) (m 1) with
    ways := onWay }

/-- Three instants a second apart; the same map in each: the way and the regions given. -/
def stretch (structures : List Structure) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t none
      [ ]  -- no road user is read
      (way :: structures)
      [ ]  -- devices

/-- `holds` (compliant): A mapped highway carries two roadway segments, one with designated
    direction [-1, 0] and one with [1, 0], and no median or dividing section lies on it, so the
    way is two-directional. -/
def holdsTrace : Trace :=
  stretch [ northSegment Build.west (some [100]), southSegment Build.east (some [100]) ]

/-- `fails` (violated): A mapped highway carries two roadway segments and a median region lying on
    the way between them, so the way is divided and not two-directional. The segments carry the
    opposed designated directions [-1, 0] and [1, 0], so the dividing section is the whole reason
    the way is not two-directional: were it not on the way, the way would be. -/
def failsTrace : Trace :=
  stretch [ northSegment Build.west (some [100]), southSegment Build.east (some [100])
          , median (some [100]) ]

/-- `blind` (unknown): A mapped highway carries two roadway segments with opposed designated
    directions, but the source does not observe which structure regions lie on the way, so whether
    a dividing section lies on it is unknown. -/
def blindTrace : Trace :=
  stretch [ northSegment Build.west none, southSegment Build.east none, median none ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := []
    regions := [("w", 100)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.on_way"] ]

end TrafficSpecWitness.Concepts.road.two_directional_way
