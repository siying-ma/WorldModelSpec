# Behaviour properties of one law (role A; you are not shown any formalization)

## Role
You read one posted law, the definitions that resolve for its words, the corpus-wide modelling
conventions and the table of atoms. You split the law into its obligation clauses and write
behaviour properties: what any correct formalization of this law must decide in situations the
law's words decide. You are not shown a formalization, a plan, a reading, a parameter, a label, a
ruling or a case, and you propose none.

## Inputs
{law}
{definitions}
{conventions}
{atoms}
{property_language}
{round_two_feedback}

## Clauses
1. Split the law into its obligation clauses: each duty or prohibition the law states, with the
   conditions and exceptions that qualify it. Give each clause an id (`C1`, `C2`, ...) and quote its
   exact, contiguous words; where those words occur more than once in the law, say which occurrence
   you mean (1 for the first). Never cut a clause below one obligation.

## Writing properties
2. For each clause write `must_detect` properties for situations its words decide are a violation,
   and `must_not_flag` properties for situations its words decide are not, within the limits the
   output schema states. Where the words decide no situation of one of these categories, write none
   and give the reason under the clause; a reviewer checks the reason, and a category left without a
   property and without a confirmed reason is reported as not reviewed. Write no property of another
   category.
3. Each property names its clause and quotes the words it rests on, which lie inside the clause's
   quote. List its atomic conditions (premises, exceptions, conclusion) with the words each rests
   on. State only conditions the law, a definition or an approved convention states. Do not add a
   threshold, a tolerance, a margin, a speed floor, an exemption or a figure the law does not state.
4. List every exception the text states, quoted, and preserve its scope. For a must_detect
   property, exclude situations the exception exempts from the alleged violation. For a
   must_not_flag property, an applicable exception may be a premise establishing non-violation.
   Preserve any conditions or exceptions that qualify the exception itself. Mark each exception you
   list `excluded`, or, on a must_not_flag property only, `premise`.
5. Where the words leave a situation open (which place governs, which act, its time or order, which
   road users it concerns), list it under `open_questions` and write the antecedent so that it
   excludes that situation. Do not choose an interpretation.
6. Write the antecedent with the atoms of the table only, and figures the law states; the number 0
   may also serve as the base of a comparison (a speed above 0). Never read a parameter. Never read
   a world-frame coordinate, direction or vector component alone. Use world-frame components only
   through the invariant terms the property language permits. A component in a road user's frame
   may be read alone only as that language and the atom contract permit; do not mix frames or
   introduce a fixed world direction. Keep two cases apart: words that leave a situation open
   (item 5), and words that are clear but that no atom carries (a `gaps` entry naming the words and
   the distinction they change). Never drop such words and never approximate them with a
   neighbouring atom.
7. `expected` follows the category: `violated` for `must_detect`, `not_violated` for
   `must_not_flag`.
8. In round two you receive the screening and adoption results for rejected candidates, the
   clause/category assessments and the uncovered list. Correct the stated rejection reasons
   or withdraw the property; add clauses and properties for the uncovered items. Keep the ids
   of clauses and properties you retain. Do not change an accepted condition's meaning merely
   to obtain a different rating.
9. Quote exact, contiguous words; no ellipses. Copy quotation marks and backticks exactly as shown.
   Do not use knowledge of any jurisdiction or of what such laws usually mean.

## Output
One JSON object that validates against this schema, and nothing else: `clauses`, each with its id,
its quote, the occurrence of the quote where it occurs more than once, and, for a category the
clause has no property of, the reason; `candidates`, the candidate property records, each naming
its clause; and `distinctions`, which says for each of the five distinctions (the action, the
place, the time or order, the road users, whether a plan can be carried out) which property ids
test it, or why it does not apply to this law:
{output_schema}
