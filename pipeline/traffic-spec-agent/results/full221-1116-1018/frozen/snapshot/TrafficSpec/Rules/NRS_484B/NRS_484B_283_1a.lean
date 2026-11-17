/-
  NRS_484B_283_1a — NRS-484B-283-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    r (reference): Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:
    c1 (condition): When official traffic-control devices are not in place or not in operation,
    s (subject): the driver of a vehicle
    ob (obligation): shall yield the right-of-way,
    st (standard): slowing down or stopping if need be so to yield,
    c2 (condition): to a pedestrian crossing the highway within a crosswalk
    c3 (condition): when the pedestrian is upon the half of the highway upon which the vehicle is traveling or onto which the vehicle is turning,
    st2 (standard): or when the pedestrian is approaching so closely from the opposite half of the highway as to be in danger.
    d (definitional): As used in this section, “half of the highway” means all traffic lanes of a highway which are designated for traffic traveling in one direction, and includes the entire highway in the case of a one-way highway.

  Elements (span → atoms, derived):
    c1: atoms ['dev.traffic_signal', 'dev.pedestrian_signal', 'dev.governs', 'dev.inoperative', 'rel.occupies', 'st.travel_region'], derived []
    s: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    ob: atoms ['kin.speed', 'rel.contact'], derived []
    c2: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian', 'rel.occupies', 'st.crosswalk'], derived []
    c3: atoms ['rel.occupies', 'st.lane', 'st.one_way_roadway', 'st.lane_direction', 'kin.heading'], derived []
    d: atoms ['st.lane', 'st.lane_direction', 'st.one_way_roadway'], derived []

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

  How each span is written:
    s: `ru_aggregate subject DEF-NRS-484A-320::vehicle` (binder class).
    c1: `devicesOut` — every traffic signal head (quantifier kind traffic_signal) that governs
        (dev_governs) a travel region (kind travel_region) the subject occupies (rel_occupies) shows
        dark or is inoperative; with no such head the condition holds ('not in place'). The pedestrian
        heads are `pedHeadsDark`: every pedestrian signal head governing a travel region p occupies
        shows dark, read inside the selection of p.
    c2: p is a pedestrian (ru_aggregate DEF-NRS-484A-165::pedestrian) whose footprint overlaps a
        crosswalk (marked or not: the kind alone).
    c3 + d: `onSubjectsHalf` — p occupies a lane or a one-way roadway whose designated direction has
        a positive dot product with the subject's heading.
    st2: `approachingFromOpposite` — p occupies a lane whose designated direction has a negative dot
        product with the subject's heading, and the closest approach of subject and p lies within
        p.conflict_horizon at a centre distance below p.conflict_centre_clearance.
    ob + st: for every selected p, no rel_contact, and where kin_speed exceeds p.halt_speed_tolerance,
        no such predicted conflict.
    r: each composition `.not (.ruleApplies …)` — those on the pedestrian with map subject ↦ p inside
        the selection of p, those on the subject with subject ↦ subject in the applicability.
  The selection of p (`pedestrianSelected`) is one formula, read in the applicability under
  `existsUser p` and in the obligation under `forallUser p`, so both denote the same pedestrians.
  No choice beyond the record was needed: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_283_1a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre
/-- Zero for the sign of a dot product of two unit directions (dimensionless). -/
def zeroRatio : Term := .lit Q.zero .ratio

/-- The pedestrian variable of c2/c3/st2. -/
def vP : Arg := .var "p"

/-- s: the subject is a vehicle (DEF-NRS-484A-320::vehicle). -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The dot product of a carrier's designated direction (st.lane_direction) with the subject's
    heading (kin.heading), both read normalised. -/
def dirDotHeading (r : String) : Term :=
  .add (.mul (.measure "st_lane_direction" [.var r, .lit "x"]) (.measure "kin_heading" [vSubject, .lit "x"]))
       (.mul (.measure "st_lane_direction" [.var r, .lit "y"]) (.measure "kin_heading" [vSubject, .lit "y"]))

/-- c1: every traffic signal head governing a travel region the subject occupies shows dark or is
    inoperative ('not in place' is the vacuous case: no such head). -/
def devicesOut : Formula :=
  .forallDevice (.lit "traffic_signal") "d"
    (.forallRegion (.lit "travel_region") "rd"
      (.implies
        (.and (.atom "dev_governs" [.var "d", .var "rd"] []) (.atom "rel_occupies" [vSubject, .var "rd"] []))
        (.or (.atom "dev_traffic_signal_shows" [.var "d", .lit "dark"] [])
             (.atom "dev_inoperative" [.var "d"] []))))

