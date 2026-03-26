{pkgs, ...}: {
  programs.nvf.settings.vim = {
    # Phase 12: AI plugins (lapping-specific)

    startPlugins = with pkgs.vimPlugins; [
      # copilot-lsp enables NES (Next Edit Suggestions) mode in copilot.lua
      copilot-lsp
      # render-markdown for avante panel rendering
      render-markdown-nvim
      # codex.nvim — not in nixpkgs, build from source
      (pkgs.vimUtils.buildVimPlugin {
        name = "codex-nvim";
        src = pkgs.fetchFromGitHub {
          owner = "johnseth97";
          repo = "codex.nvim";
          rev = "e1149cbc875ff71ee21f8832b9fe815a270442b3";
          hash = "sha256-hvBsqLzV3oCVWK4Ll/YDrDhZSTjpvUjTpDQz6SFbtVo=";
        };
      })
    ];

    # copilot_nes_debounce used by copilot-lsp for NES debounce timing
    globals.copilot_nes_debounce = 500;

    assistant.copilot = {
      enable = true;
      setupOpts = {
        suggestion.auto_trigger = true;
        # NES (Next Edit Suggestions) mode via copilot-lsp
        nes = {
          enabled = true;
          keymap = {
            accept_and_goto = "<M-u>";
            accept = false;
            dismiss = "<Esc>";
          };
        };
      };
      # suggestion.accept = "<M-l>" is already the nvf default — no override needed
    };

    assistant.avante-nvim = {
      enable = true;
      setupOpts = {
        provider = "codex";
        # ACP (Agent Completion Protocol) provider for Codex CLI
        acp_providers.codex = {
          command = "npx";
          args = ["@zed-industries/codex-acp"];
          env = {
            NODE_NO_WARNINGS = "1";
            OPENAI_API_KEY = {
              _type = "lua-inline";
              expr = ''os.getenv("OPENAI_API_KEY")'';
            };
          };
        };
      };
    };

    luaConfigRC.ai-setup = ''
      -- render-markdown: enable for markdown and Avante filetypes
      require("render-markdown").setup({ file_types = { "markdown", "Avante" } })

      -- codex.nvim popup UI for OpenAI Codex CLI
      require("codex").setup({
        keymaps = {},   -- disable internal keymaps
        border = "rounded",
        width = 0.8,
        height = 0.8,
        autoinstall = true,
      })
      vim.keymap.set("n", "<leader>cc", function() require("codex").toggle() end, { desc = "Toggle Codex popup" })
    '';
  };
}
