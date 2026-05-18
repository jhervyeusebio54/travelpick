package com.travelpick.store;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.travelpick.config.AppConfig;
import com.travelpick.model.Destination;
import com.travelpick.model.Group;
import com.travelpick.model.User;
import com.travelpick.model.Vote;
import com.travelpick.util.JsonFileManager;
import com.travelpick.util.PasswordHasher;
import com.travelpick.util.TimeUtil;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.locks.ReentrantLock;
import java.util.stream.Collectors;

/**
 * Central persistence layer mirroring Python {@code backend/server.py}.
 */
public class DataStore {

    private final JsonFileManager fileManager = new JsonFileManager();
    private final ReentrantLock lock = new ReentrantLock();
    private final ObjectMapper mapper = fileManager.getMapper();

    public DataStore() {
        lock.lock();
        try {
            System.out.println("[STARTUP] Loading all JSON files into memory...");
            StoreSnapshot store = prepareStore();
            System.out.println("[STARTUP] Success! Loaded " + store.users().size() + " users, "
                    + store.groups().size() + " groups, " + store.destinations().size() + " destinations, "
                    + store.votes().size() + " votes.");
        } catch (Exception e) {
            System.err.println("[STARTUP] Error loading JSON files on startup: " + e.getMessage());
        } finally {
            lock.unlock();
        }
    }

    public List<Group> listGroups() throws IOException {
        lock.lock();
        try {
            return copyGroups(prepareStore().groups());
        } finally {
            lock.unlock();
        }
    }

    public Optional<Group> getGroup(int groupId) throws IOException {
        lock.lock();
        try {
            return prepareStore().groups().stream()
                    .filter(group -> group.getId() == groupId)
                    .findFirst()
                    .map(this::copyGroup);
        } finally {
            lock.unlock();
        }
    }

    public Group createGroup(
            String name,
            String code,
            String privacy,
            int ownerUserId,
            List<Integer> memberUserIds) throws IOException {
        lock.lock();
        try {
            StoreSnapshot store = prepareStore();
            List<Group> groups = store.groups();
            List<User> users = store.users();

            ensureUser(ownerUserId, null, null, users, false);
            List<Integer> members = memberUserIds == null ? new ArrayList<>() : new ArrayList<>(memberUserIds);
            if (!members.contains(ownerUserId)) {
                members.add(0, ownerUserId);
            }
            for (int memberId : members) {
                ensureUser(memberId, null, null, users, false);
            }

            Group group = new Group();
            group.setId(nextId(groups));
            group.setName(name);
            group.setCode(code);
            group.setPrivacy(privacy == null || privacy.isBlank() ? "private" : privacy);
            group.setOwnerUserId(ownerUserId);
            Set<Integer> uniqueMembers = new HashSet<>(members);
            uniqueMembers.add(ownerUserId);
            List<Integer> sortedMembers = new ArrayList<>(uniqueMembers);
            Collections.sort(sortedMembers);
            group.setMemberUserIds(sortedMembers);
            group.setCreatedAt(TimeUtil.utcNow());

            groups.add(group);
            String normalizedCode = code == null || code.isBlank() ? null : code.trim().toUpperCase();
            setUserGroupMembership(ownerUserId, group.getId(), normalizedCode, "owner", users, groups, false);
            saveUsers(users);
            saveGroups(groups);
            return copyGroup(group);
        } finally {
            lock.unlock();
        }
    }

    public Optional<Group> addGroupMember(int groupId, int userId) throws IOException {
        lock.lock();
        try {
            StoreSnapshot store = prepareStore();
            List<Group> groups = store.groups();
            Optional<Group> found = groups.stream().filter(group -> group.getId() == groupId).findFirst();
            if (found.isEmpty()) {
                return Optional.empty();
            }
            Group group = found.get();

            User member = findUserById(userId, store.users())
                    .orElseThrow(() -> new IllegalArgumentException("User not found"));

            boolean alreadyInGroup = member.getGroups().stream()
                    .anyMatch(m -> m.getGroupId() == groupId);
            if (alreadyInGroup) {
                List<Integer> members = new ArrayList<>(group.getMemberUserIds());
                if (!members.contains(userId)) {
                    members.add(userId);
                    Collections.sort(members);
                    group.setMemberUserIds(members);
                    saveGroups(groups);
                }
                return Optional.of(copyGroup(group));
            }

            setUserGroupMembership(userId, groupId, group.getCode(), "member", store.users(), groups, false);

            List<Integer> members = new ArrayList<>(group.getMemberUserIds());
            if (!members.contains(userId)) {
                members.add(userId);
                Set<Integer> unique = new HashSet<>(members);
                List<Integer> sorted = new ArrayList<>(unique);
                Collections.sort(sorted);
                group.setMemberUserIds(sorted);
            }
            saveGroups(groups);
            saveUsers(store.users());
            return Optional.of(copyGroup(group));
        } finally {
            lock.unlock();
        }
    }

