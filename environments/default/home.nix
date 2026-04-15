{ config, inputs, ... }:
let
  homeTargets = [
    {
      name = "default";
      system = "x86_64-linux";
      username = "devuser";
      homeDirectory = "/home/devuser";
    }
    {
      name = "devuser@aarch64";
      system = "aarch64-linux";
      username = "devuser";
      homeDirectory = "/home/devuser";
    }
  ];

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