/-- c1 (pedestrian heads): every pedestrian signal head governing a travel region p occupies shows dark. -/
def pedHeadsDark : Formula :=
  .forallDevice (.lit "pedestrian_signal") "e"
    (.forallRegion (.lit "travel_region") "re"
      (.implies
        (.and (.atom "dev_governs" [.var "e", .var "re"] []) (.atom "rel_occupies" [vP, .var "re"] []))
        (.atom "dev_pedestrian_signal_state" [.var "e", .lit "dark"] [])))

/-- st/st2: the predicted closest approach of the subject and p falls within the conflict horizon
    at a centre distance below the conflict clearance. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vP] [pConflictHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vP] [pConflictHorizon]) .lt pConflictCentreClearance)

/-- c3 + d: p is upon the subject's half — a lane or a one-way roadway p occupies whose designated
    direction points with the subject's heading. -/
def onSubjectsHalf : Formula :=
  .or
    (.existsRegion (.lit "lane") "lh"
      (.and (.atom "rel_occupies" [vP, .var "lh"] []) (.cmp (dirDotHeading "lh") .gt zeroRatio)))
    (.existsRegion (.lit "one_way_roadway") "wh"
      (.and (.atom "rel_occupies" [vP, .var "wh"] []) (.cmp (dirDotHeading "wh") .gt zeroRatio)))

/-- st2: p on the opposite half (a lane p occupies whose designated direction points against the
    subject's heading) and approaching so closely as to be in danger. -/
def approachingFromOpposite : Formula :=
  .and
    (.existsRegion (.lit "lane") "lo"
      (.and (.atom "rel_occupies" [vP, .var "lo"] []) (.cmp (dirDotHeading "lo") .lt zeroRatio)))
    conflict

/-- r: the exceptions read of the pedestrian (NRS 484B.287 / LVMC 11-30-060). -/
def pedExceptions : Formula :=
  .and (.not (.ruleApplies "NRS_484B_287_1c" [("subject", "p")]))
  (.and (.not (.ruleApplies "NRS_484B_287_1d" [("subject", "p")]))
  (.and (.not (.ruleApplies "NRS_484B_287_1e" [("subject", "p")]))
  (.and (.not (.ruleApplies "LVMC_11_30_060_A" [("subject", "p")]))
        (.not (.ruleApplies "LVMC_11_30_060_B" [("subject", "p")])))))

/-- r: the exceptions read of the subject (LVMC 11-30-140(B), 11-46-030). -/
def subjectExceptions : Formula :=
  .and (.not (.ruleApplies "LVMC_11_30_140_B_o1" [("subject", "subject")]))
  (.and (.not (.ruleApplies "LVMC_11_30_140_B_o2" [("subject", "subject")]))
  (.and (.not (.ruleApplies "LVMC_11_46_030_o1" [("subject", "subject")]))
        (.not (.ruleApplies "LVMC_11_46_030_o2" [("subject", "subject")]))))

/-- The whole selection of the pedestrian p (c2, c3/st2, pedestrian heads of c1, exceptions of r);
    written once and read identically in the applicability and the obligation. -/
def pedestrianSelected : Formula :=
  .and (.atom "ru_aggregate" [vP, .lit "DEF-NRS-484A-165::pedestrian"] [])
  (.and (.existsRegion (.lit "crosswalk") "cw" (.atom "rel_occupies" [vP, .var "cw"] []))
  (.and pedHeadsDark
  (.and (.or onSubjectsHalf approachingFromOpposite)
        pedExceptions)))

/-- Applicability: r (subject's exceptions), c1, and some pedestrian selected by c2/c3/st2. -/
def applicability : Formula :=
  .and devicesOut
  (.and (.existsUser "p" pedestrianSelected)
        subjectExceptions)

/-- Obligation (ob, st): for every selected pedestrian, no contact, and while the subject moves
    (speed above the halt tolerance) no predicted conflict. -/
def obligation : Formula :=
  .forallUser "p"
    (.implies pedestrianSelected
      (.and (.not (.atom "rel_contact" [vSubject, vP] []))
            (.implies (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
                      (.not conflict))))

def rule : Rule :=
  { id := "NRS_484B_283_1a"
    laws := ["NRS-484B-283-1a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "slowing down or stopping if need be so to yield (the right-of-way's 'danger of a crash unless one grants precedence')"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "traffic-conflict technique: while the vehicle moves (speed above the halt tolerance), a predicted closest approach of the two centres within the conflict horizon at a centre distance below the conflict clearance is a danger of a crash the driver has not yielded to; a vehicle at rest has slowed or stopped as need be"
          surrogate := false }
      , { standard := "approaching so closely from the opposite half as to be in danger"
          concepts := ["kin.heading", "prim.closest_approach_distance", "prim.closest_approach_within", "rel.occupies", "st.lane", "st.lane_direction"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: a pedestrian in the crosswalk on a lane whose designated direction points against the vehicle's heading is in danger where the predicted closest approach of the two centres falls within the conflict horizon at a centre distance below the conflict clearance"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_283_1a