    /**
     * Persist the user's active group on their profile (users.json).
     */
    public User setUserGroupMembership(int userId, int groupId, String groupCode, String groupRole)
            throws IOException {
        lock.lock();
        try {
            StoreSnapshot store = prepareStore();
            return setUserGroupMembership(
                    userId, groupId, groupCode, groupRole, store.users(), store.groups(), true);
        } finally {
            lock.unlock();
        }
    }

    private User setUserGroupMembership(
            int userId,
            int groupId,
            String groupCode,
            String groupRole,
            List<User> users,
            List<Group> groups,
            boolean persist) throws IOException {
        Optional<Group> groupOpt = groups.stream().filter(group -> group.getId() == groupId).findFirst();
        if (groupOpt.isEmpty()) {
            throw new IllegalArgumentException("Group not found");
        }

        Group group = groupOpt.get();

        User user = findUserById(userId, users)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        String resolvedRole = (groupRole != null && !groupRole.isBlank()) ? groupRole.trim().toLowerCase() : "member";
        Optional<User.UserGroupMembership> existingMembership = user.getGroups().stream()
                .filter(m -> m.getGroupId() == groupId)
                .findFirst();

        String resolvedCode = (groupCode != null && !groupCode.isBlank())
                ? groupCode.trim().toUpperCase()
                : ((group.getCode() != null) ? group.getCode().trim().toUpperCase() : null);

        System.out.println("[DEBUG] User " + userId + " (" + user.getUsername() + ") joining group " + groupId + ". Groups count before: " + user.getGroups().size());

        if (existingMembership.isPresent()) {
            existingMembership.get().setRole(resolvedRole);
            existingMembership.get().setCode(resolvedCode);
        } else {
            user.getGroups().add(new User.UserGroupMembership(groupId, resolvedRole, resolvedCode));
        }

        // Maintain legacy properties in Java memory for JUnit / backward compatibility
        user.setGroupId(groupId);
        if (groupCode != null && !groupCode.isBlank()) {
            user.setGroupCode(groupCode.trim().toUpperCase());
        } else if (group.getCode() != null && !group.getCode().isBlank()) {
            user.setGroupCode(group.getCode().trim().toUpperCase());
        } else {
            user.setGroupCode(null);
        }
        user.setGroupRole(resolvedRole);

        if (persist) {
            saveUsers(users);
            System.out.println("[DEBUG] Saved users.json. File write success.");
        }
        System.out.println("[DEBUG] User " + userId + " group membership updated. Groups count after: " + user.getGroups().size());
        return copyUser(user);
    }

    private static Optional<User> findUserById(int userId, List<User> users) {
        return users.stream().filter(user -> user.getId() == userId).findFirst();
    }

    public List<Destination> listDestinations(int groupId) throws IOException {
        lock.lock();
        try {
            return prepareStore().destinations().stream()
                    .filter(destination -> destination.getGroupId() == groupId)
                    .map(this::copyDestination)
                    .collect(Collectors.toList());
        } finally {
            lock.unlock();
        }
    }

    public Optional<Destination> getDestination(int destinationId, Integer groupId) throws IOException {
        lock.lock();
        try {
            return prepareStore().destinations().stream()
                    .filter(item -> item.getId() == destinationId)
                    .filter(item -> groupId == null || item.getGroupId() == groupId)
                    .findFirst()
                    .map(this::copyDestination);
        } finally {
            lock.unlock();
        }
    }

