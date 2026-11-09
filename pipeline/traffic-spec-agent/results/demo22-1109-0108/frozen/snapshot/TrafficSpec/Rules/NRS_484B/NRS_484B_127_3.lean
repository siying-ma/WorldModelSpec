/-
  NRS_484B_127_3 — NRS-484B-127-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Motor vehicles being driven upon any highway
    s2 (condition): outside of a business district
    s3 (trigger): in a caravan or motorcade,
    s4 (condition): whether or not towing other vehicles,
    s5 (obligation): shall be operated to allow sufficient space between each such vehicle or combination of vehicles
    s6 (standard): so as to enable any other vehicle or combination of vehicles to enter and occupy such space without danger.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle', 'st.highway', 'rel.occupies'], derived ['drv.motion.standstill']
    s3: atoms [], derived ['drv.interaction.vehicle_file']
    s5: atoms ['rel.surface_gap', 'rel.ahead_behind_in_lane', 'ru.aggregate=DEF-NRS-484A-130::motor_vehicle', 'ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles'], derived ['drv.interaction.vehicle_file']

  How each span is written:

    s1 — the binder's class is `ru_aggregate` with the admitted aggregate id
      DEF-NRS-484A-130::motor_vehicle (never the class atom `ru.motor_vehicle`). “being driven” is
      the negation of `drv.motion.standstill` at the observation, the plan's observable reading of
      the words. “upon any highway” is a region quantifier over the kind `st.highway` whose body
      anchors it to the subject with `rel.occupies`: the way the subject's footprint overlaps, not
      any way of the scene.
    s2 — `asm.outside_business_district`, conjoined into the applicability, so that an undeclared
      district leaves whether the rule applies unknown.
    s3 — `drv.interaction.vehicle_file` on the subject with the file's three parameters; the
      concept carries “travelling one behind another”, and the motion of the file is stated by s1.
    s4 — residue (the record's): nothing in the applicability or the obligation reads these words,
      and the members of the file are read whether or not any of them draws another vehicle.
    s5 — the duty is read over the road users of the subject's own file: `rel_ahead_behind_in_lane`
      in either direction (the atom is “a is ahead of b in the same lane”, so both orders are
      written) and, for membership of the file, the space between the bodies within the file's
      reach, `p.caravan_max_member_gap`, as the concept measures it. “vehicle or combination of
      vehicles” is the disjunction of the two admitted aggregates on the member.
    s6 — the operationalization: the longitudinal component of `rel.surface_gap` between the
      subject's body and the member's must hold an entering vehicle's length plus a clear headway
      in front of and behind it at the subject's speed. The headway term is written twice (fore and
      aft) because this file may carry no figure of its own, not even a factor of two. The design
      length `p.entry_vehicle_length` is the floor; where a road user that is no member of the
      subject's file is in the scene, its own read length (`kin.extent`, read as the full length)
      must also fit, which is the greater of the two the convention names.

  Narrowings declared below (readings this session chose; the record's own are not restated):
    s5 — “each such vehicle or combination of vehicles” is written as every member of the subject's
      file that lies ahead of or behind it in the same lane and within the file's reach. The space
      to the nearest such member is the binding one, since the space to a member further along the
      file is larger, so this states the record's “immediately ahead of and behind” duty; a further
      member is read as the same bound and never as a weaker one.
    s6 — “any other vehicle or combination of vehicles” whose length is read is every road user of
      the scene that is neither the subject nor a member of the subject's file; where several are
      present the bound holds for each, which is the greater length the convention names. The
      length is read where it is observed, and `p.entry_vehicle_length` remains the floor.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_127_3

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCaravanMaxMemberGap : Term := .param "p.caravan_max_member_gap"
def pCaravanMinMembers : Term := .param "p.caravan_min_members"
def pEntryClearanceHeadwayTime : Term := .param "p.entry_clearance_headway_time"
def pEntryVehicleLength : Term := .param "p.entry_vehicle_length"
def pSameDirectionCosineTolerance : Term := .param "p.same_direction_cosine_tolerance"
def pStandstillSpeedTolerance : Term := .param "p.standstill_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsV : Formula :=
  .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- s1: “being driven” — the subject is not at a standstill at the observation. -/
def beingDriven : Formula :=
  .not (.derived "drv_motion_standstill" [vV] [pStandstillSpeedTolerance])

/-- s1: “upon any highway” — the subject's footprint overlaps a highway. -/
def uponHighway : Formula :=
  .existsRegion (.lit "highway") "hw" (.atom "rel_occupies" [vV, .var "hw"] [])

/-- s3: “in a caravan or motorcade” — the subject is one of a file of road users travelling one
    behind another. -/
def inFile : Formula :=
  .derived "drv_interaction_vehicle_file" [vV]
    [pCaravanMinMembers, pCaravanMaxMemberGap, pSameDirectionCosineTolerance]

/-- Applicability: s2 (condition): outside of a business district; s3 (trigger): in a caravan or motorcade,; s4 (condition): whether or not towing other vehicles, -/
def applicability : Formula :=
  .and beingDriven
    (.and uponHighway
      (.and inFile (.asm "asm.outside_business_district")))

/-- s6: the clear headway in front of or behind an entering vehicle, at the speed of the file. -/
def clearanceHeadway : Term :=
  .mul pEntryClearanceHeadwayTime (.measure "kin_speed" [vV])

/-- s5: the space between the subject's body and `w`'s — the longitudinal component of the gap
    between the nearest points of the two bodies. -/
def spaceTo (w : String) : Term :=
  .measure "rel_surface_gap" [vV, .var w, .lit "longitudinal"]

/-- s5: `w` is a member of the subject's file — ahead of or behind the subject in the same lane
    and within the file's reach of it, the reach measured between the nearest points of the
    bodies. -/
def fileNeighbour (w : String) : Formula :=
  .and
    (.or (.atom "rel_ahead_behind_in_lane" [vV, .var w] [])
         (.atom "rel_ahead_behind_in_lane" [.var w, vV] []))
    (.cmp (.measure "rel_surface_gap" [vV, .var w]) .le pCaravanMaxMemberGap)

/-- s5: “such vehicle or combination of vehicles” — the member is of either admitted aggregate. -/
def memberClass (w : String) : Formula :=
  .or (.atom "ru_aggregate" [.var w, .lit "DEF-NRS-484A-130::motor_vehicle"] [])
      (.atom "ru_aggregate" [.var w, .lit "DEF-NRS-484A-050::combination_of_vehicles"] [])

/-- s6: the space holds the design vehicle's length and a clear headway fore and aft. -/
def admitsDesignVehicle (w : String) : Formula :=
  .cmp (spaceTo w) .ge
    (.add pEntryVehicleLength (.add clearanceHeadway clearanceHeadway))

/-- s6: the space holds the read length of every road user of the scene that is neither the
    subject nor a member of its file, with the same headway fore and aft. -/
def admitsEnteringUser (w : String) : Formula :=
  .forallUser "e"
    (.implies
      (.and (.not (.same (.var "e") vV)) (.not (fileNeighbour "e")))
      (.cmp (spaceTo w) .ge
        (.add (.measure "kin_extent" [.var "e", .lit "length"])
              (.add clearanceHeadway clearanceHeadway))))

/-- Obligation: s5 (obligation): shall be operated to allow sufficient space between each such vehicle or combination of vehicles; s6 (standard): so as to enable any other vehicle or combination of vehicles to enter and occupy such space without danger. -/
def obligation : Formula :=
  .forallUser "w"
    (.implies (.and (memberClass "w") (fileNeighbour "w"))
      (.and (admitsDesignVehicle "w") (admitsEnteringUser "w")))

def rule : Rule :=
  { id := "NRS_484B_127_3"
    laws := ["NRS-484B-127-3"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.outside_business_district"]
    intentions := []
    operationalizations :=
      [ { standard := "so as to enable any other vehicle or combination of vehicles to enter and occupy such space without danger"
          concepts := ["drv.interaction.vehicle_file", "kin.extent", "kin.speed", "rel.surface_gap"]
          params := ["p.entry_vehicle_length", "p.entry_clearance_headway_time"]
          convention := "Gap-acceptance convention for a lane-change entry (the critical-gap family used in capacity and merging analysis): a space admits an entering vehicle where it holds the vehicle's own length plus a clear headway in front of and behind it at the speed of the stream. The space is sufficient at an observation where the longitudinal component of rel.surface_gap between the subject and the adjacent member of the file is at least p.entry_vehicle_length + 2 × p.entry_clearance_headway_time × kin.speed of the subject. kin.extent, “the body's size along its axes … a formula reads the full length, width and height, twice each”, is what p.entry_vehicle_length stands for: where a road user that is not a member of the file is in the scene, the length in the bound is the greater of p.entry_vehicle_length and that road user's own read length, so the degree of the factor is read where it is observed and the design length is the floor, never a reduction of the space owed. kin.speed scales the clearance term, so the space required grows with the speed of the file. “without danger” is bounded by those clearances and by nothing else; both magnitudes are parameters of the reading, and the law states no figure."
          surrogate := false } ]
    residues := ["“whether or not towing other vehicles” imposes no condition: it states that the duty is the same for a member drawing another vehicle and for one that is not, so no verdict of the node turns on these words. The rule is held to that: the applicability reads nothing from them, and the members of the file are read whether or not any of them draws another vehicle."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s5"
          why := "“each such vehicle or combination of vehicles” is written as every member of the subject's file that lies ahead of or behind it in the same lane (rel.ahead_behind_in_lane in either order) and within the file's reach of it (the space between the bodies at most p.caravan_max_member_gap, the reach the file concept uses). The space to the nearest such member is the binding one, since the space to a member further along the file is larger; a further member carries the same bound and never a weaker one, so the duty states the record's “immediately ahead of and behind” reading without an operator for “immediately”."
          kind := "reading" }
      , { span := "s6"
          why := "“any other vehicle or combination of vehicles” whose length the bound reads is every road user of the scene that is neither the subject nor a member of the subject's file; where several are present, the space must hold each of them, which is the greater length the convention names. The clear headway is written as the headway term twice, fore and aft, because no figure of this file's own — not even a factor of two — may enter a formula."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_127_3
