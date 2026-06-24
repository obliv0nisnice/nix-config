-- typst-preview-term: render typst output directly in a Kitty split via image.nvim
-- Phase 1: live single-page preview with page navigation.

local M = {}

local uv = vim.uv or vim.loop

M.config = {
  ppi = 144, -- compile resolution; higher = crisper, slower
  split = "vertical", -- "vertical" | "horizontal"
  focus_on_open = false, -- keep focus in the source window when opening
  follow_cursor = true, -- preview jumps to the page matching the cursor line
  toggle_keymap = "<leader>vp", -- set to false to disable
}

local state = {
  active = false,
  src = nil,
  dir = nil,
  job = nil,
  watcher = nil,
  win = nil,
  buf = nil,
  src_buf = nil,
  augroup = nil,
  page = 1,
  pages = 0,
  image = nil,
  last_render_file = nil,
  render_counter = 0,
  rendering = false,
  render_pending = false,
  timer = nil,
  follow_timer = nil,
  querying = false,
  query_pending = false,
}

local function image_api()
  local ok, image = pcall(require, "image")
  if not ok then
    vim.notify("typst-preview-term: image.nvim not found", vim.log.levels.ERROR)
    return nil
  end
  return image
end

-- sorted list of typst's per-page output PNGs
local function list_pages()
  if not state.dir then
    return {}
  end
  local files = vim.fn.glob(state.dir .. "/out-*.png", false, true)
  table.sort(files, function(a, b)
    local na = tonumber(a:match("out%-(%d+)%.png")) or 0
    local nb = tonumber(b:match("out%-(%d+)%.png")) or 0
    return na < nb
  end)
  return files
end

local function clear_image()
  if state.image then
    pcall(function()
      state.image:clear()
    end)
    state.image = nil
  end
  if state.last_render_file then
    pcall(uv.fs_unlink, state.last_render_file)
    state.last_render_file = nil
  end
end

-- forward declarations: render() and debounced_render() are mutually recursive
-- (a re-entrant render reschedules itself through the debounce).
local render, debounced_render

function render()
  if not state.active or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end
  local win = state.win
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return
  end
  local image = image_api()
  if not image then
    return
  end

  -- img:render() drives magick via :wait(), which pumps the event loop; without
  -- this guard a timer/WinResized could re-enter render() and delete the
  -- render-N.png that the in-flight magick is still reading ("No such file").
  if state.rendering then
    state.render_pending = true
    return
  end
  state.rendering = true

  pcall(function()
    local pages = list_pages()
    state.pages = #pages
    if state.pages == 0 then
      return
    end
    state.page = math.max(1, math.min(state.page, state.pages))

    clear_image()

    -- Render from a uniquely named copy so image.nvim never serves a cached
    -- crop of the previous compile (typst overwrites the same out-N.png path).
    local src_png = pages[state.page]
    state.render_counter = state.render_counter + 1
    local target = state.dir .. "/render-" .. state.render_counter .. ".png"
    if not pcall(uv.fs_copyfile, src_png, target) then
      return
    end
    state.last_render_file = target

    -- pass both dims so image.nvim fits the page proportionally into the window
    local width = vim.api.nvim_win_get_width(win)
    local height = vim.api.nvim_win_get_height(win)
    local ok, img = pcall(image.from_file, target, {
      window = win,
      buffer = state.buf,
      with_virtual_padding = true,
      -- override image.nvim's per-window caps (defaults: width 100%, height 50%);
      -- the 50% height cap otherwise halves a portrait page. these per-image values
      -- take precedence over the globals in the renderer.
      max_width_window_percentage = 100,
      max_height_window_percentage = 100,
      x = 0,
      y = 0,
      width = width,
      height = height,
    })
    if ok and img then
      pcall(function()
        img:render()
      end)
      state.image = img
    end

    pcall(vim.api.nvim_set_option_value, "winbar", string.format("  Typst  —  Seite %d/%d ", state.page, state.pages), { win = win })
  end)

  state.rendering = false
  if state.render_pending then
    state.render_pending = false
    debounced_render()
  end
end

function debounced_render()
  if state.timer then
    state.timer:stop()
    pcall(function()
      state.timer:close()
    end)
    state.timer = nil
  end
  state.timer = uv.new_timer()
  state.timer:start(
    120,
    0,
    vim.schedule_wrap(function()
      if state.timer then
        state.timer:stop()
        pcall(function()
          state.timer:close()
        end)
        state.timer = nil
      end
      render()
    end)
  )
end

-- jump the preview to the page the cursor actually renders on. we inject an
-- invisible marker at the cursor position, then ask the typst compiler which
-- page it lands on via `typst eval … query(<marker>).first().value`. this is
-- layout-exact (handles explicit breaks AND overflow), unlike a line heuristic.
-- the document is piped on stdin, so nothing touches disk.
local MARKER_LABEL = "tpt_cursor"
local MARKER = "#context[#metadata(here().page())<" .. MARKER_LABEL .. ">]"