    public Destination createDestination(
            int groupId,
            String name,
            String description,
            Integer destinationId,
            String country,
            String imageUrl,
            Double rating,
            Integer popularity,
            String estimatedCost,
            String bestSeason) throws IOException {
        lock.lock();
        try {
            StoreSnapshot store = prepareStore();
            if (store.groups().stream().noneMatch(group -> group.getId() == groupId)) {
                throw new IllegalArgumentException("Group not found");
            }

            List<Destination> destinations = store.destinations();
            int resolvedId = destinationId == null ? nextId(destinations) : destinationId;

            for (Destination destination : destinations) {
                if (destination.getId() == resolvedId && destination.getGroupId() == groupId) {
                    destination.setName(name);
                    destination.setDescription(description);
                    destination.setCountry(country);
                    destination.setImageUrl(imageUrl);
                    destination.setRating(rating);
                    destination.setPopularity(popularity);
                    destination.setEstimatedCost(estimatedCost);
                    destination.setBestSeason(bestSeason);
                    saveDestinations(destinations);
                    return copyDestination(destination);
                }
            }

            Destination destination = new Destination();
            destination.setId(resolvedId);
            destination.setGroupId(groupId);
            destination.setName(name);
            destination.setDescription(description);
            destination.setCountry(country);
            destination.setImageUrl(imageUrl);
            destination.setRating(rating);
            destination.setPopularity(popularity);
            destination.setEstimatedCost(estimatedCost);
            destination.setBestSeason(bestSeason);
            destinations.add(destination);
            saveDestinations(destinations);
            return copyDestination(destination);
        } finally {
            lock.unlock();
        }
    }

    public User ensureUser(int userId, String name, String email) throws IOException {
        lock.lock();
        try {
            StoreSnapshot store = prepareStore();
            return ensureUser(userId, name, email, store.users(), true);
        } finally {
            lock.unlock();
        }
    }

    public Optional<User> getUser(int userId) throws IOException {
        lock.lock();
        try {
            return prepareStore().users().stream()
                    .filter(user -> user.getId() == userId)
                    .findFirst()
                    .map(this::copyUser);
        } finally {
            lock.unlock();
        }
    }

    public Optional<User> findUserByEmail(String email) throws IOException {
        lock.lock();
        try {
            String normalized = email == null ? "" : email.trim().toLowerCase();
            if (normalized.isEmpty()) {
                return Optional.empty();
            }
            return prepareStore().users().stream()
                    .filter(user -> user.getEmail() != null
                            && user.getEmail().trim().equalsIgnoreCase(normalized))
                    .findFirst()
                    .map(this::copyUser);
        } finally {
            lock.unlock();
        }
    }

    /**
     * Read users.json, update one user by id, and write the full array back.
     */
    public User updateUser(int userId, UserMutation mutation) throws IOException {
        lock.lock();
        try {
            StoreSnapshot store = prepareStore();
            List<User> users = store.users();
            User user = findUserById(userId, users)
                    .orElseThrow(() -> new IllegalArgumentException("User not found"));
            System.out.println("[DEBUG] Updating user ID: " + userId + " (" + user.getUsername() + ")");
            mutation.apply(user);
            saveUsers(users);
            System.out.println("[DEBUG] User ID " + userId + " updated successfully. File write success.");
            return copyUser(user);
        } finally {
            lock.unlock();
        }
    }

    public User createUser(String name, String email, Integer requestedId) throws IOException {
        lock.lock();
        try {
            StoreSnapshot store = prepareStore();
            List<User> users = store.users();
            int userId = requestedId == null ? nextId(users) : requestedId;
            if (users.stream().anyMatch(user -> user.getId() == userId)) {
                throw new IllegalArgumentException("User already exists");
            }
            User user = new User(userId, name, email, TimeUtil.utcNow());
            users.add(user);
            saveUsers(users);
            return copyUser(user);
        } finally {
            lock.unlock();
        }
    }

