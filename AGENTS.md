# AGENTS.md - AI Agent Instructions

NixOS/Home Manager dotfiles repository using Nix flakes for declarative system configuration.

## Project Structure

- `flake.nix` - Main flake (defines `lapping` work laptop and `nixos` personal laptop configs)
- `common/` - Shared home-manager modules (packages.nix, programs.nix, terminal.nix, etc.)
- `common/email.nix` - Shared email stack (accounts.email, mbsync, msmtp, notmuch, neomutt)
- `lapping/` - Work laptop configuration
- `nixos/` - Personal laptop configuration
- `nvim/` - Neovim config (Lua): `init.lua`, `lua/config/`, `lua/plugins/`
- `zsh/` - Zsh configuration files
- `common/scripts.nix` - Custom script wrappers packaged via Nix
- `THEMING.md` - Stylix ownership and theming workflow
- `EMAIL.md` - Mail stack ownership and generated config layout
- `skills/` - AI agent skills documentation

## Build/Deploy Commands

```bash
# Update flake inputs
nix flake update

# Rebuild NixOS system configuration
sudo nixos-rebuild switch --flake .#lapping   # work laptop
sudo nixos-rebuild switch --flake .#nixos     # personal laptop

# Rebuild home-manager only (faster)
home-manager switch --flake .#peder@lapping
home-manager switch --flake .#peder@nixos

# Check flake for errors without building
nix flake check

# Build without switching (for testing)
nixos-rebuild build --flake .#lapping
```

Important: NEVER run nixos-rebuild

## Formatting and Linting

### Formatters (format-on-save enabled in Neovim)

| Language | Formatter | Command |
|----------|-----------|---------|
| Nix | alejandra | `alejandra <file.nix>` |
| Lua | stylua | `stylua <file.lua>` |
| Python | ruff | `ruff format <file.py>` |

### Linters

| Language | Linter | Purpose |
|----------|--------|---------|
| Nix | statix | Static analysis for Nix |
| Dockerfile | hadolint | Dockerfile linting |
| Shell | shellcheck | Shell script analysis |

### Format All Files

```bash
fd -e nix -x alejandra {}   # Format all Nix files
fd -e lua -x stylua {}      # Format all Lua files
statix check .              # Check Nix files with statix
```

### Pi Extension Verification

When editing TypeScript pi extensions in `extensions/`, use both checks:

```bash
# Type-check extensions without emitting JavaScript
# If this config is missing, add/maintain it rather than relying only on smoke tests.
tsc --noEmit -p tsconfig.pi-extensions.json

# Smoke-test that pi can load each extension through its runtime loader
for f in extensions/*.ts; do
  PI_OFFLINE=1 pi --no-extensions -e "$f" --list-models __pi_ext_smoke__ >/dev/null
done
```

The `tsc` check catches TypeScript errors; the pi smoke test catches runtime loader/import/factory errors without making a model call.

## Code Style Guidelines

### Nix Files

**Module Parameters**: Use destructured parameters with ellipsis:
```nix
{ pkgs, lib, config, ... }:
```

**Imports**: Declare at top of module, use relative paths:
```nix
imports = [
  ./packages.nix
  ./programs.nix
];
```

**Naming**:
- Module files: lowercase with hyphens (e.g., `version_control.nix`)
- Attribute names: camelCase for options, kebab-case for package names

**Indentation**: 2 spaces (enforced by alejandra)

**State Versions**: Keep `stateVersion` unchanged once set (currently `"24.11"` for home-manager)

### Lua Files (Neovim config)

**Plugin Manager**: lazy.nvim - plugins go in `nvim/lua/plugins/`

**Structure**:
- Return a table of plugin specs from plugin files
- Config functions use `config = function() ... end`

**Formatting**: 2-space indentation (enforced by stylua)

**Keymaps**: Leader key is Space (`vim.g.mapleader = " "`)

### Shell Scripts

**Shebang**: Use `#!/usr/bin/env bash` for bash scripts

**Location**: Define custom scripts in `common/scripts.nix` using `writeShellApplication`

## Version Control

### Primary VCS: Jujutsu (jj)

This repository uses Jujutsu with Git compatibility:

```bash
jj status              # Show working copy status
jj log                 # Show commit history
jj describe -m "msg"   # Set description for current change
jj commit -m "msg"     # Create a new commit
jj new                 # Start a new change
```

### Workspace Isolation for Agents

When making changes, use Jujutsu workspaces for isolation:

```bash
jj workspace add agent-<task-name>
cd agent-<task-name>
# Work in the workspace, then inform user when done
# Do NOT clean up without explicit user confirmation
```

See `skills/jj-workspace/SKILL.md` for detailed workspace workflow.

### Commit Style

- Use short, present-tense descriptions
- Examples: "Add package X", "Fix sway keybinding", "Update flake inputs"

## Common Tasks

### Adding a New Package

Edit `common/packages.nix`, add to `home.packages` list.

### Email Configuration

- Shared mail setup lives in `common/email.nix`
- Prefer `accounts.email` and Home Manager program modules over raw config files
- Keep the remaining mutt fragments only for shared UI/behavior (`mutt/bindings`, `mutt/colors`, `mutt/gpg.rc`, `mutt/mailcap`)

### Adding a New Neovim Plugin

Create or edit a file in `nvim/lua/plugins/`:
```lua
return {
  { "author/plugin-name", config = function() require("plugin-name").setup({}) end },
}
```

### Machine-Specific Configuration

- Work laptop config: `lapping/` directory
- Personal laptop config: `nixos/` directory
- Shared config: `common/` directory

## Error Handling

### Nix Build Errors

If `nixos-rebuild` fails:
1. Check error message for syntax issues
2. Run `alejandra` to fix formatting
3. Run `statix check .` for common issues
4. Test with `nix flake check`

### Unfree Packages

Add to allowlist in `common/packages.nix`:
```nix
nixpkgs.config.allowUnfreePredicate = pkg:
  builtins.elem (lib.getName pkg) [
    "existing-packages"
    "new-unfree-package"
  ];
```
