{
  description = "NixOS — unified x86_64 + Apple Silicon (aarch64/Asahi)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Apple Silicon (Asahi) support — used by the macbook host only.
    nixMac.url = "github:nix-community/nixos-apple-silicon";

    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim.url = "github:nix-community/nixvim";
    minegrub-world-sel-theme.url = "github:Lxtharia/minegrub-world-sel-theme";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, ... } @ inputs: let
    mkHost = {
      host,
      profile,
      username ? "oblivion",
      system ? "x86_64-linux",
      extraModules ? [ ],
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username host profile; };
        modules = [ ./profiles/${profile} ] ++ extraModules;
      };
  in {
    nixosConfigurations = {
      amd = mkHost { host = "amd"; profile = "amd"; };
      nvidia = mkHost { host = "nvidia"; profile = "nvidia"; };
      intel = mkHost { host = "intel"; profile = "intel"; };
      vm = mkHost { host = "vm"; profile = "vm"; };
      nvidia-laptop = mkHost { host = "nvidia-laptop"; profile = "nvidia-laptop"; };
      homedepot = mkHost { host = "homedepot"; profile = "homedepot"; username = "jakob"; };

      macbook = mkHost {
        host = "macbook";
        profile = "macbook";
        system = "aarch64-linux";
        extraModules = [ inputs.nixMac.nixosModules.apple-silicon-support ];
      };
    };
  };
}
