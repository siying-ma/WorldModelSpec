# Gap ledger

`ledger.jsonl` records what the ontology cannot carry: one row per gap, proposed by a plan session
and allocated an id by the harness, decided by the operator (design: `pipeline/DesignFile/PIPELINE_V2_DESIGN.md` §9).
It lives here, not under `ontology/`, because every row quotes a law's words and names its laws,
and the ontology is law-free.

Fields: `id`, `kind` (`atom | value | primitive | operator | definition | unresolvable`), `span` (the
verbatim words), `law_refs`, `node_id`, `proposal` (an ontology row, a primitive row, a formula
operator, a definition source), `nearest` (the closest existing atoms and the contract clause that
excludes the span), `parameter` (a value gap's reading parameter), `state`
(`proposed | accepted | rejected | retired`), `decision` (the operator's reason), `retired_by` (the
ontology or Core change), `proposed_in` (run and iteration).

One ledger serves every run, but a plan session is shown only the rows on the laws of its own
corpus, plus, in a test run, the rows its base (training) run proposed: a gap filed on a test line
never reaches a training plan, and a smoke or demo run's gaps reach only the runs whose corpus
holds the same laws (`GapLedger.visible`).

To decide a gap, edit `state`, `decision` and, for a retirement, `retired_by`, then regenerate the
ontology and Core (`python -m scripts.gen_ontology`) and re-run the loop: the laws blocked on a
retired gap become plannable again, and only those. A `value` gap retires by itself once its
`parameter` is set in the base reading.
