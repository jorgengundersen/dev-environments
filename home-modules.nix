{ lib, ... }:
{
  options.flake.homeModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.raw;
    default = { };
    description = "Home Manager modules exposed by aspect files";
  };
}
