/-
  NRS_484B_257_1_o2 — NRS-484B-257-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal
    s2 (trigger): When proper signs have been erected
    s3 (subject): the driver of a vehicle
    s4 (sibling): shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection
    s5 (sibling): where the driver has a view of approaching traffic on the through highway
    s6 (condition): After having stopped or, in the event of a yield sign, slowed or stopped
    s7 (obligation): the driver shall yield the right-of-way to other vehicles which have entered the intersection from such through highway
    s8 (standard): or which are approaching so closely on such through highway as to constitute an immediate hazard
    s9 (condition): during the time such driver is moving across or within the intersection

  Elements (span → atoms, derived):
    s1: atoms ['dev.human_direction', 'dev.traffic_signal', 'dev.inoperative', 'dev.governs', 'st.intersection', 'st.lane', 'st.lane_enters', 'st.reserved_lane', 'st.turn_lane', 'st.centre_turn_lane', 'st.bicycle_lane_or_path', 'st.roadway', 'st.one_way_roadway', 'st.shoulder', 'rel.occupies'], derived []
    s2: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.intersection', 'st.lane', 'st.lane_enters', 'st.reserved_lane', 'st.turn_lane', 'st.centre_turn_lane', 'st.bicycle_lane_or_path', 'st.roadway', 'st.one_way_roadway', 'st.shoulder', 'rel.occupies'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s6: atoms ['kin.speed', 'dev.yield_sign', 'dev.governs', 'st.intersection', 'rel.occupies', 'kin.path_length'], derived ['drv.motion.ceased_movement']
    s7: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.intersection', 'rel.occupies', 'st.lane', 'st.lane_enters', 'st.reserved_lane', 'st.turn_lane', 'st.centre_turn_lane', 'st.bicycle_lane_or_path', 'st.roadway', 'st.one_way_roadway', 'st.shoulder', 'st.on_way', 'st.highway', 'rel.contact', 'prim.closest_approach_within', 'prim.closest_approach_distance'], derived []
    s9: atoms ['rel.occupies', 'st.intersection', 'kin.speed'], derived []

  How each span is written:

    The junction and the approach the duty is read of are two quantified regions: `i`, an
    intersection region (st.intersection), and `a`, a travel region of one of the eight kinds
    dev.governs' contract names — st.lane, st.reserved_lane, st.turn_lane, st.centre_turn_lane,
    st.bicycle_lane_or_path, st.roadway, st.one_way_roadway, st.shoulder. The language quantifies
    over the regions of one named kind, so "a travel region of any of those kinds" is the
    disjunction of eight `existsRegion` (`existsTravelRegion`). `a` runs into `i`
    (st.lane_enters, `enters a i`), which is what ties the approach to this junction, and
    rel.occupies anchors the subject's own presence on it.

    Because each of those loops is written out eight times, every conjunct that does not depend on
    the region it binds is placed outside it — `¬(A ∨ B ∨ C)` is `¬A ∧ ¬B ∧ ¬C`, and a conjunct
    free of the bound variable moves out of an `exists` unchanged. The formulas below are therefore
    factored, not shortened: the exception's three routes are tested once each at the level the
    region they name is bound, and the vehicles of the through highway are found by binding the way
    `w` once and the two approaches `a` and `b` beside each other under it, rather than nesting one
    eight-fold loop inside the other.

    s3 — `clsV`, the binder's class: `ru_aggregate v "DEF-NRS-484A-320::vehicle"`, the admitted
      aggregate id and nothing else, never the classes it covers. "The driver of" is read through
      the vehicle's controlled motion, as the record's observable reading states; the motion itself
      is read on s9.

    s1 — the exception, conjoined into the applicability as the negation of each of the three
      routes of dev.governs the record names, for each of the two devices:
      · `officerOnOccupied` / `signalOnOccupied` — the device governs a travel region of those
        kinds the subject's footprint overlaps at the observation (`existsTravelRegion` with
        rel.occupies of the subject as the anchor). These name no junction and no approach, so they
        stand at the top of the applicability.
      · `officerGoverns i` / `signalGoverns i` — the device governs the junction region. These name
        no approach, so they stand under the binding of `i`.
      · `officerGoverns a` / `signalGoverns a` — the device governs the approach region, under the
        binding of `a`.
      A person directing traffic counts where dev_human_direction_role is `police_officer`; a
      signal head only where it is `displaying` — dev_traffic_signal_uncovered holds of it,
      dev.inoperative does not, and it does not show `dark` (dev_traffic_signal_shows). A head whose
      uncovered attribute is false shows no face to this traffic, so the conjunction is false
      whatever the source says of its other two attributes. A device at another junction, or one
      over a region the subject is neither on nor came in on, controls no traffic here.

    s2 — `stopOrYieldSign i a`: a dev.stop_sign or a dev.yield_sign that governs the approach
      region `a` or the junction region `i` (`deviceFaces`). The two routes are the record's, and
      the travel-region route of s1 is not among them: whether signs "have been erected" is asked
      of the entrance this approach makes to this junction.

    s9 — `crossingJunction i`: rel.occupies of the intersection region by the subject, with
      kin.speed standing clear of p.speed_resolution, so the duty is judged at the observations at
      which the subject is in the junction and moving. The comparison is inclusive at the
      resolution's magnitude, as that parameter's convention carries.

    s6 — `priorConduct i a`: at some observation of the stretch of path behind — the record's
      "after" read over p.stop_approach_lookback of path travelled, which kin.path_length measures
      (`someMomentBack .path`, the negation of a `holdsFor` over the window, which is how the
      language says "at some observation in the window behind") — the subject's footprint
      overlapped no intersection region (`clearOfJunctions`, rel.occupies of every st.intersection
      region false) and it either was halted (drv.motion.ceased_movement at
      p.halt_speed_tolerance) or, where a yield sign faces its traffic in the sense s2 reads, had
      its kin.speed at or below p.yield_approach_speed. The whole limb is read inside the window,
      at the observation of the conduct, and the yield sign's routes are s2's own, so the limb and
      the trigger cannot come apart.

    s7 — the obligation. It is judged at the junction s9 places the subject in
      (`crossingJunction i`) and of every other road user `l` (`.same` excludes the subject) of the
      same admitted aggregate (ru.aggregate) that `owedRightOfWay i l` qualifies: there is a
      highway region `w` (st.highway) such that some approach `a` of the subject's — a travel
      region running into `i` (st.lane_enters) its footprint overlaps or overlapped on the path
      behind — does not lie on `w` (st.on_way), and some travel region `b` running into `i` does
      lie on `w` and carries `l`'s footprint at the observation or at some observation within
      p.stop_approach_window of time behind (`cameOn`, rel.occupies); and `l` either has entered
      that intersection — rel.occupies of `i` at the observation or at some observation of that
      window behind (`hasEntered`), so that a vehicle which has traversed the junction is still
      owed the right-of-way — or is an immediate hazard in the sense of s8. "Shall yield the
      right-of-way to" is `yieldsTo l`: the subject is not in contact with it (rel.contact) and
      does not take its precedence — the centres do not approach, within p.yield_horizon under
      constant velocities, to below p.yield_clearance, which prim.closest_approach_within and
      prim.closest_approach_distance compute. Each primitive's distance is read only where the same
      primitive's `within` holds, so a pair whose centres do not approach within the horizon leaves
      the limb false and not undefined.

      The obligation does not restate the trigger's exception or the halt: the applicability
      decides whether the duty arises, and the verdict is read from the obligation only at the
      instants at which it does. `crossingJunction i` pins the junction to the one the subject is
      in, which is the junction the applicability was engaged at, and the exception's
      occupied-region route is a conjunct of the applicability itself, so testing either again
      under the eight-fold loops would decide nothing it has not already decided. What the
      obligation does carry of the engagement is the signed approach, because the way `a` lies on
      is what makes the other way the through one.

    s8 — the operationalization, written as the gap-acceptance convention the node states:
      `immediateHazard l` is prim.closest_approach_within of the subject and `l` at
      p.hazard_horizon with prim.closest_approach_distance at or below p.hazard_clearance. Its "on
      such through highway" is the same `b` the obligation quantifies, so both limbs of the duty
      read the one way-and-approach test; both the closeness and the speed of the approach enter
      the bound through the closest approach.

  Readings I chose, declared in `narrowings`: none. The record's elements, its operationalization,
  its applicability and obligation and its own narrowings fix every choice this file makes — the
  atoms of each span, the eight region kinds, the two device routes of the trigger and the three of
  the exception, the measure of each window and the parameter it takes, the inclusive and strict
  boundaries of the two clearances, and that a contact is a breach however the centres move. The
  factoring described above is a rearrangement of those conjuncts, not a reading of any span.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The quantifier variables: the junction the duty is owed at, an approach of the subject's to it,
    an approach of the through highway, the way that approach lies on, another road user, a travel
    region the subject's footprint overlaps, an intersection region the subject must be clear of,
    and a control device. -/
