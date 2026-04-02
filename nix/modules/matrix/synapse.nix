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
  

  # Deploy extra homeserver config (options not exposed by the NixOS module)
  environment.etc."synapse/homeserver.yaml" = {
    source = ../../../etc/synapse/homeserver.yaml;
    mode = "0440";
    user = "matrix-synapse";
    group = "matrix-synapse";
  };

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
      "/etc/synapse/homeserver.yaml"
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
