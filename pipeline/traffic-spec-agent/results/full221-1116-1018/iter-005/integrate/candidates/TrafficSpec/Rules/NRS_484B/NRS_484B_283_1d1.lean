/-
  NRS_484B_283_1d1 — NRS-484B-283-1d1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    r (reference): Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:
    c0 (condition): Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows:
    t (trigger): While the “Walk” indication or walking person symbol is illuminated,
    c1 (condition): pedestrians facing the signal
    c2 (condition): may proceed across the highway in the direction of the signal
    ob (obligation): and must be given
    st (standard): the right-of-way
    s (subject): by the drivers of all vehicles.

  Elements (span → atoms, derived):
    c0: atoms ['dev.pedestrian_signal', 'dev.governs', 'st.roadway', 'st.lane'], derived []
    t: atoms ['dev.pedestrian_signal'], derived []
    c1: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian', 'kin.heading', 'kin.position', 'dev.position'], derived []
    c2: atoms ['rel.occupies', 'st.roadway', 'st.lane'], derived []
    ob: atoms ['kin.speed', 'rel.contact'], derived []
    s: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []

  Compositions (span → node, as, map):
    r: NRS_484B_287_1c as exception map {'subject': 'p'}
    r: NRS_484B_287_1d as exception map {'subject': 'p'}
    r: NRS_484B_287_1e as exception map {'subject': 'p'}
    r: LVMC_11_30_060_A as exception map {'subject': 'p'}
    r: LVMC_11_30_060_B as exception map {'subject': 'p'}
    r: LVMC_11_30_140_B_o1 as exception map {'subject': 'subject'}
    r: LVMC_11_30_140_B_o2 as exception map {'subject': 'subject'}
    r: LVMC_11_46_030_o1 as exception map {'subject': 'subject'}
    r: LVMC_11_46_030_o2 as exception map {'subject': 'subject'}

  How each is written:
    s:  the binder class is `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    r:  the four subject-mapped exceptions are `not ruleApplies … [subject ↦ subject]` in the
        applicability; the five pedestrian-mapped ones are `not ruleApplies … [subject ↦ p]` inside
        the selection of each pedestrian p (`selected p`), so a pedestrian engaged by them is not
        one this rule protects.
    c0, t: a device d of kind pedestrian_signal (`existsDevice "pedestrian_signal"`) whose state
        is walk (`dev_pedestrian_signal_state d walk`), governing (`dev_governs d r`) a region r
        of kind roadway or of kind lane (two region quantifiers, one per kind named).
    c1: `ru_aggregate p "DEF-NRS-484A-165::pedestrian"`; facing is the record's three
        comparisons, with Δ = dev_position d − kin_position p and h = kin_heading p:
        h·Δ > 0, (h·Δ)² ≥ cos²·|Δ|², |Δ|² ≤ reach² (squares, so no division and no root).
    c2: `rel_occupies p r` for that region r governed by d.
    ob, st: for every selected pedestrian p (the applicability's whole selection repeated in the
        obligation through the same `selected` definition): not `rel_contact subject p`, and where
        `kin_speed subject > p.halt_speed_tolerance`, not (`prim_closest_approach_within subject p
        horizon` and `prim_closest_approach_distance subject p horizon < clearance`).
  No choice beyond the record was needed: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_283_1d1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables: the pedestrian, the pedestrian head, the governed region. -/
def vP : Arg := .var "p"
def vD : Arg := .var "d"
def vR : Arg := .var "r"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pPedSignalFacingCos : Term := .param "p.ped_signal_facing_cos"
def pPedSignalFacingReach : Term := .param "p.ped_signal_facing_reach"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- c1: pedestrian membership. -/
def isPedestrian : Formula := .atom "ru_aggregate" [vP, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- c1: Δ from the pedestrian's position to the head's position, and the pedestrian's heading. -/
def dx : Term := .sub (.measure "dev_position" [vD, .lit "x"]) (.measure "kin_position" [vP, .lit "x"])
def dy : Term := .sub (.measure "dev_position" [vD, .lit "y"]) (.measure "kin_position" [vP, .lit "y"])
def hx : Term := .measure "kin_heading" [vP, .lit "x"]
def hy : Term := .measure "kin_heading" [vP, .lit "y"]
def dotHD : Term := .add (.mul hx dx) (.mul hy dy)
def distSq : Term := .add (.mul dx dx) (.mul dy dy)

/-- c1: p faces d (cone and reach). -/
def facing : Formula :=
  .and (.cmp dotHD .gt zeroMetres)
    (.and (.cmp (.mul dotHD dotHD) .ge (.mul (.mul pPedSignalFacingCos pPedSignalFacingCos) distSq))
          (.cmp distSq .le (.mul pPedSignalFacingReach pPedSignalFacingReach)))

/-- c0, c2: a roadway or lane governed by d that p's footprint overlaps. -/
def onGovernedWay : Formula :=
  .or (.existsRegion (.lit "roadway") "r" (.and (.atom "dev_governs" [vD, vR] []) (.atom "rel_occupies" [vP, vR] [])))
      (.existsRegion (.lit "lane") "r" (.and (.atom "dev_governs" [vD, vR] []) (.atom "rel_occupies" [vP, vR] [])))

/-- c0, t, c1, c2: a pedestrian head showing walk, faced by p, governing the way p is on. -/
def walkHeadFaced : Formula :=
  .existsDevice (.lit "pedestrian_signal") "d"
    (.and (.atom "dev_pedestrian_signal_state" [vD, .lit "walk"] [])
      (.and facing onGovernedWay))

/-- r: the exceptions mapped to the pedestrian. -/
def pedNotExcepted : Formula :=
  .and (.not (.ruleApplies "NRS_484B_287_1c" [("subject", "p")]))
    (.and (.not (.ruleApplies "NRS_484B_287_1d" [("subject", "p")]))
      (.and (.not (.ruleApplies "NRS_484B_287_1e" [("subject", "p")]))
        (.and (.not (.ruleApplies "LVMC_11_30_060_A" [("subject", "p")]))
              (.not (.ruleApplies "LVMC_11_30_060_B" [("subject", "p")])))))

/-- The record's whole selection of a pedestrian p owed the right-of-way. -/
def selected : Formula :=
  .and isPedestrian (.and walkHeadFaced pedNotExcepted)

/-- r: the exceptions mapped to the subject. -/
def subjectNotExcepted : Formula :=
  .and (.not (.ruleApplies "LVMC_11_30_140_B_o1" [("subject", "subject")]))
    (.and (.not (.ruleApplies "LVMC_11_30_140_B_o2" [("subject", "subject")]))
      (.and (.not (.ruleApplies "LVMC_11_46_030_o1" [("subject", "subject")]))
            (.not (.ruleApplies "LVMC_11_46_030_o2" [("subject", "subject")]))))

/-- Applicability: c0 (condition): Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows:; t (trigger): While the “Walk” indication or walking person symbol is illuminated,; c1 (condition): pedestrians facing the signal; c2 (condition): may proceed across the highway in the direction of the signal -/
def applicability : Formula :=
  .and subjectNotExcepted (.existsUser "p" selected)

/-- st: the right-of-way given to p — no conflict while the subject moves. -/
def rightOfWayGiven : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, vP] []))
    (.implies (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
      (.not (.and (.derived "prim_closest_approach_within" [vSubject, vP] [pConflictHorizon])
                  (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vP] [pConflictHorizon])
                        .lt pConflictCentreClearance))))

/-- Obligation: ob (obligation): and must be given; st (standard): the right-of-way -/
def obligation : Formula :=
  .forallUser "p" (.implies selected rightOfWayGiven)

def rule : Rule :=
  { id := "NRS_484B_283_1d1"
    laws := ["NRS-484B-283-1d1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the right-of-way: precedence where the two approach 'under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence' (DEF-NRS-484A-210)"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "traffic-conflict technique: while the vehicle moves (speed above the halt tolerance), a predicted closest approach of the two centres within the conflict horizon at a centre distance below the conflict clearance is a danger of a crash in which the vehicle has not granted precedence"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_283_1d1
