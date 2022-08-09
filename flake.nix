{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NANASHI0X74/nixpkgs/043de04db8a6b0391b3fefaaade160514d866946";
  # inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [ pkgs.bashInteractive ];
        buildInputs = with pkgs; [
          flutter
          jdk11
        ];
      };
    });
}
