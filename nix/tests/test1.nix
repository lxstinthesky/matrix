{ pkgs ? import <nixpkgs> {} }:

pkgs.nixosTest {
  name = "matrix-login-test";
  
  nodes = {
    machine = { config, pkgs, ... }: {
      imports = [
        ../configuration.nix
      ];
      
      # Test configuration
      virtualisation.memorySize = 2048;
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    with subtest("SSH service test"):
        machine.wait_for_unit("sshd.service")
        machine.wait_for_open_port(22)
  '';
}