# Verified Properties

This document lists the formal properties checked on the Mini-Raft Promela model.

## Model version

File:

```text
model/mini_raft.pml

Version:

0.1 - bounded leader-election model

The model contains:

3 nodes;
roles: Follower, Candidate, Leader;
monotonically increasing terms;
one vote per node per term;
majority-based leadership;
bounded election attempts.

The model intentionally abstracts away:

explicit network channels;
message delays;
message loss;
log replication;
node crashes;
real-time clocks.

These aspects are planned for later versions.

P1: No two leaders in the same term
Informal statement

Two different nodes must never be leaders in the same term.

Motivation

This is a core safety requirement of leader-based consensus protocols. If two leaders exist in the same term, clients and followers may observe conflicting authority.

Promela state predicate
two_leaders_same_term =
    ((role[0] == Leader && role[1] == Leader && currentTerm[0] == currentTerm[1]) ||
     (role[0] == Leader && role[2] == Leader && currentTerm[0] == currentTerm[2]) ||
     (role[1] == Leader && role[2] == Leader && currentTerm[1] == currentTerm[2]))
LTL formula
ltl no_two_leaders {
    [] (!two_leaders_same_term)
}
Expected result

The property is expected to hold in model version 0.1.

The one-vote-per-term rule and majority voting should prevent two different candidates from both obtaining a majority in the same term.
