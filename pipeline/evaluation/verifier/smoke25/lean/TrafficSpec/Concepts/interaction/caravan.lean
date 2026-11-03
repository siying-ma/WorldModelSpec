/-
  drv.interaction.caravan — Road user u is travelling as a member of a moving line of road users at this observation. The concept denotes the configuration of a line of road users travelling along one way together, each close behind the one before it and every one of them in motion; a line of more members is the same configuration, so the count of followers is bounded below only, while a gap wider than max_gap, or headings diverging by more than same_direction_cosine allows, is no longer this configuration. It is recognized at an observation thus: u is following another road user that is itself in motion, at a longitudinal gap of at most max_gap with headings agreeing within same_direction_cosine, or another road user that is itself in motion is so following u; the number of road users of the scene that are, at this observation, in motion and following another road user that is in motion on the same way as u within that gap and tolerance is at least min_followers; and u is in motion, its speed above speed_tolerance. It is not a judgement that the line is official, escorted, ceremonial or authorized, and nothing in it reads a purpose; it is not a queue standing at a signal or in congestion, every road user the concept reads as a member - u, the road user u travels directly with, each counted follower and the road user that follower travels behind - being in motion, its speed above speed_tolerance; it is not a tow or a coupling (a towed road user and the one drawing it are one combination, not two members); it says nothing about the class of its members, and reads no class: whether a member is a motor vehicle, a cycle or a person on foot is not observed here, and a caller that owes its duty only to one class states that class of the road user it judges; and it says nothing about whether the spacing is adequate, which is the caller's to judge.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    u is following another road user that is itself in motion, at a longitudinal gap of at most max_gap with headings agreeing within same_direction_cosine, or another road user that is itself in motion is so following u: atoms [], concepts ['drv.interaction.following', 'drv.motion.standstill']
    the number of road users of the scene that are, at this observation, in motion and following another road user that is in motion on the same way as u: atoms ['rel.occupies', 'st.highway'], concepts ['drv.interaction.following', 'drv.motion.standstill']
    u is in motion, its speed above speed_tolerance: atoms [], concepts ['drv.motion.standstill']

  How the first element is written. The member-to-member relation is the configuration
  `drv.interaction.following` denotes, so it is called rather than rebuilt, with this concept's
  `same_direction_cosine` and `max_gap` passed as its tolerance and its reach. The contract's two
  ways of standing in the line - u following another road user, or another road user following u -
  are the two orders of one ordered pair, so they are written as one existential over a pair of
  road users of the scene, `a` travelling behind `b`, of which one is the road user judged
  (`same a u` or `same b u`, which is also what anchors the pair to the formal). A single call of
  the relation covers both cases: where `a` is u the pair is u following another, where `b` is u it
  is another following u, and no pair that does not contain u contributes. Motion is the negation
  of `drv.motion.standstill`, called with this concept's `speed_tolerance`: the halt is "the
  magnitude of its ground velocity is at or below speed_tolerance", so its negation is the speed
  above the tolerance, and a speed the source does not observe leaves the conjunct unknown rather
  than false. Both ends of the pair are read as in motion, which is what the contract states of
  "every road user the concept reads as a member - u, the road user u travels directly with, ...":
  the end that is u is read again by the third element.

  How the second element is written. The count is `Term.aggregate .count` over the road users `f`
  of the scene: `f` is in motion, `f` occupies the way, and some road user `g` of the scene is in
  motion with `f` following `g` within the same gap and tolerance. The way is the line's own:
  `existsRegion (.lit "highway") "w"` ranges over the regions the source records as a highway (and
  over any whose membership of that kind it cannot tell, which the quantifier conjoins as unknown),
  `st.highway` being read by the quantifier's kind as an abstract-or-labelled kind is; `rel.occupies`
  ties it to the road user judged, `rel_occupies [u, w]`, and to each counted follower,
  `rel_occupies [f, w]`, which is also what anchors `f` to the formal `u` through `w`. The way is
  read as the way as a whole and never as the roadway, as `st.highway`'s exclusion requires. The
  comparison is the count at or above `min_followers`: bounded below only, as the contract says.

  How the third element is written. The motion of the road user judged is again the negation of
  `drv.motion.standstill` with this concept's tolerance, which keeps a creeping member of a halted
  queue out of the relation and reports unknown where the source observes no speed.

  Narrowings (declared below). (1) The way restriction is read of the counted follower and of u,
  under one highway region both occupy, and not separately of the road user each follower travels
  behind: `drv.interaction.following` already requires the two to occupy a common lane, so the
  leader lies on the follower's way by that relation and no further read is needed. (2) Nothing
  excludes u, or the road user u travels directly with, from the counted followers: the contract
  counts "road users of the scene" that stand in that relation and bounds the count below only, so
  the rearmost road user of a line of seven counts among the six that follow another.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.caravan

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pMaxGap : Term := .param "max_gap"
def pSameDirectionCosine : Term := .param "same_direction_cosine"
def pMinFollowers : Term := .param "min_followers"
def pSpeedTolerance : Term := .param "speed_tolerance"

/-- The variables the body binds: the two road users of the direct pairing, as the following
    relation reads them (`a` travels behind `b`, and one of the two is u), a counted follower, the
    road user that follower travels behind, and the way the line travels on. -/
def aA : Arg := .var "a"
def aB : Arg := .var "b"
def aF : Arg := .var "f"
def aG : Arg := .var "g"
def aW : Arg := .var "w"

