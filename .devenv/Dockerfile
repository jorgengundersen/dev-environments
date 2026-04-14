# Project-specific Development Environment
# Extends the base devenv with Nix linting tools

FROM devenv:latest

USER root

RUN nix profile install \
    nixpkgs#nixfmt-rfc-style \
    nixpkgs#statix \
    nixpkgs#deadnix \
    && nix-collect-garbage -d

WORKDIR /home/devuser

USER devuser

CMD ["/bin/bash"]
