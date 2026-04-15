{ config, inputs, ... }:
let
  username = builtins.getEnv "USER";
  homeDirectory = builtins.getEnv "HOME";

  homeTargets =
    if username != "" && homeDirectory != "" then
      [
        {
          name = "default";
          system = "x86_64-linux";
          inherit username homeDirectory;
        }
        {
          name = "${username}@aarch64";
          system = "aarch64-linux";
          inherit username homeDirectory;
        }
      ]
    else
      [ ];

  mkHome =
    target:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${target.system};
      modules = builtins.attrValues config.flake.homeModules ++ [
        {
          home = {
            inherit (target) username homeDirectory;
            stateVersion = "24.11";
          };
        }
      ];
    };
in
{
  flake.homeConfigurations = builtins.listToAttrs (
    builtins.map (target: {
      inherit (target) name;
      value = mkHome target;
    }) homeTargets
  );
}
