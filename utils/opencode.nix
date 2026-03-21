{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      devShells.opencode = pkgs.mkShell {
        packages = [
          inputs.llm-agents.packages.${system}.opencode
        ];
      };
    };
}
