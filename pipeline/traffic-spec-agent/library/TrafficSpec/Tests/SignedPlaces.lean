/-
  TrafficSpec.Tests.SignedPlaces
  The sidewalks a riding-prohibition sign governs and the parking spaces an angle-parking sign
  governs, a sign legend's angle of parking, and a parking space's angle marking and axis: each
  true, false or unknown where the source does not record it; the dispatch by name; the JSON key;
  admission of the records; masking by the manifest; the region kinds Core declares.
-/
import TrafficSpec.Core.Language.Semantics
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Runtime.Admission
import TrafficSpec.Core.Evidence.TraceLint
import TrafficSpec.Core.Vocab.Ontology.Dimensions
namespace TrafficSpec.Tests.SignedPlaces
open TrafficSpec TrafficSpec.Decode

def atomV (s : Scene) (n : String) (args : List Primitives.DArg) : Option (Option Bool) :=
  match Semantics.evalAtomE s n args [] with
  | .ok r => some r.v.toOption
  | .error _ => none
def measureV (s : Scene) (n : String) (args : List Primitives.DArg) : Option Q :=
  (Semantics.evalMeasure s n args).toOption
def scene (sts : List Structure := []) (ds : List Device := []) : Scene :=
  { t := 0, structures := sts, devices := ds }
def decodeScene (j : String) : Scene := ((parse trace s!"\{\"scenes\": [{j}]}").toOption.getD []).headD { t := 0 }
def decodes (j : String) : Bool := (parse trace s!"\{\"scenes\": [{j}]}").toOption.isSome
def without (id : String) : Manifest := { Manifest.full "t" with entries := (Manifest.full "t").entries.filter (·.1 != id) }
def admitted (s : Scene) : Bool := (Admission.defects [s] Q.zero).isEmpty
def q (n : Int) : Q := Q.ofInt n

-- the places: two sidewalks, a lane, two parking spaces
def walk : Structure := { id := 20, kind := .sidewalk }
def walk2 : Structure := { id := 21, kind := .sidewalk }
def lane : Structure := { id := 22, kind := .lane }
def bay : Structure := { id := 23, kind := .parkingSpace, angleMarking := some true, parkingAxis := some (q 0, q 2) }
def bay2 : Structure := { id := 24, kind := .parkingSpace, angleMarking := some false, parkingAxis := some (q 0, q 0) }
def bay3 : Structure := { id := 25, kind := .parkingSpace }
def places : List Structure := [walk, walk2, lane, bay, bay2, bay3]

-- the signs
def regSign (id : DeviceId) (c : SignCode) : Device := { id := id, kind := .regulatorySign, code := some c }
def noBikes : Device := { regSign 50 .bicyclesProhibited with governsSidewalk := some [20] }
def noRiding : Device := { regSign 51 .bicycleEbikeEscooterProhibited with governsSidewalk := some [] }
def unrecorded : Device := regSign 52 .bicycleEbikeEscooterProhibited
def angled : Device := { regSign 53 .angleParking with governsParkingSpace := some [23], legendAngle := some (some (q 60)) }
def angledNone : Device := { regSign 54 .angleParking with governsParkingSpace := some [], legendAngle := some none }
def angledUnread : Device := regSign 55 .angleParking
def signs : Scene := scene places [noBikes, noRiding, unrecorded, angled, angledNone, angledUnread]

-- the new sign code: exactly its own value, never `bicycles_prohibited`, which keeps its own
#guard SignCode.ofString "bicycle_ebike_escooter_prohibited" = some .bicycleEbikeEscooterProhibited
#guard atomV signs "dev_regulatory_sign_code" [.v 51, .s "bicycle_ebike_escooter_prohibited"] = some (some true)
#guard atomV signs "dev_regulatory_sign_code" [.v 51, .s "bicycles_prohibited"] = some (some false)
#guard atomV signs "dev_regulatory_sign_code" [.v 50, .s "bicycle_ebike_escooter_prohibited"] = some (some false)
#guard atomV (scene [] [{ id := 56, kind := .regulatorySign }]) "dev_regulatory_sign_code" [.v 56, .s "bicycle_ebike_escooter_prohibited"] = some none
#guard dev_regulatory_sign_code (decodeScene "{\"t\": 0, \"devices\": [{\"id\": 51, \"kind\": \"regulatory_sign\", \"code\": \"bicycle_ebike_escooter_prohibited\"}]}") 51 = some .bicycleEbikeEscooterProhibited
#guard SignCode.ridingProhibitions = [.bicyclesProhibited, .bicycleEbikeEscooterProhibited]