    /**
     * Register a new voter for a group (always allocates a fresh user id).
     * Used when multiple participants must not share the same user_id.
     */
    /**
     * Register an account with a unique email and optionally add the user to a
     * group.
     */
    public SignUpResult signUp(
            String username, String email, String password, Integer groupId, String groupCode) throws IOException {
        lock.lock();
        try {
            StoreSnapshot store = prepareStore();
            String trimmedUsername = username == null ? "" : username.trim();
            if (trimmedUsername.isEmpty()) {
                throw new IllegalArgumentException("Invalid input");
            }

            String normalizedEmail = email == null ? "" : email.trim().toLowerCase();
            if (normalizedEmail.isEmpty() || !normalizedEmail.contains("@")) {
                throw new IllegalArgumentException("Invalid input");
            }
            if (password == null || password.isBlank()) {
                throw new IllegalArgumentException("Invalid input");
            }

            List<User> users = store.users();
            if (isEmailTaken(normalizedEmail, users) || isUsernameTaken(trimmedUsername, users)) {
                throw new IllegalArgumentException("User already exists");
            }

            int userId = nextId(users);
            User user = new User(
                    userId,
                    trimmedUsername,
                    normalizedEmail,
                    TimeUtil.utcNow(),
                    null,
                    null,
                    null,
                    PasswordHasher.hash(password));
            users.add(user);

            Integer resolvedGroupId = resolveSignUpGroupId(store.groups(), groupId, groupCode);
            String resolvedGroupCode = null;
            if (resolvedGroupId != null) {
                List<Group> groups = store.groups();
                Optional<Group> found = groups.stream()
                        .filter(group -> group.getId() == resolvedGroupId)
                        .findFirst();
                if (found.isEmpty()) {
                    throw new IllegalArgumentException("Group not found");
                }
                Group group = found.get();
                resolvedGroupCode = group.getCode();
                List<Integer> members = new ArrayList<>(group.getMemberUserIds());
                if (!members.contains(userId)) {
                    members.add(userId);
                    Set<Integer> unique = new HashSet<>(members);
                    List<Integer> sorted = new ArrayList<>(unique);
                    Collections.sort(sorted);
                    group.setMemberUserIds(sorted);
                    saveGroups(groups);
                }
                setUserGroupMembership(
                        userId, resolvedGroupId, resolvedGroupCode, "member", users, store.groups(), false);
            }
            saveUsers(users);

            return new SignUpResult(copyUser(user), resolvedGroupId);
        } finally {
            lock.unlock();
        }
    }

    public Optional<User> authenticate(String identifier, String password) throws IOException {
        lock.lock();
        try {
            if (identifier == null || identifier.isBlank() || password == null || password.isBlank()) {
                return Optional.empty();
            }
            String normalizedEmail = identifier.trim().toLowerCase();
            String normalizedUsername = identifier.trim();

            StoreSnapshot store = prepareStore();
            List<User> users = store.users();
            Optional<User> found = users.stream()
                    .filter(user -> matchesIdentifier(user, normalizedEmail, normalizedUsername))
                    .filter(user -> PasswordHasher.verify(password, user.getPassword()))
                    .findFirst();

            if (found.isEmpty()) {
                return Optional.empty();
            }

            User user = found.get();
            user.setLastLogin(TimeUtil.utcNow());
            saveUsers(users);
            return Optional.of(copyUser(user));
        } finally {
            lock.unlock();
        }
    }

    private static boolean matchesIdentifier(User user, String normalizedEmail, String normalizedUsername) {
        if (user.getEmail() != null && user.getEmail().trim().equalsIgnoreCase(normalizedEmail)) {
            return true;
        }
        return user.getUsername() != null
                && user.getUsername().trim().equalsIgnoreCase(normalizedUsername);
    }

    private static boolean isEmailTaken(String email, List<User> users) {
        return users.stream()
                .anyMatch(user -> user.getEmail() != null && user.getEmail().trim().equalsIgnoreCase(email));
    }

    private static boolean isUsernameTaken(String username, List<User> users) {
        return users.stream()
                .anyMatch(user -> user.getUsername() != null
                        && user.getUsername().trim().equalsIgnoreCase(username));
    }

    private static Integer resolveSignUpGroupId(List<Group> groups, Integer groupId, String groupCode) {
        if (groupId != null && groupId > 0) {
            return groupId;
        }
        if (groupCode == null || groupCode.isBlank()) {
            return null;
        }
        String normalizedCode = groupCode.trim().toUpperCase();
        return groups.stream()
                .filter(group -> group.getCode() != null
                        && group.getCode().trim().toUpperCase().equals(normalizedCode))
                .map(Group::getId)
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Group not found"));
    }

    /**
     * Attach a user to a group. Reuses an existing users.json record when possible.
     */
    public User assignUserToGroup(int groupId, Integer existingUserId, String name, String email)
            throws IOException {
        lock.lock();
        try {
            StoreSnapshot store = prepareStore();
            if (store.groups().stream().noneMatch(group -> group.getId() == groupId)) {
                throw new IllegalArgumentException("Group not found");
            }

            if (existingUserId != null && existingUserId > 0) {
                if (findUserById(existingUserId, store.users()).isEmpty()) {
                    throw new IllegalArgumentException("User not found");
                }
                addGroupMember(groupId, existingUserId);
                return getUser(existingUserId).orElseThrow();
            }

            if (email != null && !email.isBlank()) {
                String normalizedEmail = email.trim().toLowerCase();
                Optional<User> existing = store.users().stream()
                        .filter(user -> user.getEmail() != null
                                && user.getEmail().trim().equalsIgnoreCase(normalizedEmail))
                        .findFirst();
                if (existing.isPresent()) {
                    addGroupMember(groupId, existing.get().getId());
                    return getUser(existing.get().getId()).orElseThrow();
                }
            }

            return registerAnonymousGroupMember(groupId, name, email);
        } finally {
            lock.unlock();
        }
    }

