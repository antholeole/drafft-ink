{
  description = "drafft.ink — collaborative vector drawing app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # Re-export our packages into any flake-parts consumer's perSystem.
      # Closes over our own `inputs` so the consumer doesn't need crane/rust-overlay.
      flake.flakeModules.default = {lib, ...}: {
        perSystem = {system, ...}: {
          packages = lib.optionalAttrs (inputs.self.packages ? ${system})
            inputs.self.packages.${system};
        };
      };

      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
        ./nix/crane.nix
        ./nix/devshell.nix
        ./crates/drafftink-app
        ./crates/drafftink-server
      ];
    };
}
