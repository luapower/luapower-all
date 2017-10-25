---
tagline: mustache renderer
---

__NOTE:__ Work-in-progress! Don't touch yet.

## `local mustache = require'mustache'`

A mustache parser and renderer written in Lua which strives to achieve the
exact same output as mustache.js would on the same template + cjson-encoded
view.

Features:

* syntax:
  * html-escaped variables: `{{var}}`
  * unescaped variables: `{{{var}}}` or `{{& var}}`
  * sections: `{{#var}} ... {{/var}}`
  * inverted sections: `{{^var}} ... {{/var}}`
  * comments: `{{! ... }}`
  * partials: `{{>name}}`
  * set delimiters: `{{=<% %>=}}`
  * scoped vars: `a.b.c` wherever `var` is expected
* view:
  * compatible with mustache.js as to what constitutes a non-false value,
  in particular '', 0 and '0' are considered false.
  * compatibile with [cjson] as to what constitutes a list vs hashmap,
  in particular empty tables are considered lists.
  * lambdas: any value in the view can be a function.
* rendering:
  * bytecode-based.
  * compatible with mustache.js:
    * passes all mustache.js tests.
    * preserves the indentation of standalone sections and partials.
    * removes substitutions that result in empty lines.
  * good error reporting with line and column number information.


## API

-------------------------------------------------------------- --------------------------------------------------------------
`mustache.render(template, [view], [partials], [write]) -> s`  render a template
`mustache.compile(template) -> template`                       compile a template to bytecode
`mustache.dump(program)`                                       dump bytecode (for debugging)
-------------------------------------------------------------- --------------------------------------------------------------

## API

### `mustache.render(template, [data], [partials], [write]) -> s`

Render a template. Args:

  * `template` - the template, in compiled or in string form.
  * `view` - the template view.
  * `partials` - either `{name -> template}` or `function(name) -> template`
  * `write` - an optional `function(s)` to output the rendered pieces to.

### `mustache.compile(template) -> template`

Parse and compile a template to bytecode.

### `mustache.dump(program)`

Dump bytecode (for debugging).
