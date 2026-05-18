package com.travelpick.service;

import com.travelpick.model.Destination;
import com.travelpick.model.Vote;
import com.travelpick.store.DataStore;
import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

/** Group summary / weighted voting results. Mirrors Python results.py. */
public class ResultsService {

    private final DataStore store;
    private final GroupService groupService;
    private final DestinationService destinationService;

    public ResultsService(DataStore store, GroupService groupService, DestinationService destinationService) {
        this.store = store;
        this.groupService = groupService;
        this.destinationService = destinationService;
    }

    public Map<String, Object> getResults(int groupId) throws IOException {
        if (groupService.getGroup(groupId).isEmpty()) {
            throw new VoteService.NotFoundException("Group not found");
        }

        List<Destination> destinations = destinationService.listByGroup(groupId);
        if (destinations.isEmpty()) {
            Map<String, Object> empty = new LinkedHashMap<>();
            empty.put("winner", null);
            empty.put("total_votes", 0);
            empty.put("ranking", List.of());
            empty.put("breakdown", List.of());
            return empty;
        }

        Map<Integer, String> destMap = destinations.stream()
                .collect(Collectors.toMap(Destination::getId, Destination::getName));
        Map<Integer, Destination> destById = destinations.stream()
                .collect(Collectors.toMap(Destination::getId, destination -> destination));

        List<Vote> votes = store.listVotesForGroup(groupId);
        int totalVotes = votes.size();

        List<VotingEngine.VoteWeight> voteList = votes.stream()
                .map(vote -> new VotingEngine.VoteWeight(vote.getDestinationId(), vote.getWeight()))
                .collect(Collectors.toList());

        Map<Integer, Integer> scores = VotingEngine.computeScores(voteList);
        List<Map<String, Object>> ranking = VotingEngine.rankDestinations(scores, destMap);
        Optional<Integer> winnerId = VotingEngine.getWinner(scores);
        String winner = winnerId.map(destMap::get).orElse(null);

        Map<Integer, Integer> counts = VotingEngine.countVotes(voteList);
        Map<Integer, Map<Integer, Integer>> distributions = VotingEngine.voteDistribution(voteList);

        List<Map<String, Object>> breakdown = new ArrayList<>();
        for (Map.Entry<Integer, String> entry : destMap.entrySet()) {
            int destId = entry.getKey();
            Destination destination = destById.getOrDefault(destId, new Destination());
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("destination_id", destId);
            row.put("destination", entry.getValue());
            row.put("name", entry.getValue());
            row.put("country", destination.getCountry());
            row.put("imageUrl", destination.getImageUrl());
            row.put("rating", destination.getRating());
            row.put("popularity", destination.getPopularity());
            row.put("description", destination.getDescription());
            row.put("estimatedCost", destination.getEstimatedCost());
            row.put("bestSeason", destination.getBestSeason());
            row.put("total_score", scores.getOrDefault(destId, 0));
            row.put("vote_count", counts.getOrDefault(destId, 0));
            row.put("weight_distribution", distributions.getOrDefault(destId, Map.of()));
            breakdown.add(row);
        }

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("winner", winner);
        response.put("total_votes", totalVotes);
        response.put("ranking", ranking);
        response.put("breakdown", breakdown);
        return response;
    }
}
