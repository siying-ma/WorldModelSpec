/-
  Witnesses for drv.motion.backing.

  One suburban street carries all three scenarios. Every figure below is the witness's own,
  including the 0.05 m/s the instance gives the formal parameter `backing_speed_tolerance` —
  5 cm/s, the magnitude of rearward motion below which this source's sampled velocity does not
  stand clear of none.

  The street (+x east, +y north):

    - region 11, the roadway: x = -100 m to 100 m, 10 m wide (y = -5 m to 5 m);
    - region 12, the driveway entrance: x = -14 m to -6 m, y = 5 m to 15 m, meeting the roadway
      at its north edge.

  Neither region is read by the body — the concept says nothing about where on the road the road
  user is — they are the scene the narratives describe.

  The subject is a van, 5 m long and 2 m wide (half-extents 2.5 m, 1 m, 1 m), track 1, the formal
  `u`. Three instants 1 s apart from t = 0. Nothing in the body looks behind or ahead, so no
  padding and no window are needed.

  holds:  the van reverses out of the driveway. Its body points north, up the driveway, and it
          moves south at 1 m/s: the velocity vector is (0, -1) m/s against a heading of (0, 1),
          so the component of the velocity along the heading is -1 m/s, which is at or below
          -0.05 m/s. It stands at y = 10 m, 9 m and 8 m. The body is true at every instant.
  fails:  the van rolls forward along the roadway, east at 10 m/s at x = 0 m, 10 m and 20 m, with
          reverse the gear selected (kin.gear = -1). The velocity vector is (10, 0) m/s and the
          heading (1, 0), so the component along the heading is +10 m/s, far above -0.05 m/s.
          The body is false at every instant: what the gear says is not read, and the ontology
          carries no reversing lamp at all (sig.brake_lamp is not one and carries nothing about
          direction), so the lit lamps of the narrative are no part of the scene either.
  blind:  the holds scene on a source whose manifest declares kin.heading absent: the velocity
          vector is observed, the direction the body points is not, so each product in the
          component is unknown and the comparison is unknown for that atom alone.
-/
import TrafficSpec.Concepts.motion.backing
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.backing

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Formals ↦ tracks: u ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. The
    magnitude of rearward motion below which this source's velocity does not stand clear of none
    is 0.05 m/s — 50 000 µm/s, 5 cm/s — the witness's own figure. -/
def inst : Concept.Instance :=
  { name := "drv.motion.backing@w"
    concept := "drv.motion.backing"
    literals := []
    nats := []
    params := [("backing_speed_tolerance", .lit (Units.micrometresPerSecond 50000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The roadway of the street: 200 m of improved way, 10 m wide. -/
def roadway : Structure := Build.rect 11 .roadway (m (-100)) (m (-5)) (m 100) (m 5)

/-- The driveway entrance, meeting the roadway at its north edge. -/
def driveway : Structure := Build.rect 12 .drivewayOrAlleyEntrance (m (-14)) (m 5) (m (-6)) (m 15)

/-- The street, in every scene. -/
def street : List Structure := [roadway, driveway]

/-- A van of the witness: 5 m long and 2 m wide, its body pointing `heading`. -/
def van (track : TrackId) (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] pos heading speed (cm 250, m 1, m 1)

/-- `holds` (compliant): A van reverses out of a driveway: its velocity vector points opposite to its heading, so the component of the velocity along the heading is negative and its magnitude stands clear of the tolerance the caller sets. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (van 1 (m (-10), m (10 - (k : Int))) Build.north (mps 1))
          (fun kin => { kin with velocity := some (Build.scale Build.south (mps 1)) }) ]
      street
      []

/-- `fails` (violated): A van rolls forward along the roadway: the component of its velocity along its heading is positive and well above the tolerance, although reverse is the gear selected and its reversing lamps are lit. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (van 1 (m (10 * (k : Int)), m (-2)) Build.east (mps 10))
          (fun kin => { kin with gear := some (-1) }) ]
      street
      []

/-- `blind` (unknown): The holds situation, except that the source declares the heading absent: the velocity vector is observed, but the direction the body points is not, so the component of the velocity along the heading is not determined. -/
def blindTrace : Trace := holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.heading"] ]

end TrafficSpecWitness.Concepts.motion.backing
