/-
  NRS_484B_250_4_o2 — NRS-484B-250-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    c1 (trigger): When a vehicle enters an intersection
    c2 (trigger): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, but is inoperative at the time the vehicle enters the intersection,
    c3 (subject): the driver of the vehicle
    c4 (sibling): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    c5 (condition): After making such a stop,
    c6 (subject): the driver
    c7 (standard): shall proceed cautiously,
    c8 (obligation): yielding to vehicles
    c9 (condition): which have previously completed a stop or are within the intersection.

  Elements (span → atoms, derived):
    c1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.intersection', 'rel.occupies'], derived []
    c2: atoms ['dev.traffic_signal', 'dev.inoperative', 'dev.governs', 'st.lane', 'st.lane_enters', 'st.intersection', 'rel.occupies'], derived []
    c3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    c5: atoms ['st.stop_line', 'st.intersection', 'st.region_geometry', 'rel.occupies'], derived ['drv.motion.at_rest']
    c6: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    c8: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.contact', 'prim.closest_approach_within', 'prim.closest_approach_distance', 'rel.bearing', 'kin.accel_longitudinal'], derived ['drv.motion.at_rest']
    c9: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'kin.time'], derived ['drv.motion.at_rest']

  How each span is written.

  c3, c6 — the binder's class `clsV`: `ru_aggregate v "DEF-NRS-484A-320::vehicle"`, the aggregate id
  whole, never the classes it covers. The record's observable reading of agency (the duty binds the
  vehicle's conduct, whoever is at the controls) is the plan's and is not restated below: every
  formula here judges the road user `v` and nothing asks who drives it.

  c1 — `enteredJunction`, in the `applicability`, under `existsRegion "intersection" i`: the
  subject's footprint overlaps the intersection region `i` (`rel_occupies v i`) and the observation
  at which that overlap began is `rises (rel_occupies v i)` — the entry is an edge against the
  previous observation, which is what "enters" can be read as on a sampled trace. "has occupied it
  ever since" is the `since`: the entry formula `entryHere` held at some earlier observation and
  `rel_occupies v i` at every observation from it to now.

  c2 — `headInoperative`, the entry formula's second conjunct: some device of kind
  `traffic_signal` (`existsDevice "traffic_signal" d`) whose vehicular faces are not covered
  (`dev_traffic_signal_uncovered d`), which governs the junction, and which shows no valid
  indication (`dev_inoperative d`). That the head is installed and placed by authority is its
  presence in the scene with the uncovered attribute, as the record directs. "Controlled by" is
  `governsJunction`: `dev_governs d i` of the intersection region itself, or `dev_governs d l` of a
  lane `l` that runs into it (`st_lane_enters l i`) — the ontology reads which intersection a
  device controls through both. Because the whole entry formula sits under the `since`, every leaf
  of c2 is read at the observation of entry, which is where the text puts it.

  c5 — `haltMade`, the entry formula's third conjunct: `since tt haltAt`, the past "once", so the
  halt is looked for at the observation of entry or at any observation before it. `haltAt` is the
  subject at rest (`drv.motion.at_rest` of `v`, at the reading's halt tolerance) while either its
  footprint overlaps a stop line (`existsRegion "stop_line" s`, `rel_occupies v s`) or its body
  stands within the junction reach of the intersection it then enters
  (`st_region_geometry_distance v i ≤ p.junction_approach_reach`). The two limbs are the record's
  two ways of showing the halt was made for this junction; `i` is the same region the subject
  enters, so a halt made for another junction does not answer.

  c7 — the operationalization, `cautious`: while the subject's footprint overlaps an intersection
  region, `kin_speed v ≤ p.cautious_speed`. It is written under
  `forallRegion "intersection" j, rel_occupies v j → …`, so the bound is required of the junction
  the subject is in and says nothing where it is in none. The limb is the duty's own content and is
  marked a surrogate, as the record declares.

  c9 — `claimant`, the road users the duty runs to: a road user `u` other than `v`
  (`not (same u v)`) of the admitted aggregate, which is within that same intersection region
  (`rel_occupies u j`) or which completed a stop previously — `completedStop`: at some observation
  of the look-back window `p.approach_lane_window` behind, `u` was at rest (`drv.motion.at_rest`)
  while its footprint did not overlap that intersection. "At some observation of the window" is
  written as the negation of `holdsFor .time` over the negated conjunction, the language's way of
  looking back over a metric window; the window is measured on the trace's clock (`kin_time`).

  c8 — `grantsPrecedence`, required of every claimant: their bodies do not touch or overlap
  (`not (rel_contact v u)`); and either their centres do not approach within the yield horizon
  (`prim_closest_approach_within`) or their centre distance at that closest approach
  (`prim_closest_approach_distance`) is at least `p.yield_clearance`; and the subject does not make
  the other give way to it — `notMadeToGiveWay`, the negation of: the subject's reference point
  stands in the other's way (`inTheWayOf`, read from `rel_bearing` in the OTHER's frame: the
  longitudinal component of `v` from `u` above none and at most `p.yield_block_reach`, the
  magnitude of the lateral component at most `p.single_file_reach`) while the other is at rest
  (`drv.motion.at_rest`) or decelerating at or beyond the give-way deceleration
  (`kin_accel_longitudinal u ≤ − p.yield_giveway_decel`). `inTheWayOf` stands first in the
  conjunction, so where the subject is not in the other's line the limb is decided false and no
  acceleration is read, as the record directs. The components are taken as `rel_bearing`'s `x`
  (longitudinal) and `y` (lateral), which is how Core names them for that atom.

  Narrowings: none of this coder's own. Every reading the formulas stand on — agency read through
  the vehicle's conduct, the installed-and-uncovered head read from its presence with the
  attribute, and yielding read through the conduct it secures on both its sides — is declared by
  the record and is not restated here.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_4_o2

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The quantified variables: the intersection the subject entered (`i`) and the one it is within
    when the duty is read (`j`), the signal head, a lane that runs into the junction, a stop line,
    and the other road user the duty runs to. -/
