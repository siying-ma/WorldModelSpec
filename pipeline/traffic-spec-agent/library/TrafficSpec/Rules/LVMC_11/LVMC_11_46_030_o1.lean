/-
  LVMC_11_46_030_o1 — LVMC-11-46-030

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): It shall be unlawful for any person driving or operating, propelling or causing to be propelled, any vehicle,
    s2 (obligation): to fail to stop not less than fifty feet from the nearest side of
    s3 (condition): a school pedestrian lane
    s4 (condition): where any signal device, flagman or other person is stationed, giving warning that children are about to cross or are crossing the street;
    s5 (sibling): and it is further declared unlawful to proceed until such signal has stopped, raised, or been removed, or the flagman or person stationed at such pedestrian lane has given a signal to go, or has left the locality.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['st.region_geometry'], derived ['drv.motion.complete_halt']
    s3: atoms ['st.crosswalk', 'st.on_way', 'st.highway', 'prim.region_offset_along'], derived []
    s4: atoms ['dev.crossing_warning_signal', 'dev.human_direction', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []

  Literals the text states (each written through its Units constructor):
    s2: 50 ft — fifty feet

  How each span is written.
    s1: the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s4: a travel region g (`travel_region` quantifier) the subject occupies (`rel_occupies`), and a
        device d governing it (`dev_governs d g`) that gives warning: either a
        `crossing_warning_signal` whose `active` attribute holds, or a `human_direction` of any role
        whose indication is `stop`. The two device kinds are two quantifiers with their own warning
        atom (`stage`, `dutyFor`).
    s3: a highway w (`highway` quantifier) with `st_on_way g w`; a crosswalk c (`crosswalk`
        quantifier) with `st_on_way c w`, ahead of the subject along g
        (`prim_region_offset_along subject c g > 0`) and the nearest such: every crosswalk c2 on w
        with a positive offset along g has an offset at least c's.
    s2: the event is `rises (st_region_geometry_distance subject c < 50 ft)`. The act is
        `drv_motion_complete_halt subject` (tolerance `p.halt_speed_tolerance`) at an observation
        with the body distance at or above 50 ft, d warning and c ahead along a travel region the
        subject occupies that d governs (`aheadUnder`). The search is
        `since (warning ∧ aheadUnder, act)`: it ends at the warning's onset or where c is not ahead.
        The record's third end, "the previous occurrence of the same event", cannot be a conjunct of
        the since's left operand (the event itself holds at the judged observation, which `since`
        reads too), so it is written as the conjunct
        `count (distance < 50 ft) act ≤ 1`: the rises of "within fifty feet of c" since the start of
        the latest run of the act are the judged one alone, i.e. no earlier event lies between the
        latest halt and the judged one (the act holds only at distances of 50 ft or more, so no rise
        falls inside its run). Same verdicts as the record's search; no reading is added.
    The obligation repeats the applicability's whole selection (g, d, w, c, nearest, event) and
    requires the duty for every selection (`forall … implies`).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_46_030_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables. -/
def vG : Arg := .var "g"
def vD : Arg := .var "d"
def vW : Arg := .var "w"
def vC : Arg := .var "c"
def vC2 : Arg := .var "c2"
def vG2 : Arg := .var "g2"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- s2: "fifty feet". -/
def fiftyFeet : Term := .lit (Units.feet 50) .metre

/-- s2: the ground distance from the subject's body to the crosswalk c. -/
def distC : Term := .measure "st_region_geometry_distance" [vSubject, vC]

/-- s2: the subject's body is within fifty feet of c. -/
def withinFifty : Formula := .cmp distC .lt fiftyFeet

/-- s3: the signed offset of crosswalk `cv` from the subject along carrier `gv`. -/
def offsetAlong (cv gv : Arg) : Term := .quantity "prim_region_offset_along" [vSubject, cv, gv] []

/-- s4: the warning a crossing warning signal gives. -/
def warnSignal : Formula := .atom "dev_crossing_warning_signal_active" [vD] []

