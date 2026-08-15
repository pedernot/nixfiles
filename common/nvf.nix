{
  lib,
  pkgs,
  ...
}: let
  kotlinLsp = pkgs.callPackage ./kotlin-lsp.nix {};
  kotlinProjectJdkHome = ''
    (function()
      local java = vim.fn.resolve(vim.env.JAVA_HOME .. "/bin/java")
      return vim.fs.dirname(vim.fs.dirname(java))
    end)()
  '';
in {
  programs.nvf = {
    enable = true;
    settings.vim = {
      viAlias = true;
      vimAlias = true;
      lazy.enable = true; # nvf's lz.n lazy loading (re-enabled now that lazy.nvim is removed)

      # Phase 4: Theme — tinted-vim with base16-harmonic16-dark
      # To switch to stylix theming instead: remove tinted-vim from startPlugins,
      # remove luaConfigRC.theme, and enable stylix.targets.nvf in theme.nix.
      # Note: stylix uses base16-nvim which maps colors differently than tinted-vim.
      #
      # Phases 6+: hover.nvim (no nvf module), lsp-colors, none-ls (for hadolint)
      # Phases 9-11: VCS, UI, tpope/utility plugins — all managed by nvf startPlugins
      startPlugins = with pkgs.vimPlugins; [
        tinted-vim
        hover-nvim
        lsp-colors-nvim
        none-ls-nvim
        # Phase 9: VCS (no nvf modules)
        vim-fugitive
        vim-rhubarb
        hunk-nvim
        jj-nvim
        gh-nvim
        litee-nvim
        # Phase 10: UI (lualine via nvf module; rest here)
        bufferline-nvim
        nvim-web-devicons
        neoscroll-nvim
        dressing-nvim
        vim-better-whitespace
        # Phase 11: tpope + utilities
        vim-repeat
        vim-surround
        vim-unimpaired
        vim-speeddating
        vim-rsi
        vim-ReplaceWithRegister
        vim-tmux-navigator
        vim-textobj-user
        vim-textobj-entire
        vim-vinegar
        # Phase 11: Language/filetype plugins
        vim-beancount
        vim-cue
        glow-nvim
        todo-txt-vim
        # Phase 11: mini.nvim (ai, indentscope, bufremove)
        mini-nvim
        # Note: curl-nvim, vim-system-copy, vim-cooklang not in nixpkgs — skipped
      ];

      # Phase 5: Treesitter
      treesitter = {
        enable = true;
        grammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          nix
          lua
          python
          rust
          bash
          haskell
          java
          dockerfile
          markdown
          yaml
          toml
          json
          sql
        ];
      };

      additionalRuntimePaths = [./nvim-queries];

      # Phase 8: Telescope
      # telescope-undo loaded via extensions; <C-p><C-h> (oldfiles) and
      # <C-p><C-u> (undo) added in vim.keymaps since nvf has no mapping for them.
      # NOTE: investigate <C-p><C-h> if it stops working — chord bindings depend on timeoutlen.
      telescope = {
        enable = true;
        extensions = [
          {
            name = "undo";
            packages = [pkgs.vimPlugins.telescope-undo-nvim];
          }
        ];
        setupOpts.defaults.path_display = ["truncate"];
        setupOpts.defaults.vimgrep_arguments = [
          "${pkgs.ripgrep}/bin/rg"
          "--color=never"
          "--no-heading"
          "--with-filename"
          "--line-number"
          "--column"
          "--smart-case"
        ];
        setupOpts.defaults.mappings.i = {
          "<C-j>" = "move_selection_next";
          "<C-k>" = "move_selection_previous";
          "<Esc>" = "close";
        };
        mappings = {
          open = "<C-p>";
          findFiles = "<C-p><C-f>";
          liveGrep = "<C-p><C-g>";
          buffers = "<C-p><C-b>";
          lspDocumentSymbols = "<C-p><C-o>";
          lspWorkspaceSymbols = null;
          lspReferences = "r<C-]>";
          # Disable nvf defaults not in my workflow
          helpTags = null;
          resume = null;
          gitFiles = null;
          gitCommits = null;
          gitBufferCommits = null;
          gitBranches = null;
          gitStatus = null;
          gitStash = null;
          lspImplementations = null;
          lspDefinitions = null;
          lspTypeDefinitions = null;
          diagnostics = null;
          treesitter = null;
          findProjects = null;
        };
      };

      # Phase 9: Gitsigns
      # Mappings overridden from nvf defaults (<leader>h*) to match previous config (<leader>g*).
      # Text object `ih` (select_hunk) added in luaConfigRC.plugins-setup.
      git.gitsigns = {
        enable = true;
        mappings = {
          stageHunk = "<leader>gs";
          resetHunk = "<leader>gr";
          stageBuffer = "<leader>gS";
          undoStageHunk = "<leader>gu";
          resetBuffer = "<leader>gR";
          previewHunk = "<leader>gp";
          blameLine = "<leader>gb";
          # toggleBlame stays at nvf default: <leader>tb
          diffThis = "<leader>gd";
          diffProject = "<leader>gD";
          # toggleDeleted stays at nvf default: <leader>td
        };
      };

      # Phase 10: Lualine statusline
      statusline.lualine.enable = true;

      # Phase 6: LSP built-in modules
      # lsp.enable required for trouble to activate (trouble checks vim.lsp.enable).
      # Enabling it also adds nvf's default <leader>lg* LSP keymaps (buffer-local).
      lsp = {
        enable = true;
        formatOnSave = true;

        # Phase 8: Trouble (v2 API: "toggle diagnostics", not "workspace_diagnostics")
        # Default nvf mappings disabled — using <C-x><C-*> keymaps in vim.keymaps.
        trouble = {
          enable = true;
          mappings = {
            workspaceDiagnostics = null;
            documentDiagnostics = null;
            lspReferences = null;
            quickfix = null;
            locList = null;
            symbols = null;
          };
        };

        # lspSignature removed — incompatible with blink.cmp.
        # Using blink.cmp's built-in signature feature instead (see autocomplete.blink-cmp.setupOpts).
      };

      # Phase 8: Todo-comments
      notes.todo-comments.enable = true;

      # Phase 7: Completion — blink.cmp
      # "enter" preset: CR confirms, S-Tab goes prev. Tab overridden to accept (not select_next).
      # Old nvim-cmp had C-Space (trigger), C-e (close), C-b/C-f (scroll docs).
      # These can be added via setupOpts.keymap if needed in the future.
      # Cmdline "/" with buffer source is also not configured (was in old setup).
      autocomplete.blink-cmp = {
        enable = true;
        setupOpts = {
          keymap = {
            preset = "enter";
            "<Tab>" = ["accept" "fallback"];
          };
          sources.default = ["lsp" "buffer" "path" "snippets"];
          cmdline.sources = ["path" "cmdline"];
          completion.list.selection = {
            preselect = false;
            auto_insert = true;
          };
          completion.accept.auto_brackets.enabled = false;
          completion.documentation.auto_show = true;
          signature.enabled = true; # replaces lsp-signature (incompatible with blink.cmp)
        };
      };

      # Phase 6: Language modules (LSP + formatters)
      # docker has no nvf module — dockerls configured in luaConfigRC.lsp-custom
      # cue, mojo, ty have no nvf module — configured in luaConfigRC.lsp-custom
      languages = {
        lua = {
          enable = true;
          lsp.enable = true;
          format.enable = true;
        };
        python = {
          enable = true;
          lsp = {
            enable = true;
            servers = ["ruff"];
          };
          format = {
            enable = true;
            type = ["ruff"];
          };
        };
        nix = {
          enable = true;
          lsp = {
            enable = true;
            servers = ["nixd"];
          };
          format.enable = true;
          extraDiagnostics = {
            enable = true;
            types = ["statix"];
          };
        };
        rust = {
          enable = true;
          lsp.enable = true;
          format.enable = true;
        };
        bash = {
          enable = true;
          lsp.enable = true;
        };
        haskell = {
          enable = true;
          lsp.enable = true;
        };
        java = {
          enable = true;
          lsp.enable = true;
        };
        kotlin = {
          enable = true;
          treesitter.enable = true;
          lsp.enable = false;
          extraDiagnostics.enable = true;
        };
        zig = {
          enable = true;
          lsp.enable = true;
        };
      };

      # JetBrains' official Kotlin server is not packaged by nvf yet. Keep the
      # language module for Treesitter and ktlint, and register the LSP here.
      lsp.servers.kotlin-lsp = {
        cmd = ["${lib.getExe kotlinLsp}" "--stdio"];
        cmd_env.IJ_JAVA_OPTIONS = lib.generators.mkLuaInline ''
          (vim.env.IJ_JAVA_OPTIONS or "")
            .. " -Dcom.jetbrains.ls.imports.gradle.java.home="
            .. ${kotlinProjectJdkHome}
        '';
        filetypes = ["kotlin"];
        init_options.defaultSdk = lib.generators.mkLuaInline kotlinProjectJdkHome;
        root_markers = [
          "settings.gradle"
          "settings.gradle.kts"
          "pom.xml"
          "build.gradle"
          "build.gradle.kts"
          "workspace.json"
        ];
      };

      # nvf's Kotlin module exposes ktlint diagnostics but not formatting.
      formatter.conform-nvim.setupOpts = {
        # Leave Kotlin's formatter list empty so Conform uses its configured
        # LSP fallback. To restore ktlint, uncomment this block and replace
        # the empty formatter list with the commented mapping below.
        /*
        formatters.ktlint = {
          command = lib.getExe pkgs.ktlint;
          args = [
            "--format"
            "$FILENAME"
            "--log-level=none"
          ];
          # ktlint 1.8.0's stdin formatter treats Kotlin's `%` operator as a
          # printf conversion and crashes. Let Conform format a same-directory
          # temporary file instead; this also preserves .editorconfig lookup.
          stdin = false;
          # ktlint exits 1 when unfixable lint violations remain, even when it
          # successfully writes all safe formatting changes to the file.
          exit_codes = [0 1];
        };
        formatters_by_ft.kotlin = ["ktlint"];
        */
        formatters_by_ft.kotlin = [];
      };

      # Treesitter's Kotlin indent expression currently returns column zero
      # for new lines. Use Neovim's Kotlin indent script instead.
      luaConfigRC.kotlin-indent = ''
        vim.api.nvim_create_autocmd("FileType", {
          pattern = "kotlin",
          callback = function()
            vim.bo.indentexpr = "GetKotlinIndent()"
            vim.bo.expandtab = true
            vim.bo.shiftwidth = 4
            vim.bo.softtabstop = 4
            vim.bo.tabstop = 4
          end,
        })
      '';

      # nvf's synchronous format-on-save timeout is 500 ms. ktlint starts a
      # JVM, so give Kotlin buffers enough time while preserving the existing
      # timeout for faster formatters.
      luaConfigRC.kotlin-format-timeout = ''
        require("conform").setup({
          format_on_save = function(bufnr)
            if not vim.g.formatsave or vim.b[bufnr].disableFormatSave then
              return
            end

            local timeout_ms = vim.bo[bufnr].filetype == "kotlin" and 5000 or 500
            return { lsp_format = "fallback", timeout_ms = timeout_ms }
          end,
        })
      '';

      # Phase 6: Override Python conform formatters to use built-in ruff formatters.
      # nvf's ruff and ruff-check don't pass --stdin-filename, so ruff can't find
      # pyproject.toml and ignores project rules (including isort/I). Conform's
      # built-in ruff_organize_imports and ruff_format pass --stdin-filename correctly.
      luaConfigRC.python-format-override = ''
        require("conform").formatters_by_ft.python = { "ruff_organize_imports", "ruff_format" }
      '';

      # Phase 6: LspAttach keymaps (buffer-local, can't use vim.keymaps)
      # nvf's lsp.enable also adds <leader>lg* keymaps via its own LspAttach handler
      luaConfigRC.lsp-attach = ''
        vim.api.nvim_create_autocmd("LspAttach", {
          group = vim.api.nvim_create_augroup("UserLspConfig", {}),
          callback = function(ev)
            vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
            local bufopts = { noremap = true, silent = true, buffer = ev.buf }
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
            vim.keymap.set("n", "gd", function()
              vim.lsp.buf.definition({
                on_list = function(options)
                  local item = options.items[1]
                  local uri = item and item.user_data and item.user_data.uri
                  local scheme = uri and uri:match("^([%w+.-]+):")

                  if #options.items == 1 and (scheme == "jar" or scheme == "jrt") then
                    local clients = vim.lsp.get_clients({ bufnr = ev.buf, name = "kotlin-lsp" })
                    local client = clients[1]
                    if not client then
                      vim.notify("Kotlin LSP is not attached", vim.log.levels.ERROR)
                      return
                    end

                    client:request("workspace/executeCommand", {
                      command = "decompile",
                      arguments = { uri },
                    }, function(err, result)
                      if err or not result or not result.code then
                        vim.notify(
                          "Kotlin decompilation failed: " .. (err and err.message or "no source returned"),
                          vim.log.levels.ERROR
                        )
                        return
                      end

                      local bufnr = vim.uri_to_bufnr(uri)
                      vim.bo[bufnr].modifiable = true
                      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(result.code, "\n", { plain = true }))
                      vim.bo[bufnr].buftype = "nofile"
                      vim.bo[bufnr].buflisted = true
                      vim.bo[bufnr].swapfile = false
                      vim.bo[bufnr].filetype = result.language or "kotlin"
                      vim.bo[bufnr].modifiable = false
                      vim.api.nvim_set_current_buf(bufnr)

                      local range = item.user_data.range
                      if range then
                        vim.api.nvim_win_set_cursor(0, { range.start.line + 1, range.start.character })
                      end
                    end, ev.buf)
                    return
                  end

                  vim.fn.setqflist({}, " ", options)
                  if #options.items == 1 then
                    vim.cmd.cfirst()
                  else
                    vim.cmd.copen()
                  end
                end,
              })
            end, bufopts)
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
            vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, bufopts)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if client and client.name == "jdt-language-server" then
              client.server_capabilities.documentFormattingProvider = false
              client.server_capabilities.documentRangeFormattingProvider = false
            end
            vim.keymap.set("n", "<space>f", function()
              require("conform").format({
                async = true,
                lsp_format = "fallback",
              })
            end, bufopts)
          end,
        })
      '';

      # Phase 6: Servers without nvf language modules + hadolint + hover.nvim
      # package.path hacks removed — lazy.nvim is gone, startPlugins work via normal rtp
      luaConfigRC.lsp-custom = ''
        -- dockerls
        vim.lsp.config("dockerls", {
          settings = {
            docker = {
              languageserver = {
                formatter = { ignoreMultilineInstructions = true },
              },
            },
          },
        })
        vim.lsp.enable("dockerls")

        -- ty (Python type checker, no built-in neovim config)
        vim.lsp.config("ty", {
          cmd = { "ty", "server" },
          filetypes = { "python" },
          root_markers = { "pyproject.toml", "ty.toml", ".git" },
          settings = { ty = { experimental = { autoImport = true, rename = true } } },
        })
        vim.lsp.enable("ty")

        -- cue, mojo
        vim.lsp.enable("cue")
        vim.lsp.enable("mojo")

        -- hls custom settings (nvf enables it, we override)
        vim.lsp.config("hls", {
          filetypes = { "haskell", "lhaskell", "cabal" },
          settings = {
            haskell = {
              cabalFormattingProvider = "cabal-fmt",
              formattingProvider = "ormolu",
              plugin = { hlint = { diagnosticsOn = false } },
            },
          },
        })

        -- Hadolint via none-ls (no docker language module in nvf)
        local null_ls = require("null-ls")
        null_ls.setup({
          sources = { null_ls.builtins.diagnostics.hadolint },
        })

        -- hover.nvim
        require("hover").setup({
          init = function() require("hover.providers.lsp") end,
          preview_opts = { border = nil },
          title = true,
          providers = {
            { module = "hover.providers.lsp", priority = 1001 },
            { module = "hover.providers.diagnostic", priority = 1000 },
          },
        })
        vim.keymap.set("n", "<C-y>", require("hover").hover, { desc = "hover.nvim" })
      '';

      # Phase 9-11: Plugin setup (VCS, UI, mini, gitsigns text object)
      luaConfigRC.plugins-setup = ''
        -- Phase 9: VCS
        require("hunk").setup()
        require("jj").setup({})
        require("litee.lib").setup()
        require("litee.gh").setup()

        -- Phase 9: Gitsigns text object (nvf sets global keymaps; this adds the text object)
        vim.keymap.set({"o", "x"}, "ih", ":<C-U>Gitsigns select_hunk<CR>")

        -- Phase 10: UI
        require("bufferline").setup({ options = { diagnostics = "nvim_lsp" } })
        require("neoscroll").setup({
          hide_cursor = false,
          mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-e>", "zt", "zz", "zb" },
        })
        require("dressing").setup({})

        -- Phase 11: mini.nvim
        require("mini.ai").setup()
        require("mini.indentscope").setup()
        require("mini.bufremove").setup()
      '';

      luaConfigRC.theme = ''
        vim.g.tinted_colorspace = 256
        vim.cmd("colorscheme base16-harmonic16-dark")
      '';

      # Phase 13: After/syntax customizations
      # Previously in nvim/after/syntax/{markdown,python}.vim — converted to Syntax autocmds
      # so the nvim/ directory can be removed in phase 14.
      # The Syntax event fires after the filetype's syntax file is loaded (same timing as after/syntax/).
      luaConfigRC.after-syntax = ''
        -- markdown: YAML frontmatter highlighting
        vim.api.nvim_create_autocmd("Syntax", {
          pattern = "markdown",
          group = vim.api.nvim_create_augroup("after_syntax_markdown", { clear = true }),
          callback = function()
            vim.cmd([[
              if exists("b:current_syntax") | unlet b:current_syntax | endif
              syntax include @Yaml syntax/yaml.vim
              syntax region yamlFrontmatter start=/\%^---$/ end=/^---$/ keepend contains=@Yaml
            ]])
          end,
        })

        -- python: kwargs, match/case keywords, constants, dunders
        vim.api.nvim_create_autocmd("Syntax", {
          pattern = "python",
          group = vim.api.nvim_create_augroup("after_syntax_python", { clear = true }),
          callback = function()
            vim.cmd([[
              syntax match PythonKwArg "\v[\(\,]\_s?\s{-}\zs\w+\ze\=(\=)@!"
              syntax match PythonKwArg "\v^\s{-}\zs\w+\ze\=(\=)@!"
              syn keyword PythonMatch match case
              syn match PythonConstant /\<[A-Z_][A-Z_0-9]*\>/
              syn match PythonDunder "__\w*__"
              hi def link PythonKwArg Special
              hi def link PythonConstant Constant
              hi def link PythonDunder PreProc
              hi def link PythonMatch Conditional
            ]])
          end,
        })
      '';

      # Phase 1: Options
      globals = {
        mapleader = " ";
        maplocalleader = ",";
        netrw_fastbrowse = 0;
        netrw_browsex_viewer = "firefox";
      };

      options = {
        number = true;
        relativenumber = true;
        cursorline = false;
        showcmd = true;
        textwidth = 100;
        wrap = false;
        termguicolors = true;
        autoread = true;
        updatetime = 100;
        tabstop = 2;
        shiftwidth = 2;
        expandtab = true;
        autoindent = true;
        incsearch = true;
        hlsearch = true;
        ignorecase = true;
        smartcase = true;
        showmatch = true;
        wildmenu = true;
        swapfile = false;
        signcolumn = "yes";
        splitbelow = true;
        splitright = true;
        hidden = true;
        completeopt = "menu,menuone,noselect";
      };

      luaConfigRC.options-extra = ''
        vim.opt.shortmess:append("I")
        vim.opt.wildignore:append("*.swp,*~,._*,*.pyc,__pycache__")
        vim.opt.wildignore:append("*.o,*.out,*.obj,.git,*.rbc,*.rbo,*.class,.svn,*.gem")
        vim.opt.wildignore:append("*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz")

        vim.diagnostic.config({
          virtual_text = true,
          signs = true,
          underline = true,
          update_in_insert = false,
          severity_sort = true,
        })
      '';

      # Phase 2: Keymaps
      keymaps = [
        {
          key = "<space>";
          mode = ["n"];
          action = "<Nop>";
        }
        {
          key = "<leader>h";
          mode = ["n"];
          action = ":nohlsearch<CR><C-L>";
          desc = "Clear highlights";
        }
        {
          key = ".";
          mode = ["v"];
          action = ":norm.<CR>";
          desc = "Repeat in visual";
        }
        {
          key = "jk";
          mode = ["i"];
          action = "<ESC>";
          desc = "Exit insert mode";
        }
        {
          key = "Q";
          mode = ["n"];
          action = "<NOP>";
          desc = "Disable Q";
        }
        {
          key = "<leader>p";
          mode = ["n"];
          action = '':set paste<CR>o<esc>"*]p:set nopaste<cr>'';
          desc = "Paste from clipboard";
        }
        # Disable arrow keys
        {
          key = "<Up>";
          mode = ["n" "i"];
          action = "<NOP>";
        }
        {
          key = "<Down>";
          mode = ["n" "i"];
          action = "<NOP>";
        }
        {
          key = "<Left>";
          mode = ["n" "i"];
          action = "<NOP>";
        }
        {
          key = "<Right>";
          mode = ["n" "i"];
          action = "<NOP>";
        }
        # Buffer management
        {
          key = "<leader>bd";
          mode = ["n"];
          action = ":bp<CR>:bd #<CR>";
          desc = "Delete buffer";
        }
        # Tmux navigation
        {
          key = "<C-h>";
          mode = ["n"];
          action = ":TmuxNavigateLeft<CR>";
          silent = true;
          desc = "Tmux left";
        }
        {
          key = "<C-j>";
          mode = ["n"];
          action = ":TmuxNavigateDown<CR>";
          silent = true;
          desc = "Tmux down";
        }
        {
          key = "<C-k>";
          mode = ["n"];
          action = ":TmuxNavigateUp<CR>";
          silent = true;
          desc = "Tmux up";
        }
        {
          key = "<C-l>";
          mode = ["n"];
          action = ":TmuxNavigateRight<CR>";
          silent = true;
          desc = "Tmux right";
        }
        # Diagnostics
        {
          key = "<space>e";
          mode = ["n"];
          action = "<cmd>lua vim.diagnostic.open_float()<CR>";
          silent = true;
          desc = "Diagnostic float";
        }
        {
          key = "[d";
          mode = ["n"];
          action = "<cmd>lua vim.diagnostic.goto_prev()<CR>";
          silent = true;
          desc = "Prev diagnostic";
        }
        {
          key = "]d";
          mode = ["n"];
          action = "<cmd>lua vim.diagnostic.goto_next()<CR>";
          silent = true;
          desc = "Next diagnostic";
        }
        {
          key = "<space>q";
          mode = ["n"];
          action = "<cmd>lua vim.diagnostic.setloclist()<CR>";
          silent = true;
          desc = "Diagnostic loclist";
        }
        # Phase 8: Trouble (v2 API — commands changed from v1: workspace_diagnostics → diagnostics)
        {
          key = "<C-x><C-x>";
          mode = ["n"];
          action = "<cmd>Trouble toggle<cr>";
          silent = true;
          desc = "Trouble";
        }
        {
          key = "<C-x><C-w>";
          mode = ["n"];
          action = "<cmd>Trouble toggle diagnostics<cr>";
          silent = true;
          desc = "Trouble workspace";
        }
        {
          key = "<C-x><C-d>";
          mode = ["n"];
          action = "<cmd>Trouble toggle diagnostics filter.buf=0<cr>";
          silent = true;
          desc = "Trouble document";
        }
        {
          key = "<C-x><C-l>";
          mode = ["n"];
          action = "<cmd>Trouble toggle loclist<cr>";
          silent = true;
          desc = "Trouble loclist";
        }
        {
          key = "<C-x><C-q>";
          mode = ["n"];
          action = "<cmd>Trouble toggle quickfix<cr>";
          silent = true;
          desc = "Trouble quickfix";
        }
        # Phase 8: Extra telescope keymaps (not covered by nvf telescope.mappings)
        # <C-p><C-p> duplicates <C-p> (open telescope picker)
        {
          key = "<C-p><C-p>";
          mode = ["n"];
          action = "<cmd>Telescope<cr>";
          silent = true;
          desc = "Telescope";
        }
        # <C-p><C-h> — oldfiles; NOTE: if this stops working, check timeoutlen chord handling
        {
          key = "<C-p><C-h>";
          mode = ["n"];
          action = "<cmd>Telescope oldfiles<cr>";
          silent = true;
          desc = "Telescope oldfiles";
        }
        # <C-p><C-t> — dynamic workspace symbols (interactive query)
        {
          key = "<C-p><C-t>";
          mode = ["n"];
          action = "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>";
          silent = true;
          desc = "Telescope dynamic workspace symbols";
        }
        # <C-p><C-u> — telescope-undo extension
        {
          key = "<C-p><C-u>";
          mode = ["n"];
          action = "<cmd>Telescope undo<cr>";
          silent = true;
          desc = "Telescope undo";
        }
      ];

      # hover.nvim keymap is set in luaConfigRC.lsp-custom after hover is required

      # Phase 3: Autocommands
      augroups = [
        {
          name = "highlight_cmds";
          clear = true;
        }
        {
          name = "format_opts";
          clear = true;
        }
        {
          name = "FugitiveCustom";
          clear = true;
        }
        {
          name = "markdown_cmds";
          clear = true;
        }
        {
          name = "git_commit";
          clear = true;
        }
        {
          name = "ansible_ft";
          clear = true;
        }
        {
          name = "helm_ft";
          clear = true;
        }
      ];

      autocmds = [
        {
          event = ["InsertEnter"];
          pattern = ["*"];
          group = "highlight_cmds";
          command = "setlocal nohlsearch";
        }
        {
          event = ["InsertLeave"];
          pattern = ["*"];
          group = "highlight_cmds";
          command = "setlocal hlsearch";
        }
        {
          event = ["FileType"];
          pattern = ["*"];
          group = "format_opts";
          command = "setlocal formatoptions-=c formatoptions-=r formatoptions-=o";
        }
        {
          event = ["BufRead"];
          pattern = ["fugitive://*"];
          group = "FugitiveCustom";
          command = "set bufhidden=delete";
        }
        {
          event = ["FileType"];
          pattern = ["markdown"];
          group = "markdown_cmds";
          command = "setlocal spell formatoptions=tqr";
        }
        {
          event = ["FileType"];
          pattern = ["gitcommit"];
          group = "git_commit";
          command = "setlocal spell textwidth=72";
        }
        {
          event = ["BufRead" "BufNewFile"];
          pattern = ["*/playbooks/*.yml"];
          group = "ansible_ft";
          command = "set filetype=yaml.ansible";
        }
        {
          event = ["BufRead" "BufNewFile"];
          pattern = ["*.gotmpl"];
          group = "helm_ft";
          command = "set filetype=helm";
        }
      ];

      # Phase 3: Custom commands
      luaConfigRC.custom-commands = ''
        vim.api.nvim_create_user_command("W", "w", {})
        vim.api.nvim_create_user_command("Wq", "wq", {})
        vim.api.nvim_create_user_command("WQ", "wq", {})
        vim.api.nvim_create_user_command("Wqa", "wqa", {})
        vim.api.nvim_create_user_command("SQL", "enew | setlocal buftype=nofile | setlocal ft=pgsql", {})
      '';

      # luaConfigRC.existing-config removed — lazy.nvim bootstrap no longer needed.
      # All plugins now managed by nvf startPlugins and nvf module system.
    };
  };
}
