{ config, inputs, ... }:
let
  username = builtins.getEnv "USER";
  homeDirectory = builtins.getEnv "HOME";

  homeModuleNames = [
    "bash"
    "tmux"
    "prompt"
    "neovim"
    "git"
    "gh"
    "pi"
    "codex"
    "claude"
  ];

  missingHomeModules = builtins.filter (
    name: !(builtins.hasAttr name config.flake.homeModules)
  ) homeModuleNames;

  selectedHomeModules =
    if missingHomeModules == [ ] then
      builtins.map (name: config.flake.homeModules.${name}) homeModuleNames
    else
      throw "monarch home module list references missing modules: ${builtins.concatStringsSep ", " missingHomeModules}";

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
      extraSpecialArgs = {
        pkgsUnstable = inputs.nixpkgs-unstable.legacyPackages.${target.system};
      };
      modules = selectedHomeModules ++ [
        ./bash.nix
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
