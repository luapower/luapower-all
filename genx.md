---
tagline: XML writer
---

## `local genx = require'genx'`

A ffi binding of [genx][genx lib], a library for generating well-formed
canonical XML documents, written by Tim Bray.

## Features

  * does all necessary XML escaping.
  * prevents generating text that isn't well-formed.
  * generates namespace prefixes.
  * produces Canonical XML, suitable for use with digital signatures.

## Limitations

  * only UTF8 encoding supported
  * no empty element tags
  * no `<!DOCTYPE>` declarations (write it yourself before calling `w:start_doc()`)
  * no pretty-printing (add linebreaks and indentation yourself with `w:text()` where needed)

## Example

~~~{.lua}
local w = genx.new()
w:start_doc(io.stdout)
w:start_element'root'
w:text'hello'
w:end_element()
w:end_doc()
w:free()
~~~

------------------------------------------------------------ --------------------------------------------------------------------------------
`genx.new() -> w`                                            Create a new genx writer.
`w:free()`                                                   Free the genx writer.
`w:start_doc(file)`                                          Start an XML document on a `FILE *` or Lua file object
`w:start_doc(write)`                                         Start an XML document on a write function to be called as `write([s[, size]])`
`w:end_doc()`                                                Flush pending updates and release the file handle
`w:ns(uri[, prefix]) -> ns`                                  Declare a namespace for reuse. The same namespace can be declared multiple times.
`w:element(name[, ns | uri,prefix]) -> elem`                 Declare an element for reuse. The same element can be declared multiple times.
`w:attr(name[, ns | uri,prefix]) -> attr`                    Declare an attribute for reuse. The same attribute can be declared multiple times.
`w:comment(s)`                                               Add a comment to the current XML stream.
`w:pi(target, text)`                                         Add a PI to the current XML stream.
`w:start_element(elem | name [, ns | uri,prefix])`           Start a new XML element.
`w:end_element()`                                            End the current element.
`w:add_attr(attr, val[, ns | uri,prefix])`                   Add an attribute to the current element. Attributes are sorted by name in the output stream.
`w:add_ns(ns | [uri,prefix])`                                Add a namespace to the current element.
`w:unset_default_namespace()`                                Add a `xmlns=""` declaration to unset the default namespace declaration. This is a no-op if no default namespace is in effect.
`w:text(s[, size])`                                          Add utf-8 text.
`w:char(char)`                                               Add an unicode code point.
`w:check_text(s) -> genxStatus`                              Check utf-8 text.
`w:scrub_text(s) -> s`                                       Scrub utf-8 text of invalid characters.
------------------------------------------------------------ --------------------------------------------------------------------------------

See the [genx manual] for more info.

[genx lib]:    http://www.tbray.org/ongoing/When/200x/2004/02/20/GenxStatus
[genx manual]: http://www.tbray.org/ongoing/genx/docs/Guide.html
