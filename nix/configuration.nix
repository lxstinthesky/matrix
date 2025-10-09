{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ./users/users.nix
    ./modules/ssh.nix
    ./hardware-configuration.nix
    ./modules/zsh.nix
   ];

  # nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.grub.enable = true;

  networking.hostName = "matrix";

  # time zone
  time.timeZone = "Europe/Zurich";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Allow unfree packages
  # nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; [
  ];

  virtualisation.vmVariant = {
    # following configuration is added only when building VM with build-vm
    virtualisation = {
      memorySize = 4000;
      cores = 2;
      graphics = false;
      diskSize = 5000; # 5GB, needed to prevent docker error running out of space

      # Networking configuration
      #forwardPorts = [
      #  { from = "host"; host.port = 2222; guest.port = 22; }
      #];
    };

    # Add VM-specific users
    users.users.smith = {
      isNormalUser = true;
      description = "VM Test User";
      extraGroups = [ "wheel" "networkmanager" ];
      shell = pkgs.zsh;
      initialPassword = "smith";
      packages = with pkgs; [  ];
    };

    security.sudo.wheelNeedsPassword = false;

    # VM-specific packages
    environment.systemPackages = with pkgs; [
    ];

    # in order to build VM on x86_64 host
    nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
