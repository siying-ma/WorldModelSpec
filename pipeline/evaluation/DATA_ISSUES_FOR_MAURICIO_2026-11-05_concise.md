# Training data: defects and requests (concise, 2026-11-05)

Contract files: `ontology/ATOMS.md` (ATOMS), `pipeline/evaluation/evaluation_scenario/adapter/README.md`
(GUIDE), and the Lean decoder `library/TrafficSpec/Core/Runtime/Decode.lean` (Decode).

## A. Defects that block verdicts

### A by atom: how many recordings miss it, and whether they belong to the laws that use it

The denominator is the 189 `demo-train` recordings. An atom is counted missing in a recording when
its manifest declares it absent, or declares it observed while the trace lacks its values. The 17
manifests that declare every atom absent (A4) count as missing in every row. "Used by" includes
rules reached through another law's rule: 253 uses 413-2's rule (with 413-2's subject bound to the
turning vehicle), and 250-2 uses the applicability of 250-4's two rules. The last-but-one column
marks where to look, not a verdict each gap actually changed.

| Item | Atom | Origin | Missing in the 189 recordings | Used by | Do the affected recordings belong to the laws that use it? | Statute words (examples) |
|---|---|---|---|---|---|---|
| A1 Turn indicator | `sig.turn_indicator` | First version | **Partial**: 181/189. 172 within the declared scope (155 declared observed but missing values, 17 absent); 9 more (253) declared `subject`, so no vehicle but the ego has a value | 223-1b, 413-2, and 253 through 413-2's rule | **Yes, all of them**: 34/34 (223-1b 10/10, 413-2 15/15, 253 9/9). The others belong to laws that do not read it | 223-1b: "until the driver has given the appropriate turn signal"; 413-2: "A signal of intention to turn … shall be given continuously" |
| A2 Brake lamp | `sig.brake_lamp` | First version | **Doubtful value in all**: 189/189 have the ego's lamp always `false`; 172 declare it `exact`, 17 declare it absent | None | No current rule reads it | — |
| A3 Kind listed as unobserved | `st.crosswalk` | First version | **Partial**: 36/189 (17 absent, 19 list it unobserved on structures) | 450-2, 113-2, 250-4, 257-1, 257-2, and 250-2 through 250-4's applicability | **Mostly on the laws that use it**: 19/32 (257-1 8/9, 257-2 9/10, 450-2 2/4); 113-2, 250-2 and 250-4 unaffected | 257-1: "before entering the crosswalk on the near side of the intersection" |
| | `st.stop_line` | First version | **Partial**: 20/189 | 450-2, 250-4, 257-1, 257-2, and 250-2 through 250-4's applicability | 3/28 (257-2 ×3 only) | 450-2: "shall stop at a clearly marked stop line" |
| | `st.intersection` | First version | **Partial**: 27/189 | 12 laws | 10/61 (113-2, 227-1, 250-1, 307-6a, 450-2, ×2 each) | 113-2: "into an intersection" |
| | `st.roadway` | First version | **Partial**: 19/189 | 227-1, 400-2a/b, 407 | 2/18 (227-1 ×2) | 227-1: "only upon the right-hand roadway" |
| | `st.median_or_divider` | First version | **All**: 187 declared absent; the other 2 (227-1) declare it `estimate` but list it unobserved on structures. All 8 recordings of 227-1 have divider structures, 6 of them declared absent (A15) | 227-1, 400-2a/b | 12/12 | 227-1: "barrier or dividing section" |
| | `ru.child` | First version | 50 declared absent | None | No current rule reads it | — |
| A4 Unusable manifests | Every atom | — | 17/189 | 413-2, 600-1e, 223-1b | Yes, each law's own recordings: 413-2 12/15, 600-1e 3/15, 223-1b 2/10 | — |
| A5 No highway | `st.highway` | First version | **Partial**: 65/189 | 16 laws | **Yes**: 43/113. Every affected law misses it in all its recordings: 220-1 4/4, 223-1b 10/10, 227-1 8/8, 250-1 4/4, 250-2 3/3, 250-4 2/2, 307-6a 4/4, 400-2a 2/2, 400-2b 2/2, 450-2 4/4. Recordings of 127-2, 257-1, 257-2, 407, 600-1a and 600-1c have a highway | 220-1: "Upon a highway designated … for one-way traffic"; 227-1: "driven upon a divided highway" |
| | `st.on_way` | **Added later** (2026-10-21) | **All**: 189/189 | 11 laws | 87/87 | 600-1c: "the particular portion of highway being traversed" |
| A6 Signals without indications | `dev.traffic_signal` (indication) | First version | **Partial**: 24/189 (7 have signals with frames lacking an indication) | 250-1, 250-2, 250-4, 257-1, 257-2, 307-6a | **Yes**: 6/32 (250-4 2/2, 307-6a 4/4) | 307-6a: "when the red signal is exhibited" |
| | `dev.inoperative` | First version | **All**: 189/189 | 250-4, and 250-2 through 250-4's applicability | 5/5 (250-4 2/2, 250-2 3/3) | 250-4: "but is inoperative" |
| A7 Entrances, governance, sign conditions | `st.entrance_of` | **Added later** (2026-10-29) | **Partial**: 169/189 declared absent (most maps have no stop line or crosswalk; this is the A10 declaration issue) | 450-2, 250-4, 257-1, 257-2, and 250-2 through 250-4's applicability | 8/28: 450-2 2/4 (pending re-export), 250-4 2/2, 250-2 3/3, 257-2 1/10; 257-1 unaffected | 250-4: "shall stop … at each entrance to the intersection" |
| | `dev.governs` | First version | **Partial**: 23/189 | 9 laws | 6/43 (220-1, 307-6a, 450-2, ×2 each) | 450-2: "a stop intersection indicated by a stop sign" |
| | `dev.regulatory_sign` (incl. conditions) | First version | **All**: 187 declared absent; the other 2 (220-1) declare it `estimate`, but their signs lack conditions | 220-1, 250-1, 250-2 (sign class, code and governed region; no rule reads conditions) | 9/11 declared absent; the 2 observed ones are not blocked by the missing conditions | 220-1: "designated and signposted for one-way traffic" |
| A8 Lane fields | `st.lane_direction` | First version | **Partial**: 46/189 | 13 laws (250-4 through the position-along-a-lane primitive) | 21/82: 253 9/9; 220-1, 223-1b, 250-4, 400-2a, 400-2b, 450-2, ×2 each | 220-1: "shall be driven only in the direction designated" |
| | `st.lane_marking` | First version | **Partial**: 49/189 | 223-1b | 2/10 | 223-1b: "two or more clearly marked lanes" |
| | `st.lane_width` | First version | Partial: 25/189 | 600-1a | No: 0/27, every 600-1a recording has it | 600-1a: (the width enters the speed bound) |
| | `st.lane_connectivity` (`leads_to`) | First version | **All**: 139 lack values, 50 declared absent | None directly | No current rule reads it directly | — |
| A9 Intersection approaches | `st.lane_enters` (`enters_intersection`) | **Added later** (2026-10-03) | **Partial**: 23/189 | 10 laws | 4/49 (250-1 2/4, 250-4 2/2) | 250-1: "approaching an intersection" |
| A10 "Not observable" vs "none here" | `st.shoulder` | First version | **Partial**: 50/189 declared absent | 11 laws, through `st.travel_region` | 12/52 (250-1, 250-4, 307-6a, 400-2a, 400-2b, 450-2, ×2 each) | (see travel region) |
| | `st.bicycle_lane_or_path` | First version | **All**: 189/189 declared absent | Same | 52/52 | 257-2: "at one or more entrances thereto" (the travel region a sign governs) |
| A11 Hand signal | `sig.hand_signal` | First version | **All**: 189/189 | 223-1b, 413-2, and 253 through 413-2's rule | 34/34 | Same as A1: "appropriate turn signal" |
| A12 Yaw rate | `kin.yaw_rate` | First version | **All for other vehicles**: 172 give it for the subject only; 17 not even for the subject | 8 laws; those reading other vehicles: 250-1, 250-2, 253 | For other vehicles: 16/16 (250-1 4, 250-2 3, 253 9). For the subject: the 17 empty manifests, of which 413-2 ×12 read it | 250-1: "or is making a left turn" |
| A13 Sight along a way | `st.sight_along_way` | **Added later** (2026-10-21) | **All**: 189/189 declared absent | 407, 250-4, 257-1, 257-2, 450-2, 600-1a | 58/58 | 407: "cannot be seen by the driver of any other vehicle approaching from either direction within 500 feet"; 450-2: "has a view of approaching traffic" |
| A14 Lane-control signal | `dev.lane_control_signal` | First version | **All**: 189/189 declared absent | 250-1, 250-2 | 7/7 | 250-1: "intersections controlled by official traffic-control devices" |
| A15 Kind present but declared absent | `st.one_way_roadway` | First version | **Almost all**: 187/189 declared absent, 2 of them (220-1) although a one-way roadway is present | 220-1 | 2/4 | 220-1: "shall be driven only in the direction designated" |

