local global_config = require("dressing.config")

local function get_backend(config)
  local backends = config.backend
  if type(backends) ~= "table" then
    backends = { backends }
  end
  for _, backend in ipairs(backends) do
    local ok, mod = pcall(require, string.format("dressing.select.%s", backend))
    if ok and mod.is_supported() then
      return mod, backend
    end
  end
  return require("dressing.select.builtin"), "builtin"
end

return function(items, opts, on_choice)
  vim.validate({
    items = {
      items,
      function(a)
        return type(a) == "table" and vim.tbl_islist(a)
      end,
      "list-like table",
    },
    on_choice = { on_choice, "function", false },
  })
  opts = opts or {}
  local config = global_config.get_mod_config("select", opts)
  opts.prompt = opts.prompt or "Select one of:"
  if opts.format_item then
    -- Make format_item doesn't *technically* have to return a string for the
    -- core implementation. We should maintain compatibility by wrapping the
    -- return value with tostring
    local format_item = opts.format_item
    opts.format_item = function(item)
      return tostring(format_item(item))
    end
  else
    opts.format_item = tostring
  end

  local backend, name = get_backend(config)
  backend.select(config[name], items, opts, on_choice)
end
