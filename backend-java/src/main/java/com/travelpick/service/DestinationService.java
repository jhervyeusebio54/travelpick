package com.travelpick.service;

import com.travelpick.model.Destination;
import com.travelpick.store.DataStore;
import java.io.IOException;
import java.util.List;
import java.util.Optional;

public class DestinationService {

    private final DataStore store;

    public DestinationService(DataStore store) {
        this.store = store;
    }

    public List<Destination> listByGroup(int groupId) throws IOException {
        return store.listDestinations(groupId);
    }

    public Optional<Destination> get(int destinationId, Integer groupId) throws IOException {
        return store.getDestination(destinationId, groupId);
    }

    public Destination create(
            int groupId,
            String name,
            String description,
            Integer id,
            String country,
            String imageUrl,
            Double rating,
            Integer popularity,
            String estimatedCost,
            String bestSeason) throws IOException {
        return store.createDestination(
                groupId,
                name,
                description,
                id,
                country,
                imageUrl,
                rating,
                popularity,
                estimatedCost,
                bestSeason);
    }
}
