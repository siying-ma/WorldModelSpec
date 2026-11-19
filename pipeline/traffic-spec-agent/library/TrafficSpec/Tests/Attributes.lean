/-
  TrafficSpec.Tests.Attributes
  Attribute atoms of road users, structures and devices: each accessor true, false, or unknown where
  the source does not record it; the dispatch by name; and the JSON key the decoder reads it from.
-/
import TrafficSpec.Core.Language.Semantics
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Evidence.Certificate
import TrafficSpec.Core.Evidence.TraceLint
namespace TrafficSpec.Tests.Attributes
open TrafficSpec Units TrafficSpec.Decode

/-- The value an atom dispatched by name takes on a scene: `some v` for a well-formed call
    (`v` the three-valued result), `none` for a malformed one. -/
def atomV (s : Scene) (n : String) (args : List Primitives.DArg) : Option (Option Bool) :=
  match Semantics.evalAtomE s n args [] with
  | .ok r => some r.v.toOption
  | .error _ => none
def measureV (s : Scene) (n : String) (args : List Primitives.DArg) : Option Q :=
  (Semantics.evalMeasure s n args).toOption
def scene (sts : List Structure := []) (us : List RoadUser := []) (ds : List Device := []) : Scene :=
  { t := 0, users := us, structures := sts, devices := ds }
def decodeScene (j : String) : Scene := ((parse trace s!"\{\"scenes\": [{j}]}").toOption.getD []).headD { t := 0 }

-- an entrance: its kind and whether the way it leads into is private
def drive : Structure := { id := 30, kind := .drivewayOrAlleyEntrance, entranceKind := some .driveway, privateWay := some true }
def alleyMouth : Structure := { id := 31, kind := .drivewayOrAlleyEntrance, entranceKind := some .alley, privateWay := some false }
def unread : Structure := { id := 32, kind := .drivewayOrAlleyEntrance }
#guard st_driveway_or_alley_entrance_kind (scene [drive]) 30 = some .driveway
#guard st_driveway_or_alley_entrance_kind (scene [unread]) 32 = none
#guard st_driveway_or_alley_entrance_private (scene [drive]) 30 = some true
#guard st_driveway_or_alley_entrance_private (scene [alleyMouth]) 31 = some false
#guard st_driveway_or_alley_entrance_private (scene [unread]) 32 = none
#guard atomV (scene [drive]) "st_driveway_or_alley_entrance_kind" [.v 30, .s "driveway"] = some (some true)
#guard atomV (scene [drive]) "st_driveway_or_alley_entrance_kind" [.v 30, .s "alley"] = some (some false)
#guard atomV (scene [unread]) "st_driveway_or_alley_entrance_kind" [.v 32, .s "private_road"] = some none
#guard atomV (scene [drive]) "st_driveway_or_alley_entrance_kind" [.v 30, .s "garage"] = none
#guard atomV (scene [alleyMouth]) "st_driveway_or_alley_entrance_private" [.v 31] = some (some false)
#guard atomV (scene [unread]) "st_driveway_or_alley_entrance_private" [.v 32] = some none
#guard EntranceKind.ofString "property" = some .property
#guard st_driveway_or_alley_entrance_kind (decodeScene "{\"t\": 0, \"structures\": [{\"id\": 30, \"kind\": \"driveway_or_alley_entrance\", \"entrance_kind\": \"private_road\", \"private\": true}]}") 30 = some .privateRoad
#guard st_driveway_or_alley_entrance_private (decodeScene "{\"t\": 0, \"structures\": [{\"id\": 30, \"kind\": \"driveway_or_alley_entrance\", \"entrance_kind\": \"private_road\", \"private\": true}]}") 30 = some true

