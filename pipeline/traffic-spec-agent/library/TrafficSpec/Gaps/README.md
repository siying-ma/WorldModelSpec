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
reason), `retired_by` (for a retirement: the revision that now carries the span) and `resolved_by`
(for a rejection: where the decision now lives in the pipeline, or `particular`).

A proposal that matches a gap the operator rejected or retired is never filed again as pending:
the law goes back to its planner with the decision. A linked new proposal is filed only when it
cites the decided gap and names the contract clause that still excludes the span; whether it is a
distinct deficiency is the operator's judgement.

A gap names a deficiency of the pipeline, in training and in test alike, and a round (one run,
its resumes included) ends with every gap it filed resolved. A new run, and `init --fresh`, refuse
while a gap is `proposed` or `accepted`; then every resolved gap leaves the library for
`results/<the run that proposed it>/gaps.jsonl`, with all its decisions, and the counter keeps its
id. A new round therefore starts on an empty ledger, and a gap that comes back after its
retirement is filed as a new gap: the fix did not take. A record that cites a rejected gap still
reads its decision there, from its own run's and its base chain's archives. A row whose
`proposed_in` names no run is archived with `python -m harness gap archive --manifest <file.json>`
(`{"<gap id>": "<run>"}`). Within a round a plan session is shown only the rows on the laws of its
own corpus, and a training run refuses to start while a row names a held-out law. Each run also
keeps every gap it filed, as filed, in `results/<run>/gaps_measured.jsonl`; a test run is scored
on that file, which no later decision or archive changes.

To decide a gap, run `python -m harness gap decide <id> --state retired|rejected|accepted
--decision "<reason>"` (with `--retired_by` for a retirement, `--resolved_by` for a rejection); for a retirement
by ontology change, change `ontology/ATOMS.md` and Core under the full split, regenerate
(`python -m scripts.gen_ontology`), switch back, and re-run the loop: the laws blocked on the
retired gap become plannable again, and only those. A rejection carries the reason the next plan
session is shown.
