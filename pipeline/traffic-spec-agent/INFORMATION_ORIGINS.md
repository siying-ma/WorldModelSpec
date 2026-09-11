# Where every fact in a prompt comes from

The two prompt templates in `prompts/` are filled from **six kinds of source**.
The rule the repository follows is that a fact has exactly one origin, and the
prompt block that carries it is generated from that origin and names it — so a
change to the artifact reaches the agent with no second edit, and a claim can
always be checked against the thing it describes.

`run_spec doctor` enforces this. Where a check exists for a row below, it is
named.

## 1. Frozen Lean Core — the specification language

`library/TrafficSpec/Core/` is the authority for anything a rule is *written
in*. Every list below is parsed out of the file at prompt-build time; none is
stored anywhere else.

| block | generated from | by |
|---|---|---|
| `{vocab_summary}` | `Core/Vocab.lean` — `def` lines, grouped by its `-- §` headings | `summarize_vocab` |
| `{formula_summary}` | `Core/Formula.lean` — `SFProp` constructors, `frameSpan`, end-of-trace behaviour | `summarize_formula` |
| `{binder_summary}` | `Core/Grounding.lean` — binder helpers and the grounding product | `summarize_binders` |
| `{builder_summary}` | `Core/Builders.lean` — `mk*` constructor signatures, verbatim | `summarize_builders` |
| entity types, relation labels, proximity bands, capture rate, proximity-capable types | `Core/Scene.lean` — `inductive EntityType`, `inductive RelLabel`, `distanceBands`, `captureHz`, `proximityTypes` | `core_model` |
| never-bind types | `Core/Scene.lean` — constructors in no `*Types` list, so no binder can produce them | `unbindable_types` |

Checked by: `predicate references`, `formula language`, `binders cover the
model`, `capture rate`, `rate never restated`, `generator agreement`.

## 2. The adapter — the generator-to-Lean boundary

`carla/adapter.py` owns everything about the *translation*, because it performs
it. Its tables are the only record of the renames.

| fact | source | consumed by |
|---|---|---|
| which attribute keys a rule can read | `lifted_attribute_keys()` — the mapping tables plus the literal keys in `Core/Builders.lean` | the gate's `CARLA_INCOMPATIBLE`, and the prompt's attribute table |
| generator key → Lean key | `generator_key_to_lean()` | the gate, to tell an agent that reached for the generator's spelling what the Lean name is |
| generator-side keys the adapter reads | `CONSUMED_ATTRS` | the unlifted side of the key partition |
| generator label → Lean `RelLabel` | `REL_LABELS` (21 spellings onto 18 labels — many-to-one, because the generator emits more than one spelling for some relations) | `rsv source labels` |
| generator base class → `EntityType` | `BASE_TYPES` plus the name probes in `classify` | — |
| what a capture must have been recorded with | `ASSUMED_*` constants and `check_capture_preconditions` | refuses a capture whose manifest disagrees |

Checked by: `surface partitioned`, `rsv source labels`, `capture rate`.

## 3. The scene-graph generator — read, never assumed present

`scripts/diagnostics/sgg_surface.py` derives facts from `carla_sgg/*.py` with
the `ast` module — never with a regular expression, and never from a recorded
capture.

| fact | function |
|---|---|
| every attribute key an RSV node can carry | `surface()` |
| keys on base-graph waypoint nodes only, which the abstraction collapses | `base_graph_only_keys()` |
| the caller-supplied settings and where each is taken | `parameters()` |
| relation labels emitted at more than one site, i.e. overloaded | `overloaded_labels()` |
| the default threshold and relation tables | `default_tables()` |

**The generator is a sibling repository and is not guaranteed to be checked
out.** The gate therefore must not require it: `check_spec.py` uses it when
present and falls back to the schema's in-repo reason patterns otherwise.
`doctor` is where the two are held to each other, and it may require it.

## 4. `carla/schema.json` — what only it knows

Five sections. Everything derivable from §1–§3 has been removed from it, so
what remains is prose that no artifact can produce.

| section | why it cannot be derived |
|---|---|
| `relation_coverage` | which *pairs* an edge is emitted for. Core has the type lists; nothing in-repo encodes that a proximity edge always has the ego at one end, nor that a light's `controls` comes from affected lanes while a stop sign's comes from a trigger volume |
| `attribute_keys.kinds` | per key: `kind` (five distinctions, including `enum` and `integer-as-decimal`, which serialization does not make), `unit` (nine of them, documented by CARLA's API and by nothing in this repo), which entities carry it, and `from_generator_key` |
| `partially_available` | what the abstraction *destroys* — that `Sidewalk` nodes are filtered, so pavement, verge and central reservation become one `Off Road` node. Core declares one constructor and cannot say three things collapsed into it |
| `available_not_exposed` | *why* a key is not lifted. The keys are derived; the reasons are prose, and each group claims a family by regex so a new key falls into it unedited |
| `capture_preconditions` | the caller-supplied settings and the consequence of each differing. A parameter's name does not carry its consequence |

Checked by: `reading notes cover the model`, `surface partitioned`, `schema
delivery`, `preconditions cover parameters`, `schema cross-references`.

## 5. The gate — what it will reject

`tools/check_spec.py` owns its own thresholds; the prompt renders them so an
agent is not surprised by a refusal.

| fact | source |
|---|---|
| binder-domain sizes, and the grounding ceiling | `CAPTURE_ENTITY_CENSUS`, `GROUNDING_BUDGET` |
| every verdict token and what it means | the verdict table in `prompt_code.txt` |

Checked by: `binder budget coverage`, `verdict coverage`, `report format`.

## 6. Run state — the only per-iteration input

| block | source |
|---|---|
| `{laws_block}`, `{law_count}` | `laws/example/laws.jsonl` |
| `{library_summary}` | the rule files on disk |
| `{example_block}` | a real rule, path resolved from `Rules/**` |
| `{auto_notes}` | the previous iteration's outcomes |
| `{user_hints}` | `USER_HINTS.md` |
| `{progress_file}`, node spec, binders, scenarios | the plan agent's own `objectives.jsonl` |

Checked by: `prompt placeholders`, `worked example`, `documented paths`.

## What is deliberately not a source

- **No recorded capture.** A capture is produced by this project's own scripts,
  so deriving a claim from one is circular. It also under-reports: keys written
  on a branch our scenarios never took are invisible that way, and their absence
  reads as "the generator does not emit this" — the direction that discards a
  formalizable law.
- **No law corpus, in Core or in the schema.** Both are frozen before the
  pipeline sees a law, so neither may name a statute, a rule file, or a figure
  obtained by running the simulator. Checked by `frozen artifacts law-free` and
  `prompts law-free`.
- **No hand-maintained copy of anything above.** Every list removed from the
  schema was correct when written; being correct is not the same as being kept
  correct, and three of them had already drifted — an 18-of-21 label map, a
  one-of-two never-bind list, and a `multiplicity` table duplicating the gate's
  own census.
