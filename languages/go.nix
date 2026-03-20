_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.go = pkgs.mkShell {
        packages = with pkgs; [
          go
          gopls
          golangci-lint
        ];
        shellHook = ''
          export GOPATH="$HOME/go"
          export GOBIN="$HOME/go/bin"
        '';
      };
    };
}
