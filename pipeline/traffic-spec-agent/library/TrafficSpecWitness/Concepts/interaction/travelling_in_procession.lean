/-
  Witnesses for drv.interaction.travelling_in_procession.

  One straight stretch of road running east, mapped as lane 10: the box from (-400, -2) to
  (400, 2), 800 m long and 4 m wide, carrying the designated direction east. Every car is 4 m long
  and 1.8 m wide (half-extents 2 m, 0.9 m, 0.75 m) and carries heading east, so the cosine of the
  angle between any two headings is 1. Track 1 is the road user judged, which the formal `u` is
  grounded to; the cars ahead of it are tracks 2, 3, … in order. Occupancy is derived from the
  geometry: each car lies in lane 10, whose polygon contains its position. No device is built and
  no region formal is passed: the concept reads the order of the bodies in their lane, their
  headings, the judged road user's speed and the longitudinal body gap alone — not the number of
  cars in the line, not their organization, not the adequacy of the gaps, not the lawfulness of the
  travel.

  Each trace is three instants a second apart (t = 0, 1000, 2000 ms) with the same scene in each,
  padded with four further seconds of the first scene before t = 0 (`Build.pad`), because the body
  looks back over the succession window: every scenario names the window (0, 2000 ms), the instants
  it speaks about, and the lookback from each of them is covered by the padding rather than
  truncated at the start of the trace. The cars keep their positions from instant to instant, as
  the concept reads a gap and an order at each observation and no path length is observed.

  The instance's own figures: a succession window of 3 s, the time over which the close succession
  must have held for the travel to be read as travel in one line; a maximum succession gap of 15 m,
  the largest longitudinal body gap still read as one close succession; an alignment tolerance of
  0.95, the cosine at or below which two headings are no longer read as one direction (about 18°
  apart); and a motion tolerance of 1 m/s, the speed at or below which a reading counts as no
  travel.

    holds — six cars travel nose to tail eastward in lane 10 at 20 m/s, their centres 14 m apart
            (x = 0, 14, 28, 42, 56, 70), so the longitudinal gap between the nearest points of two
            successive bodies is 10 m. The road user judged (track 1, at x = 0) has track 2 ahead
            of it in its own lane, headings aligned and its own speed well above the motion
            tolerance, and the gap of 10 m is within the maximum of 15 m; the scene is the same at
            every instant of the padded window behind, so the succession has held throughout.
    fails — track 1 travels alone eastward in lane 10 at 20 m/s, the only other car (track 2) being
            300 m ahead of it at x = 300: that car is ahead of it in its lane with headings
            aligned, but the longitudinal body gap of 296 m is far beyond the maximum succession
            gap of 15 m, so at no observation of the window behind is any road user followed within
            the gap and no travel in one line is read.
    blind — the scene of `holds`, the six cars nose to tail in lane 10, but the source supplies no
            body gaps and no body extents: the manifest declares `rel.surface_gap` absent, and
            `kin.extent` with it, since a source that measures no bodies' extents can read no gap
            between the nearest points of two bodies — the footprints Core would compute the gap
            from are undefined. The order in the lane, the headings and the speed are still
            observed, so the car ahead is plainly followed; whether its body lies within the
            maximum succession gap, and hence whether the line is a close succession, is unknown.
-/
import TrafficSpec.Concepts.interaction.travelling_in_procession
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.travelling_in_procession

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: a succession window of 3 s, a maximum succession gap
    of 15 m, an alignment tolerance of 0.95 and a motion tolerance of 1 m/s. Every figure is the
    witness's own. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.travelling_in_procession@w"
    concept := "drv.interaction.travelling_in_procession"
    literals := []
    nats := []
    params := [("procession_window", .lit (Units.seconds 3) .second),
               ("procession_gap_max", .lit (Units.metres 15) .metre),
               ("alignment_tolerance", .lit (Units.ratio 95 100) .ratio),
               ("motion_speed_tolerance", .lit (Units.metresPerSecond 1) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- A rectangular polygon from two corners. -/
def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

/-- Lane 10: an 800 m × 4 m lane from (-400, -2) to (400, 2), designated east. -/
def laneEast : Structure := Build.lane 10 (box (m (-400)) (m (-2)) (m 400) (m 2)) Build.east

/-- A car travelling east at 20 m/s from the given position on the lane's centre line: 4 m long,
    1.8 m wide. -/
def car (track : TrackId) (x : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, m 0) Build.east (Units.metresPerSecond 20) (m 2, cm 90, cm 75)

/-- Three instants a second apart with the same cars and lane in each, with four seconds of the
    first scene before them so that the succession window behind t = 0 is covered. -/
def still (users : List RoadUser) : Trace :=
  Build.pad
    (Build.trace 3 0 (Units.seconds 1) fun _k t =>
      Build.scene t (some 1) users [ laneEast ]
        [ ])  -- devices
    (Units.seconds 4) Q.zero (Units.seconds 1)

/-- The six cars of the procession, nose to tail: centres 14 m apart, so 10 m between the nearest
    points of two successive bodies. -/
def procession : List RoadUser :=
  [ car 1 (m 0), car 2 (m 14), car 3 (m 28), car 4 (m 42), car 5 (m 56), car 6 (m 70) ]

/-- `holds` (compliant): six cars nose to tail eastward in lane 10 at 20 m/s with 10 m between
    successive bodies. At every observation of the window behind, track 1 follows track 2 in its
    own lane — ahead of it along the lane's direction, headings aligned, its own speed above the
    motion tolerance — within the maximum succession gap of 15 m. -/
def holdsTrace : Trace := still procession

/-- `fails` (violated): track 1 travels alone, the only other car 300 m ahead in the same lane, so
    the longitudinal body gap of 296 m exceeds the maximum succession gap at every observation of
    the window behind and no close succession is read. -/
def failsTrace : Trace := still [ car 1 (m 0), car 2 (m 300) ]

/-- `blind` (unknown): the scene of `holds`, with the manifest declaring `rel.surface_gap` absent,
    and `kin.extent` with it — the bodies' extents being what Core would compute the gap between
    the nearest points from. The car ahead is still followed in the lane, but the gap between the
    bodies cannot be read. -/
def blindTrace : Trace := holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected
    window := some (0, 2000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap", "kin.extent"] ]

end TrafficSpecWitness.Concepts.interaction.travelling_in_procession
