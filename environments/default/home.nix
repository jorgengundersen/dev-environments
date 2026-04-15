{ config, inputs, ... }:
let
  mkHome =
    system:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      modules = builtins.attrValues config.flake.homeModules ++ [
        {
          home = {
            username = "devuser";
            homeDirectory = "/home/devuser";
            stateVersion = "24.11";
          };
        }
      ];
    };
in
{
  flake.homeConfigurations = {
    default = mkHome "x86_64-linux";
    "devuser@aarch64" = mkHome "aarch64-linux";
  };
}
