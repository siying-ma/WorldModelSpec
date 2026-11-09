/-
  NRS_484B_257_2_o2 — NRS-484B-257-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:
    s1 (subject): The driver of a vehicle
    sib1 (sibling): shall stop in obedience to a stop sign or yield in compliance with a yield sign, in compliance with the manner prescribed in subsection 1 [NRS-484B-257-1], prior to entering an intersection
    c1 (condition): if a stop sign or a yield sign is erected at one or more entrances thereto
    c2 (condition): although not a part of a through highway
    st1 (standard): and shall proceed cautiously,
    ob1 (obligation): yielding to vehicles not so obligated to stop or yield and which are within the intersection
    st2 (standard): or approaching so closely as to constitute an immediate hazard
    c3 (condition): during the time such driver is moving across or within the intersection.

  Elements (span → atoms, derived):
    e1: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.human_direction', 'dev.traffic_signal', 'dev.governs', 'rel.occupies', 'st.travel_region', 'st.lane_enters', 'st.intersection'], derived []
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    c1: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.travel_region', 'st.lane_enters', 'st.intersection', 'rel.occupies'], derived []
    ob1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'rel.occupies', 'st.travel_region', 'st.lane_enters', 'st.intersection', 'rel.surface_gap', 'rel.contact', 'kin.speed', 'prim.closest_approach_within', 'prim.closest_approach_distance'], derived []
    c3: atoms ['rel.occupies', 'st.intersection', 'kin.speed'], derived []

  How each span is written
  ------------------------
  s1 — `clsV`: the binder's class is the single admitted aggregate, `ru_aggregate v
  "DEF-NRS-484A-320::vehicle"`. The driver is read through the vehicle's controlled motion, as the
  record's observable reading says; nothing is restated here.

  c1 — `signErectedAtAnEntrance`: a travel region `c` other than the junction itself whose entrance
  end is the junction `j` (`st_lane_enters c j`) that a stop sign or a yield sign governs
  (`dev_governs` under a quantifier over devices of kind `stop_sign` / `yield_sign`). "One or more
  entrances thereto" is the existential: any entrance of that junction, not only the subject's own.
  The sign's presence on the road is its erection (the record's observable reading). That the
  junction is not among its own entrances is the `st.lane_enters` contract's own content — a carrier
  runs into the intersection at its entrance end, and no junction is an approach to itself — not a
  reading chosen here.

  c3 — the junction region of kind `intersection` the subject's footprint overlaps
  (`rel_occupies v j`), with its speed above `p.standstill_speed_tolerance` for "is moving across or
  within". Both are read again in the obligation's guard, so that the duty speaks of the same
  junction and only while the subject is moving in it (Core evaluates the two formulas separately).

  e1 — `trafficControlled`: a road user `w` of the aggregate `DEF-NRS-484A-285::traffic` whose
  footprint overlaps that junction, where a travel region `cc` that is the junction itself
  (`same cc j`) or an approach carrier of it the subject occupies
  (`st_lane_enters cc j` and `rel_occupies v cc`) is governed by a device of kind `human_direction`
  with role `police_officer`, or by a device of kind `traffic_signal`. Both limbs of the record's
  reading ("the junction the subject is at or on its own approach carrier") are carried; the
  exception is negated into the applicability as a whole.

  st1 — `cautiously`: the subject's speed at or below `p.cautious_proceed_max_speed`, read at every
  observation at which the guard holds.

  ob1 / st2 — `owedPrecedence` and `grantsPrecedence`: for every road user `u` other than the
  subject that is of the aggregate `DEF-NRS-484A-320::vehicle` and is not itself obligated
  (`notObligated`: some approach carrier of that junction it occupies that no stop sign and no yield
  sign governs), and which either lies within the junction (`rel_occupies u j`) or is an immediate
  hazard (`immediateHazard`), the subject must not come into contact with it (`rel_contact`) and
  must not breach the clearance while the two draw together (`clearanceBreached`): where their
  centres approach each other under constant velocities within `p.yield_conflict_horizon`
  (`prim_closest_approach_within`), neither the centre distance at that closest approach
  (`prim_closest_approach_distance`) nor the present distance between the nearest points of the two
  bodies (`rel_surface_gap`) may fall below `p.yield_min_clearance` — the three atoms ob1's
  justification names for "yielding", read together. `immediateHazard` is st2's gap-acceptance
  convention: the vehicle's ground distance to the junction (`st_region_geometry_distance`) at most
  its own speed times `p.yield_headway_time`, or the conflict figure (`conflictPredicted`, the
  centres' closest approach below the clearance).

  c2 — residue, as the record states: concessive, no observable condition.

  Readings chosen here (declared in `narrowings`): how the clearance of the duty is measured (both
  the centre figure the primitive gives and the nearest-point figure `rel.surface_gap` gives, read
  while the two draw together), st2's two figures read as alternatives, the duty read at every
  junction the selection picks, and the protected vehicle's approach carrier read as a travel region
  other than the junction itself.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_2_o2

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCautiousProceedMaxSpeed : Term := .param "p.cautious_proceed_max_speed"
def pStandstillSpeedTolerance : Term := .param "p.standstill_speed_tolerance"
def pYieldConflictHorizon : Term := .param "p.yield_conflict_horizon"
def pYieldHeadwayTime : Term := .param "p.yield_headway_time"
def pYieldMinClearance : Term := .param "p.yield_min_clearance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- c3: the subject's footprint overlaps the junction `j`. -/
def atJunction : Formula := .atom "rel_occupies" [vV, .var "j"] []

/-- c3: the subject is moving. -/
def moving : Formula := .cmp (.measure "kin_speed" [vV]) .gt pStandstillSpeedTolerance

/-- c1: a stop sign or a yield sign governs a travel region, other than the junction itself, whose
    entrance end is `j`. -/
def signErectedAtAnEntrance : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.and (.not (.same (.var "c") (.var "j")))
      (.and (.atom "st_lane_enters" [.var "c", .var "j"] [])
        (.or (.existsDevice (.lit "stop_sign") "ds"
                (.atom "dev_governs" [.var "ds", .var "c"] []))
             (.existsDevice (.lit "yield_sign") "dy"
                (.atom "dev_governs" [.var "dy", .var "c"] [])))))

/-- e1: traffic at `j` is being controlled by a police officer or a traffic-control signal, read on
    the junction itself or on the subject's own approach carrier. -/
def trafficControlled : Formula :=
  .existsUser "w"
    (.and (.atom "ru_aggregate" [.var "w", .lit "DEF-NRS-484A-285::traffic"] [])
      (.and (.atom "rel_occupies" [.var "w", .var "j"] [])
        (.existsRegion (.lit "travel_region") "cc"
          (.and (.or (.same (.var "cc") (.var "j"))
                     (.and (.atom "st_lane_enters" [.var "cc", .var "j"] [])
                           (.atom "rel_occupies" [vV, .var "cc"] [])))
            (.or (.existsDevice (.lit "human_direction") "o"
                    (.and (.atom "dev_human_direction_role" [.var "o", .lit "police_officer"] [])
                          (.atom "dev_governs" [.var "o", .var "cc"] [])))
                 (.existsDevice (.lit "traffic_signal") "g"
                    (.atom "dev_governs" [.var "g", .var "cc"] [])))))))

/-- Applicability: e1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:; c1 (condition): if a stop sign or a yield sign is erected at one or more entrances thereto; c2 (condition): although not a part of a through highway; c3 (condition): during the time such driver is moving across or within the intersection. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "j"
    (.and atJunction
      (.and moving
        (.and signErectedAtAnEntrance
          (.not trafficControlled))))

/-- st1: proceeding cautiously. -/
def cautiously : Formula := .cmp (.measure "kin_speed" [vV]) .le pCautiousProceedMaxSpeed

/-- The subject and `u` draw together within the horizon (their centres approach each other under
    constant velocities). -/
def drawingTogether : Formula :=
  .derived "prim_closest_approach_within" [vV, .var "u"] [pYieldConflictHorizon]

/-- The centre distance at that closest approach is below the clearance. -/
def centresBelowClearance : Formula :=
  .cmp (.quantity "prim_closest_approach_distance" [vV, .var "u"] [pYieldConflictHorizon])
       .lt pYieldMinClearance

/-- st2: the conflict figure of the hazard convention — the closest approach of the two centres
    within the horizon below the clearance. -/
def conflictPredicted : Formula := .and drawingTogether centresBelowClearance

/-- ob1: the clearance the subject must keep while the two draw together — neither the closest
    approach of their centres nor the present distance between the nearest points of their bodies
    may fall below the clearance. -/
def clearanceBreached : Formula :=
  .and drawingTogether
    (.or centresBelowClearance
         (.cmp (.measure "rel_surface_gap" [vV, .var "u"]) .lt pYieldMinClearance))

/-- ob1: `u` reached `j` through an approach carrier of it that no stop sign and no yield sign
    governs. -/
def notObligated : Formula :=
  .existsRegion (.lit "travel_region") "cu"
    (.and (.not (.same (.var "cu") (.var "j")))
      (.and (.atom "rel_occupies" [.var "u", .var "cu"] [])
        (.and (.atom "st_lane_enters" [.var "cu", .var "j"] [])
          (.and (.not (.existsDevice (.lit "stop_sign") "dus"
                        (.atom "dev_governs" [.var "dus", .var "cu"] [])))
                (.not (.existsDevice (.lit "yield_sign") "duy"
                        (.atom "dev_governs" [.var "duy", .var "cu"] [])))))))

/-- st2: `u` approaches so closely as to constitute an immediate hazard. -/
def immediateHazard : Formula :=
  .or (.cmp (.measure "st_region_geometry_distance" [.var "u", .var "j"]) .le
            (.mul (.measure "kin_speed" [.var "u"]) pYieldHeadwayTime))
      conflictPredicted

/-- ob1 with st2: the vehicles this duty protects. -/
def owedPrecedence : Formula :=
  .and (.not (.same (.var "u") vV))
    (.and (.atom "ru_aggregate" [.var "u", .lit "DEF-NRS-484A-320::vehicle"] [])
      (.and notObligated
        (.or (.atom "rel_occupies" [.var "u", .var "j"] [])
             immediateHazard)))

/-- ob1: granting precedence to `u`. -/
def grantsPrecedence : Formula :=
  .and (.not (.atom "rel_contact" [vV, .var "u"] []))
       (.not clearanceBreached)

/-- Obligation: st1 (standard): and shall proceed cautiously,; ob1 (obligation): yielding to vehicles not so obligated to stop or yield and which are within the intersection; st2 (standard): or approaching so closely as to constitute an immediate hazard -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "j"
    (.implies (.and atJunction (.and moving signErectedAtAnEntrance))
      (.and cautiously
        (.forallUser "u" (.implies owedPrecedence grantsPrecedence))))

def rule : Rule :=
  { id := "NRS_484B_257_2_o2"
    laws := ["NRS-484B-257-2"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "and shall proceed cautiously"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within", "rel.occupies", "st.intersection"]
          params := ["p.cautious_proceed_max_speed", "p.yield_conflict_horizon", "p.yield_min_clearance"]
          convention := "A low-speed stopping-distance convention bounds the caution: crossing the junction after obeying the sign, the subject's speed stays at or below p.cautious_proceed_max_speed, the speed at which a vehicle can be brought to rest within the junction's conflict area on seeing a road user it must give way to. The degree of the hazard enters through the conflict-avoidance convention, the closest approach under constant velocities within p.yield_conflict_horizon staying clear of p.yield_min_clearance, so that the bound moves with the proximity and closing speed of the road users the same sentence names rather than switching on their presence alone."
          surrogate := false }
      , { standard := "or approaching so closely as to constitute an immediate hazard"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within", "rel.occupies", "rel.surface_gap", "st.intersection", "st.lane_enters", "st.region_geometry", "st.travel_region"]
          params := ["p.yield_headway_time", "p.yield_conflict_horizon", "p.yield_min_clearance"]
          convention := "Gap-acceptance convention for a crossing from a sign-controlled entrance. 'So closely' is the other vehicle's distance to the junction, which st.region_geometry gives as 'the ground distance from a road user's body outline to it', read on a vehicle on a carrier entering that junction (rel.occupies, st.travel_region, st.lane_enters): the vehicle is so close where that distance is at most its own speed (kin.speed) times p.yield_headway_time, so the bound moves with its speed -- a faster approach makes a greater distance count, a slower one a smaller. The immediacy is read in the same breath by the conflict-avoidance convention: the closest approach between the two bodies under constant velocities within p.yield_conflict_horizon falling below p.yield_min_clearance, measured between the nearest points of the bodies by rel.surface_gap. Both figures are the reading's, from gap-acceptance tables for a crossing manoeuvre."
          surrogate := false } ]
    residues := ["'although not a part of a through highway' adds no observable condition: it is concessive, saying that the cautious proceeding and the yielding are owed even where the junction is not part of a through highway, so the duty is the same whether or not it is. Reading it as a condition would make the rule apply only at junctions off a through highway, which is narrower than the words."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "ob1"
          why := "The clearance the duty keeps is read with both measures the span's justification names, because no primitive gives the closest approach between the nearest points of two bodies: where the two draw together within p.yield_conflict_horizon (prim.closest_approach_within), the duty is breached when the centre distance at that closest approach (prim.closest_approach_distance) is below p.yield_min_clearance, and also when the present distance between the nearest points of the bodies (rel.surface_gap) is below it, which catches two long bodies passing closer than the clearance while their centres stay further apart. Where the two do not draw together at all, neither figure is read: a road user moving away is granted precedence."
          kind := "reading" }
      , { span := "ob1"
          why := "The duty is read at every intersection the applicability's selection picks: the obligation quantifies universally over regions of kind st.intersection and rewrites that whole selection (the subject's footprint overlapping the junction, its moving, and a stop or yield sign at one of the junction's entrances) as the guard of the implication, since a region bound in the applicability is not in scope in the obligation."
          kind := "reading" }
      , { span := "ob1"
          why := "The approach carrier through which a protected vehicle reached the junction is read as a travel region other than the junction itself: a junction is no approach to itself, and st.lane_enters is not recorded on it, so reading the junction as its own entrance would leave the vehicle's obligation unknown wherever it stands in the junction."
          kind := "reading" }
      , { span := "st2"
          why := "The two figures of the hazard convention are read as alternatives: a vehicle approaches so closely as to constitute an immediate hazard where its ground distance to the junction is at most its own speed times p.yield_headway_time, or where the closest approach of the two centres within p.yield_conflict_horizon falls below p.yield_min_clearance. The record states both in one breath without saying which governs where, and either alone is enough to make the approach an immediate one. The nearest-point figure is not read a second time here: it measures the clearance of the duty itself (ob1), so that the set of vehicles the duty protects is decided by the approach and not by the breach."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_2_o2
