{ config, pkgs, inputs, lib, ... }:
let
  fqdn = "${config.networking.hostName}.${config.networking.domain}";
  baseUrl = "https://${fqdn}";
in
{
  sops.secrets = {
    "matrix/shared-secret" = {
      mode = "0400";
      owner = "matrix-synapse";
      sopsFile = ../../../secrets/matrix.yaml;
    };
  };
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

  # setting up unix socket directory for postgresql
  systemd.tmpfiles.rules = [
   "d /run/postgresql 0755 postgres postgres -"
  ];

  services.matrix-synapse = {
    enable = true;
    settings.server_name = config.networking.domain;
    settings.public_baseurl = baseUrl;
    # The public base URL value must match the `base_url` value set in `clientConfig` above.
    # The default value here is based on `server_name`, so if your `server_name` is different
    # from the value of `fqdn` above, you will likely run into some mismatched domain names
    # in client applications.
    settings.database.args = {
      user = "matrix-synapse";
    };

    # registrations via tokens only!
    settings.enable_registration = true;
    extraConfigFiles = [ 
      "/run/secrets/matrix/shared-secret" 
    ];

    settings.max_upload_size = "50M";

    settings.listeners = [
      { port = 8008;
        bind_addresses = [ "127.0.0.1" ];
        type = "http";
        tls = false;
        x_forwarded = true;
        resources = [ {
          names = [ "client" "federation" ];
          compress = true;
        } ];
      }
    ];
  };
}
