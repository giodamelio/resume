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
        # Package the macchiato resume theme
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

        # Conver the resume.nix to pretty printed JSON
        packages.resume-json = pkgs.stdenv.mkDerivation {
          name = "resume-json";
          unpackPhase = "true";
          buildPhase = ''
            ${pkgs.jq}/bin/jq > resume.json <<EOF
            ${builtins.toJSON (import ./resume.nix)}
            EOF
          '';
          installPhase = ''
            mkdir -p $out
            mv resume.json $out/
          '';
        };

        # Render my resume to html with resumed
        packages.resume-html = let
          themePackage = self'.packages.theme-macchiato;
          jsonResume = self'.packages.resume-json;
        in pkgs.stdenv.mkDerivation {
          name = "resume";
          src = ./.; # Adjust if `resume.nix` is in a different directory

          buildInputs = [ pkgs.resumed themePackage jsonResume ];

          buildPhase = ''
            resumed render ${jsonResume}/resume.json --theme ${themePackage}/lib/node_modules/jsonresume-theme-macchiato/index.js --output resume.html
          '';

          installPhase = ''
            mkdir -p $out
            cp resume.html $out/
            ln -s $out/resume.html $out/index.html
          '';
        };
      };
      flake = {};
    };
}
