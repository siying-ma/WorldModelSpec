/-
  NRS_484B_253_o1 — NRS-484B-253

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (trigger): within an intersection
    s3 (trigger): intending to turn to the left
    s4 (obligation): shall yield the right-of-way
    s5 (condition): to any vehicle approaching from the opposite direction
    s6 (condition): which is within the intersection
    s7 (standard): or so close thereto as to constitute an immediate hazard,
    s8 (sibling): but such driver, having so yielded
    s9 (sibling): and having given a signal
    s10 (sibling): when and as required,
    s11 (sibling): may make such left turn
    s12 (sibling): and the drivers of all other vehicles
    s13 (sibling): approaching the intersection from the opposite direction
    s14 (sibling): shall yield the right-of-way
    s15 (sibling): to the vehicle making the left turn.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived ['drv.motion.entering_region']
    s4: atoms ['kin.yaw_rate', 'kin.speed'], derived ['drv.motion.turning_left']
    s5: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.lane_enters', 'st.travel_region'], derived ['drv.road.opposed_directions', 'drv.motion.entering_region']
    s6: atoms ['rel.occupies', 'st.intersection'], derived []

  How each span is written:
    s1: binder class `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
    s2: intersection i (quantifier of kind `intersection`) with `rel_occupies x i`; x's approach
        carrier c (quantifier of kind `travel_region`) is fixed by `entryThrough`: `since` over
        `rel_occupies x i` back to x's latest entry (`drv_motion_entering_region x i`), at which x
        occupied c and `st_lane_enters c i`. An entry before the recording leaves `since` unknown.
    s3: `intent "int.left_turn" x i`, read at the judged observation.
    s4: x not turning left (`drv_motion_turning_left x` with p.speed_resolution,
        p.yaw_rate_resolution) where a vehicle is owed precedence.
    s5/s6: some vehicle y ≠ x (`same` excludes x) either (a) within i with its own latest entry
        through a carrier c2 for which `drv_road_opposed_directions c c2` holds, or
    s7: (b) outside i on an approach carrier c2 of i opposed to c, with
        `st_region_geometry_distance y i ≤ kin_speed y × p.immediate_hazard_gap`.
    Several entry carriers: the obligation holds where x yields through every one, fails where it
    yields through none, and is unknown where they disagree, as the record states.
    Choices the text did not dictate: the intersection itself is excluded from the carriers c and
    c2 by identity (`not (same c i)`), since it is no approach to itself and `st_lane_enters` on a
    region with no entrance record is unobserved rather than false.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_253_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pImmediateHazardGap : Term := .param "p.immediate_hazard_gap"
def pOpposedCarriersCosine : Term := .param "p.opposed_carriers_cosine"
def pSpeedResolution : Term := .param "p.speed_resolution"
def pYawRateResolution : Term := .param "p.yaw_rate_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- s1, s5: membership of the admitted aggregate DEF-NRS-484A-320::vehicle. -/
def vehicle (v : String) : Formula := .atom "ru_aggregate" [.var v, .lit "DEF-NRS-484A-320::vehicle"] []

/-- rel.occupies: road user `a`'s footprint overlaps region `r`. -/
def occ (a r : String) : Formula := .atom "rel_occupies" [.var a, .var r] []

/-- s2, s5: road user `a` has occupied intersection `i` at every observation since its latest entry
    into it (drv.motion.entering_region), at which entry it occupied carrier `c`, an approach whose
    entrance end is `i` (st.lane_enters). The intersection itself is no approach carrier of itself
    (it carries no entrance, so st.lane_enters on it is unobserved, never false): it is excluded by
    identity, not by any fact of the scene. -/
def entryThrough (a i c : String) : Formula :=
  .and (.not (.same (.var c) (.var i)))
    (.since (occ a i)
      (.and (.derived "drv_motion_entering_region" [.var a, .var i] [])
        (.and (occ a c) (.atom "st_lane_enters" [.var c, .var i] []))))

/-- drv.road.opposed_directions between x's approach carrier `c` and y's carrier `c2`. -/
def opposed (c c2 : String) : Formula :=
  .derived "drv_road_opposed_directions" [.var c, .var c2] [pOpposedCarriersCosine]

/-- s5, s6 (a): `y` is within `i`, having entered it through a carrier opposed to `c`. -/
def withinIntersection (c : String) : Formula :=
  .and (occ "y" "i")
    (.existsRegion (.lit "travel_region") "c2" (.and (entryThrough "y" "i" "c2") (opposed c "c2")))

/-- s5, s7 (b): `y`, outside `i`, occupies an approach carrier of `i` opposed to `c` and is so close
    to `i` as to be an immediate hazard: its ground distance to `i` is at most its speed times
    p.immediate_hazard_gap (the operationalization). -/
def immediateHazard (c : String) : Formula :=
  .and
    (.existsRegion (.lit "travel_region") "c2"
      (.and (occ "y" "c2")
        (.and (.atom "st_lane_enters" [.var "c2", .var "i"] []) (opposed c "c2"))))
    (.and (.not (occ "y" "i"))
      (.cmp (.measure "st_region_geometry_distance" [.var "y", .var "i"]) .le
        (.mul (.measure "kin_speed" [.var "y"]) pImmediateHazardGap)))

/-- s5: some vehicle other than x, approaching from the direction opposite to x's carrier `c`,
    within `i` or an immediate hazard to it. -/
def owedPrecedence (c : String) : Formula :=
  .existsUser "y"
    (.and (.not (.same (.var "y") vX))
      (.and (vehicle "y") (.or (withinIntersection c) (immediateHazard c))))

/-- s4: x yields, read as not turning left (drv.motion.turning_left), while a vehicle owed
    precedence through carrier `c` is present. -/
def yields (c : String) : Formula :=
  .implies (owedPrecedence c)
    (.not (.derived "drv_motion_turning_left" [vX] [pSpeedResolution, pYawRateResolution]))

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := vehicle "x"

/-- Applicability: s2 (trigger): within an intersection; s3 (trigger): intending to turn to the left; s5 (condition): to any vehicle approaching from the opposite direction; s6 (condition): which is within the intersection -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (occ "x" "i")
      (.and (.intent "int.left_turn" vX (.var "i"))
        (.existsRegion (.lit "travel_region") "c" (entryThrough "x" "i" "c"))))

/-- Obligation: s4 (obligation): shall yield the right-of-way; s7 (standard): or so close thereto as to constitute an immediate hazard,
    At each intersection selected as in the applicability: complied with where x yields through
    every carrier of its entry, violated where it yields through none, unknown where the carriers
    disagree (`definedWhen` over `ff` is false where its condition holds, unknown elsewhere). -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies (.and (occ "x" "i") (.intent "int.left_turn" vX (.var "i")))
      (.or
        (.forallRegion (.lit "travel_region") "c" (.implies (entryThrough "x" "i" "c") (yields "c")))
        (.definedWhen
          (.not (.existsRegion (.lit "travel_region") "c" (.and (entryThrough "x" "i" "c") (yields "c"))))
          .ff)))

def rule : Rule :=
  { id := "NRS_484B_253_o1"
    laws := ["NRS-484B-253"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations :=
      [ { standard := "so close to the intersection as to constitute an immediate hazard"
          concepts := ["kin.speed", "st.region_geometry"]
          params := ["p.immediate_hazard_gap"]
          convention := "Gap acceptance (HCM critical headway): an approaching vehicle outside the intersection is an immediate hazard where its ground distance to the intersection (st.region_geometry 'the ground distance from a road user's body outline to it') is at most its speed (kin.speed) times p.immediate_hazard_gap, so the bound moves with both proximity and speed."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_253_o1
