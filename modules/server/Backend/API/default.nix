{ lib, buildDotnetModule, dotnetCorePackages, ffmpeg }:

let
in buildDotnetModule rec {
  pname = "HomeDepotBackend";
  version = "0.1";

  src = ./.;

  projectFile = "./API.csproj";
  # File generated with `nix-build -A package.passthru.fetch-deps`.
  # To run fetch-deps when this file does not yet exist, set nugetDeps to null
  nugetDeps = ./deps.nix;

  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_8_0;

  executables = [ "API" ]; # This wraps "$out/lib/$pname/foo" to `$out/bin/foo`.

  packNupkg = true; # This packs the project as "foo-0.1.nupkg" at `$out/share`.
  runtimeDeps =
    [ ffmpeg ]; # This will wrap ffmpeg's library path into `LD_LIBRARY_PATH`.
}
