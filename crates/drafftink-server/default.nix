{...}: {
  perSystem = {
    config,
    craneLib,
    commonArgs,
    cargoArtifacts,
    ...
  }: {
    overlayAttrs = {
      inherit (config.packages) drafftink-server;
    };

    packages.drafftink-server = craneLib.buildPackage (commonArgs
      // {
        inherit cargoArtifacts;
        cargoExtraArgs = "-p drafftink-server";
      });
  };
}
