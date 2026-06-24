{
  plugins.render-markdown = {
    enable = true;
    settings = {
      file_types = [
        "markdown"
        "vimwiki"
      ];
      render_modes = [
        "n"
        "no"
        "c"
        "t"
        "i"
        "ic"
      ];
      code = {
        sign = false;
        border = "thin";
        position = "right";
        width = "block";
        above = "▁";
        below = "▔";
        language_left = "█";
        language_right = "█";
        language_border = "▁";
        left_pad = 1;
        right_pad = 1;
      };
      heading = {
        sign = false;
        width = "block";
        left_pad = 1;
        right_pad = 0;
        position = "right";
        # NOTE: original glyphs were lost in copy-paste; using explicit unicode
        # escapes as a placeholder. Replace with the exact nerd-font codepoints.
        icons.__raw = ''function(ctx) return ("\u{e0b8}"):rep(ctx.level) .. "\u{e0bc}" end'';
      };
      # tables are rendered by the md-table-fit plugin (fit-to-width + wrapping)
      pipe_table.enabled = false;
    };
    luaConfig.post = ''
      local get_hl = function(hl_name)
        local hl_info = vim.api.nvim_get_hl(0, { name = hl_name, link = false })
        return not vim.tbl_isempty(hl_info) and hl_info or nil
      end
      local setup_heading_hl_groups = function()
        local fallback_hl_info = get_hl("@markup.heading") or get_hl("Title")

        for lvl = 1, 6 do
          local hl_name = "@markup.heading." .. lvl
          local hl_info = get_hl(hl_name .. ".markdown") or get_hl(hl_name) or fallback_hl_info
          assert(
            hl_info,
            "Must set one of 'Title', '@markup.heading', '@markup.heading.N', or '@markup.heading.N.markdown'"
          )

          local hl_spec = {}
          if hl_info.fg then hl_spec.fg = hl_info.fg end
          if hl_info.bg then hl_spec.bg = hl_info.bg end
          hl_spec.bold = true

          vim.api.nvim_set_hl(0, "RenderMarkdownH" .. lvl, hl_spec)
          hl_spec.reverse = true
          vim.api.nvim_set_hl(0, "RenderMarkdownH" .. lvl .. "Bg", hl_spec)
        end

        vim.api.nvim_set_hl(0, "RenderMarkdownCode", {bg = "#002323"});
        vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", {fg = "#a6da95", bg = "#002323"});
      end
      setup_heading_hl_groups()
    '';
  };
}