/-- s4: the warning a person directing traffic gives (any role). -/
def warnHuman : Formula := .atom "dev_human_direction_indication" [vD, .lit "stop"] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s3: no other crosswalk on w lies nearer ahead of the subject along g. -/
def nearest : Formula :=
  .forallRegion (.lit "crosswalk") "c2"
    (.implies
      (.and (.atom "st_on_way" [vC2, vW] [])
            (.cmp (offsetAlong vC2 vG) .gt zeroMetres))
      (.cmp (offsetAlong vC2 vG) .ge (offsetAlong vC vG)))

/-- s3/s4: c is ahead of the subject along a travel region it occupies that d governs. -/
def aheadUnder : Formula :=
  .existsRegion (.lit "travel_region") "g2"
    (.and (.atom "rel_occupies" [vSubject, vG2] [])
      (.and (.atom "dev_governs" [vD, vG2] [])
            (.cmp (offsetAlong vC vG2) .gt zeroMetres)))

/-- s2: the event — the subject's body comes within fifty feet of c. -/
def event : Formula := .rises withinFifty

/-- s2: the act — a halt at fifty feet or more from c, under d's warning, c ahead. -/
def act (warn : Formula) : Formula :=
  .and (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])
    (.and (.cmp distC .ge fiftyFeet)
      (.and warn aheadUnder))

/-- s2: the search back from the event: through d's continuous warning with c ahead, ended at the
    warning's onset, at c not ahead, or at the previous event (the count conjunct). -/
def duty (warn : Formula) : Formula :=
  .and (.since (.and warn aheadUnder) (act warn))
       (.count withinFifty (act warn) .le 1)

/-- The selection of s3/s4 for one device kind, with `body` stated of the selected g, d, w, c. -/
def stage (kind : String) (warn : Formula) (body : Formula) : Formula :=
  .existsRegion (.lit "travel_region") "g"
    (.and (.atom "rel_occupies" [vSubject, vG] [])
      (.existsDevice (.lit kind) "d"
        (.and (.atom "dev_governs" [vD, vG] [])
          (.and warn
            (.existsRegion (.lit "highway") "w"
              (.and (.atom "st_on_way" [vG, vW] [])
                (.existsRegion (.lit "crosswalk") "c"
                  (.and (.atom "st_on_way" [vC, vW] [])
                    (.and (.cmp (offsetAlong vC vG) .gt zeroMetres)
                      (.and nearest body))))))))))

/-- The same selection, the duty required for every selected g, d, w, c at which the event holds. -/
def dutyFor (kind : String) (warn : Formula) : Formula :=
  .forallRegion (.lit "travel_region") "g"
    (.implies (.atom "rel_occupies" [vSubject, vG] [])
      (.forallDevice (.lit kind) "d"
        (.implies (.and (.atom "dev_governs" [vD, vG] []) warn)
          (.forallRegion (.lit "highway") "w"
            (.implies (.atom "st_on_way" [vG, vW] [])
              (.forallRegion (.lit "crosswalk") "c"
                (.implies
                  (.and (.atom "st_on_way" [vC, vW] [])
                    (.and (.cmp (offsetAlong vC vG) .gt zeroMetres)
                      (.and nearest event)))
                  (duty warn))))))))

/-- Applicability: s3 (condition): a school pedestrian lane; s4 (condition): where any signal device, flagman or other person is stationed, giving warning that children are about to cross or are crossing the street; -/
def applicability : Formula :=
  .or (stage "crossing_warning_signal" warnSignal event)
      (stage "human_direction" warnHuman event)

/-- Obligation: s2 (obligation): to fail to stop not less than fifty feet from the nearest side of -/
def obligation : Formula :=
  .and (dutyFor "crossing_warning_signal" warnSignal)
       (dutyFor "human_direction" warnHuman)

def rule : Rule :=
  { id := "LVMC_11_46_030_o1"
    laws := ["LVMC-11-46-030"]
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

end TrafficSpec.Rules.LVMC_11_46_030_o1
