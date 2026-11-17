/-
  NRS_484B_307_12b — NRS-484B-307-12b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Whenever signals are placed over the individual lanes of a highway,
    s2 (boilerplate): the signals indicate, and apply to
    s3 (subject): drivers of vehicles,
    s4 (boilerplate): as follows:
    s5 (trigger): A red “X” symbol means
    s6 (condition): a driver facing the signal
    s7 (obligation): must not enter or drive in any lane over which the red signal is shown.

  Elements (span → atoms, derived):
    s1: atoms ['dev.lane_control_signal', 'dev.governs', 'st.lane', 'st.on_way', 'st.highway'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s5: atoms ['dev.lane_control_signal'], derived []
    s6: atoms ['dev.position', 'kin.position', 'kin.heading'], derived []
    s7: atoms ['rel.occupies', 'st.lane', 'dev.governs'], derived ['drv.motion.complete_halt']

  How each is written:
    s3: the binder class `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
    s1: a lane `l` (`existsRegion "lane"`) lying on some highway `h` (`existsRegion "highway"`,
        `st_on_way l h`), and a lane-control signal `d` (`existsDevice "lane_control_signal"`,
        `dev_lane_control_signal d`) placed over it (`dev_governs d l`).
    s5: `dev_lane_control_signal_state d "red_x"`.
    s6: the head of `d` lies ahead of the subject: (dev_position d − kin_position subject) ·
        kin_heading subject > 0, written component-wise.
    s7: for every lane `l` and lane-control signal `d` so selected (the whole selection of s1, s5,
        s6 re-bound in the obligation): not `rises (rel_occupies subject l)` (enter) and not
        `rel_occupies subject l ∧ ¬ drv_motion_complete_halt(subject; p.halt_speed_tolerance)`
        (drive in).

  No choice beyond the record's own was needed; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_12b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def vLane : Arg := .var "l"
def vWay : Arg := .var "h"
def vSignal : Arg := .var "d"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: the lane lies on a highway. -/
def laneOnHighway : Formula :=
  .existsRegion (.lit "highway") "h" (.atom "st_on_way" [vLane, vWay] [])

/-- s6: the signal head lies ahead of the subject along its heading. -/
def facing : Formula :=
  let dx : Term := .sub (.measure "dev_position" [vSignal, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"])
  let dy : Term := .sub (.measure "dev_position" [vSignal, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"])
  let dot : Term := .add (.mul dx (.measure "kin_heading" [vSubject, .lit "x"]))
                         (.mul dy (.measure "kin_heading" [vSubject, .lit "y"]))
  .cmp dot .gt zeroMetres

/-- s1, s5, s6: the signal `d` is a lane-control signal over lane `l`, shows red_x and faces the subject. -/
def redSignalOver : Formula :=
  .and (.atom "dev_lane_control_signal" [vSignal] [])
    (.and (.atom "dev_governs" [vSignal, vLane] [])
      (.and (.atom "dev_lane_control_signal_state" [vSignal, .lit "red_x"] []) facing))

/-- Applicability: s1 (trigger): Whenever signals are placed over the individual lanes of a highway,; s5 (trigger): A red “X” symbol means; s6 (condition): a driver facing the signal -/
def applicability : Formula :=
  .existsRegion (.lit "lane") "l"
    (.and laneOnHighway (.existsDevice (.lit "lane_control_signal") "d" redSignalOver))

/-- s7: the subject neither enters lane `l` nor drives in it. -/
def staysOut : Formula :=
  let occ : Formula := .atom "rel_occupies" [vSubject, vLane] []
  .and (.not (.rises occ))
    (.not (.and occ (.not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]))))

/-- Obligation: s7 (obligation): must not enter or drive in any lane over which the red signal is shown. -/
def obligation : Formula :=
  .forallRegion (.lit "lane") "l"
    (.forallDevice (.lit "lane_control_signal") "d"
      (.implies (.and laneOnHighway redSignalOver) staysOut))

def rule : Rule :=
  { id := "NRS_484B_307_12b"
    laws := ["NRS-484B-307-12b"]
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

end TrafficSpec.Rules.NRS_484B_307_12b