def iV : Arg := .var "i"
def aV : Arg := .var "a"
def bV : Arg := .var "b"
def wV : Arg := .var "w"
def lV : Arg := .var "l"
def rV : Arg := .var "r"
def jV : Arg := .var "j"
def dV : Arg := .var "d"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pHazardClearance : Term := .param "p.hazard_clearance"
def pHazardHorizon : Term := .param "p.hazard_horizon"
def pSpeedResolution : Term := .param "p.speed_resolution"
def pStopApproachLookback : Term := .param "p.stop_approach_lookback"
def pStopApproachWindow : Term := .param "p.stop_approach_window"
def pYieldApproachSpeed : Term := .param "p.yield_approach_speed"
def pYieldClearance : Term := .param "p.yield_clearance"
def pYieldHorizon : Term := .param "p.yield_horizon"

-- ---------------------------------------------------------------------------------------------
-- The travel regions a way's traffic is carried by
-- ---------------------------------------------------------------------------------------------

/-- A disjunction of a non-empty list of formulas. -/
def orAll : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: ψ :: rest => .or φ (orAll (ψ :: rest))

/-- A conjunction of a non-empty list of formulas. -/
def andAll : List Formula → Formula
  | [] => .tt
  | [φ] => φ
  | φ :: ψ :: rest => .and φ (andAll (ψ :: rest))

