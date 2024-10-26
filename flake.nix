{
  description = "NixCon 2024 - NixOS on garnix: Production-grade hosting as a game!";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.garnix-lib = {
    url = "github:garnix-io/garnix-lib";
    inputs = {
      nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, garnix-lib, flake-utils }:
    let
      system = "x86_64-linux";
    in
    (flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let pkgs = import nixpkgs { inherit system; };
      in rec {
        packages = {
          webserver = pkgs.writers.writePython3
            "webserver"
            {
              libraries = [ pkgs.python3Packages.fastapi pkgs.python3Packages.uvicorn ];
              flakeIgnore = [ "E265" "E225" "E302" ];
            }
            (builtins.readFile ./webserver.py);
          default = packages.webserver;
        };
        apps.default = {
          type = "app";
          program = pkgs.lib.getExe (
            pkgs.writeShellApplication {
              name = "start-webserver";
              runtimeEnv = {
                PORT = "8080";
              };
              text = ''
                ${pkgs.lib.getExe packages.webserver}
              '';
            }
          );
        };
      }))
    //
    {
      nixosConfigurations.server = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          garnix-lib.nixosModules.garnix
          self.nixosModules.nixcon-garnix-player-module
          ({ pkgs, ... }: {
            playerConfig = {
              # Your github user:
              githubLogin = "jheidbrink";
              # You only need to change this if you changed the forked repo name.
              githubRepo = "nixcon-2024-player-template";
              # The nix derivation that will be used as the server process. It
              # should open a webserver on port 8080.
              # The port is also provided to the process as the environment variable "PORT".
              webserver = self.packages.${system}.webserver;
              # If you want to log in to your deployed server, put your SSH key
              # here:
              sshKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFjhXJi527umYatwTlRk9IIfQgAOh4uZTtEaAM9nm721gytxV+GEJPhzsIStFXLC7A4p1dpjzAxXTazUX30NuQZJYSxRcEaRwfW0uyNFqGhrY2KH5ccy7iUgKuS8IzMo/epiNP1560SJ+gyvsLdUJnD8u6ufOUGXw/IImyhkFQf84/fqzGlO4Z6OlMxRlxb68hXJsNiFXQiAHlvvdMkRTOmNRta0ha1mybV/U0Yv8xcoy4XIpJ+2zAKbiFrySz+RE1AOe2kj84+gzinxh2hDPtFJ5oNg1jjgeB1rWOpTbSspCyl2VzP/kIoUoRp9KWDgUGdJvPDYDDHPwuOh1ksouOFLy2lDPjfxvNfNmz8YHqFuNY1JO3rYRTN4f++BDsY9PVQxWLZmi2/LBPqdLqPNxfBYylWGdhez1/f7fDK4rHqAY/Fc6QeYagpd9e9PTadUk9ZWxm1Ip7h1UQNzDbwYNmTBWA0k1QP+Gc4a3U2zx8lazAXwIF8DTQFxrnREWbGA8=";
            };
          })
        ];
      };

      nixosModules.nixcon-garnix-player-module = ./nixcon-garnix-player-module.nix;
      nixosModules.default = self.nixosModules.nixcon-garnix-player-module;

      # Remove before starting the workshop - this is just for development
      checks = import ./checks.nix { inherit nixpkgs self; };
    };
}
