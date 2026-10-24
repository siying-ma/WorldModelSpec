import TrafficSpec.Core.Vocab.Atoms
import TrafficSpec.Core.Vocab.Params
import TrafficSpec.Core.Vocab.Primitives
namespace TrafficSpec.Tests
open TrafficSpec Units

-- Two cars on a straight road heading +x: a at the origin, b 20 m ahead, both 4.5 m × 1.8 m;
-- a pedestrian at (10, 3) with no kinematics beyond position; occupancy observed.
def car (id : Nat) (x : Int) (dir : Int) (v : Int) : RoadUser :=
  { track := id
    classes := some [.motorVehicle]
    kin := { position := some (metres x, metres 0)
             heading := some (Q.ofInt dir, Q.ofInt 0)
             velocity := some (metresPerSecond (dir * v), metres 0)
             speed := some (metresPerSecond v)
             extent := some (Q.mk' 225 100, Q.mk' 9 10, Q.mk' 3 4) } }
def ua : RoadUser := car 1 0 1 10
def ub : RoadUser := { car 2 20 1 8 with classes := some [.motorVehicle, .taxicab], sig := { turnIndicator := some .left, brakeLamp := some true } }
def uc : RoadUser := car 3 50 (-1) 12
def ped : RoadUser := { track := 4
                        classes := some [.pedestrian]
                        kin := { position := some (metres 10, metres 3) } }
def lane7 : Structure := { id := 7
                           kind := .lane
                           lane := some { countInDirection := some 2, ordinalFromLeft := some 1 } }
def sig9 : Device := { id := 9, kind := .trafficSignal, indications := some [.circularRed], governs := [7] }
def scene0 : Scene := { t := 0
                        subject := some 1
                        users := [ua, ub, uc, ped]
                        structures := [lane7]
                        devices := [sig9]
                        occupancyObserved := [1, 2, 3, 4]
                        occupies := [(1, 7), (2, 7)]
                        env := { darkness := some false }
                        assumptions := [("asm.business_district", true)] }
def sceneUnobserved : Scene := { t := 0, users := [ua, ub] }

#guard ru_motor_vehicle scene0 1 = some true
#guard ru_taxicab scene0 1 = some false
#guard ru_taxicab scene0 2 = some true
#guard ru_pedestrian scene0 4 = some true
#guard ru_motor_vehicle scene0 99 = none                 -- unknown track
#guard ru_subject scene0 1 = some true
#guard ru_subject sceneUnobserved 1 = none              -- no subject declared
#guard (kin_speed scene0 2).map (Q.eq · (metresPerSecond 8)) = some true
#guard kin_speed scene0 4 = none                        -- the pedestrian's speed was not observed
#guard (rel_centre_distance scene0 1 2).map (Q.eq · (metres 20)) = some true
#guard (rel_centre_distance scene0 1 4).map (Q.lt · (metres 11)) = some true   -- √109 ≈ 10.44
#guard (rel_centre_distance scene0 1 4).map (Q.gt · (metres 10)) = some true
#guard (rel_surface_gap_longitudinal scene0 1 2).map (Q.eq · (Q.mk' 155 10)) = some true  -- 20 − 2·2.25
#guard rel_ahead_in_lane scene0 2 1 = some true          -- b is ahead of a in the shared lane
#guard rel_ahead_in_lane scene0 1 2 = some false
#guard rel_bearing_ahead scene0 1 2 = some true
#guard rel_bearing_left scene0 1 4 = some true           -- the pedestrian is to a's left
#guard rel_oncoming scene0 1 3 (Q.mk' 9 10) = some true  -- c heads −x toward a and closes
#guard rel_oncoming scene0 1 2 (Q.mk' 9 10) = some false
#guard rel_same_direction scene0 1 2 (Q.mk' 9 10) = some true
#guard rel_contact scene0 1 2 = some false
#guard rel_surface_gap scene0 1 4 = none                 -- the pedestrian has no extent
#guard rel_occupies scene0 1 7 = some true
#guard rel_occupies scene0 4 7 = some false
#guard rel_occupies sceneUnobserved 1 7 = none           -- occupancy not observed at all
#guard rel_occupies { scene0 with occupancyObserved := [1] } 2 7 = none   -- observed for track 1 only
#guard rel_occupies { scene0 with occupancyObserved := [1] } 1 7 = some true
-- control state of the subject's vehicle, the intersection its lane enters, a measured line of sight
def ctlCar : RoadUser := { ua with kin := { ua.kin with engineRunning := some false, gear := some 0, throttle := some Q.zero } }
def lane7in : Structure := { lane7 with lane := lane7.lane.map fun l => { l with entersIntersection := some 20 } }
def junction20 : Structure := { id := 20, kind := .intersection }
def sceneCtl : Scene := { scene0 with users := [ctlCar, ub, uc, ped], structures := [lane7in, junction20],
                                      relations := [{ a := 1, b := 3, visible := some false }] }
#guard kin_engine_running sceneCtl 1 = some false
#guard kin_gear sceneCtl 1 = some 0
#guard (kin_throttle sceneCtl 1).map Q.isZero = some true
#guard kin_engine_running sceneCtl 2 = none                 -- not observed on the other car
#guard st_lane_enters sceneCtl 7 = some 20
#guard st_lane_enters scene0 7 = none
#guard rel_visible sceneCtl 1 3 = some false
#guard rel_visible sceneCtl 1 2 = none                      -- never computed from kinematics
-- region geometry: distance to a boundary is zero inside, the nearest edge outside
def box : Structure := { id := 8, kind := .crosswalk, boundary := some [(metres 5, metres 1), (metres 6, metres 1), (metres 6, metres 3), (metres 5, metres 3)] }
def sceneBox : Scene := { scene0 with structures := [lane7, box] }
#guard (st_region_geometry_distance sceneBox 1 8).map (fun d => Q.gt d (Q.mk' 275 100) && Q.lt d (Q.mk' 276 100)) = some true   -- from the front-left corner (2.25, 0.9) of a's body to (5, 1)
#guard (footprint scene0 1).map (·.length) = some 4
#guard footprint scene0 4 = none                                                              -- no extent, no heading
#guard (st_region_geometry_distance sceneBox 4 8).map (Q.eq · Q.zero) = some false          -- the pedestrian at (10,3) is outside
#guard (st_region_geometry_distance sceneBox 4 8).map (Q.eq · (metres 4)) = some true       -- 4 m east of the (6,3) corner along the edge
#guard st_region_geometry_distance sceneBox 1 99 = none
-- a crest is a region of its own: its kind is read, and the distance to it as to any region
def crestPatch : Structure := { id := 9, kind := .crest, boundary := some [(metres 20, metres (-2)), (metres 22, metres (-2)), (metres 22, metres 2), (metres 20, metres 2)] }
def sceneCrest : Scene := { scene0 with structures := [lane7, crestPatch] }
#guard st_crest sceneCrest 9 = some true
#guard st_crest sceneCrest 7 = some false
#guard (st_region_geometry_distance sceneCrest 1 9).map (Q.gt · Q.zero) = some true
#guard StructureKind.ofString "crest" = some .crest
#guard (Geom.segmentDistance (metres 3, metres 4) (metres 0, metres 0) (metres 6, metres 0)) = metres 4
#guard (Geom.polygonDistance (Q.mk' 11 2, metres 2) [(metres 5, metres 1), (metres 6, metres 1), (metres 6, metres 3), (metres 5, metres 3)]) = some Q.zero
#guard st_lane scene0 7 = some true
#guard st_lane_adjacency_count scene0 7 = some 2
#guard st_intersection scene0 7 = some false
#guard st_intersection scene0 8 = none                   -- unknown region
#guard dev_traffic_signal_shows scene0 9 .circularRed = some true
#guard dev_traffic_signal_shows scene0 9 .circularGreen = some false
#guard dev_governs scene0 9 7 = some true
#guard dev_inoperative scene0 9 = none
#guard sig_turn_indicator scene0 2 = some .left
#guard sig_brake_lamp scene0 1 = none
#guard env_darkness scene0 = some false
#guard env_precipitation scene0 = none
#guard Scene.assumption scene0 "asm.business_district" = some true
#guard Scene.assumption scene0 "asm.school_day" = none
#guard AsmId.wellFormed "asm.school_day" = true
#guard AsmId.wellFormed "school_day" = false
#guard SignalIndication.ofString "green_arrow(left)" = some (.greenArrow .left)
#guard SignalIndication.toString (.flashingYellowArrow .right) = "flashing_yellow_arrow(right)"
#guard RoadUserClass.ofString "motor_vehicle" = some .motorVehicle
-- aggregates: a member class held, none held with all observed, none held with one unobserved
#guard ru_aggregate scene0 2 [.bus, .taxicab] = some true
#guard ru_aggregate scene0 1 [.bus, .taxicab] = some false
#guard ru_aggregate scene0 4 [.bus] = some false
#guard ru_aggregate { scene0 with users := scene0.users.map fun u => if u.track == 1 then { u with unobservedClasses := [.bus] } else u } 1 [.bus, .taxicab] = none
#guard ru_aggregate scene0 99 [.bus] = none
-- the reading finds an aggregate by its id, and only by it
#guard (({ aggregates := [{ id := "D-1::vehicle", included := ["ru.bus"] }] } : Reading).aggregate "D-1::vehicle").map (·.included) = some ["ru.bus"]
#guard (({ aggregates := [{ id := "D-1::vehicle", included := ["ru.bus"] }] } : Reading).aggregate "vehicle").isNone
-- curvature is a magnitude: a bend to either hand reads the same
#guard st_curvature { t := 0, structures := [{ id := 1, kind := .roadway, curvature := some (Q.mk' (-1) 50) }] } 1 = some (Q.mk' 1 50)
-- overlap is exact over closed sets: shapes that cross with no vertex inside the other overlap,
-- shapes that only touch overlap, shapes apart do not
def barH : List Vec := [(Q.ofInt 0, Q.ofInt 4), (Q.ofInt 10, Q.ofInt 4), (Q.ofInt 10, Q.ofInt 6), (Q.ofInt 0, Q.ofInt 6)]
def barV : List Vec := [(Q.ofInt 4, Q.ofInt 0), (Q.ofInt 6, Q.ofInt 0), (Q.ofInt 6, Q.ofInt 10), (Q.ofInt 4, Q.ofInt 10)]
def beside : List Vec := [(Q.ofInt 10, Q.ofInt 4), (Q.ofInt 12, Q.ofInt 4), (Q.ofInt 12, Q.ofInt 6), (Q.ofInt 10, Q.ofInt 6)]
def apart : List Vec := [(Q.ofInt 11, Q.ofInt 4), (Q.ofInt 12, Q.ofInt 4), (Q.ofInt 12, Q.ofInt 6), (Q.ofInt 11, Q.ofInt 6)]
#guard Geom.polygonsOverlap barH barV
#guard !(barH.any (Geom.inPolygon · barV) || barV.any (Geom.inPolygon · barH))   -- the old vertex test missed it
#guard Geom.polygonsOverlap barH beside
#guard !Geom.polygonsOverlap barH apart
#guard CurbColour.ofString "purple" = none
-- a lane first from the left has no left neighbour, decidedly; its right one is not observed
#guard st_lane_left_of scene0 7 8 = some false
#guard st_lane_right_of scene0 7 8 = none
-- a device whose governed regions the source does not observe governs none decidedly
#guard dev_governs scene0 9 7 = some true
#guard dev_governs { scene0 with devices := [{ sig9 with governs := [], governsObserved := false }] } 9 7 = none
-- an indicator observed off
#guard TurnIndicatorState.ofString "off" = some .off
#guard sig_turn_indicator { scene0 with users := [{ ub with sig := { turnIndicator := some .off } }] } 2 = some .off
-- an arm observed giving no signal
#guard HandSignal.ofString "no_signal" = some .noSignal
#guard sig_hand_signal { scene0 with users := [{ ub with sig := { handSignal := some .noSignal } }] } 2 = some .noSignal
-- a strip region along the x axis between y0 and y1 (m), lying on way 100
def strip (rid : Nat) (y0 y1 : Int) : Structure :=
  { id := rid, kind := .medianOrDivider, ways := some [100]
    boundary := some [(metres (-50), metres y0), (metres 50, metres y0), (metres 50, metres y1), (metres (-50), metres y1)] }
-- the ways a region lies on
#guard st_on_way { scene0 with structures := [strip 20 3 5] } 20 = some [100]
#guard st_on_way scene0 7 = none
-- the view along a way from a road user
def viewer : RoadUser := { ua with sightAlongWay := some [(100, metres 80)] }
#guard st_sight_along_way { scene0 with users := [viewer] } 1 100 = some (metres 80)
#guard st_sight_along_way { scene0 with users := [viewer] } 1 101 = none
#guard st_sight_along_way scene0 1 100 = none
-- the side of a region from a road user at the origin heading +x: left positive, zero inside
def offsetOf (sts : List Structure) (u : RoadUser := ua) : QR :=
  (Primitives.prim_region_lateral_offset (Primitives.Ctx.mk' [{ scene0 with users := [u], structures := sts }] {}) 1 20)[0]!
def isOffset (r : QR) (q : Q) : Bool := match r with | .ok v => Q.isZero (Q.sub v q) | .error _ => false
#guard isOffset (offsetOf [strip 20 3 5]) (metres 3)
#guard isOffset (offsetOf [strip 20 (-5) (-3)]) (metres (-3))
#guard isOffset (offsetOf [strip 20 (-1) 1]) Q.zero
#guard !(offsetOf [strip 20 3 5] { ua with kin := { ua.kin with heading := none } }).toBool
end TrafficSpec.Tests
