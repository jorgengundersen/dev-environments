{ lib, ... }:
{
  options.flake.homeModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = { };
    description = "Home Manager modules exposed by shared modules";
  };
}
