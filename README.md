# Model Checking a Mini-Raft Coordination Protocol

This project formally models and verifies a simplified multi-agent coordination protocol inspired by Raft.

The main verification target is a leader-election safety property:

> Two different nodes must never be leaders in the same term.

The project uses Spin/Promela for formal modelling and verification. A deliberately faulty variant is also included to demonstrate how removing the one-vote-per-term rule leads to a counterexample.

## Project scope

The current model focuses on the leader-election core of a simplified Raft-like protocol.

Included:

- 3 nodes;
- roles: `Follower`, `Candidate`, `Leader`;
- monotonically increasing terms;
- one vote per node per term in the correct model;
- majority-based leader election;
- bounded election attempts;
- LTL safety verification with Spin;
- faulty voting variant with documented counterexample.

Not included yet:

- explicit asynchronous network channels;
- log replication;
- message delays and message loss;
- crashes and recovery;
- liveness properties;
- C++ proof-of-concept.

These features are planned for later project versions.

## Repository structure

```text
mini-raft-model-checking/
├── model/
│   ├── mini_raft.pml
│   ├── mini_raft_faulty_vote.pml
│   ├── properties.md
│   └── verification_results.md
├── results/
│   ├── safety_no_two_leaders_v01.txt
│   ├── faulty_vote_counterexample_v01.txt
│   └── traces/
│       └── faulty_vote_counterexample_trace_v01.txt
├── docs/
├── cpp/
├── Makefile
├── Dockerfile
└── README.md
Requirements

The project was tested with:

Ubuntu 24.04;
Spin 6.5.2;
gcc 13.3.0;
GNU Make 4.3.

Install dependencies on Ubuntu with:

sudo apt update
sudo apt install -y spin gcc make
How to run the verification

From the repository root, run:

make verify-safe

Expected result:

errors: 0

This verifies the correct bounded leader-election model:

model/mini_raft.pml

To run the faulty voting model:

make verify-faulty

Expected result:

errors: 1

This is intentional. The faulty model removes the one-vote-per-term restriction, so Spin finds a counterexample where two nodes become leaders in the same term.

To generate the detailed counterexample trace:

make trace-faulty

The trace is stored in:

results/traces/faulty_vote_counterexample_trace_v01.txt

To remove generated Spin files:

make clean
Verified property

The main LTL property is:

ltl no_two_leaders {
    [] (!two_leaders_same_term)
}

Informally:

It is always false that two different nodes are leaders in the same term.

Verification summary

Correct model:

file: model/mini_raft.pml;
result: errors: 0;
interpretation: no violation of the no-two-leaders property was found in the bounded state space.

Faulty model:

file: model/mini_raft_faulty_vote.pml;
result: errors: 1;
interpretation: Spin finds a counterexample because repeated votes in the same term allow two candidates to both collect a majority.
Counterexample summary

The faulty model reaches a final state with:

role[1] = Leader;
role[2] = Leader;
currentTerm[1] = 3;
currentTerm[2] = 3;
two_leaders_same_term = 1.

This demonstrates that the one-vote-per-term rule is necessary for leader-election safety.

Current limitations

The current version is intentionally small. It proves only a bounded abstraction of leader-election safety, not the correctness of the full Raft protocol.

Main limitations:

no explicit message channels yet;
no log replication yet;
no timing assumptions yet;
no crash/recovery model yet;
no liveness verification yet;
no C++ proof-of-concept yet.
Planned next steps
Add an explicit message-passing model.
Add one-slot log replication.
Verify a log agreement safety property.
Explore liveness under different timing assumptions.
Implement a minimal C++ proof-of-concept mirroring the verified abstraction.
