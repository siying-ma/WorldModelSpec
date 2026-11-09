/-
  NRS_484B_127_1 — NRS-484B-127-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (obligation): shall not follow another vehicle
    s3 (standard): more closely than is reasonable and prudent, having due regard for the speed of such vehicles and the traffic upon and the condition of the highway

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.speed'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.heading', 'kin.velocity', 'kin.speed'], derived ['drv.interaction.follows_in_line_of_travel']

  How each span is written:

    s1 — `clsV`, the binder's class: `ru_aggregate v "DEF-NRS-484A-320::vehicle"`, the admitted
      aggregate id and nothing else; never the classes the aggregate covers. "The driver of" is
      read through the vehicle's controlled motion, as the record's observable reading states:
      `driven` is `kin_speed v ≥ p.speed_resolution`, the body's speed standing clear of the
      source's resolution. The comparison is inclusive at the tolerance, which is the sense the
      called concept's own travel-speed tolerance carries ("the speed below which a measured
      velocity does not fix a direction of travel").

    s2 — `follows u`, the relation between the subject and a second road user, in two parts:
      · `followsInLine u` — `drv.interaction.follows_in_line_of_travel` of the subject and `u`,
        called with p.speed_resolution as the travel-speed tolerance, p.following_heading_cosine
        as the alignment tolerance, p.body_offset_resolution as the ahead offset,
        p.following_reach as the reach and p.single_file_reach as the line offset: the order the
        record states and the order of the concept's formal parameters. The concept decides the
        relation from the two bodies' positions, velocities and speeds, and reads no lane, so a
        scene that carries a roadway without lanes is decided exactly as one within a lane.
      · the at-rest limb — the concept admits a body at rest whatever way it lies, so where `u`'s
        own speed does not stand clear of the tolerance (`atRest u`) the span reads how that body
        lies from the atoms themselves: `liesAlongCourse u` is the magnitude of the inner product
        of `u`'s unit heading (kin.heading, by its "x" and "y" components) with the subject's
        velocity (kin.velocity, likewise), at least p.following_heading_cosine times the subject's
        speed (kin.speed). The product form is written rather than a quotient: a measured speed can
        be zero and a division by zero is unknown, not a verdict. The limb is an implication from
        `atRest u`, so the heading of a body that moves is never read, as the record requires.
      The second party is quantified, not bound: `applicability` asks for some other road user of
      the same admitted aggregate so followed (`.existsUser`), so a subject that follows nobody is
      left unengaged; `obligation` judges every such road user on its own (`.forallUser`).

    s3 — the operationalization, written as the headway convention the node states:
      · `headwayTime` — `.cond` on env.ice_or_snow selecting p.headway_ice, else `.cond` on
        env.wet_road selecting p.headway_wet, else p.headway_dry. A comparison over a `.cond` is
        decided wherever both selections decide it alike, so the surface condition leaves a verdict
        open only where the choice matters.
      · `closingAllowance u` — p.closing_time times the excess of the subject's speed over `u`'s
        where the subject is the faster, and zero where it is not (`.cond`), so a slower follower is
        owed no credit.
      · `trafficCount` — `.aggregate .count` over the road users `o` of the scene that are not the
        subject (`.same`), whose centre distance from the subject (rel.centre_distance) is at most
        p.traffic_reach, and whose footprint overlaps a highway region the subject's footprint
        overlaps too (`.existsRegion "highway" h` with rel_occupies of both bodies, the anchor the
        record names). The vehicle followed and a vehicle standing athwart the way are counted like
        any other road user, and no class screen is applied.
      · `spaceOwed u` — the subject's own speed times the headway time, plus the closing allowance,
        plus p.traffic_gap_increment times that count.
      · `keepsSpace u` — `drv.interaction.travel_gap` of the subject and `u`, with `spaceOwed u` as
        its travel-gap parameter and p.speed_resolution as its travel-speed tolerance. The
        comparison between the space left and the space owed is therefore the concept's own and
        inclusive, and the clear space is never read as a quantity of this rule; where the two
        bodies have come together that space is nothing and the bound is not met.

  Readings I chose, declared in `narrowings`: none. The record's elements, operationalization and
  narrowings fix every choice this file makes — the atoms of each span, the parameter each tolerance
  takes, the order of the three headway times, the sign of the closing allowance, the inclusive
  boundaries, and what the count of the traffic covers — so there is no reading of a carried span
  left to this session, and the record's own narrowings are the plan's and are not restated.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_127_1

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The quantifier variables: the other road user the subject is judged against, a road user of the
    traffic about the subject, and a highway region the two stand on. -/
