/-
  NRS_484B_280_1c — NRS-484B-280-1c

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    z1 (subject): A driver of a motor vehicle
    z2a (obligation): shall: Exercise
    z2 (standard): proper caution
    z3 (trigger): upon observing
    z4 (trigger): a pedestrian:
    z5 (condition): (1) On or near a highway, street or road;
    z6 (condition): (2) At or near a bus stop or bench, shelter or transit stop for passengers of public mass transportation
    z7 (condition): or in the act of boarding
    z8 (condition): a bus or other public transportation vehicle;
    z9 (condition): or (3) In or near a school zone or a school crossing zone
    z10 (condition): marked in accordance with NRS 484B.363
    z11 (condition): or a marked or unmarked crosswalk.

  Elements (span → atoms, derived):
    z1: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    z2a: atoms ['kin.speed', 'rel.contact'], derived []
    z3: atoms ['rel.visible'], derived []
    z4: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    z5: atoms ['rel.occupies', 'st.highway', 'st.region_geometry'], derived []
    z6: atoms ['st.transit_stop', 'rel.occupies', 'st.region_geometry'], derived []
    z7: atoms ['drv.motion.complete_halt', 'sig.door_open', 'rel.surface_gap'], derived ['drv.motion.complete_halt']
    z8: atoms ['ru.aggregate=DEF-NRS-484A-030::bus', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'ru.transit_bus'], derived []
    z9: atoms ['dev.zone_sign', 'dev.governs', 'st.travel_region', 'rel.occupies', 'st.region_geometry'], derived []
    z10: atoms ['dev.zone_sign'], derived []
    z11: atoms ['st.crosswalk', 'rel.occupies', 'st.region_geometry'], derived []

  How each is written:
    z1: binder class `ru_aggregate subject DEF-NRS-484A-130::motor_vehicle`.
    z2a: kin.speed above p.halt_speed_tolerance is the applicability (the record's "at every
      observation at which the subject's kin.speed is above p.halt_speed_tolerance"); rel.contact
      negated in the obligation.
    z2 (operationalization): ¬(prim.closest_approach_within(subject, p, p.conflict_horizon) ∧
      prim.closest_approach_distance(subject, p, p.conflict_horizon) < p.conflict_centre_clearance).
    z3/z4: the obligation quantifies over every road user p (forallUser), other than the subject,
      member of DEF-NRS-484A-165::pedestrian and rel_visible(subject, p). The pedestrian conditions
      sit in the antecedent of the obligation, not the applicability, because the duty is "for every
      such pedestrian": a scene with no observed pedestrian is compliant, not inapplicable.
    z5, z6 (stop), z9/z11: "on/at/in" = rel_occupies(p, region), "near" = st_region_geometry_distance
      (p, region) ≤ p.pedestrian_near_reach, over regions of kind highway / transit_stop /
      travel_region / crosswalk.
    z7/z8: some road user v, a member of DEF-NRS-484A-030::bus or of DEF-NRS-484A-320::vehicle that
      is ru_transit_bus, with rel_surface_gap(p, v) ≤ p.pedestrian_near_reach,
      drv_motion_complete_halt(v, p.halt_speed_tolerance) and sig_door_open(v) (any side).
    z9/z10: some zone_sign z of kind school or school_crossing, not an end sign, governing
      (dev_governs) a travel region r the pedestrian is on or near. Crosswalk (z11) both marked and
      unmarked: the marked attribute is not read.
  No choice beyond the record's obligation sentence was made; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_280_1c

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pPedestrianNearReach : Term := .param "p.pedestrian_near_reach"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantified variables: `p` the observed pedestrian, `v` the vehicle boarded, `h`/`s`/`c`/`r`
    the highway, transit stop, crosswalk and governed travel region, `z` the zone sign. -/
def vP : Arg := .var "p"
def vV : Arg := .var "v"
def vZ : Arg := .var "z"

/-- z1: the subject is a member of DEF-NRS-484A-130::motor_vehicle. -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- "On / at / in" a region is `rel.occupies`; "near" it is the `st.region_geometry` ground
    distance at most p.pedestrian_near_reach. -/
def onOrNear (r : String) : Formula :=
  .or (.atom "rel_occupies" [vP, .var r] [])
      (.cmp (.measure "st_region_geometry_distance" [vP, .var r]) .le pPedestrianNearReach)

/-- z5: on or near a highway, street or road (st.highway). -/
def placeHighway : Formula := .existsRegion (.lit "highway") "h" (onOrNear "h")

/-- z6: at or near a transit stop (st.transit_stop). -/
def placeTransitStop : Formula := .existsRegion (.lit "transit_stop") "s" (onOrNear "s")

/-- z8: a bus (DEF-NRS-484A-030::bus) or a vehicle (DEF-NRS-484A-320::vehicle) in public transit
    service (ru.transit_bus). -/
def publicTransportVehicle : Formula :=
  .or (.atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-030::bus"] [])
      (.and (.atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] [])
            (.atom "ru_transit_bus" [vV] []))

/-- z7 + z8: in the act of boarding — within reach of the body of such a vehicle while it is at
    rest with a door open. -/
def placeBoarding : Formula :=
  .existsUser "v"
    (.and publicTransportVehicle
      (.and (.cmp (.measure "rel_surface_gap" [vP, vV]) .le pPedestrianNearReach)
        (.and (.derived "drv_motion_complete_halt" [vV] [pHaltSpeedTolerance])
              (.atom "sig_door_open" [vV] []))))

/-- z9 + z10: in or near a travel region governed by a school or school-crossing zone sign that
    begins a zone. -/
def placeSchoolZone : Formula :=
  .existsDevice (.lit "zone_sign") "z"
    (.and (.or (.atom "dev_zone_sign_kind" [vZ, .lit "school"] [])
               (.atom "dev_zone_sign_kind" [vZ, .lit "school_crossing"] []))
      (.and (.not (.atom "dev_zone_sign_end" [vZ] []))
        (.existsRegion (.lit "travel_region") "r"
          (.and (.atom "dev_governs" [vZ, .var "r"] []) (onOrNear "r")))))

/-- z11: in or near a crosswalk, marked or unmarked (st.crosswalk). -/
def placeCrosswalk : Formula := .existsRegion (.lit "crosswalk") "c" (onOrNear "c")

/-- z3 + z4 + z5–z11: `p` is a pedestrian other than the subject, visible from the subject, at
    one of the places. -/
def observedPedestrian : Formula :=
  .and (.not (.same vP vSubject))
    (.and (.atom "ru_aggregate" [vP, .lit "DEF-NRS-484A-165::pedestrian"] [])
      (.and (.atom "rel_visible" [vSubject, vP] [])
        (.or placeHighway
          (.or (.or placeTransitStop placeBoarding)
            (.or placeSchoolZone placeCrosswalk)))))

/-- z2a + z2: no contact, and no closest approach within p.conflict_horizon below
    p.conflict_centre_clearance. -/
def caution : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, vP] []))
    (.not (.and (.derived "prim_closest_approach_within" [vSubject, vP] [pConflictHorizon])
                (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vP] [pConflictHorizon])
                  .lt pConflictCentreClearance)))

/-- The duty is read at every observation at which the subject moves (kin.speed above
    p.halt_speed_tolerance), per z2a's element. -/
def applicability : Formula :=
  .cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance

/-- For every observed pedestrian at one of the places, caution. -/
def obligation : Formula := .forallUser "p" (.implies observedPedestrian caution)

def rule : Rule :=
  { id := "NRS_484B_280_1c"
    laws := ["NRS-484B-280-1c"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "proper caution upon observing a pedestrian (a standard of the driver's care, a state of mind)"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: while the vehicle moves, caution shows in its keeping no contact and no closest approach to the observed pedestrian, under constant velocities, within a time-to-collision horizon and below a centre clearance of about a car's half-length plus half a body width"
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_280_1c
