package com.travelpick.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.ArrayList;
import java.util.List;

/** Group entity stored in groups.json. */
public class Group {

    private int id;
    private String name;
    private String code;
    private String privacy;

    @JsonProperty("owner_user_id")
    private int ownerUserId;

    @JsonProperty("member_user_ids")
    private List<Integer> memberUserIds = new ArrayList<>();

    @JsonProperty("created_at")
    private String createdAt;

    public Group() {
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getPrivacy() {
        return privacy;
    }

    public void setPrivacy(String privacy) {
        this.privacy = privacy;
    }

    public int getOwnerUserId() {
        return ownerUserId;
    }

    public void setOwnerUserId(int ownerUserId) {
        this.ownerUserId = ownerUserId;
    }

    public List<Integer> getMemberUserIds() {
        return memberUserIds;
    }

    public void setMemberUserIds(List<Integer> memberUserIds) {
        this.memberUserIds = memberUserIds;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "Group{id=" + id + ", name='" + name + "'}";
    }
}
