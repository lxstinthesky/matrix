{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ./vps/hetzner/hardware-configuration.nix
    ./modules/networking/networking.nix
    ./modules/networking/proxy.nix
    ./modules/security.nix
    ./users/users.nix
    ./modules/zsh.nix
    ./modules/vm.nix
    ./modules/matrix/synapse.nix
   ];

  # nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.download-buffer-size = 524288000; # 500MB

  # Bootloader to work with LUKS
  boot.loader.grub = {
    enable = true;
    # https://github.com/NixOS/nixpkgs/issues/55332
    device = "nodev";                    # Don't install to MBR
    efiSupport = true;                   # Enable EFI support
    enableCryptodisk = true;             # Enable LUKS support
  };
  
  boot.loader.efi.canTouchEfiVariables = true;

  # LUKS configuration
  boot.initrd.luks.devices."crypted" = {
    device = "/dev/disk/by-partlabel/luks";
    allowDiscards = true;
  };

  
  boot.initrd.kernelModules = [ "virtio_gpu" ];
  boot.kernelParams = [ "console=tty" ];  

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
