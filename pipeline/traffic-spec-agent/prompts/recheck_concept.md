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

{contract}

{contracts}

{parameters}

{facts}

{question}

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
