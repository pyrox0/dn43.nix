{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  cfg = config.dn42.wg;

  tunnelDef = {
    options = {
      enable = lib.mkOption {
        description = "Whether to enable this wireguard tunnel";
        type = types.bool;
        default = true;
        example = false;
      };
      listenPort = lib.mkOption {
        description = "The port this tunnel listens on";
        type = types.port;
        example = 42000;
      };
      privateKeyFile = lib.mkOption {
        description = "Path to the tunnel's private key";
        type = types.nullOr types.path;
        example = "/path/to/private/key";
        default = null;
      };
      peerPubKey = lib.mkOption {
        description = "Public key of the peer you're connecting to";
        type = types.str;
        example = "e6kp9sca4XIzncKa9GEQwyOnMjje299Xg9ZdgXWMwHg=";
      };
      peerEndpoint = lib.mkOption {
        description = "The endpoint of the peer you're connecting to";
        type = types.str;
        example = "example.com:42000";
      };
      peerAddrs = {
        v4 = lib.mkOption {
          description = "The peer IPv4 address to connect to in the tunnel";
          type = types.nullOr types.str;
          example = "192.168.1.1";
          default = null;
        };
        v6 = lib.mkOption {
          description = "The peer IPv6 address to connect to in the tunnel";
          type = types.nullOr types.str;
          example = "fe80::42";
          default = null;
        };
      };
      localAddrs = {
        v4 = lib.mkOption {
          description = "The local IPv4 address to listen on in the tunnel";
          type = types.nullOr types.str;
          example = "192.168.1.1";
          default = null;
        };
        v6 = lib.mkOption {
          description = "The local IPv6 address to listen on in the tunnel";
          type = types.nullOr types.str;
          example = "fe80::42";
          default = null;
        };
      };
    };
  };
in
{
  options.dn42.wg = {
    tunnelDefaults = lib.mkOption {
      description = "The default settings to apply to all tunnels";
      type = types.submodule tunnelDef;
    };
    tunnels = lib.mkOption {
      description = "DN42 WireGuard tunnels configuration";
      type = types.attrsOf (types.submodule tunnelDef);
      default = { };
    };
    configureFirewall = lib.mkEnableOption "Firewall rules for DN42 tunnels";
  };
  config.networking = {
    wireguard.interfaces = lib.optionalAttrs (cfg.tunnels != { }) (lib.mapAttrs' (
      name: value:
      let
        # Merge defaults with tunnel config, right side has priority
        # so tunnel config overrides defaults
        fc = cfg.tunnelDefaults // (lib.filterAttrs (_: v: v != null) value);
      in
      lib.nameValuePair "wg42_${name}" {
        inherit (fc) listenPort privateKeyFile;
        allowedIPsAsRoutes = false;
        peers = [
          {
            endpoint = fc.peerEndpoint;
            publicKey = fc.peerPubKey;
            allowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];
            dynamicEndpointRefreshSeconds = 5;
            persistentKeepalive = 15;
          }
        ];
        postSetup = ''
          ${lib.optionalString (
            fc.peerAddrs.v4 != null && fc.localAddrs.v4 != null
          ) "${pkgs.iproute2}/bin/ip addr add ${fc.localAddrs.v4} peer ${fc.peerAddrs.v4} dev wg42_${name}"}
          ${lib.optionalString (
            fc.peerAddrs.v6 != null && fc.localAddrs.v6 != null
          ) "${pkgs.iproute2}/bin/ip addr add ${fc.localAddrs.v6} peer ${fc.peerAddrs.v6} dev wg42_${name}"}
        '';
      }
    ) (lib.filterAttrs (_: v: v.enable) cfg.tunnels));
    firewall = lib.mkIf cfg.configureFirewall {
      trustedInterfaces = lib.mapAttrsToList (name: _: "wg42_" + name) (lib.filterAttrs (_: v: v.enable) cfg.tunnels);
      checkReversePath = false;
      extraInputRules = ''
        ip saddr 172.20.0.0/14 accept
        ip6 saddr fd00::/8 accept
        ip6 saddr fe80::/64 accept
      '';
    };
  };
}
