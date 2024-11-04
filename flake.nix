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

          src = ./macchiato;

          patches = [
            # Patch the theme so the company titles show up
            # See PR: https://github.com/biosan/jsonresume-theme-macchiato/pull/22
            (pkgs.fetchpatch {
              url = "https://patch-diff.githubusercontent.com/raw/biosan/jsonresume-theme-macchiato/pull/22.patch";
              hash = "sha256-sq5gOiY35uJF7k0Hxx19VMh1Gn9i2lWAlbNAgqBboHM=";
            })
          ];

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
          name = "resume-html";
          src = ./.; # Adjust if `resume.nix` is in a different directory

          buildInputs = [ pkgs.resumed themePackage jsonResume ];

          buildPhase = ''
            resumed render ${jsonResume}/resume.json --theme ${themePackage}/lib/node_modules/jsonresume-theme-macchiato/index.js --output resume.html
          '';

          installPhase = ''
            mkdir -p $out
            cp resume.html $out/
            ln -s $out/resume.html $out/index.html

            # Copy static files
            cp -R ${themePackage}/lib/node_modules/jsonresume-theme-macchiato/static/* $out/
          '';
        };

        # Print html resume to a PDF
        packages.resume-pdf = let
          htmlResume = self'.packages.resume-html;
        in pkgs.stdenv.mkDerivation {
          name = "resume-pdf";

          unpackPhase = "true";

          buildInputs = [
              htmlResume
              pkgs.puppeteer-cli

              # Fonts
              pkgs.fontconfig
              pkgs.lato
              pkgs.texlivePackages.josefin
          ];

          # Set some env vars to make puppeteer work
          XDG_CONFIG_HOME = "/tmp/.chromium";
          XDG_CACHE_HOME = "/tmp/.chromium";
          FONTCONFIG_PATH = "${pkgs.fontconfig.out}/etc/fonts";

          buildPhase = ''
            ${pkgs.puppeteer-cli}/bin/puppeteer print ${htmlResume}/resume.html resume.pdf --wait-until networkidle0 --margin-top 0 --margin-right 0 --margin-bottom 0 --margin-left 0 --format A4 print
          '';

          installPhase = ''
            mkdir -p $out
            cp resume.pdf $out/
          '';
        };
      };
      flake = {};
    };
}
