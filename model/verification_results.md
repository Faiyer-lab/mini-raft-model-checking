# Verification Results

This document records the verification results obtained with Spin.

## Toolchain

The current results were produced with:

- Spin Version 6.5.2;
- gcc 13.3.0;
- Ubuntu 24.04.

## Model v0.1

File: `model/mini_raft.pml`

Scope:

- bounded leader election;
- 3 nodes;
- at most 2 election attempts per node;
- no explicit network model;
- no log replication yet.

## Checked property

LTL property:

`ltl no_two_leaders { [] (!two_leaders_same_term) }`

## Commands

The verification was run with:

- `rm -f pan pan.* *.trail`
- `spin -a model/mini_raft.pml`
- `gcc -o pan pan.c`
- `./pan -a`

## Result

Spin completed the full state-space search with no errors.

Important output:

- `State-vector 64 byte, depth reached 100, errors: 0`
- `196 states, stored`
- `51 states, matched`
- `247 transitions (= stored+matched)`
- `917 atomic steps`

## Interpretation

Within the bounded abstraction of model v0.1, Spin did not find any execution in which two different nodes become leaders in the same term.

This supports the expected safety argument for the simplified leader-election model: a node can vote for at most one candidate in a term, and leadership requires a majority of votes.

## Notes on unreached states

Spin also reports an unreached final state in the generated never claim:

`unreached in claim no_two_leaders`

This is expected for this type of always-safety LTL property and is not interpreted as a verification failure.

## Limitations

This result does not yet prove correctness of a complete Raft protocol. In particular, model v0.1 does not include:

- asynchronous message channels;
- delayed or lost messages;
- log replication;
- crashes;
- recovery;
- liveness properties.

These aspects are addressed in later model versions.

---

## Faulty voting model v0.1

File: `model/mini_raft_faulty_vote.pml`

This model intentionally removes the one-vote-per-term restriction. In the correct model, a node grants a vote only when `votedFor[id] == NONE`. In the faulty model, this guard is replaced by `true`, allowing repeated votes in the same term.

### Checked property

LTL property:

`ltl no_two_leaders { [] (!two_leaders_same_term) }`

### Result

Spin finds a counterexample.

Important output:

- `errors: 1`
- `assertion violated`
- `two_leaders_same_term = 1`

### Counterexample interpretation

The final state of the trace contains:

- `role[1] = Leader`;
- `role[2] = Leader`;
- `currentTerm[1] = 3`;
- `currentTerm[2] = 3`;
- `two_leaders_same_term = 1`.

This means that two different nodes become leaders in the same term.

The counterexample shows that the one-vote-per-term rule is necessary for the safety property. If nodes can vote repeatedly in the same term, two candidates can both collect a majority and become leaders simultaneously.

### Stored artifacts

- Verification output: `results/faulty_vote_counterexample_v01.txt`
- Detailed trace: `results/traces/faulty_vote_counterexample_trace_v01.txt`

---

## Message-passing model v0.2

File: `model/mini_raft_messages.pml`

This model refines the original bounded leader-election abstraction by introducing explicit message passing.

Compared with model v0.1, this version includes:

- one inbox channel per node;
- explicit `RequestVote` messages;
- explicit `VoteGranted` messages;
- asynchronous interleavings of node actions;
- the same one-vote-per-term rule;
- the same majority-based leadership rule.

### Checked property

LTL property:

`ltl no_two_leaders { [] (!two_leaders_same_term) }`

### Result

Spin completed the full state-space search with no errors.

Important output:

- `State-vector 168 byte, depth reached 160, errors: 0`
- `78812 states, stored`
- `101106 states, matched`
- `179918 transitions (= stored+matched)`
- `157650 atomic steps`

### Interpretation

Within the bounded message-passing abstraction of model v0.2, Spin did not find any execution in which two different nodes become leaders in the same term.

This strengthens the previous result because voting is no longer represented as a direct procedure call inside the election step. Instead, vote requests and granted votes are exchanged through explicit per-node inbox channels.

---

## C++ proof-of-concept

Directory: `cpp/`

The C++ component is not used as the main verification artifact. It is a runnable sanity check that mirrors the verified abstraction.

### Nominal scenario

Command:

`./cpp/build/mini_raft_cpp nominal`

Observed behavior:

- Node 0 becomes leader in term 1;
- client value `42` is replicated to all nodes;
- all logs contain value `42`;
- all logs are committed;
- `no_two_leaders_same_term=PASS`;
- `committed_logs_agree=PASS`.

Stored output:

`results/cpp/nominal_scenario.txt`

### Faulty voting scenario

Command:

`./cpp/build/mini_raft_cpp faulty-vote`

Observed behavior:

- Node 1 becomes leader in term 1;
- Node 0 later grants another vote to Node 2 in the same term;
- Node 2 also becomes leader in term 1;
- `no_two_leaders_same_term=FAIL`.

Stored output:

`results/cpp/faulty_vote_scenario.txt`

This mirrors the faulty Promela model and demonstrates that repeated voting can violate the leader-election safety property.
