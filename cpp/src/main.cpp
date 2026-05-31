#include <array>
#include <iostream>
#include <optional>
#include <string>
#include <vector>

namespace {

constexpr int N = 3;
constexpr int MAJORITY = 2;

enum class Role {
    Follower,
    Candidate,
    Leader
};

struct Node {
    int id{};
    Role role{Role::Follower};
    int term{0};
    std::optional<int> voted_for{};
    std::optional<int> log_value{};
    bool committed{false};
};

std::string role_name(Role role) {
    switch (role) {
        case Role::Follower: return "Follower";
        case Role::Candidate: return "Candidate";
        case Role::Leader: return "Leader";
    }
    return "Unknown";
}

void print_cluster(const std::array<Node, N>& nodes) {
    std::cout << "\nCluster state:\n";
    for (const auto& node : nodes) {
        std::cout << "  Node " << node.id
                  << " role=" << role_name(node.role)
                  << " term=" << node.term
                  << " votedFor=" << (node.voted_for ? std::to_string(*node.voted_for) : "none")
                  << " log=" << (node.log_value ? std::to_string(*node.log_value) : "empty")
                  << " committed=" << (node.committed ? "true" : "false")
                  << "\n";
    }
}

bool no_two_leaders_same_term(const std::array<Node, N>& nodes) {
    for (int i = 0; i < N; ++i) {
        for (int j = i + 1; j < N; ++j) {
            if (nodes[i].role == Role::Leader &&
                nodes[j].role == Role::Leader &&
                nodes[i].term == nodes[j].term) {
                return false;
            }
        }
    }
    return true;
}

bool committed_logs_agree(const std::array<Node, N>& nodes) {
    for (int i = 0; i < N; ++i) {
        for (int j = i + 1; j < N; ++j) {
            if (nodes[i].committed && nodes[j].committed &&
                nodes[i].log_value.has_value() &&
                nodes[j].log_value.has_value() &&
                nodes[i].log_value.value() != nodes[j].log_value.value()) {
                return false;
            }
        }
    }
    return true;
}

bool request_vote(std::array<Node, N>& nodes, int candidate_id, int voter_id, bool allow_revote) {
    Node& candidate = nodes[candidate_id];
    Node& voter = nodes[voter_id];

    if (candidate.term > voter.term) {
        voter.term = candidate.term;
        voter.role = Role::Follower;
        if (!allow_revote) {
            voter.voted_for.reset();
        }
    }

    const bool can_vote =
        candidate.term == voter.term &&
        (allow_revote || !voter.voted_for.has_value());

    if (can_vote) {
        voter.voted_for = candidate_id;
        std::cout << "[term " << candidate.term << "] Node "
                  << voter_id << " grants vote to Node "
                  << candidate_id << "\n";
        return true;
    }

    std::cout << "[term " << candidate.term << "] Node "
              << voter_id << " rejects vote request from Node "
              << candidate_id << "\n";
    return false;
}

bool start_election(std::array<Node, N>& nodes, int candidate_id, bool allow_revote) {
    Node& candidate = nodes[candidate_id];

    candidate.role = Role::Candidate;
    candidate.term += 1;
    candidate.voted_for = candidate_id;

    int votes = 1;

    std::cout << "[term " << candidate.term << "] Node "
              << candidate_id << " becomes Candidate and votes for itself\n";

    for (int voter_id = 0; voter_id < N; ++voter_id) {
        if (voter_id == candidate_id) {
            continue;
        }

        if (request_vote(nodes, candidate_id, voter_id, allow_revote)) {
            votes++;
        }
    }

    if (votes >= MAJORITY) {
        candidate.role = Role::Leader;
        std::cout << "[term " << candidate.term << "] Node "
                  << candidate_id << " becomes Leader with "
                  << votes << " votes\n";
        return true;
    }

    candidate.role = Role::Follower;
    std::cout << "[term " << candidate.term << "] Node "
              << candidate_id << " fails to obtain majority\n";
    return false;
}

void replicate_value(std::array<Node, N>& nodes, int leader_id, int value) {
    Node& leader = nodes[leader_id];

    if (leader.role != Role::Leader) {
        std::cout << "Node " << leader_id << " is not leader; cannot replicate\n";
        return;
    }

    std::cout << "[term " << leader.term << "] Client request value="
              << value << " received by leader Node " << leader_id << "\n";

    leader.log_value = value;
    int ack_count = 1;

    for (int follower_id = 0; follower_id < N; ++follower_id) {
        if (follower_id == leader_id) {
            continue;
        }

        nodes[follower_id].log_value = value;
        ack_count++;

        std::cout << "[term " << leader.term << "] Node "
                  << follower_id << " appends value="
                  << value << "\n";
    }

    if (ack_count >= MAJORITY) {
        for (auto& node : nodes) {
            if (node.log_value.has_value() && node.log_value.value() == value) {
                node.committed = true;
            }
        }

        std::cout << "[term " << leader.term << "] value="
                  << value << " committed by majority\n";
    }
}

int run_nominal() {
    std::array<Node, N> nodes{};
    for (int i = 0; i < N; ++i) {
        nodes[i].id = i;
    }

    std::cout << "Scenario: nominal election and one-slot log replication\n";

    start_election(nodes, 0, false);
    replicate_value(nodes, 0, 42);

    print_cluster(nodes);

    const bool election_safe = no_two_leaders_same_term(nodes);
    const bool log_safe = committed_logs_agree(nodes);

    std::cout << "\nSafety checks:\n";
    std::cout << "  no_two_leaders_same_term="
              << (election_safe ? "PASS" : "FAIL") << "\n";
    std::cout << "  committed_logs_agree="
              << (log_safe ? "PASS" : "FAIL") << "\n";

    return (election_safe && log_safe) ? 0 : 1;
}

int run_faulty_vote() {
    std::array<Node, N> nodes{};
    for (int i = 0; i < N; ++i) {
        nodes[i].id = i;
    }

    std::cout << "Scenario: faulty voting allows repeated votes in the same term\n";

    /*
     * We intentionally construct the same safety problem as in the faulty
     * Promela model: nodes can grant repeated votes, allowing two candidates
     * to become leaders in the same term.
     */
    for (auto& node : nodes) {
        node.term = 1;
        node.voted_for.reset();
    }

    nodes[1].role = Role::Candidate;
    nodes[1].voted_for = 1;
    int votes_for_1 = 1;
    if (request_vote(nodes, 1, 0, true)) votes_for_1++;
    if (votes_for_1 >= MAJORITY) {
        nodes[1].role = Role::Leader;
        std::cout << "[term 1] Node 1 becomes Leader\n";
    }

    nodes[2].role = Role::Candidate;
    nodes[2].voted_for = 2;
    int votes_for_2 = 1;
    if (request_vote(nodes, 2, 0, true)) votes_for_2++;
    if (votes_for_2 >= MAJORITY) {
        nodes[2].role = Role::Leader;
        std::cout << "[term 1] Node 2 becomes Leader\n";
    }

    print_cluster(nodes);

    const bool election_safe = no_two_leaders_same_term(nodes);

    std::cout << "\nSafety checks:\n";
    std::cout << "  no_two_leaders_same_term="
              << (election_safe ? "PASS" : "FAIL") << "\n";

    return election_safe ? 0 : 1;
}

void print_usage(const char* program) {
    std::cout << "Usage: " << program << " <scenario>\n"
              << "\nAvailable scenarios:\n"
              << "  nominal      election + one-slot log replication\n"
              << "  faulty-vote  repeated voting counterexample\n";
}

} // namespace

int main(int argc, char** argv) {
    if (argc != 2) {
        print_usage(argv[0]);
        return 2;
    }

    const std::string scenario = argv[1];

    if (scenario == "nominal") {
        return run_nominal();
    }

    if (scenario == "faulty-vote") {
        return run_faulty_vote();
    }

    print_usage(argv[0]);
    return 2;
}