-- governs_sidewalk: listed, recorded and not listed, not recorded
#guard dev_governs_sidewalk signs 50 20 = some true
#guard dev_governs_sidewalk signs 50 21 = some false
#guard dev_governs_sidewalk signs 51 20 = some false
#guard dev_governs_sidewalk signs 52 20 = none
#guard dev_governs_sidewalk signs 99 20 = none
#guard atomV signs "dev_governs_sidewalk" [.v 50, .v 20] = some (some true)
#guard atomV signs "dev_governs_sidewalk" [.v 51, .v 20] = some (some false)
#guard atomV signs "dev_governs_sidewalk" [.v 52, .v 20] = some none
#guard atomV signs "dev_governs_sidewalk" [.v 50] = none
-- never read from the travel regions a sign governs, nor read as them
#guard dev_governs_sidewalk (scene places [{ regSign 57 .bicyclesProhibited with governs := [22] }]) 57 20 = none
#guard dev_governs signs 50 20 = some false

-- governs_parking_space
#guard dev_governs_parking_space signs 53 23 = some true
#guard dev_governs_parking_space signs 53 25 = some false
#guard dev_governs_parking_space signs 54 23 = some false
#guard dev_governs_parking_space signs 55 23 = none
#guard atomV signs "dev_governs_parking_space" [.v 53, .v 23] = some (some true)
#guard atomV signs "dev_governs_parking_space" [.v 55, .v 23] = some none

-- the decoder: a list is the complete record, `[]` records none, an absent key records nothing
def govJson (k : String) (v : String) : String :=
  s!"\{\"t\": 0, \"structures\": [\{\"id\": 20, \"kind\": \"sidewalk\"}, \{\"id\": 23, \"kind\": \"parking_space\"}], \"devices\": [\{\"id\": 50, \"kind\": \"regulatory_sign\", \"code\": \"bicycles_prohibited\"{if k.isEmpty then "" else s!", \"{k}\": {v}"}}]}"
#guard dev_governs_sidewalk (decodeScene (govJson "governs_sidewalk" "[20]")) 50 20 = some true
#guard dev_governs_sidewalk (decodeScene (govJson "governs_sidewalk" "[]")) 50 20 = some false
#guard dev_governs_sidewalk (decodeScene (govJson "governs_sidewalk" "null")) 50 20 = none
#guard dev_governs_sidewalk (decodeScene (govJson "" "")) 50 20 = none
#guard dev_governs_parking_space (decodeScene (govJson "governs_parking_space" "[23]")) 50 23 = some true
#guard dev_governs_parking_space (decodeScene (govJson "" "")) 50 23 = none

-- admission: a record on such a sign naming such a region passes; another device, another code, an
-- unrecorded code, another kind of region or a region not in the scene is refused
#guard admitted signs
#guard admitted (scene places [{ regSign 51 .bicycleEbikeEscooterProhibited with governsSidewalk := some [20, 21] }])
#guard !admitted (scene places [{ regSign 58 .noParking with governsSidewalk := some [20] }])
#guard !admitted (scene places [{ id := 58, kind := .stopSign, governsSidewalk := some [20] }])
#guard !admitted (scene places [{ id := 58, kind := .regulatorySign, governsSidewalk := some [20] }])
#guard !admitted (scene places [{ id := 58, kind := .zoneSign, code := some .bicyclesProhibited, governsSidewalk := some [20] }])
#guard !admitted (scene places [{ noBikes with governsSidewalk := some [22] }])
#guard !admitted (scene places [{ noBikes with governsSidewalk := some [23] }])
#guard !admitted (scene places [{ noBikes with governsSidewalk := some [99] }])
#guard admitted (scene places [{ id := 58, kind := .stopSign, governsSidewalk := some [] }])
#guard !admitted (scene places [{ regSign 58 .bicyclesProhibited with governsParkingSpace := some [23] }])
#guard !admitted (scene places [{ angled with governsParkingSpace := some [20] }])
#guard !admitted (scene places [{ angled with governsParkingSpace := some [22] }])
#guard (Admission.defects [scene places [{ noBikes with governsSidewalk := some [22] }]] Q.zero) =
  ["scene t=0: device 50 governs_sidewalk: structure 22 is `lane`, not `sidewalk`"]
#guard (Admission.defects [scene places [{ regSign 58 .noParking with governsSidewalk := some [20] }]] Q.zero) =
  ["scene t=0: device 58 governs_sidewalk: only a regulatory sign whose code is a riding prohibition (bicycles_prohibited, bicycle_ebike_escooter_prohibited) carries it"]
