# TravelPick Users.json - Developer Quick Reference

## Quick Patterns

### Reading User Data

```java
// Get user by ID
Optional<User> user = userService.getUser(userId);
if (user.isPresent()) {
    int groupId = user.get().getGroupId();
    String groupRole = user.get().getGroupRole();
}

// Find by email
Optional<User> user = userService.findByEmail("john@email.com");

// Authenticate
Optional<User> user = userService.authenticate("john@email.com", "password");
// Returns user with updated last_login
```

### Modifying User Data

```java
// Update group membership
User updated = userService.setGroupMembership(
    userId,      // User ID
    groupId,     // Group ID
    groupCode,   // Group code (can be null)
    "owner"      // Role: "owner" or "member"
);

// Assign user to group
User user = userService.assignUserToGroup(
    groupId,
    existingUserId,  // null if new user
    "John Doe",
    "john@email.com"
);
```

### Creating Users

```java
// Sign up (creates account with optional group)
DataStore.SignUpResult result = userService.signUp(
    "john123",           // username
    "john@email.com",    // email
    "securepass123",     // password (hashed automatically)
    null,                // groupId (optional)
    "TRVL-4821"          // groupCode to auto-join
);
User user = result.user();

// Create user without password (admin)
User user = userService.createUser(
    "John Doe",
    "john@email.com",
    null  // auto-assign ID
);
```

### Group Operations

```java
// Create group with owner
Group group = groupService.createGroup(
    "Weekend Wanderers",    // name
    "TRVL-4821",           // code
    "private",             // privacy
    ownerId,               // owner user ID
    Arrays.asList(2, 3, 4) // member IDs
);
// Note: All members' group_id/group_code/group_role automatically set

// Add member to group
groupService.addMember(groupId, userId);
// Note: Uses setUserGroupMembership internally

// Find group by code
Optional<Group> group = groupService.findByCode("TRVL-4821");
```

---

## Common Patterns

### Pattern 1: Validate User Exists Before Operation

```java
// GOOD
if (userService.getUser(userId).isEmpty()) {
    throw new IllegalArgumentException("User not found");
}

// BETTER - Use requireUserExists
userService.requireUserExists(userId);
```

### Pattern 2: Update User Data

```java
User user = store.updateUser(userId, userObj -> {
    userObj.setGroupId(groupId);
    userObj.setGroupRole("member");
    // Changes automatically saved
});
```

### Pattern 3: Read-Modify-Write (Internal)

```java
// DON'T DO THIS - Will lose updates
List<User> users = store.readUsers();
User user = users.stream().filter(...).findFirst();
user.setGroupId(10);
store.saveUsers(users);  // Other updates may be lost

// DO THIS - Use service methods
User updated = userService.setGroupMembership(userId, groupId, code, role);
```

### Pattern 4: Handle Group Codes

```java
// Group code can be null, but should be consistent
String expectedCode = group.getCode();  // May be null

// When setting user to group, code is auto-synced
User user = userService.setGroupMembership(
    userId,
    groupId,
    null,      // Will use group.getCode() automatically
    "member"
);
// Result: user.group_code = group.getCode()
```

### Pattern 5: Batch Operations

```java
// Submitting multiple votes
List<VoteService.VoteRequest> votes = new ArrayList<>();
votes.add(new VoteService.VoteRequest(userId1, destId1, weight1, groupId));
votes.add(new VoteService.VoteRequest(userId2, destId2, weight2, groupId));

List<Map<String, Object>> results = voteService.submitBatch(votes);
```

---

## Data Consistency Checks

### When Does Validation Run?

**Automatic:** Every time `prepareStore()` is called (on every read operation)

```java
// This automatically validates and repairs
Optional<User> user = userService.getUser(userId);

// This automatically validates and repairs  
List<Group> groups = groupService.listGroups();

// This automatically validates and repairs
Optional<User> user = userService.findByEmail("test@example.com");
```

### What Gets Validated?

1. **User's group_id** - Must reference valid group or cleared
2. **User's group_code** - Must match group's code
3. **User's group_role** - Must be "owner" or "member", defaults to "member"
4. **Group members** - All must have matching user records

### What Gets Repaired?

- ❌ Orphaned group references → Cleared
- ❌ Mismatched group_code → Synchronized
- ❌ Missing group_role → Defaulted to "member"
- ❌ Missing user in users.json → Created automatically
- ❌ Missing username → Generated from ID
- ❌ Missing created_at → Stamped with current time

---

## Error Handling

### Validation Errors (HTTP 400)

```java
// Invalid email format
"Invalid input"

// Duplicate email/username
"User already exists"

// User not found
"User not found"

// Invalid password length
"Invalid input"

// Group not found
"Group not found"
```

### Authentication Errors (HTTP 401)

```java
// Wrong password
"Invalid email or password"

// User doesn't exist
"Invalid email or password"
```

### Conflict Errors (HTTP 409)

```java
// User already in different group
"User is already assigned to another group"
```

---

## Password Handling

### Storing Passwords

```java
String hashedPassword = PasswordHasher.hash("plainPassword");
// Returns: "sha256:BASE64_SALT:BASE64_DIGEST"

user.setPassword(hashedPassword);
store.saveUsers(users);
```

### Verifying Passwords

```java
boolean isCorrect = PasswordHasher.verify(
    "plainPassword",           // What user entered
    user.getPassword()         // From users.json
);
```

