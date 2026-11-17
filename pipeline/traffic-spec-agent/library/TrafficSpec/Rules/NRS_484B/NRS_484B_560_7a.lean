/-
  NRS_484B_560_7a — NRS-484B-560-7a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a1 (subject): It is unlawful for the driver of any vehicle:
    a2 (trigger): When crossing at grade any track or tracks of a railroad,
    a3 (obligation): to fail to completely cross the track or tracks without stopping
    a4 (condition): due to insufficient: (1) Space for the vehicle on the opposite side of the railroad crossing; or (2) Undercarriage clearance of the vehicle.
    a5 (definitional): As used in this section, “completely cross” means to travel across a railroad track or tracks in such a manner that the trailing end of the vehicle is 15 feet or more past the nearest rail of the railroad track or tracks.

  Elements (span → atoms, derived):
    a1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    a2: atoms ['rel.occupies', 'st.railway_crossing'], derived []
    a3: atoms [], derived ['drv.motion.complete_halt']
    a4: atoms [], derived ['drv.motion.complete_halt']
    a5: atoms ['st.region_geometry', 'st.railway_crossing'], derived []

  How each span is written:
    a1: the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    a2 + a5 (applicability): some region c of kind `railway_crossing` such that, at this
        observation, the ground distance from the subject's body to c
        (`st_region_geometry_distance`) is below 15 ft, and that distance has been below 15 ft at
        every observation since one (this one included) at which the subject occupied c
        (`rel_occupies`): `since (dist < 15 ft) (occupies c)`. The crossing is "under way" from
        the first overlap until the trailing end is 15 ft past the crossing outline.
    a3 + a4 (obligation): the subject is not halted, `¬ drv_motion_complete_halt(subject)` with
        `p.halt_speed_tolerance`. The obligation names no region, so the applicability's
        selection of c is not repeated there. a4's causes are read through that halt (the
        record's observable reading).

  Literals the text states (each written through its Units constructor):
    a5: 15 ft — 15 feet

  No choice beyond the record's own narrowings was made; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_560_7a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- a5: "15 feet" past the nearest rail. -/
def completelyCrossDistance : Term := .lit (Units.feet 15) .metre

/-- The crossing region variable. -/
def vCrossing : Arg := .var "c"

/-- a5: the subject's body is within the literal 15 ft of the crossing outline. -/
def notYetPast : Formula :=
  .cmp (.measure "st_region_geometry_distance" [vSubject, vCrossing]) .lt completelyCrossDistance

/-- a2: the subject's footprint overlaps the crossing. -/
def onCrossing : Formula :=
  .atom "rel_occupies" [vSubject, vCrossing] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: a2 (trigger) with a5: crossing at grade a railway crossing and not yet
    completely across it. -/
def applicability : Formula :=
  .existsRegion (.lit "railway_crossing") "c"
    (.and notYetPast (.since notYetPast onCrossing))

/-- Obligation: a3/a4: not halted before having completely crossed. -/
def obligation : Formula :=
  .not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])

def rule : Rule :=
  { id := "NRS_484B_560_7a"
    laws := ["NRS-484B-560-7a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_560_7a
