-- Native Neovim port of danilo-augusto/vim-afterglow, hand-extracted rather
-- than pulled in as a plugin. The original targets legacy vim-regex syntax
-- groups across a couple dozen languages; we highlight via Treesitter
-- instead, and Treesitter's default captures already link to the base
-- groups set below, so there's no need to carry over the per-language
-- groups (rubySymbol, pythonBuiltin, etc.) from the source theme.

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.background = "dark"
vim.g.colors_name = "afterglow"

local p = {
  fg = "#d6d6d6",
  bg = "#1a1a1a",
  selection = "#5a647e",
  line = "#393939",
  comment = "#797979",
  red = "#ac4142",
  orange = "#e87d3e",
  yellow = "#e5b567",
  green = "#b4c973",
  blue = "#6c99bb",
  wine = "#b05279",
  purple = "#9e86c8",
  window = "#4d5057",
}

local hl = vim.api.nvim_set_hl

-- UI
hl(0, "Normal", { fg = p.fg, bg = p.bg })
hl(0, "NormalFloat", { fg = p.fg, bg = p.bg })
hl(0, "FloatBorder", { fg = p.window, bg = p.bg })
hl(0, "CursorLine", { bg = p.line })
hl(0, "CursorLineNr", { fg = p.orange })
hl(0, "CursorColumn", { bg = p.line })
hl(0, "ColorColumn", { bg = p.line })
hl(0, "LineNr", { fg = p.comment, bg = p.bg })
hl(0, "SignColumn", { bg = p.bg })
hl(0, "Visual", { bg = p.selection })
hl(0, "Search", { fg = p.bg, bg = p.yellow })
hl(0, "IncSearch", { link = "Search" })
hl(0, "MatchParen", { bg = p.selection })
hl(0, "Folded", { fg = p.comment, bg = p.bg })
hl(0, "FoldColumn", { bg = p.bg })
-- Original applies these fg/bg pairs with a `reverse` attribute layered on
-- top; baking in the already-swapped visual result directly is equivalent
-- and simpler than replicating the reverse flag.
hl(0, "StatusLine", { fg = p.yellow, bg = p.window })
hl(0, "StatusLineNC", { fg = p.fg, bg = p.window })
hl(0, "TabLine", { fg = p.fg, bg = p.window })
hl(0, "TabLineFill", { fg = p.fg, bg = p.window })
hl(0, "TabLineSel", { fg = p.bg, bg = p.orange })
hl(0, "WinSeparator", { fg = p.window, bg = p.window })
hl(0, "Pmenu", { fg = p.fg, bg = p.selection })
hl(0, "PmenuSel", { fg = p.selection, bg = p.fg })

-- Syntax (base groups; Treesitter's default @capture links inherit these)
hl(0, "Comment", { fg = p.comment })
hl(0, "Constant", { fg = p.purple })
hl(0, "String", { fg = p.yellow })
hl(0, "Identifier", { fg = p.orange })
hl(0, "Statement", { fg = p.wine })
hl(0, "Conditional", { fg = p.wine })
hl(0, "Repeat", { fg = p.wine })
hl(0, "Structure", { fg = p.wine })
hl(0, "Function", { fg = p.orange })
hl(0, "Operator", { fg = p.purple })
hl(0, "Keyword", { fg = p.orange })
hl(0, "Type", { fg = p.blue })
hl(0, "StorageClass", { fg = p.orange })
hl(0, "PreProc", { fg = p.green })
hl(0, "Define", { fg = p.wine })
hl(0, "Include", { fg = p.wine })
hl(0, "Special", { fg = p.blue })
hl(0, "Tag", { fg = p.orange, bold = true })
hl(0, "Underlined", { fg = p.orange, underline = true })
hl(0, "Title", { fg = p.comment, bold = true })
hl(0, "Todo", { fg = p.red, bg = p.bg, bold = true })

-- Diagnostics (didn't exist when the source theme was written in 2017;
-- mapped onto the same accent palette)
hl(0, "DiagnosticError", { fg = p.red })
hl(0, "DiagnosticWarn", { fg = p.orange })
hl(0, "DiagnosticInfo", { fg = p.blue })
hl(0, "DiagnosticHint", { fg = p.purple })
hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = p.red })
hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = p.orange })
hl(0, "DiagnosticUnderlineInfo", { undercurl = true, sp = p.blue })
hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = p.purple })

-- Diff
hl(0, "DiffAdd", { bg = "#4c4e39" })
hl(0, "DiffChange", { bg = "#2b5b77" })
hl(0, "DiffDelete", { fg = p.bg, bg = p.red })
hl(0, "DiffText", { fg = p.line, bg = p.blue })

-- gitsigns.nvim (the source theme targeted vim-gitgutter's group names;
-- these are gitsigns' actual groups)
hl(0, "GitSignsAdd", { fg = p.green })
hl(0, "GitSignsChange", { fg = p.yellow })
hl(0, "GitSignsDelete", { fg = p.red })
