{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.socket_vmnet;
in
{
  options.services.socket_vmnet = {
    enable = mkEnableOption "socket_vmnet";
    package = mkOption {
      type = types.package;
      default = pkgs.socket_vmnet;
      description = "The socket_vmnet package to use";
    };
    bridgedInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface name for bridged mode. Empty value (default) disables bridged mode.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    security.sudo.extraConfig = ''
      %staff ALL=(ALL) NOPASSWD: ${cfg.package}/bin/socket_vmnet --vmnet-gateway=192.168.105.1 /var/run/socket_vmnet
      ${optionalString (cfg.bridgedInterface != null) ''
        %staff ALL=(ALL) NOPASSWD: ${cfg.package}/bin/socket_vmnet --vmnet-mode=bridged --vmnet-interface=${cfg.bridgedInterface} /var/run/socket_vmnet.bridged.${cfg.bridgedInterface}
      ''}
    '';

    launchd.daemons = mkMerge [
      {
        "io.github.lima-vm.socket_vmnet" = {
          script = ''
            mkdir -p /var/run/socket_vmnet
            mkdir -p /var/log/socket_vmnet
            exec ${cfg.package}/bin/socket_vmnet --vmnet-gateway=192.168.105.1 /var/run/socket_vmnet
          '';
          serviceConfig = {
            KeepAlive = true;
            RunAtLoad = true;
            UserName = "root";
            ProcessType = "Interactive";
            StandardOutPath = "/var/log/socket_vmnet/stdout.log";
            StandardErrorPath = "/var/log/socket_vmnet/stderr.log";
          };
        };
      }
      (mkIf (cfg.bridgedInterface != null) {
        "io.github.lima-vm.socket_vmnet.bridged.${cfg.bridgedInterface}" = {
          script = ''
            mkdir -p /var/run/socket_vmnet
            mkdir -p /var/log/socket_vmnet
            exec ${cfg.package}/bin/socket_vmnet --vmnet-mode=bridged --vmnet-interface=${cfg.bridgedInterface} /var/run/socket_vmnet.bridged.${cfg.bridgedInterface}
          '';
          serviceConfig = {
            KeepAlive = true;
            RunAtLoad = true;
            UserName = "root";
            ProcessType = "Interactive";
            StandardOutPath = "/var/log/socket_vmnet/bridged.${cfg.bridgedInterface}.stdout.log";
            StandardErrorPath = "/var/log/socket_vmnet/bridged.${cfg.bridgedInterface}.stderr.log";
          };
        };
      })
    ];
  };
}