{
  nixConfig = {
    substituters = [
      "https://cache.nixos.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  inputs = {
    flake-commons.url = "github:nxmatic/nix-flake-commons/develop";
    flake-compat.follows = "flake-commons/flake-compat";
    nixpkgs.follows = "flake-commons/nixpkgs";
    nvfetcher.follows = "flake-commons/nvfetcher";
    utils.follows = "flake-commons/flake-utils";
  };

  outputs = { self, nixpkgs, flake-commons,flake-compat, nvfetcher, utils }:
    let
      darwinModule = import ./darwin-module.nix;      
    in utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        nvfetcherBin = nvfetcher.packages.${system}.default;

        generateSources = pkgs.writeShellScriptBin "generate-sources" ''
        ${nvfetcherBin}/bin/nvfetcher -c ${./nvfetcher.toml} -o .nvfetcher
      '';

        sources = import ./.nvfetcher/generated.nix { 
          inherit (pkgs) fetchgit fetchurl fetchFromGitHub;
          dockerTools = pkgs.dockerTools or {};
        };

        socket_vmnet = pkgs.callPackage ./package.nix { 
          inherit sources;
        };

      in
        {
          packages = {
            default = socket_vmnet;
            socket_vmnet = socket_vmnet;
            updateSources = generateSources;
          };

          devShell = pkgs.mkShell {
            buildInputs = with pkgs; [
            ];
          };

          darwinModules = {
            default = darwinModule;
            socket_vmnet = darwinModule;
          };

        }
    ) // {
      darwinModules = {
        default = import ./darwin-module.nix;
        socket_vmnet = import ./darwin-module.nix;
      };
    };
}