`st.travel_region` needs no data: the pipeline derives it from the concrete kinds (lane, roadway,
shoulder, bicycle lane or path, intersection).

### A by item: what the table does not show, and what we ask

**A1. Turn indicator (checked).** GUIDE:266, GUIDE:278-280, ATOMS:220; Decode:137 reads only
`turn_indicator`.
- `off` appears 0 times in 196,003 scenes. The ego has no value in 82 % of its scenes, non-ego
  vehicles in 99 %.
- 24 recordings write `left_indicator_enabled` / `right_indicator_enabled`, which the decoder
  ignores. 17 recordings (227-1 ×8, 253 ×9) have the ego's indicator `left` in every scene.
- Example: 52d9fa3a2c62 (250-1), t = 50 ms, ego: both `*_enabled` keys false, no `turn_indicator`,
  manifest `exact`.
- Ask: write `turn_indicator` ∈ {left, right, hazard, off} for every vehicle on every frame, from the
  simulator's light state, and drop the `*_enabled` keys.
- Contract: write the indicator for every vehicle you can read it on and declare `sig.turn_indicator`
  `exact`; if you read it for the ego alone, declare it `subject` (GUIDE:566-569); if not at all, `absent`.

**A2. Brake lamp constant (checked).** ATOMS:221, GUIDE:267.
- In 186 recordings `service_brake` is above 0.1 in some scene while the lamp stays `false`; in 184
  every ego lamp is constant (all `false`, headlamp `off`).
