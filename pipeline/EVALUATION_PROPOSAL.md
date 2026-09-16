# Evaluation dataset — proposal

**Date:** 2026-09-15 · **Status:** design, for approval
**Supersedes** the dataset design in `EVALUATION_HANDOFF.md` §2–3. The measured facts in that
document still hold; what changes is the unit of test and the ground-truth procedure.

---

## 1. What we test

**Unit: one law clause.** Not a capture, not a route, not a rule.

For each clause we hold:

| | |
|---|---|
| **Specs** | Spec₁ … Specₙ — the Lean rules the formalizer produced for this clause. One clause often needs several |
| **Scenarios** | exactly two — one **compliant**, one **violating** |
| **Label** | which of the two each scenario is. Not free text; the outcome of §3 |

**The test.** Run every spec of the clause on both scenarios and take the union:

```
violating scenario :  OR over specs ( spec reports a violation )  MUST be TRUE
compliant scenario :  OR over specs ( spec reports a violation )  MUST be FALSE
```

A clause **passes** only if both hold. Two failure modes, named separately because they are not
interchangeable:

- **MISSED** — no spec fired on the violating scenario. The formalization does not cover the clause.
- **FALSE ALARM** — some spec fired on the compliant scenario. The formalization over-reaches.

**Two guards that keep the test honest:**

1. **The pair is the unit of evidence, not the scenario.** A spec that never fires passes the
   compliant test trivially. Only the violating scenario gives that test teeth, and only the
   compliant scenario stops "always fire" from scoring perfectly. Never report one without the other.
2. **Vacuity is not a pass.** If every spec of a clause grounds zero times on *both* scenarios, the
   clause is **UNTESTED**, not passed. A library of rules that never engage would otherwise score 100%.

This is deliberately coarse: one bit per clause plus two error labels. It scales to hundreds of
clauses, it is readable by a non-specialist, and it does not need per-frame annotation.

*(Optional, later: a near-threshold pair in addition to the plain pair, to measure where a spec's
threshold actually sits. Not part of the core protocol.)*

---

## 2. The hard part

Two scenarios per clause, and someone must say which is which. Doing that by hand does not scale to
~300 clauses × jurisdictions, and it is also the least reliable part of the whole pipeline.

Two obvious answers, both wrong on their own:

| Approach | Why it fails alone |
|---|---|
| **Trust the construction** — "we set `ignore_lights_percentage = 100`, so it ran the red light" | The simulator may not do what it was told. Our own scenario code documents the failures: *"the cross vehicle crossed and left while the ego was still 28 m away"*, *"the compliant ego met a red that outlasted the whole capture"*. The switch was set; the situation never happened |
| **Derive the label from the trace** — evaluate the clause over what was recorded | This is a *second formalization of the same statute*. When it agrees with the spec you have learned nothing; when it disagrees you cannot say which is wrong. Already observed here: *"two seconds of space"* became **20 m** in the Lean rule and **4 m** in the label script |

---

## 3. The answer: two independent paths, and agreement is the label

```
                    ┌─────────────────────────────────────────┐
  RECIPE  ─────────►│  A.  INTENT     what we asked for       │
  (per clause)      │      known before the simulator runs    │
                    └─────────────────────────────────────────┘
                                      ║  must agree
                    ┌─────────────────────────────────────────┐
  FACT TRACK ──────►│  B.  OUTCOME    what actually happened  │
  (privileged)      │      derived after the run              │
                    └─────────────────────────────────────────┘

        agree  →  the scenario enters the dataset with that label
        differ →  the scenario is REJECTED. Never relabelled.
```

**Why this works when neither path does alone.** A is a claim about *what we told the simulator to
do*. B is a claim about *what the simulator did*. They are independent in exactly the way the spec
and the label are not — and agreement between them is free, automatic, and falsifiable.

**Why rejection rather than relabelling.** If A and B disagree, something is wrong with the recipe,
the controller, or the reading — and we do not know which. Keeping the scenario with B's label
silently launders a broken recipe into the dataset. Rejecting it puts the scenario on a queue a
human looks at. **The rejection rate is itself a quality metric** and should be published.

**What B is evaluated over.** The *privileged fact track* — CARLA server state in SI units
(`evalkit/facts.py`) — never the scene graph. The specs are evaluated over the scene graph. That
keeps B independent of everything the specs depend on: the abstraction, the adapter, the lifted
attribute set. A disagreement between a spec and the label is then a real finding about the
specification, the abstraction, or the adapter, and the three can be told apart.

---

## 4. The recipe (item 1): from statute text to a runnable configuration

One record per clause. This is the only artifact a human reviews.

