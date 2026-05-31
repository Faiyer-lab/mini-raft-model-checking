SPIN=spin
CC=gcc

MODEL_SAFE=model/mini_raft.pml
MODEL_FAULTY=model/mini_raft_faulty_vote.pml
MODEL_MESSAGES=model/mini_raft_messages.pml
MODEL_LOG=model/mini_raft_log_replication.pml

RESULTS_DIR=results
TRACES_DIR=results/traces

.PHONY: all verify-safe verify-faulty verify-messages verify-log trace-faulty clean

all: verify-safe verify-messages verify-log verify-faulty

verify-safe:
	@mkdir -p $(RESULTS_DIR)
	@rm -f pan pan.* *.trail
	$(SPIN) -a $(MODEL_SAFE)
	$(CC) -o pan pan.c
	./pan -a | tee $(RESULTS_DIR)/safety_no_two_leaders_v01.txt

verify-faulty:
	@mkdir -p $(RESULTS_DIR)
	@rm -f pan pan.* *.trail
	$(SPIN) -a $(MODEL_FAULTY)
	$(CC) -o pan pan.c
	-./pan -a | tee $(RESULTS_DIR)/faulty_vote_counterexample_v01.txt

verify-messages:
	@mkdir -p $(RESULTS_DIR)
	@rm -f pan pan.* *.trail
	$(SPIN) -a $(MODEL_MESSAGES)
	$(CC) -o pan pan.c
	./pan -a | tee $(RESULTS_DIR)/message_passing_no_two_leaders_v02.txt

verify-log:
	@mkdir -p $(RESULTS_DIR)
	@rm -f pan pan.* *.trail
	$(SPIN) -a $(MODEL_LOG)
	$(CC) -o pan pan.c
	./pan -a | tee $(RESULTS_DIR)/log_agreement_v03.txt

trace-faulty:
	@mkdir -p $(TRACES_DIR)
	$(SPIN) -t -p -g -l -k mini_raft_faulty_vote.pml.trail $(MODEL_FAULTY) | tee $(TRACES_DIR)/faulty_vote_counterexample_trace_v01.txt

clean:
	rm -f pan pan.* *.trail _spin_nvr.tmp