/-- The kinds of travel region dev.governs' contract names: "a lane, reserved lane, turn lane,
    centre turn lane, bicycle lane or path, roadway, one-way roadway or shoulder". -/
def travelKinds : List String :=
  ["lane", "reserved_lane", "turn_lane", "centre_turn_lane", "bicycle_lane_or_path", "roadway",
   "one_way_roadway", "shoulder"]

/-- Some travel region of any of those kinds satisfies `φ`. -/
def existsTravelRegion (v : String) (φ : Formula) : Formula :=
  orAll (travelKinds.map fun k => .existsRegion (.lit k) v φ)

-- ---------------------------------------------------------------------------------------------
-- The leaves the spans share
-- ---------------------------------------------------------------------------------------------

/-- Membership of the admitted aggregate the text's "vehicle" is read as. -/
def vehicleOf (x : Arg) : Formula :=
  .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []

/-- A road user's footprint overlaps a region. -/
def occupies (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []

/-- The travel region `r` runs into the intersection region `i` at its end. -/
def enters (r i : Arg) : Formula := .atom "st_lane_enters" [r, i] []

/-- The device `d` controls the traffic of the region `r`. -/
def governs (d r : Arg) : Formula := .atom "dev_governs" [d, r] []

/-- The region `r` lies on the public way `w`. -/
def onWay (r w : Arg) : Formula := .atom "st_on_way" [r, w] []

/-- The magnitude of a road user's velocity. -/
def speedOf (x : Arg) : Term := .measure "kin_speed" [x]

/-- `φ` at some observation of the window of length `d` behind, measured in `m`. -/
def someMomentBack (m : Measure) (d : Term) (φ : Formula) : Formula :=
  .not (.holdsFor m d "v" (.not φ))

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := vehicleOf vV

-- ---------------------------------------------------------------------------------------------
-- s2 (trigger): the signs erected for the traffic this approach carries into this junction
-- ---------------------------------------------------------------------------------------------

/-- s2: a device of the kind faces the traffic the approach `a` carries into `i` — it governs that
    approach, or it governs that junction. -/
def deviceFaces (kind : String) (i a : Arg) : Formula :=
  .existsDevice (.lit kind) "d" (.or (governs dV a) (governs dV i))

/-- s2: a stop sign or a yield sign has been erected facing that traffic. -/
def stopOrYieldSign (i a : Arg) : Formula :=
  .or (deviceFaces "stop_sign" i a) (deviceFaces "yield_sign" i a)

/-- s6: a yield sign faces that traffic, in the sense s2 reads. -/
def yieldSignFaces (i a : Arg) : Formula := deviceFaces "yield_sign" i a

-- ---------------------------------------------------------------------------------------------
-- s1 (exception): traffic controlled by a police officer or a traffic-control signal
-- ---------------------------------------------------------------------------------------------

/-- s1: the head is displaying an indication — installed uncovered, not inoperative, and not
    showing `dark`. -/
def displaying : Formula :=
  .and (.atom "dev_traffic_signal_uncovered" [dV] [])
    (.and (.not (.atom "dev_inoperative" [dV] []))
          (.not (.atom "dev_traffic_signal_shows" [dV, .lit "dark"] [])))

/-- s1: the device `d` governs a travel region the subject's footprint overlaps. -/
def onGovernedTravelRegion : Formula :=
  existsTravelRegion "r" (.and (occupies vV rV) (governs dV rV))

/-- s1: a person directing traffic whose role is police officer governs the region `r`. -/
def officerGoverns (r : Arg) : Formula :=
  .existsDevice (.lit "human_direction") "d"
    (.and (.atom "dev_human_direction_role" [dV, .lit "police_officer"] []) (governs dV r))

/-- s1: a signal head displaying an indication governs the region `r`. -/
def signalGoverns (r : Arg) : Formula :=
  .existsDevice (.lit "traffic_signal") "d" (.and displaying (governs dV r))

/-- s1: a police officer governs a travel region the subject's footprint overlaps. -/
def officerOnOccupied : Formula :=
  .existsDevice (.lit "human_direction") "d"
    (.and (.atom "dev_human_direction_role" [dV, .lit "police_officer"] [])
          onGovernedTravelRegion)

/-- s1: a displaying signal head governs a travel region the subject's footprint overlaps. -/
def signalOnOccupied : Formula :=
  .existsDevice (.lit "traffic_signal") "d" (.and displaying onGovernedTravelRegion)

-- ---------------------------------------------------------------------------------------------
-- s9 (condition) and the approach: the subject's own traffic and its passage of the junction
-- ---------------------------------------------------------------------------------------------

/-- s2/s1: the subject's traffic is the traffic the approach `a` carries — its footprint overlaps
    `a` at the observation, or overlapped it at some observation of the path behind. -/
def onApproach (a : Arg) : Formula :=
  .or (occupies vV a) (someMomentBack .path pStopApproachLookback (occupies vV a))

/-- s9: the subject is moving across or within the intersection region `i`. -/
def crossingJunction (i : Arg) : Formula :=
  .and (occupies vV i) (.cmp (speedOf vV) .ge pSpeedResolution)

-- ---------------------------------------------------------------------------------------------
-- s6 (condition): after having stopped, or slowed or stopped for a yield sign
-- ---------------------------------------------------------------------------------------------

/-- s6: the subject's footprint overlaps no intersection region. -/
def clearOfJunctions : Formula :=
  .forallRegion (.lit "intersection") "j" (.not (occupies vV jV))

/-- s6: the subject is not moving — "complete cessation from movement" as the concept observes it. -/
def halted : Formula := .derived "drv_motion_ceased_movement" [vV] [pHaltSpeedTolerance]

/-- s6: at some observation of the stretch of path behind, its footprint overlapping no
    intersection region, the subject was halted or, in the event of a yield sign, had slowed to the
    yield-approach speed. -/
def priorConduct (i a : Arg) : Formula :=
  someMomentBack .path pStopApproachLookback
    (andAll
      [ clearOfJunctions
      , .or halted (.and (yieldSignFaces i a) (.cmp (speedOf vV) .le pYieldApproachSpeed)) ])

-- ---------------------------------------------------------------------------------------------
-- s7 (obligation) and s8 (standard): the vehicles of the through highway, and yielding to them
-- ---------------------------------------------------------------------------------------------

/-- s7: `x`'s footprint overlaps the region `r` at the observation or at some observation of the
    window of time behind. -/
def cameOn (x r : Arg) : Formula :=
  .or (occupies x r) (someMomentBack .time pStopApproachWindow (occupies x r))

/-- s8: `x` is approaching so closely as to constitute an immediate hazard — the centres approach
    within the hazard horizon to at most the hazard clearance. -/
def immediateHazard (x : Arg) : Formula :=
  .and (.derived "prim_closest_approach_within" [vV, x] [pHazardHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vV, x] [pHazardHorizon])
             .le pHazardClearance)

