package com.travelpick.service;

import com.travelpick.model.Group;
import com.travelpick.store.DataStore;
import java.io.IOException;
import java.util.List;
import java.util.Optional;

public class GroupService {

    private final DataStore store;

    public GroupService(DataStore store) {
        this.store = store;
    }

    public List<Group> listGroups() throws IOException {
        return store.listGroups();
    }

    public Optional<Group> getGroup(int groupId) throws IOException {
        return store.getGroup(groupId);
    }

    public Optional<Group> findByCode(String code) throws IOException {
        if (code == null || code.isBlank()) {
            return Optional.empty();
        }
        String normalized = code.trim().toUpperCase();
        return store.listGroups().stream()
                .filter(group -> group.getCode() != null
                        && group.getCode().trim().toUpperCase().equals(normalized))
                .findFirst();
    }

    public Group createGroup(
            String name,
            String code,
            String privacy,
            int ownerUserId,
            List<Integer> memberUserIds) throws IOException {
        return store.createGroup(name, code, privacy, ownerUserId, memberUserIds);
    }

    public Optional<Group> addMember(int groupId, int userId) throws IOException {
        return store.addGroupMember(groupId, userId);
    }
}
