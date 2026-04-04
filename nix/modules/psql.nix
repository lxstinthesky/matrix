{config, pkgs, ... }:

{
  services.postgresql = {
    enable = true;
    enableTCPIP = false; # only using unix sockets
    package = pkgs.postgresql_17; 
    initialScript = pkgs.writeText "synapse-init.sql" ''
      CREATE ROLE "matrix-synapse" LOGIN;
      CREATE DATABASE "matrix-synapse"
        WITH OWNER "matrix-synapse"
        TEMPLATE template0
        LC_COLLATE = 'C'
        LC_CTYPE = 'C';
    '';
    settings = {
      unix_socket_directories = "/run/postgresql";
    };
  };

  services.postgresqlBackup = {
    enable = true;
    databases = [ "matrix-synapse" ];
    pgdumpOptions = "--exclude-table-data=public.e2e_one_time_keys_json";
    location = "/var/backup/postgresql";
    startAt = "03:15:00";
    compression = "zstd";
    compressionLevel = 6;
  };

  services.postgresql.ensureDatabases = [ "mautrix-whatsapp" ];
  services.postgresql.ensureUsers = [
    {
      name = "mautrix-whatsapp";
      ensureDBOwnership = true;
    }
  ];

  systemd.services.prune-postgresql-backups = {
    description = "Prune old PostgreSQL backup dumps";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      if [ -d /var/backup/postgresql ]; then
        find /var/backup/postgresql -type f -mtime +7 -delete
      fi
    '';
  };

  systemd.timers.prune-postgresql-backups = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
  };

  systemd.services.update-postgresql-backup-metrics = {
    description = "Export PostgreSQL backup freshness metrics for Prometheus";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      metrics_dir=/var/lib/prometheus-node-exporter-textfiles
      metrics_file="$metrics_dir/postgresql_backup.prom"
      tmp_file="$metrics_file.tmp"

      mkdir -p "$metrics_dir"

      latest_mtime=$(find /var/backup/postgresql -type f -printf '%T@\n' 2>/dev/null | sort -n | tail -n 1)
      if [ -n "$latest_mtime" ]; then
        latest_mtime=$(printf '%.0f' "$latest_mtime")
      else
        latest_mtime=0
      fi

      cat > "$tmp_file" <<EOF
      # HELP postgresql_backup_last_success_timestamp_seconds Unix timestamp of the newest PostgreSQL dump file.
      # TYPE postgresql_backup_last_success_timestamp_seconds gauge
      postgresql_backup_last_success_timestamp_seconds $latest_mtime
      EOF

      mv "$tmp_file" "$metrics_file"
    '';
  };

  systemd.timers.update-postgresql-backup-metrics = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10m";
      OnUnitActiveSec = "1h";
      Persistent = true;
    };
  };

  # setting up unix socket directory for postgresql
  systemd.tmpfiles.rules = [
   "d /run/postgresql 0755 postgres postgres -"
   "d /var/lib/prometheus-node-exporter-textfiles 0755 root root -"
  ];
}