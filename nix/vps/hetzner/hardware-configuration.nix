{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./aarch64.nix
  ];

  networking.useDHCP = lib.mkDefault true;
}