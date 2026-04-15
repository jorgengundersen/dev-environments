_:
let
  profiles = builtins.fromJSON (builtins.readFile ./profiles.json);
in
{
  perSystem =
    { self', pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        inputsFrom = builtins.map (name: self'.devShells.${name}) profiles.default;
      };
    };
}
