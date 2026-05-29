/*
 * Mini-Raft faulty voting model, version 0.1-faulty
 *
 * Scope:
 * - intentionally allows repeated votes in the same term.
 * - 3 nodes;
 * - simplified leader election;
 * - one vote per node per term;
 * - majority-based leadership;
 * - bounded number of election attempts;
 * - LTL safety property: no two leaders in the same term.
 *
 * This first model intentionally abstracts away explicit network messages.
 * Message channels, log replication, faults and liveness are added later.
 */

#define N 3
#define NONE 255
#define MAX_ATTEMPTS 2

mtype = { Follower, Candidate, Leader };

byte role[N];
byte currentTerm[N];
byte votedFor[N];
byte votesReceived[N];

bool two_leaders_same_term = false;

/*
 * Updates the global safety flag.
 * The flag becomes true exactly when two different nodes are leaders
 * in the same term.
 */
inline update_safety_flag()
{
    two_leaders_same_term =
        ((role[0] == Leader && role[1] == Leader && currentTerm[0] == currentTerm[1]) ||
         (role[0] == Leader && role[2] == Leader && currentTerm[0] == currentTerm[2]) ||
         (role[1] == Leader && role[2] == Leader && currentTerm[1] == currentTerm[2]))
}

/*
 * A simplified election step.
 *
 * The candidate increments its term, votes for itself, and receives votes
 * from followers that have not voted yet in the candidate's term.
 */
inline start_election(id)
{
    role[id] = Candidate;
    currentTerm[id]++;
    votedFor[id] = id;
    votesReceived[id] = 1;

    if
    :: id != 0 && currentTerm[0] <= currentTerm[id] && true ->
        currentTerm[0] = currentTerm[id];
        votedFor[0] = id;
        votesReceived[id]++
    :: else -> skip
    fi;

    if
    :: id != 1 && currentTerm[1] <= currentTerm[id] && true ->
        currentTerm[1] = currentTerm[id];
        votedFor[1] = id;
        votesReceived[id]++
    :: else -> skip
    fi;

    if
    :: id != 2 && currentTerm[2] <= currentTerm[id] && true  ->
        currentTerm[2] = currentTerm[id];
        votedFor[2] = id;
        votesReceived[id]++
    :: else -> skip
    fi;

    if
    :: votesReceived[id] >= 2 ->
        role[id] = Leader
    :: else ->
        role[id] = Follower
    fi;

    update_safety_flag()
}

/*
 * Bounded node behavior for v0.1:
 * each node may start at most MAX_ATTEMPTS elections.
 */
proctype Node(byte id)
{
    byte attempts = 0;

    do
    :: attempts < MAX_ATTEMPTS ->
        atomic {
            start_election(id);
            attempts++
        }
    :: else -> break
    od
}

/*
 * LTL safety property:
 * always, two different leaders must not be active in the same term.
 */
ltl no_two_leaders {
    [] (!two_leaders_same_term)
}

init
{
    atomic {
        byte i = 0;

        do
        :: i < N ->
            role[i] = Follower;
            currentTerm[i] = 0;
            votedFor[i] = NONE;
            votesReceived[i] = 0;
            i++
        :: else -> break
        od;

        update_safety_flag();

        run Node(0);
        run Node(1);
        run Node(2);
    }
}
