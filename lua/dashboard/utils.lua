local uv = vim.loop
local utils = {}

utils.is_win = uv.os_uname().version:match('Windows')

function utils.path_join(...)
  local path_sep = utils.is_win and '\\' or '/'
  return table.concat({ ... }, path_sep)
end

function utils.element_align(tbl)
  local max = utils.get_max_len(tbl)
  local res = {}
  for _, item in pairs(tbl) do
    local len = vim.api.nvim_strwidth(item)
    local times = math.floor((max - len) / vim.api.nvim_strwidth(' '))
    item = item .. (' '):rep(times)
    table.insert(res, item)
  end
  return res
end

function utils.get_max_len(contents)
  vim.validate({
    contents = { contents, 't' },
  })
  local max_len = 0
  for _, v in pairs(contents) do
    local str_w = vim.api.nvim_strwidth(v)
    if str_w > max_len then
      max_len = str_w
    end
  end
  return max_len
end

-- draw the graphics into the screen center
function utils.center_align(tbl)
  vim.validate({
    tbl = { tbl, 'table' },
  })
  local function fill_sizes(lines)
    local fills = {}
    for _, line in pairs(lines) do
      table.insert(fills, math.floor((vim.o.columns - vim.api.nvim_strwidth(line)) / 2))
    end
    return fills
  end

  local centered_lines = {}
  local fills = fill_sizes(tbl)

  for i = 1, #tbl do
    local fill_line = (' '):rep(fills[i]) .. tbl[i]
    table.insert(centered_lines, fill_line)
  end

  return centered_lines
end

---@param lines string[]
---@param alignment Alignment
---@param fill_empty_lines boolean?
---@return string[]
function utils.align_lines(lines, alignment, fill_empty_lines)
  fill_empty_lines = fill_empty_lines == true
  local aligned_lines = {}
  local max_width = utils.get_max_len(lines)
  for _, line in ipairs(lines) do
    local line_w = vim.api.nvim_strwidth(line)
    local new_line = ''
    if #line == 0 and not fill_empty_lines then
      goto skip_to_insert
    end
    if alignment == 'center' then
      local padding_left = math.floor((max_width - line_w) / 2)
      new_line = string.rep(' ', math.floor(padding_left / vim.api.nvim_strwidth(' '))) .. line
      local new_line_w = vim.api.nvim_strwidth(new_line)
      new_line = new_line
        .. string.rep(' ', math.floor((max_width - new_line_w) / vim.api.nvim_strwidth(' ')))
    elseif alignment == 'left' then
      new_line = line
        .. string.rep(' ', math.floor((max_width - line_w) / vim.api.nvim_strwidth(' ')))
    elseif alignment == 'right' then
      new_line = string.rep(' ', math.floor((max_width - line_w) / vim.api.nvim_strwidth(' ')))
        .. line
    end
    ::skip_to_insert::
    table.insert(aligned_lines, new_line)
  end
  return aligned_lines
end