-- a road user's unladen mass, in kilograms; a pound is 0.45359237 kg exactly
def heavy : RoadUser := { track := 1, classes := some [.motorVehicle, .truck], unladenMass := some (pounds 8000) }
def unweighed : RoadUser := { track := 2, classes := some [.motorVehicle] }
#guard Q.eq (pounds 8000) (Q.mk' 362873896 100000) = true
#guard (ru_unladen_mass (scene [] [heavy]) 1).map (Q.eq · (Q.mk' 362873896 100000)) = some true
#guard ru_unladen_mass (scene [] [unweighed]) 2 = none
#guard (measureV (scene [] [heavy]) "ru_unladen_mass" [.v 1]).map (Q.gt · (kilograms 3600)) = some true
#guard measureV (scene [] [unweighed]) "ru_unladen_mass" [.v 2] = none
#guard (ru_unladen_mass (decodeScene "{\"t\": 0, \"users\": [{\"track\": 1, \"unladen_mass\": 3628.5}]}") 1).map (Q.eq · (Q.mk' 7257 2)) = some true
#guard (ru_unladen_mass (mask { Manifest.full "t" with entries := (Manifest.full "t").entries.filter (·.1 != "ru.unladen_mass") } (scene [] [heavy])) 1) = none
-- a mass compares with a mass, never with a length or a ratio; a reading may state it in pounds
def massEnv : DimEnv := DimCheck.envOf default []
#guard DimCheck.errors massEnv (.cmp (.measure "ru_unladen_mass" [.var "v"]) .gt (.lit (pounds 8000) .kilogram)) = []
#guard (DimCheck.errors massEnv (.cmp (.measure "ru_unladen_mass" [.var "v"]) .gt (.lit (Q.ofInt 8000) .ratio))).map DimError.tag = ["mismatch"]
#guard (DimCheck.errors massEnv (.cmp (.measure "ru_unladen_mass" [.var "v"]) .gt (.lit (Q.ofInt 8000) .metre))).map DimError.tag = ["mismatch"]
#guard match Lean.Json.parse "\"pounds\"" with
  | .ok j => match Decode.unit "u" j with | .ok (.kilogram, k) => Q.eq k (pounds 1) | _ => false
  | .error _ => false
#guard match Lean.Json.parse "{\"lit\": {\"num\": 3600, \"den\": 1}, \"unit\": \"kilogram\"}" with
  | .ok j => match Decode.term "t" j with | .ok (.lit q .kilogram) => q.num == 3600 | _ => false
  | .error _ => false

