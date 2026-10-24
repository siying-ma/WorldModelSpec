/-
  Witnesses for drv.interaction.following_on_way.

  One straight public way running east carries the three scenarios. Every figure below is the
  witness's own, including the four the instance gives the formal parameters: a motion tolerance
  of 2 km/h (about 0.56 m/s), an alignment tolerance of 0.9 (the cosine of about 26 degrees), an
  ordering resolution of 1 m and an abreast reach of 2 m.

  The map is one highway region, 120 m long and 20 m wide, from x = -20 m to x = 100 m and from
  y = -10 m to y = +10 m, with a paved shoulder of that way along its south side, from y = -10 m
  to y = -4 m, lying on it. No lane region is built: the concept reads membership of the public
  way and nothing of lanes, and the narratives put the two bodies on the shoulder, in no lane.

  The two bodies are cars, 4 m long and 1.8 m wide (half-extents 2 m, 0.9 m, 0.75 m): the
  follower is track 1, the formal `f`, and the leader is track 2, the formal `l`. Both point east
  and both travel east at 20 m/s, 20 m further on at each observation. Three instants one second
  apart from t = 0, so t = 0 s, 1 s, 2 s. Nothing in the body looks behind or ahead of the
  observation, so no padding and no window are needed: every scenario is read over the whole of
  its trace.

  Occupancy is derived from the geometry, so each scene says which regions a footprint overlaps
  by where the body stands.

  holds:  both cars run down the shoulder at y = -7 m, the leader's reference point 5 m east of
          the follower's and at the same northing. Both footprints overlap the one highway
          region; each speed, 20 m/s, stands far above the motion tolerance, so neither body is
          at rest; the two headings are identical, so the cosine between them is 1, well above
          the tolerance of 0.9; both move the way they point, so neither is backing and the two
          move alike; the offset of the leader's reference point from the follower's, in the
          follower's frame, is 5 m ahead, at or above the ordering resolution of 1 m; and its
          lateral component is zero, within the abreast reach of 2 m. The concept holds at each
          of the three observations.
  fails:  the same two bodies on the same way, pointing and travelling east, the leader's
          reference point 5 m east of the follower's as before but 6 m to its left, at y = -1 m
          on the way rather than on the shoulder. Everything else is as in holds — one and the
          same way, both moving, the headings aligned, both forward, the offset 5 m ahead — and
          the lateral component of the offset is 6 m, beyond the abreast reach of 2 m: the two
          travel beside one another, not in one line. The concept fails at each of the three
          observations, on the lateral offset alone.
  blind:  the holds trace itself, read by a source that reports no bearing between the two
          bodies: its manifest declares rel.bearing absent. A manifest that drops the bearing
          alone would not leave it unreported, since the library computes the bearing of one body
          from another from their positions and the first one's heading wherever the source does
          not measure one; and a scene may not withhold the position of a body whose occupancy is
          observed, the adapter lint requiring a footprint of it. The source therefore declares
          kin.position absent as well: a source that cannot tell where a body is cannot report
          the offset between two reference points, measured or computed. Everything else is as in
          holds — the way both footprints overlap, the two speeds, the two headings and the two
          velocities are all observed and all decided — so the concept is unknown, and unknown
          for the offset alone.
-/
import TrafficSpec.Concepts.interaction.following_on_way
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.following_on_way

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: f ↦ 1, l ↦ 2

/-- The instance every scenario speaks about: every parameter given a value through a `Units`
    constructor. The motion tolerance is 2 km/h, the alignment tolerance 0.9 (the cosine of about
    26 degrees), the ordering resolution 1 m and the abreast reach 2 m — the witness's own figures
    for what counts as no movement at all, for how nearly the two bodies must point one way, for
    how far the one reference point must stand clear of the other and for how far beside it the
    one body may travel and still travel in its line. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.following_on_way@w"
    concept := "drv.interaction.following_on_way"
    literals := []
    nats := []
    params := [("motion_speed_tolerance", .lit (Units.kmh 2) .metrePerSecond),
               ("heading_alignment_cosine", .lit (Units.ratio 9 10) .ratio),
               ("ordering_resolution", .lit (Units.metres 1) .metre),
               ("abreast_reach", .lit (Units.metres 2) .metre)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

-- ---------------------------------------------------------------------------------------------
-- The way: one straight public way running east, with a paved shoulder along its south side
-- ---------------------------------------------------------------------------------------------
/-- The public way the two bodies share: the entire way between its boundary lines. -/
def way : Structure := Build.rect 10 .highway (m (-20)) (m (-10)) (m 100) (m 10)

/-- A paved shoulder of that way, lying on it; read by nothing in the body. -/
def shoulder : Structure :=
  { Build.rect 11 .shoulder (m (-20)) (m (-10)) (m 100) (m (-4)) with
      paved := some true, ways := some [10] }

def structures : List Structure := [way, shoulder]

/-- A car of the witness at a place on the way, heading east at 20 m/s. -/
def car (track : TrackId) (x y : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) Build.east (Units.metresPerSecond 20) (m 2, cm 90, cm 75)

/-- The easting of the follower at the observation at second `k`: 20 m further on each second. -/
def easting (k : Nat) : Q := m (20 * Int.ofNat k)

-- ---------------------------------------------------------------------------------------------
-- holds (and blind): both bodies on the shoulder, the leader 5 m ahead and square behind it
-- ---------------------------------------------------------------------------------------------
/-- `holds` (compliant): Two motor vehicles occupy one and the same highway region, a paved shoulder of it, neither in any lane. Both point east and both travel east at 20 m/s. l's reference point lies 5 m ahead of f's along the direction both point, with no lateral offset between them. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (easting k) (m (-7))
      , car 2 (Q.add (easting k) (m 5)) (m (-7)) ]
      structures
      []

-- ---------------------------------------------------------------------------------------------
-- fails: the leader 5 m ahead but 6 m to the follower's left, beyond the abreast reach
-- ---------------------------------------------------------------------------------------------
/-- `fails` (violated): The same two bodies on the same way, pointing and travelling east, but l's reference point lies 5 m ahead of f's and 6 m to its left, beyond the abreast reach the caller sets: the two travel beside one another, not in one line. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (easting k) (m (-7))
      , car 2 (Q.add (easting k) (m 5)) (m (-1)) ]
      structures
      []

-- ---------------------------------------------------------------------------------------------
-- blind: the holds scene from a source that reports no bearing between the two bodies
-- ---------------------------------------------------------------------------------------------
/-- `blind` (unknown): The same scene as the holding one, but the source does not observe the bearing of l from f, so the offset between the two reference points cannot be read and the concept reports unknown. -/
def blindTrace : Trace := holdsTrace

/-- The atoms the blind source does not observe: the bearing of one body from another, and the
    position of a body, from which a bearing would otherwise be computed. -/
def blindAbsent : List String := ["rel.bearing", "kin.position"]

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

end TrafficSpecWitness.Concepts.interaction.following_on_way
