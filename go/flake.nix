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
              (lib.fileset.fileFilter (f: lib.hasSuffix ".go" f.name) ./.)
              ./go.mod
              ./go.sum
            ]);
          };
          package = {
            name = throw "package.name: package name is missing.";
            version = throw "package.version: package version is missing.";
            vendorHash = throw "package.version: vendorHash is missing.";
          };
        in
        {
          packages = {
            ${package.name} = pkgs.buildGoModule {
              pname = package.name;
              inherit (package)
                version
                vendorHash;
              inherit src;
            };
            default = config.packages.${package.name};
          };

          devShells = {
            ${package.name} = pkgs.mkShell {
              inherit (package) name;
              inputsFrom = [ config.packages.${package.name} ];
              packages = with pkgs; [
                gopls
              ];
            };
            default = config.devShells.${package.name};
          };

          treefmt = {
            projectRootFile = "go.mod";
            programs.gofmt.enable = true;
          };
        };
    };
}
