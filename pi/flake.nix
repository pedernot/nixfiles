{
  description = "NixOS flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        nodejs
        pi-coding-agent
        typescript
      ];

      shellHook = ''
        pi_package="${pkgs.pi-coding-agent}/lib/node_modules/pi-monorepo"
        pi_node_modules="$pi_package/node_modules"
        pi_dev_node_modules="$PWD/.direnv/pi-node_modules"

        mkdir -p "$pi_dev_node_modules/@mariozechner" "$pi_dev_node_modules/@types"
        ln -sfn "$pi_package" "$pi_dev_node_modules/@mariozechner/pi-coding-agent"
        ln -sfn "$pi_node_modules/@mariozechner/pi-ai" "$pi_dev_node_modules/@mariozechner/pi-ai"
        ln -sfn "$pi_node_modules/@mariozechner/pi-agent-core" "$pi_dev_node_modules/@mariozechner/pi-agent-core"
        ln -sfn "$pi_node_modules/@mariozechner/pi-tui" "$pi_dev_node_modules/@mariozechner/pi-tui"
        ln -sfn "$pi_node_modules/typebox" "$pi_dev_node_modules/typebox"
        ln -sfn "$pi_node_modules/@types/node" "$pi_dev_node_modules/@types/node"

        if [ -L node_modules ] || [ ! -e node_modules ]; then
          ln -sfn .direnv/pi-node_modules node_modules
        else
          echo "node_modules already exists; leaving it unchanged. Ensure pi extension deps are available for tsc."
        fi
      '';
    };
  };
}
