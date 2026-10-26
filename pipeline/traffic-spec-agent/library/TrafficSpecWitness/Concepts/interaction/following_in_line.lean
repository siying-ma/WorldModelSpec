/-
  Witnesses for drv.interaction.following_in_line.

  One straight roadway running east carries the three scenarios: a rectangle from x = -50 m to
  x = 200 m and 16 m across, centred on y = 0, whose region carries its boundary. The scene
  carries no lane at all, which is the point of the concept: the relation is decided on the
  roadway alone.

  Two cars, each 4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m): track 1 is the formal `f`,
  track 2 the formal `l`. Both head due east at 15 m/s and advance 15 m over each second. Three
  instants one second apart from t = 0, so t = 0 s, 1 s, 2 s; the body is a statement at the
  instant and looks neither behind nor ahead, so no window is set and no padding is needed.

  Every figure here is the witness's own, the three the instance gives the formal parameters
  included: the heading-alignment tolerance 0.95 (a cosine, about 18 degrees), the following
  reach 30 m and the line offset 1.5 m. Nothing of the two bodies' relation is supplied to the
  scenes: the headings, the gap between the nearest points and the bearing are all computed from
  the positions, headings and extents the scenes carry.

  holds:  track 1 at x = 0 m and track 2 at x = 20 m at the first instant, both at y = 0, both
          heading due east. The cosine of the angle between the headings is 1, above the
          tolerance; the longitudinal distance between the nearest points is 20 m less the two
          half-lengths, 16 m, positive and inside the 30 m reach; the lateral offset of the two
          reference points is zero, inside the 1.5 m line offset. Track 1 runs in track 2's line,
          behind it, at each of the three instants.
  fails:  the same roadway, with track 2 3.5 m to the left of track 1 (y = 3.5 m against y = 0)
          and 20 m ahead of it. The headings are still aligned and the longitudinal distance
          between the nearest points is still 16 m, inside the reach, but the lateral offset of
          the two reference points is 3.5 m, beyond the 1.5 m line offset: track 2 runs abreast
          of track 1's neighbouring line of travel, not in it. The concept fails at every
          instant, and it is the lateral offset alone that makes it fail.
  blind:  the holds scenes on a source that reports each body's position, heading and speed and
          declares the gap between the nearest points of two bodies absent. Because the library
          computes that gap from the two bodies' extents wherever a source supplies no measured
          value for it, a source that does not report the gap is one that does not report the
          extents either, and the manifest declares both absent (`rel.surface_gap`, `kin.extent`):
          the one statement of the source is that it gives no distance between two bodies'
          nearest points. The headings are observed, so the alignment is decided true; the bearing
          is taken from the two reference points and f's heading, so the lateral offset is decided
          inside the line offset; the longitudinal distance by which the leader stands ahead is
          unobserved. Neither of the two decided readings is false, so the relation is unknown,
          and it is unknown for `rel.surface_gap` — the atom of the element this scenario blinds.
-/
import TrafficSpec.Concepts.interaction.following_in_line
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.following_in_line

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: f ↦ 1, l ↦ 2

/-- The instance every scenario speaks about: every parameter given a value through a `Units`
    constructor. The heading-alignment tolerance is the cosine 0.95, the following reach 30 m and
    the line offset 1.5 m — the witness's own figures for the observer's three tolerances. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.following_in_line@w"
    concept := "drv.interaction.following_in_line"
    literals := []
    nats := []
    params :=
      [ ("heading_alignment_cosine", .lit (Units.ratio 95 100) .ratio)
      , ("following_reach", .lit (Units.metres 30) .metre)
      , ("line_offset", .lit (Units.centimetres 150) .metre) ]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The roadway the three scenarios run on: one region, its boundary carried, and no lane. -/
def roadway : Structure := Build.rect 11 .roadway (m (-50)) (m (-8)) (m 200) (m 8)

/-- The easting of a car at the observation at second `k`, from its easting at the first: 15 m
    further on each second. -/
def easting (x0 : Int) (k : Nat) : Q := m (x0 + 15 * Int.ofNat k)

/-- A car of the witness at a place on the roadway, heading due east at 15 m/s, 4 m long and 2 m
    wide. -/
def car (track : TrackId) (x y : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) Build.east (Units.metresPerSecond 15) (m 2, m 1, m 1)

/-- `holds` (compliant): Two cars run east along one roadway whose region carries its boundary. Track 1 is at x=0, track 2 at x=20, both heading due east and both at 15 m/s, their reference points at the same lateral offset from the roadway's axis, their positions advancing 15 m over each second. The cosine of the angle between the headings is 1, above the tolerance; the longitudinal distance between the nearest points is about 16 m, positive and within the reach; the lateral offset of the reference points is zero. Track 1 runs in track 2's line, behind it. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (easting 0 k) (m 0)
      , car 2 (easting 20 k) (m 0) ]
      [ roadway ]
      []

/-- `fails` (violated): The same roadway, but track 2 runs 3.5 m to the left of track 1 and 20 m ahead of it, both heading due east at 15 m/s with positions advancing 15 m over each second. The headings are aligned and the longitudinal distance is within the reach, but the lateral offset of the two reference points, 3.5 m, exceeds the line offset: track 2 is abreast of track 1's neighbouring line of travel, not in it, so track 1 does not run in track 2's line. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (easting 0 k) (m 0)
      , car 2 (easting 20 k) (cm 350) ]
      [ roadway ]
      []

/-- `blind` (unknown): The same two bodies, aligned and offset as in the holds case, on a source that reports headings and bearings but declares the gap between the nearest points of two bodies absent. The longitudinal distance by which the leader stands ahead is unobserved, so the relation is unknown. -/
def blindTrace : Trace := holdsTrace

/-- What the blind source does not report: the gap between the nearest points of two bodies, and
    the extents of the bodies the library would otherwise take that gap from. The two together are
    one statement of the source — that it does not report the distance between two bodies' nearest
    points — and the atom that leaves the relation undecided is `rel.surface_gap`. -/
def blindAbsent : List String := ["rel.surface_gap", "kin.extent"]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("f", 1), ("l", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) blindAbsent ]

end TrafficSpecWitness.Concepts.interaction.following_in_line
