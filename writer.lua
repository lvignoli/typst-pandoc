-- A custom Pandoc Typst writer.
-- Louis Vignoli

-- Imports
-- This module is provided in Pandoc embedded Lua runtime.

local pandoc = require "pandoc"

-- For better performance we put these functions in local variables:

local layout = pandoc.layout

local blankline = layout.blankline
local concat = layout.concat
local cr = layout.cr
local double_quotes = layout.double_quotes
local empty = layout.empty
local hang = layout.hang
local inside = layout.inside
local literal = layout.literal
local nest = layout.nest
local parens = layout.parens
local prefixed = layout.prefixed
local space = layout.space
local to_roman = pandoc.utils.to_roman_numeral
local stringify = pandoc.utils.stringify

-- Default indent size for Typst generated code.
local TAB_SIZE = 2
local BLOCKQUOTE_BOX_RELATIVE_WIDTH = "97%"

-- Writer is the custom writer that Pandoc will use.
-- We scaffold it from Pandoc.
Writer = pandoc.scaffolding.Writer

local inlines = Writer.Inlines
local blocks = Writer.Blocks

-- escape escapes reserved Typst markup character with a backslash.
local escape = function(s)
	return (s:gsub("[#$\\'\"`_*]", function(x)
		return "\\" .. x
	end))
end

-- inline_wrap wraps a doc in a call to cmd using Typst content syntax.
-- Namely
-- cmd[doc]
-- Any additional # in cmd is the caller responsibility.
local inline_wrap = function(doc, cmd)
	cmd = cmd or "#"
	return concat { cmd .. "[", doc, "]" }
end

-- wrap wraps a doc in a call to cmd using Typst content blocks syntax.
-- Namely
-- cmd[
--   doc
-- ]
-- Any additional # in cmd is the caller responsibility.
local wrap = function(doc, cmd)
	cmd = cmd or "#"
	return concat { cmd .. "[", cr, nest(doc, TAB_SIZE), cr, "]" }
end

Writer.Block.Null = function(e)
	return empty
end

Writer.Block.Plain = function(el)
	return inlines(el.content)
end

Writer.Block.Para = function(para)
	return { Writer.Inlines(para.content), blankline }
end

Writer.Block.Header = function(header)
	return {
		string.rep("=", header.level),
		space,
		inlines(header.content),
	}
end

Writer.Block.BulletList = function(e)
	local function render_item(item)
		return concat { hang(blocks(item), TAB_SIZE, "- "), cr } -- hang allows to indent nested list properly
	end
	return e.content:map(render_item)
end

Writer.Block.OrderedList = function(e)
	local function render_item(item)
		return hang(blocks(item, blankline), TAB_SIZE, "+ ")
	end

	local sep = cr
	return concat(e.content:map(render_item), sep)
end

Writer.Block.DefinitionList = function(e)
	-- To simplify their treatment, blocks after the first one in definitions
	-- are put on the next line and indented by a single space. It is not very
	-- pretty (better would be to indent them by TAB_SIZE or up to the colon),
	-- but valid Typst syntax.
	local function render_term(term)
		return concat { concat { "/", space, inlines(term), ":" } }
	end
	local function render_definition(def)
		return concat { " ", blocks(def), cr }
	end
	local function render_item(item)
		local term, definitions = table.unpack(item)
		local inner = concat(definitions:map(render_definition))
		return concat { render_term(term), inner }
	end

	local sep = cr
	return concat(e.content:map(render_item), sep)
end

Writer.Block.CodeBlock = function(e)
	return { "```", e.classes[1], cr, nest(e.text, TAB_SIZE), cr, "```" }
end

Writer.Block.BlockQuote = function(e)
	-- Since there is no dedicated Typst markup, we retain the popular
	-- blockquote rendering of having an indented block in dimmed font with a
	-- light vertical ruler on the left.

	local indent = "#h(1fr)" -- filler space that pushes the box to the right
	local style = '#set text(style: "italic", fill: gray.darken(10%))'
	local citation = concat { style, cr, blocks(e.content), blankline }

	-- The choice of having a relative indent rather than an absolute one is debatable.
	-- It works well with current Typst default page layout.
	local box_cmd = string.format("#box(width: %s)", BLOCKQUOTE_BOX_RELATIVE_WIDTH)
	local box = concat { indent, cr, wrap(citation, box_cmd) }

	local stacked_content = wrap(box, "#stack(dir: ltr)")

	local rect_cmd = "#rect(stroke: (left:2pt+silver))"
	local result = wrap(stacked_content, rect_cmd)

	return result
end

Writer.Block.Div = function(e)
	return concat { blankline, wrap(blocks(e.content)), blankline }
end

Writer.Block.HorizontalRule = function(e)
	return { blankline, "#line(length: 100%)", blankline }
end

Writer.Inline.Str = function(e)
	return escape(e.text)
end

Writer.Inline.Space = space

Writer.Inline.SoftBreak = function(_, opts)
	return opts.wrap_text == "wrap-preserve" and cr or space
end

Writer.Inline.LineBreak = { space, "\\", cr }

Writer.Inline.Emph = function(el)
	return { "_", inlines(el.content), "_" }
end

Writer.Inline.Strong = function(el)
	return { "*", inlines(el.content), "*" }
end

Writer.Inline.Strikeout = function(el)
	return { inline_wrap(inlines(el.content), "#strike") }
end

Writer.Inline.Subscript = function(el)
	return { inline_wrap(inlines(el.content), "#sub") }
end

Writer.Inline.Superscript = function(el)
	return { inline_wrap(inlines(el.content), "#super") }
end

Writer.Inline.Underline = function(el)
	return { inline_wrap(inlines(el.content), "#underline") }
end

Writer.Inline.SmallCaps = function(el)
	return { inline_wrap(inlines(el.content), "#smallcaps") }
end

Writer.Inline.Link = function(link)
	local cmd = "#link" .. parens(double_quotes(link.target))
	return inline_wrap(inlines(link.content), cmd)
end

Writer.Inline.Span = function(el)
	return inlines(el.content)
end

Writer.Inline.Quoted = function(el)
	if el.quotetype == "DoubleQuote" then
		return concat { '"', inlines(el.content), '"' }
	else
		return concat { "'", inlines(el.content), "'" }
	end
end

Writer.Inline.Code = function(code)
	return { "`", code.text, "`" }
end

Writer.Inline.Math = function(math)
	-- Conversion between LaTeX math and Typst math is out of the scope of this
	-- writer. We return a dummy filler symbol.
	if math.mathtype == "DisplayMath" then
		return literal "$ quest.excl $"
	else
		return literal "$quest.excl$"
	end
end

Writer.Inline.Image = function(img)
	return { inline_wrap(img.src, "#image") }
end

-- template_string is a default template for this reader, applied when pandoc
-- CLI is called with the -s/--standalone.
-- BUG: the numbersections if branch is not entered when pandoc CLI is called
-- with the -n/--number-sections options, but works when the numbersections
-- field is set to true in a pandoc YAML header. Probably a Pandoc bug?
local template_string = [[
#set page("a4")
#set text(lang: "en")
$if(numbersections)$
#set headings(numbering: "1.1")
$endif$
$if(toc)$
// Future table of contents call here.
$endif$
$if(date)$
$date$
$endif$

$body$
]]

Template = function()
	return template_string
end
