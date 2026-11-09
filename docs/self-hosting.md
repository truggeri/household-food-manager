# Self-hosting with Docker Compose

This setup runs the app on a home server and makes it available to devices on
the same home network. It does not configure a public address, HTTPS, or access
from outside your home network. Do not forward the app's port from your router.

## Requirements

- A server with Docker Engine and the Docker Compose plugin (`docker compose`).
- A trusted home network. The app is served over HTTP in this setup.

The initial image build needs access to download the Ruby base image and Ruby
gems. Once built, the app does not need public internet access to serve pages on
your home network.

## First-time setup

On the server, clone this repository and enter its directory. Then create a
private environment file and generate a unique Rails secret:

```sh
cp .env.example .env
openssl rand -hex 64
```

Edit `.env` and paste the generated value after `SECRET_KEY_BASE=`. Keep `.env`
private; it is ignored by Git. Change `APP_PORT` if port 3000 is already in use.
The example's HTTP settings are intended only for this direct, trusted-LAN
setup.

Build and start the app:

```sh
docker compose up -d --build
docker compose logs -f web
```

The container prepares the SQLite database on startup and listens on all
container interfaces. From another device on the same home network, open
`http://SERVER_LAN_IP:3000` (or the port selected by `APP_PORT`). Find the
server's LAN IP in its network settings or router. If the page does not load,
check that the server firewall allows the selected port from your home network.

## Updating

From the repository directory on the server, fetch the new version and rebuild:

```sh
git pull
docker compose up -d --build
```

The Compose service restarts automatically after a host restart. The app's
SQLite database is stored at `storage/production.sqlite3` on the server, outside
the container image, so rebuilding or replacing the container does not erase
household data. Keep `.env` in place during updates.

## Stopping and backing up

Stop the app with:

```sh
docker compose down
```

To make a consistent database backup, stop the app, copy the database file to a
safe location, then start the app again:

```sh
docker compose stop
cp storage/production.sqlite3 /path/to/private-backup/production.sqlite3
docker compose start
```

Protect backups as carefully as the live database. To restore one, stop the
app, replace `storage/production.sqlite3` with the backup, then start the app.
The database and `.env` are machine-local data and settings; neither should be
committed to the repository.