def iI : Arg := .var "i"
def jJ : Arg := .var "j"
def dD : Arg := .var "d"
def lL : Arg := .var "l"
def sS : Arg := .var "s"
def uU : Arg := .var "u"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pApproachLaneWindow : Term := .param "p.approach_lane_window"
def pCautiousSpeed : Term := .param "p.cautious_speed"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pJunctionApproachReach : Term := .param "p.junction_approach_reach"
def pSingleFileReach : Term := .param "p.single_file_reach"
def pYieldBlockReach : Term := .param "p.yield_block_reach"
def pYieldClearance : Term := .param "p.yield_clearance"
def pYieldGivewayDecel : Term := .param "p.yield_giveway_decel"
def pYieldHorizon : Term := .param "p.yield_horizon"

def zeroMetres : Term := .lit Q.zero .metre

/-- The admitted aggregate, carried whole. -/
def vehicleAggregate : String := "DEF-NRS-484A-320::vehicle"

/-- c5, c8, c9: a road user is not moving at the observation, at the reading's halt tolerance. -/
def atRest (x : Arg) : Formula := .derived "drv_motion_at_rest" [x] [pHaltSpeedTolerance]

/-- c1: the subject's footprint overlaps the intersection region `i`. -/
def withinI : Formula := .atom "rel_occupies" [vV, iI] []

/-- c2: the head governs the intersection region itself, or a lane that runs into it. -/
def governsJunction : Formula :=
  .or (.atom "dev_governs" [dD, iI] [])
      (.existsRegion (.lit "lane") "l"
        (.and (.atom "st_lane_enters" [lL, iI] []) (.atom "dev_governs" [dD, lL] [])))

/-- c2: an uncovered vehicular head governing this junction shows no valid indication. -/
def headInoperative : Formula :=
  .existsDevice (.lit "traffic_signal") "d"
    (.and (.atom "dev_traffic_signal_uncovered" [dD] [])
      (.and governsJunction (.atom "dev_inoperative" [dD] [])))

/-- c5: the subject at rest, where the halt counts as made for this junction — on a stop line, or
    with its body within the junction reach of the intersection it enters. -/
def haltAt : Formula :=
  .and (atRest vV)
    (.or (.existsRegion (.lit "stop_line") "s" (.atom "rel_occupies" [vV, sS] []))
         (.cmp (.measure "st_region_geometry_distance" [vV, iI]) .le pJunctionApproachReach))

/-- c5: such a halt was made at this observation or at an earlier one. -/
def haltMade : Formula := .since .tt haltAt

