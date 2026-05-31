/*
 * Mini-Raft log replication model, version 0.3
 *
 * Scope:
 * - 3 nodes;
 * - one abstract stable leader;
 * - one-slot replicated log;
 * - explicit AppendEntries and AppendAck messages;
 * - majority-based commit;
 * - LTL safety property: committed logs never diverge.
 *
 * This model focuses only on the log agreement part.
 * Leader election was verified separately in previous models.
 */

#define N 3
#define NONE 255
#define LEADER_ID 0
#define MAJORITY 2
#define INBOX_SIZE 8

mtype = {
    Follower,
    Leader,
    AppendEntries,
    AppendAck
};

byte role[N];
byte logValue[N];
bool hasLog[N];
bool committed[N];
byte ackCount;

bool committed_logs_diverge = false;
bool request_sent = false;

chan inbox[N] = [INBOX_SIZE] of { mtype, byte, byte };
/* message fields: kind, src, value */

inline update_log_safety_flag()
{
    committed_logs_diverge =
        ((committed[0] && committed[1] && logValue[0] != logValue[1]) ||
         (committed[0] && committed[2] && logValue[0] != logValue[2]) ||
         (committed[1] && committed[2] && logValue[1] != logValue[2]))
}

inline send_append_entries(from_id, to_id, value)
{
    inbox[to_id]!AppendEntries(from_id, value)
}

inline send_append_ack(from_id, to_id, value)
{
    inbox[to_id]!AppendAck(from_id, value)
}

inline broadcast_append_entries(value)
{
    if
    :: LEADER_ID != 0 -> send_append_entries(LEADER_ID, 0, value)
    :: else -> skip
    fi;

    if
    :: LEADER_ID != 1 -> send_append_entries(LEADER_ID, 1, value)
    :: else -> skip
    fi;

    if
    :: LEADER_ID != 2 -> send_append_entries(LEADER_ID, 2, value)
    :: else -> skip
    fi
}

inline leader_client_request(value)
{
    request_sent = true;

    hasLog[LEADER_ID] = true;
    logValue[LEADER_ID] = value;
    ackCount = 1;

    broadcast_append_entries(value);
    update_log_safety_flag()
}

inline handle_append_entries(self, src, value)
{
    if
    :: role[self] == Follower ->
        hasLog[self] = true;
        logValue[self] = value;
        send_append_ack(self, src, value)
    :: else -> skip
    fi;

    update_log_safety_flag()
}

inline handle_append_ack(self, src, value)
{
    if
    :: self == LEADER_ID && hasLog[self] && logValue[self] == value ->
        ackCount++;

        if
        :: ackCount >= MAJORITY ->
            committed[LEADER_ID] = true;

            if
            :: hasLog[0] && logValue[0] == value -> committed[0] = true
            :: else -> skip
            fi;

            if
            :: hasLog[1] && logValue[1] == value -> committed[1] = true
            :: else -> skip
            fi;

            if
            :: hasLog[2] && logValue[2] == value -> committed[2] = true
            :: else -> skip
            fi
        :: else -> skip
        fi
    :: else -> skip
    fi;

    update_log_safety_flag()
}

proctype LeaderNode()
{
    mtype kind;
    byte src;
    byte value;

    do
    :: !request_sent ->
        atomic {
            if
            :: leader_client_request(1)
            :: leader_client_request(2)
            fi
        }

    :: inbox[LEADER_ID]?kind(src, value) ->
        if
        :: kind == AppendAck ->
            atomic {
                handle_append_ack(LEADER_ID, src, value)
            }
        :: else -> skip
        fi

    :: timeout -> break
    od
}

proctype FollowerNode(byte id)
{
    mtype kind;
    byte src;
    byte value;

    do
    :: inbox[id]?kind(src, value) ->
        if
        :: kind == AppendEntries ->
            atomic {
                handle_append_entries(id, src, value)
            }
        :: else -> skip
        fi

    :: timeout -> break
    od
}

ltl log_agreement {
    [] (!committed_logs_diverge)
}

init
{
    atomic {
        byte i = 0;

        do
        :: i < N ->
            role[i] = Follower;
            logValue[i] = NONE;
            hasLog[i] = false;
            committed[i] = false;
            i++
        :: else -> break
        od;

        role[LEADER_ID] = Leader;
        ackCount = 0;
        request_sent = false;
        update_log_safety_flag();

        run LeaderNode();
        run FollowerNode(1);
        run FollowerNode(2);
    }
}
