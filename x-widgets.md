
Data-driven web components in pure JavaScript.

## Overview

Better [check out the demo](http://luapower.com/x-widgets-demo.html)
before anything, which also includes some quick-reference documentation.

This library is designed for data-dense business-type apps with a focus
on data entry and data navigation.

Such apps need higher information density, higher signal-to-noise ratio,
faster loading times and lower operational latencies than the usual
consumer-centric web-apps, and as such, tend to favor tabbed and split-pane
layouts over newspaper-type layouts, optimize for keyboard navigation,
and are generally designed for an office setting with a big screen, a chair
and a keyboard and mouse ("keyboard & mouse"-first apps).

So what this means is: none of that responsive stuff, keyboard is king,
no touchy the screen, and no megabytes of polyfills to implement half a
browser because you want to squeeze that last drop of the market or deliver
a few more ads.

## Browser Compatibility

This will probably only work on desktop Firefox and Chrome/Edge for the
forseeable future. Something might be done for Safari (if it doesn't catch
up all by itself, or you know, dies and spares us all some grief) and maybe
mobile Chrome and Firefox too. Anything else is out.

## Installation

To install the library you need docker, kubernetes, webpack, redis, memcached
(because RAM is cheap) four medium AWS instances and an Apple developer account.
Look, it's just one .js file and one .css file. Load them as they are or
bundle, minify and gzip them, do what you have to do. Just make it look professional.

The dependencies are `glue.js` and `divs.js` from [webb] so get those first.

`glue.js` extends JavaScript with basic routines similar to [glue] from Lua.

`divs.js` is a tiny jQuery-like library for DOM manipulation.

## Styling

Even though they're web components, the widgets don't use shadow DOMs so
both their sub-elements and their styling are up for grabs. All widgets
get the `.x-widget` class that you can set global styling like a custom
font to, without disturbing your other styles.

## Web developers beware

If you're a web developer (as opposed to say, a programmer), you might want
to stay away from this library. This library's author doesn't have much
respect for "design patterns", "best practices", "code smells" and other
such _thinking-avoidance mechanisms_ often employed by web developers.
If you're still not sure, here's a list to
<s>test the limits of your dogmatism</s> see how unprofessional I am:

* this lib pollutes the global namespace like it's London 1858.
* this lib extends built-in classes with new methods.
* this lib only uses `===` when it's actually necessary.
* this lib uses both `var` and `let` as needed.
* this lib uses `<table>` for layouting. are you sick yet?
* this lib uses snake case instead of hungarian notation.
* this lib wraps instantiations with `new` into plain functions.
* this lib does not even quote html attributes. why are you still reading?
* this lib uses a deployment system whereby you open up your file explorer
and then you copy-paste a bunch of .css and .js files to your goddam www folder.
* look, it's not even a framework, it's a library. don't you wanna use _a framework_?