/-- c1 ∧ c2 ∧ c5: the observation of entry — the subject's occupancy of the junction begins, the
    governing head is inoperative, and the halt has been made. -/
def entryHere : Formula := .and (.rises withinI) (.and headInoperative haltMade)

/-- c1: the subject entered the junction at an earlier observation and has occupied it ever since. -/
def enteredJunction : Formula := .since withinI entryHere

/-- c7: the subject's rate of speed while it is within the junction. -/
def speedV : Term := .measure "kin_speed" [vV]

/-- c7 (the operationalization): proceeding cautiously. -/
def cautious : Formula := .cmp speedV .le pCautiousSpeed

/-- c9: another road user of the admitted aggregate. -/
def otherVehicle : Formula :=
  .and (.not (.same uU vV)) (.atom "ru_aggregate" [uU, .lit vehicleAggregate] [])

/-- c9: at some observation of the look-back window behind, the other was at rest while its
    footprint did not overlap that intersection. -/
def completedStop : Formula :=
  .not (.holdsFor .time pApproachLaneWindow "v"
         (.not (.and (atRest uU) (.not (.atom "rel_occupies" [uU, jJ] [])))))

/-- c9: the road users the duty runs to — within the intersection, or previously stopped. -/
def claimant : Formula :=
  .and otherVehicle (.or (.atom "rel_occupies" [uU, jJ] []) completedStop)

/-- c8: the bodies do not touch or overlap. -/
def noContact : Formula := .not (.atom "rel_contact" [vV, uU] [])

/-- c8: the centres do not approach within the horizon, or their distance at the closest approach
    is at least the yield clearance. -/
def clearOfConflict : Formula :=
  .or (.not (.derived "prim_closest_approach_within" [vV, uU] [pYieldHorizon]))
      (.cmp (.quantity "prim_closest_approach_distance" [vV, uU] [pYieldHorizon]) .ge pYieldClearance)

/-- c8: the subject's reference point stands ahead of the other along the direction the other's
    body points, within the obstruction reach and in its line, both in the other's frame. -/
def inTheWayOf : Formula :=
  .and (.cmp (.measure "rel_bearing" [uU, vV, .lit "x"]) .gt zeroMetres)
    (.and (.cmp (.measure "rel_bearing" [uU, vV, .lit "x"]) .le pYieldBlockReach)
          (.cmp (.abs (.measure "rel_bearing" [uU, vV, .lit "y"])) .le pSingleFileReach))

/-- c8: the other is at rest, or slowing at or beyond the give-way deceleration. -/
def givesWay : Formula :=
  .or (atRest uU)
      (.cmp (.measure "kin_accel_longitudinal" [uU]) .le (.neg pYieldGivewayDecel))

/-- c8: the subject does not make the other give way to it. -/
def notMadeToGiveWay : Formula := .not (.and inTheWayOf givesWay)

/-- c8: the subject grants the other precedence. -/
def grantsPrecedence : Formula := .and noContact (.and clearOfConflict notMadeToGiveWay)

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit vehicleAggregate] []

/-- Applicability: c1 (trigger): When a vehicle enters an intersection; c2 (trigger): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, but is inoperative at the time the vehicle enters the intersection,; c5 (condition): After making such a stop,; c9 (condition): which have previously completed a stop or are within the intersection. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" enteredJunction

/-- Obligation: c7 (standard): shall proceed cautiously,; c8 (obligation): yielding to vehicles -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "j"
    (.implies (.atom "rel_occupies" [vV, jJ] [])
      (.and cautious
        (.forallUser "u" (.implies claimant grantsPrecedence))))

def rule : Rule :=
  { id := "NRS_484B_250_4_o2"
    laws := ["NRS-484B-250-4"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations :=
      [ { standard := "shall proceed cautiously"
          concepts := ["kin.speed", "rel.occupies", "st.intersection"]
          params := ["p.cautious_speed"]
          convention := "Stopping-sight-distance model for an intersection approach: proceeding cautiously is proceeding no faster than the speed from which the vehicle can halt within the view the junction affords, so the subject's speed (kin.speed) while its footprint overlaps the intersection region is bounded by p.cautious_speed. The standard is the duty's own content here, so the bound is a policy choice and the limb is marked a surrogate."
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- every reading these formulas stand on is the record's own; none is this coder's
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_250_4_o2
