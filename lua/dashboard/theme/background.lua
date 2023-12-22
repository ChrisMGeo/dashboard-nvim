local api = vim.api
local utils = require('dashboard.utils')

local function generate_background(config, min_height)
  min_height = min_height or 0
  if not config.command then
    local background = (config.background or {})
    local background_lines = background.lines or background
    local center = background.center ~= false
    local tile = background.tile == true
    local in_alignment = background.in_alignment or 'left'
    background_lines = utils.align_lines(background_lines, in_alignment, true)
    local final_lines = {}
    if tile then
      final_lines =
        utils.tile_lines(background_lines, vim.o.columns, math.max(vim.o.lines, min_height), center)
    else
      if center then
        final_lines = utils.center_align(background_lines)
      else
        final_lines = background_lines
      end
    end
    api.nvim_buf_set_lines(config.bufnr, 0, -1, false, final_lines)

    for i, _ in ipairs(background_lines) do
      vim.api.nvim_buf_add_highlight(config.bufnr, 0, 'DashboardBackground', i - 1, 0, -1)
    end
    return
  end

  local empty_table = utils.generate_empty_table(config.file_height + 4)
  api.nvim_buf_set_lines(config.bufnr, 0, -1, false, utils.center_align(empty_table))
  local preview = require('dashboard.preview')
  preview:open_preview({
    width = config.file_width,
    height = config.file_height,
    cmd = config.command .. ' ' .. config.file_path,
  })
end

return {
  generate_background = generate_background,
}
