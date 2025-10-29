{ config, pkgs, inputs, ... }:

{
  # Define user accounts
  users.defaultUserShell = pkgs.zsh;
  users.users.neo = {
    isNormalUser = true;
    description = "Neovim only user";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ ];
    openssh.authorizedKeys.keyFiles = [
      ./keys/neo.pub
    ];
  };

  users.users.morpheus = {
    isNormalUser = true;
    description = "I'm colorblind";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ ];
    openssh.authorizedKeys.keyFiles = [
      ./keys/morpheus.pub
    ];
  };

  users.users.trinity = {
    isNormalUser = true;
    description = "Named after an atom bomb test";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ ];
  };
}