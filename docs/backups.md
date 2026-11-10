# Database backups and recovery

`bin/backup` uses SQLite's online backup API, not a copy of the active database.
It captures a consistent snapshot including committed WAL data while the app
continues serving requests. Uncommitted changes are not included. It checks
integrity before publishing a uniquely named `.sqlite3` file; partial files are
removed on failure. A busy database is retried for up to 60 seconds, then the
command fails so an operator can retry. Both commands exit nonzero and report
local or upload failures; a failed upload leaves the local backup intact.

## Prerequisites and local backups

Use the [Compose deployment](self-hosting.md) with the `web` service running,
the current image rebuilt, and enough free host disk space for another full
database (plus ongoing WAL writes). From the repository directory:

```sh
script/backup
```

The script runs `docker compose exec -T web bin/backup`. The resulting file is
under host `storage/backups/`, visible through the existing `/rails/storage`
bind mount. No SQLite CLI or additional gem is needed. New files are private
(mode 600); the backup directory is created with mode 700. Run as the deployment
owner with permission to access Docker and the storage directory.

Without Docker, use the repository's Ruby and installed bundle:

```sh
bin/backup storage/development.sqlite3 /absolute/private/backup-directory
```

The defaults are **production** and `storage/backups`, independent of
`RAILS_ENV`. Always specify the source for development or test data.
Do not copy an active `.sqlite3` file directly, or discard its `-wal` file.

Local backups do **not** protect against server loss. Copy them to private
off-server storage, or enable B2 uploads below. No automatic deletion is
performed. Monitor disk use and define retention for both local and remote
backups; never remove the last known recoverable copy.

## Backblaze B2 uploads

Install AWS CLI v2 **on the host**, create a **private** B2 bucket, and create
a bucket-restricted application key with upload permission. Use a separate
key with read and list permissions for recovery if desired. Set the endpoint and region shown by
Backblaze for that bucket. No storage is provisioned by this repository.

Keep the credentials outside Git and outside the web container. For example,
create a host-only `.env.backup` in the repository, ignored by Git and Docker:

```sh
export B2_BUCKET='your-private-bucket'
export B2_ENDPOINT_URL='https://s3.us-west-004.backblazeb2.com'
export AWS_DEFAULT_REGION='us-west-004'
export AWS_ACCESS_KEY_ID='your-B2-key-ID'
export AWS_SECRET_ACCESS_KEY='your-B2-application-key'
```

Use your actual bucket region, not necessarily this example. Protect this file
with `chmod 600 .env.backup`; do not put B2 credentials in Compose's `.env`.
The AWS CLI credential chain (for example a private named profile via
`AWS_PROFILE`) is also supported instead of explicit AWS key variables.

```sh
. ./.env.backup
script/backup --upload-b2
```

Each successful run uploads one object under
`s3://BUCKET/household-food-manager/household-TIMESTAMP-RANDOM.sqlite3`.
The application itself needs no B2 access. Backups contain household data;
control key access and bucket permissions, rotate keys, and use B2 lifecycle
rules for retention. B2 transport uses HTTPS; the script does not add
client-side encryption. Decide whether additional encryption is required and
store its recovery keys separately before using real household data.

### Schedule and monitoring

Run on the host using cron or a systemd timer. For example, edit the deployment
owner's crontab (`crontab -e`) to run daily at 03:00 in the host's timezone:

```cron
PATH=/usr/local/bin:/usr/bin:/bin
0 3 * * * cd /srv/household-food-manager && . ./.env.backup && script/backup --upload-b2 >> /srv/private-backup.log 2>&1
```

Replace paths and include the actual Docker/AWS CLI directories in `PATH`.
Pre-create the log with mode 600 and arrange log rotation. Use `script/backup`
without the flag for local-only scheduling (no environment file required).
Configure cron mail or external job monitoring to alert on nonzero exits,
missing runs, and stale remote objects. Scheduling alone is not monitoring.
Choose frequency and retention based on acceptable data loss and cost.
Check remote uploads and rehearse recovery periodically, including after
schema changes.

## Retrieve and restore

Restore requires a compatible application version, the backup, Docker (or the
correct Ruby bundle), and deployment secrets such as the original `.env`.
Database backups do **not** include `.env`, Rails secrets, attachments, or other
files in `storage`. Keep those separately in secure off-server storage as
needed. This foundation currently has no uploaded-file feature.

1. Select the desired timestamp. With read-capable B2 credentials loaded:

   ```sh
   aws --endpoint-url "$B2_ENDPOINT_URL" s3 ls "s3://$B2_BUCKET/household-food-manager/"
   umask 077
   mkdir -p storage/backups
   aws --endpoint-url "$B2_ENDPOINT_URL" s3 cp \
     "s3://$B2_BUCKET/household-food-manager/EXACT-BACKUP-NAME.sqlite3" \
     storage/backups/recovery.sqlite3 --only-show-errors
   ```

   For a local backup, use its existing filename instead. Check download exit
   status; do not proceed after an error.

2. Verify the backup before replacing anything. This also creates a checked
   local copy, without modifying the downloaded file:

   ```sh
   docker compose exec -T web bin/backup storage/backups/recovery.sqlite3 storage/backups/verified
   ```

3. Stop **all** processes that access this database (including backup jobs).
   Preserve the old database and sidecars together, then install the backup:

   ```sh
   (
     set -eu
     docker compose stop web
     saved="storage/before-restore-$(date -u +%Y%m%dT%H%M%SZ)"
     mkdir -m 700 "$saved"
     for file in storage/production.sqlite3 storage/production.sqlite3-wal storage/production.sqlite3-shm; do
       if [ -e "$file" ]; then mv "$file" "$saved/"; fi
     done
     cp storage/backups/recovery.sqlite3 storage/production.sqlite3
     chmod 600 storage/production.sqlite3
     docker compose up -d web
     docker compose logs --tail=100 web
   )
   ```

   Stop if any command fails. Use a unique preservation directory on every
   attempt. Ensure the restored file is writable by the container's user.
   Never leave old `-wal`/`-shm` files beside a restored database. The container
   runs `db:prepare` at startup, applying pending migrations; prefer the app
   version that created the backup, then upgrade normally. Do not start older
   application code against a newer schema.

4. Open the app and check recovered records, not just `/up` (which checks boot,
   not data). Preserve the pre-restore files until recovery is confirmed.
   For a failed-server recovery, first rebuild the same app version and restore
   deployment secrets following the self-hosting guide, then install the
   database **before** starting the web service. To perform the integrity
   check before web is running, replace `exec -T web` with
   `run --rm --no-deps -T web` in step 2.

Automated tests back up a real WAL-mode SQLite database while a writer remains
connected, recover committed records into a replacement database, and verify
that uncommitted records are excluded. Upload tests use a fake AWS CLI and do
not send data externally. A real B2 round trip must be verified by the operator
with their bucket and credentials before relying on scheduled backups.
