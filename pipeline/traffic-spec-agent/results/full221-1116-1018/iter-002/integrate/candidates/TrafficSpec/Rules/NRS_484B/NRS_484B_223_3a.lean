/-
  NRS_484B_223_3a — NRS-484B-223-3a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): If a highway has been designed to provide a single center lane to be used only for turning by traffic moving in both directions,
    s2 (boilerplate): the following rules apply:
    s3 (subject): A vehicle
    s4 (obligation): may be driven in the center turn lane
    s5 (exception): only for the purpose of making a left-hand turn
    s6 (exception): onto or from the highway.

  Elements (span → atoms, derived):
    s1: atoms ['st.centre_turn_lane', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s4: atoms ['rel.occupies', 'st.centre_turn_lane'], derived []
    s6: atoms ['rel.occupies', 'st.highway', 'st.on_way', 'st.intersection', 'st.driveway_or_alley_entrance'], derived ['drv.motion.left_turn']

  How each span is written:
    s3: the binder class `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
    s1: a region c of kind `centre_turn_lane` (the kind is `st.centre_turn_lane`, read through the
        region quantifier) that the subject occupies (`rel_occupies`); the traffic the lane serves is
        the admitted aggregate DEF-NRS-484A-285::traffic, carried on the only road user the rule
        binds, the subject (`ru_aggregate subject DEF-NRS-484A-285::traffic`), in the applicability.
    s4: in the obligation, at every centre turn lane c the subject occupies (the same selection as
        the applicability's), the presence is excused by s5/s6 and otherwise violated.
    s5/s6 "from": the declared intention `int.left_turn` of the subject at some region of kind
        `intersection` or `driveway_or_alley_entrance`, read at the judged observation. "From the
        highway" is the highway on which c lies: the target region lies on (`st_on_way`) a highway g
        on which c lies — the place where the left turn leaves that highway. This is the span's own
        "the highway" written with s6's claimed `st.on_way`, and it ties the target region to the
        subject (through c), which the intention alone does not.
    s5/s6 "onto": `since (occupies c) (left_turn ∧ occupies c ∧ ∃ highway h, on_way(c, h) ∧
        ¬ holdsFor[p.vehicle_turn_window] (occupies h))`: the subject has occupied c at every
        observation since one at which drv.motion.left_turn held while it occupied c, and at some
        observation of the turn window behind that one it occupied no part of a highway h on which
        c lies (`st_on_way c h`). The window is p.vehicle_turn_window, the concept's own window.

  Choices: "the highway h on which c lies" is written as some highway region c lies on (the record
  names one); no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_223_3a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pTurnYawRateTol : Term := .param "p.turn_yaw_rate_tol"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"
def pVehicleTurnWindow : Term := .param "p.vehicle_turn_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- The subject's footprint overlaps region `r`. -/
def occupies (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: the subject is of the traffic the centre turn lane serves. -/
def isTraffic : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] []

/-- Applicability: s1 — the subject (traffic) occupies a centre turn lane c. -/
def applicability : Formula :=
  .and isTraffic (.existsRegion (.lit "centre_turn_lane") "c" (occupies "c"))

/-- drv.motion.left_turn of the subject, with the node's parameters. -/
def leftTurn : Formula :=
  .derived "drv_motion_left_turn" [vSubject]
    [pVehicleTurnWindow, pTurnHeadingMin, pUTurnHeadingMin, pTurnYawRateTol]

/-- s5/s6 "from the highway": int.left_turn declared at an intersection or a driveway/alley
    entrance of the highway g on which c lies (the turn leaves that highway there). -/
def fromHighway : Formula :=
  .existsRegion (.lit "highway") "g"
    (.and (.atom "st_on_way" [.var "c", .var "g"] [])
      (.or (.existsRegion (.lit "intersection") "i"
              (.and (.atom "st_on_way" [.var "i", .var "g"] []) (.intent "int.left_turn" vSubject (.var "i"))))
           (.existsRegion (.lit "driveway_or_alley_entrance") "e"
              (.and (.atom "st_on_way" [.var "e", .var "g"] []) (.intent "int.left_turn" vSubject (.var "e"))))))

/-- At some observation of the turn window behind, the subject occupied no part of a highway h
    on which c lies. -/
def offHighwayBehind : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "st_on_way" [.var "c", .var "h"] [])
          (.not (.holdsFor .time pVehicleTurnWindow "subject" (occupies "h"))))

/-- s5/s6 "onto the highway": in c at every observation since a left turn recognized in c, made
    from off the highway c lies on. -/
def ontoHighway : Formula :=
  .since (occupies "c") (.and (.and leftTurn (occupies "c")) offHighwayBehind)

/-- Obligation: s4 with s5/s6 — at every centre turn lane c the subject occupies, its presence is
    for a left-hand turn from or onto the highway. -/
def obligation : Formula :=
  .forallRegion (.lit "centre_turn_lane") "c"
    (.implies (occupies "c") (.or fromHighway ontoHighway))

def rule : Rule :=
  { id := "NRS_484B_223_3a"
    laws := ["NRS-484B-223-3a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_223_3a