-- the JSON path is held to the same admission
#guard (match parse trace "{\"scenes\": [{\"t\": 0, \"structures\": [{\"id\": 22, \"kind\": \"lane\"}], \"devices\": [{\"id\": 50, \"kind\": \"regulatory_sign\", \"code\": \"bicycles_prohibited\", \"governs_sidewalk\": [22]}]}]}" with
  | .ok τ => (Admission.defects τ Q.zero).length == 1
  | .error _ => false)

-- the hand-written trace check names a region a record names only where it is in the scene
#guard (TraceLint.checkReferences [scene places [{ noBikes with governsSidewalk := some [99] }]]).length = 1
#guard TraceLint.checkReferences [signs] = []

-- a legend's angle: stated, confirmed none, not recorded
#guard dev_regulatory_sign_legend_angle signs 53 = some (q 60)
#guard dev_regulatory_sign_legend_angle signs 54 = none
#guard dev_regulatory_sign_legend_angle signs 55 = none
#guard dev_regulatory_sign_legend_angle_stated signs 53 = some true
#guard dev_regulatory_sign_legend_angle_stated signs 54 = some false
#guard dev_regulatory_sign_legend_angle_stated signs 55 = none
#guard measureV signs "dev_regulatory_sign_legend_angle" [.v 53] = some (q 60)
#guard measureV signs "dev_regulatory_sign_legend_angle" [.v 54] = none
#guard atomV signs "dev_regulatory_sign_legend_angle_stated" [.v 54] = some (some false)
#guard atomV signs "dev_regulatory_sign_legend_angle_stated" [.v 55] = some none
def legendJson (v : String) : String :=
  s!"\{\"t\": 0, \"devices\": [\{\"id\": 53, \"kind\": \"regulatory_sign\", \"code\": \"angle_parking\"{if v.isEmpty then "" else s!", \"legend_angle\": {v}"}}]}"
#guard dev_regulatory_sign_legend_angle (decodeScene (legendJson "45")) 53 = some (q 45)
#guard dev_regulatory_sign_legend_angle_stated (decodeScene (legendJson "\"none\"")) 53 = some false
#guard dev_regulatory_sign_legend_angle_stated (decodeScene (legendJson "")) 53 = none
#guard dev_regulatory_sign_legend_angle_stated (decodeScene (legendJson "null")) 53 = none
#guard decodes (legendJson "\"none\"")
#guard !decodes (legendJson "\"sixty\"")
#guard !decodes (legendJson "true")
#guard (Dimensions.ofMeasure).lookup "dev_regulatory_sign_legend_angle" = some ⟨0, 0, 1, 0⟩
-- the angle and the boolean never disagree: stated exactly when an angle is recorded, false only on a
-- confirmed `none` (the angle unknown then), both unknown when nothing is recorded
def agree (s : Scene) (d : DeviceId) : Bool :=
  match dev_regulatory_sign_legend_angle_stated s d, dev_regulatory_sign_legend_angle s d with
  | some true, some _ => true
  | some false, none => true
  | none, none => true
  | _, _ => false
#guard [53, 54, 55, 50, 99].all (agree signs)
#guard ["45", "0", "\"none\"", "null", ""].all fun v => agree (decodeScene (legendJson v)) 53
#guard [53, 54, 55].all (agree (mask (without "dev.regulatory_sign") signs))

-- a space's angle marking: confirmed, confirmed not, not recorded
#guard st_parking_space_angle_marking signs 23 = some true
#guard st_parking_space_angle_marking signs 24 = some false
#guard st_parking_space_angle_marking signs 25 = none
#guard atomV signs "st_parking_space_angle_marking" [.v 24] = some (some false)
#guard atomV signs "st_parking_space_angle_marking" [.v 25] = some none
#guard st_parking_space_angle_marking (decodeScene "{\"t\": 0, \"structures\": [{\"id\": 23, \"kind\": \"parking_space\", \"angle_marking\": false}]}") 23 = some false
#guard st_parking_space_angle_marking (decodeScene "{\"t\": 0, \"structures\": [{\"id\": 23, \"kind\": \"parking_space\"}]}") 23 = none

-- a space's axis: read normalised; the zero vector and an unrecorded axis read unknown
#guard measureV signs "st_parking_space_axis" [.v 23, .s "x"] = some Q.zero
#guard measureV signs "st_parking_space_axis" [.v 23, .s "y"] = some (q 1)
#guard measureV signs "st_parking_space_axis" [.v 24, .s "x"] = none
#guard measureV signs "st_parking_space_axis" [.v 25, .s "y"] = none
#guard measureV signs "st_parking_space_axis" [.v 23] = none
#guard (measureV (decodeScene "{\"t\": 0, \"structures\": [{\"id\": 23, \"kind\": \"parking_space\", \"axis\": [-3, 0]}]}") "st_parking_space_axis" [.v 23, .s "x"]) = some (q 1)

