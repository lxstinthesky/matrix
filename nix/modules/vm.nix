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
        { from = "host"; host.port = 8008; guest.port = 8008; }
      ];

      # Use QEMU's built-in DHCP with predictable addresses
      # Or configure vlans for multi-VM networking
      vlans = [ 1 ];  # Creates a virtual network on vlan 1
    };

    networking.firewall.enable = lib.mkForce false;

    networking.hostName = lib.mkForce "matrix-test";

    # DNS configuration for local testing
    services.dnsmasq = {
      enable = true;
      settings = {
        # Listen on localhost only
        listen-address = "127.0.0.1";
        # Bind to loopback interface
        interface = "lo";
        # Don't read /etc/resolv.conf
        no-resolv = true;
        # Forward all other queries to Cloudflare and Google DNS
        server = [ "1.1.1.1" "8.8.8.8" ];
        # Local DNS overrides for testing
        address = [ 
          "/matrix.test.com/127.0.0.1"
          "/test.com/127.0.0.1"
          "/matrix.example.com/127.0.0.1"
          "/example.com/127.0.0.1"
        ];
      };
    };

    # this is related to luks remote unlock via ssh
    # Disable initrd secrets for VM builds to avoid secret error 
    # Error is not present in real depolyments
    boot.initrd.secrets = lib.mkForce {};

    # Remove Hetzner-specific settings
    networking.useDHCP = lib.mkForce true;
    networking.nameservers = lib.mkForce [ "127.0.0.1" ];  # Point to dnsmasq for local DNS testing
    networking.interfaces = lib.mkForce {};
    networking.defaultGateway = lib.mkForce null;
    networking.defaultGateway6 = lib.mkForce null;
    boot.kernelParams = lib.mkForce [];
    boot.initrd.preLVMCommands = lib.mkForce "";

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