def uV : Arg := .var "u"
def oV : Arg := .var "o"
def hV : Arg := .var "h"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pBodyOffsetResolution : Term := .param "p.body_offset_resolution"
def pClosingTime : Term := .param "p.closing_time"
def pFollowingHeadingCosine : Term := .param "p.following_heading_cosine"
def pFollowingReach : Term := .param "p.following_reach"
def pHeadwayDry : Term := .param "p.headway_dry"
def pHeadwayIce : Term := .param "p.headway_ice"
def pHeadwayWet : Term := .param "p.headway_wet"
def pSingleFileReach : Term := .param "p.single_file_reach"
def pSpeedResolution : Term := .param "p.speed_resolution"
def pTrafficGapIncrement : Term := .param "p.traffic_gap_increment"
def pTrafficReach : Term := .param "p.traffic_reach"

def zeroMetres : Term := .lit Q.zero .metre
/-- The quantity a count aggregates: the count itself is the number of members, so the term the
    aggregate carries adds nothing to it. -/
def noQuantity : Term := .lit Q.zero .count

/-- The magnitude of a road user's velocity. -/
def speedOf (x : Arg) : Term := .measure "kin_speed" [x]

/-- Membership of the admitted aggregate the text's "vehicle" is read as. -/
def vehicleOf (x : Arg) : Formula :=
  .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := vehicleOf vV

-- ---------------------------------------------------------------------------------------------
-- s1 (subject): the vehicle that is being driven
-- ---------------------------------------------------------------------------------------------

/-- s1: being driven — the body's speed stands clear of the source's resolution. -/
def driven : Formula := .cmp (speedOf vV) .ge pSpeedResolution

-- ---------------------------------------------------------------------------------------------
-- s2 (obligation): the vehicle followed
-- ---------------------------------------------------------------------------------------------

/-- s2: the subject travels behind `x` in its own line of travel. -/
def followsInLine (x : Arg) : Formula :=
  .derived "drv_interaction_follows_in_line_of_travel" [vV, x]
    [pSpeedResolution, pFollowingHeadingCosine, pBodyOffsetResolution, pFollowingReach,
     pSingleFileReach]

/-- s2: `x`'s own velocity fixes no direction of travel. -/
def atRest (x : Arg) : Formula := .cmp (speedOf x) .le pSpeedResolution

/-- s2: the component of `x`'s unit heading along the subject's direction of travel, taken as the
    inner product of that heading with the subject's velocity. -/
def headingAlongCourse (x : Arg) : Term :=
  .add (.mul (.measure "kin_heading" [x, .lit "x"]) (.measure "kin_velocity" [vV, .lit "x"]))
       (.mul (.measure "kin_heading" [x, .lit "y"]) (.measure "kin_velocity" [vV, .lit "y"]))

/-- s2: the body `x` presents lies along the subject's course — that component, in magnitude, is at
    least the alignment tolerance times the subject's speed. -/
def liesAlongCourse (x : Arg) : Formula :=
  .cmp (.abs (headingAlongCourse x)) .ge (.mul pFollowingHeadingCosine (speedOf vV))

/-- s2: the subject follows `x` — it travels behind it in its line of travel, and a body at rest
    is followed only where it lies along the subject's course. -/
def follows (x : Arg) : Formula :=
  .and (followsInLine x) (.implies (atRest x) (liesAlongCourse x))

/-- s2: `x` is another vehicle the subject follows. -/
def followedVehicle (x : Arg) : Formula :=
  .and (.not (.same x vV)) (.and (vehicleOf x) (follows x))

-- ---------------------------------------------------------------------------------------------
-- s3 (standard): the space the headway convention owes
-- ---------------------------------------------------------------------------------------------

