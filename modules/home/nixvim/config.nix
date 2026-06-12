{ lib, pkgs, ... }:
{
  enable = true;
  viAlias = true;
  vimAlias = true;
  colorschemes.dracula.enable = true;

  globals.mapleader = " ";
  opts = {
    updatetime = 100; # Faster completion

    number = true;
    relativenumber = true;
    showmode = false; #already shown in lightline

    autoindent = true;
    clipboard = "unnamedplus";
    expandtab = true;
    shiftwidth = 2;
    smartindent = true;
    tabstop = 2;

    ignorecase = true;
    incsearch = true;
    smartcase = true;
    wildmode = "list:longest";

    swapfile = false;
    undofile = true; # Build-in persistent undo

    termguicolors = lib.mkForce pkgs.stdenv.isLinux;
  };

  plugins.mini-align.enable = true;

  keymaps = [
    # Global
    # Default mode is "" which means normal-visual-op
    {
      key = "<leader>x";
      action = "<CMD>NvimTreeToggle<CR>";
      options.desc = "Toggle NvimTree";
    }
    {
      key = "<leader>p";
      action = "<CMD>PasteImg<CR>";
      options.desc = "Pastes an Image from the clipboard";
    }

    # File
    #{
    #  mode = "n";
    #  key = "<leader>sf";
    #  action = "+find/file";
    #}
    {
      # Format file
      key = "<leader>fm";
      action = "<CMD>lua vim.lsp.buf.format()<CR>";
      options.desc = "Format the current buffer";
    }

    # Git    
    {
      mode = "n";
      key = "<leader>g";
      action = "+git";
    }
    {
      key = "<leader>gg";
      action = "<CMD>LazyGit<CR>";
      options.desc = "Open LazyGit";
    }
    {
      mode = "n";
      key = "<leader>gt";
      action = "+toggles";
    }
    {
      key = "<leader>gtb";
      action = "<CMD>Gitsigns toggle_current_line_blame<CR>";
      options.desc = "Gitsigns current line blame";
    }
    {
      key = "<leader>gtd";
      action = "<CMD>Gitsigns toggle_deleted";
      options.desc = "Gitsigns deleted";
    }
    {
      key = "<leader>gc";
      action = "<CMD>NvimTreeClose<CR><CMD>Neogit<CR>";
      options.desc = "Commit changes";
    }
    {
      key = "<leader>gd";
      action = "<CMD>NvimTreeClose<CR><CMD>DiffviewOpen<CR>";
      options.desc = "View git changes";
    }
    {
      key = "<leader>gq";
      action = "<CMD>DiffviewClose<CR><CMD>NvimTreeOpen<CR>";
      options.desc = "Close git changes";
    }
    {
      mode = "n";
      key = "<leader>gr";
      action = "+resets";
    }
    {
      key = "<leader>grh";
      action = "<CMD>Gitsigns reset_hunk<CR>";
      options.desc = "Gitsigns reset hunk";
    }
    {
      key = "<leader>grb";
      action = "<CMD>Gitsigns reset_buffer<CR>";
      options.desc = "Gitsigns reset current buffer";
    }

    # Tabs (barbar)
    {
      mode = "n";
      key = "<leader>tn";
      action = "<CMD>tabnew<CR>";
      options.desc = "Create new tab";
    }
    {
      mode = "n";
      key = "<leader>td";
      action = "<CMD>BufferClose<CR>";
      options.desc = "Close tab";
    }
    {
      mode = "n";
      key = "<leader>tt";
      action = "<CMD>BufferNext<CR>";
      options.desc = "Go to the sub-sequent tab";
    }
    {
      mode = "n";
      key = "<leader>tp";
      action = "<CMD>BufferPrevious<CR>";
      options.desc = "Go to the previous tab";
    }

    # Terminal
    {
      # Escape terminal mode using ESC
      mode = "t";
      key = "<esc>";
      action = "<C-\\><C-n>";
      options.desc = "Escape terminal mode";
    }

    # Trouble 
    {
      key = "<leader>dt";
      action = "<CMD>TroubleToggle<CR>";
      options.desc = "Toggle trouble";
    }

    # Rust
    {
      # Start standalone rust-analyzer (fixes issues when opening files from nvim tree)
      mode = "n";
      key = "<leader>rs";
      action = "<CMD>RustStartStandaloneServerForBuffer<CR>";
      options.desc = "Start standalone rust-analyzer";
    }

    # refactoring
    {
      mode = "n";
      key = "<leader>re";
      action = ":Refactor extract_var ";
      options.desc = "Extract to variable";
    }
    {
      mode = "n";
      key = "<leader>rE";
      action = ":Refactor extract ";
      options.desc = "Extract to function";
    }
    {
      mode = "n";
      key = "<leader>rb";
      action = ":Refactor extract_block ";
      options.desc = "Extract to block";
    }
    {
      mode = "n";
      key = "<leader>ri";
      action = ":Refactor inline_var ";
      options.desc = "Inline variable";
    }
    {
      mode = "n";
      key = "<leader>rI";
      action = ":Refactor inline_func ";
      options.desc = "Inline function";
    } 
    # hop
        {
      key = "f";
      action.__raw = ''
        function()
          require'hop'.hint_char1({
            --direction = require'hop.hint'.HintDirection.AFTER_CURSOR,
            current_line_only = false,
            case_insensitive = true,
          })
       end
      '';
      options.remap = true;
    }
    {
      key = "F";
      action.__raw = ''
        function()
          require'hop'.hint_char1({
            direction = require'hop.hint'.HintDirection.BEFORE_CURSOR,
            current_line_only = false
          })
        end
     '';
      options.remap = true;
    }
  ];
}
