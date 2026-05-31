# Limitations

This document describes the main limitations of the current project.

The limitations are intentional. The project is designed as a small, inspectable model-checking case study rather than a complete implementation of Raft.

## Not a full Raft implementation

The project models a simplified Mini-Raft-like protocol.

It does not implement or verify the full Raft protocol. In particular, it does not include:

- persistent storage;
- log compaction;
- snapshots;
- cluster membership changes;
- leader lease mechanisms;
- full client interaction model;
- recovery after restart;
- arbitrary-length logs.

The goal is to focus on a small set of protocol properties that can be understood, checked, and explained clearly.

## Bounded model checking scope

The Promela models use bounded abstractions:

- 3 nodes;
- bounded election attempts;
- bounded channels;
- one-slot log replication.

These bounds make the state space finite and reproducible.

The results therefore mean:

> No violation was found within the modeled bounded abstraction.

They do not mean:

> The full Raft protocol has been proven correct in all possible deployments.

## Simplified timing model

The current models do not represent real-time clocks, randomized election timeouts, or timing constraints.

Timing is represented only indirectly through nondeterministic interleavings of process actions.

Consequences:

- safety properties can still be meaningfully checked;
- liveness properties are not fully addressed yet;
- real timing assumptions are left for future extensions.

## Simplified network model

The message-passing model uses explicit inbox channels, but it does not fully model a real network.

Currently omitted:

- message loss;
- message duplication;
- network partitions;
- reordering beyond what is induced by model interleavings;
- latency distributions;
- bandwidth limits.

The current message-passing model is sufficient to show that the leader-election safety property is preserved when vote requests and vote grants are exchanged explicitly.

## One-slot log

The log replication model uses a single abstract log slot.

This is enough to study the core safety question:

> Can two committed logs contain different values?

However, it does not model:

- multiple log indices;
- previous log term/index checks;
- leader completeness;
- conflict resolution;
- overwriting uncommitted entries;
- commit index advancement over longer logs.

A full Raft log model would require a much larger state space.

## Stable leader assumption in log replication

The log replication model assumes one stable leader.

Leader election is verified separately in the election models.

This separation is an intentional modelling choice:

- leader-election safety is checked in `mini_raft.pml` and `mini_raft_messages.pml`;
- log agreement is checked in `mini_raft_log_replication.pml`.

Combining both into one model is possible but would significantly increase state-space complexity.

## C++ proof-of-concept limitations

The C++ component is a runnable sanity check, not a production distributed system.

It does not include:

- real networking;
- concurrency;
- disk persistence;
- retries;
- randomized timers;
- fault recovery.

It mirrors the verified abstraction using deterministic scenarios:

- nominal election and replication;
- faulty repeated voting.

The formal Promela models remain the main verification artifacts.

## Liveness not fully verified

The current project primarily verifies safety properties.

Checked safety properties:

- no two leaders in the same term;
- committed logs do not diverge.

Liveness properties such as:

> If a request arrives, it is eventually committed.

are not fully verified yet.

This is because liveness depends heavily on fairness, timing, and network assumptions. Future work may add explicit assumptions and compare cases where liveness holds or fails.

## Why these limitations are acceptable

The project aims to be:

- small enough to inspect;
- reproducible;
- suitable for model checking;
- understandable during an oral exam;
- useful as a teaching demonstrator.

The chosen abstraction captures the core reasoning behind two important coordination properties while avoiding unnecessary implementation complexity.