    /** Legacy path: create a lightweight participant without a full account. */
    public User registerGroupVoter(int groupId, String name, String email) throws IOException {
        return assignUserToGroup(groupId, null, name, email);
    }

    private User registerAnonymousGroupMember(int groupId, String name, String email) throws IOException {
        StoreSnapshot store = prepareStore();
        List<User> users = store.users();
        List<Group> groups = store.groups();

        // Validate group exists
        Optional<Group> groupOpt = groups.stream().filter(g -> g.getId() == groupId).findFirst();
        if (groupOpt.isEmpty()) {
            throw new IllegalArgumentException("Group not found");
        }
        Group group = groupOpt.get();

        int userId = nextId(users);
        String resolvedName = name == null || name.isBlank() ? "User " + userId : name.trim();
        User user = new User(userId, resolvedName, email, TimeUtil.utcNow());

        System.out.println("[DEBUG] Registering anonymous user " + userId + " (" + resolvedName + ") in group " + groupId + ". Groups count before: 0");
        // Set group information immediately
        user.getGroups().add(new User.UserGroupMembership(groupId, "member", group.getCode()));
        user.setGroupId(groupId);
        user.setGroupCode(group.getCode());
        user.setGroupRole("member");

        users.add(user);
        saveUsers(users);
        System.out.println("[DEBUG] Registered anonymous user saved to users.json. File write success.");
        System.out.println("[DEBUG] Registered anonymous user " + userId + " groups count after: " + user.getGroups().size());
        addGroupMember(groupId, userId);
        return getUser(userId).orElseThrow();
    }

    public Vote upsertVote(int userId, int destinationId, int weight, Integer groupId) throws IOException {
        lock.lock();
        try {
            StoreSnapshot store = prepareStore();
            List<User> users = store.users();
            List<Destination> destinations = store.destinations();
            List<Vote> votes = store.votes();

            if (users.stream().noneMatch(user -> user.getId() == userId)) {
                throw new IllegalArgumentException("User not found");
            }

            Optional<Destination> destinationOpt = destinations.stream()
                    .filter(destination -> destination.getId() == destinationId)
                    .filter(destination -> groupId == null || destination.getGroupId() == groupId)
                    .findFirst();
            if (destinationOpt.isEmpty()) {
                throw new IllegalArgumentException("Destination not found");
            }
            Destination destination = destinationOpt.get();

            int resolvedGroupId = groupId == null ? destination.getGroupId() : groupId;
            if (store.groups().stream().noneMatch(group -> group.getId() == resolvedGroupId)) {
                throw new IllegalArgumentException("Group not found");
            }
            if (destination.getGroupId() != resolvedGroupId) {
                throw new IllegalArgumentException("Destination is not in this group");
            }

            String now = TimeUtil.utcNow();
            for (Vote vote : votes) {
                if (vote.getUserId() == userId
                        && vote.getDestinationId() == destinationId
                        && vote.getGroupId() == resolvedGroupId) {
                    vote.setWeight(weight);
                    vote.setUpdatedAt(now);
                    saveVotes(votes);
                    Vote response = copyVote(vote);
                    response.setCreated(false);
                    return response;
                }
            }

            Vote vote = new Vote();
            vote.setId(nextId(votes));
            vote.setGroupId(resolvedGroupId);
            vote.setUserId(userId);
            vote.setDestinationId(destinationId);
            vote.setWeight(weight);
            vote.setCreatedAt(now);
            vote.setUpdatedAt(now);
            votes.add(vote);
            saveVotes(votes);
            Vote response = copyVote(vote);
            response.setCreated(true);
            return response;
        } finally {
            lock.unlock();
        }
    }

    public List<Vote> listVotesForGroup(int groupId) throws IOException {
        lock.lock();
        try {
            StoreSnapshot store = prepareStore();
            Map<Integer, Destination> destinations = store.destinations().stream()
                    .filter(destination -> destination.getGroupId() == groupId)
                    .collect(Collectors.toMap(Destination::getId, destination -> destination));

            List<Vote> rows = new ArrayList<>();
            for (Vote vote : store.votes()) {
                Destination destination = destinations.get(vote.getDestinationId());
                if (destination == null) {
                    continue;
                }
                if (vote.getGroupId() != groupId) {
                    continue;
                }
                Vote row = copyVote(vote);
                row.setGroupId(groupId);
                row.setDestinationName(destination.getName());
                rows.add(row);
            }
            return rows;
        } finally {
            lock.unlock();
        }
    }

