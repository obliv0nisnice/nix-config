-- md-preview-term: render markdown like GitHub directly in a Kitty split.
-- pipeline: cmark-gfm (md->html) -> github css -> weasyprint (->pdf)
--           -> pdftoppm (->png) -> magick trim -> image.nvim
-- The result is one tall image fitted to the split width and scrolled through.

local M = {}

local uv = vim.uv or vim.loop
local CSS = require("md-preview-term.css")

M.config = {
  density = 140, -- pdftoppm rasterization dpi
  split = "vertical", -- "vertical" | "horizontal"
  focus_on_open = false,
  toggle_keymap = "<leader>vm", -- set to false to disable
}

local state = {
  active = false,
  src = nil,
  src_buf = nil,
  dir = nil,
  html = nil,
  pdf = nil,
  win = nil,
  buf = nil,
  augroup = nil,
  image = nil,
  image_file = nil,
  render_counter = 0,
  building = false,
  build_pending = false,
}

local function image_api()
  local ok, image = pcall(require, "image")
  if not ok then
    vim.notify("md-preview-term: image.nvim not found", vim.log.levels.ERROR)
    return nil
  end
  return image
end

local function render()
  if not state.active or not state.image_file then
    return
  end
  if not (state.win and vim.api.nvim_win_is_valid(state.win)) then
    return
  end
  local image = image_api()
  if not image then
    return
  end

  if state.image then
    pcall(function()
      state.image:clear()
    end)
    state.image = nil
  end

  -- width-fit; height follows aspect ratio so a long document overflows the
  -- window vertically and is scrolled through. the huge height cap disables
  -- image.nvim's default fit-to-window-height shrinking.
  local width = vim.api.nvim_win_get_width(state.win)
  local ok, img = pcall(image.from_file, state.image_file, {
    window = state.win,
    buffer = state.buf,
    with_virtual_padding = true,
    max_width_window_percentage = 100,
    max_height_window_percentage = 100000,
    x = 0,
    y = 0,
    width = width,
  })
  if ok and img then
    pcall(function()
      img:render()
    end)
    state.image = img
  end
end

-- cmark-gfm -> html -> weasyprint -> pdftoppm -> magick trim, all async.
local function build()
  if not state.active then
    return
  end
  if state.building then
    state.build_pending = true
    return
  end
  state.building = true

  -- callbacks are scheduled onto the main loop: vim.fn.* (shellescape,
  -- fnamemodify) must not run in libuv's fast event context.
  vim.system(
    { "cmark-gfm", "-e", "table", "-e", "strikethrough", "-e", "autolink", "-e", "tasklist", state.src },
    { text = true },
    vim.schedule_wrap(function(c1)
      if not state.active then
        state.building = false
        return
      end
      if c1.code ~= 0 then
        state.building = false
        vim.notify("md-preview-term: cmark-gfm failed\n" .. (c1.stderr or ""), vim.log.levels.ERROR)
        return
      end

      local mddir = vim.fn.fnamemodify(state.src, ":h")
      local html = string.format(
        '<!doctype html><html><head><meta charset="utf-8">'
          .. '<base href="file://%s/"><style>%s</style></head><body>%s</body></html>',
        mddir,
        CSS,
        c1.stdout
      )
      local hf = io.open(state.html, "w")
      if hf then
        hf:write(html)
        hf:close()
      end

      state.render_counter = state.render_counter + 1
      -- unique final name so image.nvim never serves a cached crop
      local final = state.dir .. "/final-" .. state.render_counter .. ".png"
      local page = state.dir .. "/page"
      local cmd = table.concat({
        "weasyprint " .. vim.fn.shellescape(state.html) .. " " .. vim.fn.shellescape(state.pdf),
        "pdftoppm -png -r " .. M.config.density .. " -singlefile " .. vim.fn.shellescape(state.pdf) .. " " .. vim.fn.shellescape(page),
        "magick " .. vim.fn.shellescape(page .. ".png") .. " -trim +repage -bordercolor white -border 24 " .. vim.fn.shellescape(final),
      }, " && ")

      vim.system(
        { "sh", "-c", cmd },
        { text = true },
        vim.schedule_wrap(function(c2)
          state.building = false
          if c2.code == 0 then
            state.image_file = final
            render()
          else
            vim.notify("md-preview-term: render failed\n" .. (c2.stderr or ""), vim.log.levels.ERROR)
          end
          if state.build_pending and state.active then
            state.build_pending = false
            build()
          end
        end)
      )
    end)
  )
