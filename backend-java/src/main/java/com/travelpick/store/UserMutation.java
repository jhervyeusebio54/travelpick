package com.travelpick.store;

import com.travelpick.model.User;

/** Callback used when updating a single user record in users.json. */
@FunctionalInterface
public interface UserMutation {
    void apply(User user);
}