- Example: cb6ec1a81f55 (250-1), scene 394, t = 19,750 ms: speed 4.71 m/s, `service_brake` 1.0,
  `brake_lamp` false.
- Ask: take lamp states from the simulator's vehicle light state; if they cannot be captured,
  declare the atoms absent rather than `exact`.
- Contract: as for A1, `exact` for every vehicle, `subject` for the ego alone (GUIDE:566-569), or
  `absent`.

**A3. A kind listed as unobserved on structures although the manifest declares it observed
(checked).** GUIDE:293, GUIDE:347-355. Such a listing makes the kind unknown on that structure
(`Structure.isOfKind`, `library/TrafficSpec/Core/Vocab/Atoms.lean:284-304`).
- `crosswalk` is listed on 45–47 structures per map. `child` is listed unobserved on vehicles in 139
  recordings while the manifest declares `ru.child` observed.
- Example: 5e2d68c8af83 (257-2), scene 0: 46 structures carry `unobserved_kinds: ["crosswalk"]`,
  while the manifest declares `st.crosswalk: estimate:native_map_object`.
- Ask: list a kind as unobserved only where the source really cannot tell it, and keep it
  consistent with the manifest.

**A4. Unusable manifests.** Besides the 17 empty manifests, 6 recordings await a revised export:
8b66dc711065 and f82eb9859f57 (450-2), 46d0a7663615 and 968996df2771 (220-1), bf5ba06672dc and
71e2a17317ca (250-4). Ask: re-export these with the current manifest.

