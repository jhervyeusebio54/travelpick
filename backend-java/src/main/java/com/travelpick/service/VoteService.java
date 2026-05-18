package com.travelpick.service;

import com.travelpick.model.Destination;
import com.travelpick.model.Vote;
import com.travelpick.store.DataStore;
import com.travelpick.util.Validators;
import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

public class VoteService {

    private final DataStore store;
    private final UserService userService;
    private final GroupService groupService;
    private final DestinationService destinationService;

    public VoteService(
            DataStore store,
            UserService userService,
            GroupService groupService,
            DestinationService destinationService) {
        this.store = store;
        this.userService = userService;
        this.groupService = groupService;
        this.destinationService = destinationService;
    }

    public List<Vote> listForGroup(int groupId) throws IOException {
        return store.listVotesForGroup(groupId);
    }

    public Map<String, Object> submitVote(int userId, int destinationId, int weight, Integer groupId) throws IOException {
        Validators.validatePositiveInt(userId, "user_id");
        Validators.validatePositiveInt(destinationId, "destination_id");
        Validators.validateWeight(weight);

        Optional<Destination> destination = destinationService.get(destinationId, groupId);
        if (destination.isEmpty()) {
            throw new NotFoundException("Destination not found");
        }
        if (groupId != null && destination.get().getGroupId() != groupId) {
            throw new BadRequestException("Destination is not in this group");
        }

        int resolvedGroupId = groupId == null ? destination.get().getGroupId() : groupId;
        userService.requireUserExists(userId);
        groupService.addMember(resolvedGroupId, userId);

        Vote saved = store.upsertVote(userId, destinationId, weight, resolvedGroupId);
        String message = saved.isCreated() ? "Vote recorded" : "Vote updated";
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("message", message);
        response.put("vote_id", saved.getId());
        response.put("user_id", saved.getUserId());
        response.put("destination_id", saved.getDestinationId());
        response.put("weight", saved.getWeight());
        return response;
    }

    public Map<String, Object> submitBatch(List<VoteRequest> votes) throws IOException {
        List<Map<String, Object>> saved = new ArrayList<>();
        for (VoteRequest vote : votes) {
            saved.add(submitVote(vote.userId(), vote.destinationId(), vote.weight(), vote.groupId()));
        }
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("message", "Votes saved");
        response.put("votes", saved);
        return response;
    }

    public record VoteRequest(int userId, int destinationId, int weight, Integer groupId) {
    }

    public static class NotFoundException extends RuntimeException {
        public NotFoundException(String message) {
            super(message);
        }
    }

    public static class BadRequestException extends RuntimeException {
        public BadRequestException(String message) {
            super(message);
        }
    }
}
