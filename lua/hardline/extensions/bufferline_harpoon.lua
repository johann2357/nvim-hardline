local ok, HarpoonMarked = pcall(require, 'harpoon.mark')
if not ok then HarpoonMarked = nil end

local fmt = string.format

local function get_path_variations(input_path)
    local variations = {}
    local parts = vim.fn.split(input_path, "/")
    for i, _ in ipairs(parts) do
        local modified_path = table.concat(parts, "/", i)
        table.insert(variations, 1, modified_path)
    end
    return variations
end

local function unique_tail(buffers)
  local counts = {}
  local path_variations = {}
  for _, buffer in ipairs(buffers) do
    if buffer.name ~= '(empty)' then
        path_variations[buffer.name] = get_path_variations(buffer.name)
        for _, variation in ipairs(path_variations[buffer.name]) do
            counts[variation] = (counts[variation] or 0) + 1
        end
    end
  end
  for _, buffer in ipairs(buffers) do
    local name = vim.fn.fnamemodify(buffer.name, ":t")
    if counts[name] == 1 then
      buffer.name = vim.fn.fnamemodify(name, ":t")
    else
      for _, variation in ipairs(path_variations[buffer.name]) do
          if counts[variation] == 1 then
              buffer.name = variation
              break
          end
      end
      buffer.name = buffer.name
    end
  end
end

local function get_buffers(settings)
  if not HarpoonMarked then
    local bufferline = require('hardline.bufferline')
    return bufferline.get_buffers(settings)
  end

  local buffers = {}
  for idx = 1, HarpoonMarked.get_length() do
    local file = HarpoonMarked.get_marked_file_name(idx)
    if file == '' then
      file = '(empty)'
    end
    local buffer_name = fmt('%s', file)
    local buffer_nr = vim.fn.bufnr(buffer_name)
    table.insert(buffers, {
      bufnr = buffer_nr,
      name = buffer_name,
      harpoonidx = idx,
      current = buffer_nr == vim.fn.bufnr('%'),
      flags = {
        modified = vim.fn.getbufvar(buffer_nr, '&modified') == 1,
        modifiable = vim.fn.getbufvar(buffer_nr, '&modifiable') == 1,
        readonly = vim.fn.getbufvar(buffer_nr, '&readonly') == 1,
      },
    })
  end
  unique_tail(buffers)
  return buffers
end

return {
  get_buffers = get_buffers,
}
