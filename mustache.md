---
tagline: mustache renderer
---

## `local mustache = require'mustache'`

Full-spec mustache parser and bytecode-based renderer.

## API

-------------------------------------------------------------- --------------------------------------------------------------
`mustache.render(template, [view], [partials], [write]) -> s`  render a template
`mustache.compile(template) -> template`                       compile a template to bytecode
`mustache.dump(program)`                                       dump bytecode (for debugging)
-------------------------------------------------------------- --------------------------------------------------------------

## Features

  * scoped vars
  * partials with recursion
  * preserving indentation for sections and partials

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
