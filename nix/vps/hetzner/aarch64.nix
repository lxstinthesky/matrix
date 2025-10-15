{ config, lib, ... }:

{
  # Specific settings for Hetzner Cloud AArch64 instances
  # https://wiki.nixos.org/wiki/Install_NixOS_on_Hetzner_Cloud#AArch64_(CAX_instance_type)_specifics
  boot.initrd.kernelModules = [ "virtio_gpu" ];
  boot.kernelParams = [ "console=tty" ];  

  # aarch64-linux
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}