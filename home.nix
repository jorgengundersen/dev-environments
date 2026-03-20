{ config, inputs, ... }:
{
  flake.homeConfigurations.default = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
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
}
