/-
  Witnesses for LVMC_11_16_060.

  The geometry. One straight way running east: the highway region 10, a rectangle 600 m long and
  24 m wide (y from -12 to 12). Inside its boundary lines, each with `ways := [10]`:
    * the roadway 11, 12 m wide (y -6 … 6);
    * the lane 12, 6 m wide, direction east (y 0 … 6);
    * the shoulder 13 (y 6 … 10) — inside the way, outside the roadway and the lane;
    * the bicycle lane 14 (y -10 … -6);
    * the intersection 15, a 40 m square across the way (x 280 … 320).
  A second way, the highway 20 (y 20 … 44) with its own lane 22 (`ways := [20]`), is built only for
  the witness in which a sign governs a region of a different way.

  The subject is track 1, a motor vehicle 4 m by 2 m, travelling east along the region it occupies
  and advancing 20 m between the three observations, one second apart. It rides at y = 2 on the
  roadway / lane, and at y = 8 on the shoulder.

  The devices: speed limit sign 1, with the governed regions, stated value and kind each witness
  needs — 45 mph as a maximum (a different limit), 15 mph as a minimum (no limit in place of the
  prima facie maximum), 25 mph as a zone (not a different limit).

  The speeds: 35 mph where the witness breaks the prima facie limit, 20 mph where it keeps it — a
  clear margin either side of the 25 mph the section states. Every figure here is the witness's own
  and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_16_060
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_16_060

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mph (n : Int) : Q := Units.mph n

-- Binders ↦ tracks: d ↦ 1

/-- The way the subject travels. -/
def way : Structure := Build.rect 10 .highway (m 0) (m (-12)) (m 600) (m 12)

/-- The roadway of that way. -/
def carriageway : Structure :=
  { Build.rect 11 .roadway (m 0) (m (-6)) (m 600) (m 6) with ways := some [10] }

/-- A lane of that way. -/
def travelLane : Structure :=
  { Build.lane 12 [(m 0, m 0), (m 600, m 0), (m 600, m 6), (m 0, m 6)] Build.east with
      ways := some [10] }

/-- The shoulder of that way: inside its boundary lines, outside the roadway and the lane. -/
def verge : Structure :=
  { Build.rect 13 .shoulder (m 0) (m 6) (m 600) (m 10) with ways := some [10], paved := some true }

/-- The bicycle lane of that way. -/
def bikeway : Structure :=
  { Build.rect 14 .bicycleLaneOrPath (m 0) (m (-10)) (m 600) (m (-6)) with ways := some [10] }

/-- An intersection on that way. -/
def crossing : Structure :=
  { Build.rect 15 .intersection (m 280) (m (-12)) (m 320) (m 12) with ways := some [10] }

/-- A second way, which the subject does not travel. -/
def otherWay : Structure := Build.rect 20 .highway (m 0) (m 20) (m 600) (m 44)

/-- A lane of that second way. -/
def otherLane : Structure :=
  { Build.lane 22 [(m 0, m 24), (m 600, m 24), (m 600, m 30), (m 0, m 30)] Build.east with
      ways := some [20] }

/-- The subject at observation `k`, travelling east at `speed` along `y`. -/
def subject (speed : Q) (y : Q) (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (50 + 20 * (k : Int)), y) Build.east speed (m 2, m 1, m 1)

/-- The posted speed limit sign: `governs`, the value it states, and its kind. -/
def limitSign (governs : List RegionId) (v : Q) (kind : SpeedSignKind) : Device :=
  Build.speedLimit 1 governs v kind

/-- `forbid` (violated): The subject drives at thirty-five miles per hour along the roadway of a residential city street on which no speed limit sign is posted at all. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 35) (m 2) k ]
      [ way, carriageway ]
      [ ]

/-- `permit` (compliant): The subject drives at twenty miles per hour along the same unposted street. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 20) (m 2) k ]
      [ way, carriageway ]
      [ ]

/-- `idle` (not_applicable): The subject drives at thirty-five miles per hour in a lane of a highway, and a speed limit sign of kind maximum governing that lane states forty-five miles per hour. No other road user is present in the scene. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 35) (m 2) k ]
      [ way, travelLane ]
      [ limitSign [12] (mph 45) .maximum ]

/-- `blind` (unknown): The subject drives at thirty-five miles per hour on a highway; the source maps the way and its lanes but declares speed limit signs absent, so whether a different limit is posted cannot be decided. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 35) (m 2) k ]
      [ way, travelLane ]
      [ limitSign [12] (mph 45) .maximum ]

/-- `branch_1` (violated): The subject drives at thirty-five miles per hour entirely on the shoulder of an unposted highway, its footprint overlapping no roadway and no lane; the shoulder lies within the highway's boundary lines. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 35) (m 8) k ]
      [ way, verge ]
      [ ]

/-- `branch_2` (violated): The subject drives at thirty-five miles per hour on the roadway of a highway where the only speed limit sign governing that roadway is of kind minimum and states fifteen miles per hour. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 35) (m 2) k ]
      [ way, carriageway ]
      [ limitSign [11] (mph 15) .minimum ]

/-- `branch_3` (violated): The subject drives at thirty-five miles per hour on the roadway of one highway while a speed limit sign of kind maximum stating forty-five miles per hour governs a lane that lies on a different highway, and no sign governs any region of the way the subject is on. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 35) (m 2) k ]
      [ way, carriageway, otherWay, otherLane ]
      [ limitSign [22] (mph 45) .maximum ]

/-- `branch_4` (compliant): The subject drives at twenty miles per hour in a lane of a highway governed by a speed limit sign of kind zone stating twenty-five miles per hour: the posted limit is not a different one, so the section applies and the subject keeps it. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 20) (m 2) k ]
      [ way, travelLane ]
      [ limitSign [12] (mph 25) .zone ]

/-- `branch_5` (not_applicable): a sign of kind maximum stating forty-five miles per hour governs
    the roadway of the way the subject is on, so a different limit is posted there. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 35) (m 2) k ]
      [ way, carriageway ]
      [ limitSign [11] (mph 45) .maximum ]

/-- `branch_6` (not_applicable): the same posting, governing the shoulder of the way the subject
    rides rather than its roadway. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 35) (m 8) k ]
      [ way, verge ]
      [ limitSign [13] (mph 45) .maximum ]

/-- `branch_7` (not_applicable): the same posting, governing the bicycle lane of the way the
    subject is on. -/
def branch_7Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 35) (m 2) k ]
      [ way, carriageway, bikeway ]
      [ limitSign [14] (mph 45) .maximum ]

/-- `branch_8` (not_applicable): the same posting, governing an intersection that lies on the way
    the subject is on. -/
def branch_8Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 35) (m 2) k ]
      [ way, carriageway, crossing ]
      [ limitSign [15] (mph 45) .maximum ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "LVMC_11_16_060"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("d", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.speed_limit_sign"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .notApplicable ]

end TrafficSpecWitness.LVMC_11_16_060