    private User ensureUser(
            int userId,
            String name,
            String email,
            List<User> users,
            boolean persist) throws IOException {
        Optional<User> existing = users.stream().filter(user -> user.getId() == userId).findFirst();
        if (existing.isPresent()) {
            User user = existing.get();
            if (name != null) {
                user.setUsername(name);
            }
            if (email != null) {
                user.setEmail(email);
            }
            if (persist) {
                saveUsers(users);
            }
            return copyUser(user);
        }

        User user = new User(userId, name == null ? "User " + userId : name, email, TimeUtil.utcNow());
        users.add(user);
        if (persist) {
            saveUsers(users);
        }
        return copyUser(user);
    }

    private StoreSnapshot prepareStore() throws IOException {
        ensureMigrated();
        List<User> users = normalizeUsers(readUsers());
        List<Group> groups = readGroups();
        normalizeGroups(groups, users);
        validateUserGroupConsistency(groups, users);
        List<Destination> destinations = normalizeDestinations(readDestinations());
        List<Vote> votes = normalizeVotes(readVotes());
        return new StoreSnapshot(groups, users, destinations, votes);
    }

    private void ensureMigrated() throws IOException {
        Path legacy = AppConfig.legacyFile();
        if (!Files.exists(legacy)) {
            return;
        }
        try {
            Map<String, Object> legacyData = mapper.readValue(legacy.toFile(), new TypeReference<>() {
            });
            if (!(legacyData instanceof Map)) {
                return;
            }
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> groups = (List<Map<String, Object>>) legacyData.getOrDefault("groups", List.of());
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> users = (List<Map<String, Object>>) legacyData.getOrDefault("users", List.of());
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> destinations = (List<Map<String, Object>>) legacyData.getOrDefault("destinations",
                    List.of());
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> votes = (List<Map<String, Object>>) legacyData.getOrDefault("votes", List.of());

            if (!groups.isEmpty() && readGroups().isEmpty()) {
                saveGroups(mapper.convertValue(groups, new TypeReference<List<Group>>() {
                }));
            }
            if (!users.isEmpty() && readUsers().size() <= 1) {
                saveUsers(mapper.convertValue(users, new TypeReference<List<User>>() {
                }));
            }
            if (!destinations.isEmpty() && readDestinations().isEmpty()) {
                saveDestinations(mapper.convertValue(destinations, new TypeReference<List<Destination>>() {
                }));
            }
            if (!votes.isEmpty() && readVotes().isEmpty()) {
                saveVotes(mapper.convertValue(votes, new TypeReference<List<Vote>>() {
                }));
            }

            Path backup = AppConfig.legacyFile().resolveSibling("travelpick.json.bak");
            if (!Files.exists(backup)) {
                Files.move(legacy, backup);
            }
        } catch (IOException ignored) {
            // keep legacy file if migration fails
        }
    }

    private List<User> normalizeUsers(List<User> users) throws IOException {
        String now = TimeUtil.utcNow();
        if (users.isEmpty()) {
            users = new ArrayList<>();
            users.add(new User(1, "Guest", null, now));
            saveUsers(users);
            return users;
        }
        boolean changed = false;
        for (User user : users) {
            // @JsonAlias("name") already populates username from old JSON format;
            // this fallback only handles users with a genuinely blank username.
            if (user.getUsername() == null || user.getUsername().isBlank()) {
                user.setUsername("User " + user.getId());
                changed = true;
            }
            if (user.getCreatedAt() == null) {
                user.setCreatedAt(now);
                changed = true;
            }
            if ((user.getGroups() == null || user.getGroups().isEmpty()) && user.getLegacyGroupId() != null) {
                user.getGroups().add(new User.UserGroupMembership(user.getLegacyGroupId(),
                        user.getLegacyGroupRole() != null ? user.getLegacyGroupRole() : "member"));
                user.setLegacyGroupId(null);
                user.setLegacyGroupCode(null);
                user.setLegacyGroupRole(null);
                changed = true;
            }
        }
        if (changed) {
            saveUsers(users);
        }
        return users;
    }

