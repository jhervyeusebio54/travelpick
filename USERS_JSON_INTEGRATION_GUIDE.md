# TravelPick Users.json Integration Guide

## Overview

This document describes the **fully integrated users.json system** for TravelPick backend. The users.json file is now the **single source of truth** for all user-related data across the entire system.

---

## Updated Users.json Structure

Each user object in `users.json` contains:

```json
{
  "id": 2,
  "username": "john123",
  "email": "john@email.com",
  "password": "sha256:BASE64_SALT:BASE64_DIGEST",
  "group_id": 10,
  "group_code": "TRVL-4821",
  "group_role": "owner",
  "created_at": "2026-05-18T10:00:00Z",
  "last_login": "2026-05-18T12:30:00Z"
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | INT | ✓ | Unique user identifier |
| `username` | STRING | ✓ | Username for login |
| `email` | STRING | Optional | Email address (must be unique if provided) |
| `password` | STRING | Optional | Hashed password using SHA256 |
| `group_id` | INT \| NULL | Optional | Currently assigned group ID |
| `group_code` | STRING \| NULL | Optional | Group code (matches assigned group) |
| `group_role` | STRING \| NULL | Optional | Role in group: "owner" or "member" |
| `created_at` | TIMESTAMP | ✓ | Account creation timestamp (UTC) |
| `last_login` | TIMESTAMP \| NULL | Optional | Last login timestamp (UTC) |

---

## System Architecture

### Single Source of Truth

All user operations flow through **DataStore.java** which:
1. Reads users.json
2. Parses into User objects
3. Modifies specific user(s)
4. Writes entire array back safely
5. Never overwrites other users

### Thread Safety

- Uses `ReentrantLock` for all operations
- Prevents concurrent modification issues
- Ensures data consistency during high load

### Password Hashing

- Uses **SHA256** with salt via `PasswordHasher.hash()`
- Never stores plain text passwords
- Automatic verification during login

---

## Core Operations

### 1. SIGN UP

**Endpoint:** `POST /users/signup`

**Request:**
```json
{
  "name": "john123",
  "email": "john@email.com",
  "password": "securepass123",
  "group_code": "TRVL-4821"  // optional
}
```

**Process:**
1. Validate email uniqueness ✓
2. Validate username uniqueness ✓
3. Hash password ✓
4. Create user record in users.json ✓
5. If group_code provided:
   - Find group by code
   - Add user to group
   - Set group_id, group_code, group_role="member" ✓
6. Save users.json ✓

**Result:** New user appears in users.json with full data preserved

---

### 2. LOGIN

**Endpoint:** `POST /users/login`

**Request:**
```json
{
  "email": "john@email.com",  // or username
  "password": "securepass123"
}
```

**Process:**
1. Read users.json
2. Find user by email OR username ✓
3. Verify password using PasswordHasher.verify() ✓
4. Update last_login timestamp ✓
5. Save users.json ✓
6. Return user profile

**Result:** User profile returned with updated last_login

---

### 3. CREATE GROUP

**Endpoint:** `POST /groups`

**Request:**
```json
{
  "name": "Weekend Wanderers",
  "code": "TRVL-4821",
  "owner_user_id": 2,
  "member_user_ids": [2, 3]
}
```

**Process:**
1. Create group record in groups.json ✓
2. For owner_user_id:
   - Set group_id = new group ID ✓
   - Set group_code = group code ✓
   - Set group_role = "owner" ✓
   - Save to users.json ✓
3. For each member:
   - Set group_id = new group ID ✓
   - Set group_code = group code ✓
   - Set group_role = "member" ✓
   - Save to users.json ✓

**Result:** All users have group info persisted in users.json

---

### 4. JOIN GROUP

**Endpoint:** `POST /users/membership`

**Request:**
```json
{
  "user_id": 3,
  "group_id": 10,
  "group_role": "member"  // optional, defaults to "member"
}
```

**Process:**
1. Find user in users.json ✓
2. Find group in groups.json ✓
3. Check user not already in different group ✓
4. Set user.group_id = group ID ✓
5. Set user.group_code = group code ✓
6. Set user.group_role = specified role ✓
7. Add user to group.memberUserIds ✓
8. Save both users.json and groups.json ✓

**Result:** User's profile now shows group membership

---

### 5. PROFILE VIEW

**Endpoint:** `GET /users/{user_id}`

**Returns:**
```json
{
  "id": 2,
  "username": "john123",
  "name": "john123",
  "email": "john@email.com",
  "created_at": "2026-05-18T10:00:00Z",
  "group_id": 10,
  "group_code": "TRVL-4821",
  "group_role": "owner",
  "last_login": "2026-05-18T12:30:00Z"
}
```

**Process:**
1. Read users.json ✓
2. Find user by ID ✓
3. Return profile with all fields ✓
4. Includes group_id, group_code, group_role if set ✓
5. Includes last_login if updated ✓

**Guarantee:** Data is always fresh from users.json

---

### 6. VOTING SYSTEM

**Endpoint:** `POST /votes`

**Request:**
```json
{
  "user_id": 2,
  "destination_id": 5,
  "weight": 85,
  "group_id": 10
}
```

**Process:**
1. Verify user exists in users.json ✓
2. Verify destination exists ✓
3. Record vote in votes.json ✓
4. User_id must be from users.json ✓
5. Validate group_id matches ✓

**Result:** Only valid users from users.json can vote

---

## Data Consistency Guarantees

### Automatic Validation & Repair

During every `prepareStore()` call:

1. **User Group Validation:**
   - If user.group_id references non-existent group → cleared
   - If user.group_code ≠ group's code → synchronized
   - If group_role is blank → set to "member"

2. **Group Member Validation:**
   - All users in group.memberUserIds must have group_id set
   - All users in group.memberUserIds have group_code synchronized
   - Missing users are added to users.json automatically

3. **User Record Validation:**
   - Username normalized if missing
   - created_at timestamp added if missing
   - Email uniqueness maintained

### Write Safety

All updates follow this pattern:
```java
// 1. Read
List<User> users = prepareStore().users();

