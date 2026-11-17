/-
  LVMC_11_48_060 — LVMC-11-48-060

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): Streets
    s2 (condition): other than truck routes
    s3 (obligation): shall not be used as through routes
    s4 (trigger): from one truck route to another
    s5 (exception): unless pick-up, delivery or essential use is required enroute

  Elements (span → atoms, derived):
    s1: atoms ['rel.occupies', 'st.highway'], derived []
    s2: atoms ['dev.regulatory_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    s3: atoms ['rel.occupies', 'st.highway'], derived []
    s4: atoms ['ru.aggregate=DEF-NRS-484A-305::truck', 'dev.regulatory_sign', 'dev.governs', 'rel.occupies', 'st.travel_region', 'st.on_way', 'st.highway'], derived []
    s5: atoms [], derived ['drv.motion.parked']

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_48_060

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pDeliveryHaltMinDuration : Term := .param "p.delivery_halt_min_duration"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
  s4 (truck): the subject's class is the admitted aggregate DEF-NRS-484A-305::truck (ru_aggregate).
  s2/s4 (truck route): onTR(g) = rel_occupies(subject, g) for a travel region g (quantifier kind
    travel_region) governed (dev_governs) by a regulatory sign (quantifier kind regulatory_sign) whose
    code is truck_route (dev_regulatory_sign_code). onTRany = some such g.
  s4 (trigger): rises(onTRany) at the judged observation t — on a truck route now, on none at the
    observation before.
  s1/s3 (the stretch on streets other than truck routes): a cell of the stretch is an observation at
    which the subject occupies some st.highway region and no truck-route travel region. φ = cell or
    rises(onTRany) (the latter admits t itself, as the record writes it).
  s4 ("from one … to another"): ψ(g2) = some travel region g1 with onTR(g1) such that every highway w
    that g1 lies on (st_on_way) is not one g2 lies on: no highway in common.
  s3 (obligation): for every travel region g2 with onTR(g2) at t, not since(φ, ψ(g2)).
  s5 (exception): the same stretch re-bound with its full selection (some g2 with onTR(g2) at t, the
    stretch back to a g1 on no way of g2's), and at some observation u of it (a cell, after the
    truck-route observation that starts it) drv_motion_parked(subject; p.halt_speed_tolerance,
    p.delivery_halt_min_duration): since(φ, parked ∧ cell ∧ since(φ, ψ(g2))).
  Every bound variable carries its own name (a tag per use), so no quantifier shadows another.
  No choice beyond the record's own narrowings was needed: `narrowings` is empty.
-/

/-- A regulatory sign with code truck_route governs travel region `g` (device variable `d`). -/
def truckRouteGoverns (d g : String) : Formula :=
  .existsDevice (.lit "regulatory_sign") d
    (.and (.atom "dev_regulatory_sign_code" [.var d, .lit "truck_route"] [])
          (.atom "dev_governs" [.var d, .var g] []))

/-- onTR(g): the subject occupies travel region `g`, which a truck_route sign governs. -/
def onTR (g : String) : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var g] []) (truckRouteGoverns ("d_" ++ g) g)

/-- onTR-any: the subject occupies some truck-route travel region. -/
def onTRany (tag : String) : Formula :=
  .existsRegion (.lit "travel_region") ("g_" ++ tag) (onTR ("g_" ++ tag))

/-- The subject occupies some highway region (a street). -/
def onHighway (tag : String) : Formula :=
  .existsRegion (.lit "highway") ("h_" ++ tag) (.atom "rel_occupies" [vSubject, .var ("h_" ++ tag)] [])

/-- A cell of the stretch: on a street, on no truck route. -/
def cell (tag : String) : Formula :=
  .and (.not (onTRany ("c" ++ tag))) (onHighway ("c" ++ tag))

/-- The since-body: a cell of the stretch, or the rise onto a truck route at t. -/
def stretchStep (tag : String) : Formula :=
  .or (cell ("s" ++ tag)) (.rises (onTRany ("r" ++ tag)))

/-- The stretch's start: a truck-route travel region g1 with no highway in common with `g2`. -/
def fromOtherRoute (g2 tag : String) : Formula :=
  let g1 := "g1_" ++ tag
  let w := "w_" ++ tag
  .existsRegion (.lit "travel_region") g1
    (.and (onTR g1)
      (.forallRegion (.lit "highway") w
        (.implies (.atom "st_on_way" [.var g1, .var w] [])
                  (.not (.atom "st_on_way" [.var g2, .var w] [])))))

/-- The stretch to `g2` from another truck route: since(φ, ψ(g2)). -/
def throughStretch (g2 tag : String) : Formula :=
  .since (stretchStep tag) (fromOtherRoute g2 tag)

/-- s5: parked (delivery dwell) at some cell of the stretch. -/
def parkedEnroute : Formula :=
  .derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pDeliveryHaltMinDuration]

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-305::truck -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-305::truck"] []

/-- Exception (s5), re-bound with the stretch's full selection. -/
def exception : Formula :=
  .existsRegion (.lit "travel_region") "g2_x"
    (.and (onTR "g2_x")
      (.since (stretchStep "xo")
        (.and parkedEnroute (.and (cell "xp") (throughStretch "g2_x" "xi")))))

/-- Applicability: s1 (condition): Streets; s2 (condition): other than truck routes; s4 (trigger): from one truck route to another; s5 (exception): unless pick-up, delivery or essential use is required enroute -/
def applicability : Formula :=
  .and (.rises (onTRany "trig")) (.not exception)

/-- Obligation: s3 (obligation): shall not be used as through routes -/
def obligation : Formula :=
  .forallRegion (.lit "travel_region") "g2_o"
    (.implies (onTR "g2_o") (.not (throughStretch "g2_o" "o")))

def rule : Rule :=
  { id := "LVMC_11_48_060"
    laws := ["LVMC-11-48-060"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_48_060
