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
    # using the same key as for initrd
    hostKeys = [
      { path = "/etc/secrets/initrd/ssh_host_ed25519_key"; type = "ed25519"; }
    ];
  };

  # remote unlock for luks via ssh
  boot.kernelParams = [ "ip=dhcp" ];
  boot.initrd = {
    availableKernelModules = [ "virtio-pci" ];
    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 22;
        authorizedKeys = [ 
          (builtins.readFile ../users/keys/neo.pub) 
          (builtins.readFile ../users/keys/morpheus.pub) 
        ];
        hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
        shell = "/bin/cryptsetup-askpass";
      };
    };
  };

  # Generate SSH host key for initrd
  system.activationScripts.initrd-ssh-key = {
    text = ''
      mkdir -p /etc/secrets/initrd
      if [ ! -f /etc/secrets/initrd/ssh_host_ed25519_key ]; then
        ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f /etc/secrets/initrd/ssh_host_ed25519_key -N ""
        chmod 600 /etc/secrets/initrd/ssh_host_ed25519_key
        chmod 644 /etc/secrets/initrd/ssh_host_ed25519_key.pub
      fi
    '';
    deps = [ ];
  };

  # other security hardening options can go here
  security.sudo.wheelNeedsPassword = false;
}