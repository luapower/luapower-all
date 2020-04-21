
## credex-ifn.ro website

### Functionality

	* message form that sends an email via a smtp server.
	* payment form that uses BTPay to pay monthly loan payments.

### Downloading

```
git clone https://github.com/capr/multigit credex
cd credex
./mgit clone ssh://git@bitbucket-tools.altex.ro:7999/BROK/credex-ifn.ro-repos
./mgit clone-all
```

What you get out of this is a portable standalone nginx/OpenResty web server
(i.e. you can move it to any folder, but move it whole) complete with
source code, binaries, config file templates and a nginx start/stop script.

So all you have to do now is configure it and start the server.

But if you get a glibc error, you have to build it first.

### Building

The repos contain pre-compiled binaries with no external dependencies,
but they're not going to work on an old glibc because... linux (versioned
symbols to be exact). So the repos also contain complete C sources
and build scripts for everything in the `csrc` dir. Just run
`build-linux64.sh` on each lib that has one.

NOTE: If there's a `get-it.sh` script in there, run that first.

Refer to https://luapower.com/building for more info.

### Configuring

Copy the credex folder somewhere, and run:

```
chown nginx:nginx -R credex
```

Copy `credex-nginx-test|prod.conf` and see if you need to change anything
there.

Copy `credex_conf_test|prod.lua` to `credex_conf.lua` and fill up
the SMTP password for `aws-alerts.altex.ro` and the BTPay credentials
if you're setting up a production environment.

If you're making a test environment, you need to put a number in
`credex/next_order_num` file (i.e. `cat 200 > next_order_num` or a bigger
number depending on how many payments were made used during testing),
otherwise BTPay will complain of duplicate order numbers.


### Running

```
sudo credex-nginx          # start the server
sudo credex-nginx -s stop  # stop the server
```

