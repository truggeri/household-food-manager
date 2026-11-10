# Household access and account recovery

The app uses individual username-and-password accounts stored in its SQLite
database. There is no external identity provider, email delivery, public account
registration, or default password. An authenticated household member can add
accounts for other members. Each account has a distinct name and sign-in for
future attribution.

## Create the first household member

Start the app once so its database is prepared, then open a Rails console in the
same environment and database as the running app:

```sh
bin/rails console
```

In the console, enter the following and choose a unique username. The password
is requested without echoing it:

```ruby
require "io/console"
password = IO.console.getpass("Password (at least 12 characters): ")
HouseholdMember.create!(
  name: "Household member",
  username: "member",
  password: password,
  password_confirmation: password
)
```

The first user can then sign in and choose **Add a member** to create individual
accounts for the rest of the household. Give each person their username and
password privately. Usernames are normalized to lowercase and must be unique.

For local development, run `bin/rails db:prepare` before opening the console. For
Docker Compose, run `docker compose exec web bin/rails console` after starting
the service.

## Recover an account

There is deliberately no email-based reset flow. Anyone with server and
database access can reset an account from the Rails console:

```ruby
require "io/console"
member = HouseholdMember.find_by!(username: "member")
password = IO.console.getpass("New password (at least 12 characters): ")
member.update!(password: password, password_confirmation: password)
```

Choose a new password with at least 12 characters and share it with the account
holder over a private channel. Keep server access limited to trusted household
administrators; a person with Rails console or SQLite database access can
change accounts or household data. Protect database backups and the server's
Rails secret as described in [Database backups and recovery](backups.md).

## Network and QR-link access

Authentication is required for application pages and forms, including the
household member directory; only the sign-in page and Rails health endpoint are
public. Future QR-linked pages must remain behind the same application
authentication. A QR code is a link, not an access credential.

The documented home-server setup serves HTTP on a trusted home LAN and does not
provide transport encryption. Do not use it over untrusted Wi-Fi, forward its
port from the router, or expose it to the public internet. For access beyond a
trusted LAN, put the app behind HTTPS and an appropriately managed network
boundary before sharing credentials.