```jsonc
{
  "clause": "BC-MVA-162-1",
  "text": "A driver must not cause or permit the vehicle to follow another
           vehicle more closely than is reasonable and prudent",

  // --- what the world must look like for the clause to apply at all
  "preconditions": {
    "road": "straight, >= 2 lanes same direction, no junction within 80 m",
    "actors": [{"role": "lead", "class": "car", "lane": "ego"}],
    "controls": "none required",
    "weather": "clear, dry",          // only when the clause depends on it
    "time_of_day": "any"
  },

  // --- the ONE knob the clause's threshold is monotone in
  "decisive_parameter": {"name": "headway_s", "unit": "s"},
  "compliant_setting":  {"headway_s": 3.0},
  "violating_setting":  {"headway_s": 1.0},

  // --- path B: how the outcome is checked, over the fact track
  "applies_when":   {"all": ["ego.lead.present", {"gt": ["ego.speed_mps", 2.0]}]},
  "violated_when":  {"sustained": [1.0, {"lt": ["ego.lead.headway_s", 2.0]}]},

  // --- every vague term quantified once, with who chose the number
  "quantifications": [
    {"term": "reasonable and prudent", "value": 2.0, "unit": "s", "kind": "reading",
     "note": "the two-second rule; the statute names no number. THE reviewer's decision"}
  ]
}
```

**The recipe and the reading are one artifact, extracted together.** This is the point: the
quantification of every vague term happens **exactly once**, in a place both the generator and the
verifier cite. That is what made the 20 m / 4 m divergence possible and is what prevents it here.

**Where the LLM goes.** Drafting these from statute text is a text-to-structure task with a short,
auditable output that cites its section — the right use, and the pipeline already does this kind of
work. Three controls:

1. **Ensemble.** N independent drafts of the same clause, produced blind to each other.
   Disagreement routes to a human; agreement lowers priority but still enters the audit sample.
2. **Schema validation.** Every `preconditions` term must come from a **closed vocabulary** the map
   indexer can actually satisfy (see §5 stage 1), and every fact path must exist in the fact schema.
   A recipe that names a road feature we cannot find, or a fact we do not record, is rejected at
   authoring time — not discovered three hundred simulations later.
3. **The LLM never produces the verdict.** It proposes the configuration and the reading; the
   verdict is always derived.

**Human cost:** ~300 clauses × ~10 min review ≈ 50 hours, once per jurisdiction, front-loaded. There
is no per-scenario and no per-frame annotation anywhere in this design.

---

## 5. The pipeline

```
 0  APPLICABILITY   which clauses CARLA can stage at all        → applicability.jsonl
 1  MAP INDEX       every site in every town, by feature        → sites/<town>.json
 2  RECIPES         statute text → recipe + reading (LLM+human) → recipes/<jurisdiction>.jsonl
 3  STAGE           recipe × site → two runnable configurations
 4  SIMULATE        scripted controller, fixed seed, sync mode  → rsv/*.pkl + facts.jsonl
 5  VERIFY          path A vs path B; agree → keep, differ → reject
 6  SCORE           run the clause's specs; union vs label      → per-clause pass / MISSED / FALSE ALARM
 7  PORTABILITY     which kinds of data did the pass rely on?   → sim-only pass vs would-transfer pass
```

**Stage 0 — applicability (item 2).** Largely **already done**: `ALIGNMENT_AUDIT_2026-09-14.md` §3a
classifies **87** BC MVA Part 3 driving obligations against four statuses — `lifted`,
`in_base_not_rsv`, `in_api_not_graph`, `absent` — plus `judgement` for clauses that turn on a human
standard. Roughly 40 are formalizable (most with a stated reading), roughly 30 are not, the rest are
conditional on a named gap.

*What is left:* the "Formalizable?" column is free text — **20 distinct spellings across 87 rows**.
Convert §3a to a machine-readable `applicability.jsonl` so the harness can enforce it and the
denominator is honest. An out-of-scope clause must be *published as out of scope with a reason*, not
quietly absent.

**Stage 1 — map index.** Offline, once per town. Enumerate every site by feature: signalized
approaches, stop-sign approaches, uncontrolled junctions, multi-lane straights, curves, crosswalks,
one-ways, merges. From `map.get_topology()`, `map.get_all_landmarks()`, `junction.get_waypoints()`,
`map.get_crosswalks()`, `TrafficLight.get_stop_waypoints()`. This is the **closed vocabulary** the
recipe's `preconditions` must draw from, and it turns "where does this scenario go" from a human
choice into a query.

**Stage 3–4 — staging and simulation.** Do **not** drive the vehicle under test with Traffic Manager.
TM is a black box that will not reliably produce a specific violation. Drive a fixed route with a
scripted controller whose speed profile and lateral offset are the recipe's parameters. Then the
compliant and violating runs differ in **exactly one parameter**, which is what makes a later
disagreement attributable. TM for background traffic only. Determinism (sync mode, fixed delta,
seeded TM, fixed spawn order) is a precondition and is measured, not assumed.

**Stage 5 — verify.** The gate described in §3. Also the natural place for two free cross-checks:
- CARLA's own `RunningRedLightTest` / `RunningStopTest` / `CollisionTest` / `OutsideRouteLanesTest`
  are independent implementations of clauses we also cover. Where they overlap, they validate the
  labelling machinery at zero human cost.
