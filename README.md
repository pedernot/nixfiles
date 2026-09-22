# nixfiles

## Apple Silicon MacBook bootstrap

This configuration assumes that Nix is installed with flakes enabled and that
`/nix` is available. Home Manager does not need to be installed separately;
the flake exposes the version pinned in `flake.lock`.

```sh
mkdir -p ~/workspace
git clone https://github.com/pedernot/nixfiles.git ~/workspace/nixfiles
cd ~/workspace/nixfiles
nix run .#home-manager -- switch --flake '.#peder@macbook'
```

Subsequent updates use the same command from the repository directory.
