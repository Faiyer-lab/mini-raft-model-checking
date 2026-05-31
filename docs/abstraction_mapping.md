# Abstraction Mapping

This document explains how the project maps the informal Mini-Raft protocol concepts to the Promela models and to the C++ proof-of-concept.

The goal is not to implement full Raft. The goal is to build a small, inspectable abstraction that is suitable for model checking and then mirror the same abstraction in a runnable C++ sanity check.

## Scope of the abstraction

The project focuses on two safety aspects:

1. Leader-election safety:
   - two different nodes must never be leaders in the same term.

2. Log agreement safety:
   - two committed logs must never contain different values.

The abstraction intentionally keeps the system small:

- 3 nodes;
- bounded election attempts;
- one-slot log;
- no persistence;
- no dynamic membership;
- no snapshots;
- no real networking;
- no real-time clocks.

## Mapping table

| Protocol concept | Promela representation | C++ representation | Notes |
|---|---|---|---|
| Node | `proctype Node(byte id)` or specialized processes such as `LeaderNode` and `FollowerNode` | `struct Node` | The Promela models split behavior across processes; the C++ PoC uses a simple array of nodes. |
| Node identity | `byte id` | `int id` | Node IDs are `0`, `1`, and `2`. |
| Role | `mtype = { Follower, Candidate, Leader }` | `enum class Role` | Same abstract role set. |
| Term | `currentTerm[N]` | `term` field in `Node` | Terms are simplified bounded integers. |
| Vote record | `votedFor[N]` | `std::optional<int> voted_for` | Represents whether a node has already voted in the current term. |
| Majority | `MAJORITY = 2` | `MAJORITY = 2` | In a 3-node cluster, 2 votes are enough for majority. |
| Leader election | `start_election(id)` | `start_election(nodes, candidate_id, allow_revote)` | The correct model enforces one vote per term. |
| Faulty voting | `mini_raft_faulty_vote.pml` | `faulty-vote` scenario | Both intentionally allow repeated votes to demonstrate a counterexample. |
| Network | Per-node `inbox[N]` channels in `mini_raft_messages.pml` | Direct function calls / deterministic simulation | C++ is a sanity check, not a distributed implementation. |
| Vote request | `RequestVote` message | `request_vote(...)` function | The message-passing Promela model makes this explicit. |
| Vote granted | `VoteGranted` message | return value of `request_vote(...)` | C++ compresses the message into a function result. |
| Log entry | `logValue[N]` and `hasLog[N]` | `std::optional<int> log_value` | One-slot log only. |
| AppendEntries | `AppendEntries` message | `replicate_value(...)` | Promela models explicit append messages; C++ uses a deterministic loop. |
| AppendAck | `AppendAck` message | acknowledgement counter in `replicate_value(...)` | Both model majority-based commit. |
| Commit flag | `committed[N]` | `bool committed` | Indicates that a node's one-slot log is considered committed. |
| Leader safety predicate | `two_leaders_same_term` | `no_two_leaders_same_term(...)` | Checked with LTL in Promela and as a runtime check in C++. |
| Log agreement predicate | `committed_logs_diverge` | `committed_logs_agree(...)` | Checked with LTL in Promela and as a runtime check in C++. |

## Promela model variants

### `model/mini_raft.pml`

This is the first bounded abstraction of leader election. It does not model explicit messages. Voting is represented directly inside the election step.

Purpose:

- establish the basic leader-election safety property;
- keep the first state space small and easy to inspect.

Checked property:

`ltl no_two_leaders { [] (!two_leaders_same_term) }`

### `model/mini_raft_faulty_vote.pml`

This is a deliberately faulty version of the first model.

Difference:

- the one-vote-per-term guard is removed;
- nodes can vote repeatedly in the same term.

Purpose:

- demonstrate that Spin finds a counterexample;
- show that the one-vote-per-term rule is necessary for leader-election safety.

### `model/mini_raft_messages.pml`

This model refines leader election by introducing explicit message passing.

Added elements:

- one inbox channel per node;
- `RequestVote` messages;
- `VoteGranted` messages.

Purpose:

- make the model closer to a distributed protocol;
- verify that the same leader-election safety property still holds under asynchronous interleavings.

### `model/mini_raft_log_replication.pml`

This model focuses on one-slot log replication.

Assumption:

- leader election is abstracted away;
- one stable leader is assumed.

Added elements:

- one-slot log;
- `AppendEntries` messages;
- `AppendAck` messages;
- majority-based commit.

Checked property:

`ltl log_agreement { [] (!committed_logs_diverge) }`

## C++ proof-of-concept

The C++ component is intentionally minimal. It is not a replacement for the formal model.

It serves three purposes:

1. Show that the abstraction corresponds to runnable behavior.
2. Provide readable nominal and faulty execution traces.
3. Support oral-exam explanation with concrete executions.

Available scenarios:

- `nominal`
  - elects Node 0 as leader;
  - replicates value `42`;
  - checks leader-election safety;
  - checks committed log agreement.

- `faulty-vote`
  - intentionally allows repeated voting;
  - creates two leaders in the same term;
  - reproduces the same kind of violation as the faulty Promela model.

## Important abstraction choices

### Why only 3 nodes?

A 3-node cluster is the smallest cluster where majority voting is meaningful and failures of agreement can be demonstrated.

### Why bounded attempts?

Model checking explores all reachable states. Unbounded elections can create an infinite or extremely large state space. Bounded attempts make the verification finite and reproducible.

### Why one-slot logs?

The project targets the essence of log agreement, not full Raft log management. A one-slot log is enough to check whether committed values can diverge.

### Why no real network in C++?

The C++ component is a proof-of-concept and sanity check. The formal model is the main artifact. Real networking would add implementation complexity without improving the model-checking argument.
