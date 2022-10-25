{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dart-flutter = {
      url = "github:flafydev/dart-flutter-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, dart-flutter }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ dart-flutter.overlays.default ];
          };
        in
        {
          devShell = pkgs.mkFlutterShell {
            android = {
              enable = true;
              buildToolsVersions = [ "29-0-2" ];
              platformsAndroidVersions = [ "32" ];
            };
          };
        }) // { };
}
