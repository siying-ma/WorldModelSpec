/-
  LVMC_11_20_060_o1 — LVMC-11-20-060

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (subject): The driver of a vehicle
    e2 (condition): within a business or residence district
    e3 (condition): emerging or entering an alley, driveway or building
    e4 (obligation): shall stop such vehicle immediately prior to
    e5 (trigger): driving onto a sidewalk or onto the sidewalk area extending across any alleyway or driveway
    e6 (sibling): yielding
    e7 (sibling): the right-of-way
    e8 (sibling): to any pedestrian
    e9 (sibling): as may be necessary to avoid collision
    e10 (boilerplate): and
    e11 (sibling): upon entering the roadway
    e12 (sibling): shall yield
    e13 (sibling): the right-of-way
    e14 (sibling): to all vehicles approaching on said roadway

  Elements (span → atoms, derived):
    e1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    e3: atoms ['st.driveway_or_alley_entrance', 'st.alley', 'rel.occupies'], derived []
    e4: atoms [], derived ['drv.motion.complete_halt']
    e5: atoms ['st.sidewalk', 'rel.occupies', 'st.region_geometry'], derived []

  How each is written:
    e1: binder class ru_aggregate(subject, "DEF-NRS-484A-320::vehicle").
    e2: .asm "asm.business_or_residence_district" in the applicability.
    e3: ∃ region of kind driveway_or_alley_entrance, or ∃ region of kind alley, that the subject
        occupies (rel_occupies) at the entry observation.
    e5: ∃ sidewalk region s with rises(rel_occupies(subject, s)); the obligation restates the
        whole selection (e5 ∧ e3) under ∀ sidewalk s.
    e4: stop zone(s) = ¬rel_occupies(subject, s) ∧ st_region_geometry_distance(subject, s) ≤
        p.stop_point_tolerance; halt = drv_motion_complete_halt(subject; p.halt_speed_tolerance).
        The record's search "(zone or the entry itself) since (zone ∧ halt)" is written as the
        value at the observation before the entry of `zone since (zone ∧ halt)`, obtained as
        rises(¬(zone since (zone ∧ halt))): at the entry the zone is false (the subject is on s),
        so the rise is exactly the previous observation's value. This makes the previous entry
        onto s end the run even when the subject stayed on s for a single observation, as the
        record says ("nothing else ends it" — and the previous entry does).
  No choice beyond the record's own narrowings was made; `narrowings` stays empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_20_060_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle (e1; "the driver of" is the
    record's observable reading through the vehicle's own motion). -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- e2: the declared assumption. -/
def district : Formula := .asm "asm.business_or_residence_district"

/-- rel.occupies(subject, r). -/
def occ (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

/-- e3: the subject occupies a driveway-or-alley-entrance region or an alley region. -/
def onDrivewayOrAlley : Formula :=
  .or (.existsRegion (.lit "driveway_or_alley_entrance") "d" (occ "d"))
      (.existsRegion (.lit "alley") "a" (occ "a"))

/-- e5 with e3: at this observation the subject begins to occupy the sidewalk `s`
    (rel.occupies here and not at the previous observation) while on a driveway or alley. -/
def entry (s : String) : Formula :=
  .and (.rises (occ s)) onDrivewayOrAlley

/-- Applicability: e2 ∧ (e5 ∧ e3) for some sidewalk region `s`. -/
def applicability : Formula :=
  .and district (.existsRegion (.lit "sidewalk") "s" (entry "s"))

/-- The stop zone before `s`: off `s`, the body within p.stop_point_tolerance of it
    (st.region_geometry ground distance). -/
def stopZone (s : String) : Formula :=
  .and (.not (occ s))
       (.cmp (.measure "st_region_geometry_distance" [vSubject, .var s]) .le pStopPointTolerance)

/-- e4: drv.motion.complete_halt(subject; p.halt_speed_tolerance). -/
def halted : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- A halt lies in the unbroken run of stop-zone observations ending here. -/
def haltInRun (s : String) : Formula := .since (stopZone s) (.and (stopZone s) halted)

/-- Obligation: for every sidewalk `s` the subject enters here from a driveway or alley (the
    applicability's whole selection, restated), a halt lies in the run of stop-zone observations
    ending at the observation before the entry. At the entry the subject is on `s`, so the zone
    and hence `haltInRun s` are false there; `rises (¬ haltInRun s)` therefore is exactly
    `haltInRun s` at the previous observation (unknown where it is unknown). The run ends at
    the last observation outside the zone upstream or on `s` (a previous entry), and nowhere
    else; reaching the recording's start without a halt is unknown. -/
def obligation : Formula :=
  .forallRegion (.lit "sidewalk") "s"
    (.implies (entry "s") (.rises (.not (haltInRun "s"))))

def rule : Rule :=
  { id := "LVMC_11_20_060_o1"
    laws := ["LVMC-11-20-060"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.business_or_residence_district"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_20_060_o1
