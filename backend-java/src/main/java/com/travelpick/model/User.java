package com.travelpick.model;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;

/** User entity stored in users.json (single source of truth). */
public class User {

    private int id;

    @JsonAlias("name")
    private String username;

    private String email;

    /** Hashed credential; persisted in users.json, never returned by public API mappers. */
    private String password;

    @JsonProperty(value = "group_id", access = JsonProperty.Access.WRITE_ONLY)
    private Integer legacyGroupId;

    @JsonProperty(value = "group_code", access = JsonProperty.Access.WRITE_ONLY)
    private String legacyGroupCode;

    @JsonProperty(value = "group_role", access = JsonProperty.Access.WRITE_ONLY)
    private String legacyGroupRole;

    @JsonProperty("groups")
    private java.util.List<UserGroupMembership> groups = new java.util.ArrayList<>();

    @JsonProperty("created_at")
    private String createdAt;

    @JsonProperty("last_login")
    private String lastLogin;

    public static class UserGroupMembership {
        @JsonProperty("group_id")
        private int groupId;
        private String role;
        private String code;

        public UserGroupMembership() {}

        public UserGroupMembership(int groupId, String role) {
            this(groupId, role, null);
        }

        public UserGroupMembership(int groupId, String role, String code) {
            this.groupId = groupId;
            this.role = role;
            this.code = code;
        }

        public int getGroupId() { return groupId; }
        public void setGroupId(int groupId) { this.groupId = groupId; }

        public String getRole() { return role; }
        public void setRole(String role) { this.role = role; }

        public String getCode() { return code; }
        public void setCode(String code) { this.code = code; }
    }

    public User() {
    }

    public User(int id, String username, String email, String createdAt) {
        this(id, username, email, createdAt, null, null, null, null, null);
    }

    public User(
            int id,
            String username,
            String email,
            String createdAt,
            Integer groupId,
            String groupCode,
            String groupRole,
            String password) {
        this(id, username, email, createdAt, groupId, groupCode, groupRole, password, null);
    }

    public User(
            int id,
            String username,
            String email,
            String createdAt,
            Integer groupId,
            String groupCode,
            String groupRole,
            String password,
            String lastLogin) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.createdAt = createdAt;
        this.legacyGroupId = groupId;
        this.legacyGroupCode = groupCode;
        this.legacyGroupRole = groupRole;
        this.password = password;
        this.lastLogin = lastLogin;
        this.groups = new java.util.ArrayList<>();
        if (groupId != null) {
            this.groups.add(new UserGroupMembership(groupId, groupRole != null ? groupRole : "member", groupCode));
        }
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    @JsonIgnore
    public String getName() {
        return username;
    }

    @JsonIgnore
    public void setName(String name) {
        this.username = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    @JsonIgnore
    public Integer getGroupId() {
        if (groups == null || groups.isEmpty()) {
            return legacyGroupId;
        }
        return groups.get(groups.size() - 1).getGroupId();
    }

    @JsonIgnore
    public void setGroupId(Integer groupId) {
        this.legacyGroupId = groupId;
        if (groupId != null) {
            if (groups == null) {
                groups = new java.util.ArrayList<>();
            }
            java.util.Optional<UserGroupMembership> existing = groups.stream()
                    .filter(m -> m.getGroupId() == groupId)
                    .findFirst();
            if (existing.isPresent()) {
                UserGroupMembership membership = existing.get();
                groups.remove(membership);
                groups.add(membership);
            } else {
                groups.add(new UserGroupMembership(groupId, legacyGroupRole != null ? legacyGroupRole : "member", legacyGroupCode));
            }
        }
    }

    @JsonIgnore
    public String getGroupCode() {
        if (groups == null || groups.isEmpty()) {
            return legacyGroupCode;
        }
        String c = groups.get(groups.size() - 1).getCode();
        return c != null ? c : legacyGroupCode;
    }

    @JsonIgnore
    public void setGroupCode(String groupCode) {
        this.legacyGroupCode = groupCode;
        if (groups != null && !groups.isEmpty()) {
            groups.get(groups.size() - 1).setCode(groupCode);
        }
    }

    @JsonIgnore
    public String getGroupRole() {
        if (groups == null || groups.isEmpty()) {
            return legacyGroupRole;
        }
        return groups.get(groups.size() - 1).getRole();
    }

    @JsonIgnore
    public void setGroupRole(String groupRole) {
        this.legacyGroupRole = groupRole;
        if (groups != null && !groups.isEmpty() && groupRole != null) {
            groups.get(groups.size() - 1).setRole(groupRole);
        }
    }

    @JsonIgnore
    public Integer getLegacyGroupId() {
        return legacyGroupId;
    }

    @JsonIgnore
    public void setLegacyGroupId(Integer legacyGroupId) {
        this.legacyGroupId = legacyGroupId;
    }

    @JsonIgnore
    public String getLegacyGroupCode() {
        return legacyGroupCode;
    }

    @JsonIgnore
    public void setLegacyGroupCode(String legacyGroupCode) {
        this.legacyGroupCode = legacyGroupCode;
    }

    @JsonIgnore
    public String getLegacyGroupRole() {
        return legacyGroupRole;
    }

    @JsonIgnore
    public void setLegacyGroupRole(String legacyGroupRole) {
        this.legacyGroupRole = legacyGroupRole;
    }

    public java.util.List<UserGroupMembership> getGroups() {
        if (groups == null) {
            groups = new java.util.ArrayList<>();
        }
        return groups;
    }

    public void setGroups(java.util.List<UserGroupMembership> groups) {
        this.groups = groups;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    public String getLastLogin() {
        return lastLogin;
    }

    public void setLastLogin(String lastLogin) {
        this.lastLogin = lastLogin;
    }

    @Override
    public String toString() {
        return "User{id=" + id + ", username='" + username + "'}";
    }
}
