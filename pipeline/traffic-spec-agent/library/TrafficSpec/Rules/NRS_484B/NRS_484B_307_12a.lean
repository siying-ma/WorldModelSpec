/-
  NRS_484B_307_12a — NRS-484B-307-12a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Whenever signals are placed over the individual lanes of a highway,
    s2 (boilerplate): the signals indicate, and apply to
    s3 (subject): drivers of vehicles,
    s4 (boilerplate): as follows:
    s5 (trigger): A downward-pointing green arrow means that
    s6 (condition): a driver facing the signal
    s7 (obligation): may drive in any lane over which the green signal is shown.

  Elements (span → atoms, derived):
    s1: atoms ['dev.lane_control_signal', 'dev.governs', 'st.lane', 'st.on_way', 'st.highway'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s5: atoms ['dev.lane_control_signal', 'dev.governs', 'st.lane'], derived []
    s6: atoms ['dev.position', 'kin.position', 'kin.heading'], derived []
    s7: atoms ['rel.occupies', 'st.lane', 'dev.governs', 'dev.lane_control_signal'], derived ['drv.motion.complete_halt']

  How each span is written:
    s3: the binder class `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
    s1 + s5 + s6 (applicability, first limb): some region `l` of kind `lane` lying on some region
        `h` of kind `highway` (`st_on_way l h`), and some device `d` of kind `lane_control_signal`
        with `dev_governs d l`, `dev_lane_control_signal_state d green_down_arrow`, and facing the
        subject (`facing d`).
    s6 facing: (dev_position d − kin_position subject) · kin_heading subject > 0, componentwise in
        x and y — the head lies ahead of the subject, as the record states.
    s7 selection (applicability, second limb): some lane `l2` the subject occupies
        (`rel_occupies subject l2`) with some lane-control signal `d2` governing it, not showing
        `dark` and facing the subject; and the subject is not at a complete halt
        (`drv_motion_complete_halt subject p.halt_speed_tolerance` false).
    s7 obligation: for every lane `l2` and lane-control signal `d2` re-selected with the whole
        selection above (occupied while moving, governed, lit, facing), `d2` shows
        `green_down_arrow`.
  Anchoring: the gate does not take the s6 comparison (which reads `d` and the subject) as a tie,
    so the highway `h` of s1 is tied to the subject through the claimed anchoring atom
    `rel_occupies subject h`: the lanes are those of the highway the subject is on. A driver
    facing a head over a lane of a highway and driving in a signalled lane of it is on that
    highway, so this adds no condition the record's situation does not already carry.
  No other choice beyond the record's own reading was needed; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_12a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- s6: the head of device `dv` lies ahead of the subject: the vector from the subject's position
    to the head, dotted with the subject's heading, is above zero — written as the head's
    projection on the heading exceeding the subject's own (the same inequality, the dot product
    being linear). -/
def facing (dv : String) : Formula :=
  .cmp
    (.add
      (.mul (.measure "dev_position" [.var dv, .lit "x"]) (.measure "kin_heading" [vSubject, .lit "x"]))
      (.mul (.measure "dev_position" [.var dv, .lit "y"]) (.measure "kin_heading" [vSubject, .lit "y"])))
    .gt
    (.add
      (.mul (.measure "kin_position" [vSubject, .lit "x"]) (.measure "kin_heading" [vSubject, .lit "x"]))
      (.mul (.measure "kin_position" [vSubject, .lit "y"]) (.measure "kin_heading" [vSubject, .lit "y"])))

/-- The lane-control signal `dv` shows the state spelled `st`. -/
def shows (dv st : String) : Formula :=
  .atom "dev_lane_control_signal_state" [.var dv, .lit st] []

/-- s7: the subject moves (no complete halt at the observation). -/
def moving : Formula :=
  .not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])

/-- s7 selection of one lane `l2` and one signal `d2`: the subject occupies `l2`, `d2` governs
    `l2`, is lit (not dark) and faces the subject. -/
def drivenUnder (l2 d2 : String) : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var l2] [])
    (.and (.atom "dev_governs" [.var d2, .var l2] [])
      (.and (.not (shows d2 "dark")) (facing d2)))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1, s5, s6: a lane of a highway under a lane-control signal showing a green downward arrow
    that faces the subject. -/
def greenFaced : Formula :=
  .existsRegion (.lit "lane") "l"
    (.and (.existsRegion (.lit "highway") "h"
            (.and (.atom "rel_occupies" [vSubject, .var "h"] []) (.atom "st_on_way" [.var "l", .var "h"] [])))
      (.existsDevice (.lit "lane_control_signal") "d"
        (.and (.atom "dev_governs" [.var "d", .var "l"] [])
          (.and (shows "d" "green_down_arrow") (facing "d")))))

/-- s7 selection: the subject drives in a lane under a lit lane-control signal that faces it. -/
def drivesInSignalledLane : Formula :=
  .existsRegion (.lit "lane") "l2"
    (.existsDevice (.lit "lane_control_signal") "d2" (drivenUnder "l2" "d2"))

/-- Applicability: s1 (trigger): Whenever signals are placed over the individual lanes of a highway,; s5 (trigger): A downward-pointing green arrow means that; s6 (condition): a driver facing the signal -/
def applicability : Formula :=
  .and greenFaced (.and drivesInSignalledLane moving)

/-- Obligation: s7 (obligation): may drive in any lane over which the green signal is shown. -/
def obligation : Formula :=
  .forallRegion (.lit "lane") "l2"
    (.forallDevice (.lit "lane_control_signal") "d2"
      (.implies (.and (drivenUnder "l2" "d2") moving) (shows "d2" "green_down_arrow")))

def rule : Rule :=
  { id := "NRS_484B_307_12a"
    laws := ["NRS-484B-307-12a"]
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

end TrafficSpec.Rules.NRS_484B_307_12a
