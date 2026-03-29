{ config, pkgs, lib, ... }:
let
  ketesaRoot = pkgs.stdenvNoCC.mkDerivation {
    name = "ketesa-v0.11.1-etke53";
    src = pkgs.fetchurl {
      url ="https://github.com/etkecc/ketesa/releases/download/v0.11.1-etke53/synapse-admin.tar.gz";
      sha256 = "sha256-VUXTMMaesqtOvgINhCjeIpgB++dFWumeXNdgxdx/AqE=";
    };
    dontBuild = true;
    installPhase = ''
      mkdir -p $out
      tar -xzf $src -C $out --strip-components=1
      # Overwrite the bundled config.json with our own
      cp ${../../../etc/ketesa/config.json} $out/config.json
    '';
  };
in
{
  # Serve ketesa as static files via nginx on the WireGuard interface only.
  # Access: connect to WireGuard, then open http://10.100.0.1/ketesa/
  services.nginx.virtualHosts."vpn-ketesa" = {
    listen = [{ addr = "10.100.0.1"; port = 80; ssl = false; }];
    serverName = "_";
    locations."/ketesa/" = {
      root = lib.mkForce ketesaRoot;
      tryFiles = "$uri /index.html";
    };
  };
}
