# Typst custom reader and writer for Pandoc

[Typst](https://typst.app) is a modern markup-based typesetting system with powerful typesetting and scripting capabilities.
_It's really great._

[Pandoc](https://pandoc.org) is a universal document converter that handles **lots** of formats.

The custom `reader.lua` and `writer.lua` allow converting to and from Typst using Pandoc embedded Lua engine.

## Usage

```terminal
pandoc -t writer.lua input.tex -o output.typ
pandoc -f reader.lua input.typ -o output.html
```

> Hint:
> Try converting this README to Typst!

See [Pandoc User's guide](https://pandoc.org/MANUAL.html) for more advanced usage.

## TODO

Some planned improvements to be done.

- [X] Better formatting
- [X] Sort imports
- [ ] Support tight and sparse lists properly
- [ ] Improve standalone template with prettier default
- [ ] Parse the language of code blocks in Typst markup \[reader\]
- [ ] Parse Typst nested lists (that's a bit tricky here, use a recursive pattern or an LPeg dedicated grammar) \[reader\]
- [ ] Parse escaped Typst markup characters \[reader\]
- [ ] Work towards feature completeness
- [ ] Handle most informative attributes in the writer
- [ ] …

---

## Features completeness

Checked items are minimally supported.  
Unchecked items are not supported.

### Writer

#### Blocks

- [X] Plain
- [X] Para
- [ ] LineBlock
- [X] CodeBlock
- [X] RawBlock
- [X] BlockQuote
- [X] OrderedList
- [X] BulletList
- [X] DefinitionList
- [X] Header
- [X] HorizontalRule
- [ ] Table
- [ ] Figure
- [X] Div

#### Inlines

- [X] Str
- [X] Emph
- [X] Underline
- [X] Strong
- [X] Strikeout
- [X] Superscript
- [X] Subscript
- [X] SmallCaps
- [X] Quoted
- [ ] Cite
- [X] Code
- [X] Space
- [X] SoftBreak
- [X] LineBreak
- [ ] Math (needs to convert TeX syntax to Typst)
- [ ] RawInline
- [X] Link
- [X] Image
- [ ] Note
- [X] Span

### Reader

Some Pandoc AST items do not have a dedicated Typst markup.
The result is usually obtained by a generic and expected function call, which could be parsed, such as `#strike[redacted]` or `#underline[important]`.

#### Blocks

- [X] Plain
- [X] Para
- [ ] LineBlock
- [X] CodeBlock
- [ ] RawBlock
- [ ] BlockQuote (no markup)
- [X] OrderedList
- [X] BulletList
- [ ] DefinitionList
- [X] Header
- [X] HorizontalRule
- [ ] Table
- [ ] Figure
- [ ] Div (probably corresponds to a content block)

#### Inlines

- [X] Str
- [X] Emph
- [ ] Underline (no markup)
- [X] Strong
- [ ] Strikeout (no markup)
- [X] Superscript
- [X] Subscript
- [X] SmallCaps
- [ ] Quoted
- [ ] Cite
- [X] Code
- [X] Space
- [X] SoftBreak
- [X] LineBreak
- [ ] Math (needs to convert TeX syntax to Typst, not planned)
- [ ] RawInline
- [X] Link
- [ ] Image
- [ ] Note
- [ ] Span
