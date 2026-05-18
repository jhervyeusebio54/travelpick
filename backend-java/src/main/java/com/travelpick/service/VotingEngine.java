package com.travelpick.service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Weighted approval voting logic.
 * Mirrors Python {@code backend/services/voting_engine.py}.
 */
public final class VotingEngine {

    private VotingEngine() {
    }

    public static Map<Integer, Integer> computeScores(List<VoteWeight> votes) {
        Map<Integer, Integer> scores = new HashMap<>();
        for (VoteWeight vote : votes) {
            if (vote.destinationId() == null) {
                continue;
            }
            int weight = vote.weight() == null ? 0 : vote.weight();
            scores.merge(vote.destinationId(), weight, Integer::sum);
        }
        return scores;
    }

    public static Map<Integer, Integer> countVotes(List<VoteWeight> votes) {
        Map<Integer, Integer> counts = new HashMap<>();
        for (VoteWeight vote : votes) {
            if (vote.destinationId() == null) {
                continue;
            }
            counts.merge(vote.destinationId(), 1, Integer::sum);
        }
        return counts;
    }

    public static Map<Integer, Map<Integer, Integer>> voteDistribution(List<VoteWeight> votes) {
        Map<Integer, Map<Integer, Integer>> dist = new HashMap<>();
        for (VoteWeight vote : votes) {
            if (vote.destinationId() == null || vote.weight() == null) {
                continue;
            }
            dist.computeIfAbsent(vote.destinationId(), ignored -> new HashMap<>())
                    .merge(vote.weight(), 1, Integer::sum);
        }
        return dist;
    }

    public static List<Map<String, Object>> rankDestinations(
            Map<Integer, Integer> scores,
            Map<Integer, String> destMap) {
        List<Map.Entry<Integer, Integer>> items = new ArrayList<>();
        for (Integer destId : destMap.keySet()) {
            items.add(Map.entry(destId, scores.getOrDefault(destId, 0)));
        }
        items.sort(Comparator
                .<Map.Entry<Integer, Integer>>comparingInt(Map.Entry::getValue).reversed()
                .thenComparing(entry -> destMap.getOrDefault(entry.getKey(), "")));

        List<Map<String, Object>> ranking = new ArrayList<>();
        for (Map.Entry<Integer, Integer> entry : items) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("destination_id", entry.getKey());
            row.put("destination", destMap.getOrDefault(entry.getKey(), ""));
            row.put("total_score", entry.getValue());
            ranking.add(row);
        }
        return ranking;
    }

    public static Optional<Integer> getWinner(Map<Integer, Integer> scores) {
        if (scores.isEmpty()) {
            return Optional.empty();
        }
        return scores.entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey);
    }

    public record VoteWeight(Integer destinationId, Integer weight) {
    }
}
