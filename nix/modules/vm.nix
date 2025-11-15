{ config, pkgs, inputs, lib, ... }:
# this configuration will only be loaded inside of VMs build for testing purposes
# none of this will be applied to real deployments
{
  virtualisation.vmVariant = {
    # following configuration is added only when building VM with build-vm
    virtualisation = {
      memorySize = 4000;
      cores = 2;
      graphics = false;
      diskSize = 5000; # 5GB, needed to prevent docker error running out of space

      # Networking configuration
      forwardPorts = [
        { from = "host"; host.port = 2222; guest.port = 22; }
      ];
    };

    # this is related to luks remote unlock via ssh
    # Disable initrd secrets for VM builds to avoid secret error 
    # Error is not present in real depolyments
    boot.initrd.secrets = lib.mkForce {};

    # Add VM-specific users
    users.users.smith = {
      isNormalUser = true;
      description = "VM Test User";
      extraGroups = [ "wheel" "networkmanager" ];
      shell = pkgs.zsh;
      initialPassword = "smith";
      packages = with pkgs; [  ];
    };

    # VM-specific packages
    environment.systemPackages = with pkgs; [
    ];

    # in order to build VM on x86_64 host
    nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";
  };
}