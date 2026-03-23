{ config, pkgs, inputs, ... }:
# this file provides a static networking configuration
# https://docs.hetzner.com/cloud/servers/static-configuration/
let
  # IPv4 configuration
  ipv4Address = "188.245.32.95";  # Hetzner assigned static IP
  ipv4Gateway = "172.31.1.1";     # hetzner gateway
  ipv4Netmask = 32;               # CIDR notation
  
  # IPv6 configuration
  ipv6Address = "2a01:4f8:1c1b:9b71::1";
  ipv6Gateway = "fe80::1";    # link-local gateway
  ipv6PrefixLength = 64;
  
  # DNS servers
  # hetzner nameservers
  nameservers = [ "185.12.64.1" "185.12.64.2" "2a01:4ff:ff00::add:1" "2a01:4ff:ff00::add:2" ];

  # Network interface name
  interface = "enp1s0";

  hostname = "matrix";
in
{
  networking.hostName = hostname;
  networking.domain = "asterism.ch";
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  
  # Disable DHCP globally
  networking.useDHCP = false;
  
  # Configure network interface
  networking.interfaces.${interface} = {
    ipv4.addresses = [{
      address = ipv4Address;
      prefixLength = ipv4Netmask;
    }];

    # Add point-to-point route to gateway
    # specific requirement of Hetzner
    ipv4.routes = [{
      address = ipv4Gateway;
      prefixLength = 32;
    }];
    
    ipv6.addresses = [{
      address = ipv6Address;
      prefixLength = ipv6PrefixLength;
    }];
  };
  
  # Set default gateway
  networking.defaultGateway = {
    address = ipv4Gateway;
    interface = interface;
  };
  
  networking.defaultGateway6 = {
    address = ipv6Gateway;
    interface = interface;
  };
  
  # DNS configuration
  networking.nameservers = nameservers;
  
  # Enable IPv6
  networking.enableIPv6 = true;
  
  # Optional: Disable IPv6 privacy extensions for static config
  networking.tempAddresses = "disabled";

  # this is needed for remote LUKS unlock via ssh
  # here we do not actually need a static ip configuration, hetzner will handle this anyway
  boot.kernelParams = [ "ip=dhcp" ];
}