/-- s3: the headway time the surface selects — ice or snow, else wet, else dry. -/
def headwayTime : Term :=
  .cond (.atom "env_ice_or_snow" [] []) pHeadwayIce
    (.cond (.atom "env_wet_road" [] []) pHeadwayWet pHeadwayDry)

/-- s3: the allowance for the speed by which the subject exceeds the road user ahead, and nothing
    where the subject is not the faster of the two. -/
def closingAllowance (x : Arg) : Term :=
  .cond (.cmp (speedOf vV) .gt (speedOf x))
        (.mul pClosingTime (.sub (speedOf vV) (speedOf x)))
        zeroMetres

/-- s3: `o` is one of the traffic upon the highway about the subject — another road user within the
    reach whose footprint overlaps a highway region the subject's footprint overlaps. -/
def trafficAbout : Formula :=
  .and (.not (.same oV vV))
    (.and (.cmp (.measure "rel_centre_distance" [vV, oV]) .le pTrafficReach)
      (.existsRegion (.lit "highway") "h"
        (.and (.atom "rel_occupies" [vV, hV] []) (.atom "rel_occupies" [oV, hV] []))))

/-- s3: how thick the traffic upon the highway is about the subject. -/
def trafficCount : Term := .aggregate .count "o" trafficAbout noQuantity

/-- s3: the space the convention owes the road user `x` ahead. -/
def spaceOwed (x : Arg) : Term :=
  .add (.mul (speedOf vV) headwayTime)
       (.add (closingAllowance x) (.mul pTrafficGapIncrement trafficCount))

/-- s3: the subject leaves `x` at least the space owed, along its own direction of travel. -/
def keepsSpace (x : Arg) : Formula :=
  .derived "drv_interaction_travel_gap" [vV, x] [spaceOwed x, pSpeedResolution]

-- ---------------------------------------------------------------------------------------------
-- The rule
-- ---------------------------------------------------------------------------------------------

/-- Applicability: s1 (subject): a vehicle being driven; s2 (obligation): that follows some other
    vehicle. -/
def applicability : Formula :=
  .and driven (.existsUser "u" (followedVehicle uV))

/-- Obligation: s2 (obligation): shall not follow another vehicle; s3 (standard): more closely than is reasonable and prudent, having due regard for the speed of such vehicles and the traffic upon and the condition of the highway -/
def obligation : Formula :=
  .forallUser "u" (.implies (followedVehicle uV) (keepsSpace uV))

def rule : Rule :=
  { id := "NRS_484B_127_1"
    laws := ["NRS-484B-127-1"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations :=
      [ { standard := "more closely than is reasonable and prudent, having due regard for the speed of such vehicles and the traffic upon and the condition of the highway"
          concepts := ["drv.interaction.travel_gap", "env.ice_or_snow", "env.wet_road", "kin.speed", "rel.centre_distance", "rel.occupies", "st.highway"]
          params := ["p.headway_dry", "p.headway_wet", "p.headway_ice", "p.closing_time", "p.traffic_reach", "p.traffic_gap_increment"]
          convention := "Time-headway convention (the two-second rule) with the surface braking factors, the closing-speed allowance and the density increment. The space the following vehicle owes is its own speed (kin.speed) times the headway time the surface selects - p.headway_ice where env.ice_or_snow holds, else p.headway_wet where env.wet_road holds, else p.headway_dry - plus p.closing_time times the amount by which the follower's speed exceeds the leader's, so a faster follower owes more space than a matched one, plus p.traffic_gap_increment for each other road user whose centre lies within p.traffic_reach of the subject (rel.centre_distance) and whose footprint overlaps the same highway region the subject's does (st.highway with rel.occupies as the anchor), so the space owed rises as the traffic upon the highway thickens. The space actually left is drv.interaction.travel_gap of this plan, 'the clear space, in metres, between the body of the road user f and the body of the road user l along f's direction of travel', and the duty is met where that space is at least the space owed; where the two bodies have come together the space is nothing and the bound is not met. Each named factor is read by its degree: the two speeds and the count of the traffic enter the bound itself, and the surface condition selects among the three headway times of one convention."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- the record's elements, operationalization and narrowings fix every choice; none is this session's
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_127_1
