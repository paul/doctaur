---
title: Current user
endpoint: /user
method: GET
category: users
---

# Retrieve the currently logged in user

Retrieves all public data for the currently logged in user

<p class="alert">Requires authentication</p>

    GET /user

## Example

### Terminal

    $ http https://api.github.com/user

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
    @github.current_user
    # => #<User login: "paul">

