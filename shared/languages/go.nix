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

  flake.homeModules.go = _: {
    home.sessionVariables = {
      GOPATH = "$HOME/go";
      GOBIN = "$HOME/go/bin";
    };
    home.sessionPath = [ "$HOME/go/bin" ];
  };
}
