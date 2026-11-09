# Household Food Manager

A mobile-first Rails application for household food management. This foundation
provides a responsive welcome page, Rails health endpoint, Hotwire (Turbo and
Stimulus), and SQLite. Food inventory, authentication, deployment, and other
product features are intentionally not implemented yet.

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

The welcome page stacks on narrow screens and switches to two columns at 768px.
It uses semantic landmarks, a keyboard skip link, visible focus states, and no
animation or external fonts.

## Automated checks

```sh
bin/rails test
```

The smoke tests request the home page with desktop and mobile browser headers,
check the responsive viewport and Hotwire entry points, request `/up`, and execute
a SQLite query. The health endpoint confirms application boot, not database or
external-service availability.

To check autoloading and the asset build as well:

```sh
bin/rails zeitwerk:check
bin/rails assets:precompile
```

Compiled assets in `public/assets` take precedence over development assets.
After checking the build, run `bin/rails assets:clobber` before editing CSS or
JavaScript.

## Structure

- `app/controllers/home_controller.rb` and `app/views/home/index.html.erb`: welcome page.
- `app/assets/stylesheets/application.css`: mobile-first styles.
- `app/javascript/` and `config/importmap.rb`: Turbo and Stimulus setup.
- `config/database.yml`: SQLite configuration.
- `test/integration/foundation_test.rb`: application smoke tests.

## License

[MIT](LICENSE).
