/-
  LVMC_11_40_140_o1 — LVMC-11-40-140

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (subject): The operator of a bicycle, electric bicycle, or electric scooter
    e2 (condition): within a business or residence district
    e3 (trigger): entering into or emerging from an alley, driveway or building
    e4 (obligation): shall stop such vehicle immediately prior to
    e5 (trigger): driving onto a sidewalk or onto the sidewalk area extending across any alleyway, driveway or building
    e6 (sibling): yielding the right-of-way to any pedestrian
    e7 (sibling): as may be necessary to avoid collision

  Elements (span → atoms, derived):
    e1: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle', 'ru.aggregate=DEF-LVMC-11-02-083::electric_scooter'], derived []
    e3: atoms ['rel.occupies', 'st.alley', 'st.driveway_or_alley_entrance', 'st.highway'], derived []
    e4: atoms [], derived ['drv.motion.complete_halt']
    e5: atoms ['rel.occupies', 'st.region_geometry', 'st.sidewalk'], derived []

  How each span is written.
    e1: the class is the disjunction of the three admitted aggregates, each `ru_aggregate subject
        "<id>"` with the aggregate id as its literal.
    e2: `asm.business_or_residence_district`, read at the entry.
    e5: for a sidewalk region s, the entry is `rises (rel_occupies subject s)`: the footprint
        overlaps s here and did not at the observation before.
    e3: three disjuncts, as the applicability states them.
        (i) at the entry or the observation before, the subject occupies an alley or a driveway /
            alley entrance region: `AD ∨ rises ¬AD` (AD at the entry, or AD not at the entry and AD
            at the observation before — together, AD here or at the previous observation);
        (ii) at the observation before it occupies no highway region: `rises H`, H = the subject
            occupies some highway region. At an entry at which H holds this is exactly "no highway
            region at the observation before"; at an entry at which H does not hold (a map that
            puts the sidewalk under no highway region) disjunct (iii) holds at once (its ψ, ¬H,
            holds at the entry), so the disjunction is the record's whatever H is at the entry;
        (iii) from the entry on it occupies s until it occupies no highway region:
            `until (rel_occupies subject s) (¬H)` (strong until).
    e4: act before an event (rule 4c). Zone(s) = the subject does not occupy s and the ground
        distance from its body to s (`st_region_geometry_distance`) is at most
        p.stop_point_tolerance. The search is `since Zone (Zone ∧ complete_halt)`: a halt in the
        zone at some observation, the subject in the zone at every observation after it. Read at
        the observation before the entry, it ends where the zone first fails going back — the
        approach start (farther than the tolerance) or the previous occupancy of s (the previous
        entry) — false there without a halt; it reaches the recording start as unknown
        (`windowTruncated since`), and an unobserved distance or occupancy leaves it unknown.
        "At the observation before" is written `rises (¬ search)`: at the entry the subject
        occupies s, so Zone and the search are decided false there, and ¬search rising is the
        search holding at the observation before.
    3c: the obligation re-selects s with the applicability's whole selection (entry, district,
        e3) under a universal over sidewalk regions: every entry selected carries its own duty.
  No choice beyond the record's reading was needed: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_40_140_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter -/
def clsSubject : Formula :=
  .or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-082::electric_bicycle"] [])
         (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-083::electric_scooter"] []))

/-- The subject's footprint overlaps region `r`. -/
def occ (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

/-- e3: the subject occupies an alley or a driveway / alley entrance region. -/
def inAlleyOrDriveway : Formula :=
  .or (.existsRegion (.lit "alley") "a" (occ "a"))
      (.existsRegion (.lit "driveway_or_alley_entrance") "d" (occ "d"))

/-- e3: the subject occupies some highway region. -/
def onHighway : Formula := .existsRegion (.lit "highway") "h" (occ "h")

/-- e5: the entry onto sidewalk `s`. -/
def entry (s : String) : Formula := .rises (occ s)

/-- e3: entering into or emerging from an alley, driveway or building, read at the entry onto `s`. -/
def entersOrEmerges (s : String) : Formula :=
  .or (.or inAlleyOrDriveway (.rises (.not inAlleyOrDriveway)))
    (.or (.rises onHighway)
         (.until (occ s) (.not onHighway)))

/-- The selection of sidewalk `s` (e2, e3, e5), shared by applicability and obligation. -/
def selects (s : String) : Formula :=
  .and (entry s)
    (.and (.asm "asm.business_or_residence_district") (entersOrEmerges s))

/-- e4/e5: the stopping zone of `s`: outside s, body within p.stop_point_tolerance of it. -/
def inZone (s : String) : Formula :=
  .and (.not (occ s))
    (.cmp (.measure "st_region_geometry_distance" [vSubject, .var s]) .le pStopPointTolerance)

/-- e4: a halt in the zone, the subject in the zone at every observation since. -/
def haltedInZone (s : String) : Formula :=
  .since (inZone s)
    (.and (inZone s) (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]))

/-- Applicability: e2 (condition): within a business or residence district; e3 (trigger): entering into or emerging from an alley, driveway or building; e5 (trigger): driving onto a sidewalk or onto the sidewalk area extending across any alleyway, driveway or building -/
def applicability : Formula :=
  .existsRegion (.lit "sidewalk") "s" (selects "s")

/-- Obligation: e4 (obligation): shall stop such vehicle immediately prior to -/
def obligation : Formula :=
  .forallRegion (.lit "sidewalk") "s"
    (.implies (selects "s") (.rises (.not (haltedInZone "s"))))

def rule : Rule :=
  { id := "LVMC_11_40_140_o1"
    laws := ["LVMC-11-40-140"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.business_or_residence_district"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_40_140_o1
