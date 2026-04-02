{ config, ... }:
{
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9100;
    enabledCollectors = [ "systemd" "textfile" ];
    extraFlags = [ "--collector.textfile.directory=/var/lib/prometheus-node-exporter-textfiles" ];
  };

  services.prometheus.exporters.postgres = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9187;
    runAsLocalSuperUser = true;
    dataSourceName = "user=postgres database=postgres host=/run/postgresql sslmode=disable";
  };

  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    webExternalUrl = "http://10.100.0.1/prometheus/";
    retentionTime = "7d";
    alertmanagers = [
      {
        static_configs = [
          {
            targets = [ "127.0.0.1:9093" ];
          }
        ];
      }
    ];
    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = [ "127.0.0.1:9090" ];
          }
        ];
      }
      {
        job_name = "node";
        static_configs = [
          {
            targets = [ "127.0.0.1:9100" ];
          }
        ];
      }
      {
        job_name = "postgres";
        static_configs = [
          {
            targets = [ "127.0.0.1:9187" ];
          }
        ];
      }
    ];
    rules = [ "${../../etc/prometheus/rules.yaml}" ];
  };

  services.prometheus.alertmanager = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9093;
    webExternalUrl = "http://10.100.0.1/alertmanager/";
    configuration = {
      global = { };
      route = {
        receiver = "local-ui";
        group_by = [ "alertname" "instance" ];
        group_wait = "30s";
        group_interval = "5m";
        repeat_interval = "4h";
      };
      receivers = [
        {
          name = "local-ui";
        }
      ];
    };
  };
}
