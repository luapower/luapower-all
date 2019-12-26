---
title: luapower & git
tagline: git-based workflow for luapower
---

## What

Managing luapower with [multigit](https://github.com/capr/multigit),
the tool for working with overlaid git repositories.

## How

First, clone multigit. Then clone the luapower-repos meta-package
which contains the current list of packages. Finally, clone the packages:

<div class="shell_btn"></div>
<div class=unix_shell>
	git clone https://github.com/capr/multigit luapower
	cd luapower
	./mgit clone https://github.com/luapower/luapower-repos
	./mgit clone-all
</div>
<div class=windows_shell>
	git clone https://github.com/capr/multigit luapower
	cd luapower
	mgit clone https://github.com/luapower/luapower-repos
	mgit clone-all
</div>

> __Tip:__ To clone packages via ssh instead, you can either:
a) change luapower's base url in multigit with
`mgit baseurl luapower ssh://git@github.com/luapower/`, or
b) configure git to replace urls on-the-fly with
`git config --global url."ssh://git@github.com/luapower/".insteadOf https://github.com/luapower/`

> __Tip:__ Add multigit to your PATH so you can type `mgit` instead of
`./mgit`. Then you won't have to clone luapower into the same directory where
you cloned multigit and you will be able to use multigit for other things
too. On Linux and OSX you can do this with:
`sudo ln -s /path/to/multigit/mgit /usr/local/bin/`.

After all the packages are cloned, your luapower directory should
look like [this](/files/luapower/).

## Why not use plain git?

Because luapower packages need to be overlaid over the same directory, and
there's just no git-clone option to do that - you need to type in a few more
git commands, and multigit does just that. Another reason is keeping
[a list of all known packages](https://github.com/luapower/luapower-repos/tree/master/.mgit)
so that they can be managed as a collection (i.e. clone all, pull all, etc.).
And then, there's a handy set of git commands for working with overlaid repos
(show modified files across all repos, etc.).

## Managing packages

<div class="shell_btn"></div>
<div class="unix_shell">
	./mgit luajit pull               # update a single package
	./mgit --all pull                # update all packages
	./mgit glue                      # enter a git subshell for package glue
	[glue] $ git pull                # use git to update glue
	[glue] $ exit                    # exit the subshell
	./mgit remove glue               # remove glue
	./mgit --all make-hardlinks      # make hard links in .mgit for all packages
</div>
<div class="windows_shell">
	mgit luajit pull                 # update a single package
	mgit --all pull                  # update all packages
	mgit glue                        # enter a git subshell for package glue
	[glue]> git pull                 # use git to update glue
	[glue]> exit                     # exit the subshell
	mgit remove glue                 # remove glue
</div>

## Getting packages from other sources

Say you want to clone `foo` and `bar` from `https://github.com/bob/`
into your tree:

<div class="shell_btn"></div>
<div class="unix_shell">
	./mgit clone https://github.com/bob/foo https://github.com/bob/bar
</div>
<div class="windows_shell">
	mgit clone https://github.com/bob/foo https://github.com/bob/bar
</div>

You don't have to type the full url all the time:

<div class="shell_btn"></div>
<div class="unix_shell">
	./mgit baseurl bob https://github.com/bob/
	./mgit clone bob/foo bob/bar
</div>
<div class="windows_shell">
	mgit baseurl bob https://github.com/bob/
	mgit clone bob/foo bob/bar
</div>

## Creating a new package

Say you created a new module locally, and now you want to turn it
into a package named `foo`, hosted at `https://github.com/bob/foo`.

Create the repo `bob/foo` on github, make it known to multigit so
it can clone it, clone it, add in your files, commit and push:

	mgit baseurl bob https://github.com/bob/    # add bob's base url
	mgit origin foo bob                         # add foo's origin, which is bob
	mgit clone foo                              # clone it
	mgit foo add -f ...                         # add your files to git
	mgit foo commit -m "init"                   # commit
	mgit foo push                               # push

Once commited, the package is "registered" into your local tree
and you can use the [luapower] command on it.

Once pushed, you can share it to the world.
Tell your users to clone it using:

	mgit clone https://github.com/bob/foo

## Publishing a package on luapower.com

Before you start, make sure to read [get-involved], and check your
package with the [luapower] command.

Publishing your package to luapower.com is just a matter of sending
a pull request on the [luapower-repos](https://github.com/luapower/luapower-repos)
package with your additions. So you have to fork luapower-repos, clone it
again, add your package origins to it, push, then send a pull request:

	$ mgit remove luapower-repos
	$ mgit clone https://github.com/you/luapower-repos
	$ mgit luapower-repos                          # enter a git subshell
	[luapower-repos]$ git remote add upstream https://github.com/luapower/luapower-repos
	[luapower-repos]$ git status                   # see your additions
	[luapower-repos]$ git add ...                  # add them
	[luapower-repos]$ git commit -m "new stuff"    # commit
	[luapower-repos]$ git push                     # push
	[luapower-repos]$ exit                         # exit the git subshell
	$ _

All that jazz just to add two files to a repository on github is pretty
ridiculous, I know. We programmers have such low standards. So just click
on the "+" sign [here](https://github.com/luapower/luapower-repos/tree/master/.mgit)
(which will automatically make a fork of luapower-repos to your account) and
(continuing to assume that your github username is "bob" and your package
is called "foo"), add a new file called `bob.baseurl` in which you write
_`https://github.com/bob/`_ and a file called `foo.origin` in which you write
_`bob`_ and send a pull request.

Note that luapower users will always pull the package directly from your
repository, so it's important that your repository remains accessible
at its url, and that you don't destroy its history, in case users might
need an older version of the package _in the future_.

Repos are git-pulled every hour for updating the website.

## Creating package collections

Remember that you don't have to use the luapower-repos meta-package
if you don't want to. You can create your own meta-package with an
entirely different module collection, which users will then be
able to clone wholesale with:

	mgit clone https://github.com/you/your-repos
	mgit clone-all

The procedure for that is exactly the same as before, except you'll
be adding the .origin and .baseurl files to a different package
instead of luapower-repos.
