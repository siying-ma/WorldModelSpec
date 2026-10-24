/-
  drv.control.intersection_controlled — The intersection the road user is at is under the control of a device at the observation: there is an intersection region which the road user's footprint overlaps, or which a lane the road user's footprint overlaps runs into at its end, and a signal head, a stop sign, a yield sign or a point regulatory sign governs that lane or that intersection region. It is a configuration at an instant, read from the road user's lane and region membership, from the intersection a lane runs into, and from the traffic a device faces. It says nothing about what the device displays - a dark, covered or inoperative head governs its approach exactly as a lit one does - nothing about whether the device governs the road user's own approach rather than another, nothing about which movements the device permits or forbids, and nothing about whether a public authority placed it: the device's presence beside the approach is what the scene shows. It is not the state of a signal, not a pavement marking, not a warning or zone sign standing along the road, and not a person directing traffic.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    there is an intersection region: atoms ['st.intersection'], concepts []
    which the road user's footprint overlaps, or which a lane the road user's footprint overlaps: atoms ['rel.occupies', 'st.lane'], concepts []
    runs into at its end: atoms ['st.lane_enters'], concepts []
    a signal head, a stop sign, a yield sign or a point regulatory sign: atoms ['dev.traffic_signal', 'dev.stop_sign', 'dev.yield_sign', 'dev.regulatory_sign'], concepts []
    governs that lane or that intersection region: atoms ['dev.governs'], concepts []

  How each element is written:

    "there is an intersection region" — an existential over the scene's intersection regions, the
    bound region read as an intersection (`st_intersection ix`) rather than taken from the
    quantifier's kind, so a region whose kind the source cannot tell leaves the conjunct unknown
    instead of silently true. Everything else in the body is read of that one region, so the
    junction the device controls is the junction the road user is at. The road user may be at
    more than one junction (a short block between two); "the intersection the road user is at"
    is read as "some intersection it is at", which is what an existential says.

    "which the road user's footprint overlaps, or which a lane the road user's footprint overlaps"
    — the two memberships the contract names, both through `rel_occupies`: the footprint overlaps
    the intersection region itself (`rel_occupies u ix`), or it overlaps a lane (`st_lane ln`, read
    of the bound region, and `rel_occupies u ln`). The lane is bound by a second existential, over
    the scene's lane regions, inside the first.

    "runs into at its end" — `st_lane_enters ln ix`: the intersection the lane is an approach to is
    the intersection bound above. The lane the road user stands in and the junction it is at are
    thereby the same junction; nothing reads where along the lane the road user is, and nothing
    reads a halting place.

    "a signal head, a stop sign, a yield sign or a point regulatory sign" — four existentials, one
    per device kind, each over the scene's devices of that kind and each reading the kind of the
    bound device (`dev_traffic_signal d`, `dev_stop_sign d`, `dev_yield_sign d`,
    `dev_regulatory_sign d`), so a device whose kind the source cannot tell leaves its disjunct
    unknown rather than false. Nothing of what a device shows, carries or forbids is read: no
    indication, no sign code, no `dev.inoperative`, no `dev.traffic_signal.uncovered`. A warning or
    zone sign, a railway signal, a temporary control and a person directing traffic are excluded by
    the kinds themselves: no quantifier here ranges over them.

    "governs that lane or that intersection region" — `dev_governs d ix` for the intersection
    region and `dev_governs d ln` for the approach lane the road user stands in, the two regions
    the contract names. The disjunction is written once over each of the two sites:
    `intersectionGoverned` is "the road user is at the junction (in it, or on an approach to it)
    and a device governs the junction region", `approachGoverned` is "the road user's own approach
    lane runs into the junction and a device governs that lane".

  Nothing about what the device displays, about which movements it permits, about who placed it,
  about a pavement marking, or about where in the lane the road user stands is written: the
  contract and the residue exclude them.

  No magnitude below is this file's own: parameters are formals the caller fills. The body
  declares none, and reads no quantity at all.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.control.intersection_controlled

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The intersection region, bound inside the body and anchored to the formal by `rel_occupies`
    (directly, or through the approach lane the road user's footprint overlaps). -/
def aIx : Arg := .var "ix"
/-- The approach lane, anchored to the formal by `rel_occupies` and to the junction by
    `st_lane_enters`. -/
def aLn : Arg := .var "ln"
/-- The device, anchored to the junction or to the approach lane by `dev_governs`. -/
def aDev : Arg := .var "d"

/-- A signal head governing the region. -/
def signalHeadGoverns (r : Arg) : Formula :=
  .existsDevice (.lit "traffic_signal") "d"
    (.and (.atom "dev_traffic_signal" [aDev] [])
      (.atom "dev_governs" [aDev, r] []))

/-- A stop sign governing the region. -/
def stopSignGoverns (r : Arg) : Formula :=
  .existsDevice (.lit "stop_sign") "d"
    (.and (.atom "dev_stop_sign" [aDev] [])
      (.atom "dev_governs" [aDev, r] []))

/-- A yield sign governing the region. -/
def yieldSignGoverns (r : Arg) : Formula :=
  .existsDevice (.lit "yield_sign") "d"
    (.and (.atom "dev_yield_sign" [aDev] [])
      (.atom "dev_governs" [aDev, r] []))

/-- A point regulatory sign governing the region. -/
def regulatorySignGoverns (r : Arg) : Formula :=
  .existsDevice (.lit "regulatory_sign") "d"
    (.and (.atom "dev_regulatory_sign" [aDev] [])
      (.atom "dev_governs" [aDev, r] []))

/-- A signal head, a stop sign, a yield sign or a point regulatory sign governs the region. -/
def deviceGoverns (r : Arg) : Formula :=
  .or (signalHeadGoverns r)
    (.or (stopSignGoverns r)
      (.or (yieldSignGoverns r) (regulatorySignGoverns r)))

/-- The road user's footprint overlaps the intersection region. -/
def inIntersection : Formula :=
  .atom "rel_occupies" [aU, aIx] []

/-- `ln` is a lane the road user's footprint overlaps, and it runs into the intersection region at
    its end. -/
def approachLane : Formula :=
  .and (.atom "st_lane" [aLn] [])
    (.and (.atom "rel_occupies" [aU, aLn] [])
      (.atom "st_lane_enters" [aLn, aIx] []))

/-- The road user is at the intersection: its footprint overlaps the junction region itself, or it
    overlaps a lane that runs into that junction at its end. -/
def atIntersection : Formula :=
  .or inIntersection (.existsRegion (.lit "lane") "ln" approachLane)

/-- The road user is at the junction and a device governs that intersection region. -/
def intersectionGoverned : Formula :=
  .and atIntersection (deviceGoverns aIx)

/-- The road user's own approach lane runs into the junction and a device governs that lane. -/
def approachGoverned : Formula :=
  .existsRegion (.lit "lane") "ln"
    (.and approachLane (deviceGoverns aLn))

def body : Formula :=
  .existsRegion (.lit "intersection") "ix"
    (.and (.atom "st_intersection" [aIx] [])
      (.or intersectionGoverned approachGoverned))

def concept : Concept :=
  { id := "drv.control.intersection_controlled"
    contract := "The intersection the road user is at is under the control of a device at the observation: there is an intersection region which the road user's footprint overlaps, or which a lane the road user's footprint overlaps runs into at its end, and a signal head, a stop sign, a yield sign or a point regulatory sign governs that lane or that intersection region. It is a configuration at an instant, read from the road user's lane and region membership, from the intersection a lane runs into, and from the traffic a device faces. It says nothing about what the device displays - a dark, covered or inoperative head governs its approach exactly as a lit one does - nothing about whether the device governs the road user's own approach rather than another, nothing about which movements the device permits or forbids, and nothing about whether a public authority placed it: the device's presence beside the approach is what the scene shows. It is not the state of a signal, not a pavement marking, not a warning or zone sign standing along the road, and not a person directing traffic."
    definition := none
    args := [("u", .track)]
    params := []
    body := .formula body
    residues := ["a pavement marking is not read: no atom relates a marking to the intersection it would control, and st.lane_marking carries only the line beside a lane"]  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "there is an intersection region"
          why := "Written as an existential over the scene's intersection regions, with the bound region read as an intersection (st.intersection) rather than taken from the quantifier's kind. 'The intersection the road user is at' is read as 'some intersection it is at': a road user on a short block may stand in one lane that is an approach to one junction, and the concept holds where some such junction is controlled. Every other element is read of that one bound region."
          kind := "reading" }
      , { span := "which the road user's footprint overlaps, or which a lane the road user's footprint overlaps runs into at its end"
          why := "Both memberships are read through rel.occupies, the ontology's footprint overlap, and the approach through st.lane_enters, the intersection a lane runs into at its end. Where the road user's footprint overlaps several lanes, 'a lane' is read as 'some lane it overlaps'. Nothing reads how far along the lane it stands, which way the lane runs, or whether it faces the junction: the contract leaves those out and no atom of the record carries them."
          kind := "reading" }
      , { span := "governs that lane or that intersection region"
          why := "'That lane' is read as the road user's own approach lane - the lane the footprint overlaps and that runs into the junction - and 'that intersection region' as the junction region itself, the two regions the contract names. A device governing only some other approach of the junction, and no part of the junction region, is not read. The contract's exclusion 'nothing about whether the device governs the road user's own approach rather than another' is honoured by the second half of the disjunction: a device that governs the junction region satisfies the concept whichever approach it faces, and which traffic it faces inside that region is never read."
          kind := "reading" }
      , { span := "a signal head, a stop sign, a yield sign or a point regulatory sign"
          why := "Written as four existentials, one per device kind of the record, each reading the kind of the bound device so that a device whose kind the source cannot tell leaves its disjunct unknown rather than false. Nothing a device shows or carries is read - no indication, no sign code, no inoperative or covered flag - so a dark, covered or inoperative head governs its approach exactly as a lit one does."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.control.intersection_controlled
