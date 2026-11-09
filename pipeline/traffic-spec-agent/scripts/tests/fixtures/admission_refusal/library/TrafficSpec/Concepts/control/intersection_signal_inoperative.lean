/-
  drv.control.intersection_signal_inoperative — The road user is at an intersection whose traffic a signal head controls, and that head is installed with its faces not covered and shows no valid indication at the observation: there is an intersection region which the road user's footprint overlaps, or which a lane the road user's footprint overlaps runs into at its end, and there is a signal head whose faces are not covered, which governs that intersection region or governs a lane that runs into that intersection region, and which is inoperative - installed and uncovered but showing no valid indication. The concept is a configuration at an instant, read from the road user's region and lane membership, from the intersection a lane runs into, from the travel regions the head controls and from the head's own state. It says nothing about which approach of the junction the head stands over: a head over any approach of that intersection, or over the junction itself, satisfies it, whether or not it is the approach the road user came in on. It says nothing about what any other device at the junction shows, nothing about whether a public authority placed or erected the head, nothing about the direction the road user travels, the movement it makes or how fast it goes, nothing about where the road user must halt, and nothing about whether it has halted. It is not a head whose faces are covered, and not the absence of a head; it is not a head that shows a valid indication, a flashing red or a flashing yellow head being an operating head that does not satisfy it; it is not a stop sign, a yield sign or any other sign; it is not a person directing traffic; it is not the lane a lane leads into; and it is not a judgement that the road user has or lacks the right to proceed. Where the scene does not observe whether an installed uncovered head shows a valid indication, or does not observe the travel regions a head controls, the concept is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    there is an intersection region which the road user's footprint overlaps: atoms ['st.intersection', 'rel.occupies'], concepts []
    or which a lane the road user's footprint overlaps runs into at its end: atoms ['st.lane', 'st.lane_enters', 'rel.occupies'], concepts []
    there is a signal head whose faces are not covered: atoms ['dev.traffic_signal'], concepts []
    which governs that intersection region or governs a lane that runs into that intersection region: atoms ['dev.governs', 'st.lane_enters'], concepts []
    and which is inoperative - installed and uncovered but showing no valid indication: atoms ['dev.inoperative'], concepts []

  How each element is written:

    The whole body is ONE existential over the scene's intersection regions,
    `existsRegion (.lit "intersection") "i"`, whose quantifier is the st.intersection atom (a
    quantifier over a kind reads that kind's atom, and a region whose kind the source cannot tell
    makes the quantifier unknown rather than decided by its absence). The junction is bound ONCE
    and the two conjuncts under it are the road user's place and the head's control, so that the
    contract's "that intersection region" is the same region in both: a road user at one junction
    and an inoperative head at another junction of the scene does not satisfy the concept.

    "there is an intersection region which the road user's footprint overlaps" —
    `rel_occupies u i`, the atom whose words are "a road user's footprint overlaps a lane /
    region (roadway, shoulder, sidewalk, intersection, crosswalk, ...)", read of the formal `u`
    and the bound junction. Nothing of a stop line, a crosswalk or a place of halting is read.

    "or which a lane the road user's footprint overlaps runs into at its end" — a nested
    existential over the scene's lane regions (the st.lane atom), `rel_occupies u l` for the
    overlap and `st_lane_enters l i` for "the intersection region a lane runs into at its end".
    The two limbs are joined by an inclusive `.or`: a road user whose footprint overlaps both the
    junction and a lane that runs into it satisfies the element by either limb, the contract
    stating no exclusive choice. st.lane_connectivity (the lane a lane leads into) is nowhere in
    the file, as the contract's exclusion requires.

    "there is a signal head whose faces are not covered" — an existential over the scene's devices
    of kind traffic_signal, `existsDevice (.lit "traffic_signal") "d"` (the dev.traffic_signal
    atom, through the quantifier's kind test), with the atom's uncovered attribute,
    `dev_traffic_signal_uncovered d`, as a conjunct beside it: "an installed head whose faces are
    not covered". A decidedly covered head makes the conjunction false and no sign, no person
    directing traffic and no other kind of device is ranged over at all.

    "which governs that intersection region or governs a lane that runs into that intersection
    region" — `dev_governs d i` for control of the junction itself, or a SECOND nested existential
    over lane regions, `dev_governs d lg` and `st_lane_enters lg i`, for control of an approach to
    that junction. The governed lane `lg` is a variable of its own, never the lane `l` the road
    user's footprint overlaps, which is what the contract's "a head over any approach of that
    intersection, or over the junction itself, satisfies it, whether or not it is the approach the
    road user came in on" requires. Where the source does not observe the travel regions a head
    controls, dev.governs is unknown of every region and the element is unknown, as the contract's
    last sentence states.

    "and which is inoperative - installed and uncovered but showing no valid indication" —
    `dev_inoperative d` alone, the atom whose words are word for word the state the contract
    names, read of the same head as the other two conjuncts: one head carries all three. The
    indication atom (dev_traffic_signal_shows) is nowhere in the file, so a head showing
    circular red, a flashing red or a flashing yellow fails the concept through the source's own
    reading of dev.inoperative and not through a list of spellings; where that reading is
    unobserved the concept is unknown, as the contract's last sentence states.

    Nothing of the body looks before or after the observation — no window, no edge, no `since`, no
    `always` — and no class, heading, speed, movement, stop line or other device is read: the
    concept is the configuration at the instant. No `definedWhen` is written: the contract's two
    unknown sources are exactly what the three-valued atoms give, and a head the source sees to be
    uncovered, governing and operating makes the existential false rather than unknown.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.control.intersection_signal_inoperative

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The junction the concept speaks of, bound once and shared by both elements. -/
def vI : Arg := .var "i"
/-- A lane the road user's footprint overlaps. -/
def vL : Arg := .var "l"
/-- A signal head of the scene. -/
def vD : Arg := .var "d"
/-- A lane the head governs — a variable of its own, never the lane the road user is in. -/
def vLg : Arg := .var "lg"

/-- A road user's footprint overlaps a lane or region. -/
def footprintOverlaps (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []

/-- The intersection region a lane runs into at its end. -/
def laneRunsInto (l i : Arg) : Formula := .atom "st_lane_enters" [l, i] []

/-- An installed head whose faces are not covered. -/
def facesNotCovered (d : Arg) : Formula := .atom "dev_traffic_signal_uncovered" [d] []

/-- A travel region or intersection whose traffic the device controls. -/
def controls (d r : Arg) : Formula := .atom "dev_governs" [d, r] []

/-- A signal head installed and uncovered but showing no valid indication. -/
def showsNoValidIndication (d : Arg) : Formula := .atom "dev_inoperative" [d] []

/-- Some lane region of the scene. -/
def someLane (v : String) (φ : Formula) : Formula := .existsRegion (.lit "lane") v φ

/-- Some intersection region of the scene. -/
def someIntersection (v : String) (φ : Formula) : Formula := .existsRegion (.lit "intersection") v φ

/-- Some signal head of the scene. -/
def someSignalHead (v : String) (φ : Formula) : Formula := .existsDevice (.lit "traffic_signal") v φ

/-- The road user is at the junction `i`: its footprint overlaps that intersection region, or it
    overlaps a lane that runs into that intersection region at its end. -/
def atIntersection : Formula :=
  .or (footprintOverlaps aU vI)
      (someLane "l" (.and (footprintOverlaps aU vL) (laneRunsInto vL vI)))

/-- The head `d` controls the junction `i`: it governs that intersection region, or it governs a
    lane that runs into that intersection region — any approach of the junction, not only the one
    the road user came in on. -/
def controlsIntersection : Formula :=
  .or (controls vD vI)
      (someLane "lg" (.and (controls vD vLg) (laneRunsInto vLg vI)))

/-- There is a signal head whose faces are not covered, which controls the junction `i`, and which
    is inoperative: one head carries all three. -/
def inoperativeHeadAt : Formula :=
  someSignalHead "d"
    (.and (facesNotCovered vD) (.and controlsIntersection (showsNoValidIndication vD)))

/-- The road user is at an intersection whose traffic an installed, uncovered head controls, and
    that head shows no valid indication at the observation. -/
def body : Formula := someIntersection "i" (.and atIntersection inoperativeHeadAt)

def concept : Concept :=
  { id := "drv.control.intersection_signal_inoperative"
    contract := "The road user is at an intersection whose traffic a signal head controls, and that head is installed with its faces not covered and shows no valid indication at the observation: there is an intersection region which the road user's footprint overlaps, or which a lane the road user's footprint overlaps runs into at its end, and there is a signal head whose faces are not covered, which governs that intersection region or governs a lane that runs into that intersection region, and which is inoperative - installed and uncovered but showing no valid indication. The concept is a configuration at an instant, read from the road user's region and lane membership, from the intersection a lane runs into, from the travel regions the head controls and from the head's own state. It says nothing about which approach of the junction the head stands over: a head over any approach of that intersection, or over the junction itself, satisfies it, whether or not it is the approach the road user came in on. It says nothing about what any other device at the junction shows, nothing about whether a public authority placed or erected the head, nothing about the direction the road user travels, the movement it makes or how fast it goes, nothing about where the road user must halt, and nothing about whether it has halted. It is not a head whose faces are covered, and not the absence of a head; it is not a head that shows a valid indication, a flashing red or a flashing yellow head being an operating head that does not satisfy it; it is not a stop sign, a yield sign or any other sign; it is not a person directing traffic; it is not the lane a lane leads into; and it is not a judgement that the road user has or lacks the right to proceed. Where the scene does not observe whether an installed uncovered head shows a valid indication, or does not observe the travel regions a head controls, the concept is unknown."
    definition := none
    args := [("u", .track)]
    params := []
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "there is an intersection region which the road user's footprint overlaps, or which a lane the road user's footprint overlaps runs into at its end"
          why := "Written as ONE existential over the scene's intersection regions, with the junction bound once and both of the contract's elements — the road user's place and the head's control — conjoined under it, so that \"that intersection region\" denotes the same region in both. The contract's words leave open whether the head's junction is the road user's; the sentence binds them by the demonstrative (\"which governs THAT intersection region\"), and the single binder is what makes a road user at one junction and an inoperative head at another junction of the same scene fail the concept. The two limbs of the element are joined by an inclusive `.or`: a footprint that overlaps both the junction and a lane running into it satisfies the element by either limb, the contract stating no exclusive choice. The lane limb binds a lane variable of its own, anchored to the formal by `rel_occupies u l`."
          kind := "reading" }
      , { span := "which governs that intersection region or governs a lane that runs into that intersection region"
          why := "Inclusive `.or`, and the governed lane is a SECOND bound lane variable (`lg`), never the lane the road user's footprint overlaps. The contract leaves open which approach the head stands over and then settles it: \"a head over any approach of that intersection, or over the junction itself, satisfies it, whether or not it is the approach the road user came in on\". Writing the governed lane as the road user's own lane would be the narrower reading the contract expressly rejects, so the two lanes are bound separately and are tied to each other only through the junction they both run into. A head that governs both the junction and an approach satisfies the element by either limb."
          kind := "reading" }
      , { span := "there is a signal head whose faces are not covered"
          why := "The head's kind is the quantifier's test — `existsDevice (.lit \"traffic_signal\")`, which reads the dev.traffic_signal atom — and the atom's uncovered attribute is a conjunct beside it, `dev_traffic_signal_uncovered d`, rather than part of the range quantified over. Nothing of the indication the head displays is read here, the inoperative element reading it instead. A head the source sees to be covered makes the conjunction false (not the absence of a head, which makes the existential false as well); a head whose cover the source does not report leaves the existential unknown, which is what the three-valued atoms give and not a choice of this file's."
          kind := "reading" }
      , { span := "and which is inoperative - installed and uncovered but showing no valid indication"
          why := "`dev_inoperative d` alone, of the same head as the other two conjuncts, so one head is installed, uncovered, controlling and showing no valid indication; dev_traffic_signal_shows is nowhere in the file. A head showing circular red, a flashing red or a flashing yellow therefore fails the concept through the source's own reading of dev.inoperative rather than through a list of indication spellings, which is what the contract's \"a flashing red or a flashing yellow head being an operating head that does not satisfy it\" asks for, and what keeps a dark covered head out of the concept, the uncovered attribute being read beside it."
          kind := "reading" }
      , { span := "The concept is a configuration at an instant"
          why := "Nothing of the body looks before or after the observation — no window, no rising edge, no `since`, no `always` — and no class, position, heading, speed, movement, stop line, marking or other device is read, so the concept decides the configuration at the instant alone. No `definedWhen` guard is written: the contract names exactly two unknown sources (the head's valid indication, the travel regions a head controls) and both are the plain unknowns of the atoms that read them, while a head the source sees to be uncovered, controlling and operating makes the existential false rather than unknown. No guard that the scene carry lanes is written either: at a junction a source maps without lanes the second limb of each element is false of every region and the concept is decided by the junction region alone."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.control.intersection_signal_inoperative
