{
  description = "FUSE filesystem exposing a filtered view of a Nix store scoped to a toplevel closure";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
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
            };
          }
        );
    in
    {
      overlays = {
        default = final: prev: {
          nix-store-fs = self.packages.${final.stdenv.hostPlatform.system}.nix-store-fs;
        };
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
