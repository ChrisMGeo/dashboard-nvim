local api = vim.api
local utils = require('dashboard.utils')
local header_module = require('dashboard.theme.header')
local background_module = require('dashboard.theme.background')

local function get_center(config)
  local center_config = config.center
    or {
      { desc = 'Please config your own center section', key = 'p' },
    }
  local items = center_config.items or center_config
  local alignment = center_config.alignment or 'center'
  local in_alignment = center_config.in_alignment or 'left'
  local key_format = center_config.key_format or ' [%s]'
  return {
    items = items,
    alignment = alignment,
    in_alignment = in_alignment,
    key_format = key_format,
  }
end

local function generate_center(config, first_line)
  local lines = {}
  local center_config = get_center(config)
  local items = center_config.items
  local alignment = center_config.alignment
  local in_alignment = center_config.in_alignment
  local key_format = center_config.key_format

  local counts = {}
  for _, item in pairs(items) do
    local count = item.keymap and #item.keymap or 0
    local line = (item.icon or '') .. item.desc

    if item.key then
      line = line .. (' '):rep(#item.key + 4)
      count = count + #item.key + 3
      if type(item.action) == 'string' then
        vim.keymap.set('n', item.key, function()
          local dump = loadstring(item.action)
          if not dump then
            vim.cmd(item.action)
          else
            dump()
          end
        end, { buffer = config.bufnr, nowait = true, silent = true })
      elseif type(item.action) == 'function' then
        vim.keymap.set(
          'n',
          item.key,
          item.action,
          { buffer = config.bufnr, nowait = true, silent = true }
        )
      end
    end

    if item.keymap then
      line = line .. (' '):rep(#item.keymap)
    end

    table.insert(lines, line)
    table.insert(lines, '')
    table.insert(counts, count)
    table.insert(counts, 0)
  end

  lines = utils.align_lines(lines, in_alignment, true)
  -- lines = utils.element_align(lines)
  -- lines = utils.center_align(lines)
  for i, count in ipairs(counts) do
    lines[i] = lines[i]:sub(1, #lines[i] - count)
  end
  -- print(vim.inspect(lines))

  first_line = first_line or api.nvim_buf_line_count(config.bufnr)
  local extents = utils.buf_set_aligned_lines(lines, config.bufnr, first_line, -1, false, alignment)

  if not items then
    return
  end

  local ns = api.nvim_create_namespace('DashboardDoom')
  local seed = 0
  local pos_map = {}
  for i = 1, #lines do
    if lines[i]:find('%w') then
      local idx = i == 1 and i or i - seed
      seed = seed + 1
      pos_map[i] = idx
      local scol = extents[i].col_start
      -- local _, scol = lines[i]:find('%s+', extents[i].col_start + 1)
      local ecol = scol + (items[idx].icon and api.nvim_strwidth(items[idx].icon) or 0)

      if items[idx].icon then
        api.nvim_buf_add_highlight(
          config.bufnr,
          0,
          items[idx].icon_hl or 'DashboardIcon',
          first_line + i - 1,
          scol,
          ecol
        )
      end

      api.nvim_buf_add_highlight(
        config.bufnr,
        0,
        items[idx].desc_hl or 'DashboardDesc',
        first_line + i - 1,
        ecol,
        extents[i].col_end
      )

      if items[idx].key then
        local virt_tbl = {}
        if items[idx].keymap then
          table.insert(virt_tbl, { items[idx].keymap, 'DashboardShortCut' })
        end
        table.insert(virt_tbl, {
          string.format(items[idx].key_format or key_format, items[idx].key),
          items[idx].key_hl or 'DashboardKey',
        })
        api.nvim_buf_set_extmark(config.bufnr, ns, first_line + i - 1, 0, {
          virt_text_pos = 'eol',
          virt_text = virt_tbl,
        })
      end
    end
  end

  local col = extents[1].col_start + api.nvim_strwidth(items[1].icon or '')
  col = col and col - 1 or 9999
  api.nvim_win_set_cursor(config.winid, { first_line + 1, col })

  local bottom = first_line + 2 * #items
  vim.defer_fn(function()
    local before = 0
    if api.nvim_get_current_buf() ~= config.bufnr then
      return
    end
    api.nvim_create_autocmd('CursorMoved', {
      buffer = config.bufnr,
      callback = function()
        local curline = api.nvim_win_get_cursor(0)[1]
        if curline < first_line + 1 then
          curline = bottom - 1
        elseif curline > bottom - 1 then
          curline = first_line + 1
        elseif not api.nvim_get_current_line():find('%w') then
          curline = curline + (before > curline and -1 or 1)
        end
        before = curline
        api.nvim_win_set_cursor(config.winid, { curline, col })
      end,
    })
  end, 0)

  vim.keymap.set('n', config.confirm_key or '<CR>', function()
    local curline = api.nvim_win_get_cursor(0)[1]
    local index = pos_map[curline - first_line]
    if index and items[index].action then
      if type(items[index].action) == 'string' then
        local dump = loadstring(items[index].action)
        if not dump then
          vim.cmd(items[index].action)
        else
          dump()
        end
      elseif type(items[index].action) == 'function' then
        items[index].action()
      else
        print('Error with action, check your config')
      end
    end
  end, { buffer = config.bufnr, nowait = true, silent = true })
end

local function get_footer(config)
  local package_manager_stats = utils.get_package_manager_stats()
  local footer = {}
  if package_manager_stats.name == 'lazy' then
    footer = {
      '',
      '',
      'Startuptime: ' .. package_manager_stats.time .. ' ms',
      'Plugins: '
        .. package_manager_stats.loaded
        .. ' loaded / '
        .. package_manager_stats.count
        .. ' installed',
    }
  else
    footer = {
      '',
      'neovim loaded ' .. package_manager_stats.count .. ' plugins',
    }
  end
  if config.footer then
    if type(config.footer) == 'function' then
      footer = config.footer()
    elseif type(config.footer) == 'string' then
      local dump = loadstring(config.footer)
      if dump then
        footer = dump()
      end
    elseif type(config.footer) == 'table' then
      footer = config.footer
    end
  end
  return footer
end

local function generate_footer(config, first_line)
  first_line = first_line or api.nvim_buf_line_count(config.bufnr)
  local footer = get_footer(config)
  local extents = utils.buf_set_aligned_lines(footer, config.bufnr, first_line)
  for i, extent in pairs(extents) do
    api.nvim_buf_add_highlight(
      config.bufnr,
      0,
      'DashboardFooter',
      first_line + i - 1,
      extent.col_start,
      extent.col_end
    )
  end
end

---@private
local function theme_instance(config)
  utils.turn_modifiable_on(config.bufnr)
  local header_config = header_module.get_header(config)
  local header_height = #header_config.lines
  local center_config = get_center(config)
  local center_height = 2 * #center_config.items
  local footer_config = get_footer(config)
  local footer_height = #footer_config
  background_module.generate_background(
    config,
    header_height + 1 + center_height + 1 + footer_height + 1 + vim.o.lines
  )
  header_module.generate_header(config)
  generate_center(config, header_height + 1)
  generate_footer(config, header_height + 1 + center_height + 1)
  api.nvim_set_option_value('modifiable', false, { buf = config.bufnr })
  api.nvim_set_option_value('modified', false, { buf = config.bufnr })
  --defer until next event loop
  vim.schedule(function()
    api.nvim_exec_autocmds('User', {
      pattern = 'DashboardLoaded',
      modeline = false,
    })
  end)
end

return setmetatable({}, {
  __call = function(_, t)
    return theme_instance(t)
  end,
})
