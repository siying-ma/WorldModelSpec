/-
  NRS_484B_407 — NRS-484B-407

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A vehicle
    s2 (obligation): shall not be turned so as to proceed in the opposite direction
    s3 (condition): upon any curve,
    s4 (boilerplate): or
    s5 (condition): upon the approach to or near the crest of a grade,
    s6 (condition): where such vehicle cannot be seen by the driver of any other vehicle approaching from either direction within 500 feet.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=vehicle'], derived []
    s2: atoms [], derived ['drv.motion.u_turn']
    s3: atoms ['st.curvature', 'rel.occupies', 'st.roadway'], derived []
    s5: atoms ['st.crest', 'st.region_geometry'], derived []
    s6: atoms ['st.sight_distance'], derived []

  Literals the text states (each written through its Units constructor):
    s6: 500 ft — 500 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written.

  s1 — `clsV` is the aggregate word itself, `ru_aggregate v "vehicle"`: the word the text uses,
  never the member classes the run's reading derives for it.

  s3 — `uponACurve` is read on the roadway region the subject's footprint overlaps
  (`existsRegion "roadway" rw`, `rel_occupies v rw`), so the bend is the one the subject is upon
  and not a bend elsewhere in the scene. The span states no sharpness, so the condition is the
  presence of a bend: the magnitude of the roadway's curvature at that place is at or above the
  reciprocal of `p.curve_radius_floor`, the flattest alignment the source still tells from a
  tangent. That comparison, `|κ| ≥ 1 / R`, is written with the division cleared: both sides
  multiplied by the floor radius squared, which is positive, give `|κ| · R · R ≥ R`, two lengths
  compared. The rule therefore divides nothing and states no magnitude of its own — neither a
  bound of the reading's nor the bare one a reciprocal would need: the only figure in the
  condition is the parameter, written twice.

  s5 — `nearACrest` is the ground distance from the subject's body outline to a crest region
  (`st_region_geometry_distance v cr` over `existsRegion "crest" cr`) at or below `p.crest_reach`.
  The reach is what the span's own words, "the approach to or near", state without a figure, and
  it is two-sided, as the distance to a region is. `st.grade` is not read: the slope where a road
  user is says nothing of a crest ahead of it.

  s6 — `cannotBeSeen` is the sight distance of the place the subject is at, below the 500 feet the
  text states. The blueprint reads the words through the road's own geometry rather than through
  what a driver perceives (its narrowing on s6, gap G5): `st_sight_distance` speaks of both
  directions and of whether a vehicle at the place could be seen, whether or not another road user
  is there, which is the case the words are written for. That reading is the node's and is left
  where the node records it; this file adds no narrowing of its own.

  s3, s5, s6 together — the place the duty speaks of is one formula, `atSuchAPlace`: upon a
  roadway the subject occupies, either the bend (s3) or the nearness to a crest (s5), and, joined
  to whichever holds, the short sight distance (s6). It stands bare in `applicability` — the rule
  is engaged of a vehicle at such a place, which is what the node's applicability states "at the
  observation" and what the `permit` scene needs to be cleared rather than left not applicable.

  s2 and the occasion — `obligation` forbids the act: the turning about is
  `drv.motion.u_turn v [p.turn_window, p.turn_reversal_tolerance]`, taken from the catalogue by
  its id, which observes over the window behind a turning "so as to proceed in the opposite
  direction", "whether accomplished by one continuous movement or not". The node reads spans
  s3/s5/s6 at `some_moment` of that act, so the prohibition is not of turning about anywhere but
  of turning about whose course included an observation, with the act under way, at which the
  place conditions held together: `.not (.holdsFor .time p.turn_window v (.not (U ∧ place)))`,
  with U the `under_way` element `|kin_yaw_rate v| ≥ p.yaw_rate_floor` — the rate at which a
  tracked body counts as turning rather than holding its heading, which is what tells an
  observation inside the turning from one before it began, since the place cannot.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_407

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The roadway the subject occupies, and the crest region the distance is read to. -/
def rwV : Arg := .var "rw"
def crV : Arg := .var "cr"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCrestReach : Term := .param "p.crest_reach"
def pCurveRadiusFloor : Term := .param "p.curve_radius_floor"
def pTurnReversalTolerance : Term := .param "p.turn_reversal_tolerance"
def pTurnWindow : Term := .param "p.turn_window"
def pYawRateFloor : Term := .param "p.yaw_rate_floor"

def zeroMetres : Term := .lit Q.zero .metre

/-- The distance s6 states, in the Units constructor of its unit. -/
def fiveHundredFeet : Term := .lit (Units.feet 500) .metre

/-- Class of `v`: ru.aggregate=vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "vehicle"] []

/-- s3: upon any curve — the roadway's curvature at the subject's place, at or above the
    reciprocal of the radius floor (`|κ| ≥ 1 / R`, multiplied through by `R · R`). -/
def uponACurve : Formula :=
  .cmp (.mul (.abs (.measure "st_curvature" [rwV])) (.mul pCurveRadiusFloor pCurveRadiusFloor))
    .ge pCurveRadiusFloor

/-- s5: upon the approach to or near the crest of a grade — the ground distance from the
    subject's body outline to a crest region, at or below the reach. -/
def nearACrest : Formula :=
  .existsRegion (.lit "crest") "cr"
    (.cmp (.measure "st_region_geometry_distance" [vV, crV]) .le pCrestReach)

/-- s6: where such vehicle cannot be seen … within 500 feet — the sight distance of the place. -/
def cannotBeSeen : Formula :=
  .cmp (.measure "st_sight_distance" [rwV]) .lt fiveHundredFeet

/-- The place the duty speaks of: upon a roadway the subject occupies, a bend (s3) or a nearness
    to a crest (s5), and with it the short sight distance (s6). -/
def atSuchAPlace : Formula :=
  .existsRegion (.lit "roadway") "rw"
    (.and (.atom "rel_occupies" [vV, rwV] [])
      (.and (.or uponACurve nearACrest) cannotBeSeen))

/-- Applicability: s3 (condition): upon any curve,; s5 (condition): upon the approach to or near the crest of a grade,; s6 (condition): where such vehicle cannot be seen by the driver of any other vehicle approaching from either direction within 500 feet. -/
def applicability : Formula := atSuchAPlace

/-- s2: the act — a turning about so as to proceed in the opposite direction. -/
def turningAbout : Formula :=
  .derived "drv_motion_u_turn" [vV] [pTurnWindow, pTurnReversalTolerance]

/-- The occasion's `under_way`: the body is turning, not holding its heading. -/
def underWay : Formula :=
  .cmp (.abs (.measure "kin_yaw_rate" [vV])) .ge pYawRateFloor

/-- The place conditions held together at some observation of the window behind at which the
    turning was under way. -/
def atSuchAPlaceWhileUnderWay : Formula :=
  .not (.holdsFor .time pTurnWindow "v" (.not (.and underWay atSuchAPlace)))

/-- Obligation: s2 (obligation): shall not be turned so as to proceed in the opposite direction -/
def obligation : Formula := .not (.and turningAbout atSuchAPlaceWhileUnderWay)

def rule : Rule :=
  { id := "NRS_484B_407"
    laws := ["NRS-484B-407"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_407
