local ts_utils = require "nvim-treesitter.ts_utils"

local M = {}

local function_declaration_snippet = function(node)
  -- require luasnip
  local ls = require "luasnip"
  local s = ls.s
  local fmt = require("luasnip.extras.fmt").fmt
  local i = ls.insert_node

  local returns_something = false

  -- basic description
  local snippet_text = { "--- {}" }
  local snippet_params = {}
  table.insert(snippet_params, i(1, "function description"))
  local insert_node_count = 1

  -- parse parameters
  local children = ts_utils.get_named_children(node)
  local parameters = nil
  for _, v in ipairs(children) do
    if v:type() == "parameters" then
      parameters = ts_utils.get_named_children(v)
    end

    -- does the function return something?
    if v:type() == "block" then
      for _, v2 in ipairs(ts_utils.get_named_children(v)) do
        if v2:type() == "return_statement" then
          returns_something = true
        end
      end
    end
  end

  -- parse parameters
  for _, v in ipairs(parameters) do
    if v:type() == "identifier" then
      local c = "-- @" .. ts_utils.get_node_text(v)[1] .. " {}"
      table.insert(snippet_text, c)
      insert_node_count = insert_node_count + 1
      table.insert(snippet_params, i(insert_node_count))
    end
  end

  if returns_something then
    table.insert(snippet_text, "-- @return {}")
    insert_node_count = insert_node_count + 1
    table.insert(snippet_params, i(insert_node_count))
  end

  snippet_text = table.concat(snippet_text, "\n")
  P(snippet_text)

  local snippet = s("", fmt(snippet_text, snippet_params))

  return { result = snippet, type = "luasnip" }
end

M.function_declaration = function(node, options)
  if options.luasnip_enabled then
    return function_declaration_snippet(node)
  end
end

return M
