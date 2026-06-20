{...}: {
  perSystem = {
    config,
    pkgs,
    craneLib,
    rustToolchain,
    commonArgs,
    cargoArtifacts,
    ...
  }: let
    vendoredDeps = craneLib.vendorCargoDeps {inherit (commonArgs) src;};

    waylandLibs = with pkgs; [
      wayland
      libxkbcommon
      vulkan-loader
      libGL
      libx11
      libxcursor
      libxi
      libxrandr
    ];
  in {
    overlayAttrs =
      {inherit (config.packages) drafftink-wasm;}
      // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
        inherit (config.packages) drafftink-desktop-wayland;
      };
    packages =
      pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
        drafftink-desktop-wayland = let
          unwrapped = craneLib.buildPackage (commonArgs
            // {
              inherit cargoArtifacts;
              cargoExtraArgs = "-p drafftink-app";
            });
          wrapped = pkgs.runCommand "drafftink-desktop-wayland-bin" {
            nativeBuildInputs = [pkgs.makeWrapper];
          } ''
            mkdir -p $out/bin
            makeWrapper ${unwrapped}/bin/drafftink $out/bin/drafftink \
              --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath waylandLibs}
          '';
          desktopItem = pkgs.makeDesktopItem {
            name = "drafftink";
            exec = "drafftink";
            desktopName = "Drafft Ink";
            categories = ["Graphics"];
          };
        in
          pkgs.symlinkJoin {
            name = "drafftink-desktop-wayland";
            paths = [wrapped desktopItem];
          };
      }
      // {
        drafftink-wasm = pkgs.stdenvNoCC.mkDerivation {
          name = "drafftink-wasm-build";
          inherit (commonArgs) src;

          nativeBuildInputs = [
            rustToolchain
            pkgs.wasm-bindgen-cli_0_2_121
            pkgs.binaryen
            pkgs.pkg-config
            pkgs.openssl
          ];

          buildPhase = ''
            export HOME=$(mktemp -d)
            export CARGO_HOME=$HOME/.cargo
            mkdir -p $CARGO_HOME

            mkdir -p .cargo
            cat ${vendoredDeps}/config.toml >> .cargo/config.toml

            cargo build --release -p drafftink-app --target wasm32-unknown-unknown --no-default-features

            mkdir -p pkg
            wasm-bindgen \
              --target web \
              --out-dir pkg \
              --out-name drafftink_app \
              target/wasm32-unknown-unknown/release/drafftink_app.wasm

            wasm-opt -Oz -o pkg/drafftink_app_bg.wasm pkg/drafftink_app_bg.wasm || true
          '';

          installPhase = ''
            mkdir -p $out
            cp -r web/* $out/
            cp -r pkg $out/
          '';
        };
      };
  };
}
