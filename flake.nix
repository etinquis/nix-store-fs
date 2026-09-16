{
  description = "A Nix-flake-based Go 1.23 development environment";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      goVersion = 23; # Change this to update the whole stack

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ self.overlays.default ];
            };
          }
        );
    in
    {
      overlays.default = final: prev: {
        go = final."go_1_${toString goVersion}";
      };

      packages = forEachSupportedSystem (
        { pkgs }: rec {
          default = nix-store-fs;
          nix-store-fs = pkgs.buildGoModule {
            name = "nix-store-fs";
            src = ./src;
            vendorHash = "sha256-UuiXA+p9LTdOfeXxkZm/ee5iDtehQ9O8Gsecfx9ZXFQ=";
            ldflags = [
              "-s"
              "-w"
            ];
            meta = {
              description = "FUSE filesystem exposing a filtered view of a Nix store scoped to a toplevel closure";
              license = pkgs.lib.licenses.mit;
              mainProgram = "nix-store-fs";
            };
          };
        }
      );

      devShells = forEachSupportedSystem (
        { pkgs }: {
          default = pkgs.mkShell {
            packages = with pkgs; [
              go
              gcc
              fuse
            ];

            hardeningDisable = [ "fortify" ];
          };

        }
      );
    };
}
