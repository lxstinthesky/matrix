{ config, pkgs, inputs, ... }:

{
  # Define user accounts
  users.defaultUserShell = pkgs.zsh;
  users.users.neo = {
    isNormalUser = true;
    description = "Matrix User 1";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ ];
  };

  users.users.morpheus = {
    isNormalUser = true;
    description = "Matrix User 2";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ ];
  };

  users.users.trinity = {
    isNormalUser = true;
    description = "Matrix User 3";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ ];
  };
}