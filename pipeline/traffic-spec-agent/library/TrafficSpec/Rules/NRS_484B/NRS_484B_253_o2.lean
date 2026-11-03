/-
  NRS_484B_253_o2 — NRS-484B-253

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): The driver of a vehicle
    s2 (condition): within an intersection
    s3 (condition): intending to turn to the left
    s4 (sibling): shall yield the right-of-way
    s5 (sibling): to any vehicle approaching from the opposite direction
    s6 (sibling): which is within the intersection
    s7 (sibling): or so close thereto as to constitute an immediate hazard,
    s8a (standard): but such driver, having so yielded
    s8b (standard): and having given a signal when and as required,
    s8c (condition): may make such left turn
    s9a (subject): and the drivers of all other vehicles approaching the intersection from the opposite direction
    s9b (obligation): shall yield the right-of-way to the vehicle making the left turn.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.velocity'], derived []
    s2: atoms ['rel.occupies', 'st.intersection'], derived []
    s8c: atoms [], derived ['drv.motion.leftward_course_change']
    s9a: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.velocity', 'rel.occupies', 'st.travel_region', 'st.lane_enters', 'st.lane_direction', 'st.intersection'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  HOW EACH SPAN IS WRITTEN (this session's record)

    s1 "the driver of a vehicle" — the turning party, quantified inside the applicability
      (`existsUser "w"`), never a binder: `ru_aggregate w DEF-NRS-484A-320::vehicle` for the class
      and `kin_velocity` for the plan's agency reading — the vehicle's own controlled motion is
      read as its velocity vector being observed (`|vx| + |vy| ≥ 0`, true where the vector is
      there, unknown where the source did not observe it). `.not (.same v w)` keeps the subject
      out, as "all other vehicles" requires.
    s2 "within an intersection" — `existsRegion "intersection" "i"`, `st_intersection i` and
      `rel_occupies w i`. This is the one junction every later condition reads.
    s3 "intending to turn to the left" — the declared intention `int.turn_left` of `w` at `i`,
      read at the judged observation.
    s8c "may make such left turn" — `drv.motion.leftward_course_change` on `w` with
      p.turn_left_heading_change_min over p.turn_window, read at the observation itself (not at
      its rise): the concept holds from the observation at which the accumulated change reaches
      the bound through the later observations of its window, which is the turn being made.
    s9a "all other vehicles approaching the intersection from the opposite direction" — the
      subject's approach is a carrier (`st_travel_region`) whose entrance end is that junction
      (`st_lane_enters`) which it occupies (`rel_occupies`): read at the judged observation, or,
      where the subject has itself come to be within the junction, at the last observation before
      it did, which `.since (occupies x i) (occupies x c ∧ ¬occupies x i)` states with no window
      at all. Opposition is the two carriers' designated directions (`st_lane_direction`) with
      their dot product at most −p.opposed_direction_cos_min; the current headings are never read,
      since the turning vehicle's heading rotates through its turn.
    s8a "having so yielded" — the first clause's yield, carried in full: at every observation of
      the window behind at which `w` had not yet turned its course and occupied that junction,
      every other vehicle then approaching that junction from the direction opposite `w`'s own
      approach and either within the junction (`rel_occupies`), or within its measured speed
      (`kin_speed`) times p.immediate_hazard_arrival_max of it (`st_region_geometry` distance), or
      converging to a closest approach within p.yield_conflict_horizon below p.yield_clearance_min,
      was granted precedence: `w` was not in motion (`drv.motion.in_motion` with
      p.motion_speed_min), or its motion left the closest approach at or above the clearance, the
      measured body gap (`rel_surface_gap`) at or above it, and the bodies untouched
      (`rel_contact`).
    s8b "having given a signal when and as required" — some observation of the window behind at
      which `w` had not yet turned its course and throughout whose own p.signal_lead_time window
      it showed the left side of its manoeuvre (`sig_turn_indicator` left or `sig_hand_signal`
      left). A signal switched off once the turn is under way does not undo one completed before.
      The standstill of s8a is read once over the whole quantification of the vehicles precedence
      was owed to rather than inside it: a vehicle at rest grants precedence to every one of them
      at once, so the two arrangements say the same thing of every trace.
    s9b "shall yield the right-of-way to the vehicle making the left turn" — the obligation binds
      the junction and the turning vehicle again with the whole selection the applicability made,
      universally (`forallRegion`/`forallUser`: the duty is owed to each vehicle making such a
      turn there), and at every observation at which that selection holds — the turn's recognition
      and every later observation of its window, not the rise alone. The duty itself is the same
      gap-acceptance and conflict-margin convention, read from the subject toward that vehicle.

  NARROWINGS DECLARED BELOW (readings this session chose; the record's own are not restated)

    s8a — the search into the past for an observation at which the turning vehicle failed to grant
      precedence is bounded by p.turn_window, the recognition window of the very turn the condition
      is about, rather than running to the start of the recording. An unbounded search into the past
      is truncated at the start of every finite trace and so is unknown there, which would leave the
      condition undecidable on any trace; the window the reading already gives the turn is the
      narrowest bound the span's own words support.
    s8b — the search for the pre-turn observation whose lead window carries the signal is bounded,
      for the same reason, by p.turn_window behind the judged observation: the recognition window of
      the very turn the signal must precede.

  Not narrowed, and stated here because the choice is visible in the formulas: the look-back for
  which carrier a vehicle approached through is confined to no window (`.since`), as the record
  requires; only the two searches above are bounded.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_253_o2

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pImmediateHazardArrivalMax : Term := .param "p.immediate_hazard_arrival_max"
def pMotionSpeedMin : Term := .param "p.motion_speed_min"
def pOpposedDirectionCosMin : Term := .param "p.opposed_direction_cos_min"
def pSignalLeadTime : Term := .param "p.signal_lead_time"
def pTurnLeftHeadingChangeMin : Term := .param "p.turn_left_heading_change_min"
def pTurnWindow : Term := .param "p.turn_window"
def pYieldClearanceMin : Term := .param "p.yield_clearance_min"
def pYieldConflictHorizon : Term := .param "p.yield_conflict_horizon"

def zeroMetres : Term := .lit Q.zero .metre
def zeroSpeed : Term := .lit Q.zero .metrePerSecond

/-- The variables the formulas quantify: the turning vehicle, the junction, the two approach
    carriers, a vehicle the turning vehicle owed precedence to and its carrier. -/
def wV : Arg := .var "w"
def iV : Arg := .var "i"
def cwV : Arg := .var "cw"
def cvV : Arg := .var "cv"
def uV : Arg := .var "u"
def cuV : Arg := .var "cu"

/-- The admitted aggregate, by its id. -/
def vehicleAggregate : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- s1 / s9a: a vehicle of the admitted aggregate. -/
def isVehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, vehicleAggregate] []

