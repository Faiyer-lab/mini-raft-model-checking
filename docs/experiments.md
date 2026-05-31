# Experiments

This document summarizes the verification and execution experiments included in the project.

The goal is to make the project reproducible and easy to inspect.

## Toolchain

The experiments were run with:

- Ubuntu 24.04;
- Spin 6.5.2;
- gcc 13.3.0;
- GNU Make 4.3;
- CMake 3.28.3;
- g++ 13.3.0.

## Summary table

| ID | Artifact | Command | Expected result | Observed result |
|---|---|---|---|---|
| E1 | Abstract leader-election model | `make verify-safe` | no violation of leader-election safety | `errors: 0` |
| E2 | Faulty voting model | `make verify-faulty` | counterexample found | `errors: 1` |
| E3 | Faulty voting trace | `make trace-faulty` | detailed counterexample trace generated | trace saved in `results/traces/` |
| E4 | Message-passing leader-election model | `make verify-messages` | no violation of leader-election safety | `errors: 0` |
| E5 | One-slot log replication model | `make verify-log` | no violation of log agreement | `errors: 0` |
| E6 | C++ nominal scenario | `./cpp/build/mini_raft_cpp nominal` | safety checks pass | `PASS` |
| E7 | C++ faulty voting scenario | `./cpp/build/mini_raft_cpp faulty-vote` | leader-election safety fails | `FAIL` |

## E1: Abstract leader-election safety

Model:

`model/mini_raft.pml`

Command:

`make verify-safe`

Property:

`ltl no_two_leaders { [] (!two_leaders_same_term) }`

Observed result:

- `errors: 0`

Interpretation:

Spin did not find any reachable state where two different nodes are leaders in the same term.

Stored output:

`results/safety_no_two_leaders_v01.txt`

## E2: Faulty voting counterexample

Model:

`model/mini_raft_faulty_vote.pml`

Command:

`make verify-faulty`

Property:

`ltl no_two_leaders { [] (!two_leaders_same_term) }`

Observed result:

- `errors: 1`

Interpretation:

Spin finds a counterexample because the faulty model allows repeated voting in the same term. This demonstrates why the one-vote-per-term rule is necessary.

Stored output:

`results/faulty_vote_counterexample_v01.txt`

## E3: Faulty voting trace

Command:

`make trace-faulty`

Observed result:

The detailed trail is replayed and stored in:

`results/traces/faulty_vote_counterexample_trace_v01.txt`

Important final state:

- `role[1] = Leader`;
- `role[2] = Leader`;
- `currentTerm[1] = 3`;
- `currentTerm[2] = 3`;
- `two_leaders_same_term = 1`.

Interpretation:

Two different nodes are leaders in the same term, violating the safety property.

## E4: Message-passing leader-election safety

Model:

`model/mini_raft_messages.pml`

Command:

`make verify-messages`

Property:

`ltl no_two_leaders { [] (!two_leaders_same_term) }`

Observed result:

- `errors: 0`

Interpretation:

The leader-election safety property still holds when vote requests and vote grants are represented as explicit messages through per-node inbox channels.

Stored output:

`results/message_passing_no_two_leaders_v02.txt`

## E5: One-slot log agreement

Model:

`model/mini_raft_log_replication.pml`

Command:

`make verify-log`

Property:

`ltl log_agreement { [] (!committed_logs_diverge) }`

Observed result:

- `errors: 0`

Interpretation:

Spin did not find any reachable state where two committed logs contain different values.

Stored output:

`results/log_agreement_v03.txt`

## E6: C++ nominal scenario

Executable:

`cpp/build/mini_raft_cpp`

Command:

`./cpp/build/mini_raft_cpp nominal`

Observed behavior:

- Node 0 becomes leader;
- value `42` is replicated to all nodes;
- all nodes commit value `42`;
- `no_two_leaders_same_term=PASS`;
- `committed_logs_agree=PASS`.

Stored output:

`results/cpp/nominal_scenario.txt`

## E7: C++ faulty voting scenario

Executable:

`cpp/build/mini_raft_cpp`

Command:

`./cpp/build/mini_raft_cpp faulty-vote`

Observed behavior:

- Node 1 becomes leader in term 1;
- Node 0 grants another vote to Node 2 in the same term;
- Node 2 also becomes leader in term 1;
- `no_two_leaders_same_term=FAIL`.

Stored output:

`results/cpp/faulty_vote_scenario.txt`

Interpretation:

The C++ faulty voting scenario mirrors the faulty Promela model and demonstrates the same safety violation at the implementation-sanity-check level.

## Reproducing all experiments

A typical reproduction sequence is:

```bash
make clean
make verify-safe
make verify-messages
make verify-log
make verify-faulty
make trace-faulty
make cpp
make cpp-run

The faulty model and the faulty C++ scenario intentionally produce violations. These violations are expected and documented.
