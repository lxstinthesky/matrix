{ config, pkgs, inputs, lib, ... }:
let
  fqdn = "${config.networking.hostName}.${config.networking.domain}";
  baseUrl = "https://${fqdn}";
in
{
  sops.secrets = {
    "coturn/static-auth-secret" = {
      mode = "0400";
      owner = "coturn";
      sopsFile = ../../../secrets/coturn.yaml;
    };
  };

  # https://discourse.nixos.org/t/how-to-make-coturn-play-nice-with-matrix-continuwuity/69433
  # https://github.com/element-hq/element-android/issues/1533
  # https://nixos.wiki/wiki/Matrix#Coturn_with_Synapse
  services.coturn = rec {
    enable = true;
    use-auth-secret = true;
    static-auth-secret-file = "/run/secrets/coturn/static-auth-secret";

    realm = "turn.${config.networking.domain}";

    no-cli = true;
    no-tcp-relay = true;
    #secure-stun = true;
    cert = "${config.security.acme.certs."turn.${config.networking.domain}".directory}/fullchain.pem";
    pkey = "${config.security.acme.certs."turn.${config.networking.domain}".directory}/key.pem";

    extraConfig = ''
      # for debugging
      verbose
      # ban private IP ranges
      no-multicast-peers
      denied-peer-ip=0.0.0.0-0.255.255.255
      denied-peer-ip=10.0.0.0-10.255.255.255
      denied-peer-ip=100.64.0.0-100.127.255.255
      denied-peer-ip=127.0.0.0-127.255.255.255
      denied-peer-ip=169.254.0.0-169.254.255.255
      denied-peer-ip=172.16.0.0-172.31.255.255
      denied-peer-ip=192.0.0.0-192.0.0.255
      denied-peer-ip=192.0.2.0-192.0.2.255
      denied-peer-ip=192.88.99.0-192.88.99.255
      denied-peer-ip=192.168.0.0-192.168.255.255
      denied-peer-ip=198.18.0.0-198.19.255.255
      denied-peer-ip=198.51.100.0-198.51.100.255
      denied-peer-ip=203.0.113.0-203.0.113.255
      denied-peer-ip=240.0.0.0-255.255.255.255
      denied-peer-ip=::1
      denied-peer-ip=64:ff9b::-64:ff9b::ffff:ffff
      denied-peer-ip=::ffff:0.0.0.0-::ffff:255.255.255.255
      denied-peer-ip=100::-100::ffff:ffff:ffff:ffff
      denied-peer-ip=2001::-2001:1ff:ffff:ffff:ffff:ffff:ffff:ffff
      denied-peer-ip=2002::-2002:ffff:ffff:ffff:ffff:ffff:ffff:ffff
      denied-peer-ip=fc00::-fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
      denied-peer-ip=fe80::-febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff
    '';
  };

  networking.firewall.allowedTCPPorts = [
    config.services.coturn.listening-port
    config.services.coturn.tls-listening-port
  ];
  networking.firewall.allowedUDPPorts = [
    config.services.coturn.listening-port
    config.services.coturn.tls-listening-port
  ];

  networking.firewall.allowedUDPPortRanges = [
    {
      from = config.services.coturn.min-port;
      to = config.services.coturn.max-port;
    }
  ];

   # get a certificate
  security.acme.certs.${config.services.coturn.realm} = {
    postRun = "systemctl restart coturn.service";
    group = "turnserver";
  };

  # configure synapse to point users to coturn
  services.matrix-synapse.settings = with config.services.coturn; {
    turn_uris = ["turn:${realm}:3478?transport=udp" "turn:${realm}:3478?transport=tcp"];
    turn_shared_secret = static-auth-secret;
    turn_user_lifetime = "1h";
  };
}
