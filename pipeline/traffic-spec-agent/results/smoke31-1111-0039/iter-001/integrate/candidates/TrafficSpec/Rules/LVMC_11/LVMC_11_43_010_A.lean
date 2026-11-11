/-
  LVMC_11_43_010_A — LVMC-11-43-010-A

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    t1 (boilerplate): The following regulations pertain to the operation of
    t2 (subject): vehicles
    t3 (condition): within a roundabout
    t4 (obligation): All vehicular travel shall be in a counterclockwise direction

  Elements (span → atoms, derived):
    t2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    t3: atoms ['st.roundabout', 'rel.occupies'], derived []
    t4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.roundabout', 'st.region_geometry', 'kin.position', 'kin.velocity', 'kin.speed'], derived ['drv.motion.clockwise_about_region']

  How each span is written:
    t2: the binder class is ru_aggregate(x, "DEF-NRS-484A-320::vehicle").
    t3: some region of kind `roundabout` (st.roundabout, by the quantifier's kind) that x occupies
        (rel_occupies).
    t4: for every roundabout region r x occupies (t3's selection restated, as the record says "for
        every"), not drv_motion_clockwise_about_region(x, r) with speed_floor p.speed_resolution and
        sine_tolerance p.circulation_sine_tolerance; the concept reads st.region_geometry,
        kin.position, kin.velocity and kin.speed. The record's own narrowing on t4 (counter-clockwise
        judged as the absence of clockwise motion) is the plan's and not restated; no further choice
        was made here.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_43_010_A

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCirculationSineTolerance : Term := .param "p.circulation_sine_tolerance"
def pSpeedResolution : Term := .param "p.speed_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- t3: `x` occupies the region `r` (bound by the caller's roundabout quantifier). -/
def withinRoundabout (r : String) : Formula := .atom "rel_occupies" [vX, .var r] []

/-- Applicability: t3 (condition): within a roundabout — `x` occupies some st.roundabout region. -/
def applicability : Formula :=
  .existsRegion (.lit "roundabout") "r" (withinRoundabout "r")

/-- Obligation: t4 (obligation): All vehicular travel shall be in a counterclockwise direction —
    at every st.roundabout region `x` occupies (the applicability's whole selection, restated),
    `x` does not move clockwise about that region's reference point. -/
def obligation : Formula :=
  .forallRegion (.lit "roundabout") "r"
    (.implies (withinRoundabout "r")
      (.not (.derived "drv_motion_clockwise_about_region" [vX, .var "r"]
        [pSpeedResolution, pCirculationSineTolerance])))

def rule : Rule :=
  { id := "LVMC_11_43_010_A"
    laws := ["LVMC-11-43-010-A"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_43_010_A
