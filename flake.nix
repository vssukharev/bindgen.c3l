{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    c3c.url = "github:c3lang/c3c";
    c3c.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, ... } @ inputs: inputs.flake-utils.lib.eachDefaultSystem (system: 
    let 
      pkgs = import inputs.nixpkgs { inherit system; };
      c3c = inputs.c3c.packages.${system}.default;
    in 
    {
      devShells.default = pkgs.callPackage ./shell.nix { inherit c3c; };
    }
  );
}
