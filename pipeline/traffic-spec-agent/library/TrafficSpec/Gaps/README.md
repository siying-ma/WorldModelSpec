# Gap ledger

`ledger.jsonl` records what the frozen vocabulary cannot carry: one row per gap, proposed by a
plan or a node-repair session, allocated an id by the harness, decided by the operator. It lives
beside the rules and concepts it concerns, not under `ontology/`, because every row quotes a
law's words and names its laws, and the ontology is law-free. `counter.txt` holds the next id and
only grows: a row archived with an earlier run never gives its id to a new one.

Fields: `id`, `kind` (`atom`: no atom or enumeration value denotes the span; `operator`: the
formula language cannot express it), `span` (the verbatim words), `law_refs`, `node_id`,
`proposal` (the ontology row or the formula operator that would carry the span), `nearest` (the
closest existing atoms and the contract clause that excludes the span), `state`
(`proposed | accepted | rejected | retired`), `decision` (the operator's reason), `retired_by`
(the ontology or Core change), `proposed_in` (run and iteration).

One ledger serves every run, but a plan session is shown only the rows on the laws of its own
corpus, plus, in a test run, the rows its base (training) run proposed: a gap filed on a test line
never reaches a training plan, and a smoke or demo run's gaps reach only the runs whose corpus
holds the same laws.

To decide a gap, edit `state`, `decision` and, for a retirement, `retired_by`; for a retirement
by ontology change, change `ontology/ATOMS.md` and Core under the full split, regenerate
(`python -m scripts.gen_ontology`), switch back, and re-run the loop: the laws blocked on the
retired gap become plannable again, and only those. A rejection carries the reason the next plan
session is shown.

`python -m harness init --fresh --snapshot <run>` moves the rows still `proposed` or `accepted`
to `results/<run>/gaps_undecided.jsonl` and keeps the decided ones, so a new run is shown the
operator's decisions and not the last run's undecided proposals.
