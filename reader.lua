-- A custom Pandoc Typst reader.
-- Louis Vignoli

-- Imports
-- These modules are provided in Pandoc embedded Lua runtime.

local lpeg = require "lpeg"
local pandoc = require "pandoc"

-- For better performance we put these functions in local variables:

local B = lpeg.B
local C = lpeg.C
local Cb = lpeg.Cb
local Cc = lpeg.Cc
local Cf = lpeg.Cf
local Cg = lpeg.Cg
local Cmt = lpeg.Cmt
local Cs = lpeg.Cs
local Ct = lpeg.Ct
local P = lpeg.P
local R = lpeg.R
local S = lpeg.S
local V = lpeg.V

-- Common patterns

local whitespacechar = S " \t\r\n"
local specialchar = S "/*_~[]\\{}|`"
local wordchar = (1 - (whitespacechar + specialchar))
local spacechar = S " \t"
local newline = P "\r" ^ -1 * P "\n"
local blankline = spacechar ^ 0 * newline
local endline = newline * #-blankline
local endequals = spacechar ^ 0 * P "=" ^ 0 * spacechar ^ 0 * newline
local cellsep = spacechar ^ 0 * P "|"

-- trim trims a string from its surrounding whitespaces.
local function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- ListItem is a helper function to parse bullet and numbered lists.
-- It is almost copy pasted form the pandoc Creole reader example.
local function ListItem(lev, ch)
	local start
	if ch == nil then
		start = S "-+"
	else
		start = P(ch)
	end
	local subitem = function(c)
		if lev < 6 then
			return ListItem(lev + 1, c)
		else
			return (1 - 1) -- fails
		end
	end
	local parser = spacechar ^ 0
		* start ^ lev -- NOTE: This patterns is completely wrong regarding Typst grammar, but flat list are well-parsed this way.
		* #-start
		* spacechar ^ 0
		* Ct((V "Inline" - (newline * spacechar ^ 0 * S "-+")) ^ 0)
		* newline
		* (Ct(subitem "-" ^ 1) / pandoc.BulletList + Ct(subitem "+" ^ 1) / pandoc.OrderedList + Cc(nil))
		/ function(ils, sublist)
			return { pandoc.Plain(ils), sublist }
		end
	return parser
end

-- Typst (incomplete) grammar.
G = P {
	"Pandoc",
	Pandoc = Ct(V "Block" ^ 0) / pandoc.Pandoc,

	Block = blankline ^ 0 * (V "Header" + V "CodeBlock" + V "List" + V "Para"),

	Para = Ct(V "Inline" ^ 1) * newline / pandoc.Para,
	Header = P "=" ^ 1 / string.len * spacechar ^ 1 * Ct(V "Inline" ^ 1) / pandoc.Header,
	CodeBlock = P "```" * blankline * C((1 - P "```") ^ 0) * P "```" / trim / pandoc.CodeBlock,
	List = V "BulletList" + V "OrderedList",
	BulletList = Ct(ListItem(1, "-") ^ 1) / pandoc.BulletList,
	OrderedList = Ct(ListItem(1, "+") ^ 1) / pandoc.OrderedList,

	Inline = V "Strong" + V "Emph" + V "LineBreak" + V "Str" + V "Space" + V "SoftBreak" + V "Code",

	Strong = P "*" * Ct((V "Inline" - P "*") ^ 1) * P "*" / pandoc.Strong,
	Emph = P "_" * Ct((V "Inline" - P "_") ^ 1) * P "_" / pandoc.Emph,
	LineBreak = P "\\" / pandoc.LineBreak,
	Str = wordchar ^ 1 / pandoc.Str,
	Space = spacechar ^ 1 / pandoc.Space,
	SoftBreak = endline / pandoc.SoftBreak,
	Code = P "`" * C((1 - P "`") ^ 1) * P "`" / pandoc.Code,
}

function Reader(input, reader_options)
	return lpeg.match(G, tostring(input))
end
