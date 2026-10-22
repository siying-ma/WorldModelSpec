# Gap ledger

The gap ledger records what the frozen vocabulary cannot carry: one gap per proposal, proposed by
a plan, a coding or a repair session, allocated an id by the harness, decided by the operator. It
is two append-only files with one writer each: `proposals.jsonl` (the harness) and
`decisions.jsonl` (the operator's `python -m harness gap decide`); a gap's state is its proposal
with its latest decision, so a decision is never lost to a harness write. It lives
beside the rules and concepts it concerns, not under `ontology/`, because every row quotes a
law's words and names its laws, and the ontology is law-free. `counter.txt` holds the next id and
only grows: a row archived with an earlier run never gives its id to a new one.

Fields: `id`, `kind` (`atom`: no atom or enumeration value denotes the span; `operator`: the
formula language cannot express it), `span` (the verbatim words), `law_refs`, `node_id`,
`proposal` (the ontology row or the formula operator that would carry the span), `nearest` (the
closest existing atoms and the contract clause that excludes the span), `proposed_in` (run and
iteration), and for a proposal that follows a decided gap, `linked_to` and `excluding_clause`.
A decision row holds `id`, `state` (`accepted | rejected | retired`), `decision` (the operator's
reason) and `retired_by` (the ontology or Core change).

A proposal that matches a gap the operator rejected or retired is never filed again as pending:
the law goes back to its planner with the decision. A linked new proposal is filed only when it
cites the decided gap and names the contract clause that still excludes the span; whether it is a
distinct deficiency is the operator's judgement.

One ledger serves every run, but a plan session is shown only the rows on the laws of its own
corpus, plus, in a test run, the rows its base (training) run proposed: a gap filed on a test line
never reaches a training plan, and a smoke or demo run's gaps reach only the runs whose corpus
holds the same laws.

To decide a gap, run `python -m harness gap decide <id> --state retired|rejected|accepted
--decision "<reason>"` (and `--retired_by` for a retirement); for a retirement
by ontology change, change `ontology/ATOMS.md` and Core under the full split, regenerate
(`python -m scripts.gen_ontology`), switch back, and re-run the loop: the laws blocked on the
retired gap become plannable again, and only those. A rejection carries the reason the next plan
session is shown.

`python -m harness init --fresh --snapshot <run>` moves the rows still `proposed` or `accepted`
to `results/<run>/gaps_undecided.jsonl` and keeps the decided ones, so a new run is shown the
operator's decisions and not the last run's undecided proposals.