local function follow()
  if not state.active or state.pages == 0 then
    return
  end
  if vim.api.nvim_get_current_buf() ~= state.src_buf then
    return
  end
  -- one query at a time; coalesce moves that arrive while one is in flight
  if state.querying then
    state.query_pending = true
    return
  end

  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(state.src_buf, 0, -1, false)
  if row > #lines then
    return
  end
  -- attach the marker at the end of the nearest non-blank line at/above the
  -- cursor. injecting into a blank line (a paragraph break) or before a list
  -- marker changes the layout and reports the wrong page near boundaries.
  local target = row
  while target > 1 and lines[target]:match("^%s*$") do
    target = target - 1
  end
  lines[target] = lines[target] .. MARKER
  local content = table.concat(lines, "\n")
  local root = vim.fn.fnamemodify(state.src, ":h")

  state.querying = true
  vim.system(
    { "typst", "eval", "query(<" .. MARKER_LABEL .. ">).first().value", "--in", "-", "--root", root },
    { stdin = content, text = true },
    vim.schedule_wrap(function(obj)
      state.querying = false
      if state.active and obj.code == 0 and obj.stdout then
        local page = tonumber((obj.stdout:gsub("%s+", "")))
        if page then
          page = math.max(1, math.min(state.pages, page))
          if page ~= state.page then
            state.page = page
            debounced_render()
          end
        end
      end
      -- a move landed during the query: run once more with the latest cursor
      if state.query_pending and state.active then
        state.query_pending = false
        follow()
      end
    end)
  )
end

-- debounce cursor moves so we don't spawn a compile on every keystroke
local function schedule_follow()
  if not (state.active and M.config.follow_cursor) then
    return
  end
  if state.follow_timer then
    state.follow_timer:stop()
    pcall(function()
      state.follow_timer:close()
    end)
    state.follow_timer = nil
  end
  state.follow_timer = uv.new_timer()
  state.follow_timer:start(
    150,
    0,
    vim.schedule_wrap(function()
      if state.follow_timer then
        state.follow_timer:stop()
        pcall(function()
          state.follow_timer:close()
        end)
        state.follow_timer = nil
      end
      follow()
    end)
  )
end

local function open_window()
  local cur = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "typst-preview"

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
  vim.wo[win].fillchars = "eob: "

  state.win = win
  state.buf = buf

  -- buffer-local navigation (only inside the preview window)
  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "j", M.next_page, opts)
  vim.keymap.set("n", "<Down>", M.next_page, opts)
  vim.keymap.set("n", "k", M.prev_page, opts)
  vim.keymap.set("n", "<Up>", M.prev_page, opts)
  vim.keymap.set("n", "q", M.stop, opts)

  if not M.config.focus_on_open then
    vim.api.nvim_set_current_win(cur)
  end
end

function M.start()
  if state.active then
    return
  end
  if vim.bo.filetype ~= "typst" then
    vim.notify("typst-preview-term: not a typst buffer", vim.log.levels.WARN)
    return
  end
  local src = vim.api.nvim_buf_get_name(0)
  if src == "" or vim.fn.filereadable(src) == 0 then
    vim.notify("typst-preview-term: save the file first", vim.log.levels.WARN)
    return
  end
  if not image_api() then
    return
  end

  state.src = src
  state.src_buf = vim.api.nvim_get_current_buf()
  state.dir = vim.fn.tempname()
  vim.fn.mkdir(state.dir, "p")
  state.page = 1
  state.render_counter = 0
  state.active = true

  open_window()

  state.job = vim.system({
    "typst",
    "watch",
    src,
    state.dir .. "/out-{p}.png",
    "--ppi",
    tostring(M.config.ppi),
  }, { stdout = false, stderr = false }, function() end)

  state.watcher = uv.new_fs_event()
  state.watcher:start(
    state.dir,
    {},
    vim.schedule_wrap(function(err, fname)
      if err then
        return
      end
      -- ignore our own render-*.png copies, else we'd retrigger ourselves
      if fname and fname:match("^render%-") then
        return
      end
      debounced_render()
    end)
  )

  state.augroup = vim.api.nvim_create_augroup("TypstPreviewTerm", { clear = true })
  -- keep the page fitted when the window/layout changes
  vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
    group = state.augroup,
    callback = function()
      if state.active then
        debounced_render()
      end
    end,
  })
  if M.config.follow_cursor then
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      group = state.augroup,
      buffer = state.src_buf,
      callback = schedule_follow,
    })
  end

  -- first paint once typst has produced its initial output
  vim.defer_fn(render, 400)
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
  if state.timer then
    pcall(function()
      state.timer:stop()
      state.timer:close()
    end)
    state.timer = nil
  end
  if state.follow_timer then
    pcall(function()
      state.follow_timer:stop()
      state.follow_timer:close()
    end)
    state.follow_timer = nil
  end
  state.querying, state.query_pending = false, false
  clear_image()
  if state.watcher then
    pcall(function()
      state.watcher:stop()
      state.watcher:close()
    end)
    state.watcher = nil
  end
  if state.job then
    pcall(function()
      state.job:kill(15)
    end)
    state.job = nil
  end
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    pcall(vim.api.nvim_win_close, state.win, true)
  end
  if state.dir then
    pcall(vim.fn.delete, state.dir, "rf")
  end
  state.win, state.buf, state.dir, state.src, state.src_buf = nil, nil, nil, nil, nil
  state.page, state.pages = 1, 0
end

function M.toggle()
  if state.active then
    M.stop()
  else
    M.start()
  end
end

function M.next_page()
  if state.active and state.page < state.pages then
    state.page = state.page + 1
    render()
  end
end

function M.prev_page()
  if state.active and state.page > 1 then
    state.page = state.page - 1
    render()
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  vim.api.nvim_create_user_command("TypstPreviewTerm", M.toggle, { desc = "Toggle typst terminal preview" })
  vim.api.nvim_create_user_command("TypstPreviewTermStop", M.stop, { desc = "Stop typst terminal preview" })

  if M.config.toggle_keymap then
    vim.keymap.set("n", M.config.toggle_keymap, M.toggle, { desc = "Toggle typst terminal preview" })
  end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = M.stop,
  })
end

return M