-- the axis is read undirected: of v and -v, the one with y positive, or y zero and x positive
#guard Geom.undirected (q 1, q (-2)) = (q (-1), q 2)
#guard Geom.undirected (q (-1), q 2) = (q (-1), q 2)
#guard Geom.undirected (q (-3), q 0) = (q 3, q 0)
#guard Geom.undirected (q 3, q 0) = (q 3, q 0)
#guard Geom.undirected (q 0, q 0) = (q 0, q 0)
def axisAt (v : Vec) : Scene :=
  scene [{ id := 23, kind := .parkingSpace, parkingAxis := some v }, { id := 22, kind := .lane, lane := some { direction := some (q 1, q 0) } }]
def axisReads (v : Vec) : List (Option Q) := ["x", "y"].map fun k => measureV (axisAt v) "st_parking_space_axis" [.v 23, .s k]
#guard [(q 1, q 1), (q 2, q (-3)), (q (-5), q 0), (q 0, q 7)].all fun (x, y) => axisReads (x, y) == axisReads (Q.neg x, Q.neg y)
#guard axisReads (q 0, q 0) = [none, none]
-- a formula comparing the axis with a lane's direction gives the same verdict for v and -v
def term (m r k : String) : Term := .measure m [.var r, .lit k]
def alongLane : Formula :=
  .cmp (.add (.mul (term "st_parking_space_axis" "p" "x") (term "st_lane_direction" "l" "x"))
             (.mul (term "st_parking_space_axis" "p" "y") (term "st_lane_direction" "l" "y")))
       .ge (.lit (Q.mk' 1 2) .ratio)
def verdicts (v : Vec) : List Bool × List Bool × List Bool :=
  let rs := (Semantics.evalAll (Semantics.SemCtx.mk' [axisAt v] {} (({} : Binding).bind "p" (.region 23) |>.bind "l" (.region 22))) alongLane).toList
  (rs.map (·.v == .t), rs.map (·.v == .f), rs.map (·.v == .u))
#guard verdicts (q 1, q 1) == verdicts (q (-1), q (-1)) && verdicts (q 1, q 1) == ([true], [false], [false])
#guard verdicts (q 2, q 0) == verdicts (q (-2), q 0) && verdicts (q 2, q 0) == ([true], [false], [false])
#guard verdicts (q 1, q (-4)) == verdicts (q (-1), q 4) && verdicts (q 1, q (-4)) == ([false], [true], [false])
#guard verdicts (q 0, q 0) == ([false], [false], [true])
#guard (Dimensions.ofMeasure).lookup "st_parking_space_axis" = some ⟨0, 0, 0, 0⟩

-- masking: each unknown where the manifest does not supply its atom
#guard dev_governs_sidewalk (mask (without "dev.governs_sidewalk") signs) 50 20 = none
#guard dev_governs_sidewalk (mask (without "dev.governs_parking_space") signs) 50 20 = some true
#guard dev_governs_parking_space (mask (without "dev.governs_parking_space") signs) 53 23 = none
#guard dev_governs_parking_space (mask (without "dev.governs") signs) 53 23 = some true
#guard dev_regulatory_sign_legend_angle_stated (mask (without "dev.regulatory_sign") signs) 54 = none
#guard dev_regulatory_sign_legend_angle_stated (mask (Manifest.full "t") signs) 54 = some false
#guard st_parking_space_angle_marking (mask (without "st.parking_space") signs) 24 = none
#guard st_parking_space_axis (mask (without "st.parking_space") signs) 23 = none
#guard st_parking_space_angle_marking (mask (without "st.sidewalk") signs) 24 = some false

-- the region kinds Core declares: a sidewalk, a parking space
#guard TraceLint.regionArgKinds.lookup ("dev_governs_sidewalk", 1) = some (some [.sidewalk])
#guard TraceLint.regionArgKinds.lookup ("dev_governs_parking_space", 1) = some (some [.parkingSpace])
#guard TraceLint.regionArgKinds.lookup ("st_parking_space_angle_marking", 0) = some none
#guard TraceLint.regionArgKinds.lookup ("st_parking_space_axis", 0) = some none
#guard Semantics.atomArgSorts "dev_governs_sidewalk" = some [some .device, some .region]
#guard Semantics.atomArgSorts "dev_governs_parking_space" = some [some .device, some .region]

end TrafficSpec.Tests.SignedPlaces
