_: {
  perSystem =
    { self', pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        inputsFrom = builtins.attrValues (
          builtins.removeAttrs self'.devShells [
            "default"
            "minimal"
          ]
        );
      };
    };
}
