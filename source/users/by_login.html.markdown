---
title: User by login
endpoint: /users/{login}
method: GET
category: users
---

# Fetch a user by login

Retrieves all public data for a user by their login name.

    GET /users/{login}

## Example

### Terminal

    $ http https://api.github.com/users/paul

    {
        "avatar_url": "https://secure.gravatar.com/avatar/d587890d0fcf8f45724baa8b1bfe1bf4?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png",
        "bio": "",
        "blog": "blog.theamazingrando.com",
        "company": "GitHub",
        "created_at": "2008-02-11T18:44:09Z",
        "email": "psadauskas@gmail.com",
        "followers": 35,
        "following": 1,
        "gravatar_id": "d587890d0fcf8f45724baa8b1bfe1bf4",
        "hireable": false,
        "html_url": "https://github.com/paul",
        "id": 184,
        "location": "Boulder, CO",
        "login": "paul",
        "name": "Paul Sadauskas",
        "public_gists": 323,
        "public_repos": 83,
        "type": "User",
        "url": "https://api.github.com/users/paul"
    }

### Ruby

    @github = Github::Client.new("https://api.github.com")
    @github.user("paul")
    # => #<User login: "paul">




