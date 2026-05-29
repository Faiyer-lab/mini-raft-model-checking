/*
 * Mini-Raft message-passing model, version 0.2
 *
 * Scope:
 * - 3 nodes;
 * - explicit RequestVote and VoteGranted messages;
 * - one inbox channel per node;
 * - one vote per node per term;
 * - majority-based leadership;
 * - bounded election attempts;
 * - LTL safety property: no two leaders in the same term.
 *
 * This model is still intentionally small.
 * Log replication, crashes and liveness are added later.
 */

#define N 3
#define NONE 255
#define MAX_ATTEMPTS 1
#define MAJORITY 2
#define INBOX_SIZE 8

mtype = {
    Follower,
    Candidate,
    Leader,
    RequestVote,
    VoteGranted
};

byte role[N];
byte currentTerm[N];
byte votedFor[N];
byte votesReceived[N];
byte electionAttempts[N];

bool two_leaders_same_term = false;

chan inbox[N] = [INBOX_SIZE] of { mtype, byte, byte };
/* message fields: kind, src, term */

inline update_safety_flag()
{
    two_leaders_same_term =
        ((role[0] == Leader && role[1] == Leader && currentTerm[0] == currentTerm[1]) ||
         (role[0] == Leader && role[2] == Leader && currentTerm[0] == currentTerm[2]) ||
         (role[1] == Leader && role[2] == Leader && currentTerm[1] == currentTerm[2]))
}

inline send_request_vote(from_id, to_id)
{
    inbox[to_id]!RequestVote(from_id, currentTerm[from_id])
}

inline send_vote_granted(from_id, to_id, vote_term)
{
    inbox[to_id]!VoteGranted(from_id, vote_term)
}

inline broadcast_request_vote(id)
{
    if
    :: id != 0 -> send_request_vote(id, 0)
    :: else -> skip
    fi;

    if
    :: id != 1 -> send_request_vote(id, 1)
    :: else -> skip
    fi;

    if
    :: id != 2 -> send_request_vote(id, 2)
    :: else -> skip
    fi
}

inline start_election(id)
{
    role[id] = Candidate;
    currentTerm[id]++;
    votedFor[id] = id;
    votesReceived[id] = 1;
    electionAttempts[id]++;

    broadcast_request_vote(id);
    update_safety_flag()
}

inline handle_request_vote(self, src, term)
{
    if
    :: term > currentTerm[self] ->
        currentTerm[self] = term;
        role[self] = Follower;
        votedFor[self] = NONE
    :: else -> skip
    fi;

    if
    :: term == currentTerm[self] && votedFor[self] == NONE ->
        votedFor[self] = src;
        send_vote_granted(self, src, term)
    :: else -> skip
    fi;

    update_safety_flag()
}

inline handle_vote_granted(self, src, term)
{
    if
    :: role[self] == Candidate && term == currentTerm[self] ->
        votesReceived[self]++;

        if
        :: votesReceived[self] >= MAJORITY ->
            role[self] = Leader
        :: else -> skip
        fi
    :: else -> skip
    fi;

    update_safety_flag()
}

proctype Node(byte id)
{
    mtype kind;
    byte src;
    byte term;

    do
    :: electionAttempts[id] < MAX_ATTEMPTS ->
        atomic {
            start_election(id)
        }

    :: inbox[id]?kind(src, term) ->
        if
        :: kind == RequestVote ->
            atomic {
                handle_request_vote(id, src, term)
            }
        :: kind == VoteGranted ->
            atomic {
                handle_vote_granted(id, src, term)
            }
        fi

    :: else -> break
    od
}

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
            electionAttempts[i] = 0;
            i++
        :: else -> break
        od;

        update_safety_flag();

        run Node(0);
        run Node(1);
        run Node(2);
    }
}