**A5. No highway.** ATOMS:147: `st.highway` is the entire public way between its boundary lines,
sidewalks and shoulders included, and it is not a stand-in for the roadway.
- Effect: 307-6a's rule needs the subject to be on a highway, so on these recordings it can never
  conclude a violation.
- Ask: emit the highway region itself. Marking `st.highway` observed without emitting the region
  would make such rules silently conclude "not applicable" everywhere, which is worse than unknown.
- The contract that already holds (written; the adapter has not implemented it yet, EVAL:86–91
  items 1, 2 and 6 are open):
  - **Highway** (ATOMS:147): one `highway` region per public road, its boundary covering every
    lane, shoulder and sidewalk of that road (one OpenDRIVE road; EVAL item 1). Declare
    `st.highway` `exact`.
  - **Roadway** (ATOMS:149): the part of a highway improved for vehicular traffic, shoulders
    excluded; the two sides of a divided highway are separate roadways. A lane is a strip of a
    roadway. A highway contains its roadways; a roadway is never a stand-in for the highway.
  - **Which highway a structure belongs to** (`st.on_way`, ATOMS:155, GUIDE:294 `ways`): every
    lane, roadway, shoulder, crosswalk, stop line and median lists the `highway` region of its
    road; a junction lists every highway whose road meets there. The roads on the two sides of a
    junction that form one public way (by road name, or by straight continuation through the
    junction) share one `highway` region. Where you cannot group them, declare `st.on_way` absent.
    We never infer this from geometric containment or nearness (EVAL item 6).
  - **"None here" versus "cannot see"** (ATOMS:143, EVAL item 2): a kind you enumerate completely
    from the map is declared `exact`, also when the map has none of it; then "no such region
    here" is decided. Declare a kind `absent` only when you do not read it at all (see A10).
- One point the contract does not yet cover, the map crop: what area does a recording's map
  cover, and how is a road cut by the crop written? Our proposal: each highway, roadway and lane is
  written as its part inside the crop, keeps the same id in every scene, and is still listed in
  `ways`; a road that leaves the crop is not a different road. Please confirm or tell us what you
  do now.
- Example: one intersection.
  ```
                   Oak Ave (highway H2)
                      |  L5 ↓ | L6 ↑ |
                      |       |      |
    ------------------+-------+------+------------------   north sidewalk of Main St (part of H1)
     L2 ← westbound   |               |   L4 ← westbound
    ··················S1  junction J  ···················   centre line
     L1 → eastbound  C1               |   L3 → eastbound
    ------------------+-------+------+------------------   south sidewalk of Main St (part of H1)
       roadway R1     |       |      |     roadway R2
                      |  L7 ↓ | L8 ↑ |
                   Oak Ave (highway H2)
     the map crop is the 200 m around J
  ```

  | Structure | Kind | `ways` | Notes |
  |---|---|---|---|
  | H1 | `highway` | — | All of Main St inside the crop: roadways, sidewalks, any shoulders. The roads on both sides of the junction are one H1 |
  | H2 | `highway` | — | All of Oak Ave |
  | R1, R2 | `roadway` | `[H1]` | Main St's carriageway west and east of the junction; lanes L1–L4 lie inside them |
  | L1 … L4 | `lane` | `[H1]` | Each with its direction; L1 enters J |
  | L5 … L8 | `lane` | `[H2]` | Oak Ave's lanes |
  | C1 | `crosswalk` | `[H1]` | West side of J; `entrance_of` is L1 |
  | S1 | `stop_line` | `[H1]` | On L1 |
  | J | `intersection` | `[H1, H2]` | A junction lies on every road that meets there |
  | (none) | `st.shoulder` declared `exact` | — | The map has no shoulder: declare the kind observed and write no shoulder region |

  How the rules read it:
  - **220-1** "Upon a highway designated … for one-way traffic": the car is in L1, whose `ways` is
    H1, so it is on a highway and the rule goes on to the one-way question. Without H1 and `ways`
    (48 recordings today) this is unknown.
  - **250-2** "When two vehicles enter an intersection from different highways": car A enters J
    from L1 (H1) and car B from L5 (H2), so they come from different highways. If west and east
    Main St were two highways, a car going straight through would wrongly count as coming from a
    different highway; that is why one road on both sides of a junction is one highway.
  - **257-1** "stop at a clearly marked stop line or, if there is none, before entering the
    crosswalk": S1's `entrance_of` is L1, so a car in L1 stops at S1. Where an approach has no stop
    line and `st.stop_line` is `exact`, "none" is decided and the rule turns to the crosswalk.
  - **Shoulder:** declared `exact` with no region, "no shoulder here" is decided. Declared `absent`,
    every structure (crosswalks and sidewalks included) might be a shoulder and so a travel region,
    and the rules that quantify over travel regions become unknown and slow (A10).
  - **Crop:** Main St continues beyond the crop. Under our proposal H1, R1 and R2 are written as
    their part inside the crop, keep their ids in every scene, and stay listed in `ways`.

