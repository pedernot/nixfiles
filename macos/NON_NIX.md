# Non-Nix macOS fallback

This fallback is for an Apple Silicon Mac where `/nix` cannot exist. It does
not replace or modify the Nix Home Manager configuration.

## Bootstrap

Install Homebrew, clone this repository to `~/workspace/nixfiles`, and run:

```sh
./macos/bootstrap
```

The bootstrap installs `macos/Brewfile` without upgrading packages already
installed by Homebrew. It then creates symlinks for the portable Zsh, tmux,
Git, Jujutsu, and Neovim configuration. Existing non-symlink files are never
overwritten.

Neovim uses the conventional Lua configuration in `nvim/`, with lazy.nvim and
the committed `nvim/lazy-lock.json`. Plugins are downloaded on first launch.
The configuration mirrors the main NVF setup, but is independent of Nix so it
can also be tested on Linux with a recent Neovim.

The Git configuration delegates GitHub credentials to `gh`. Run `gh auth
login` once on the Mac before using authenticated GitHub remotes. The Git and
Jujutsu identity and signing-key ID are configured, but the private GPG key is
not provisioned by this repository.

## Deliberate gaps

- These Home Manager-managed tmux plugins are not ported:
  - `tmux-thumbs`, including its custom alphabet and colors.
  - `tmux-fzf`, including its `w` binding for `choose-tree -Z`.
- Other Home Manager-managed terminal application settings, themes,
  completions, and services are not yet represented.
- Secrets and private keys are intentionally not provisioned.
