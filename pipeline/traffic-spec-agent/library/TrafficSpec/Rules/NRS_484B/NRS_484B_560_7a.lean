/-
  NRS_484B_560_7a — NRS-484B-560-7a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): It is unlawful for the driver of any vehicle:
    s2 (trigger): When crossing at grade any track or tracks of a railroad,
    s3 (obligation): to fail to completely cross the track or tracks without stopping due to insufficient: (1) Space for the vehicle on the opposite side of the railroad crossing; or (2) Undercarriage clearance of the vehicle.
    s4 (definitional): As used in this section, “completely cross” means to travel across a railroad track or tracks in such a manner that the trailing end of the vehicle is 15 feet or more past the nearest rail of the railroad track or tracks.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.railway_crossing', 'st.region_geometry'], derived ['drv.position.within_clearance_since_entry', 'drv.motion.entering_region']
    s3: atoms ['kin.speed', 'dev.human_direction', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived ['drv.motion.halted']
    s4: atoms ['st.region_geometry', 'st.railway_crossing', 'rel.occupies'], derived ['drv.position.within_clearance_since_entry']

  Literals the text states (each written through its Units constructor):
    s4: 15 ft — 15 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    s1: the class of x is `ru_aggregate x "DEF-NRS-484A-320::vehicle"`; the driver is read through
        the vehicle's controlled motion (the record's observable reading), so no further atom.
    s2 + s4: some railway crossing r (`existsRegion "railway_crossing"`, which reads
        st.railway_crossing) such that `drv.position.within_clearance_since_entry(x, r)` with the
        clearance the literal 15 ft of s4. The concept carries the entry
        (drv.motion.entering_region over rel.occupies) and the body-outline distance
        (st.region_geometry), so r is the subject's own crossing, anchored through x. The entry
        the element names (drv.motion.entering_region) is written beside it as a disjunct: x is
        crossing r from the observation it enters r until it has completely crossed it. By the
        concept's contract the entry already makes the clearance state true, so the disjunct
        states the element's words and changes no instant.
    s3: x is not halted (`drv.motion.halted` with speed_floor p.speed_resolution, over kin.speed),
        or a human direction d with role police_officer and indication stop governs
        (dev.governs) a travel region l (st.travel_region) x's footprint overlaps (rel.occupies)
        at that observation — the definition-of-stopping exception the record reads. The
        obligation names no crossing of its own, as the record states.

  No choice was left open beyond the record's narrowings; this file adds none.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_560_7a

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pSpeedResolution : Term := .param "p.speed_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- s4: “15 feet or more past the nearest rail” — the text's literal. -/
def completeClearance : Term := .lit (Units.feet 15) .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s2 (trigger): When crossing at grade any track or tracks of a railroad, -/
def applicability : Formula :=
  .existsRegion (.lit "railway_crossing") "r"
    (.or (.derived "drv_motion_entering_region" [vX, .var "r"] [])
      (.derived "drv_position_within_clearance_since_entry" [vX, .var "r"] [completeClearance]))

/-- s3: a police officer's direction to stop governing a travel region x's footprint overlaps. -/
def policeDirectsStop : Formula :=
  .existsDevice (.lit "human_direction") "d"
    (.and (.atom "dev_human_direction_role" [.var "d", .lit "police_officer"] [])
      (.and (.atom "dev_human_direction_indication" [.var "d", .lit "stop"] [])
        (.existsRegion (.lit "travel_region") "l"
          (.and (.atom "dev_governs" [.var "d", .var "l"] [])
            (.atom "rel_occupies" [vX, .var "l"] [])))))

/-- Obligation: s3 (obligation): to fail to completely cross the track or tracks without stopping due to insufficient: (1) Space for the vehicle on the opposite side of the railroad crossing; or (2) Undercarriage clearance of the vehicle. -/
def obligation : Formula :=
  .or (.not (.derived "drv_motion_halted" [vX] [pSpeedResolution])) policeDirectsStop

def rule : Rule :=
  { id := "NRS_484B_560_7a"
    laws := ["NRS-484B-560-7a"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_560_7a
