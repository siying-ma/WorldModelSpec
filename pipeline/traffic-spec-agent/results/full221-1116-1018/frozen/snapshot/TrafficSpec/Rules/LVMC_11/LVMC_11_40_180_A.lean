/-
  LVMC_11_40_180_A — LVMC-11-40-180-A

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a1 (obligation): It shall be unlawful for any person to ride
    a2 (subject): a bicycle, electric bicycle, or electric scooter
    a3 (condition): upon the sidewalks
    a4 (condition): on Fremont Street between Main Street and Seventh Street
    a5 (condition): This area shall be posted with signs indicating that the riding of bicycles, electric bicycles, or electric scooters on the sidewalk is prohibited

  Elements (span → atoms, derived):
    a1: atoms [], derived ['drv.motion.complete_halt']
    a2: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle', 'ru.aggregate=DEF-LVMC-11-02-083::electric_scooter'], derived []
    a3: atoms ['rel.occupies', 'st.sidewalk'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_40_180_A

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written:
    a2: the subject's class is the disjunction of the three admitted aggregates, each the atom
        `ru_aggregate` with the aggregate id as its literal argument (never the classes it covers);
        membership under the electric-scooter aggregate, which includes no class under the run's
        reading, is at best unknown, and the disjunction then rests on the other two.
    a3: some region of kind `sidewalk` (the st.sidewalk kind, as the record names it, refinements
        included) that the subject occupies (`rel_occupies subject sw`).
    a4: the declared assumption `asm.fremont_street_main_to_seventh`, conjoined.
    a5: a residue (sign posting); not written.
    a1: the duty is that the subject be at rest: `drv_motion_complete_halt(subject; p.halt_speed_tolerance)`,
        judged at each observation at which the applicability holds. The reading of riding through
        motion is the record's own observable reading and is not restated here.
  No choice was left open beyond these: no narrowing of my own is declared.
-/

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter -/
def clsSubject : Formula :=
  .or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-082::electric_bicycle"] [])
      (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-083::electric_scooter"] []))

/-- a3: the subject occupies a sidewalk. -/
def onSidewalk : Formula :=
  .existsRegion (.lit "sidewalk") "sw" (.atom "rel_occupies" [vSubject, .var "sw"] [])

/-- Applicability: a3 (condition): upon the sidewalks; a4 (condition): on Fremont Street between Main Street and Seventh Street; a5 (condition): This area shall be posted with signs indicating that the riding of bicycles, electric bicycles, or electric scooters on the sidewalk is prohibited -/
def applicability : Formula :=
  .and onSidewalk (.asm "asm.fremont_street_main_to_seventh")

/-- Obligation: a1 (obligation): It shall be unlawful for any person to ride -/
def obligation : Formula :=
  .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

def rule : Rule :=
  { id := "LVMC_11_40_180_A"
    laws := ["LVMC-11-40-180-A"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.fremont_street_main_to_seventh"]
    intentions := []
    operationalizations := []
    residues := ["The sentence directs the City to post signs; the riding prohibition of the first sentence holds whether or not the signs are posted, so the duty is the same either way."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_40_180_A
