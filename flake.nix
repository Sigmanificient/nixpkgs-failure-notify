{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
         "aarch64-linux"
      ] (system: function nixpkgs.legacyPackages.${system});
  in {
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        env.CFLAGS = "" /* ensure default configuration */;

        packages = with pkgs; [
          curl
          gcc
          python3
          jq
          gh
        ];
      };
    });

    packages = forAllSystems (pkgs: let
      python-script = name: path:
        pkgs.writers.writePython3Bin name {
          doCheck = false;
        } (builtins.readFile path);

      inherit (pkgs) lib;
    in {
      default = pkgs.symlinkJoin {
         name = "zappy";
         paths = with self.packages.${pkgs.system}; [
          collect
          fast-hydra-parser
          hydra-parser
          create-issues
        ];

        meta.mainProgram = "collect";
      };

      hydra-parser = let
        pyproj = (lib.importTOML ./python_hydra_parser/pyproject.toml).project;
      in pkgs.python3Packages.buildPythonPackage {
        pname = pyproj.name;
        inherit (pyproj) version;
        pyproject = true;
        src = pkgs.lib.cleanSource ./python_hydra_parser;

        build-system = [
          pkgs.python3Packages.uv-build
        ];

        pythonImportsCheck = [ "hydra_parser" ];

        meta = {
          inherit (pyproj) description;
          mainProgram = "hydra-to-csv";
          license = lib.getLicenseFromSpdxId pyproj.license;
        };
      };

      create-issues = python-script "create-issues.py" ./create-issues.py;

      collect = pkgs.writeShellApplication {
        name = "collect.sh";
        text = (builtins.readFile ./collect.sh);
        runtimeInputs = with pkgs; [
          curl
          gcc
          python3
          jq
          self.packages.${system}.fast-hydra-parser
        ];
      };

      fast-hydra-parser = pkgs.callPackage (
        { stdenv, lib }:
        stdenv.mkDerivation {
          pname = "fast-hydra-parser";
          version = "0.0.1";
          src = ./.;

          env.PREFIX = "${placeholder "out"}";
          meta = {
            description = "Parser collecting a hydra jobset overview to CSV";
            maintainers = with lib.maintainers; [ sigmanificient ];
            license = lib.licenses.bsd3;
            mainProgram = "fhp";
          };
        }
      ) {};
    });
  };
}
