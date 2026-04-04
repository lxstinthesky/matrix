# The Matrix Protocol
Who needs something else?

# Depolyment

## Manual Steps

# Operation

## PostgreSQL Backups

The current PostgreSQL backup configuration is defined in [nix/modules/psql.nix](/home/henrik/Code/matrix/nix/modules/psql.nix).

Important: the current backup job only dumps the `matrix-synapse` database. The `mautrix-whatsapp` database is created on the host, but it is not included in `services.postgresqlBackup.databases` right now.

Backups are written to `/var/backup/postgresql` and, with the current config, the active dump file is:

```sh
/var/backup/postgresql/matrix-synapse.sql.zstd
```

The previous dump is kept as:

```sh
/var/backup/postgresql/matrix-synapse.prev.sql.zstd
```

### Force a Dump

To trigger a dump immediately, start the generated systemd unit for the configured database:

```sh
sudo systemctl start postgresqlBackup-matrix-synapse.service
```

To confirm that the dump exists and has a fresh timestamp:

```sh
sudo ls -lh /var/backup/postgresql
```

### Restore the Database

If the production `matrix-synapse` database must be fully restored from backup:

1. Stop services that write to Synapse before restoring:

```sh
sudo systemctl stop matrix-hookshot.service mautrix-whatsapp.service matrix-synapse.service
```

2. Drop and recreate the database with the same owner and locale settings:

```sh
sudo -u postgres dropdb matrix-synapse
sudo -u postgres createdb \
	--owner=matrix-synapse \
	--template=template0 \
	--lc-collate=C \
	--lc-ctype=C \
	matrix-synapse
```

3. Restore the dump:

```sh
sudo -u postgres sh -c 'zstd -dc /var/backup/postgresql/matrix-synapse.sql.zstd | psql matrix-synapse'
```

4. Start the services again:

```sh
sudo systemctl start matrix-synapse.service mautrix-whatsapp.service matrix-hookshot.service
```