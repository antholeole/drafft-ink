{...}: {
  perSystem = {
    pkgs,
    rustToolchain,
    ...
  }: let
    dev = pkgs.writeShellScriptBin "dev" ''
      # warn for deps; debug for our crates only (env_logger matches on :: separators, not _)
      export RUST_LOG=warn,drafftink=debug,drafftink_app=debug,drafftink_core=debug,drafftink_server=debug,drafftink_render=debug,drafftink_widgets=debug
      subcmd="$1"; shift
      case "$subcmd" in
        wayland)
          if [ $# -gt 0 ]; then
            cargo watch -x "run -p drafftink-app -- $*"
          else
            cargo watch -x "run -p drafftink-app"
          fi
          ;;
        server)
          if [ $# -gt 0 ]; then
            cargo watch -x "run -p drafftink-server -- $*"
          else
            cargo watch -x "run -p drafftink-server"
          fi
          ;;
        *)
          echo "Usage: dev <wayland|server> [args...]"
          exit 1
          ;;
      esac
    '';

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
    devShells.default = pkgs.mkShell {
      nativeBuildInputs = with pkgs; [
        rustToolchain
        pkg-config
        cargo-watch
        dev
      ];

      buildInputs =
        (with pkgs; [openssl])
        ++ pkgs.lib.optionals pkgs.stdenv.isLinux waylandLibs;

      LD_LIBRARY_PATH = pkgs.lib.optionalString pkgs.stdenv.isLinux (
        pkgs.lib.makeLibraryPath waylandLibs
      );
    };
  };
}