// 2. Find & Modify
User user = findUserById(userId, users);
user.setGroupId(groupId);

// 3. Write
saveUsers(users);  // Writes entire array atomically
```

**Protection:**
- Only modified user is changed
- Other users not touched
- Atomic write with lock
- No partial writes

---

## File Handling Best Practices

### Reading Users.json

```java
Optional<User> user = userService.getUser(userId);
// Returns fresh copy from users.json
// Always reflects latest saved state
```

### Updating User

```java
User updated = userService.setGroupMembership(userId, groupId, groupCode, "owner");
// Automatically:
// 1. Reads users.json
// 2. Finds user by id
// 3. Updates group fields
// 4. Writes entire array back
// 5. Returns updated user
```

### No Partial Updates

❌ **DON'T:** Load once, modify multiple times, save once
✓ **DO:** Load, modify one user, save immediately (locked operation)

---

## Bug Fixes Implemented

### 1. Group Code Consistency
**Before:** group_code could be null after joining group
**After:** group_code always matches group's code via `validateUserGroupConsistency()`

### 2. Password Storage
**Before:** signUp didn't store password for all cases
**After:** All signup paths hash and store password

### 3. Anonymous Members
**Before:** Anonymous voters created without group_id
**After:** `registerAnonymousGroupMember()` now sets group_id, group_code, group_role

### 4. Profile Persistence
**Before:** Group disappears from profile after operations
**After:** Validation repair ensures group data persists

### 5. Data Loss Prevention
**Before:** Could overwrite other users during save
**After:** Read → modify one → write pattern prevents overwrites

---

## Testing Scenario

### Test Case: Full Workflow

```
1. User signs up
   ✓ Record created in users.json with password hash
   ✓ created_at set to current UTC time
   ✓ email is unique
   ✓ username is unique

2. User logs in
   ✓ Validated from users.json
   ✓ last_login timestamp updated
   ✓ Profile returned with all fields

3. User creates group
   ✓ Group created in groups.json
   ✓ User's group_id set to new group
   ✓ User's group_code set to group code
   ✓ User's group_role set to "owner"
   ✓ Data persists in users.json

4. Another user joins group
   ✓ User's group_id set to group ID
   ✓ User's group_code set to group code
   ✓ User's group_role set to "member"
   ✓ Data persists in users.json

5. System restart
   ✓ users.json loaded fresh
   ✓ All user data intact
   ✓ Group memberships preserved
   ✓ Passwords still hashed

6. Profile always shows correct data
   ✓ GET /users/2 returns group_id, group_code, group_role
   ✓ Matches latest state in users.json
   ✓ Matches group membership in groups.json
```

---

## API Endpoints Reference

### Users

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/users/signup` | Create account |
| POST | `/users/login` | Authenticate user |
| GET | `/users/{id}` | Get user profile |
| POST | `/users/membership` | Join group |
| POST | `/users` | Create user (admin) |

### Groups

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/groups` | Create group |
| GET | `/groups/{id}` | Get group details |
| GET | `/groups?code=...` | Find by code |

### Voting

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/votes` | Submit vote |
| POST | `/votes/batch` | Batch votes |
| GET | `/votes/{groupId}` | List votes |

---

## Error Handling

### Validation Errors (400)
- Invalid email format
- Duplicate email/username
- User not found
- Group not found
- Invalid password length

### Authentication Errors (401)
- Invalid email or password

### Consistency Errors (409)
- User already in different group
- Group not found for code

---

## Performance Notes

1. **Locking:** ReentrantLock used for thread safety
2. **File I/O:** Jackson ObjectMapper handles serialization
3. **Memory:** Entire users.json loaded into memory (appropriate for small teams)
4. **Startup:** Data validated and repaired on first load

---

## Migration Notes

If upgrading from old schema:

1. `ensureMigrated()` handles legacy data
2. Converts old format to new structure
3. Preserves all user data
4. Adds missing fields with defaults
5. Creates demo user if needed

---

## Data Backup & Recovery

### Backup Strategy
- users.json is the authoritative source
- Commit to version control regularly
- Keep daily backups

### Recovery
- Restore users.json from backup
- Restart server
- Validation repair runs automatically
- System resumes normal operation

---

## Security Considerations

✓ Passwords hashed with SHA256 + salt
✓ Email addresses are unique
✓ No plain text storage
✓ Thread-safe concurrent operations
✓ Locked file writes prevent corruption
✓ Automatic data validation

⚠️ Future improvements:
- Add password strength requirements
- Add rate limiting for login attempts
- Add audit logging for sensitive operations
- Encrypt users.json at rest

---

## Summary

The TravelPick backend now properly integrates users.json as the single source of truth:

✓ All user operations read/write to users.json only
✓ Group membership persisted in user records
✓ Passwords hashed and stored securely
✓ Data consistency validated and repaired automatically
✓ Thread-safe concurrent operations
✓ No data loss on overwrites
✓ Timestamps (created_at, last_login) maintained
✓ Relationships (user ↔ group) always synchronized

**Result:** A reliable, consistent user management system that works across signup, login, group operations, and voting.
