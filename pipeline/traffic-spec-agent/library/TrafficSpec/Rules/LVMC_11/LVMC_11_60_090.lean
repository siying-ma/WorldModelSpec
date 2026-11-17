/-
  LVMC_11_60_090 — LVMC-11-60-090

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Any cab,
    s2 (trigger): upon leaving any stand designated in accordance with the provisions of this Section,
    s3 (obligation): shall execute a right-hand turn,
    s4 (condition): when a sign is posted giving notice of this requirement,
    s5 (condition): at the first street intersection after it leaves such stand.

  Elements (span → atoms, derived):
    s1: atoms ['ru.taxicab'], derived []
    s2: atoms ['rel.occupies', 'st.curb_zone'], derived []
    s3: atoms ['kin.yaw_rate', 'rel.occupies'], derived ['drv.motion.right_turn_through_region']
    s4: atoms ['dev.regulatory_sign', 'dev.governs', 'st.travel_region', 'rel.occupies', 'prim.conditions_hold'], derived []
    s5: atoms ['rel.occupies', 'st.intersection', 'st.curb_zone'], derived []

  How each span is written:
    s1: the binder class `ru_taxicab subject`.
    s2: `standDeparture` — some curb zone `k` of kind taxicab_stand whose overlap by the subject
        falls at this observation: `rises (not rel_occupies(subject, k))` (true now, false before).
    s4: `signAtDeparture` — some regulatory sign `d` of code right_turn_only whose conditions hold
        for the subject (prim_conditions_hold) and which governs (dev_governs) a travel region `v`
        the subject occupies at that same observation. s2 and s4 are one conjunction, so both are
        read at the departure observation, as the record states.
    s5: `selection r` — the subject's footprint ceases to overlap intersection `r` now
        (`rises (not rel_occupies(subject, r))`: the occasion's recognition, the exit from r), and
        `[every intersection q other than r is unoccupied] since [s2 ∧ s4]`: from the departure up
        to now the subject overlapped no intersection but r, so r is the first after the stand.
    s3: at the recognition, `drv_motion_right_turn_through_region(subject, r)` with
        step = p.heading_since_step_carla_scene_graph, turn_min = p.turn_heading_min,
        u_turn_min = p.u_turn_heading_min.
  The obligation repeats the applicability's whole selection of `r` (rule 3c) and requires the
  turn at every intersection so selected (`forallRegion … implies`); only one intersection can be
  exited at an observation and be the first since the departure, so this is the duty at the one
  the applicability found.

  No choice beyond the record's own readings was made: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_60_090

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"

def zeroMetres : Term := .lit Q.zero .metre

/-- The subject's footprint overlaps the region bound to `v`. -/
def occ (v : String) : Formula := .atom "rel_occupies" [vSubject, .var v] []

/-- Class of `subject`: ru.taxicab -/
def clsSubject : Formula := .atom "ru_taxicab" [vSubject] []

/-- s2: the subject leaves a taxicab_stand curb zone at this observation. -/
def standDeparture : Formula :=
  .existsRegion (.lit "curb_zone") "k"
    (.and (.atom "st_curb_zone_kind" [.var "k", .lit "taxicab_stand"] [])
          (.rises (.not (occ "k"))))

/-- s4: a right_turn_only regulatory sign whose conditions hold for the subject governs a travel
    region the subject occupies at this observation. -/
def signAtDeparture : Formula :=
  .existsDevice (.lit "regulatory_sign") "d"
    (.and (.atom "dev_regulatory_sign_code" [.var "d", .lit "right_turn_only"] [])
      (.and (.derived "prim_conditions_hold" [.var "d", vSubject] [])
            (.existsRegion (.lit "travel_region") "v"
              (.and (.atom "dev_governs" [.var "d", .var "v"] []) (occ "v")))))

/-- s5: no intersection other than the one bound to `r` is overlapped by the subject. -/
def noOtherIntersection (r : String) : Formula :=
  .forallRegion (.lit "intersection") "q"
    (.or (.same (.var "q") (.var r)) (.not (occ "q")))

/-- s5 with s2 and s4: the subject exits intersection `r` now, and since its departure from a
    taxicab stand under a posted right_turn_only sign it has overlapped no other intersection. -/
def selection (r : String) : Formula :=
  .and (.rises (.not (occ r)))
       (.since (noOtherIntersection r) (.and standDeparture signAtDeparture))

/-- Applicability: s2 (trigger): upon leaving any stand designated in accordance with the provisions of this Section,; s4 (condition): when a sign is posted giving notice of this requirement,; s5 (condition): at the first street intersection after it leaves such stand. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "r" (selection "r")

/-- Obligation: s3 (obligation): shall execute a right-hand turn, -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "r"
    (.implies (selection "r")
      (.derived "drv_motion_right_turn_through_region" [vSubject, .var "r"]
        [pHeadingSinceStepCarlaSceneGraph, pTurnHeadingMin, pUTurnHeadingMin]))

def rule : Rule :=
  { id := "LVMC_11_60_090"
    laws := ["LVMC-11-60-090"]
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

end TrafficSpec.Rules.LVMC_11_60_090
