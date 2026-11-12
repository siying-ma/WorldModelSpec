# Concept recheck — what does the contract decide on these facts?

## Role

A concept's contract states what the concept denotes. You are shown its current contract, what the
names its words use denote, the parameters it names with their values, and the facts of one
situation as the harness executed them. Decide what the contract's words decide on those facts at
the observation judged. You are shown no code and no earlier decision; you do not judge code,
propose a fix, or look for further situations.

## Inputs (injected below)

- **The contract** — the concept's meaning, and the definition it quotes when it has one.
- **The contracts** — what each atom and concept the contract's words use denotes.
- **The parameters** — each parameter the concept names: its unit, its meaning and its value here.
- **The executed facts** — the scenes in time order as the harness ran them, the grounding, the
  regions, the instant judged and the instance, in Core units, with the fields the concept reads
  that a scene leaves unobserved.
- **The question** — whether the concept is a formula or a quantity, and so what to answer.

### Contract

`drv.interaction.overtakes`: Road user a overtakes and passes road user b: travelling with headings aligned, a goes from wholly behind b to wholly ahead of it. a is wholly behind b at an observation where drv.position.behind of a relative to b holds and drv.position.behind of b relative to a does not; a is wholly ahead of b where drv.position.behind of b relative to a holds and drv.position.behind of a relative to b does not. Where both hold, as headings that are aligned but not parallel allow for bodies apart sideways, a is neither wholly behind nor wholly ahead of b. The act is recognized at the observation at which a becomes wholly ahead of b, provided that a was wholly behind b at an earlier observation and the headings stayed aligned (rel.same_direction with the alignment tolerance) at every observation from that one to the recognition. Its observed beginning is the last observation at which a was wholly behind b before the recognition. The concept holds at the recognition observation only. Where the recording shows no observation of a wholly behind b before a becomes wholly ahead of it, with the headings aligned at every observation since the recording began, whether a overtook b is unknown, never false. Not a stand-in for a lane change or for contact between the bodies; it does not say in which lane either travels.


### The contracts of the names the contract's words use

| id | contract |
|---|---|
| `drv.position.behind` | Road user a is behind road user b at an observation: their headings are aligned and b's body lies wholly ahead of a's along a's heading. Measured as headings aligned (rel.same_direction with the alignment tolerance, the cosine of the largest angle between the headings counted as aligned), the bearing of b from a (rel.bearing) pointing forward in a's frame, and the two footprints' projections on a's heading sharing no length (rel.longitudinal_overlap below zero). Either road user may be at rest. Not a stand-in for following in the same lane: b may travel in another lane. |
| `rel.same_direction` | headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1 |


### Parameters

- `alignment` (ratio): the cosine of the largest angle between the two headings counted as aligned; its value here: 0.5 ratio


### The executed facts

What the harness ran, as the trace states it (numbers in Core units: metres, seconds, m/s, m/s², degrees and degrees per second).

- grounding: `a` = track 1, `b` = track 2
- the observation judged: t = 1000 ms
- parameters: `alignment` = 0.5 ratio

Scene t = 0 ms:
- track 1: kin.position [0, 0]; kin.heading [1, 0]; kin.extent [1, 0.5, 0.5]
- track 2: kin.position [0, 10]; kin.heading [-1, 0]; kin.extent [1, 0.5, 0.5]
- occupancy derived from the geometry before running: none
Scene t = 1000 ms (the observation judged):
- track 1: kin.position [0, 0]; kin.heading [1, 0]; kin.extent [1, 0.5, 0.5]
- track 2: kin.position [10, 30]; kin.heading [1, -1]; kin.extent [1, 0.5, 0.5]
- occupancy derived from the geometry before running: none


### The question

The concept is a formula. Answer whether the contract's words, read on these facts at the observation judged, hold, fail, or leave it undecided.


## How to decide

1. **Read the contract's words on the facts.** Apply them to the grounding, the regions and the
   instance named, at the observation judged, using what the contracts above say each name denotes
   and the parameter values given.
2. **A formula.** Answer `holds` when the contract's words, under every reasonable reading of them,
   say the concept is true of these facts; `fails` when, under every reasonable reading, they say it
   is false.
3. **A quantity.** Answer the interval the contract's words put the value in on these facts: `lo`
   and `hi`, each `[value, unit]` in a unit of the value's dimension, both ends included, `lo` at
   most `hi`; a value the words fix exactly is an interval whose ends are equal. The interval spans
   every value a reasonable reading of the words allows.
4. **undecided** — the words decide nothing here: reasonable readings of them give different
   answers on these facts, or the answer turns on a fact the facts leave unobserved. Never guess an
   answer the words do not give. Say which in `undecided_by`: `facts` when the answer turns on a
   fact the facts leave unobserved, `contract` when the facts are complete and the readings of the
   words still differ.
5. **Facts only.** Decide on the executed facts. Keys listed as unverified annotations are no fact
   of the situation.
6. Quote, verbatim, the words of the contract that decide your answer (for `undecided`, the words
   that leave it open). Do not use knowledge of any law or jurisdiction.

## Output

JSON, this schema and nothing more. For a formula:

```
{"verdict": "holds | fails", "reason": "<one or two sentences>", "quote": "<the contract's deciding words, verbatim>"}
{"verdict": "undecided", "undecided_by": "facts | contract", "reason": "<one or two sentences>", "quote": "<the contract's words that leave it open, verbatim>"}
```

For a quantity, an interval, or `undecided`:

```
{"interval": {"lo": [<value>, "<unit>"], "hi": [<value>, "<unit>"]}, "reason": "<one or two sentences>", "quote": "<the contract's deciding words, verbatim>"}
{"verdict": "undecided", "undecided_by": "facts | contract", "reason": "<one or two sentences>", "quote": "<the contract's words that leave it open, verbatim>"}
```

## Finish

Finish when the JSON is written. No commentary outside it.
