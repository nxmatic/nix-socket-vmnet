{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.socket_vmnet;
  dataDir = cfg.dataDir;
  lanInterface = cfg.lanInterface;
  wanGateway = cfg.wanGateway;
  wanSubnet = cfg.wanSubnet;
in
{
  options.services.socket_vmnet = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable both custom socket_vmnet daemons (LAN and WAN).";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/run/socket_vmnet";
      description = "Directory for socket_vmnet sockets and logs.";
    };
    lanInterface = mkOption {
      type = types.str;
      default = "en0";
      description = "Network interface to bridge for LAN mode.";
    };
    wanGateway = mkOption {
      type = types.str;
      default = "10.80.16.1";
      description = "Gateway IP for WAN shared mode.";
    };
    wanSubnet = mkOption {
      type = types.str;
      default = "10.80.16.0/24";
      description = "Subnet for WAN shared mode.";
    };
  };

  config = mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    launchd.daemons = {
      "com.nxmatic.socket-vmnet-lan" = {
        serviceConfig = {
          Label = "com.nxmatic.socket-vmnet-lan";
          ProgramArguments = [
            "/opt/socket_vmnet/bin/socket_vmnet"
            "--vmnet-mode=bridged"
            "--vmnet-interface=${cfg.lanInterface}"
            "--socket-group=admin"
            "${cfg.dataDir}/lan.sock"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "${cfg.dataDir}/socket_vmnet_lan.log";
          StandardErrorPath = "${cfg.dataDir}/socket_vmnet_lan_error.log";
          UserName = "root";
        };
      };
      "com.nxmatic.socket-vmnet-wan" = {
        serviceConfig = {
          Label = "com.nxmatic.socket-vmnet-wan";
          ProgramArguments = [
            "/opt/socket_vmnet/bin/socket_vmnet"
            "--vmnet-mode=shared"
            "--vmnet-gateway=${cfg.wanGateway}"
            "--vmnet-dhcp-end=10.80.16.254"
            "--vmnet-mask=255.255.255.0"
            "--socket-group=admin"
            "${cfg.dataDir}/wan.sock"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "${cfg.dataDir}/socket_vmnet_wan.log";
          StandardErrorPath = "${cfg.dataDir}/socket_vmnet_wan_error.log";
          UserName = "root";
        };
      };
    };

    system.activationScripts.socket-vmnet-setup.text =
      let
        socket_vmnet_pkg = pkgs.socket_vmnet or (throw "socket_vmnet package not found in pkgs");
      in ''
        : "Setting up custom socket_vmnet services..."
        mkdir -p /opt/socket_vmnet
        rsync -av --delete "${socket_vmnet_pkg}/" /opt/socket_vmnet/
        mkdir -p "${cfg.dataDir}"
        chmod 755 "${cfg.dataDir}"
        # If you really need ownership change, reference a stable user:
        # chown root:wheel "${cfg.dataDir}"
        touch "${cfg.dataDir}/socket_vmnet_lan.log" \
              "${cfg.dataDir}/socket_vmnet_wan.log" \
              "${cfg.dataDir}/socket_vmnet_lan_error.log" \
              "${cfg.dataDir}/socket_vmnet_wan_error.log"
        chmod 644 "${cfg.dataDir}/socket_vmnet"*.log
      '';
  };
}