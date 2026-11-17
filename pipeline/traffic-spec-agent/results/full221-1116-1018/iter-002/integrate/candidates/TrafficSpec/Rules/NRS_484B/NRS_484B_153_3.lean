/-
  NRS_484B_153_3 — NRS-484B-153-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (subject): A person
    e2 (obligation): shall not leave open a door on the side of a vehicle which is closest to passing traffic
    e3 (standard): longer than is necessary for immediate loading or unloading of passengers or cargo.

  Elements (span → atoms, derived):
    e1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    e2: atoms ['sig.door_open', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_153_3

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pTrafficSideDoorMaxOpen : Term := .param "p.traffic_side_door_max_open"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written:
    e1: the binder `subject` is classed by ru_aggregate(subject, DEF-NRS-484A-320::vehicle); the
        person is read through the vehicle whose door it is (the record's observable reading).
    e2: "a door on the side of a vehicle which is closest to passing traffic" is open =
        sig_door_open(subject, traffic). The applicability is that the traffic-side door is open
        now (the record's applicability); the vehicle class is the binder's class.
    e3: "longer than is necessary for immediate loading or unloading" is the operationalization:
        the traffic-side door open at every observation of the time window behind of length
        p.traffic_side_door_max_open (holdsFor .time). The obligation is its negation.
  No choice beyond the record's was made; no narrowing is declared.
-/

/-- The traffic-side door of the subject is open (e2). -/
def trafficDoorOpen : Formula := .atom "sig_door_open" [vSubject, .lit "traffic"] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: the subject's traffic-side door is open. -/
def applicability : Formula := trafficDoorOpen

/-- Obligation: e2 (obligation): shall not leave open a door on the side of a vehicle which is closest to passing traffic; e3 (standard): longer than is necessary for immediate loading or unloading of passengers or cargo.
    Not: the traffic-side door open at every observation of the window behind of length
    p.traffic_side_door_max_open. -/
def obligation : Formula :=
  .not (.holdsFor .time pTrafficSideDoorMaxOpen "subject" trafficDoorOpen)

def rule : Rule :=
  { id := "NRS_484B_153_3"
    laws := ["NRS-484B-153-3"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "longer than is necessary for immediate loading or unloading of passengers or cargo"
          concepts := ["sig.door_open"]
          params := ["p.traffic_side_door_max_open"]
          convention := "A traffic-side door left open at every observation of the window behind of length p.traffic_side_door_max_open has been open longer than immediate loading or unloading needs: the curbside dwell of a passenger pick-up or a hand-carried delivery."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_153_3
