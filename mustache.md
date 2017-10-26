---
tagline: logic-less templates
---

## `local mustache = require'mustache'`

A mustache parser and renderer written in Lua with the aim of producing the
exact same output as mustache.js on the same template + cjson-encoded view.
For full syntax of mustache see the
[mustache manual](https://mustache.github.io/mustache.5.html).

Features:

	* syntax:
		* html-escaped values: `{{var}}`
		* unescaped values: `{{{var}}}` or `{{& var}}`
		* sections: `{{#var}} ... {{/var}}`
		* inverted sections: `{{^var}} ... {{/var}}`
		* comments: `{{! ... }}`
		* partials: `{{>name}}`
		* set delimiters: `{{=<% %>=}}`
		* scoped vars: `a.b.c` wherever `var` is expected.
	* semantics:
		* compatible with mustache.js as to what constitutes a non-false value,
		in particular `''`, `0` and `'0'` are considered false.
		* compatibile with [cjson] as to what constitutes a list vs hashmap,
		in particular empty tables are considered lists.
		* section lambdas and value lambdas.
	* rendering:
		* passes all mustache.js tests.
		* preserves the indentation of standalone partials.
		* escapes `&><"'/`=` like mustache.js.
		* good error reporting with line and column number information.


## API

-------------------------------------------------- --------------------------------------------------------------
`mustache.render(template, [view], `               render a template
`[partials], [write][, d1, d2]) -> s`
`mustache.compile(template[, d1, d2]) -> template` compile a template to bytecode
`mustache.dump(program)`                           dump bytecode (for debugging)
-------------------------------------------------- --------------------------------------------------------------

## API

### `mustache.render(template, [data], [partials], [write][, d1, d2]) -> s`

Render a template. Args:

  * `template` - the template, in compiled or in string form.
  * `view` - the template view.
  * `partials` - either `{name -> template}` or `function(name) -> template`
  * `write` - a `function(s)` to output the rendered pieces to.
  * `d1, d2` - initial set delimiters.

### `mustache.compile(template[, d1, d2]) -> template`

Parse and compile a template to bytecode.

### `mustache.dump(program)`

Dump bytecode (for debugging).
