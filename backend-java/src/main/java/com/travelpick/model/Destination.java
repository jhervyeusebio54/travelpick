package com.travelpick.model;

import com.fasterxml.jackson.annotation.JsonProperty;

/** Destination entity stored in destinations.json. */
public class Destination {

    private int id;

    @JsonProperty("group_id")
    private int groupId;

    private String name;
    private String description;
    private String country;

    @JsonProperty("imageUrl")
    private String imageUrl;

    private Double rating;
    private Integer popularity;

    @JsonProperty("estimatedCost")
    private String estimatedCost;

    @JsonProperty("bestSeason")
    private String bestSeason;

    public Destination() {
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getGroupId() {
        return groupId;
    }

    public void setGroupId(int groupId) {
        this.groupId = groupId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getCountry() {
        return country;
    }

    public void setCountry(String country) {
        this.country = country;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public Double getRating() {
        return rating;
    }

    public void setRating(Double rating) {
        this.rating = rating;
    }

    public Integer getPopularity() {
        return popularity;
    }

    public void setPopularity(Integer popularity) {
        this.popularity = popularity;
    }

    public String getEstimatedCost() {
        return estimatedCost;
    }

    public void setEstimatedCost(String estimatedCost) {
        this.estimatedCost = estimatedCost;
    }

    public String getBestSeason() {
        return bestSeason;
    }

    public void setBestSeason(String bestSeason) {
        this.bestSeason = bestSeason;
    }

    @Override
    public String toString() {
        return "Destination{id=" + id + ", name='" + name + "', groupId=" + groupId + "}";
    }
}
