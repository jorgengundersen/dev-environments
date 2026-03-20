_: {
  perSystem =
    { self', pkgs, ... }:
    {
      devShells.minimal = pkgs.mkShell {
        inputsFrom = with self'.devShells; [
          core
          bash
          prompt
        ];
      };
    };
}
