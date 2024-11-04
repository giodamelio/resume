{
  description = "Render cool resumes from a data file";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        packages.theme-macchiato = pkgs.buildNpmPackage rec {
          pname = "jsonresume-theme-macchiato";
          version = "2024-11-4";

          src = pkgs.fetchFromGitHub {
            owner = "biosan";
            repo = pname;
            rev = "c783186d31c88924b7808bf65a892cef233099c4";
            hash = "sha256-ssqZBlVnEtOSldDrEAPsmTxAdGozeABdt98xSXv0Fe0=";
          };

          npmDepsHash = "sha256-yK7Yp2580XiGv1nHmyBnnF7dLlADOP8NWLvuzAMclOo=";
          npmInstallFlags = ["--omit=dev"];
          dontNpmBuild = true;
          PUPPETEER_SKIP_CHROMIUM_DOWNLOAD = 1;
        };

        packages.resume-html = let
          themePackage = self'.packages.theme-macchiato;
        in pkgs.stdenv.mkDerivation {
          name = "resume";
          src = ./.; # Adjust if `resume.nix` is in a different directory

          buildInputs = [ pkgs.resumed pkgs.nix themePackage ];

          buildPhase = ''
            # Convert resume.nix to JSON
            nix eval --raw --impure --expr 'builtins.toJSON (import ./resume.nix)' > resume.json

            # Render the resume to HTML using resumed
            resumed render resume.json --theme ${themePackage}/lib/node_modules/jsonresume-theme-macchiato/index.js --output resume.html
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp resume.html $out/bin/
          '';
        };
      };
      flake = {};
    };
}
