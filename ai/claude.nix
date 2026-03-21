{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      devShells.claude = pkgs.mkShell {
        packages = [
          inputs.llm-agents.packages.${system}.claude-code
        ];
      };
    };
}
