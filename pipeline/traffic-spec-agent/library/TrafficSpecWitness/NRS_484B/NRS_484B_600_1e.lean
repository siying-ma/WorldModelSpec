/-
  Witnesses for NRS_484B_600_1e.

  The geometry. One straight rural way running east: the highway region 10, a rectangle 2000 m
  long and 24 m wide, and on it the roadway region 11, 12 m wide, lying on that way
  (`ways := [10]`). The subject is track 1, a motor vehicle 4 m by 2 m (half-extents 2 m, 1 m,
  1 m), travelling east along the middle of the roadway at y = 2 m and advancing 40 m between the
  three observations, one second apart. The `branch_1` scene keeps the same body and motion but
  builds no highway and no roadway at all: open ground, the body's footprint overlapping no part
  of a public way.

  The speeds: 100 mph where the witness breaks the rate the text states, 60 mph where it keeps it
  — a clear margin either side of 80 mph — and 0 mph where the body stands at rest, so that no
  vehicle is in controlled motion. Every figure here is the witness's own and appears nowhere in
  the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1e
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1e

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mph (n : Int) : Q := Units.mph n

-- Binders ↦ tracks: v ↦ 1

/-- The rural way. -/
def way : Structure := Build.rect 10 .highway (m 0) (m (-12)) (m 2000) (m 12)

/-- The roadway of that way. -/
def carriageway : Structure :=
  { Build.rect 11 .roadway (m 0) (m (-6)) (m 2000) (m 6) with ways := some [10] }

/-- The subject at observation `k`, travelling east at `speed` along the roadway. -/
def subject (speed : Q) (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (100 + 40 * (k : Int)), m 2) Build.east speed (m 2, m 1, m 1)

/-- The subject standing at rest at the same place at every observation. -/
def restingSubject : RoadUser :=
  Build.user 1 [.motorVehicle] (m 100, m 2) Build.east Q.zero (m 2, m 1, m 1)

/-- `forbid` (violated): The subject travels a rural highway at a speed above the rate the text states. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 100) k ]
      [ way, carriageway ]
      [ ]

/-- `permit` (compliant): The subject travels the same highway at a speed below the rate the text states at every observation; no other road user is in the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 60) k ]
      [ way, carriageway ]
      [ ]

/-- `idle` (not_applicable): The subject stands at rest, its measured speed zero at every observation, so no vehicle is in controlled motion and the rule does not speak of it. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ restingSubject ]
      [ way, carriageway ]
      [ ]

/-- `blind` (unknown): The subject is moving, but the source does not observe speed for it, so the rate cannot be compared with the stated bound. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 100) k ]
      [ way, carriageway ]
      [ ]

/-- `branch_1` (violated): The subject travels at a speed above the rate the text states on open ground that lies within no highway region of the scene, its footprint overlapping no part of a public way; the bound applies in any event. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 100) k ]
      [ ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_600_1e"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .violated ]

end TrafficSpecWitness.NRS_484B_600_1e