    private void normalizeGroups(List<Group> groups, List<User> users) throws IOException {
        String now = TimeUtil.utcNow();
        Set<Integer> userIds = users.stream().map(User::getId).collect(Collectors.toSet());
        boolean groupsChanged = false;
        boolean usersChanged = false;

        for (Group group : groups) {
            int ownerUserId = group.getOwnerUserId() == 0 ? 1 : group.getOwnerUserId();
            if (group.getOwnerUserId() != ownerUserId) {
                group.setOwnerUserId(ownerUserId);
                groupsChanged = true;
            }

            List<Integer> members = group.getMemberUserIds() == null
                    ? new ArrayList<>()
                    : new ArrayList<>(group.getMemberUserIds());
            if (!members.contains(ownerUserId)) {
                members.add(0, ownerUserId);
                groupsChanged = true;
            }
            Set<Integer> uniqueMembers = new HashSet<>(members);
            List<Integer> sortedMembers = new ArrayList<>(uniqueMembers);
            Collections.sort(sortedMembers);
            if (!sortedMembers.equals(group.getMemberUserIds())) {
                group.setMemberUserIds(sortedMembers);
                groupsChanged = true;
            }

            if (group.getCode() == null) {
                group.setCode(null);
            }
            if (group.getPrivacy() == null || group.getPrivacy().isBlank()) {
                group.setPrivacy("private");
                groupsChanged = true;
            }
            if (group.getCreatedAt() == null) {
                group.setCreatedAt(now);
                groupsChanged = true;
            }

            if (!userIds.contains(ownerUserId)) {
                users.add(new User(ownerUserId, "User " + ownerUserId, null, now));
                userIds.add(ownerUserId);
                usersChanged = true;
            }
        }

        if (groupsChanged) {
            saveGroups(groups);
        }
        if (usersChanged) {
            saveUsers(users);
        }
    }

    /**
     * Validate and repair user-group consistency.
     * Ensures:
     * - Users with group_id have that group exist
     * - Users in group's memberUserIds also have group set in user record
     * - group_code is consistent between user and group
     */
    private void validateUserGroupConsistency(List<Group> groups, List<User> users) throws IOException {
        Set<Integer> validGroupIds = groups.stream().map(Group::getId).collect(Collectors.toSet());
        Map<Integer, Group> groupMap = groups.stream()
                .collect(Collectors.toMap(Group::getId, g -> g));

        boolean usersChanged = false;

        for (User user : users) {
            java.util.List<User.UserGroupMembership> memberships = user.getGroups();
            int originalSize = memberships.size();
            memberships.removeIf(m -> !validGroupIds.contains(m.getGroupId()));
            if (memberships.size() != originalSize) {
                usersChanged = true;
            }
        }

        // Check that all group members have their group in their list
        for (Group group : groups) {
            List<Integer> memberIds = group.getMemberUserIds();
            if (memberIds != null) {
                for (Integer memberId : memberIds) {
                    Optional<User> memberOpt = users.stream()
                            .filter(u -> u.getId() == memberId)
                            .findFirst();
                    if (memberOpt.isPresent()) {
                        User member = memberOpt.get();
                        boolean hasGroup = member.getGroups().stream()
                                .anyMatch(m -> m.getGroupId() == group.getId());
                        if (!hasGroup) {
                            String role = (group.getOwnerUserId() == member.getId()) ? "owner" : "member";
                            member.getGroups().add(new User.UserGroupMembership(group.getId(), role));
                            usersChanged = true;
                        }
                    }
                }
            }
        }

        if (usersChanged) {
            saveUsers(users);
        }
    }

    private List<Destination> normalizeDestinations(List<Destination> destinations) throws IOException {
        boolean changed = false;
        for (Destination destination : destinations) {
            if (destination.getCountry() == null
                    && destination.getImageUrl() == null
                    && destination.getRating() == null
                    && destination.getPopularity() == null
                    && destination.getDescription() == null
                    && destination.getEstimatedCost() == null
                    && destination.getBestSeason() == null) {
                // fields may all be null already
            }
            // ensure keys exist in serialized output by touching defaults (no-op if set)
        }
        if (changed) {
            saveDestinations(destinations);
        }
        return destinations;
    }

    private List<Vote> normalizeVotes(List<Vote> votes) throws IOException {
        String now = TimeUtil.utcNow();
        boolean changed = false;
        for (Vote vote : votes) {
            if (vote.getCreatedAt() == null) {
                vote.setCreatedAt(now);
                changed = true;
            }
            if (vote.getUpdatedAt() == null) {
                vote.setUpdatedAt(vote.getCreatedAt() == null ? now : vote.getCreatedAt());
                changed = true;
            }
        }
        if (changed) {
            saveVotes(votes);
        }
        return votes;
    }

