# * A Bystander plugin to compile CoffeeScript files

# ---

# ### Require Dependencies

# #### Standard Node Modules
# `util` : [Utilities](http://nodejs.org/api/util.html)  
# `fs` : [File System](http://nodejs.org/api/fs.html)  
# `path` : [Path](http://nodejs.org/api/path.html)  
# `events` : [Events](http://nodejs.org/api/events.html)
util = require('util') 
fs = require('fs')
path = require('path')
EventEmitter = require('events').EventEmitter

# #### Third Party Modules
# `coffee-script` by [jashkenas@Jeremy Ashkenas](https://github.com/jashkenas/coffee-script)  
# `minimatch` by [Isaac Z. Schlueter@issacs](https://github.com/issacs/minimatch)
coffee = require('coffee-script')
minimatch = require('minimatch')
_ = require('underscore')

# ---

# ## ByCoffeeScript Class
module.exports = class ByCoffeeScript extends EventEmitter

  # ### Events
  # `compiled` : successfully compiled `@csfile`  
  # `compile error` : failed to compile `@csfile`  
  # `nofile` : failed to find `@csfile`  

  # #### constructor
  constructor:(@opts = {}) ->
    @errorFiles = []
    @noCompileFiles = []
    if @opts?.noCompile?
      @_setNoCompileFiles(@opts.noCompile)

  _setListeners: (@bystander) ->
    @bystander.on('File found', (file, stat) =>
      if path.extname(file) is '.coffee' and not @_isNoCompile(file)
        @compile(file)
    )
    @bystander.on('File created', (file, stat) =>
      if path.extname(file) is '.coffee' and not @_isNoCompile(file)
        @emit('coffee created', file, stat)
        @compile(file)
    )
    @bystander.on('File changed', (file, stat) =>
      if path.extname(file) is '.coffee' and not @_isNoCompile(file)
        @emit('coffee changed', file, stat)
        @compile(file)
    )
    @bystander.on('File removed', (file, stat) =>
      if path.extname(file) is '.coffee' and not @_isNoCompile(file)
        @errorFiles = _(@errorFiles).without(file)
        @emit('coffee removed', file, stat)
    )

  # ---

  # ### Private Methods
 
  # #### check if the given file shouldn't be compiled
  # `dir (String)` : a path to a file
  _isNoCompile: (file) ->
    for v in @noCompileFiles
      if minimatch(file, v, {dot : true})
        return true
    return false

  # #### Add patterns to @noCompileFiles
  # `newFiles (Array)` : glob `String`s to add to `@noCompileFiles`  
  _setNoCompileFiles: (newFiles) ->
    @noCompileFiles = _(@noCompileFiles).union(newFiles)    

  # #### Get a list of compilation error coffee files
  getErrorFiles: ->
    return @errorFiles

  # #### Emit compiled event with lint result
  # `lint (Object)` : a coffeelint result object 
  _emitCompiled: (file, compiled, code) ->
    @emit(
      'compiled',
      {file: file, compiled: compiled, code: code}
    )
  # #### Read @csfile and get coffeescript code 
  # `cb (Function)` : a callback funtion  
  _getCode: (file, cb) ->
    fs.readFile(file, 'utf8', (err, code) =>
      cb({err: err, code: code, file: file})
    )

  # ---

  # ### Public API

  # #### Compile CoffeeScript to JavaScript, lint and write to a JS file
  # `nojs (Bool)` : `true` to avoid writing to `@jsfile`    
  compile: (file) ->
    # Get coffeescript sorce code from `@csfile`
    @_getCode(file, (data) =>
      if data.err
        # emit `nofile` event if `@csfile` is not found
        unless @opts.nolog
          console.log('coffee file not found'.yellow + " - #{file}\n") 
        @emit(
          'nofile',
          {file: file, err: data.err}
        )
      else
        # `coffee.compile()` `data.code` to JS  
        try
          compiled = coffee.compile(data.code)
          unless @opts.nolog
            message = [
              'compiled'.green,
              " - #{file}"
            ]
            console.log(message.join('') + '\n')
          @_emitCompiled(file, compiled, data.code)
          # If something went wrong, emit `compile error`
        catch e
          unless @opts.nolog
            console.log(
              'compile error'.red +
              " in #{file}" +
              (" => #{e}").red+'\n'
            )
          @errorFiles.push(file)
          @errorFiles = _(@errorFiles).uniq()
          @emit('compile error', {file: file, err: e})
    )