end

local function open_window()
  local cur = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown-preview"
  -- blank lines give the tall image room to be scrolled through
  local blanks = {}
  for i = 1, 1000 do
    blanks[i] = ""
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, blanks)
  vim.bo[buf].modifiable = false

  if M.config.split == "horizontal" then
    vim.cmd("botright split")
  else
    vim.cmd("botright vsplit")
  end
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].cursorline = false
  vim.wo[win].list = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].wrap = false
  vim.wo[win].fillchars = "eob: "

  state.win = win
  state.buf = buf

  vim.keymap.set("n", "q", M.stop, { buffer = buf, nowait = true, silent = true })

  if not M.config.focus_on_open then
    vim.api.nvim_set_current_win(cur)
  end
end

function M.start()
  if state.active then
    return
  end
  if vim.bo.filetype ~= "markdown" then
    vim.notify("md-preview-term: not a markdown buffer", vim.log.levels.WARN)
    return
  end
  local src = vim.api.nvim_buf_get_name(0)
  if src == "" or vim.fn.filereadable(src) == 0 then
    vim.notify("md-preview-term: save the file first", vim.log.levels.WARN)
    return
  end
  for _, exe in ipairs({ "cmark-gfm", "weasyprint", "pdftoppm", "magick" }) do
    if vim.fn.executable(exe) == 0 then
      vim.notify("md-preview-term: '" .. exe .. "' not found", vim.log.levels.ERROR)
      return
    end
  end
  if not image_api() then
    return
  end

  state.src = src
  state.src_buf = vim.api.nvim_get_current_buf()
  state.dir = vim.fn.tempname()
  vim.fn.mkdir(state.dir, "p")
  state.html = state.dir .. "/doc.html"
  state.pdf = state.dir .. "/doc.pdf"
  state.render_counter = 0
  state.active = true

  open_window()

  state.augroup = vim.api.nvim_create_augroup("MdPreviewTerm", { clear = true })
  vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
    group = state.augroup,
    callback = function()
      if state.active then
        render()
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = state.augroup,
    buffer = state.src_buf,
    callback = build,
  })

  build()
end

function M.stop()
  if not state.active then
    return
  end
  state.active = false
  if state.augroup then
    pcall(vim.api.nvim_del_augroup_by_id, state.augroup)
    state.augroup = nil
  end
  if state.image then
    pcall(function()
      state.image:clear()
    end)
    state.image = nil
  end
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    pcall(vim.api.nvim_win_close, state.win, true)
  end
  if state.dir then
    pcall(vim.fn.delete, state.dir, "rf")
  end
  state.win, state.buf, state.dir, state.src, state.src_buf = nil, nil, nil, nil, nil
  state.image_file, state.building, state.build_pending = nil, false, false
end

function M.toggle()
  if state.active then
    M.stop()
  else
    M.start()
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  vim.api.nvim_create_user_command("MarkdownPreviewTerm", M.toggle, { desc = "Toggle markdown GitHub preview" })
  vim.api.nvim_create_user_command("MarkdownPreviewTermStop", M.stop, { desc = "Stop markdown preview" })

  if M.config.toggle_keymap then
    vim.keymap.set("n", M.config.toggle_keymap, M.toggle, { desc = "Toggle markdown GitHub preview" })
  end

  vim.api.nvim_create_autocmd("VimLeavePre", { callback = M.stop })
end

return M
