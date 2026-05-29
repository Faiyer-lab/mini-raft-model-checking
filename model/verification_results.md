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
