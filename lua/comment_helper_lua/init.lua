local ts_utils = require "nvim-treesitter.ts_utils"

local M = {}

local function find_descendant(node, predicate)
  if node == nil then
    return nil
  end

  for _, v in ipairs(ts_utils.get_named_children(node)) do
    if predicate(v) then
      return v
    else
      local recurse = find_descendant(v, predicate)
      if recurse ~= nil then
        return recurse
      end
    end
  end
end

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
  end

  returns_something = find_descendant(node, function(n)
    return n:type() == "return_statement"
  end) ~= nil

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

  local snippet = s("", fmt(snippet_text, snippet_params))

  return { result = snippet, type = "luasnip" }
end

local assignment_statement_snippet = function(node)
  local children = ts_utils.get_named_children(node)
  for _, v in ipairs(children) do
    if v:type() == "expression_list" then
      for _, v2 in ipairs(ts_utils.get_named_children(v)) do
        if v2:type() == "function_definition" then
          return function_declaration_snippet(v2)
        end
      end
    end
  end
end

local variable_declaration_snippet = function(node)
  local children = ts_utils.get_named_children(node)
  for _, v in ipairs(children) do
    if v:type() == "assignment_statement" then
      return assignment_statement_snippet(v)
    end
  end
end

M.function_declaration = function(node, options)
  if options.luasnip_enabled then
    return function_declaration_snippet(node)
  end
end

M.variable_declaration = function(node, options)
  if options.luasnip_enabled then
    return variable_declaration_snippet(node)
  end
end

M.assignment_statement = function(node, options)
  if options.luasnip_enabled then
    return assignment_statement_snippet(node)
  end
end

return M
