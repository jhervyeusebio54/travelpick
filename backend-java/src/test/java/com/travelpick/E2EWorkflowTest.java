package com.travelpick;

import com.travelpick.config.AppConfig;
import com.travelpick.model.Group;
import com.travelpick.model.Vote;
import com.travelpick.service.DestinationService;
import com.travelpick.service.GroupService;
import com.travelpick.service.ResultsService;
import com.travelpick.service.UserService;
import com.travelpick.service.VoteService;
import com.travelpick.store.DataStore;
import com.travelpick.util.JsonFileManager;
import com.travelpick.model.User;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class E2EWorkflowTest {

    @TempDir
    Path tempDir;

    @Test
    void fullWorkflow() throws IOException {
        bindTempDataDir(tempDir);
        JsonFileManager files = new JsonFileManager();
        files.writeFile(AppConfig.usersFile(), List.of(new User(1, "Guest", null, "2026-05-18T00:00:00.000Z")));
        files.writeFile(AppConfig.groupsFile(), List.of());
        files.writeFile(AppConfig.destinationsFile(), List.of());
        files.writeFile(AppConfig.votesFile(), List.of());

        DataStore store = new DataStore();
        GroupService groups = new GroupService(store);
        UserService users = new UserService(store);
        DestinationService destinations = new DestinationService(store);
        VoteService votes = new VoteService(store, users, groups, destinations);
        ResultsService results = new ResultsService(store, groups, destinations);

        Group group = groups.createGroup("Beach Trip", "BEACH01", "private", 1, List.of(1));
        assertEquals(1, group.getId());

        var destination = destinations.create(group.getId(), "Boracay", "White sand", null, null, null, null, null, null, null);
        assertEquals(1, destination.getId());

        users.ensureUser(2, "Alex", null);
        groups.addMember(group.getId(), 2);

        Vote vote = store.upsertVote(1, destination.getId(), 5, group.getId());
        assertTrue(vote.isCreated());

        List<Vote> groupVotes = votes.listForGroup(group.getId());
        assertEquals(1, groupVotes.size());
        assertEquals(5, groupVotes.get(0).getWeight());
        assertEquals("Boracay", groupVotes.get(0).getDestinationName());

        Vote updated = store.upsertVote(1, destination.getId(), 3, group.getId());
        assertFalse(updated.isCreated());
        assertEquals(1, votes.listForGroup(group.getId()).size());

        List<Vote> persisted = files.readFile(AppConfig.votesFile(), Vote.class);
        assertEquals(1, persisted.size());
        assertEquals(3, persisted.get(0).getWeight());

        Map<String, Object> summary = results.getResults(group.getId());
        assertEquals(1, summary.get("total_votes"));
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> breakdown = (List<Map<String, Object>>) summary.get("breakdown");
        breakdown.sort(Comparator.comparingInt(row -> (Integer) row.get("destination_id")));
        assertEquals(3, breakdown.get(0).get("total_score"));
    }

    @Test
    void multipleUsersAccumulateVotesForSameDestination() throws IOException {
        bindTempDataDir(tempDir);
        JsonFileManager files = new JsonFileManager();
        files.writeFile(AppConfig.usersFile(), List.of(new User(1, "Guest", null, "2026-05-18T00:00:00.000Z")));
        files.writeFile(AppConfig.groupsFile(), List.of());
        files.writeFile(AppConfig.destinationsFile(), List.of());
        files.writeFile(AppConfig.votesFile(), List.of());

        DataStore store = new DataStore();
        GroupService groups = new GroupService(store);
        UserService users = new UserService(store);
        DestinationService destinations = new DestinationService(store);
        VoteService votes = new VoteService(store, users, groups, destinations);
        ResultsService results = new ResultsService(store, groups, destinations);

        Group group = groups.createGroup("Friends Trip", "FRIENDS1", "private", 1, List.of(1));
        var destination = destinations.create(group.getId(), "Bali", "Beach", null, null, null, null, null, null, null);

        store.upsertVote(1, destination.getId(), 5, group.getId());
        User alex = users.registerGroupVoter(group.getId(), "Alex", null);
        store.upsertVote(alex.getId(), destination.getId(), 3, group.getId());

        assertEquals(2, votes.listForGroup(group.getId()).size());

        Map<String, Object> summary = results.getResults(group.getId());
        assertEquals(2, summary.get("total_votes"));
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> breakdown = (List<Map<String, Object>>) summary.get("breakdown");
        assertEquals(8, breakdown.get(0).get("total_score"));
        assertEquals(2, breakdown.get(0).get("vote_count"));
    }

    @Test
    void loginReadsFromUsersJson() throws IOException {
        bindTempDataDir(tempDir);
        JsonFileManager files = new JsonFileManager();
        files.writeFile(AppConfig.usersFile(), List.of());
        files.writeFile(AppConfig.groupsFile(), List.of());
        files.writeFile(AppConfig.destinationsFile(), List.of());
        files.writeFile(AppConfig.votesFile(), List.of());

        UserService users = new UserService(new DataStore());
        users.signUp("Login User", "login@travelpick.com", "secret12", null, null);

        Optional<User> loggedIn = users.authenticate("login@travelpick.com", "secret12");
        assertTrue(loggedIn.isPresent());
        assertEquals("Login User", loggedIn.get().getUsername());
        assertNotNull(loggedIn.get().getLastLogin());
    }

    @Test
    void signUpAssignsUserToGroupByCode() throws IOException {
        bindTempDataDir(tempDir);
        JsonFileManager files = new JsonFileManager();
        files.writeFile(AppConfig.usersFile(), List.of(new User(1, "Guest", null, "2026-05-18T00:00:00.000Z")));
        files.writeFile(AppConfig.groupsFile(), List.of());
        files.writeFile(AppConfig.destinationsFile(), List.of());
        files.writeFile(AppConfig.votesFile(), List.of());

        DataStore store = new DataStore();
        GroupService groups = new GroupService(store);
        UserService users = new UserService(store);

        Group group = groups.createGroup("Signup Trip", "SIGNUP1", "private", 1, List.of(1));
        DataStore.SignUpResult result =
                users.signUp("Jamie", "jamie@travelpick.com", "secret12", null, "SIGNUP1");

        assertEquals("jamie@travelpick.com", result.user().getEmail());
        assertEquals(group.getId(), result.groupId());

        Optional<Group> updated = groups.getGroup(group.getId());
        assertTrue(updated.isPresent());
        assertTrue(updated.get().getMemberUserIds().contains(result.user().getId()));
    }

    @Test
    void multipleUsersAccumulateWeightedVotesInResults() throws IOException {
        bindTempDataDir(tempDir);
        JsonFileManager files = new JsonFileManager();
        files.writeFile(AppConfig.usersFile(), List.of(new User(1, "Guest", null, "2026-05-18T00:00:00.000Z")));
        files.writeFile(AppConfig.groupsFile(), List.of());
        files.writeFile(AppConfig.destinationsFile(), List.of());
        files.writeFile(AppConfig.votesFile(), List.of());

        DataStore store = new DataStore();
        GroupService groups = new GroupService(store);
        UserService users = new UserService(store);
        DestinationService destinations = new DestinationService(store);
        VoteService votes = new VoteService(store, users, groups, destinations);
        ResultsService results = new ResultsService(store, groups, destinations);

        Group group = groups.createGroup("Accumulate Trip", "ACCUM01", "private", 1, List.of(1));
        var destination = destinations.create(group.getId(), "Paris", "City", null, null, null, null, null, null, null);

        store.upsertVote(1, destination.getId(), 5, group.getId());
        User second = users.registerGroupVoter(group.getId(), "Sam", "sam@travelpick.com");
        store.upsertVote(second.getId(), destination.getId(), 3, group.getId());
        assertEquals(2, votes.listForGroup(group.getId()).size());

        Map<String, Object> summary = results.getResults(group.getId());
        assertEquals(2, summary.get("total_votes"));
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> breakdown = (List<Map<String, Object>>) summary.get("breakdown");
        assertEquals(8, breakdown.get(0).get("total_score"));
        assertEquals(2, breakdown.get(0).get("vote_count"));

        Optional<User> samProfile = users.getUser(second.getId());
        assertTrue(samProfile.isPresent());
        assertEquals(group.getId(), samProfile.get().getGroupId());
        assertEquals("ACCUM01", samProfile.get().getGroupCode());
        assertEquals("member", samProfile.get().getGroupRole());
    }

    @Test
    void createGroupSetsOwnerMembershipOnUserProfile() throws IOException {
        bindTempDataDir(tempDir);
        JsonFileManager files = new JsonFileManager();
        files.writeFile(
                AppConfig.usersFile(),
                List.of(new User(1, "Guest", null, "2026-05-18T00:00:00.000Z", null, null, null, null)));
        files.writeFile(AppConfig.groupsFile(), List.of());
        files.writeFile(AppConfig.destinationsFile(), List.of());
        files.writeFile(AppConfig.votesFile(), List.of());

        DataStore store = new DataStore();
        GroupService groups = new GroupService(store);
        UserService users = new UserService(store);

        Group group = groups.createGroup("Owners Trip", "OWN123", "private", 1, List.of(1));
        Optional<User> owner = users.getUser(1);
        assertTrue(owner.isPresent());
        assertEquals(group.getId(), owner.get().getGroupId());
        assertEquals("owner", owner.get().getGroupRole());
        assertEquals("OWN123", owner.get().getGroupCode());
    }

    @Test
    void signUpRejectsDuplicateEmail() throws IOException {
        bindTempDataDir(tempDir);
        JsonFileManager files = new JsonFileManager();
        files.writeFile(AppConfig.usersFile(), List.of(new User(1, "Guest", null, "2026-05-18T00:00:00.000Z")));
        files.writeFile(AppConfig.groupsFile(), List.of());
        files.writeFile(AppConfig.destinationsFile(), List.of());
        files.writeFile(AppConfig.votesFile(), List.of());

        UserService users = new UserService(new DataStore());
        users.signUp("Alex", "alex@travelpick.com", "secret12", null, null);

        IllegalArgumentException error = org.junit.jupiter.api.Assertions.assertThrows(
                IllegalArgumentException.class,
                () -> users.signUp("Alex Two", "alex@travelpick.com", "otherpass", null, null));
        assertEquals("User already exists", error.getMessage());
    }

    private static void bindTempDataDir(Path tempDir) throws IOException {
        Files.createDirectories(tempDir);
        System.setProperty("travelpick.data.dir", tempDir.toAbsolutePath().toString());
    }
}