/-- s1 / s9a: "the driver of", read through the vehicle's own controlled motion — its velocity
    vector, observed here and unknown where the source did not observe it. -/
def hasControlledMotion (x : Arg) : Formula :=
  .cmp (.add (.abs (.measure "kin_velocity" [x, .lit "x"]))
             (.abs (.measure "kin_velocity" [x, .lit "y"]))) .ge zeroSpeed

/-- s2 / s9a: the body's footprint overlaps the region. -/
def occupies (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []

/-- s2: the region is the junction. -/
def isJunction (r : Arg) : Formula := .atom "st_intersection" [r] []

/-- s9a: the region is a carrier a vehicle travels in. -/
def isCarrier (c : Arg) : Formula := .atom "st_travel_region" [c] []

/-- s9a: the carrier's entrance end is that junction. -/
def entersJunction (c j : Arg) : Formula := .atom "st_lane_enters" [c, j] []

/-- s9a: a component of a carrier's designated direction. -/
def carrierDirection (c : Arg) (k : String) : Term := .measure "st_lane_direction" [c, .lit k]

/-- s9a: the two carriers' designated directions are opposed within the reading's tolerance. -/
def opposedCarriers (a b : Arg) : Formula :=
  .cmp (.add (.mul (carrierDirection a "x") (carrierDirection b "x"))
             (.mul (carrierDirection a "y") (carrierDirection b "y")))
       .le (.neg pOpposedDirectionCosMin)

/-- s9a: the carrier `x` approaches that junction through — the one it occupies here, or, where it
    has itself come to be within the junction, the one it occupied at the last observation before
    it did, a look-back confined to no window. -/
def approachesThrough (x c j : Arg) : Formula :=
  .and (isCarrier c)
    (.and (entersJunction c j)
      (.since (occupies x j) (.and (occupies x c) (.not (occupies x j)))))

/-- s8c / s9b: the road user has turned its course to the left over the window behind. -/
def turnsLeft (x : Arg) : Formula :=
  .derived "drv_motion_leftward_course_change" [x] [pTurnLeftHeadingChangeMin, pTurnWindow]

/-- s8a: the road user's body is moving at this observation. -/
def isMoving (x : Arg) : Formula := .derived "drv_motion_in_motion" [x] [pMotionSpeedMin]

/-- s8b: the left side of the manoeuvre shown, by indicator or by arm. -/
def showsLeftSignal (x : Arg) : Formula :=
  .or (.atom "sig_turn_indicator" [x, .lit "left"] [])
      (.atom "sig_hand_signal" [x, .lit "left"] [])

/-- s8b: the window behind within which the pre-turn observation is sought (see the narrowing):
    the recognition window of the very turn the signal must precede. -/
def signalSearchWindow : Term := pTurnWindow

/-- s8b: at some observation of that window the vehicle had not yet turned its course to the left
    and had shown the side of its manoeuvre throughout the lead window behind that observation. -/
def signalGiven (x : Arg) : Formula :=
  .not (.holdsFor .time signalSearchWindow "v"
         (.not (.and (.not (turnsLeft x))
                     (.holdsFor .time pSignalLeadTime "v" (showsLeftSignal x)))))

/-- s8a / s9b: `a`'s motion grants precedence to `b` — no closest approach within the reading's
    horizon below its clearance, the measured body gap at or above that clearance, no contact. -/
def grantsPrecedence (a b : Arg) : Formula :=
  .and (.not (.and (.derived "prim_closest_approach_within" [a, b] [pYieldConflictHorizon])
                   (.cmp (.quantity "prim_closest_approach_distance" [a, b] [pYieldConflictHorizon])
                         .lt pYieldClearanceMin)))
    (.and (.cmp (.measure "rel_surface_gap" [a, b]) .ge pYieldClearanceMin)
          (.not (.atom "rel_contact" [a, b] [])))

/-- s8a: `u` is a vehicle the yield of the first clause is owed to by `x`, which approached that
    junction through `cx`: another vehicle approaching that junction from the opposite direction
    and either within it, or so close to it as to be an immediate hazard, or converging with `x`
    below the clearance. -/
def owedPrecedence (x u j cx : Arg) : Formula :=
  .and (.not (.same x u))
    (.and (isVehicle u)
      (.and (.existsRegion (.lit "travel_region") "cu"
               (.and (approachesThrough u cuV j) (opposedCarriers cuV cx)))
            (.or (occupies u j)
              (.or (.cmp (.measure "st_region_geometry_distance" [u, j]) .le
                         (.mul (.measure "kin_speed" [u]) pImmediateHazardArrivalMax))
                   (.and (.derived "prim_closest_approach_within" [x, u] [pYieldConflictHorizon])
                         (.cmp (.quantity "prim_closest_approach_distance" [x, u] [pYieldConflictHorizon])
                               .lt pYieldClearanceMin))))))

/-- s8a: at this observation `x` granted precedence to every vehicle it owed it to — standing
    still is granting it, whoever the vehicle, which is why the standstill is read once over the
    whole quantification rather than inside it. -/
def grantedPrecedenceHere (x j cx : Arg) : Formula :=
  .or (.not (isMoving x))
    (.forallUser "u"
      (.implies (owedPrecedence x uV j cx) (grantsPrecedence x uV)))

/-- s8a: "having so yielded" — at every observation of the window behind at which `x` had not yet
    turned its course and occupied that junction, it granted precedence. -/
def yieldedBeforeTurn (x j cx : Arg) : Formula :=
  .holdsFor .time pTurnWindow "v"
    (.implies (.and (.not (turnsLeft x)) (occupies x j))
              (grantedPrecedenceHere x j cx))

/-- The whole selection of the junction and of the vehicle making its left turn there: s1, s2, s3,
    s8a, s8b, s8c and the approach of s9a. -/
def turningVehicleAt (j : Arg) : Formula :=
  .and (.not (.same vV wV))
    (.and (isVehicle wV)
      (.and (hasControlledMotion wV)
        (.and (occupies wV j)
          (.and (.intent "int.turn_left" wV j)
            (.and (turnsLeft wV)
              (.and (signalGiven wV)
                (.existsRegion (.lit "travel_region") "cw"
                  (.and (approachesThrough wV cwV j)
                    (.and (yieldedBeforeTurn wV j cwV)
                      (.existsRegion (.lit "travel_region") "cv"
                        (.and (approachesThrough vV cvV j)
                              (opposedCarriers cvV cwV))))))))))))

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle, kin.velocity -/
def clsV : Formula := .and (isVehicle vV) (hasControlledMotion vV)

/-- Applicability: s1 (condition): The driver of a vehicle; s2 (condition): within an intersection; s3 (condition): intending to turn to the left; s8c (condition): may make such left turn -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (isJunction iV) (.existsUser "w" (turningVehicleAt iV)))