### DO NOT

❌ Store plain text passwords
❌ Use user passwords for encryption keys
❌ Log passwords anywhere
❌ Compare passwords with `==`

---

## Timestamps

### Format

All timestamps are **ISO 8601** in **UTC timezone**:
```
"2026-05-18T12:30:00Z"
```

### Creating Timestamps

```java
String now = TimeUtil.utcNow();
user.setCreatedAt(now);
user.setLastLogin(now);
```

### When Updated

| Field | Updated | By |
|-------|---------|-----|
| `created_at` | Once at signup | signUp() |
| `last_login` | Each login | authenticate() |

---

## Testing with Mock Data

### Mock User in Group

```json
{
  "id": 2,
  "username": "john123",
  "email": "john@email.com",
  "password": "sha256:...",
  "group_id": 10,
  "group_code": "TRVL-4821",
  "group_role": "owner",
  "created_at": "2026-05-18T10:00:00Z",
  "last_login": "2026-05-18T12:30:00Z"
}
```

### Mock Anonymous Voter

```json
{
  "id": 8,
  "username": "User 8",
  "email": null,
  "password": null,
  "group_id": 10,
  "group_code": "TRVL-4821",
  "group_role": "member",
  "created_at": "2026-05-18T14:00:00Z",
  "last_login": null
}
```

### Mock Unregistered User

```json
{
  "id": 7,
  "username": "david_brown",
  "email": "david@email.com",
  "password": "sha256:...",
  "group_id": null,
  "group_code": null,
  "group_role": null,
  "created_at": "2026-05-18T11:30:00Z",
  "last_login": "2026-05-18T11:35:00Z"
}
```

---

## API Endpoints Usage

### Authentication Flow

```
1. POST /users/signup
   Request: { name, email, password, group_code? }
   Response: { id, username, email, created_at, group_id?, group_code?, group_role? }

2. POST /users/login
   Request: { email/username, password }
   Response: { id, username, email, created_at, last_login, group_id?, group_code?, group_role? }

3. GET /users/{id}
   Response: { id, username, email, created_at, last_login?, group_id?, group_code?, group_role? }
```

### Group Flow

```
1. POST /groups
   Request: { name, code?, privacy?, owner_user_id, member_user_ids? }
   Response: { id, name, code, privacy, owner_user_id, member_user_ids, created_at }
   Side Effect: All members get group_id set in users.json

2. POST /users/membership
   Request: { user_id, group_id, group_code?, group_role? }
   Response: { id, username, email, created_at, group_id, group_code, group_role }
   Side Effect: user.group_* fields updated in users.json
```

### Voting Flow

```
1. POST /votes
   Request: { user_id, destination_id, weight, group_id? }
   Response: { id, user_id, destination_id, weight, group_id, created_at, updated_at, created: true }
   Validation: user_id must exist in users.json

2. GET /votes/{groupId}
   Response: [{ id, user_id, destination_id, weight, ... }]
```

---

## Common Gotchas

### ❌ Gotcha 1: Group Code Null

```java
// This might be null!
String code = group.getCode();

// Do this instead
String code = Optional.ofNullable(group.getCode())
    .orElse("NO-CODE");
```

### ❌ Gotcha 2: User Without Email

```java
// Email might be null for anonymous voters
if (user.getEmail() != null) {
    // Safe to use
}
```

### ❌ Gotcha 3: Last Login Not Set

```java
// last_login might be null if never logged in
if (user.getLastLogin() != null) {
    // User has logged in before
}
```

### ❌ Gotcha 4: Calling Save Twice

```java
// DON'T
store.saveUsers(users);
// ... modify more ...
store.saveUsers(users);

// DO - Use service methods that handle saving
userService.setGroupMembership(userId, groupId, code, role);
```

---

## Performance Tips

1. **Avoid Re-reading:** Use service methods that return fresh data
2. **Lock Time:** Keep operations in locks brief
3. **Batch Operations:** Use `/votes/batch` for multiple votes
4. **Lazy Load:** Don't load all data if you only need one user

---

## Debugging Tips

### Check User-Group Consistency

```bash
# In users.json, verify:
# 1. user.group_id matches some group.id ✓
# 2. user.group_code matches the group's code ✓
# 3. user.group_role is "owner" or "member" ✓
# 4. If user.id in group.memberUserIds, then user.group_id should be group.id ✓
```

### Check Passwords

```bash
# Users should have:
# "password": "sha256:BASE64_SALT:BASE64_DIGEST"
# NOT:
# "password": "plaintext"
# NOT:
# "password": null (unless guest)
```

### Check Timestamps

```bash
# All should be ISO 8601 UTC:
# "created_at": "2026-05-18T10:00:00Z"  ✓
# "last_login": "2026-05-18T12:30:00Z"  ✓
# NOT: "1234567890" (unix timestamp) ✗
```

---

## Summary Checklist

✅ Use DataStore for all user operations
✅ All users.json reads go through validation
✅ Group memberships automatically synchronized
✅ Passwords always hashed before storing
✅ Timestamps in ISO 8601 UTC format
✅ Use service methods, not direct file I/O
✅ Check for null on email and last_login
✅ Group role defaults to "member"
✅ Data consistency auto-repaired on load
✅ Thread-safe locked operations

