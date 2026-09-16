# Evaluation dataset — overview

One page, for alignment. Detail lives in `EVALUATION_PROPOSAL.md`.

---

## Goal

Test whether our formalized traffic rules actually catch the violations they are supposed to catch —
at the scale of a whole statute book, and without hand-labelling anything.

## The unit of test: one law clause

```
                    ┌─────────────────────────────────────┐
   Law clause  ───► │  Spec₁   Spec₂   Spec₃   (Lean)     │
                    └─────────────────────────────────────┘
                                   │  run on
                    ┌──────────────┴──────────────────────┐
                    │  Scenario A: compliant              │
                    │  Scenario B: violating              │
                    └─────────────────────────────────────┘
```

Each clause gets **N specs** and **exactly two scenarios**. The clause passes only if:

| Scenario | Union of all its specs | Otherwise |
|---|---|---|
| **violating** | at least one spec fires | **MISSED** — the formalization does not cover the clause |
| **compliant** | no spec fires | **FALSE ALARM** — the formalization over-reaches |

Two guards keep this honest:
- **The pair is the evidence, never one scenario.** A spec that never fires passes the compliant test
  trivially; only the violating scenario gives it teeth.
- **A rule that never engages is UNTESTED, not passed.** Otherwise a library of vacuous rules scores 100%.

Result per clause: one of **pass / MISSED / FALSE ALARM / UNTESTED**.

## The hard problem, and our answer

Every scenario needs a trustworthy label, and hand-labelling ~300 clauses does not scale.

Two obvious approaches both fail on their own:
- **Trust the setup** ("we told the car to run the red light") — the simulator often doesn't do what
  it was told, and we have recorded cases of exactly that.
- **Read the label off the recording** — that is a *second formalization of the same law*. If it
  agrees with the spec we learn nothing; if it disagrees we can't tell which one is wrong. We have
  already seen one clause quantified two different ways by these two paths.

**Our answer: run both, and require them to agree.**

```
  INTENT   what we asked the simulator for   (known before the run)
                        ║ must agree
  OUTCOME  what the simulator actually did   (measured after the run)

     agree  → the scenario joins the dataset with that label
     differ → the scenario is rejected, never relabelled
```

They are independent in the right way, agreement is free and automatic, and the **rejection rate
becomes a quality metric we publish** rather than a problem we hide.

---

## Four workstreams

### 1. Law → CARLA configuration
For each clause, one record that says: what the world must look like for the clause to apply (road
structure, controls, weather, other actors), the **one parameter** that decides compliance, and its
compliant and violating settings. 

I personally recommend you to use some LLM to do this part and reviewed by a human. There are two ways we discussed in the previous meeting:
- Launch a LLM to directly capture all the world/scenario information and ask LLM to map it to the CARLA config
- Map the CARLA config scope with ICBC traffic law scope first and then ask LLM to capture the config setting (this one is more trustworthy). 

The development of the ground truth label needs to be reliable and also accurate. Method 1 might be a bit weak if we want it to be written into a section in the paper. We could discuss this more in the meeting.

This same record also states how the outcome is checked — so every vague term ("reasonable and
prudent") is **quantified exactly once**, in a place both sides cite. That single decision is what
prevents the two paths from drifting apart.

Human cost: roughly one review per clause, once per jurisdiction. 
### 2. Which laws CARLA cannot stage
Not every clause is testable — school buses, flaggers, hand signals, arrow signals, officer
direction. These must be **selected out and published with a reason**, or the denominator is
dishonest.

**Mostly done.** The 2026-09-14 alignment audit already classifies 87 BC MVA Part 3 driving
obligations: ~40 formalizable (most with a stated residue), ~30 not, the rest conditional on a named
gap. Remaining work is mechanical — turn that table into a machine-readable file the harness enforces.

### 3. What only the simulator can give us

Every rule we validate in CARLA may be leaning on something a real camera **cannot provide**. If we
do not track that, a perfect score here means nothing about a real vehicle.

So each element our specs can read is classified into one of four kinds:

| | |
|---|---|
| **portable** | a camera sees it about as well — e.g. brake lamps, signal colour |
| **estimate** | recoverable, but with error that grows with range — position, speed, size, class |
| **simulator-only** | no camera counterpart at all — lane and junction identities, which signal governs which lane, the driver's own throttle/brake inputs, stable object ids |
| **inverted** | the simulator gives *more* than reality — the scene graph includes vehicles hidden behind buildings, because occlusion is off |

The last one is the trap, and it is not a missing feature. A rule validated in CARLA may be firing on
a vehicle nobody could see, and be silent on video, while **both runs look correct**. Stable object
identity is the other one to watch: our whole rule structure assumes one id per vehicle for a whole
trace, and a real tracker does not deliver that.

**Consequence for the dataset:** we record, per clause, which kinds its specs depend on, and report
a clause that passes only by leaning on simulator-only data **separately** from one that would also
pass on video. One number for "does the formalization work", one for "would it transfer".

**Mostly done.** All 60 readable elements are already classified, and the audit ranks which rules are
most exposed. Remaining work is to carry that classification into the score.

### 4. Scene-graph generator update — **deferred, by design**
Some clauses need data the generator doesn't currently record (other vehicles' speed, the ego's own
turn signals, crosswalks, lane width). The request list already exists, ranked by how many clauses
each unlocks.

**Sequencing rule: only add a channel a workstream-1 record actually asks for.** Doing it earlier
adds data nothing reads. Revisit once 1 and 2 have completed a first pass.

---

## Status

| | |
|---|---|
| ✅ Done | the fact/label machinery, the scoring metrics, the alignment audit, the law classification and the simulator-only classification (both as documents) |
| 🔨 Next, no simulator needed | machine-readable law classification · full recipe schema · LLM drafter · switch scoring from per-rule to per-clause · carry the portability class into the score |
| ⏳ Needs CARLA | map site index · scripted scenario staging · the agreement gate · first full run |

## Open questions

1. Two scenarios per **clause**, or per **spec**? Per spec gives sharper attribution at several times
   the simulation cost.
2. When intent and outcome disagree — auto-retry with an adjusted setup, or send to a human queue?
3. BC only for now, or design against a second jurisdiction immediately to keep the schema honest?
4. Do we **gate** on portability — refuse to count a clause that only passes on simulator-only data —
   or just report the two numbers side by side? Gating is stricter but shrinks the testable set.