-- regulatory sign codes: lamps on, parking permitted (with conditions read as the zone sign's)
def lampsSign : Device := { id := 40, kind := .regulatorySign, code := some .lampsOn, governs := [7] }
def parkSign : Device := { id := 41, kind := .regulatorySign, code := some .parkingPermitted, conditions := some {}, governs := [7] }
def unreadSign : Device := { id := 42, kind := .regulatorySign }
#guard SignCode.ofString "lamps_on" = some .lampsOn
#guard SignCode.ofString "parking_permitted" = some .parkingPermitted
#guard dev_regulatory_sign_code (scene [] [] [lampsSign]) 40 = some .lampsOn
#guard atomV (scene [] [] [lampsSign]) "dev_regulatory_sign_code" [.v 40, .s "lamps_on"] = some (some true)
#guard atomV (scene [] [] [parkSign]) "dev_regulatory_sign_code" [.v 41, .s "lamps_on"] = some (some false)
#guard atomV (scene [] [] [parkSign]) "dev_regulatory_sign_code" [.v 41, .s "parking_permitted"] = some (some true)
#guard atomV (scene [] [] [unreadSign]) "dev_regulatory_sign_code" [.v 42, .s "parking_permitted"] = some none
#guard (dev_regulatory_sign_conditions (scene [] [] [parkSign]) 41).map (·.windows.isEmpty) = some true
#guard dev_regulatory_sign_code (decodeScene "{\"t\": 0, \"devices\": [{\"id\": 41, \"kind\": \"regulatory_sign\", \"code\": \"parking_permitted\", \"governs\": []}]}") 41 = some .parkingPermitted

-- a railway track, its kind, and the view along it from a road user near its crossing
def rails : Structure := { id := 50, kind := .railwayTrack, railwayKind := some .railroad
                           boundary := some [(metres (-200), metres 10), (metres 200, metres 10), (metres 200, metres 12), (metres (-200), metres 12)] }
def tram : Structure := { id := 51, kind := .railwayTrack, railwayKind := some .streetcar }
def bareTrack : Structure := { id := 52, kind := .railwayTrack }
def crossingRegion : Structure := { id := 53, kind := .railwayCrossing }
def nearRails : RoadUser := { track := 1, classes := some [.motorVehicle], kin := { position := some (metres 0, metres 0) },
                              sightAlongWay := some [(50, metres 120)] }
#guard st_railway_track (scene [rails]) 50 = some true
#guard st_railway_track (scene [crossingRegion]) 53 = some false
#guard st_railway_crossing (scene [rails]) 50 = some false
#guard st_railway_track_kind (scene [rails]) 50 = some .railroad
#guard st_railway_track_kind (scene [tram]) 51 = some .streetcar
#guard st_railway_track_kind (scene [bareTrack]) 52 = none
#guard atomV (scene [tram]) "st_railway_track_kind" [.v 51, .s "railroad"] = some (some false)
#guard atomV (scene [bareTrack]) "st_railway_track_kind" [.v 52, .s "railroad"] = some none
#guard atomV (scene [rails]) "st_railway_track" [.v 50] = some (some true)
#guard (st_region_geometry_distance (scene [rails] [nearRails]) 1 50).map (Q.eq · (metres 10)) = some true
#guard (measureV (scene [rails] [nearRails]) "st_sight_along_way" [.v 1, .v 50]).map (Q.eq · (metres 120)) = some true
#guard measureV (scene [rails] [{ nearRails with sightAlongWay := none }]) "st_sight_along_way" [.v 1, .v 50] = none
#guard StructureKind.sightWays.contains .railwayTrack
#guard TraceLint.checkReferences [scene [rails] [nearRails]] = []
#guard (TraceLint.checkReferences [scene [crossingRegion] [{ nearRails with sightAlongWay := some [(53, metres 120)] }]]).length = 1
#guard st_railway_track_kind (decodeScene "{\"t\": 0, \"structures\": [{\"id\": 51, \"kind\": \"railway_track\", \"railway_kind\": \"streetcar\"}]}") 51 = some .streetcar

-- a disabled vehicle: true or false as the source records it, unknown otherwise, never a class
def brokenDown : RoadUser := { track := 1, classes := some [.motorVehicle], disabled := some true, sig := { hazard := some true } }
def running : RoadUser := { track := 2, classes := some [.motorVehicle], disabled := some false }
def halted : RoadUser := { track := 3, classes := some [.motorVehicle], sig := { hazard := some true }, kin := { speed := some Q.zero, engineRunning := some false } }
#guard ru_disabled (scene [] [brokenDown]) 1 = some true
#guard ru_disabled (scene [] [running]) 2 = some false
#guard ru_disabled (scene [] [halted]) 3 = none
#guard atomV (scene [] [brokenDown]) "ru_disabled" [.v 1] = some (some true)
#guard atomV (scene [] [running]) "ru_disabled" [.v 2] = some (some false)
#guard atomV (scene [] [halted]) "ru_disabled" [.v 3] = some none
#guard RoadUserClass.ofString "disabled" = none
#guard ru_disabled (mask { Manifest.full "t" with entries := (Manifest.full "t").entries.filter (·.1 != "ru.disabled") } (scene [] [brokenDown])) 1 = none
#guard ru_disabled (decodeScene "{\"t\": 0, \"users\": [{\"track\": 1, \"disabled\": false}]}") 1 = some false
-- an impassable section of a sidewalk is a region kind of its own, not an obstruction
def gapInWalk : Structure := { id := 60, kind := .impassableSection }
def walk : Structure := { id := 61, kind := .sidewalk }
def debris : Structure := { id := 62, kind := .obstruction, obstructionKind := some .debris }
#guard st_impassable_section (scene [gapInWalk]) 60 = some true
#guard st_impassable_section (scene [walk]) 61 = some false
#guard st_impassable_section (scene [debris]) 62 = some false
#guard st_obstruction (scene [gapInWalk]) 60 = some false
#guard st_impassable_section (scene [{ walk with unobservedKinds := [.impassableSection] }]) 61 = none
#guard atomV (scene [gapInWalk]) "st_impassable_section" [.v 60] = some (some true)

-- an official vehicle in postal service
def mailVan : RoadUser := { track := 1, classes := some [.motorVehicle, .officialVehicle], officialKind := some .postal }
#guard OfficialKind.ofString "postal" = some .postal
#guard ru_official_vehicle_kind (scene [] [mailVan]) 1 = some .postal
#guard atomV (scene [] [mailVan]) "ru_official_vehicle_kind" [.v 1, .s "postal"] = some (some true)
#guard atomV (scene [] [mailVan]) "ru_official_vehicle_kind" [.v 1, .s "tow"] = some (some false)
#guard atomV (scene [] [{ mailVan with officialKind := none }]) "ru_official_vehicle_kind" [.v 1, .s "postal"] = some none
-- a hose, protected or bare; a sidewalk elevator or chute
def bridgedHose : Structure := { id := 70, kind := .obstruction, obstructionKind := some .hose, isProtected := some true }
def bareHose : Structure := { id := 71, kind := .obstruction, obstructionKind := some .hose, isProtected := some false }
def hose : Structure := { id := 72, kind := .obstruction, obstructionKind := some .hose }
def chute : Structure := { id := 73, kind := .obstruction, obstructionKind := some .sidewalkElevatorOrChute }
#guard st_obstruction_protected (scene [bridgedHose]) 70 = some true
#guard st_obstruction_protected (scene [bareHose]) 71 = some false
#guard st_obstruction_protected (scene [hose]) 72 = none
#guard atomV (scene [bareHose]) "st_obstruction_protected" [.v 71] = some (some false)
#guard atomV (scene [hose]) "st_obstruction_protected" [.v 72] = some none
#guard atomV (scene [chute]) "st_obstruction_kind" [.v 73, .s "sidewalk_elevator_or_chute"] = some (some true)
#guard atomV (scene [chute]) "st_obstruction_kind" [.v 73, .s "sidewalk_fixture"] = some (some false)
#guard st_obstruction_protected (decodeScene "{\"t\": 0, \"structures\": [{\"id\": 71, \"kind\": \"obstruction\", \"obstruction_kind\": \"hose\", \"protected\": false}]}") 71 = some false
-- a fire official directing traffic is a role of its own
def fireChief : Device := { id := 80, kind := .humanDirection, humanRole := some .fireOfficial, humanIndication := some .proceed }
#guard HumanRole.ofString "fire_official" = some .fireOfficial
#guard atomV (scene [] [] [fireChief]) "dev_human_direction_role" [.v 80, .s "fire_official"] = some (some true)
#guard atomV (scene [] [] [fireChief]) "dev_human_direction_role" [.v 80, .s "police_officer"] = some (some false)
#guard atomV (scene [] [] [{ fireChief with humanRole := none }]) "dev_human_direction_role" [.v 80, .s "fire_official"] = some none

-- the split classes and the tow car: each its own class, none implying another
def shuttle : RoadUser := { track := 1, classes := some [.motorVehicle, .bus, .tourOrShuttleBus] }
def limo : RoadUser := { track := 2, classes := some [.motorVehicle, .limousine] }
def semi : RoadUser := { track := 3, classes := some [.trailer] }
def rig : RoadUser := { track := 4, classes := some [.motorVehicle, .truck, .vehicleCombination] }
def wrecker : RoadUser := { track := 5, classes := some [.motorVehicle, .towCar] }
def unsure : RoadUser := { track := 6, classes := some [.motorVehicle], unobservedClasses := [.limousine, .towCar] }
def fleet : Scene := scene [] [shuttle, limo, semi, rig, wrecker, unsure]
#guard ru_tour_or_shuttle_bus fleet 1 = some true
#guard ru_limousine fleet 1 = some false
#guard ru_limousine fleet 2 = some true
#guard ru_tour_or_shuttle_bus fleet 2 = some false
#guard ru_trailer fleet 3 = some true
#guard ru_vehicle_combination fleet 3 = some false
#guard ru_vehicle_combination fleet 4 = some true
#guard ru_trailer fleet 4 = some false
#guard ru_tow_car fleet 5 = some true
#guard ru_official_vehicle fleet 5 = some false
#guard ru_tow_car fleet 6 = none
#guard ru_limousine fleet 6 = none
#guard atomV fleet "ru_tow_car" [.v 5] = some (some true)
#guard atomV fleet "ru_vehicle_combination" [.v 3] = some (some false)
#guard atomV fleet "ru_limousine" [.v 6] = some none
#guard ru_aggregate fleet 5 [.towCar, .limousine] = some true
#guard ru_aggregate fleet 6 [.towCar] = none
#guard RoadUserClass.ofString "tour_bus_or_limousine" = none
#guard RoadUserClass.ofString "trailer_or_combination" = none
#guard ru_tow_car (decodeScene "{\"t\": 0, \"users\": [{\"track\": 5, \"classes\": [\"motor_vehicle\", \"tow_car\"]}]}") 5 = some true

-- the trimobile: a motorcycle as well; unobserved is unknown, and a complete class list without it
-- decides it false
def trike : RoadUser := { track := 1, classes := some [.motorcycle, .trimobile] }
def oldTrike : RoadUser := { track := 2, classes := some [.motorcycle], unobservedClasses := [.trimobile] }
def bike : RoadUser := { track := 3, classes := some [.motorcycle] }
def unclassed : RoadUser := { track := 4 }
def riders : Scene := scene [] [trike, oldTrike, bike, unclassed]
#guard ru_trimobile riders 1 = some true
#guard ru_motorcycle riders 1 = some true
#guard ru_trimobile riders 2 = none
#guard ru_motorcycle riders 2 = some true
#guard ru_trimobile riders 3 = some false
#guard ru_trimobile riders 4 = none
#guard atomV riders "ru_trimobile" [.v 1] = some (some true)
#guard atomV riders "ru_trimobile" [.v 2] = some none
#guard atomV riders "ru_trimobile" [.v 3] = some (some false)
#guard ru_aggregate riders 2 [.trimobile] = none
#guard ru_aggregate riders 2 [.motorcycle, .trimobile] = some true
#guard ru_aggregate riders 3 [.trimobile] = some false
#guard RoadUserClass.ofString "trimobile" = some .trimobile
#guard ru_trimobile (decodeScene "{\"t\": 0, \"users\": [{\"track\": 1, \"classes\": [\"motorcycle\", \"trimobile\"]}]}") 1 = some true
#guard ru_trimobile (decodeScene "{\"t\": 0, \"users\": [{\"track\": 2, \"classes\": [\"motorcycle\"], \"unobserved_classes\": [\"trimobile\"]}]}") 2 = none
#guard ru_trimobile (mask { Manifest.full "t" with entries := (Manifest.full "t").entries.filter (·.1 != "ru.trimobile") } riders) 1 = none
#guard ru_motorcycle (mask { Manifest.full "t" with entries := (Manifest.full "t").entries.filter (·.1 != "ru.trimobile") } riders) 1 = some true
#guard ru_trimobile (mask { Manifest.full "t" with entries := (Manifest.full "t").entries.filter (·.1 != "ru.trimobile") } riders) 3 = none
#guard atomIds.contains "ru.trimobile"

end TrafficSpec.Tests.Attributes
