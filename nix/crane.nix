{inputs, ...}: {
  perSystem = {system, ...}: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [inputs.rust-overlay.overlays.default];
    };

    rustToolchain = pkgs.rust-bin.stable.latest.default.override {
      targets = ["wasm32-unknown-unknown"];
    };

    craneLib = (inputs.crane.mkLib pkgs).overrideToolchain rustToolchain;

    src = inputs.self;

    commonArgs = {
      inherit src;
      pname = "drafftink";
      version = "0.1.1";

      strictDeps = true;

      nativeBuildInputs = with pkgs; [pkg-config];

      buildInputs =
        (with pkgs; [openssl])
        ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
          pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
        ];
    };

    cargoArtifacts = craneLib.buildDepsOnly commonArgs;
  in {
    _module.args = {
      inherit craneLib rustToolchain commonArgs cargoArtifacts;
    };
  };
}
