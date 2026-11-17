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

  How each is written.
    e1  The class is the disjunction of the three admitted aggregates (`ru_aggregate` with each id).
    e5  "On the sidewalk s" (`onS`): the subject occupies s (`rel_occupies`) and the ground distance
        from its outline to s's outline is zero (`st_region_geometry_distance`): the occupancy the
        source reports, read with the sidewalk outline the record claims for it. The applicability
        holds for some sidewalk region s (`existsRegion sidewalk`) on which the subject is now and has
        been at every observation since its latest entry: every fact read "at the entry" is a
        `since onS ψ`, which reaches back exactly to the latest rise of `onS` (ψ = `rises onS ∧ …`)
        or to the observation just before it (ψ = `¬onS ∧ …`, since `onS` holds at every later one).
    e2  `asm.business_or_residence_district` at the entry: `since onS (rises onS ∧ asm)`.
    e3  At the entry, one of (as the record lists them):
          - it occupied an alley or a driveway/alley entrance region at the entry or at the observation
            before it: `since onS ((¬onS ∨ rises onS) ∧ (∃ alley a. occ a ∨ ∃ driveway d. occ d))`;
          - at the observation before it occupied no highway region (emerging from a building):
            `since onS (¬onS ∧ ¬∃ highway h. occ h)`;
          - from the entry it stays on s until it occupies no highway region (entering a building):
            `since onS (rises onS ∧ (onS U ¬∃ highway h. occ h))` (strong until, read ahead of the entry).
        The three alternatives share one `since`, so they speak of the same entry.
    e6/e7 For every road user p that is a pedestrian (`ru_aggregate` DEF-NRS-484A-165::pedestrian)
        other than the subject (`same`): no contact (`rel_contact`), and not [the subject's speed above
        p.halt_speed_tolerance while the centres approach within p.conflict_horizon
        (`prim_closest_approach_within`) to a centre distance below p.conflict_centre_clearance
        (`prim_closest_approach_distance`)]. A scene with no pedestrian is compliant (the quantifier
        is vacuous over the subject itself). This is the record's own reading (its e6 narrowing);
        no narrowing of this session's is added.

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

/-- Membership of the road user `x` in an admitted aggregate. -/
def agg (x : Arg) (id : String) : Formula := .atom "ru_aggregate" [x, .lit id] []

/-- The subject occupies region `r`. -/
def occ (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

/-- e5: the subject is on the sidewalk region `s`: it occupies it, and its outline meets s's outline. -/
def onS : Formula :=
  .and (occ "s") (.cmp (.measure "st_region_geometry_distance" [vSubject, .var "s"]) .eq zeroMetres)

/-- The subject occupies some highway region. -/
def inHighway : Formula := .existsRegion (.lit "highway") "h" (occ "h")

/-- The subject occupies an alley or a driveway/alley entrance region. -/
def onAlleyOrDriveway : Formula :=
  .or (.existsRegion (.lit "alley") "a" (occ "a"))
      (.existsRegion (.lit "driveway_or_alley_entrance") "d" (occ "d"))

/-- e2 at the latest entry onto s. -/
def entryInDistrict : Formula :=
  .since onS (.and (.rises onS) (.asm "asm.business_or_residence_district"))

/-- e3 at the latest entry onto s: from or into an alley or driveway (at the entry or the observation
    before it), from a building (no highway region the observation before), into a building (on s from
    the entry until it occupies no highway region). -/
def entryFromOrInto : Formula :=
  .since onS
    (.or (.and (.or (.not onS) (.rises onS)) onAlleyOrDriveway)
      (.or (.and (.not onS) (.not inHighway))
           (.and (.rises onS) (.until onS (.not inHighway)))))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter -/
def clsSubject : Formula :=
  .or (agg vSubject "DEF-NRS-484A-025::bicycle")
    (.or (agg vSubject "DEF-LVMC-11-02-082::electric_bicycle")
         (agg vSubject "DEF-LVMC-11-02-083::electric_scooter"))

/-- Applicability: e2 (condition): within a business or residence district; e3 (trigger): entering into or emerging from an alley, driveway or building; e5 (condition): driving onto a sidewalk or onto the sidewalk area extending across any alleyway, driveway or building -/
def applicability : Formula :=
  .existsRegion (.lit "sidewalk") "s" (.and onS (.and entryInDistrict entryFromOrInto))

/-- e7: the subject moves while the pedestrian `p`'s centre comes, under constant velocities, within
    the conflict clearance of its own within the conflict horizon. -/
def conflictWith (p : Arg) : Formula :=
  .and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
    (.and (.derived "prim_closest_approach_within" [vSubject, p] [pConflictHorizon])
          (.cmp (.quantity "prim_closest_approach_distance" [vSubject, p] [pConflictHorizon]) .lt
                pConflictCentreClearance))

/-- Obligation: e6 (obligation): yielding the right-of-way to any pedestrian; e7 (standard): as may be necessary to avoid collision -/
def obligation : Formula :=
  .forallUser "p"
    (.implies (.and (agg (.var "p") "DEF-NRS-484A-165::pedestrian") (.not (.same (.var "p") vSubject)))
      (.and (.not (.atom "rel_contact" [vSubject, .var "p"] []))
            (.not (conflictWith (.var "p")))))

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
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_40_140_o2
