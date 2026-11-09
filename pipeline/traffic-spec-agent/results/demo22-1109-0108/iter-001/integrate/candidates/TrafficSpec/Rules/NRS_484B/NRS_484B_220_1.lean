/-
  NRS_484B_220_1 — NRS-484B-220-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Upon a highway designated and signposted for one-way traffic
    s2 (subject): a vehicle
    s3 (obligation): shall be driven only in the direction designated.

  Elements (span → atoms, derived):
    s1: atoms ['st.highway', 'st.one_way_roadway', 'st.roadway', 'st.travel_region', 'st.lane_direction', 'st.on_way', 'rel.occupies', 'dev.regulatory_sign', 'dev.governs', 'prim.conditions_hold', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['rel.occupies', 'st.travel_region', 'st.lane_direction'], derived ['drv.position.direction_component']

  How the spans are written:

    s1 (trigger) — `applicability`, one existential over the travelled region, whose body is
    `designatedOneWayRegion`: the subject's footprint overlaps a travel region (`rel_occupies`;
    `st.travel_region` is the quantifier's kind, the abstract union that admits the lane, roadway,
    one-way roadway and shoulder a designated direction may be carried on), that region is a
    roadway (`st_roadway`) on which traffic is restricted to one direction (`st_one_way_roadway`,
    which refines it — the designation carried as the ontology's vocabulary carries it), it lies on
    a highway (`st_on_way` under the quantifier over `st.highway`), it carries a designated
    direction of travel (`st_lane_direction`, read by its components: a region that carries none
    leaves the trigger unknown, never false), and a regulatory sign (the device quantifier's kind
    `dev.regulatory_sign`) of catalogue code `one_way` (`dev_regulatory_sign_code`) governs that
    region (`dev_governs`) with its posted conditions holding at the observation for the subject
    (`prim_conditions_hold`, unconditional where the legend states no restriction, unknown where no
    legend was read). “traffic” is its admitted aggregate DEF-NRS-484A-285::traffic, claimed of the
    bound road user (`ru_aggregate`): the travel the one-way designation governs is the subject's.

    s2 (subject) — `clsV`: membership of DEF-NRS-484A-320::vehicle, claimed whole.

    s3 (obligation) — `obligation`: at every region the trigger selects (the trigger's whole
    selection is repeated under the quantifier, so the region judged is the one s1 singled out, not
    merely a region of the same kind), the component of the vehicle's velocity along that region's
    designated direction of travel (`drv.position.direction_component`, built on kin.velocity and
    `st.lane_direction`) is strictly above the negative of p.wrong_way_speed_tolerance. A component
    at or below it is travel against the designation and violates; travel with the designation, a
    standstill and a movement across the region within the tolerance comply; an unobserved velocity
    or an unobserved designated direction leaves the duty unknown.

  The one choice the record left open, declared as a narrowing on s3: where the vehicle occupies
  several of the regions the trigger selects, the duty is written as holding at each of them (a
  universal quantifier over the selected regions), so a component at or below the negative
  tolerance at any one of them is a violation even where another selected region's component
  complies; the record would leave those two regions disagreeing undecided.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_220_1

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The travelled region the trigger selects and the obligation judges. -/
def rV : Arg := .var "r"

/-- The highway that region lies on. -/
def hV : Arg := .var "h"

/-- The regulatory sign that governs that region. -/
def dV : Arg := .var "d"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pWrongWaySpeedTolerance : Term := .param "p.wrong_way_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Zero, for a component of a designated direction of travel, which is read normalised. -/
def zeroDirection : Term := .lit Q.zero .ratio

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The components of the designated direction of travel of the region `r`. -/
def directionX : Term := .measure "st_lane_direction" [rV, .lit "x"]
def directionY : Term := .measure "st_lane_direction" [rV, .lit "y"]

/-- `r` carries a designated direction of travel: unknown where the source reads none for it. -/
def carriesDirection : Formula :=
  .not (.and (.cmp directionX .eq zeroDirection) (.cmp directionY .eq zeroDirection))

/-- `r` lies on a highway. -/
def onHighway : Formula :=
  .existsRegion (.lit "highway") "h" (.atom "st_on_way" [rV, hV] [])

/-- `r` is signposted for one-way traffic: a regulatory sign of code `one_way` governs it and its
    posted conditions hold at the observation for `v`. -/
def signpostedOneWay : Formula :=
  .existsDevice (.lit "regulatory_sign") "d"
    (.and (.atom "dev_regulatory_sign_code" [dV, .lit "one_way"] [])
      (.and (.atom "dev_governs" [dV, rV] [])
        (.derived "prim_conditions_hold" [dV, vV] [])))

/-- The travelled region the words speak of: a travel region `v` occupies which is a roadway
    restricted to one direction, lies on a highway, carries a designated direction of travel and is
    signposted for the one-way traffic `v` is part of. -/
def designatedOneWayRegion : Formula :=
  .and (.atom "rel_occupies" [vV, rV] [])
    (.and (.atom "st_roadway" [rV] [])
      (.and (.atom "st_one_way_roadway" [rV] [])
        (.and onHighway
          (.and carriesDirection
            (.and signpostedOneWay
              (.atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-285::traffic"] []))))))

/-- Applicability: s1 (trigger): Upon a highway designated and signposted for one-way traffic -/
def applicability : Formula :=
  .existsRegion (.lit "travel_region") "r" designatedOneWayRegion

/-- The component of `v`'s velocity along the designated direction of travel of `r`. -/
def directionComponent : Term :=
  .quantity "drv_position_direction_component" [vV, rV] []

/-- Obligation: s3 (obligation): shall be driven only in the direction designated. -/
def obligation : Formula :=
  .forallRegion (.lit "travel_region") "r"
    (.implies designatedOneWayRegion
      (.cmp directionComponent .gt (.neg pWrongWaySpeedTolerance)))

def rule : Rule :=
  { id := "NRS_484B_220_1"
    laws := ["NRS-484B-220-1"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s3",
          why := "Where the vehicle occupies several of the regions the trigger selects, the duty is written as holding at each of them (a universal quantifier over the selected regions): a component of the velocity at or below the negative of p.wrong_way_speed_tolerance at any one of them is a violation, even where another selected region's component complies. The record leaves selected regions that disagree undecided; the duty here is decided against the vehicle.",
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_220_1
