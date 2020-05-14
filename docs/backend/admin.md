---
title: Admin Panel
---

# What is the admin panel?

The admin panel is a CRUD interface generated via the
[Administrate gem](https://github.com/thoughtbot/administrate). In production,
this is generally not used often and will be deprecated in favor of the internal
panel (`http://localhost:3000/internal/*`). For more details, see
[the internal guide](/internal).

# Accessing the admin panel

There is an admin panel located at <http://localhost:3000/admin>.

To access the panel, you must be logged with a user with the `admin` role
activated.

To activate such a role, you can follow these instructions:

- open the Rails console

```shell
rails console
```

1. load the user object of for _bob_ (or whatever the username is)

```ruby
Loading development environment (Rails 5.2.3)
[1] pry(main)> user = User.find_by(username: "bob")
[2] pry(main)> user.add_role(:super_admin)
[3] pry(main)> user.save!
```

Now you'll be able to access the
[administration panel](http://localhost:3000/admin).
