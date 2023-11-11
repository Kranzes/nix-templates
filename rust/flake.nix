{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = { url = "github:hercules-ci/flake-parts"; inputs.nixpkgs-lib.follows = "nixpkgs"; };
    treefmt-nix = { url = "github:numtide/treefmt-nix"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ inputs.treefmt-nix.flakeModule ];

      perSystem = { pkgs, lib, config, ... }:
        let
          src = lib.fileset.toSource {
            root = ./.;
            fileset = (lib.fileset.unions [
              (lib.fileset.fileFilter (f: lib.hasSuffix ".rs" f.name) ./.)
              (lib.fileset.fileFilter (f: f.name == "Cargo.toml") ./.)
              ./Cargo.lock
            ]);
          };
          inherit (lib.importTOML (src + "/Cargo.toml")) package;
        in
        {
          packages = {
            ${package.name} = pkgs.rustPlatform.buildRustPackage {
              pname = package.name;
              inherit (package) version;
              inherit src;
              cargoLock.lockFile = (src + "/Cargo.lock");
            };
            default = config.packages.${package.name};
          };

          devShells = {
            ${package.name} = pkgs.mkShell {
              inherit (package) name;
              inputsFrom = [ config.packages.${package.name} ];
              packages = with pkgs; [
                rust-analyzer
              ];
            };
            default = config.devShells.${package.name};
          };

          treefmt = {
            projectRootFile = "Cargo.toml";
            programs.rustfmt.enable = true;
          };
        };
    };
}
