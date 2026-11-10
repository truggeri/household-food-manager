# Household Food Manager

A mobile-first Rails application to help a household keep track of food in its
freezer and make better use of it. The project is being built in phases:

1. **Freezer inventory:** make it easy for a family to see what is stored in the
   freezer.
2. **QR labels:** make freezer items easier to identify and manage.
3. **Meal planning:** help plan meals around food the household has available.
4. **Scratch cooking:** support preparing meals from those plans.

These are product goals, not a specification of implementation details. This
repository currently provides the Rails foundation: Hotwire (Turbo and
Stimulus), SQLite, household sign-in and member identity, and a health endpoint.
The freezer-tracking and later product capabilities are not implemented yet.

See [Contributing](CONTRIBUTING.md) and
[Copilot instructions](.github/copilot-instructions.md) for guidance on making
small, reviewable changes. Use the
[issue template](.github/ISSUE_TEMPLATE/issue.md) to describe a desired outcome
and its acceptance criteria.

## Requirements

- Ruby **3.3.9** (see `.ruby-version`).
- Bundler **2.5.22** (`gem install bundler -v 2.5.22` if it is missing).
- A compiler toolchain for native gems, such as Xcode Command Line Tools on macOS
  (`xcode-select --install`) or `build-essential` on Debian/Ubuntu.

SQLite is managed by the `sqlite3` gem; no database server is needed. JavaScript
uses importmap, so Node.js, npm, and a JavaScript build process are not required.

## Run locally

From a checkout of this repository:

```sh
# If you use rbenv:
rbenv install -s 3.3.9
rbenv local 3.3.9

gem install bundler -v 2.5.22
bin/setup
```

`bin/setup` installs the locked dependencies, prepares SQLite, and starts the
development server. Open **http://localhost:3000**. Stop the server with Ctrl-C.
For other Ruby managers, select Ruby 3.3.9 before running the same setup command.
The first run requires creating the initial household member from the Rails
console; follow [Household access and account recovery](docs/household-access.md)
before signing in. There is no default account or public account registration.

To prepare without starting the server, or to start it again later:

```sh
bin/setup --skip-server
bin/dev
```

Development and test databases live separately in `storage/development.sqlite3`
and `storage/test.sqlite3`. They are ignored by Git, along with logs, temporary
files, generated assets, and local secret keys. No credentials or environment
variables are required for local development.

### Try it on a phone

Run `bin/dev -b 0.0.0.0` and open `http://YOUR_COMPUTER_LAN_IP:3000` from a phone
on the same trusted Wi-Fi network. A firewall may need to allow the connection.
This exposes the development server to your local network: don't use it on an
untrusted network or expose it to the internet. Use `bin/dev -p 3001` if port
3000 is already occupied.

The sign-in and household member pages adapt to narrow screens and desktop. They
use semantic landmarks, a keyboard skip link, visible focus states, and no
animation or external fonts. For initial account creation, adding household
members, and account recovery, see
[Household access and account recovery](docs/household-access.md).

## Backups

For live SQLite backups, Backblaze B2 uploads, and recovery, see
[Database backups and recovery](docs/backups.md).

## Automated checks

See [Contributing](CONTRIBUTING.md) for all CI commands and the screenshot
requirements for user-facing pull requests. GitHub Actions checks application
tests, code quality, and the production asset build on proposed changes.

```sh
bin/rails test
```

The smoke tests request the sign-in page with desktop and mobile browser
headers, check the responsive viewport and Hotwire entry points, request `/up`,
and execute a SQLite query. The health endpoint confirms application boot, not
database or external-service availability.

To check autoloading and the asset build as well:

```sh
bin/rails zeitwerk:check
bin/rails assets:precompile
```

Compiled assets in `public/assets` take precedence over development assets.
After checking the build, run `bin/rails assets:clobber` before editing CSS or
JavaScript.

## Structure

- `app/controllers/sessions_controller.rb` and `app/views/sessions/`: sign-in
  and sign-out.
- `app/controllers/household_members_controller.rb` and
  `app/views/household_members/`: household member identity.
- `app/assets/stylesheets/application.css`: mobile-first styles.
- `app/javascript/` and `config/importmap.rb`: Turbo and Stimulus setup.
- `config/database.yml`: SQLite configuration.
- `test/integration/foundation_test.rb`: application smoke tests.

## License

[MIT](LICENSE).