**A6. Signals without indications.** GUIDE:397.
- Examples: fdc101fc9070 (307-6a): 3,912 of 7,206 signal-scenes have no `indications`, device 2
  already has none at t = 0; bf5ba06672dc (250-4): 426 of 1,239 have none, the rest show only `dark`.
- 5 of the 29 signals never change state during their recording. Every `governs` target is a lane
  or a roadway; none is an intersection.
- Ask: write the indication of every signal head on every frame.

**A7. Entrances, governance and sign conditions.** GUIDE:295, GUIDE:396, GUIDE:400.
- The six pending recordings (A4) declare `st.entrance_of` absent although they have 21 stop lines
  and 16 crosswalks; the 20 revised recordings are complete.
- `governs` is omitted on 16 devices in 6 recordings. Example: 8b66dc711065 (450-2), 6 of its 9
  devices, stop sign 8 among them.
- `conditions` is required only on regulatory and zone signs. 4 recordings (all 220-1) have
  regulatory signs without it, 2 of them declaring `dev.regulatory_sign` absent (A15).
- Ask: fill all three, or declare what cannot be supplied.
- Contract: `conditions` belongs to regulatory and zone signs only (ATOMS:206-207): `{}` for a sign
  known to state no restriction, omitted only when the legend is not read (GUIDE:400). Stop, yield and
  speed-limit signs need none.

**A8. Lane fields missing although the manifest says `exact`.** GUIDE:292, ATOMS:151-157, ATOMS:189.
- Missing on scene-0 lanes: `direction` 704 of 2,574 (29 recordings; example 8b66dc711065, lane 1,
  81 of its 168 lanes); `marking_left` / `marking_right` 1,252 (32 recordings); `width` 582
  (8 recordings); `leads_to` 74 % of lanes (139 recordings).
- Ask: fill these fields for every lane, junction-internal lanes included, or declare the atom
  absent.
- Contract: a field of an atom declared `exact` is supplied on every lane (`exact` means ground
  truth, GUIDE:563-565); `leads_to` (`st.lane_connectivity`) included. What you cannot supply, declare
  absent.

**A9. Intersection approaches.** GUIDE:298-322: `occupies` and `enters_intersection` must be right
for every carrier.
- Intersections that no carrier enters: 250-4 ×2 (intersection 728), 250-1 ×2 (intersection 26),
  113-2 ×2.
- The ego enters an intersection from no carrier marked as entering it in 5 recordings. Example:
  cb6ec1a81f55 (250-1), scene 283, t = 14,200 ms: the ego enters intersection 26 from lane 1 and
  roadway 3, and neither has `enters_intersection` = 26.

**A10. "Not observable" used where "none here" is meant (new).** ATOMS:143.
- A travel region is derived, not emitted: a region is a travel region exactly when it is a lane,
  a bicycle lane or path, a roadway, a shoulder or an intersection.
