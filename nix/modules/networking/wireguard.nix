# WireGuard VPN server
# 
# === One-time setup ===
#
# 1. Generate server keypair (on any machine with wireguard-tools):
#      wg genkey | tee server-private.key | wg pubkey > server-public.key
#
# 2. Encrypt the private key into sops:
#      Add "wireguard/server-private-key" to secrets/wireguard.yaml and encrypt it.
#
# 3. For each client (laptop, phone, etc.):
#      wg genkey | tee client-private.key | wg pubkey > client-public.key
#    Add the client's PUBLIC key as a new peer below.
#    Give the client its private key + the server public key to configure their WireGuard app.
#
# === Client config template ===
#
#   [Interface]
#   PrivateKey = <client-private-key>
#   Address    = 10.100.0.X/32   # assign a unique IP per client
#   DNS        = 10.100.0.1       # optional: use server as DNS
#
#   [Peer]
#   PublicKey  = <server-public-key>   # from server-public.key above
#   Endpoint   = 188.245.32.95:51820
#   AllowedIPs = 10.100.0.0/24         # only route VPN subnet through tunnel
#                                       # use 0.0.0.0/0 to route ALL traffic
#   PersistentKeepalive = 25

{ config, ... }:
{
  sops.secrets."wireguard/server-key" = {
    mode = "0400";
    owner = "root";
    sopsFile = ../../../secrets/wireguard.yaml;
  };

  networking.wireguard.interfaces.wg0 = {
    # VPN subnet: server is 10.100.0.1, clients get 10.100.0.2+
    ips = [ "10.100.0.1/24" ];
    listenPort = 51820;
    privateKeyFile = "/run/secrets/wireguard/server-key";

    peers = [
      # --- Add one entry per client ---
      # neo
      {
        publicKey  = "IXquAxIxVQYM3+ti7mUCrGzZ18RKIBruY9Xi63O411U=";
        allowedIPs = [ "10.100.0.2/32" ];  # unique IP per client
      }
    ];
  };

  # Open WireGuard port
  networking.firewall.allowedUDPPorts = [ 51820 ];

  # Trust the WireGuard interface — peers can reach localhost services
  networking.firewall.trustedInterfaces = [ "wg0" ];
}
