_: {
  perSystem =
    { pkgs, lib, ... }:
    let
      playwright-cli = pkgs.writeShellScriptBin "playwright-cli" ''
        exec ${pkgs.nodejs}/bin/npx --yes @playwright/cli@latest "$@"
      '';
    in
    {
      devShells.playwright = pkgs.mkShell {
        packages =
          with pkgs;
          [
            nodejs
            playwright-cli
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ chromium ];
      };
    };
}