/-- Obligation: s8a (standard): but such driver, having so yielded; s8b (standard): and having given a signal when and as required,; s9b (obligation): shall yield the right-of-way to the vehicle making the left turn. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallUser "w"
      (.implies (.and (isJunction iV) (turningVehicleAt iV))
                (grantsPrecedence vV wV)))

def rule : Rule :=
  { id := "NRS_484B_253_o2"
    laws := ["NRS-484B-253"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.turn_left"]
    operationalizations :=
      [ { standard := "“having so yielded”: the condition refers back to the yield the first clause of this section requires of the turning driver, and that yield carries the standard of DEF-NRS-484A-210 — precedence owed to a vehicle “approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash”. The referent is carried in full, with every qualification the referring words retain: the same party (the turning vehicle), the same object (opposing vehicles within that junction or so close to it as to be an immediate hazard), the same place, and an order that puts the yield before the turn."
          concepts := ["drv.motion.in_motion", "drv.motion.leftward_course_change", "kin.speed", "kin.velocity", "prim.closest_approach_distance", "prim.closest_approach_within", "rel.contact", "rel.occupies", "rel.surface_gap", "st.intersection", "st.lane_direction", "st.lane_enters", "st.region_geometry", "st.travel_region"]
          params := ["p.yield_conflict_horizon", "p.yield_clearance_min", "p.immediate_hazard_arrival_max", "p.opposed_direction_cos_min", "p.motion_speed_min", "p.turn_left_heading_change_min", "p.turn_window"]
          convention := "The same gap-acceptance and conflict-margin convention as the yield of the first clause, read over the observations before the rise of the turning vehicle's left course change (drv.motion.leftward_course_change with p.turn_left_heading_change_min over p.turn_window) at which it occupied that junction (rel.occupies, st.intersection). At each of them, for every other vehicle then approaching that junction from the direction opposite the turning vehicle's own approach (a carrier of kind st.travel_region whose entrance end is that junction by st.lane_enters, its designated direction st.lane_direction opposed within p.opposed_direction_cos_min) and either within that junction (rel.occupies) or at a body-to-region distance (st.region_geometry) at most its measured speed (kin.speed) times p.immediate_hazard_arrival_max or converging under the two current velocities (kin.velocity) to a closest approach within p.yield_conflict_horizon below p.yield_clearance_min, the turning vehicle must have granted precedence: either it was not in motion (drv.motion.in_motion with p.motion_speed_min — a vehicle standing still grants precedence by standing still, and a contact another road user brings about while it stands is no failure of its own to yield), or its motion did not bring the two bodies, under their current velocities, to a closest approach within p.yield_conflict_horizon (prim.closest_approach_within) below p.yield_clearance_min (prim.closest_approach_distance), left the measured body gap (rel.surface_gap) at or above that clearance, and did not touch (rel.contact). A weaker fact — that it merely slowed, or that no conflict happened to occur — is no substitute, and composing the node of the first clause would not do: a composed rule counts as complied with where it is not engaged, and that would let a turning vehicle to which the first clause never applied satisfy this condition."
          surrogate := false }
      , { standard := "“having given a signal when and as required”: the section does not say which signal, how long before or by what means, and the requiring provision is not a line of this corpus, so when and as required is a standard of judgement here."
          concepts := ["drv.motion.leftward_course_change", "sig.hand_signal", "sig.turn_indicator"]
          params := ["p.signal_lead_time", "p.turn_left_heading_change_min", "p.turn_window"]
          convention := "Signal-lead convention. “Having given” is a perfect: the signal is required before the turn and is given once it has been shown for the lead time. The condition holds where there is an observation at or before the judged one at which the turning vehicle had not yet turned its course to the left (drv.motion.leftward_course_change with p.turn_left_heading_change_min over p.turn_window does not hold for it there) and throughout the window of length p.signal_lead_time behind that observation it showed the side of its manoeuvre: its turn indicator in the left state (sig.turn_indicator, “the turn indicator state ∈ {off, left, right}”, which is “not a stand-in for: the turn or lane change itself”, judged here separately from the turn), or the driver's arm signal meaning left (sig.hand_signal, “a driver's or rider's arm signal; meaning ∈ {no_signal, left, right, stop_or_slow, re_enter}”). Either means satisfies the condition, as the law's “when and as required” leaves the means to the requiring provision; the lead time is the one signal-lead practice sets for a turn. A signal switched off once the turn is under way does not undo a signal already completed before it, and a vehicle that showed no such signal at any observation before its turn has not given one."
          surrogate := false }
      , { standard := "“shall yield the right-of-way to the vehicle making the left turn”: DEF-NRS-484A-210 defines right-of-way as “the right of one vehicle or pedestrian to proceed in a lawful manner in preference to another vehicle or pedestrian approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other”, so the duty — grant precedence to the turning vehicle — is concrete, while “the danger of a crash” arising from direction, speed and proximity is the standard. The party it is owed to is identified in the span's own words as the vehicle making the left turn."
          concepts := ["drv.motion.leftward_course_change", "kin.speed", "kin.velocity", "prim.closest_approach_distance", "prim.closest_approach_within", "rel.contact", "rel.occupies", "rel.surface_gap", "st.intersection"]
          params := ["p.yield_conflict_horizon", "p.yield_clearance_min", "p.turn_left_heading_change_min", "p.turn_window"]
          convention := "Gap-acceptance and conflict-margin convention, read toward “the vehicle making the left turn”: the road user whose footprint overlaps that junction (rel.occupies, st.intersection) and whose course has turned to the left over the window behind (drv.motion.leftward_course_change with p.turn_left_heading_change_min over p.turn_window — the concept is not a stand-in for a signal, a lane change or the place of the turn, which the node's own atoms carry). The words name a turn under way, not the instant at which it is recognized, so the duty is owed at every observation at which that concept holds for the vehicle and its footprint overlaps the junction — the observation at which its accumulated change first reaches the bound and each later observation of the window over which it still does — and not at that first observation alone. At each of them the subject's motion must not bring the two bodies, under their current velocities (kin.velocity), to a closest approach occurring within p.yield_conflict_horizon (prim.closest_approach_within) at a distance (prim.closest_approach_distance) below p.yield_clearance_min; the measured body gap (rel.surface_gap) must stay at or above that clearance and the bodies must not touch (rel.contact). Direction, speed and proximity enter the bound by degree, the closest approach being computed from both velocity vectors and the subject's own speed (kin.speed) entering through them."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s8a"
          why := "The search into the past for an observation at which the turning vehicle, not yet having turned its course and occupying that junction, failed to grant precedence is bounded by p.turn_window — the recognition window of the very turn this condition is about — rather than running to the start of the recording. A search into the past with no bound is truncated at the start of every finite trace and is unknown there, so the condition would never be decided; the window the reading already gives the turn is the narrowest bound the span's words support. Every qualification of the referred yield is otherwise carried in full: the same party, the same object, the same place, and the order that puts the yield before the turn."
          kind := "reading" }
      , { span := "s8b"
          why := "The search for the observation at or before the judged one at which the vehicle had not yet turned its course, and throughout whose own lead window it showed the side of its manoeuvre, is bounded by p.turn_window behind the judged observation — the recognition window of the very turn the signal must precede — rather than running to the start of the recording, for the same reason: an unbounded search into the past is unknown on every finite trace. Which means satisfies the condition is left open, as the words leave it to the requiring provision."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_253_o2