/-- s7: the subject takes `x`'s precedence — the centres approach, within the conflict horizon, to
    below the gap-acceptance clearance. -/
def takesPrecedence (x : Arg) : Formula :=
  .and (.derived "prim_closest_approach_within" [vV, x] [pYieldHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vV, x] [pYieldHorizon])
             .lt pYieldClearance)

/-- s7: the subject yields the right-of-way to `x` — no contact, and no taking of its precedence. -/
def yieldsTo (x : Arg) : Formula :=
  .and (.not (.atom "rel_contact" [vV, x] [])) (.not (takesPrecedence x))

/-- s7: an approach of the subject's to the junction `i` that does not lie on the way `w`. -/
def ownApproachOffWay (i w : Arg) : Formula :=
  existsTravelRegion "a"
    (andAll [ enters aV i, onApproach aV, stopOrYieldSign i aV, .not (onWay aV w) ])

/-- s7: an approach of the way `w` into the junction `i` that `x` came to `i` on. -/
def throughApproachOf (i w x : Arg) : Formula :=
  existsTravelRegion "b" (andAll [ enters bV i, onWay bV w, cameOn x bV ])

/-- s7: `x` has entered the intersection `i` — its footprint overlaps it at the observation or did
    at some observation of the window of time behind. -/
def hasEntered (x i : Arg) : Formula := cameOn x i

