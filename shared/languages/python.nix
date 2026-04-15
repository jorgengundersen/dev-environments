_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.python = pkgs.mkShell {
        packages = with pkgs; [
          python3
          uv
        ];
      };
    };
}
