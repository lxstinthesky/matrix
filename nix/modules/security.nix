{ config, pkgs, inputs, ... }:

{
  # providing an ssh configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";                    # Disable root login
      PasswordAuthentication = false;            # Force SSH key auth only
      PubkeyAuthentication = true;               # Enable SSH keys
    };
    ports = [ 22 ];
  };

  # other security hardening options can go here
  security.sudo.wheelNeedsPassword = false;
}