/-
  LVMC_11_40_140_o2 — LVMC-11-40-140

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (subject): The operator of a bicycle, electric bicycle, or electric scooter
    e2 (condition): within a business or residence district
    e3 (trigger): entering into or emerging from an alley, driveway or building
    e4 (sibling): shall stop such vehicle immediately prior to
    e5 (condition): driving onto a sidewalk or onto the sidewalk area extending across any alleyway, driveway or building
    e6 (obligation): yielding the right-of-way to any pedestrian
    e7 (standard): as may be necessary to avoid collision

  Elements (span → atoms, derived):
    e1: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle', 'ru.aggregate=DEF-LVMC-11-02-083::electric_scooter'], derived []
    e3: atoms ['rel.occupies', 'st.alley', 'st.driveway_or_alley_entrance', 'st.highway'], derived []
    e5: atoms ['rel.occupies', 'st.region_geometry', 'st.sidewalk'], derived []
    e6: atoms ['kin.speed', 'rel.contact', 'ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []

  How each span is written:
    e1 — the subject's class is the disjunction of the three admitted aggregates (`ru_aggregate`
         with the aggregate id as its literal).
    e5 — "on the sidewalk s" (`onSidewalk`): the subject occupies the sidewalk region s
         (`rel_occupies`) and its body outline is at zero ground distance from s's outline
         (`st_region_geometry_distance`, the distance accessor of st.region_geometry): the
         occupancy read with the sidewalk's outline, as the element maps it. The applicability
         holds at an observation where, for some sidewalk s, the subject has been on s at every
         observation since its latest entry onto s (`since`, whose operand at the entry is the
         rise of `onSidewalk`), so it holds now too.
    e2 — `asm.business_or_residence_district`, read at that entry.
    e3 — read at that entry, the three limbs the applicability states:
         (i) at the entry or at the observation before it the subject occupied an alley or a
             driveway/alley-entrance region: `A ∨ rises(¬A)` with A the occupancy of such a
             region (`rises(¬A)` is "A at the observation before, and not now");
         (ii) at the observation before it occupied no highway region: written `rises(H)`, H the
             occupancy of some highway region. The remaining case of (ii) — no highway region
             now either — is entailed by limb (iii), which then holds at the entry itself, so
             the disjunction is unchanged;
         (iii) from the entry it stays on s until it occupies no highway region (`until`).
    e6/e7 — for every road user p that is a pedestrian (the admitted aggregate): no contact
         with p (`rel_contact`), and not [the subject's speed above p.halt_speed_tolerance while
         the centres approach within p.conflict_horizon (`prim_closest_approach_within`) to a
         centre distance below p.conflict_centre_clearance (`prim_closest_approach_distance`)].
         "Other than the subject" needs no clause: the subject is a bicycle, electric bicycle or
         electric scooter, which the pedestrian aggregate does not include, so the implication
         holds for p = subject. A scene with no pedestrian makes the quantifier true.

  No narrowing is declared: every limb above is the record's applicability and obligation as
  stated; the rewriting of limb (ii) is an equivalence, not a narrower reading.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_40_140_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Membership of the subject in an admitted aggregate. -/
def inAggregate (v : String) (id : String) : Formula := .atom "ru_aggregate" [.var v, .lit id] []

/-- The subject occupies region `r`. -/
def occupies (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter -/
def clsSubject : Formula :=
  .or (inAggregate "subject" "DEF-NRS-484A-025::bicycle")
    (.or (inAggregate "subject" "DEF-LVMC-11-02-082::electric_bicycle")
      (inAggregate "subject" "DEF-LVMC-11-02-083::electric_scooter"))

/-- e5: the subject on the sidewalk region `s` — it occupies `s`, its outline at zero distance from `s`'s. -/
def onSidewalk : Formula :=
  .and (occupies "s")
    (.cmp (.measure "st_region_geometry_distance" [vSubject, .var "s"]) .le zeroMetres)

/-- e3: the subject occupies an alley or a driveway / alley-entrance region. -/
def inAlleyOrDriveway : Formula :=
  .or (.existsRegion (.lit "alley") "a" (occupies "a"))
    (.existsRegion (.lit "driveway_or_alley_entrance") "d" (occupies "d"))

/-- e3: the subject occupies a highway region. -/
def onHighway : Formula := .existsRegion (.lit "highway") "h" (occupies "h")

/-- e3, read at the entry onto `s`: (i) in an alley or driveway region at the entry or the
    observation before it; (ii) on no highway region at the observation before it; (iii) on `s`
    from the entry until on no highway region. -/
def enteringOrEmerging : Formula :=
  .or (.or inAlleyOrDriveway (.rises (.not inAlleyOrDriveway)))
    (.or (.rises onHighway) (.until onSidewalk (.not onHighway)))

/-- The entry onto `s` the duty arises at: the rise of `onSidewalk`, in the district (e2), from
    or into an alley, driveway or building (e3). -/
def entry : Formula :=
  .and (.rises onSidewalk)
    (.and (.asm "asm.business_or_residence_district") enteringOrEmerging)

/-- Applicability: e2 (condition): within a business or residence district; e3 (trigger): entering into or emerging from an alley, driveway or building; e5 (condition): driving onto a sidewalk or onto the sidewalk area extending across any alleyway, driveway or building -/
def applicability : Formula :=
  .existsRegion (.lit "sidewalk") "s" (.since onSidewalk entry)

def vPed : Arg := .var "p"

/-- e7: a danger of collision with `p` while the subject moves. -/
def conflict : Formula :=
  .and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
    (.and (.derived "prim_closest_approach_within" [vSubject, vPed] [pConflictHorizon])
      (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vPed] [pConflictHorizon]) .lt
        pConflictCentreClearance))

/-- Obligation: e6 (obligation): yielding the right-of-way to any pedestrian; e7 (standard): as may be necessary to avoid collision -/
def obligation : Formula :=
  .forallUser "p"
    (.implies (inAggregate "p" "DEF-NRS-484A-165::pedestrian")
      (.and (.not (.atom "rel_contact" [vSubject, vPed] [])) (.not conflict)))

def rule : Rule :=
  { id := "LVMC_11_40_140_o2"
    laws := ["LVMC-11-40-140"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.business_or_residence_district"]
    intentions := []
    operationalizations :=
      [ { standard := "as may be necessary to avoid collision"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "traffic-conflict technique: while the subject moves, a pedestrian whose centre comes, under constant velocities, within the conflict clearance of the subject's centre within the conflict horizon is a danger of collision the subject must yield to"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_40_140_o2