/-- Road user `a` is travelling behind road user `b` on the same line of travel, at a longitudinal
    gap of at most `max_gap` with headings agreeing within `same_direction_cosine`. -/
def follows (a b : Arg) : Formula :=
  .derived "drv_interaction_following" [a, b] [pSameDirectionCosine, pMaxGap]

/-- The road user is in motion: it is not at a standstill within `speed_tolerance`, so its speed is
    above that tolerance; unknown where the source observes no speed. -/
def moving (x : Arg) : Formula :=
  .not (.derived "drv_motion_standstill" [x] [pSpeedTolerance])

/-- u is following another road user that is itself in motion, or another road user that is itself
    in motion is so following u: two road users of the scene, one of them u, the one travelling
    behind the other within this concept's gap and tolerance, both in motion. -/
def travelsWithAMember : Formula :=
  .existsUser "a" (.existsUser "b"
    (.and (.or (.same aA aU) (.same aB aU))
      (.and (follows aA aB) (.and (moving aA) (moving aB)))))

/-- A counted follower: a road user of the scene that is in motion, lies on the way `w`, and is
    following another road user of the scene that is itself in motion. -/
def countedFollower : Formula :=
  .and (.atom "rel_occupies" [aF, aW] [])
    (.and (moving aF)
      (.existsUser "g" (.and (moving aG) (follows aF aG))))

/-- The number of such road users at this observation. -/
def followerCount : Term :=
  .aggregate .count "f" countedFollower (.lit Q.zero .count)

/-- On one way u lies on, the number of road users in motion following another road user in motion
    is at least `min_followers`. -/
def enoughFollowers : Formula :=
  .existsRegion (.lit "highway") "w"
    (.and (.atom "rel_occupies" [aU, aW] [])
      (.cmp followerCount .ge pMinFollowers))

/-- u travels as a member of a moving line: it travels directly with a member in motion, the line
    has at least `min_followers` members following another in motion on u's way, and u is itself in
    motion. -/
def body : Formula :=
  .and travelsWithAMember (.and enoughFollowers (moving aU))

def concept : Concept :=
  { id := "drv.interaction.caravan"
    contract := "Road user u is travelling as a member of a moving line of road users at this observation. The concept denotes the configuration of a line of road users travelling along one way together, each close behind the one before it and every one of them in motion; a line of more members is the same configuration, so the count of followers is bounded below only, while a gap wider than max_gap, or headings diverging by more than same_direction_cosine allows, is no longer this configuration. It is recognized at an observation thus: u is following another road user that is itself in motion, at a longitudinal gap of at most max_gap with headings agreeing within same_direction_cosine, or another road user that is itself in motion is so following u; the number of road users of the scene that are, at this observation, in motion and following another road user that is in motion on the same way as u within that gap and tolerance is at least min_followers; and u is in motion, its speed above speed_tolerance. It is not a judgement that the line is official, escorted, ceremonial or authorized, and nothing in it reads a purpose; it is not a queue standing at a signal or in congestion, every road user the concept reads as a member - u, the road user u travels directly with, each counted follower and the road user that follower travels behind - being in motion, its speed above speed_tolerance; it is not a tow or a coupling (a towed road user and the one drawing it are one combination, not two members); it says nothing about the class of its members, and reads no class: whether a member is a motor vehicle, a cycle or a person on foot is not observed here, and a caller that owes its duty only to one class states that class of the road user it judges; and it says nothing about whether the spacing is adequate, which is the caller's to judge."
    definition := none
    args := [("u", .track)]
    params := [⟨"max_gap", .metre⟩, ⟨"same_direction_cosine", .ratio⟩, ⟨"min_followers", .count⟩, ⟨"speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := ["The statute's two words name the same observable configuration - a line of road users travelling close together along a way, all of them moving - and whatever distinguishes a motorcade from a caravan is its occasion and its organization, neither of which shows in the motion of the road users."]  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "u is following another road user that is itself in motion, at a longitudinal gap of at most max_gap with headings agreeing within same_direction_cosine, or another road user that is itself in motion is so following u"
          why := "written as one existential over an ordered pair of road users of the scene, the first travelling behind the second by drv.interaction.following with this concept's max_gap as its reach and same_direction_cosine as its tolerance, one of the two being the road user judged: where the first is u the pair is u following another road user, where the second is u it is another road user following u, so a single call of the relation carries both of the contract's cases. Both ends of the pair are read as in motion, which the contract states of every road user it reads as a member; the end that is u is read again by the third element, so the conjunction decides nothing the contract does not already require"
          kind := "reading" }
      , { span := "the number of road users of the scene that are, at this observation, in motion and following another road user that is in motion on the same way as u within that gap and tolerance"
          why := "the way restriction is written of the counted follower and of u, under one highway region both occupy (`existsRegion` over the kind, `rel.occupies` of u and of the follower), and not separately of the road user each counted follower travels behind: drv.interaction.following already requires the two to occupy a common lane, so the leader lies on the follower's way by that relation and no further read is needed; one region serves the whole count, so the line counted is a line on a single way of the scene"
          kind := "reading" }
      , { span := "the number of road users of the scene that are, at this observation, in motion and following another road user that is in motion"
          why := "nothing excludes u itself, or the road user u travels directly with, from the counted followers: the contract counts the road users of the scene standing in that relation and bounds the count below only, so in a line of seven the rearmost road user judged counts among the six that follow another"
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.caravan
