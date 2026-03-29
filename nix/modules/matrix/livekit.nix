{ config, lib, pkgs, ... }: 
let
  fqdn = "${config.networking.hostName}.${config.networking.domain}";
in 
# https://wiki.nixos.org/wiki/Matrix
{
  sops.secrets = {
    "livekit/api-secret" = {
      mode = "0444";
      owner = "nobody"; # TODO which user runs livekit?
      group = "nogroup";
      sopsFile = ../../../secrets/livekit.yaml;
    };
  };

  services.livekit = {
    enable = true;
    openFirewall = true;
    settings.room.auto_create = false;
    keyFile = "/run/secrets/livekit/api-secret";
  };
  services.lk-jwt-service = {
    enable = true;
    # can be on the same virtualHost as synapse
    livekitUrl = "wss://${fqdn}/livekit/sfu";
    keyFile = "/run/secrets/livekit/api-secret";
  };
  # restrict access to livekit room creation to a homeserver
  systemd.services.lk-jwt-service.environment.LIVEKIT_FULL_ACCESS_HOMESERVERS = config.networking.domain;
}