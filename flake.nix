{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    { self, ... }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};

        devInputs = with pkgs; [
          d2
          docker-client
          glab
          go-migrate
          go-task
          go-tools
          go_1_24
          golangci-lint
        ];

        devEnv = with pkgs; mkShell { buildInputs = devInputs; };

        treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs (
          { pkgs, ... }:
          {
            projectRootFile = "flake.nix";

            programs = {
              golines.enable = true;
              nixfmt.enable = true;
              # prettier.enable = true;
              # templ.enable = true;
              # shfmt.enable = true;
            };

            settings = {
              global.excludes = [ "vendor/*" ];

              # formatter = {
              #   golines = {
              #     options = [
              #       "--base-formatter=${pkgs.gofumpt}/bin/gofumpt"
              #     ];
              #   };
              #
              #   prettier = {
              #     excludes = [
              #       "assets/ui/*"
              #       "deployments/nix/modules/monitoring/grafana-dashboards/*"
              #     ];
              #   };
              # };
            };
          }
        );
      in
      {
        devShells = {
          default = devEnv;
        };

        checks = {
          formatting = treefmtEval.config.build.check self;
        };
        formatter = treefmtEval.config.build.wrapper;

      }
    );
}
