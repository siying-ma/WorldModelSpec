/-
  Rule R0010 — a prudent gap when the vehicle ahead is braking.

  Law text (laws/example/laws.jsonl, id EX-FOLLOW-001, "Following too closely"):
    "The driver of a motor vehicle shall not follow another vehicle more
     closely than is reasonable and prudent. A vehicle shall not remain
     within four metres of the vehicle it is following."

  SCOPE. This rule formalizes the **first sentence only** — "shall not follow
  another vehicle more closely than is reasonable and prudent". The second
  sentence, the four-metre bright line, is the sibling rule
  `Following/R0003_following_distance`; read its header alongside this one.
  Neither rule subsumes the other. The decomposition only earns its keep if this
  rule convicts conduct R0003 permits, which is why the negative scenario here
  sits in the `superNear` band (4–7 m) — strictly *outside* the four metres R0003
  measures, so R0003 is silent on that trace and this rule is not.

  THE TWO NUMBERS IN THIS RULE ARE BOTH CHOICES THE STATUTE DOES NOT MAKE.
  "Reasonable and prudent" fixes no distance and no duration; this file picks
  **seven metres** and **one second**, and a reviewer who disagrees should
  disagree with those two constants and nothing else.

  Formalization notes
  -------------------
  * **Seven metres is a choice the statute does not make.** It is *not* a derived
    stopping distance — no such derivation is possible here, because the ego's
    speed is the only speed available and the abstraction keeps no metric
    separation at all. It is simply the next proximity-band boundary above the
    four-metre bright line: `Pred.withinMetres 7` is the union of `safetyHazard`
    (<2 m), `nearCollision` (2–4 m) and `superNear` (4–7 m). The six bands are
    all the separation there is — `process_to_junction_rsv` does not copy the
    metric `distance` the base graph puts on each proximity edge
    (`carla/schema.json`, `not_available.exact_distance`) — so the reading of
    "more closely than is prudent" can only be quantised to a band boundary.
    Writing `rel v .near w` instead would mean the 10–16 m band, the second
    *farthest*, and would invert the rule.
  * **One second is a choice the statute does not make.** "Follow" describes a
    sustained relation rather than an instant, and traffic legitimately
    compresses: a dab of the brakes ahead, or one frame of closure at a junction,
    is not imprudent following. This rule requires the condition to hold for
    `TrafficSpec.secondsToFrames 1` = 20 consecutive frames = 1 s at the 20 Hz
    reference capture rate. Frames carry no timestamp
    (`carla/schema.json`, `not_available.timestamps`), so a duration can only ever
    be a frame count at an assumed rate. The declared scenarios pin the constant
    no further than the range 9–30 — anything in that range agrees with all five
    — so the scenarios do not choose it either; this file does.
  * "The vehicle it is following" is same-lane occupancy with the follower at the
    rear: `Pred.followingWithin 7 v w` = `sameLane v w ⋀ behind v w ⋀
    withinMetres 7 v w`. The relation direction reads "src is ⟨rel⟩ tgt"
    (`Core/Vocab.lean` §5), so `behind v w` says **v** is behind **w**: v is the
    follower and **w is the lead whose brake light is read**. Swapping the two
    would read the *follower's* brake light and convict the vehicle being
    followed; the `being_tailgated_while_braking` scenario is the test for that
    and fails if they are swapped.
  * The antecedent is gated on `Pred.isEgo v`. Legally the duty falls on the
    driver of the following vehicle, and the ego is the only driver this
    specification speaks about. In the data, proximity and angular edges exist
    only between the ego and another actor, so an ungated rule would read the
    ego's own edge in the `v = car_0, w = ego` grounding and convict the ego of
    another car's tailgating.
  * `w` is bound with `proximityVehicleBinder`: the generator emits proximity and
    angular edges only for the base classes `person` / `bicycle` / `car` /
    `motorcycle` / `bus` / `truck`, so a `van` or a bare `vehicle` would ground
    into an antecedent that can never fire and inflate the grounding count
    without testing anything.
  * `□ ¬ₛ (.bounded n φ)` reads: at no position of the trace does φ hold for `n`
    consecutive frames. `bounded` has strong-next semantics, so a window running
    off the end of the trace is false — a trace shorter than `n` frames can never
    violate this rule.

  Residues a reviewer must weigh against any clean verdict
  -------------------------------------------------------
  1. `light_brake` is evidence of the driver's **action**, not of the resulting
     deceleration, and it stays `false` if the simulated traffic manager never
     actuates it (`carla/schema.json`,
     `partially_available.another_vehicle_braking_or_signalling`). Check the
     antecedent-firing count on a real capture before believing a clean verdict:
     a rule whose antecedent never fires is indistinguishable from one that is
     satisfied.
  2. `non_ego_dynamics` is unavailable — `copy_carla_actor_state` and
     `copy_carla_control` run for the ego node alone — so the lead's speed,
     deceleration and brake-pedal position are all unreadable. The brake light is
     the *only* braking evidence about the lead that exists.
  3. "Reasonable and prudent" is a context-dependent standard: it depends on
     speed, road surface and visibility, and `environment` is genuinely absent
     from the graph (no weather, time of day, surface or visibility state
     anywhere). Fixing the standard at one distance and one duration therefore
     both **over-reports** — a four-metre gap at walking pace behind a braking
     lead is prudent, and this rule convicts it — and **under-reports** — an
     eight-metre gap at 80 km/h in the rain is imprudent, and this rule acquits
     it. That gap is the price of making an open-textured standard decidable, not
     a defect to be patched by moving the constants.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Following.R0010

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- How long the close following must persist to count as "following" rather than
    a momentary compression: 1 s = 20 frames at the 20 Hz reference rate. A
    formalization choice; the statute states no duration. -/