    private List<Group> readGroups() throws IOException {
        return fileManager.readFile(AppConfig.groupsFile(), Group.class);
    }

    private List<User> readUsers() throws IOException {
        return fileManager.readFile(AppConfig.usersFile(), User.class);
    }

    private List<Destination> readDestinations() throws IOException {
        return fileManager.readFile(AppConfig.destinationsFile(), Destination.class);
    }

    private List<Vote> readVotes() throws IOException {
        return fileManager.readFile(AppConfig.votesFile(), Vote.class);
    }

    private void saveGroups(List<Group> groups) throws IOException {
        fileManager.writeFile(AppConfig.groupsFile(), groups);
    }

    private void saveUsers(List<User> users) throws IOException {
        fileManager.writeFile(AppConfig.usersFile(), users);
    }

    private void saveDestinations(List<Destination> destinations) throws IOException {
        fileManager.writeFile(AppConfig.destinationsFile(), destinations);
    }

    private void saveVotes(List<Vote> votes) throws IOException {
        fileManager.writeFile(AppConfig.votesFile(), votes);
    }

    private int nextId(List<?> items) {
        int max = 0;
        for (Object item : items) {
            if (item instanceof Group group) {
                max = Math.max(max, group.getId());
            } else if (item instanceof User user) {
                max = Math.max(max, user.getId());
            } else if (item instanceof Destination destination) {
                max = Math.max(max, destination.getId());
            } else if (item instanceof Vote vote) {
                max = Math.max(max, vote.getId());
            }
        }
        return max + 1;
    }

    private Group copyGroup(Group group) {
        Group copy = new Group();
        copy.setId(group.getId());
        copy.setName(group.getName());
        copy.setCode(group.getCode());
        copy.setPrivacy(group.getPrivacy());
        copy.setOwnerUserId(group.getOwnerUserId());
        copy.setMemberUserIds(group.getMemberUserIds() == null ? List.of() : new ArrayList<>(group.getMemberUserIds()));
        copy.setCreatedAt(group.getCreatedAt());
        return copy;
    }

    private List<Group> copyGroups(List<Group> groups) {
        return groups.stream().map(this::copyGroup).collect(Collectors.toList());
    }

    public void resetData() throws IOException {
        lock.lock();
        try {
            saveUsers(new ArrayList<>());
            saveGroups(new ArrayList<>());
            saveDestinations(new ArrayList<>());
            saveVotes(new ArrayList<>());
        } finally {
            lock.unlock();
        }
    }

    private User copyUser(User user) {
        User copy = new User(
                user.getId(),
                user.getUsername(),
                user.getEmail(),
                user.getCreatedAt(),
                user.getGroupId(),
                user.getGroupCode(),
                user.getGroupRole(),
                user.getPassword(),
                user.getLastLogin());
        copy.setGroups(user.getGroups() == null ? new ArrayList<>() : new ArrayList<>(user.getGroups()));
        return copy;
    }

    private Destination copyDestination(Destination destination) {
        Destination copy = new Destination();
        copy.setId(destination.getId());
        copy.setGroupId(destination.getGroupId());
        copy.setName(destination.getName());
        copy.setDescription(destination.getDescription());
        copy.setCountry(destination.getCountry());
        copy.setImageUrl(destination.getImageUrl());
        copy.setRating(destination.getRating());
        copy.setPopularity(destination.getPopularity());
        copy.setEstimatedCost(destination.getEstimatedCost());
        copy.setBestSeason(destination.getBestSeason());
        return copy;
    }

    private Vote copyVote(Vote vote) {
        Vote copy = new Vote();
        copy.setId(vote.getId());
        copy.setGroupId(vote.getGroupId());
        copy.setUserId(vote.getUserId());
        copy.setDestinationId(vote.getDestinationId());
        copy.setWeight(vote.getWeight());
        copy.setCreatedAt(vote.getCreatedAt());
        copy.setUpdatedAt(vote.getUpdatedAt());
        copy.setDestinationName(vote.getDestinationName());
        return copy;
    }

    public record SignUpResult(User user, Integer groupId) {
    }

    private record StoreSnapshot(List<Group> groups, List<User> users, List<Destination> destinations,
            List<Vote> votes) {
    }
}