- Declaring `st.shoulder` or `st.bicycle_lane_or_path` absent makes every structure that is not
  already known to be a travel region (crosswalks, centre lines, sidewalks) an undecided travel
  region. Declaring `st.highway` or `st.median_or_divider` absent makes every structure an
  undecided highway or divider. Verdicts become unknown and quantifiers range over every
  structure; we believe this adds to the 400-2a/b and 227-1 timeouts.
- Ask: when the simulator can see a kind and the map simply has none, declare it observed and emit
  no structure of it; keep `absent` for kinds the source really cannot see. See the supplement
  after A15.

**A11. Hand signal declared absent everywhere (new).** GUIDE:274 asks for `hand_signal` with
`no_signal` when none is given. Rules read "turn indicator or hand signal", so "no signal given"
stays unknown even after A1 is fixed. Ask: write `no_signal` for every vehicle on every frame, and
declare the atom observed.

**A12. Yaw rate only for the subject (new).** Whether another vehicle is turning is always unknown:
250-1's exception ("the other vehicle is making a left turn") and 253's turner can never be decided
for a non-ego vehicle. Ask: supply yaw rate for every vehicle.

**A13. Sight along a way absent everywhere.** ATOMS:173. All 189 manifests declare
`st.sight_along_way` absent. Six laws read it (407, 450-2, 250-4, 257-1, 257-2, 600-1a; 58
recordings): 407 ("cannot be seen by the driver of any other vehicle approaching from either
direction within 500 feet") can never conclude a violation; the branch "the point nearest the
intersection where the driver has a view of approaching traffic" of 450-2, 250-4, 257-1 and 257-2
stays unknown; 600-1a's reasonable-speed bound never concludes compliant. Ask: write
`sight_along_way` on the road users you can cast rays from (EVAL item 7), or keep it absent where
you cannot.

**A14. Lane-control signals absent everywhere.** All 189 manifests declare
`dev.lane_control_signal` absent. 250-1 and 250-2 read it in their exception "intersections
controlled by official traffic-control devices" (7 recordings), so a lane-control signal can never
settle whether an intersection is controlled. Ask: emit lane-control signals where the map has them;
where it has none, declare the kind observed and emit none (A10).

**A15. Kinds present but declared absent.**
- `median_or_divider` is present in 227-1 ×6 but declared absent.
- A `one_way_roadway` and a `regulatory_sign` (code `one_way`) are present in 220-1 ×2 but declared
  absent.
- Ask: declare these kinds observed; the trace already shows them.

**Supplement to A10 and A15: how to declare a kind, and what each declaration does.**

1. *A kind the source can see but this map does not contain.* Declare the atom observed (`exact`,
   or `estimate` with its error class) and emit no structure of that kind. This changes what the
   evaluator concludes, and that is the point. A quantifier over a kind ranges only over the
   structures that may be of that kind (`regionCandidates`,
   `library/TrafficSpec/Core/Vocab/Atoms.lean:436`). With the kind observed and none emitted the
   range is empty, so "there is a crosswalk …" is false and "every crosswalk …" is true, and a rule
   can take the right branch. Example: 257-1 reads "stop … at a clearly marked stop line or, if
   there is none, before entering the crosswalk"; the rule must know there is no stop line before
   it can move to the crosswalk, and with `st.stop_line` absent that step is unknown.
   - The one risk: declaring a kind observed promises that every structure of that kind is
     emitted. A structure the generator misses then yields a definite wrong verdict, not an
     unknown one, so use this declaration only where the generator emits every instance.
   - The highway is the exception (A5). Every road lies on a highway, so the highway is always
     emitted. Declared observed and not emitted, rules conclude that the subject is on no highway
     and silently report "not applicable".
2. *What "present" means in A15.* The trace itself contains structures of the kind, whichever law the
   recording serves. 25 recordings do this: the 17 empty manifests of A4 (their lanes, roadways,
   intersections and centre lines are emitted), 227-1 ×6 (`median_or_divider`) and 220-1 ×2
   (`one_way_roadway`, and a regulatory sign of code `one_way`). Such a recording contradicts itself:
   the trace gives the structure while the manifest says the kind cannot be seen. The evaluator
   follows the manifest. For a kind with no parent kind (median or divider, crosswalk, stop line,
   highway), every structure becomes an undecided member, the real divider included; for a kind
   that refines a concrete parent (a one-way roadway refines roadway), every roadway becomes an
   undecided one-way roadway.
3. *Which declaration fits which case.*

   | Case | Manifest | Trace |
   |---|---|---|
   | The generator can see the kind, and the map has it | `exact` / `estimate` | emit every structure of it |
   | The generator can see the kind, and this map has none | `exact` / `estimate` | emit none: "known to be none here" |
   | The generator cannot tell the kind at all | `absent` | emit none; the structures become undecided members (see 2) |
   | The kind is visible in general, but one structure cannot be told | `exact` / `estimate` | list the kind in that structure's `unobserved_kinds` |

   `exact` and `estimate` both mean observed; `estimate` names an error class (ATOMS:63), and which
   one fits a kind read from the simulator's map objects is the data producer's call. ATOMS:68-71
   says a `local` atom (one that exists because of the jurisdiction's own vehicle taxonomy or device
   catalogue) is declared absent by "a source that has no such thing": that means the source has no
   such concept at all, not that one map happens to contain none. The kinds of A10 (shoulder,
   bicycle lane or path, median or divider, crosswalk, highway) are `general` and follow the table
   above.

## B. Defects that degrade results or cost

**B1. Overlapping roadway patches made only to carry grade; map size (checked).** ATOMS:149 and
ATOMS:169-170. A road may legitimately be split into several roadway regions (by direction, or at
the map crop); what the contract does not allow is extra roadway regions laid over the road only to
carry a property of it.
- 51 recordings have 300 or more structures:
  - 727–728 structures: the six pending recordings;
  - 512: 448b9e51002d and fdc101fc9070 (307-6a, 1,201 scenes);
  - 461: 227-1 ×2, of which 450 are obstructions;
  - 306: 127-1 ×22, 127-2 ×15, 407 ×4.
- Example: 5f27ffa7562a (127-1), scene 0, has 301 roadway structures. Roadway 4 (36,000 m²) is the
  road. Roadways 5–304 are 48 m² patches inside it that carry only `grade`, and roadway 4 itself has
  no `grade`. The ego therefore occupies four "roadways" at once.
- Effect: wrong "which roadway" readings, and evaluation time. Most of the time on the 307-6a
  recordings with 512 structures was our evaluator's own cost, which we have since removed (a full
  307-6a recording now takes about 3 minutes), but every extra structure still widens what the
  rules have to scan.
