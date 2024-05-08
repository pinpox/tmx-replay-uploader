{
  description = "Trackmania record uploader";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let

      # System types to support.
      supportedSystems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        });
    in
    {

      # A Nixpkgs overlay.
      overlays.default = final: prev: {
        tm-uploader = with final;
          stdenv.mkDerivation {
            name = "tm-uploader";
            unpackPhase = ":";
            src = lib.sources.sourceFilesBySuffices ./. [ ".html" ".css" ".js" ".ico" ];
            installPhase = "cp -r $src $out";
          };
      };

      # Package
      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) tm-uploader;
        default = self.packages.${system}.tm-uploader;
      });

      # Nixos module
      nixosModules.tm-uploader = { pkgs, lib, config, ... }:
        with lib;
        let cfg = config.services.tm-uploader;
        in {

          # Options for configuration. TODO add host and port
          options.services.tm-uploader.enable = mkEnableOption "tm-uploader page";

          config = mkIf cfg.enable {
            nixpkgs.overlays = [ self.overlays.default ];




            services.caddy = {

              enable = true;
              virtualHosts = {

                "tm.0cx.de".extraConfig = ''
                  root * ${pkgs.tm-uploader}

                  file_server
                  encode zstd gzip

                  log {
                    level DEBUG
                  }

                  @options {
                      method OPTIONS
                  }

                  header {
                      Access-Control-Allow-Origin "{http.request.header.Origin}"
                      Access-Control-Allow-Credentials true
                      Access-Control-Allow-Methods *
                      Access-Control-Allow-Headers *
                      defer
                  }

                  reverse_proxy https://trackmania.exchange:443 {
                      header_down -Access-Control-Allow-Origin
                      header_down -Access-Control-Allow-Headers
                      header_down -Access-Control-Allow-Credentials
                      header_down +Access-Control-Allow-Credentials true
                      header_up -Host
                      header_up +Host trackmania.exchange
                  }

                  respond @options 204
                '';
              };
            };

            # services.nginx = {
            #   enable = true;
            #   virtualHosts."server" = {
            #     root = pkgs.tm-uploader;
            #   };
            # };
          };
        };


      # Tests run by 'nix flake check' and by Hydra.
      checks = forAllSystems
        (system:
          with nixpkgsFor.${system};


          lib.optionalAttrs stdenv.isLinux {
            # A VM test of the NixOS module.
            vmTest =
              with import (nixpkgs + "/nixos/lib/testing-python.nix")
                {
                  inherit system;
                };

              (makeTest {
                name = "tm-uploader-test";
                nodes = {
                  server = {
                    imports = [ self.nixosModules.tm-uploader ];

                    services.tm-uploader.enable = true;

                    networking.firewall = {
                      enable = true;
                      allowPing = true;
                      allowedTCPPorts = [ 80 ];
                    };
                  };
                  client = { };
                };

                testScript =
                  ''
                    start_all()
                    client.wait_for_unit("multi-user.target")
                    server.wait_for_unit("multi-user.target")
                    server.wait_for_open_port(80)
                    client.succeed("curl -sSfL http://server:80", timeout=5)
                  '';
              }).test;
          }
        );
    };
}
