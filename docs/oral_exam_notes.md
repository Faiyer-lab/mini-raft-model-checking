# Oral Exam Notes

This document summarizes how to explain the project during the oral exam.

## One-minute project summary

This project is a formal verification case study of a simplified multi-agent coordination protocol inspired by Raft.

The main goal is to check safety properties of a small Mini-Raft abstraction using Spin/Promela and to mirror the verified abstraction with a minimal C++ proof-of-concept.

The project focuses on two safety properties:

1. Leader-election safety:
   - two different nodes must never be leaders in the same term.

2. Log agreement safety:
   - two committed logs must never contain different values.

The project also includes a deliberately faulty voting model to demonstrate that removing the one-vote-per-term rule leads to a counterexample.

## Why this is relevant to IIoT / CPS

Industrial IoT and cyber-physical systems often contain distributed agents that must coordinate reliably:

- controllers;
- edge nodes;
- gateways;
- replicated services;
- autonomous components.

In these systems, coordination errors can cause inconsistent decisions or unsafe behavior.

A consensus-style protocol is relevant because it provides a way to reason about agreement, leadership, and replicated state among multiple agents.

## Why Spin/Promela

Spin/Promela is suitable because:

- Promela naturally models concurrent processes;
- channels can model message passing;
- nondeterministic interleavings can be explored automatically;
- LTL properties can express safety requirements;
- Spin can generate counterexamples when a property is violated.

## What was modelled

The project uses several model variants.

### Abstract leader-election model

File:

`model/mini_raft.pml`

Purpose:

- small first model;
- direct voting abstraction;
- verifies the basic no-two-leaders property.

Result:

- `errors: 0`.

### Faulty voting model

File:

`model/mini_raft_faulty_vote.pml`

Purpose:

- intentionally removes the one-vote-per-term rule;
- demonstrates that the safety property can fail.

Result:

- `errors: 1`;
- Spin finds a counterexample.

Key lesson:

> One vote per term is necessary for leader-election safety.

### Message-passing election model

File:

`model/mini_raft_messages.pml`

Purpose:

- refines the abstract model with explicit messages;
- uses per-node inbox channels;
- models `RequestVote` and `VoteGranted`.

Result:

- `errors: 0`.

Key lesson:

> The leader-election safety property still holds when voting is represented through explicit message passing.

### One-slot log replication model

File:

`model/mini_raft_log_replication.pml`

Purpose:

- models simplified log replication;
- assumes one stable leader;
- uses `AppendEntries` and `AppendAck`;
- checks committed log agreement.

Result:

- `errors: 0`.

Key lesson:

> In the bounded one-slot abstraction, committed logs do not diverge.

## Main properties

### P1: No two leaders in the same term

Informal statement:

> It is never possible for two different nodes to be leaders in the same term.

Promela LTL formula:

`ltl no_two_leaders { [] (!two_leaders_same_term) }`

Why it matters:

If two leaders exist in the same term, different parts of the system may accept commands from different authorities, which can later lead to inconsistent replicated state.

### P2: Committed logs do not diverge

Informal statement:

> Two committed logs must never contain different values.

Promela LTL formula:

`ltl log_agreement { [] (!committed_logs_diverge) }`

Why it matters:

A replicated system is useful only if committed state is consistent across nodes.

## Counterexample explanation

In the faulty voting model, the guard that prevents repeated voting is removed.

Correct model:

`votedFor[id] == NONE`

Faulty model:

`true`

As a consequence:

1. A candidate can receive a majority and become leader.
2. The same voters can later vote again in the same term.
3. Another candidate can also receive a majority.
4. Spin reaches a state where two nodes are leaders in the same term.

Important final trace state:

- `role[1] = Leader`;
- `role[2] = Leader`;
- `currentTerm[1] = 3`;
- `currentTerm[2] = 3`;
- `two_leaders_same_term = 1`.

This violates the LTL property.

## C++ proof-of-concept

The C++ component is not the main verification artifact. It is a sanity check.

It demonstrates two scenarios:

### Nominal scenario

Command:

`./cpp/build/mini_raft_cpp nominal`

Observed behavior:

- Node 0 becomes leader;
- value `42` is replicated;
- all nodes commit value `42`;
- leader-election safety passes;
- log agreement passes.

### Faulty voting scenario

Command:

`./cpp/build/mini_raft_cpp faulty-vote`

Observed behavior:

- Node 1 becomes leader;
- Node 0 votes again for Node 2;
- Node 2 also becomes leader in the same term;
- leader-election safety fails.

This mirrors the faulty Promela model.

## Important design choices

### Why 3 nodes?

Three nodes are the smallest meaningful cluster for majority-based agreement. With 3 nodes, a majority is 2.

### Why bounded models?

Model checking explores reachable states. Unbounded models can create infinite or extremely large state spaces. Bounded models make verification finite and reproducible.

### Why one-slot log?

The goal is to capture the essence of log agreement without modelling the full complexity of Raft logs.

### Why separate election and log replication?

Combining all features into one model would significantly increase the state space. The project separates concerns:

- election safety is checked in election models;
- log agreement is checked in the log replication model.

This makes the project easier to inspect and explain.

## Likely questions and answers

### Is this full Raft?

No. It is a simplified Mini-Raft abstraction. The project focuses on selected safety properties and keeps the model small enough for explicit-state model checking.

### What exactly did Spin prove?

Spin checked that no counterexample exists within the bounded state space of each model. For the correct models, Spin found `errors: 0`. For the faulty model, Spin found the expected counterexample.

### Does this prove the real Raft protocol correct?

No. It supports correctness arguments for the simplified abstraction only.

### Why include a faulty model?

The faulty model demonstrates that the verification is meaningful. Spin is able to find a violation when a key protocol rule is removed.

### Why does liveness require extra assumptions?

Liveness depends on timing, fairness, message delivery, and failure assumptions. Without such assumptions, a request may never be committed because messages may be delayed forever or elections may keep happening.

### Why is the C++ implementation small?

The C++ implementation is a sanity check, not the central artifact. The central artifact is the formal model and its verification results.

## How to demonstrate the project

Suggested demo sequence:

1. Show repository structure.
2. Run `make verify-safe`.
3. Run `make verify-messages`.
4. Run `make verify-log`.
5. Run `make verify-faulty`.
6. Show the faulty trace in `results/traces/`.
7. Build C++ with `make cpp`.
8. Run `./cpp/build/mini_raft_cpp nominal`.
9. Run `./cpp/build/mini_raft_cpp faulty-vote`.
10. Explain how the C++ traces correspond to the Promela models.

## Final takeaway

The project shows how formal verification can be used to reason about coordination protocols among distributed agents.

The most important result is not only that the correct models satisfy the checked safety properties, but also that a small faulty change produces an explicit counterexample.

This makes the role of the protocol rules clear and inspectable.
