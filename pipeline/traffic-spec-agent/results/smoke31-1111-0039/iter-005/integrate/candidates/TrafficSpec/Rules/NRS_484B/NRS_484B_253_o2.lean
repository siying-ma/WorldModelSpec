/-
  NRS_484B_253_o2 — NRS-484B-253

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (trigger): within an intersection
    s3 (trigger): intending to turn to the left
    s4 (sibling): shall yield the right-of-way
    s5 (sibling): to any vehicle approaching from the opposite direction
    s6 (sibling): which is within the intersection
    s7 (sibling): or so close thereto as to constitute an immediate hazard,
    s8 (condition): but such driver, having so yielded
    s9 (condition): and having given a signal
    s10 (reference): when and as required,
    s11 (condition): may make such left turn
    s12 (subject): and the drivers of all other vehicles
    s13 (trigger): approaching the intersection from the opposite direction
    s14 (obligation): shall yield the right-of-way
    s15 (condition): to the vehicle making the left turn.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived ['drv.motion.entering_region']
    s9: atoms ['sig.turn_indicator', 'sig.hand_signal', 'rel.occupies', 'st.travel_region', 'st.intersection', 'st.lane_enters'], derived ['drv.motion.entering_region']
    s11: atoms ['kin.yaw_rate', 'kin.speed', 'rel.occupies', 'st.intersection'], derived ['drv.motion.turning_left']
    s12: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s13: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived ['drv.motion.entering_region', 'drv.road.opposed_directions']
    s14: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.entering_region']
    s15: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection'], derived ['drv.motion.turning_left']

  Compositions (span → node, as, map):
    s8: NRS_484B_253_o1 as compliance map {'x': 'y'}

  How each is written:
    s1, s12: `ru_aggregate` with DEF-NRS-484A-320::vehicle, of x (the binder's class) and of the
      turning vehicle y (quantified over the scene's road users, `same x y` excluded).
    applicability (s13's approach, s14's event): x enters an intersection i at this observation
      (`drv_motion_entering_region x i`) and occupies at this observation a travel region c whose
      entrance end is i (`rel_occupies x c`, `st_lane_enters c i`). A carrier (c here, c2 below)
      is a travel region that is no intersection (`not st_intersection`): st.lane_enters' contract
      names the carriers (lanes, roadways, shoulders, bicycle lanes or paths), and an intersection,
      a travel region x and y occupy whenever they are in it, carries no entrance record, so the
      relation would otherwise read unknown on i itself and no entry would be decided. This
      states the contract's carrier, not a narrower one.
    s2 (within an intersection, of y): `rel_occupies y i` now, and `since (rel_occupies y i)
      (entering_region y i ∧ rel_occupies y c2)`: y has occupied i at every observation since its
      latest entry into i, at which it occupied the travel region c2 with `st_lane_enters c2 i`.
    s13 (from the opposite direction): `drv_road_opposed_directions c c2` with
      p.opposed_carriers_cosine, read from the carriers, never from headings.
    s3: `intent int.left_turn y i`, read at the judged observation.
    s9 (signal): `since (occ y c2 ∨ occ y i) (signal ∧ since (occ y c2 ∨ occ y i)
      (entering_region y c2))`, signal being `sig_turn_indicator y left ∨ sig_hand_signal y left`:
      some observation since y last came onto c2, y on c2 or in i at every one since that arrival.
    s11, s15, s8 (making the turn, having so yielded): `since (occ y i) (rises (turning_left y ∧
      occ y i) ∧ since o1 (o1 ∧ entering_region y i))`: the onset O of the turn within i, y in i at
      every observation from O to now, and NRS_484B_253_o1 {x ↦ y} complied with at every
      observation from y's entry into i (included) through O. Nothing after O is read for o1.
    s14: the duty is that no such y exists at x's entry (`not (existsUser y …)`).
    Several carriers: the obligation is decided where every (i, c) x enters through gives the same
      verdict, and unknown (`definedWhen`) where they differ, as the record's applicability states.
    s10: the node's residue. No choice beyond the record's was needed; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_253_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pOpposedCarriersCosine : Term := .param "p.opposed_carriers_cosine"
def pSpeedResolution : Term := .param "p.speed_resolution"
def pYawRateResolution : Term := .param "p.yaw_rate_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantified variables: the turning vehicle, the intersection, x's and y's approach carriers. -/
def vY : Arg := .var "y"
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vC2 : Arg := .var "c2"

/-- s1, s12, s15: a vehicle of the admitted aggregate. -/
def vehicle (u : Arg) : Formula := .atom "ru_aggregate" [u, .lit "DEF-NRS-484A-320::vehicle"] []

def occ (u r : Arg) : Formula := .atom "rel_occupies" [u, r] []

def entering (u r : Arg) : Formula := .derived "drv_motion_entering_region" [u, r] []

/-- c is an approach carrier whose entrance end is i: st.lane_enters, on a carrier (st.lane_enters'
    contract: a lane, roadway, shoulder or bicycle lane or path — never an intersection, which is a
    travel region but no carrier, and on which the relation is never recorded). -/
def approachTo (c i : Arg) : Formula :=
  .and (.not (.atom "st_intersection" [c] [])) (.atom "st_lane_enters" [c, i] [])

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := vehicle vX

/-- x enters i at this observation through a carrier c it occupies whose entrance end is i. -/
def entersThrough (i c : Arg) : Formula :=
  .and (entering vX i) (.and (occ vX c) (approachTo c i))

/-- Applicability: s13 (trigger): approaching the intersection — x enters i from an approach carrier c. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" (.existsRegion (.lit "travel_region") "c" (entersThrough vI vC))

/-- s9: y's left signal, by indicator or by arm. -/
def signalLeft : Formula :=
  .or (.atom "sig_turn_indicator" [vY, .lit "left"] []) (.atom "sig_hand_signal" [vY, .lit "left"] [])

/-- y on c2 or in i. -/
def onApproachOrIn : Formula := .or (occ vY vC2) (occ vY vI)

/-- s9: a left signal at some observation since y last came onto c2, y on c2 or in i since then. -/
def signalled : Formula :=
  .since onApproachOrIn (.and signalLeft (.since onApproachOrIn (entering vY vC2)))

/-- s2, s13, s9: y has been in i since its latest entry, made from c2, a carrier opposed to x's c,
    on which y signalled left. -/
def withinFromOpposite : Formula :=
  .existsRegion (.lit "travel_region") "c2"
    (.and (approachTo vC2 vI)
      (.and (.derived "drv_road_opposed_directions" [vC, vC2] [pOpposedCarriersCosine])
        (.and (.since (occ vY vI) (.and (entering vY vI) (occ vY vC2)))
          signalled)))

/-- s11: y turning left within i. -/
def turningLeftIn : Formula :=
  .and (.derived "drv_motion_turning_left" [vY] [pSpeedResolution, pYawRateResolution]) (occ vY vI)

/-- s8: NRS_484B_253_o1 complied with by y. -/
def soYielded : Formula := .rule "NRS_484B_253_o1" [("x", "y")]

/-- s11, s15, s8: the turn began within i at an onset O, y in i at every observation since O, and
    o1 complied with from y's entry into i (included) through O. -/
def makingTurn : Formula :=
  .since (occ vY vI)
    (.and (.rises turningLeftIn) (.since soYielded (.and soYielded (entering vY vI))))

/-- s15: a vehicle other than x making a left turn in i under the words' conditions. -/
def turningVehicle (i c : Arg) : Formula :=
  .existsUser "y"
    (.and (.not (.same vX vY))
      (.and (vehicle vY)
        (.and (occ vY i)
          (.and (.intent "int.left_turn" vY i)
            (.and withinFromOpposite makingTurn)))))

/-- At every entry of x through a carrier, `φ` of that intersection and carrier. -/
def atEveryEntry (φ : Arg → Arg → Formula) : Formula :=
  .forallRegion (.lit "intersection") "i" (.forallRegion (.lit "travel_region") "c"
    (.implies (entersThrough vI vC) (φ vI vC)))

/-- Obligation: s14 (obligation): shall yield the right-of-way — at x's entry no vehicle is making
    the left turn; unknown where the carriers x enters through disagree. -/
def obligation : Formula :=
  .definedWhen
    (.or (atEveryEntry fun i c => .not (turningVehicle i c)) (atEveryEntry turningVehicle))
    (atEveryEntry fun i c => .not (turningVehicle i c))

def rule : Rule :=
  { id := "NRS_484B_253_o2"
    laws := ["NRS-484B-253"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations := []
    residues := ["'when and as required' refers to signalling requirements stated outside this line, and no bracketed id resolves which rule it names; the signal itself is read on s9."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_253_o2
