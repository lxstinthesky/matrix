{ config, pkgs, ... }:
{
  # Deploy the ketesa config file from the repo into /etc/ketesa/config.json
  environment.etc."ketesa/config.json" = {
    source = ../../../etc/ketesa/config.json;
    mode = "0440";
    user = "root";
    group = "root";
  };

  # Access by wireguard only!
  virtualisation.oci-containers.containers.ketesa = {
    image = "ghcr.io/etkecc/ketesa:latest";
    autoStart = true;
    ports = [ "10.100.0.1:8888:8080" ];
    volumes = [
      # /var/public is the container's document root where static files are served from
      "/etc/ketesa/config.json:/var/public/config.json:ro"
    ];
  };
}
