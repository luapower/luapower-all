
Model-driven live-editable web components in pure JavaScript.

## Overview

__UPDATE:__ this library is now developed as part of [Allegory SDK](https://github.com/allegory-software/allegory-sdk).

This library is designed for data-dense business-type apps with a focus
on data entry and data navigation.

These types of apps have higher information density, higher signal-to-noise
ratio, faster loading times and lower operational latencies than the usual
consumer-centric web-apps, and as such, tend to favor tabbed and split-pane
layouts over newspaper-type layouts, optimize for keyboard navigation,
and are generally designed for an office setting with a big screen, a chair,
a keyboard and a mouse ("keyboard & mouse"-first apps).

So what this means is: none of that responsive stuff (except for forms
for which you can define different grid layouts based on screen width),
keyboard is king, no touchy the screen, and no megabytes of polyfills
to implement half a browser because you want to squeeze that last drop
of the market or deliver a few more ads.

## Components

The highlight of the library is the virtual [grid widget][x-grid]
which can *load, scroll, sort and filter 100K items instantly on any modern
computer (or phone)*, can act as a tree-grid or as a vertical grid, has
inline editing, drag & drop moving of columns and rows and tons of other
features (not to mention, far, far less code than any js library of similar
capabilities, if you're into that sort of thing).

Accompanying that there's a listbox widget which is not virtual (so it can't
hold as many items as the grid efficiently), not out-of-the-box editable,
but the items can be custom-rendered to variable widths and heights and you
can still have drag & drop moving, multiple selection, sorting, etc.

Next there's an assortment of single-value input widgets to use for forms.
You tie these up to a navigation component (grid or listbox) and they show
and edit the data at whatever the focused row is on that component.

Then there's a bunch of layouting widgets like pagelist, splitter and
a css-grid. The beauty with these is that you can Ctrl+(Shift+)click on
any of those and they temporarily enter a "design mode" which allows you
to *tweak the layout of your application while it's running*. Press Esc
or click outside and it goes back to normal mode. The widgets include
full built-in customizable (de)serialization to help with making those
changes persistent. There's also an object inspector and a widget tree,
which together make up a fully functional UI designer built right into
your living app, so you can fully design your app while it's running.

All navigation widgets as well as the single-value widgets are model-driven
(we used to call these data-driven way back when wearing a t-shirt over
a long sleeve was cool). The nav widget holds the data, and one or more
value widgets are then bound to the nav widget so changes made on a cell
by one widget are reflected instantly in other widgets (aka 2-way binding).
The nav widget then gathers the changes made to one or more rows/cells and
can push them to a server (aka 3-way binding).

I'm also working on a WebGL2-based 3D model editor [x-modeleditor] which
comes with its own WebGL2 wrapper, 3D math lib and shaders. I hope to finish
it all this year (2021). This will be kept open-source with a public domain
license forever but it will be developed as part of a commercial product.

## Browser Compatibility

This will probably only work on desktop Firefox and Chrome/Edge for the
foreseeable future. Something might be done for Safari (if it doesn't catch
up all by itself, or better yet, dies and spares us all some grief) and
maybe mobile Chrome and Firefox too. Anything else is out.

## Installation

To install the library you need docker, kubernetes, webpack, redis, memcached
(because RAM is cheap) four medium AWS instances and an Apple developer
account. Look, Jesus Christ it's just a bunch of .js files and one big .css
file. Load them as they are, dependencies first, using simple html tags.

The dependencies are `glue.js` and `divs.js` (included).

`glue.js` extends JavaScript with basic routines similar to [glue] from Lua.

`divs.js` is a tiny jQuery-like library for DOM manipulation.

Additionally, [x-modeleditor] is implemented in `x-modeleditor.js`,
`x-model3.js` and depends on `3d.js`, `gl.js`, `gl-renderer.js`
and `earcut.js` (also included).

`3d.js` is a fast 3D math library for WebGL.

`gl.js` is a tiny WebGL2 wrapper.

`earcut.js` is the polygon triangulation library from mapbox.

## Styling

Even though they're web components, the widgets don't use shadow DOMs so
both their sub-elements and their styling are up for grabs. All widgets
get the `.x-widget` class that you can set global styling like a custom
font to, without disturbing your other styles.

## Security

Strings are never rendered directly as HTML to avoid accidentally creating
XSS holes. For formatting rich text safely use templates (`mustache.js` from
[webb] is a good candidate and it also has a server-side Lua implementation).

## Web developers beware

If you're a web developer (as opposed to say, a _programmer_), you might want
to stay away from this library. This library's author doesn't have much
respect for "design patterns", "best practices", "code smells" and other
such _thinking-avoidance mechanisms_ often employed by web developers.
If you're still not sure, here's a list to
<s>test the limits of your dogmatism</s> see how unprofessional I am:

* this lib pollutes the global namespace like it's London 1858.
* this lib extends built-in classes with new methods.
* this lib only uses `===` when it's actually necessary.
* this lib uses both `var` and `let` as needed.
* this lib uses `<table>` for layouting. Tables, man. For layouting.
* this lib uses snake case instead of hungarian notation.
* this lib wraps instantiations with `new` into plain functions.
* this lib does not even quote html attributes. why are you still reading?
* this lib uses synchronous ajax requests that some smart-ass condescending
w3c people found that it's in our best interest to deprecate.
* this lib uses a deployment system whereby you open up your file explorer
and then you copy-paste a bunch of .css and .js files to your goddamn www folder.
* this lib was not written by Google so it must have a lot of security vulnerabilities.
* this libs uses tabs, not spaces.
* look, it's not even a framework, it's a library. don't you wanna use a framework?
