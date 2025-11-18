{ config, lib, ... }:
let
  cfg = config.networking.dn42;
in
{
  imports = [
    ./firewall.nix
    ./bird2.nix
    ./stayrtr.nix
    ./roagen.nix
    ./wg-tunnels.nix
  ];

  options.networking.dn42 = {
    enable = lib.mkEnableOption "DN42 integration";

    routerId = lib.mkOption {
      type = lib.types.str;
      description = "32bit router identifier. Defaults to the router's IPv4 address(you probably shouldn't change this)";
      default = cfg.addr.v4;
    };

    as = lib.mkOption {
      type = lib.types.int;
      description = "Your DN42 Autonomous System Number";
    };

    region = lib.mkOption {
      type = lib.types.int;
      description = "Region BGP Community Number(see https://dn42.dev/howto/BGP-communities#region)";
    };

    country = lib.mkOption {
      type = lib.types.int;
      description = "Region BGP Community Number(see https://dn42.dev/howto/BGP-communities#country)";
    };

    blockedAs = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      description = "ASNs to block.";
    };

    collector.enable = lib.mkEnableOption "Enable peering with the DN42 route collector(https://dn42.dev/services/Route-Collector)";

    addr = {
      v4 = lib.mkOption {
        type = lib.types.str;
        description = "Primary IPv4 address";
      };

      v6 = lib.mkOption {
        type = lib.types.str;
        description = "Primary IPv6 address";
      };
    };

    nets = {
      v4 = lib.mkOption {
        type = with lib.types; listOf str;
        description = "Own IPv4 networks, list of CIDRs";
      };

      v6 = lib.mkOption {
        type = with lib.types; listOf str;
        description = "Own IPv6 networks, list of CIDRs";
      };
    };

    peers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          as = lib.mkOption {
            type = lib.types.int;
            description = "Autonomous System Number of the peer.";
          };

          extendedNextHop = lib.mkOption {
            type = lib.types.bool;
            description = "If extended next-hop should be used, which creates IPv4 routes using an IPv6 next-hop address.";
            default = false;
          };

          latency = lib.mkOption {
            type = lib.types.int;
            description = "Latency BGP Community(see https://dn42.dev/howto/BGP-communities#bgp-community-criteria)";
          };

          bandwidth = lib.mkOption {
            type = lib.types.int;
            description = "Bandwidth BGP Community(see https://dn42.dev/howto/BGP-communities#bgp-community-criteria)";
          };

          crypto = lib.mkOption {
            type = lib.types.int;
            description = "Encryption BGP Community(see https://dn42.dev/howto/BGP-communities#bgp-community-criteria)";
          };

          transit = lib.mkOption {
            type = lib.types.bool;
            description = "Whether to transit BGP routes from other peers via this peering";
          };

          addr = {
            v4 = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "IPv4 address of the peer.";
              default = null;
            };

            v6 = lib.mkOption {
              type = lib.types.str;
              description = "IPv6 address of the peer.";
            };
          };

          srcAddr = {
            v4 = lib.mkOption {
              type = with lib.types; nullOr str;
              description = "Local IPv4 address to use for BGP.";
              default = null;
            };

            v6 = lib.mkOption {
              type = with lib.types; nullOr str;
              description = "Local IPv6 address to use for BGP.";
            };
          };

          interface = lib.mkOption {
            type = lib.types.str;
            description = "Interface name of the peer.";
          };
        };
      });
    };

    vrf = {
      name = lib.mkOption {
        type = lib.types.strMatching "^[A-Za-z0-9_]+$";
        default = "vrf0";
        description = "Name of the vrf to use. May differ from the kernel vrf name.";
      };
      table = lib.mkOption {
        type = with lib.types; nullOr int;
        default = null;
        description = "Kernel routing table number to use.";
      };
    };
  };
}
