_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      devShells.linters = pkgs.mkShell {
        packages =
          with pkgs;
          [
            shellcheck
            mdformat
            lefthook
            bats
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            hadolint
          ];
      };
    };
}