def prudenceFrames : Nat := TrafficSpec.secondsToFrames 1

/-- The imprudent-gap band: within seven metres. A formalization choice; the
    statute states no distance. -/
def prudentGapMetres : Nat := 7

/-- The ego vehicle `v` is following `w` within seven metres while `w` — the
    lead — has its brake lights lit. `behind` inside `followingWithin` makes `v`
    the follower, so `brakeLightOn w` reads the *lead's* light. -/
def closingOnBrakingLead (v w : EntityId) : SFProp :=
  isEgo v ⋀ followingWithin prudentGapMetres v w ⋀ brakeLightOn w

/-- The rule: at no point does the ego sustain, for a full second, a gap of
    under seven metres behind a vehicle that is braking. -/
def schema : PropertySchema where
  name    := "prudent_gap_when_lead_brakes"
  binders := [vehicleBinder "v", proximityVehicleBinder "w"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    □ (¬ₛ (.bounded prudenceFrames (closingOnBrakingLead v w)))

def entry : RuleEntry where
  nodeId  := "Following/R0010_prudent_gap_when_lead_brakes"
  lawRefs := ["EX-FOLLOW-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- Every trace is thirty frames — comfortably longer than the twenty-frame
-- window, so a trace that does not violate the rule fails to do so because of
-- its content and not because it ran out of frames.
----------------------------------------------------------------------

/-- Road structure shared by every trace: one lane inside one road, so
    `sameLane` holds for both vehicles throughout. -/
private def lane : Nat := 10
private def road : Nat := 20

private def structureEntities : List Entity :=
  [mkLane lane "Lane 7_-1", mkRoad road "Road 7"]

private def laneRels : List Relation :=
  [mkRel lane .isIn road, mkRel 1 .isIn lane, mkRel 2 .isIn lane]

private def ego : Entity := mkEgo 1 .car "9.0" "0.0" "0.3" "0.0"
private def lead : Entity := mkActor 2 "car_0" .car

/-- One frame with the ego (id 1) following `car_0` (id 2) at proximity `band`:
    ego at the direct rear of `car_0`, `car_0` directly ahead of the ego.
    `leadBrake` is `car_0`'s `light_brake`; `none` leaves the attribute absent,
    which reads false exactly as a captured frame would. -/
private def egoFollows (band : RelLabel) (leadBrake : Option String) : Scene :=
  frame
    ([ ego
     , match leadBrake with
       | some v => lead.withAttr "light_brake" v
       | none   => lead ] ++ structureEntities)
    (laneRels ++ [ mkRel 1 band 2, mkRel 1 .atDRearOf 2, mkRel 2 .inDFrontOf 1 ])

/-- One frame with the roles reversed: `car_0` at the direct rear of the ego at
    proximity `band`, ego directly ahead. The **ego's** own brake light is lit and
    `car_0`'s is explicitly off, so the only braking vehicle here is the one being
    followed. -/
private def egoIsFollowed (band : RelLabel) : Scene :=
  frame
    ([ ego.withAttr "light_brake" "true"
     , lead.withAttr "light_brake" "false" ] ++ structureEntities)
    (laneRels ++ [ mkRel 2 band 1, mkRel 2 .atDRearOf 1, mkRel 1 .inDFrontOf 2 ])

/-- Thirty frames in the `near` band (10–16 m) with `car_0` braking throughout.
    A braking lead ten metres or more ahead leaves a prudent gap. -/
def traceAdequateGap : Trace :=
  List.replicate 30 (egoFollows .near (some "true"))

/-- Thirty frames at `superNear` (4–7 m) with `car_0`'s `light_brake` absent.
    Close running behind a lead that is not braking is outside this rule — the
    under-report of note 3 made concrete. This trace differs from the violating
    one in exactly one attribute, so it is the discriminator for the brake-light
    conjunct: drop that conjunct and this scenario flips. -/
def traceCloseButNotBraking : Trace :=
  List.replicate 30 (egoFollows .superNear none)

/-- Thirty frames at `superNear` (4–7 m) with `car_0` braking for frames 12–19
    only — eight consecutive frames, 0.4 s, short of the twenty-frame window.
    A dab of the brakes ahead is not sustained imprudent following. -/
def traceMomentaryFlash : Trace :=
  List.replicate 12 (egoFollows .superNear (some "false"))
    ++ List.replicate 8 (egoFollows .superNear (some "true"))
    ++ List.replicate 10 (egoFollows .superNear (some "false"))

/-- Thirty frames with `car_0` sitting at `superNear` (4–7 m) off the ego's rear
    while the **ego** brakes throughout. The ego is the vehicle being followed, so
    it breaks nothing. This trace fails if the follower and lead arguments are
    swapped, or if the `isEgo` gate is dropped. -/
def traceBeingTailgatedWhileBraking : Trace :=
  List.replicate 30 (egoIsFollowed .superNear)

/-- Thirty frames with the ego four to seven metres off a continuously braking
    lead — never inside four metres, so `Following/R0003` permits this trace,
    and one and a half seconds of it, past the one-second window. Following more
    closely than is reasonable and prudent. -/
def traceSustainedCloseFollowing : Trace :=
  List.replicate 30 (egoFollows .superNear (some "true"))

def scenarios : List Scenario :=
  [ { name := "adequate_gap_while_lead_brakes",
      trace := traceAdequateGap,                  expected := true }
  , { name := "close_but_lead_not_braking",
      trace := traceCloseButNotBraking,           expected := true }
  , { name := "momentary_brake_flash",
      trace := traceMomentaryFlash,               expected := true }
  , { name := "being_tailgated_while_braking",
      trace := traceBeingTailgatedWhileBraking,   expected := true }
  , { name := "sustained_close_following_while_lead_brakes",
      trace := traceSustainedCloseFollowing,      expected := false } ]

end TrafficSpec.Rules.Following.R0010