- Ask: drop the overlapping grade patches and carry grade on the roadway regions that represent the
  road (a direction or crop split is fine).
- Contract: `curvature`, `grade` and `sight_distance` are properties of the roadway at a point
  (ATOMS:169-172), written on roadway regions. They are static: `sight_distance` holds "whether or
  not any road user is there", so it does not change over time (it changes in 73 recordings).

**B2. Declared intentions and assumptions.** Three parts: (a) the intentions the rules need are
missing, (b) some assumption ids stand in for things the trace can observe, (c) the declared-fact
ids we do need, proposed as one shared catalogue.
- (a) Intentions appear only in 253 ×3, for the ego only (`int.preparing_left_turn`).
- The rules generated so far need `int.left_turn` for every vehicle at the region it approaches.
  250-1's exception concerns the other vehicle's intention, and all four 250-1 recordings came out
  unknown partly for this reason.
- (b) Some assumption ids in the data stand in for things the trace can observe, or for the verdict
  itself: `asm.appropriate_signal_fixed`, `asm.driver_ascertained_lane_change_safe`,
  `asm.no_crosswalk_on_approach`, `asm.no_hand_signal`, `asm.empty_conflicting_traffic`,
  `asm.proceed_cautiously_fixed_for_halt_probe`. GUIDE:197 and ATOMS:43-46 do not allow that.
