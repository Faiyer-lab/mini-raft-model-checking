# Final Checklist

This checklist summarizes the final project artifacts and the commands needed to reproduce the results.

## Repository

Project repository:

`mini-raft-model-checking`

Main entry point:

`README.md`

## Formal models

| File | Purpose | Expected result |
|---|---|---|
| `model/mini_raft.pml` | Abstract bounded leader-election model | `errors: 0` |
| `model/mini_raft_messages.pml` | Message-passing leader-election model | `errors: 0` |
| `model/mini_raft_log_replication.pml` | One-slot log replication model | `errors: 0` |
| `model/mini_raft_faulty_vote.pml` | Faulty repeated-voting model | `errors: 1` |

## Verified properties

Leader-election safety:

`ltl no_two_leaders { [] (!two_leaders_same_term) }`

Log agreement safety:

`ltl log_agreement { [] (!committed_logs_diverge) }`

## Reproduction commands

Run all Spin verification targets:

```bash
make clean
make all

Expected sequence:

errors: 0
errors: 0
errors: 0
errors: 1

The final errors: 1 is expected because it belongs to the deliberately faulty model.

Run only the correct models:

make verify-safe
make verify-messages
make verify-log

Run the faulty model:

make verify-faulty

Generate the faulty counterexample trace:

make trace-faulty
C++ proof-of-concept

Build:

make cpp

Run both C++ scenarios:

make cpp-run

Expected C++ checks:

no_two_leaders_same_term=PASS
committed_logs_agree=PASS
no_two_leaders_same_term=FAIL

The final FAIL is expected because it belongs to the faulty voting scenario.

Stored results

Spin verification outputs:

results/safety_no_two_leaders_v01.txt
results/message_passing_no_two_leaders_v02.txt
results/log_agreement_v03.txt
results/faulty_vote_counterexample_v01.txt

Counterexample trace:

results/traces/faulty_vote_counterexample_trace_v01.txt

C++ outputs:

results/cpp/nominal_scenario.txt
results/cpp/faulty_vote_scenario.txt
Documentation

Project documentation:

README.md
model/properties.md
model/verification_results.md
docs/abstraction_mapping.md
docs/experiments.md
docs/limitations.md
docs/oral_exam_notes.md
Final verification status

The project includes:

a working formal model;
multiple refinement levels;
a documented faulty counterexample;
reproducible verification commands;
a minimal runnable C++ proof-of-concept;
documentation for review and oral examination.

This satisfies the expected deliverables:

formal model;
LTL property set;
verification results;
documented counterexample;
C++ proof-of-concept;
reproducible repository.
