# Gap ledger

`ledger.jsonl` records what the ontology cannot carry: one row per gap, proposed by a plan session
and allocated an id by the harness, decided by the operator (design: `pipeline/DesignFile/PIPELINE_V2_DESIGN.md` §9).

Fields: `id`, `kind` (`atom | value | derived | operator | definition | unresolvable`), `span` (the
verbatim words), `law_refs`, `node_id`, `proposal` (an ontology row, a derived-concept row, a
formula operator, a definition source), `nearest` (the closest existing atoms and the contract
clause that excludes the span), `state` (`proposed | accepted | rejected | retired`), `decision`
(the operator's reason), `retired_by` (the ontology or Core change), `proposed_in` (run and iteration).

To decide a gap, edit `state`, `decision` and, for a retirement, `retired_by`, then regenerate the
ontology and Core (`python -m scripts.gen_ontology`) and re-run the loop: the laws blocked on a
retired gap become plannable again, and only those.
