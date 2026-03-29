{ config, pkgs, ... }:
{
  # Deploy the ketesa config file from the repo into /etc/ketesa/config.json
  environment.etc."ketesa/config.json" = {
    source = ../../../etc/ketesa/config.json;
    mode = "0440";
    user = "root";
    group = "root";
  };

  # Ketesa listens on localhost only — access it via SSH tunnel:
  #   ssh -L 8888:127.0.0.1:8888 neo@188.245.32.95 -N
  # then open http://localhost:8888 in your browser.
  # No public vhost or DNS record needed.
  virtualisation.oci-containers.containers.ketesa = {
    image = "ghcr.io/etkecc/ketesa:latest";
    autoStart = true;
    ports = [ "127.0.0.1:8888:8080" ];
    volumes = [
      # /var/public is the container's document root where static files are served from
      "/etc/ketesa/config.json:/var/public/config.json:ro"
    ];
  };
}
