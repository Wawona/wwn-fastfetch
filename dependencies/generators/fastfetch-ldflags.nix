# Link flags for in-process fastfetch on Apple targets.
# Pass nativeDeps with fastfetch from mobile-platform-deps.
{ lib, deps, forceLoad ? true }:

let
  strip = d: if d == null then "" else toString d;
  fastfetch = deps.fastfetch or null;
  libff = if fastfetch != null then "${strip fastfetch}/lib/libfastfetch.a" else "";
in
if forceLoad && fastfetch != null && builtins.pathExists libff then
  [ "-force_load" libff ]
else
  [ ]