/-- s7, s8: `x` is another vehicle owed the right-of-way at the junction `i`: it came to it on a
    way the subject's signed approach does not lie on, and it has entered the junction or is an
    immediate hazard. -/
def owedRightOfWay (i x : Arg) : Formula :=
  andAll
    [ .not (.same x vV)
    , vehicleOf x
    , .existsRegion (.lit "highway") "w"
        (.and (ownApproachOffWay i wV) (throughApproachOf i wV x))
    , .or (hasEntered x i) (immediateHazard x) ]

-- ---------------------------------------------------------------------------------------------
-- The rule
-- ---------------------------------------------------------------------------------------------

/-- Applicability: s1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal; s2 (trigger): When proper signs have been erected; s6 (condition): After having stopped or, in the event of a yield sign, slowed or stopped; s9 (condition): during the time such driver is moving across or within the intersection -/
def applicability : Formula :=
  andAll
    [ .not officerOnOccupied
    , .not signalOnOccupied
    , .existsRegion (.lit "intersection") "i"
        (andAll
          [ crossingJunction iV
          , .not (officerGoverns iV)
          , .not (signalGoverns iV)
          , existsTravelRegion "a"
              (andAll
                [ enters aV iV
                , onApproach aV
                , stopOrYieldSign iV aV
                , .not (officerGoverns aV)
                , .not (signalGoverns aV)
                , priorConduct iV aV ]) ]) ]

/-- Obligation: s7 (obligation): the driver shall yield the right-of-way to other vehicles which have entered the intersection from such through highway; s8 (standard): or which are approaching so closely on such through highway as to constitute an immediate hazard -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies (crossingJunction iV)
      (.forallUser "l" (.implies (owedRightOfWay iV lV) (yieldsTo lV))))

def rule : Rule :=
  { id := "NRS_484B_257_1_o2"
    laws := ["NRS-484B-257-1"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations :=
      [ { standard := "or which are approaching so closely on such through highway as to constitute an immediate hazard"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within", "rel.occupies", "st.bicycle_lane_or_path", "st.centre_turn_lane", "st.highway", "st.intersection", "st.lane", "st.lane_enters", "st.on_way", "st.one_way_roadway", "st.reserved_lane", "st.roadway", "st.shoulder", "st.turn_lane"]
          params := ["p.hazard_horizon", "p.hazard_clearance"]
          convention := "Gap-acceptance convention for an immediate hazard: a vehicle on the intersecting way is so close as to be an immediate hazard where, under constant velocities, the centres of the two bodies approach within p.hazard_horizon - 'the time ahead within which an approaching vehicle's arrival makes it an immediate hazard to a vehicle crossing the junction' - to a centre distance at or below p.hazard_clearance, which prim.closest_approach_within and prim.closest_approach_distance compute. 'on such through highway' is read as that vehicle's footprint overlapping a travel region which runs into the junction (st.lane_enters, rel.occupies as the anchor) and which lies (st.on_way) on a way (st.highway) other than the one the subject's approach lies on; the travel region is of any kind a way's travel regions are carried by - st.lane, st.reserved_lane, st.turn_lane, st.centre_turn_lane, st.bicycle_lane_or_path, st.roadway, st.one_way_roadway, st.shoulder - since the certified situation carried the approach of a through-highway vehicle as a reserved lane. Both the closeness and the speed of the approach enter the bound as measured magnitudes through the closest approach, so the standard moves as the approaching vehicle's distance and speed move."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- the record's elements, operationalization, applicability and obligation fix every choice; none is this session's
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_1_o2
