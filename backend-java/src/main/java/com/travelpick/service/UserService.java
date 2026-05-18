package com.travelpick.service;

import com.travelpick.model.User;
import com.travelpick.store.DataStore;
import java.io.IOException;
import java.util.Optional;

/** All user operations delegate to users.json via {@link DataStore}. */
public class UserService {

    private final DataStore store;

    public UserService(DataStore store) {
        this.store = store;
    }

    public Optional<User> getUser(int userId) throws IOException {
        return store.getUser(userId);
    }

    public Optional<User> findByEmail(String email) throws IOException {
        return store.findUserByEmail(email);
    }

    public User ensureUser(int userId, String name, String email) throws IOException {
        return store.ensureUser(userId, name, email);
    }

    public User createUser(String name, String email, Integer id) throws IOException {
        return store.createUser(name, email, id);
    }

    public User assignUserToGroup(int groupId, Integer existingUserId, String name, String email)
            throws IOException {
        return store.assignUserToGroup(groupId, existingUserId, name, email);
    }

    public User registerGroupVoter(int groupId, String name, String email) throws IOException {
        return store.registerGroupVoter(groupId, name, email);
    }

    public DataStore.SignUpResult signUp(
            String username, String email, String password, Integer groupId, String groupCode)
            throws IOException {
        return store.signUp(username, email, password, groupId, groupCode);
    }

    public Optional<User> authenticate(String identifier, String password) throws IOException {
        return store.authenticate(identifier, password);
    }

    public User setGroupMembership(int userId, int groupId, String groupCode, String groupRole)
            throws IOException {
        return store.setUserGroupMembership(userId, groupId, groupCode, groupRole);
    }

    public void requireUserExists(int userId) throws IOException {
        if (store.getUser(userId).isEmpty()) {
            throw new IllegalArgumentException("User not found");
        }
    }
}
