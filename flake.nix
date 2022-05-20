{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, flake-utils, nixpkgs }:
    let
      supportedSystems = [
        "aarch64-linux"
        "aarch64-darwin"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      inherit (flake-utils) lib;
    in
    lib.eachSystem supportedSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        go = pkgs.go_1_18;
        name = "ipfs-cluster";
        project = pkgs.buildGoPackage rec {
          inherit system name;
          goPackagePath = "github.com/ipfs/ipfs-cluster";
          goDeps = ./deps.nix;
          buildInputs = with pkgs; [ ];
          src = ./.;
        };
        buildInputs = with pkgs; [
        ];
        dockerImage = with pkgs; dockerTools.buildLayeredImage {
          name = "docker.io/decarbonify/nix-ipfs-cluster";
          tag = "latest";
          contents = buildInputs ++ [
            bash
            coreutils
            cacert
            project
          ];
          fakeRootCommands = ''
            mkdir usr
            ln -sf /bin usr/bin
            ln -sf /bin usr/sbin
          '';
          config = {
            Env = [
              "PATH=/bin:/usr/bin:${bash}/bin:${coreutils}/bin"
            ];
            Cmd = [ "sh" ];
          };
        };
      in
      {
        packages = {
          inherit project dockerImage;
        };

        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            vgo2nix
            go
          ];
        };
      });
}
