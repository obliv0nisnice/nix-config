#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nuget-to-nix dotnet-sdk_8
dotnet restore --packages out
nuget-to-nix out > deps.nix