--- aligns block of text on top of previous content of buffer
---@param lines string[] block of text to insert
---@param buffer integer buffer number
---@param start number? line number to start from (zero-based index) (Default is 0)
---@param end_ number? line number to end replacing text for (zero-based index) (Default is -1)
---@param strict_indexing boolean? Whether an invalid index should be errored
---@param alignment Alignment? How to horizontally align block of text in relation to buffer
---@param in_alignment Alignment? How to horizontally align each line of lines in relation to the longest line (For block of text where lines may not be of equal length) TODO: Implement
---@return string[]
---@return Extent[]
function utils.align_conserve(lines, buffer, start, end_, strict_indexing, alignment, in_alignment)
  vim.validate({
    lines = { lines, 'table' },
  })
  local max_width = utils.get_max_len(lines)
  start = start or 0
  end_ = end_ or -1
  strict_indexing = strict_indexing == true
  alignment = alignment or 'center'
  in_alignment = in_alignment or 'center'
  lines = utils.align_lines(lines, in_alignment)
  local prev_lines = vim.api.nvim_buf_get_lines(buffer, start, end_, strict_indexing)
  ---@type string[]
  local aligned_lines = {}
  ---@type Extent[]
  local extents = {}
  for line_nr, line in ipairs(lines) do
    local new_line = ''
    local str_w = vim.api.nvim_strwidth(line)
    local padding_left = math.max(math.floor((vim.o.columns - str_w) / 2), 0)
    if alignment == 'right' then
      padding_left = math.max(vim.o.columns - max_width, 0)
    elseif alignment == 'left' then
      padding_left = 0
    end
    for i = 1, padding_left do
      new_line = new_line
        .. (
          (line_nr <= #prev_lines and line_nr >= 1 and i <= #prev_lines[line_nr])
            and prev_lines[line_nr]:sub(i, i)
          or ' '
        )
    end
    new_line = new_line .. line
    local col_end = vim.api.nvim_strwidth(new_line)
    for i = padding_left + str_w + 1, vim.api.nvim_strwidth((line_nr < #prev_lines) and prev_lines[line_nr] or '') do
      new_line = new_line
        .. (
          (
            line_nr <= #prev_lines
            and line_nr >= 1
            and i <= vim.api.nvim_strwidth(prev_lines[line_nr])
          ) and prev_lines[line_nr]:sub(i, i)
        )
    end
    table.insert(aligned_lines, new_line)
    table.insert(extents, { col_start = padding_left, col_end = col_end })
  end
  for line_nr = #lines + 1, #prev_lines do
    table.insert(aligned_lines, prev_lines[line_nr])
    table.insert(extents, { col_start = 0, col_end = 0 })
  end
  return aligned_lines, extents
end

---@param tbl string[] Lines can be of varying lengths/widths/sizes.
---@param columns integer
---@param lines integer
---@param center boolean
---@return string[]
function utils.tile_lines(tbl, columns, lines, center)
  local res = {}
  local height = #tbl
  local width = #tbl[1]
  local x_offset = 0
  local y_offset = 0
  if center then
    x_offset = math.floor((columns - width) / 2)
    y_offset = math.floor((lines - height) / 2)
  end
  for i = 0, (lines or 1) - 1 do
    local y = (i + y_offset) % height + 1
    local line = ''
    for j = 0, (columns or 1) - 1 do
      local x = (j + x_offset) % width + 1
      line = line .. tbl[y]:sub(x, x)
    end
    table.insert(res, line)
  end
  return res
end

---@param bufnr integer
function utils.turn_modifiable_on(bufnr)
  if not vim.bo[bufnr].modifiable then
    vim.bo[bufnr].modifiable = true
  end
end

---@param lines string[]
---@param buffer integer
---@param start number?
---@param end_ number?
---@param strict_indexing boolean?
---@param alignment Alignment?
---@param in_alignment Alignment?
function utils.buf_set_aligned_lines(
  lines,
  buffer,
  start,
  end_,
  strict_indexing,
  alignment,
  in_alignment
)
  start = start or 0
  end_ = end_ or -1
  strict_indexing = strict_indexing == true
  alignment = alignment or 'center'
  in_alignment = in_alignment or 'center'
  local replacement, extents =
    utils.align_conserve(lines, buffer, start, end_, strict_indexing, alignment, in_alignment)
  vim.api.nvim_buf_set_lines(buffer, start, end_, strict_indexing, replacement)
  return extents
end

function utils.get_icon(filename)
  local ok, devicons = pcall(require, 'nvim-web-devicons')
  if not ok then
    vim.notify('[dashboard.nvim] not found nvim-web-devicons')
    return nil
  end
  return devicons.get_icon(filename, nil, { default = true })
end

function utils.read_project_cache(path)
  local fd = assert(uv.fs_open(path, 'r', tonumber('644', 8)))
  local stat = uv.fs_fstat(fd)
  local chunk = uv.fs_read(fd, stat.size, 0)
  local dump = assert(loadstring(chunk))
  return dump()
end

function utils.async_read(path, callback)
  uv.fs_open(path, 'a+', 438, function(err, fd)
    assert(not err, err)
    uv.fs_fstat(fd, function(err, stat)
      assert(not err, err)
      uv.fs_read(fd, stat.size, 0, function(err, data)
        assert(not err, err)
        uv.fs_close(fd, function(err)
          assert(not err, err)
          callback(data)
        end)
      end)
    end)
  end)
end

function utils.disable_move_key(bufnr)
  local keys = { 'w', 'f', 'b', 'h', 'j', 'k', 'l', '<Up>', '<Down>', '<Left>', '<Right>' }
  vim.tbl_map(function(k)
    vim.keymap.set('n', k, '<Nop>', { buffer = bufnr })
  end, keys)
end

--- return the most recently files list
function utils.get_mru_list()
  local mru = {}
  for _, file in pairs(vim.v.oldfiles or {}) do
    if file and vim.fn.filereadable(file) == 1 then
      table.insert(mru, file)
    end
  end
  return mru
end

function utils.get_package_manager_stats()
  local package_manager_stats = { name = '', count = 0, loaded = 0, time = 0 }
  ---@diagnostic disable-next-line: undefined-global
  if packer_plugins then
    package_manager_stats.name = 'packer'
    ---@diagnostic disable-next-line: undefined-global
    package_manager_stats.count = #vim.tbl_keys(packer_plugins)
  end
  local status, lazy = pcall(require, 'lazy')
  if status then
    package_manager_stats.name = 'lazy'
    package_manager_stats.loaded = lazy.stats().loaded
    package_manager_stats.count = lazy.stats().count
    package_manager_stats.time = lazy.stats().startuptime
  end
  return package_manager_stats
end

--- generate an empty table by length
function utils.generate_empty_table(length)
  local empty_tbl = {}
  if length == 0 then
    return empty_tbl
  end

  for _ = 1, length do
    table.insert(empty_tbl, '')
  end
  return empty_tbl
end

function utils.generate_truncateline(cells)
  local char = '┉'
  return char:rep(math.floor(cells / vim.api.nvim_strwidth(char)))
end

function utils.get_vcs_root(buf)
  buf = buf or 0
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':p:h')
  local patterns = { '.git', '.hg', '.bzr', '.svn' }
  for _, pattern in pairs(patterns) do
    local root = vim.fs.find(pattern, { path = path, upward = true, stop = vim.env.HOME })
    if root then
      return root
    end
  end
end

local index = 0
function utils.gen_bufname(prefix)
  index = index + 1
  return prefix .. '-' .. index
end

function utils.buf_is_empty(bufnr)
  bufnr = bufnr or 0
  return vim.api.nvim_buf_line_count(0) == 1
    and vim.api.nvim_buf_get_lines(0, 0, -1, false)[1] == ''
end

return utils
