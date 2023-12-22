local api = vim.api
local utils = require('dashboard.utils')

local function week_ascii_text()
  return {
    ['Monday'] = {
      '',
      '███╗   ███╗ ██████╗ ███╗   ██╗██████╗  █████╗ ██╗   ██╗',
      '████╗ ████║██╔═══██╗████╗  ██║██╔══██╗██╔══██╗╚██╗ ██╔╝',
      '██╔████╔██║██║   ██║██╔██╗ ██║██║  ██║███████║ ╚████╔╝ ',
      '██║╚██╔╝██║██║   ██║██║╚██╗██║██║  ██║██╔══██║  ╚██╔╝  ',
      '██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██████╔╝██║  ██║   ██║   ',
      '╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ',
      '',
    },
    ['Tuesday'] = {
      '',
      '████████╗██╗   ██╗███████╗███████╗██████╗  █████╗ ██╗   ██╗',
      '╚══██╔══╝██║   ██║██╔════╝██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝',
      '   ██║   ██║   ██║█████╗  ███████╗██║  ██║███████║ ╚████╔╝ ',
      '   ██║   ██║   ██║██╔══╝  ╚════██║██║  ██║██╔══██║  ╚██╔╝  ',
      '   ██║   ╚██████╔╝███████╗███████║██████╔╝██║  ██║   ██║   ',
      '   ╚═╝    ╚═════╝ ╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ',
      '',
    },
    ['Wednesday'] = {
      '',
      '██╗    ██╗███████╗██████╗ ███╗   ██╗███████╗███████╗██████╗  █████╗ ██╗   ██╗',
      '██║    ██║██╔════╝██╔══██╗████╗  ██║██╔════╝██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝',
      '██║ █╗ ██║█████╗  ██║  ██║██╔██╗ ██║█████╗  ███████╗██║  ██║███████║ ╚████╔╝ ',
      '██║███╗██║██╔══╝  ██║  ██║██║╚██╗██║██╔══╝  ╚════██║██║  ██║██╔══██║  ╚██╔╝  ',
      '╚███╔███╔╝███████╗██████╔╝██║ ╚████║███████╗███████║██████╔╝██║  ██║   ██║   ',
      ' ╚══╝╚══╝ ╚══════╝╚═════╝ ╚═╝  ╚═══╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ',
      '',
    },
    ['Thursday'] = {
      '',
      '████████╗██╗  ██╗██╗   ██╗██████╗ ███████╗██████╗  █████╗ ██╗   ██╗',
      '╚══██╔══╝██║  ██║██║   ██║██╔══██╗██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝',
      '   ██║   ███████║██║   ██║██████╔╝███████╗██║  ██║███████║ ╚████╔╝ ',
      '   ██║   ██╔══██║██║   ██║██╔══██╗╚════██║██║  ██║██╔══██║  ╚██╔╝  ',
      '   ██║   ██║  ██║╚██████╔╝██║  ██║███████║██████╔╝██║  ██║   ██║   ',
      '   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ',
      '',
    },
    ['Friday'] = {
      '',
      '███████╗██████╗ ██╗██████╗  █████╗ ██╗   ██╗',
      '██╔════╝██╔══██╗██║██╔══██╗██╔══██╗╚██╗ ██╔╝',
      '█████╗  ██████╔╝██║██║  ██║███████║ ╚████╔╝ ',
      '██╔══╝  ██╔══██╗██║██║  ██║██╔══██║  ╚██╔╝  ',
      '██║     ██║  ██║██║██████╔╝██║  ██║   ██║   ',
      '╚═╝     ╚═╝  ╚═╝╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ',
      '',
    },
    ['Saturday'] = {
      '',
      '███████╗ █████╗ ████████╗██╗   ██╗██████╗ ██████╗  █████╗ ██╗   ██╗',
      '██╔════╝██╔══██╗╚══██╔══╝██║   ██║██╔══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝',
      '███████╗███████║   ██║   ██║   ██║██████╔╝██║  ██║███████║ ╚████╔╝ ',
      '╚════██║██╔══██║   ██║   ██║   ██║██╔══██╗██║  ██║██╔══██║  ╚██╔╝  ',
      '███████║██║  ██║   ██║   ╚██████╔╝██║  ██║██████╔╝██║  ██║   ██║   ',
      '╚══════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ',
      '',
    },
    ['Sunday'] = {
      '',
      '███████╗██╗   ██╗███╗   ██╗██████╗  █████╗ ██╗   ██╗',
      '██╔════╝██║   ██║████╗  ██║██╔══██╗██╔══██╗╚██╗ ██╔╝',
      '███████╗██║   ██║██╔██╗ ██║██║  ██║███████║ ╚████╔╝ ',
      '╚════██║██║   ██║██║╚██╗██║██║  ██║██╔══██║  ╚██╔╝  ',
      '███████║╚██████╔╝██║ ╚████║██████╔╝██║  ██║   ██║   ',
      '╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ',
      '',
    },
  }
end

local function default_header()
  return {
    '',
    ' ██████╗  █████╗ ███████╗██╗  ██╗██████╗  ██████╗  █████╗ ██████╗ ██████╗  ',
    ' ██╔══██╗██╔══██╗██╔════╝██║  ██║██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██╔══██╗ ',
    ' ██║  ██║███████║███████╗███████║██████╔╝██║   ██║███████║██████╔╝██║  ██║ ',
    ' ██║  ██║██╔══██║╚════██║██╔══██║██╔══██╗██║   ██║██╔══██║██╔══██╗██║  ██║ ',
    ' ██████╔╝██║  ██║███████║██║  ██║██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝ ',
    ' ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ',
    '',
  }
end

local function week_header(concat, append)
  local week = week_ascii_text()
  local daysoftheweek =
    { 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' }
  local day = daysoftheweek[os.date('*t').wday]
  local tbl = week[day]
  table.insert(tbl, os.date('%Y-%m-%d %H:%M:%S ') .. (concat or ''))
  if append then
    vim.list_extend(tbl, append)
  end
  table.insert(tbl, '')
  return tbl
end

local function get_header(config)
  if not config.command then
    local header_config = config.week_header
        and config.week_header.enable
        and week_header(config.week_header.concat, config.week_header.append)
      or (config.header or default_header())
    local lines = header_config.lines or header_config
    local alignment = header_config.alignment or 'center'
    local in_alignment = header_config.in_alignment or 'left'
    return { lines = lines, alignment = alignment, in_alignment = in_alignment }
  end

  local empty_table = utils.generate_empty_table(config.file_height + 4)
  return { lines = empty_table, alignment = 'center', in_alignment = 'center' }
end

local function generate_header(config)
  local header = get_header(config)
  if not config.command then
    local extents = utils.buf_set_aligned_lines(
      header.lines,
      config.bufnr,
      0,
      -1,
      false,
      header.alignment,
      header.in_alignment
    )
    for i, extent in pairs(extents) do
      vim.api.nvim_buf_add_highlight(
        config.bufnr,
        0,
        'DashboardHeader',
        i - 1,
        extent.col_start,
        extent.col_end
      )
    end
    return
  end
  api.nvim_buf_set_lines(config.bufnr, 0, -1, false, utils.center_align(header.lines))
  local preview = require('dashboard.preview')
  preview:open_preview({
    width = config.file_width,
    height = config.file_height,
    cmd = config.command .. ' ' .. config.file_path,
  })
end

return {
  generate_header = generate_header,
  get_header = get_header,
}