- A VLM over the camera stills, asked **only about perceptual facts** ("is the signal facing the ego
  red?"), cross-checked against privileged state. A disagreement detector, never an oracle.

**Stage 6 — score.** Per clause: pass / MISSED / FALSE ALARM / UNTESTED, plus the corpus-level
counts. Report separately, never blended.

---

## 5b. Stage 7 — what only the simulator can give us

A clause can pass here and mean nothing about a real vehicle, if its specs lean on data no camera
provides. Every readable element is classified — **portable** (brake lamps, signal colour),
**estimate** (position, speed, extent, class — error grows with range), **simulator-only** (lane and
junction identity, governance edges, the ego's own control inputs, stable object ids), and one
**inverted** case.

The inverted case is the trap and is not a missing feature: `check_occlusion` is false, so the scene
graph contains vehicles hidden behind buildings. A rule validated in CARLA may be firing on a vehicle
nobody could see and be silent on video, **while both runs look correct**. Stable identity is the
other structural exposure — `Core/Grounding.lean` binds one entity id for a whole trace, and a real
tracker drops, re-acquires and swaps ids under occlusion.

**Already classified:** `perception/portability.json` v2.0.0 covers all 60 lifted keys plus three
structural properties (identity, occlusion, time base); `ALIGNMENT_AUDIT_2026-09-14.md` §3c ranks
which rules are most exposed.

**What stage 7 adds:** carry that classification into the result. Each clause's pass is tagged with
the strongest class its specs depended on, and the corpus reports **two numbers** — "the
formalization works" and "it would transfer". They are different questions and a single score hides
the second one.

## 6. Item 4 — updating the SG generator

**Agreed: defer.** Do stages 0–2 first, then decide from what the recipes actually demand.

The request list already exists — `ALIGNMENT_AUDIT_2026-09-14.md` §3b, ordered by how many clauses
each unblocks. The two cheapest and highest-yield:

| Change | Unblocks |
|---|---|
| `get_velocity()` / `get_acceleration()` on **every** actor (today: ego only, `sgg.py:563`) | every "the other vehicle is stopped / faster / approaching" clause — 8 sections |
| `get_light_state()` on the **ego** (today the ego is in `exclude_ids`, `sgg.py:543`) | every signalled manoeuvre by the subject vehicle — 4 sections |

Then: `Map.get_crosswalks()`, `TrafficLight.get_stop_waypoints()`, weather from the manifest, the
`traffic.yield` blueprint, and the base-graph lane detail (width, markings, curvature) that
`process_to_junction_rsv` folds away.

**Sequencing rule:** a generator change is only worth making if a *recipe* needs it. Stage 2 produces
that evidence. Doing it the other way round adds channels nothing reads.

---

## 7. What exists today

| Stage | Status |
|---|---|
| 0 applicability | **§3a of the audit, 87 rows.** Needs converting to machine-readable |
| 1 map index | **not built.** Needs CARLA; offline, one run per town |
| 2 recipes | **10 of ~300** written, as readings only (no staging half) — `evalkit/readings/bc_mva_part3.jsonl` |
| 3 staging | **not built** |
| 4 simulation | capture runner exists; needs the scripted controller |
| 5 verify | path B implemented (`evalkit/evaluate.py`); **path A and the gate not built** |
| 6 score | implemented (`evalkit/metrics.py`), but per-*rule*; needs the per-clause union |

Supporting work already landed: the fact schema with per-field provenance; the three-valued reading
language (UNKNOWN ≠ False; UNTESTABLE ≠ NOT_APPLICABLE); mutation testing; the parameter search;
33 passing tests; and the adapter's "never fabricate a measurement" fix, which removed fabricated
zeros that were making `Pred.stopped` true on every frame of every replay capture — a channel read
by 12 of 24 rule files.

---

## 8. Proposed order

| # | Task | Needs CARLA |
|---|---|---|
| 1 | Convert §3a to `applicability.jsonl`; publish out-of-scope clauses with reasons | no |
| 2 | Extend the reading schema to a full recipe (preconditions, decisive parameter, two settings) | no |
| 3 | Build the LLM recipe drafter + ensemble + schema validation; draft all in-scope clauses | no |
| 4 | Change §6 scoring from per-rule to **per-clause union over specs**, with the vacuity guard | no |
| 5 | Map indexer (`sites.py`), one run per town | **yes** |
| 6 | Scripted controller + staging; the A-vs-B verification gate | **yes** |
| 7 | First full run; publish pass / MISSED / FALSE ALARM / UNTESTED and the **rejection rate** | **yes** |
| 8 | Tag each clause's result with the portability class its specs relied on | no |
| 9 | Revisit the generator update list against what the recipes actually demanded | — |

Items 1–4 are the critical path and need no simulator.

---

## 9. Decisions needed from you

1. **Two scenarios per clause, or two per *spec*?** This proposal says per clause, with the union
   rule. Per spec would give finer attribution at roughly n× the simulation cost.
2. **What happens to a rejected scenario?** Auto-retry with a perturbed recipe, or straight to a
   human queue? Affects how much simulation budget the gate consumes.
3. **Rejection-rate threshold.** Above what rate do we stop and fix the recipes rather than keep
   generating?
4. **Jurisdiction scope now.** BC only, or design the recipe schema against a second jurisdiction
   immediately to keep it honest? The fact layer is already jurisdiction-neutral and this has been
   demonstrated on two readings files.
