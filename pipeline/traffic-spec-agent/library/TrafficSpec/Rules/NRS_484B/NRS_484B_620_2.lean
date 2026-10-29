/-
  NRS_484B_620_2 — NRS-484B-620-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    f1 (trigger): After the establishment of a speed zone and the installation of appropriate signs to control speed,
    f2 (subject): it is unlawful for any person to drive a motor vehicle
    f3 (condition): upon the road
    f4 (condition): and in the speed zone
    f5 (obligation): in excess of the speed therein authorized.

  Elements (span → atoms, derived):
    f1: atoms ['dev.zone_sign', 'dev.speed_limit_sign', 'dev.governs', 'rel.occupies', 'st.roadway', 'st.lane', 'st.on_way', 'st.highway'], derived []
    f2: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle', 'kin.speed'], derived []
    f4: atoms ['dev.zone_sign', 'dev.governs', 'rel.occupies', 'st.roadway', 'st.lane', 'st.on_way'], derived []
    f5: atoms ['kin.speed', 'dev.speed_limit_sign', 'dev.governs', 'rel.occupies', 'st.roadway'], derived []

  How each span is written.

    f2 (subject), class of `m`: the single atom `ru_aggregate` with the admitted aggregate id
      `DEF-NRS-484A-130::motor_vehicle` as its literal argument; the classes it covers are never
      written here. 'any person to drive' is the record's observable reading through the vehicle's
      controlled motion, written as `kin_speed m > 0` (zero is the only magnitude in this file).

    f3 (condition), 'upon the road': the node's assumption `asm.outside_city_limits`, as `.asm`.

    f1 (trigger) and f4 (condition), the established zone and its installed signs: one travel
      region `r` the subject occupies (`rel_occupies m r`), of a kind the element names —
      `st_roadway r` or `st_lane r`; since `lane` refines no roadway kind, the two kinds are two
      region quantifiers, one per kind, and `isTravelRegion` states the element's disjunction
      inside each. `st_on_way r w` with `st_highway w` ties that region to the way it lies on.
      `dev_zone_sign z` of `dev_zone_sign_kind z speed_zone` with `dev_governs z r` is the zone
      established on that stretch; `dev_speed_limit_sign d` with `dev_governs d r`, of a kind that
      states a maximum, is the appropriate sign installed to control speed there. No distance from a
      sign head is read: the zone is the regions its sign governs, as the record says.

    f5 (obligation), 'in excess of the speed therein authorized': `kin_speed m` is not above
      `dev_speed_limit_sign_value d` for the installed maximum-stating sign governing the travel
      region the subject occupies. The region selection of f1/f4 is written again in the duty, so
      that it denotes the same region, and the duty is stated at every selected region and for
      every such sign governing it (the narrowing below).

  Narrowing declared on f5 (the duty span): 'the speed therein authorized' is written as every
  installed speed limit sign stating a maximum that governs the travel region the subject occupies,
  so the duty is the lowest of them; the record's words name 'that sign' in the singular and leave
  the case of several governing signs open.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_620_2

/-- The binders, as arguments (order and names are the node's). -/
def vM : Arg := .var "m"

def zeroSpeed : Term := .lit Q.zero .metrePerSecond

/-- Class of `m`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsM : Formula :=
  .atom "ru_aggregate" [vM, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- f2: the vehicle is in controlled motion. -/
def inMotion : Formula := .cmp (.measure "kin_speed" [vM]) .gt zeroSpeed

/-- f1/f4: the travel region kinds the elements name. -/
def isTravelRegion (r : String) : Formula :=
  .or (.atom "st_roadway" [.var r] []) (.atom "st_lane" [.var r] [])

/-- f1/f4: the travel region `r` lies on a way. -/
def onAWay (r : String) : Formula :=
  .existsRegion (.lit "highway") "w"
    (.and (.atom "st_highway" [.var "w"] [])
          (.atom "st_on_way" [.var r, .var "w"] []))

/-- f1/f4: a zone sign of the speed_zone kind governs `r`. -/
def zoneSignGoverns (r : String) : Formula :=
  .existsDevice (.lit "zone_sign") "z"
    (.and (.atom "dev_zone_sign" [.var "z"] [])
      (.and (.atom "dev_zone_sign_kind" [.var "z", .lit "speed_zone"] [])
            (.atom "dev_governs" [.var "z", .var r] [])))

/-- f1/f5: `d` is a speed limit sign stating a maximum and governing `r`. -/
def maximumSignGoverns (d r : String) : Formula :=
  .and (.atom "dev_speed_limit_sign" [.var d] [])
    (.and (.or (.atom "dev_speed_limit_sign_kind" [.var d, .lit "maximum"] [])
            (.or (.atom "dev_speed_limit_sign_kind" [.var d, .lit "zone"] [])
                 (.atom "dev_speed_limit_sign_kind" [.var d, .lit "structure_maximum"] [])))
          (.atom "dev_governs" [.var d, .var r] []))

/-- f1/f4: `m` occupies the travel region `r`, on a way, that a speed zone's sign governs. -/
def inSignedZone (r : String) : Formula :=
  .and (isTravelRegion r)
    (.and (.atom "rel_occupies" [vM, .var r] [])
      (.and (onAWay r) (zoneSignGoverns r)))

/-- f1/f4: and a speed limit sign stating a maximum is installed for that stretch. -/
def zoneEngaged (r : String) : Formula :=
  .and (inSignedZone r)
    (.existsDevice (.lit "speed_limit_sign") "d" (maximumSignGoverns "d" r))

/-- Applicability: f1 (trigger): After the establishment of a speed zone and the installation of appropriate signs to control speed,; f3 (condition): upon the road; f4 (condition): and in the speed zone -/
def applicability : Formula :=
  .and (.asm "asm.outside_city_limits")
    (.and inMotion
      (.or (.existsRegion (.lit "roadway") "r" (zoneEngaged "r"))
           (.existsRegion (.lit "lane") "r" (zoneEngaged "r"))))

/-- f5, at one selected travel region: no installed maximum the subject's speed exceeds. -/
def dutyAt (r : String) : Formula :=
  .implies (inSignedZone r)
    (.forallDevice (.lit "speed_limit_sign") "d"
      (.implies (maximumSignGoverns "d" r)
        (.cmp (.measure "kin_speed" [vM]) .le
              (.measure "dev_speed_limit_sign_value" [.var "d"]))))

/-- Obligation: f5 (obligation): in excess of the speed therein authorized. -/
def obligation : Formula :=
  .and (.forallRegion (.lit "roadway") "r" (dutyAt "r"))
       (.forallRegion (.lit "lane") "r" (dutyAt "r"))

def rule : Rule :=
  { id := "NRS_484B_620_2"
    laws := ["NRS-484B-620-2"]
    binders :=
      [ { name := "m", cls := clsM } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.outside_city_limits"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "f5"
          why := "'the speed therein authorized' is written as every installed speed limit sign stating a maximum that governs the travel region the subject occupies, and the duty is stated at each such region: where several such signs govern the stretch the lowest stated value binds. The words name 'that sign' in the singular and do not say which value binds when more than one maximum is installed for the stretch."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_620_2
