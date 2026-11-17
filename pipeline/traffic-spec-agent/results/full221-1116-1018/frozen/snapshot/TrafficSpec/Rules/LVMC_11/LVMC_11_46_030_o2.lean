/-
  LVMC_11_46_030_o2 — LVMC-11-46-030

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): It shall be unlawful for any person driving or operating, propelling or causing to be propelled, any vehicle,
    s2 (condition): to fail to stop not less than fifty feet from the nearest side of
    s3 (condition): a school pedestrian lane
    s4 (condition): where any signal device, flagman or other person is stationed, giving warning that children are about to cross or are crossing the street;
    s5 (obligation): and it is further declared unlawful to proceed
    s6 (condition): until such signal has stopped, raised, or been removed, or the flagman or person stationed at such pedestrian lane has given a signal to go, or has left the locality.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['st.region_geometry'], derived ['drv.motion.complete_halt']
    s3: atoms ['st.crosswalk', 'st.on_way', 'st.highway', 'prim.region_offset_along'], derived []
    s4: atoms ['dev.crossing_warning_signal', 'dev.human_direction', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    s5: atoms [], derived ['drv.motion.complete_halt']
    s6: atoms ['dev.crossing_warning_signal', 'dev.human_direction', 'dev.governs'], derived []

  Literals the text states (each written through its Units constructor):
    s2: 50 ft — fifty feet

  How each span is written:
    s1: the binder class `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
    s4: a travel region g (`existsRegion "travel_region"`) the subject occupies (`rel_occupies`); a
        device d, quantified separately over the two kinds (`existsDevice "crossing_warning_signal"`
        and `existsDevice "human_direction"`), whose warning is `dev_governs(d, g)` together with
        `dev_crossing_warning_signal_active(d)` for the signal and
        `dev_human_direction_indication(d, stop)` for the person (any role).
    s3: a highway w (`existsRegion "highway"`) with `st_on_way(g, w)`, and a crosswalk c
        (`existsRegion "crosswalk"`) with `st_on_way(c, w)`, ahead of the subject along g
        (`prim_region_offset_along(subject, c, g) > 0`). "Nearest" is written as: no crosswalk c2
        on w that is ahead along g has a smaller offset along g than c. The record measures "ahead"
        by the offset along g, so the nearness among crosswalks ahead is read by the same offset
        (not a choice among meanings of a carried duty span; recorded here only).
    s2: the halt the duty follows: `drv_motion_complete_halt(subject)` with p.halt_speed_tolerance,
        with `st_region_geometry_distance(subject, c) >= 50 ft` (Units.feet 50), under the warning
        and with c ahead.
    s6: `since(warning(d) ∧ ahead(c), halt ∧ distance ≥ 50 ft ∧ warning(d) ∧ ahead(c))`: the duty
        lasts from that halt for as long as the same device d keeps warning; it ends at the first
        observation at which d's active attribute is false, d's indication is not stop (proceed),
        d no longer governs g, or d is no longer in the scene (the quantifier ranges over the devices
        present at the judged observation).
    s5: obligation `drv_motion_complete_halt(subject)` with p.halt_speed_tolerance.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_46_030_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables. -/
def vG : Arg := .var "g"
def vW : Arg := .var "w"
def vC : Arg := .var "c"
def vC2 : Arg := .var "c2"
def vD : Arg := .var "d"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- s2: the text's "fifty feet". -/
def fiftyFeet : Term := .lit (Units.feet 50) .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2/s5: the subject at rest. -/
def halted : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- s3: the offset of a region along g from the subject's reference point. -/
def offsetAlong (r : Arg) : Term := .quantity "prim_region_offset_along" [vSubject, r, vG] []

/-- s3: crosswalk c ahead of the subject along g. -/
def ahead : Formula := .cmp (offsetAlong vC) .gt zeroMetres

/-- s3: c is the nearest crosswalk on w ahead along g. -/
def nearest : Formula :=
  .forallRegion (.lit "crosswalk") "c2"
    (.implies
      (.and (.atom "st_on_way" [vC2, vW] []) (.cmp (offsetAlong vC2) .gt zeroMetres))
      (.cmp (offsetAlong vC) .le (offsetAlong vC2)))

/-- s4/s6: the crossing warning signal d governs g and is active. -/
def signalWarns : Formula :=
  .and (.atom "dev_governs" [vD, vG] []) (.atom "dev_crossing_warning_signal_active" [vD] [])

/-- s4/s6: the person d directing traffic governs g and indicates stop. -/
def personWarns : Formula :=
  .and (.atom "dev_governs" [vD, vG] []) (.atom "dev_human_direction_indication" [vD, .lit "stop"] [])

/-- s2/s6: the subject halted not less than fifty feet from c under d's warning, and d's warning
    (with c ahead) has lasted since. -/
def stoppedFor (warns : Formula) : Formula :=
  .since (.and warns ahead)
    (.and halted
      (.and (.cmp (.measure "st_region_geometry_distance" [vSubject, vC]) .ge fiftyFeet)
        (.and warns ahead)))

/-- Applicability: s2 (condition): to fail to stop not less than fifty feet from the nearest side of; s3 (condition): a school pedestrian lane; s4 (condition): where any signal device, flagman or other person is stationed, giving warning that children are about to cross or are crossing the street;; s6 (condition): until such signal has stopped, raised, or been removed, or the flagman or person stationed at such pedestrian lane has given a signal to go, or has left the locality. -/
def applicability : Formula :=
  .existsRegion (.lit "travel_region") "g"
    (.and (.atom "rel_occupies" [vSubject, vG] [])
      (.existsRegion (.lit "highway") "w"
        (.and (.atom "st_on_way" [vG, vW] [])
          (.existsRegion (.lit "crosswalk") "c"
            (.and (.atom "st_on_way" [vC, vW] [])
              (.and nearest
                (.or (.existsDevice (.lit "crossing_warning_signal") "d" (stoppedFor signalWarns))
                     (.existsDevice (.lit "human_direction") "d" (stoppedFor personWarns)))))))))

/-- Obligation: s5 (obligation): and it is further declared unlawful to proceed -/
def obligation : Formula := halted

def rule : Rule :=
  { id := "LVMC_11_46_030_o2"
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

end TrafficSpec.Rules.LVMC_11_46_030_o2
