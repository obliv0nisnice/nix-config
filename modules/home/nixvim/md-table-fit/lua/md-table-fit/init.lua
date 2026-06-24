-- md-table-fit: in-buffer markdown table renderer that fits the window width.
-- It wraps cell content inside fixed-width columns and keeps the borders intact
-- on every wrapped line -- something neovim's 'wrap' / render-markdown cannot do.
-- The raw table lines are concealed and the rendered table is drawn as
-- virt_lines; the table under the cursor is left raw so it can be edited.

local M = {}

local ns

local function disp(s)
  return vim.fn.strdisplaywidth(s)
end

-- split a table row into trimmed cells (naive: does not handle escaped \| )
local function split_cells(line)
  local s = line:gsub("^%s*|", ""):gsub("|%s*$", "")
  local cells = {}
  for cell in (s .. "|"):gmatch("(.-)|") do
    cells[#cells + 1] = vim.trim(cell)
  end
  return cells
end

local function is_delim(line)
  return line:match("^[%s|:%-]+$") ~= nil and line:find("%-") ~= nil
end

local function align_of(cell)
  local l = cell:sub(1, 1) == ":"
  local r = cell:sub(-1) == ":"
  if l and r then
    return "center"
  elseif r then
    return "right"
  else
    return "left"
  end
end

-- word-wrap a cell to a display width, hard-splitting overly long tokens
local function wrap_cell(s, w)
  s = vim.trim(s)
  if w < 1 then
    w = 1
  end
  if s == "" then
    return { "" }
  end
  local lines, cur = {}, ""
  for _, word in ipairs(vim.split(s, "%s+", { trimempty = true })) do
    while disp(word) > w do
      local take, i, n = "", 0, vim.fn.strchars(word)
      while i < n do
        local ch = vim.fn.strcharpart(word, i, 1)
        if disp(take .. ch) > w then
          break
        end
        take, i = take .. ch, i + 1
      end
      if take == "" then
        take, i = vim.fn.strcharpart(word, 0, 1), 1
      end
      if cur ~= "" then
        lines[#lines + 1], cur = cur, ""
      end
      lines[#lines + 1] = take
      word = vim.fn.strcharpart(word, i)
    end
    if word ~= "" then
      if cur == "" then
        cur = word
      elseif disp(cur .. " " .. word) <= w then
        cur = cur .. " " .. word
      else
        lines[#lines + 1], cur = cur, word
      end
    end
  end
  if cur ~= "" then
    lines[#lines + 1] = cur
  end
  if #lines == 0 then
    lines = { "" }
  end
  return lines
end

local function pad(s, w, align)
  local total = math.max(0, w - disp(s))
  if align == "right" then
    return string.rep(" ", total) .. s
  elseif align == "center" then
    local left = math.floor(total / 2)
    return string.rep(" ", left) .. s .. string.rep(" ", total - left)
  end
  return s .. string.rep(" ", total)
end

local function parse(buf, srow, erow)
  local lines = vim.api.nvim_buf_get_lines(buf, srow, erow + 1, false)
  local rows, aligns, ncol, header_count = {}, {}, 0, 0
  local seen_delim = false
  for _, line in ipairs(lines) do
    if is_delim(line) then
      seen_delim = true
      for i, dc in ipairs(split_cells(line)) do
        aligns[i] = align_of(dc)
      end
    else
      local cells = split_cells(line)
      if #cells > ncol then
        ncol = #cells
      end
      rows[#rows + 1] = cells
      if not seen_delim then
        header_count = header_count + 1
      end
    end
  end
  for c = 1, ncol do
    aligns[c] = aligns[c] or "left"
  end
  return rows, header_count, aligns, ncol
end

local function compute_widths(rows, ncol, avail)
  local nat = {}
  for c = 1, ncol do
    nat[c] = 1
  end
  for _, row in ipairs(rows) do
    for c = 1, ncol do
      local w = disp(row[c] or "")
      if w > nat[c] then
        nat[c] = w
      end
    end
  end
  local content = avail - (ncol + 1) - (2 * ncol) -- borders + padding
  if content < ncol then
    return nil
  end
  local sum = 0
  for c = 1, ncol do
    sum = sum + nat[c]
  end
  if sum <= content then
    return nat
  end
  -- keep columns narrower than their fair share at natural width; distribute
  -- the remaining budget among the wide columns so short headers stay readable.
  local width, fixed = {}, {}
  local remaining, free = content, ncol
  local changed = true
  while changed and free > 0 do
    changed = false
    local fair = remaining / free
    for c = 1, ncol do
      if not fixed[c] and nat[c] <= fair then
        width[c], fixed[c] = nat[c], true
        remaining, free = remaining - nat[c], free - 1
        changed = true
      end
    end
  end
  if free > 0 then
    local each, extra = math.floor(remaining / free), remaining % free
    for c = 1, ncol do
      if not fixed[c] then
        width[c] = math.max(3, each + (extra > 0 and 1 or 0))
        extra = extra > 0 and extra - 1 or 0
      end
    end
  end
  return width
end

local function hline(widths, left, mid, right)
  local parts = {}
  for c = 1, #widths do
    parts[c] = string.rep("─", widths[c] + 2)
  end
  return left .. table.concat(parts, mid) .. right
end

local function row_vis_lines(cells, widths, aligns)
  local wrapped, height = {}, 1
  for c = 1, #widths do
    wrapped[c] = wrap_cell(cells[c] or "", widths[c])
    if #wrapped[c] > height then
      height = #wrapped[c]
    end
  end
  local out = {}
  for k = 1, height do
    local segs = {}
    for c = 1, #widths do
      segs[c] = " " .. pad(wrapped[c][k] or "", widths[c], aligns[c]) .. " "
    end
    out[#out + 1] = "│" .. table.concat(segs, "│") .. "│"
  end
  return out
end

local function build(rows, header_count, widths, aligns)
  local vl = {}
  local function add(str, hl)
    vl[#vl + 1] = { { str, hl } }
  end
  add(hline(widths, "┌", "┬", "┐"), "RenderMarkdownTableHead")
  for i = 1, header_count do
    for _, l in ipairs(row_vis_lines(rows[i], widths, aligns)) do
      add(l, "RenderMarkdownTableHead")
    end
  end
  add(hline(widths, "├", "┼", "┤"), "RenderMarkdownTableHead")
  for i = header_count + 1, #rows do
    for _, l in ipairs(row_vis_lines(rows[i], widths, aligns)) do
      add(l, "RenderMarkdownTableRow")
    end
  end
  add(hline(widths, "└", "┴", "┘"), "RenderMarkdownTableRow")
  return vl
end

local function find_tables(buf)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, "markdown")
  if not ok or not parser then
    return {}
  end
  local trees = parser:parse()
  if not trees or not trees[1] then
    return {}
  end
  local q = vim.treesitter.query.parse("markdown", "(pipe_table) @t")
  local res = {}
  for _, node in q:iter_captures(trees[1]:root(), buf, 0, -1) do
    local sr, _, er, ec = node:range()
    res[#res + 1] = { srow = sr, erow = (ec == 0) and (er - 1) or er }
  end
  return res
end

function M.render(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  if vim.bo[buf].filetype ~= "markdown" then
    return
  end

  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(win) ~= buf then
    return
  end
  if vim.wo[win].conceallevel < 2 then
    vim.wo[win].conceallevel = 2
  end
  local avail = vim.api.nvim_win_get_width(win) - 2
  local cursor = vim.api.nvim_win_get_cursor(win)[1] - 1

  for _, t in ipairs(find_tables(buf)) do
    -- leave the table under the cursor raw for editing
    if not (cursor >= t.srow and cursor <= t.erow) then
      local rows, header_count, aligns, ncol = parse(buf, t.srow, t.erow)
      local widths = ncol > 0 and compute_widths(rows, ncol, avail) or nil
      if widths then
        local vl = build(rows, header_count, widths, aligns)
        for l = t.srow, t.erow do
          pcall(vim.api.nvim_buf_set_extmark, buf, ns, l, 0, { conceal_lines = "" })
        end
        -- attach the overlay to a line OUTSIDE the concealed range, else the
        -- virt_lines are hidden along with their (concealed) host line.
        local nlines = vim.api.nvim_buf_line_count(buf)
        local anchor, above
        if t.erow + 1 < nlines then
          anchor, above = t.erow + 1, true
        elseif t.srow > 0 then
          anchor, above = t.srow - 1, false
        else
          anchor, above = t.srow, true
        end
        pcall(vim.api.nvim_buf_set_extmark, buf, ns, anchor, 0, {
          virt_lines = vl,
          virt_lines_above = above,
        })
      end
    end
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", { enabled = true }, opts or {})
  if not M.config.enabled then
    return
  end
  ns = vim.api.nvim_create_namespace("md_table_fit")
  local grp = vim.api.nvim_create_augroup("MdTableFit", { clear = true })
  vim.api.nvim_create_autocmd({
    "BufEnter",
    "BufWinEnter",
    "TextChanged",
    "TextChangedI",
    "CursorMoved",
    "CursorMovedI",
    "WinResized",
  }, {
    group = grp,
    callback = function(ev)
      if vim.bo[ev.buf].filetype == "markdown" then
        M.render(ev.buf)
      end
    end,
  })
end

return M