- Ask: declare `int.*` for every vehicle from the scenario's route plan. Keep `asm.*` to facts the
  scene cannot show.

**B2c. Declared-fact ids we need (a proposal to confirm together).** The data declares
`asm.business_district`, `asm.residential_district`, `asm.other_area` and
`int.preparing_left_turn`. Our rules read the ids below. No id is shared today. This table is a proposal
for one shared catalogue. Please do not rename anything in the data until we have both confirmed the
meaning and scope of each entry; until then we keep our entries marked proposed and add no alias.

| Proposed id | Proposed meaning and scope | Question for you |
|---|---|---|
| `asm.way_within_city_limits` | At this scene's timestamp, the trace subject's current location on the road is within an incorporated city's territorial limits. It is not a claim about the whole road. | Is an independent city-boundary classification available? `asm.public_highway` means something else and cannot stand in for it. |
| `asm.way_within_business_or_residential_district` | At this scene's timestamp, the trace subject's current location belongs to a business district as defined in NRS 484B.010, or to a residence district as defined in NRS 484B.053. | Do `asm.business_district` and `asm.residential_district` follow these definitions and this scope, or are they scenario or land-use categories of your own? Does an explicit false mean "known not to be"? |
| `asm.way_outside_business_district` | At this scene's timestamp, the trace subject's current location is known not to belong to a business district as defined in NRS 484B.010, including its industrial-use cases. | Can this negative be confirmed on its own? A missing `asm.business_district`, or `asm.other_area`, does not automatically mean it. |
| `int.left_turn` | At this scene's timestamp, the source declares that the named vehicle plans to turn left at the named target region (our existing intention record: one vehicle, one target region). | Does `int.preparing_left_turn` carry the same plan, vehicle, target region and time scope? |

The two definitions, in short:
- NRS 484B.010 (business district): buildings in business or industrial use occupy at least 300 ft
  of frontage within 600 ft along the highway, on one side or on both sides together. Buildings on
  both sides, or continuous frontage, are not required.
- NRS 484B.053 (residence district): at least 300 ft of mainly residential frontage, and not a
  business district.

**What applies to every entry:**
- An entry that is not supplied, not classified, or cannot be confirmed is unknown, never false.
- The three `asm.*` entries are per-scene statements about the trace subject only, not about every
  vehicle or region.
- The `int.*` entry keeps both keys, the vehicle and the target region. It is a current plan, not
  "will turn left somewhere later in the recording".

Only after a definition and its scope are confirmed independently may we combine your
classifications:
- the district union from business OR residence, under three-valued logic (true OR unknown = true,
  false OR unknown = unknown);
- "outside" as the negation of a known business classification (NOT unknown = unknown).

A field that is not listed is never taken as false, and we never confirm an equivalence from a label
or from a rule's verdict. If your categories are coarser scenario categories, please tell us; we
will then disclose them as a simulation convention for the operator to approve, rather than
replacing the legal definition.

**B3. Crests absent everywhere.** No recording has crests (`st.crest`), and no rule generated so far
reads them; a law about turning or passing near a crest will need them. Ask: say whether the simulator
can provide them.

**B4. Mixed sources.** There are 7 `source` strings and 14 distinct manifest profiles across the
189 recordings; 600-1e alone mixes 4 sources. GUIDE:583 asks for one manifest per generator version.

**B5. Minor.**
- `sig.reverse_lamp` (all 189) and `user.source_classifications` (82) are ignored by the decoder.
- The `source_capabilities` block (149 manifests) is not read, and its ids are not ontology atoms.
- Centre lines are written as zero-area polygons, some self-intersecting (8 recordings). The 727–728
  structure maps (450-2, 220-1, 250-4 pending recordings) also carry 21 stop lines with zero area;
  a stop line's offset from a vehicle is then undefined, so this one is not only cosmetic.
- `speed` differs from |velocity| in 840 of 392,075 user-scenes, mostly at scene 0.


