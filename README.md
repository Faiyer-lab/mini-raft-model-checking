# Model Checking a Mini-Raft Coordination Protocol

This project formally models and verifies a simplified multi-agent coordination protocol inspired by Raft.

The project uses Spin/Promela for formal modelling and verification. It focuses on safety properties of leader election and one-slot log replication. A deliberately faulty voting variant is also included to demonstrate how removing the one-vote-per-term rule leads to a counterexample.

A minimal C++ proof-of-concept is included as a runnable sanity check that mirrors the verified abstraction.

## Project scope

The project focuses on a simplified Mini-Raft-like protocol.

Included:

- 3 nodes;
- roles: `Follower`, `Candidate`, `Leader`;
- monotonically increasing terms;
- one vote per node per term in the correct model;
- majority-based leader election;
- bounded election attempts;
- explicit message-passing leader-election model;
- one-slot log replication model;
- LTL safety verification with Spin;
- faulty voting model with documented counterexample;
- minimal C++ proof-of-concept.

The project intentionally does not include:

- full Raft;
- arbitrary-length logs;
- persistent storage;
- snapshots;
- cluster membership changes;
- real networking in C++;
- crashes and recovery;
- full liveness verification.

## Repository structure

```text
mini-raft-model-checking/
├── model/
│   ├── mini_raft.pml
│   ├── mini_raft_faulty_vote.pml
│   ├── mini_raft_messages.pml
│   ├── mini_raft_log_replication.pml
│   ├── properties.md
│   └── verification_results.md
├── results/
│   ├── safety_no_two_leaders_v01.txt
│   ├── faulty_vote_counterexample_v01.txt
│   ├── message_passing_no_two_leaders_v02.txt
│   ├── log_agreement_v03.txt
│   ├── cpp/
│   │   ├── nominal_scenario.txt
│   │   └── faulty_vote_scenario.txt
│   └── traces/
│       └── faulty_vote_counterexample_trace_v01.txt
├── docs/
│   ├── abstraction_mapping.md
│   ├── experiments.md
│   ├── limitations.md
│   └── oral_exam_notes.md
├── cpp/
│   ├── CMakeLists.txt
│   └── src/
│       └── main.cpp
├── Makefile
├── Dockerfile
└── README.md
Requirements

The project was tested with:

Ubuntu 24.04;
Spin 6.5.2;
gcc 13.3.0;
g++ 13.3.0;
CMake 3.28.3;
GNU Make 4.3.

Install dependencies on Ubuntu with:

sudo apt update
sudo apt install -y spin gcc g++ cmake make
How to run the verification

From the repository root, run:

make verify-safe

Expected result:

errors: 0

This verifies the abstract bounded leader-election model:

model/mini_raft.pml

To run the message-passing leader-election model:

make verify-messages

Expected result:

errors: 0

This verifies:

model/mini_raft_messages.pml

To run the one-slot log replication model:

make verify-log

Expected result:

errors: 0

This verifies:

model/mini_raft_log_replication.pml

To run the faulty voting model:

make verify-faulty

Expected result:

errors: 1

This is intentional. The faulty model removes the one-vote-per-term restriction, so Spin finds a counterexample where two nodes become leaders in the same term.

To generate the detailed counterexample trace:

make trace-faulty

The trace is stored in:

results/traces/faulty_vote_counterexample_trace_v01.txt

To run the main verification targets together:

make all

Expected result sequence:

errors: 0
errors: 0
errors: 0
errors: 1

The final errors: 1 is expected because it belongs to the deliberately faulty model.

Verified properties
P1: No two leaders in the same term

Informal statement:

Two different nodes must never be leaders in the same term.

Promela LTL formula:

ltl no_two_leaders {
    [] (!two_leaders_same_term)
}

This property is checked in:

model/mini_raft.pml;
model/mini_raft_messages.pml;
model/mini_raft_faulty_vote.pml.

The correct models satisfy the property. The faulty model violates it intentionally.

P2: Committed logs do not diverge

Informal statement:

Two committed logs must never contain different values.

Promela LTL formula:

ltl log_agreement {
    [] (!committed_logs_diverge)
}

This property is checked in:

model/mini_raft_log_replication.pml

Spin reports:

errors: 0
Verification summary
Correct abstract leader-election model
file: model/mini_raft.pml;
command: make verify-safe;
result: errors: 0;
interpretation: no violation of the no-two-leaders property was found in the bounded state space.
Correct message-passing leader-election model
file: model/mini_raft_messages.pml;
command: make verify-messages;
result: errors: 0;
interpretation: no violation of the no-two-leaders property was found when vote requests and vote grants are exchanged through explicit inbox channels.
One-slot log replication model
file: model/mini_raft_log_replication.pml;
command: make verify-log;
result: errors: 0;
interpretation: no violation of committed log agreement was found in the bounded one-slot replication model.
Faulty voting model
file: model/mini_raft_faulty_vote.pml;
command: make verify-faulty;
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

C++ proof-of-concept

The repository includes a minimal C++ proof-of-concept.

Build it with:

make cpp

Run the nominal scenario:

./cpp/build/mini_raft_cpp nominal

Expected result:

leader election succeeds;
value 42 is replicated;
no_two_leaders_same_term=PASS;
committed_logs_agree=PASS.

Run the faulty voting scenario:

./cpp/build/mini_raft_cpp faulty-vote

Expected result:

two leaders appear in the same term;
no_two_leaders_same_term=FAIL.

The faulty C++ scenario mirrors the faulty Promela model.

You can also run both C++ scenarios with:

make cpp-run

The faulty scenario intentionally returns a failure code. The Makefile ignores it because the failure is expected and documented.

Documentation

Additional documentation is available in:

docs/abstraction_mapping.md;
docs/experiments.md;
docs/limitations.md;
docs/oral_exam_notes.md.
Current limitations

The current version is intentionally small. It verifies bounded abstractions, not the full Raft protocol.

Main limitations:

no full Raft log;
no persistent storage;
no crash/recovery model;
no real networking in the C++ component;
no full liveness verification;
no real-time election timeout model.
Planned next steps

Possible future extensions:

explore liveness under explicit fairness and timing assumptions;
add optional message loss scenarios;
add richer diagrams;
extend the one-slot log model to multiple log indices.
