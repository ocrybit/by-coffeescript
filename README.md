By-CoffeeScript
===============

A Bystander plugin to auto-compile CoffeeScript files on file change events.  

Note it doesn't save compiled js code to js files, you need [by-write2js](http://tomoio.github.com/by-write2js/) plugin to do that.

**By-CoffeeScript** plugin compiles CoffeeScript files to Javascript and broadcasts if the compilation is successful. This plugin utilizes other handy plugins such as [by-write2js](http://tomoio.github.com/by-write2js/), [by-coffeelint](http://tomoio.github.com/by-coffeelint/), [by-docco](http://tomoio.github.com/by-docco/) and [by-mocha](http://tomoio.github.com/by-mocha/).

Installation
------------

To install **by-coffeescript**,

    sudo npm install -g by-coffeescript

Options
-------

> `noCompile` : an array of glob patterns for files to ignore.

By-CoffeeScript uses [minimatch](https://github.com/isaacs/minimatch) without `matchBase` option to match glob patterns.  

#### Examples

Ignoring files under `ignore` and `nocompile` directories.

    // .bystander config file
	.....
	.....
      "plugins" : ["by-coffeescript"],
      "by" : {
        "coffeescript" : {
          "noCompile" : ["**/ignore/*", "**/nocompile/*"]
        }
      },
    .....
	.....


Broadcasted Events for further hacks
------------------------

> `compiled` : successfully compiled the given coffee file  
> `compile error` : failed to compile the given coffee file  
> `nofile` : failed to find the given coffee file  

See the [annotated source](docs/by-coffeescript.html) for details.

Running Tests
-------------

Run tests with [mocha](http://visionmedia.github.com/mocha/)

    make
	
License
-------
**By-CoffeeScript** is released under the **MIT License**. - see the [LICENSE](https://raw.github.com/tomoio/by-coffeescript/master/LICENSE) file
