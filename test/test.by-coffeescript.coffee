fs = require('fs')
path = require('path')

async = require('async')
rimraf = require('rimraf')
mkdirp = require('mkdirp')
chai = require('chai')
Bystander = require('bystander')
should = chai.should()
ByCoffeeScript = require('../lib/by-coffeescript')

describe('ByCoffeeScript', ->
  GOOD_CODE = 'foo = 1'
  BAD_CODE = 'foo ==== 1'
  TMP = "#{__dirname}/tmp"
  FOO = "#{TMP}/foo"
  FOO2 = "#{TMP}/foo2"
  NODIR = "#{TMP}/nodir"
  NOFILE = "#{TMP}/nofile.coffee"
  HOTCOFFEE = "#{TMP}/hot.coffee"
  BLACKCOFFEE = "#{TMP}/black.coffee"
  ICEDCOFFEE = "#{FOO}/iced.coffee"
  TMP_BASE = path.basename(TMP)
  FOO_BASE = path.basename(FOO)
  FOO2_BASE = path.basename(FOO2)
  NODIR_BASE = path.basename(NODIR)
  NOFILE_BASE = path.basename(NOFILE)
  HOTCOFFEE_BASE = path.basename(HOTCOFFEE)
  BLACKCOFFEE_BASE = path.basename(BLACKCOFFEE)
  ICEDCOFFEE_BASE = path.basename(ICEDCOFFEE)
  NO_COMPILE = ["**/foo/*"]
  bystander = new Bystander()
  byCoffeeScript = new ByCoffeeScript()
  stats = {}

  beforeEach((done) ->
    mkdirp(FOO, (err) ->
      async.forEach(
        [HOTCOFFEE, ICEDCOFFEE],
        (v, callback) ->
          fs.writeFile(v, GOOD_CODE, (err) ->
            async.forEach(
              [FOO, HOTCOFFEE,ICEDCOFFEE,BLACKCOFFEE],
              (v, callback2) ->
                fs.stat(v, (err,stat) ->
                  stats[v] = stat
                  callback2()
                )
              ->
                callback()
            )
          )
        ->
          byCoffeeScript = new ByCoffeeScript({nolog:true})
          done()
      )
    )
  )

  afterEach((done) ->
    rimraf(TMP, (err) =>
      byCoffeeScript.removeAllListeners()
      done()
    )
  )

  describe('constructor', ->
    it('init test', ->
      ByCoffeeScript.should.be.a('function')
    )
    it('should instanciate', ->
      byCoffeeScript.should.be.a('object')
    )
    it('should set @noCompileFiles', () ->
      byCoffeeScript = new ByCoffeeScript({noCompile:NO_COMPILE,nolog:true})
      byCoffeeScript.noCompileFiles.should.eql(NO_COMPILE)
    )
  )
  describe('_setNoCompileFiles', ->
    it('should set @noCompileFiles', () ->
      byCoffeeScript._setNoCompileFiles(NO_COMPILE)
      byCoffeeScript.noCompileFiles.should.eql(NO_COMPILE)
    )
  )
  describe('_isNoCompile', ->
    it('should test if a file should be compiled or ignored', () ->
      byCoffeeScript = new ByCoffeeScript({noCompile:NO_COMPILE, nolog:true})
      byCoffeeScript._isNoCompile(ICEDCOFFEE).should.be.ok
      byCoffeeScript._isNoCompile(HOTCOFFEE).should.not.be.ok
    )
  )

  describe('_emitCompiled', ->
    it('emit "compiled" event', (done) ->
      byCoffeeScript.on('compiled', (data) ->
        data.file.should.equal(HOTCOFFEE)
        done()
      )
      byCoffeeScript._emitCompiled(HOTCOFFEE)
    )
  )

  describe('_getCode', ->
    it('should read coffee file', (done) ->
      fs.writeFile(HOTCOFFEE, GOOD_CODE, () ->
        byCoffeeScript._getCode(HOTCOFFEE, (data) ->
          should.not.exist(data.err)
          data.code.should.equal(GOOD_CODE)
          done()
        )
      )
    )
  )

  describe('compile', ->
    it('should emit "nofile" if file is not found', (done) ->
      byCoffeeScript.once('nofile',(data)=>
        data.err.code.should.be.equal('ENOENT')
        done()
      )
      byCoffeeScript.compile(NOFILE)
    )

    it('should emit "compile error" for bad code', (done) ->
      fs.writeFile(BLACKCOFFEE, BAD_CODE, =>
        byCoffeeScript.once('compile error',(data)=>
          data.file.should.equal(BLACKCOFFEE)
          done()
        )
        byCoffeeScript.compile(BLACKCOFFEE)
      )
    )

    it('should emit "compiled" for good code',(done)->
      fs.writeFile(BLACKCOFFEE, GOOD_CODE, =>
        byCoffeeScript.once('compiled',(data)=>
          data.file.should.equal(BLACKCOFFEE)
          done()
        )
        byCoffeeScript.compile(BLACKCOFFEE)
      )
    )
  )
  describe('_setListeners', ->
    beforeEach(->
      bystander = new Bystander(TMP,{nolog:true})
      byCoffeeScript._setListeners(bystander)
    )
    it('should listen to "File found"', (done) ->
      byCoffeeScript.once('compiled',(data)->
        data.file.should.equal(HOTCOFFEE)
        done()
      )
      bystander.run()
    )
    it('should listen to "File created" and emit "coffee created"', (done) ->
      bystander.on('watchset',()->
        byCoffeeScript.once('coffee created',(file)->
          file.should.equal(BLACKCOFFEE)
          done()
        )
        fs.writeFile(BLACKCOFFEE,GOOD_CODE)
      )
      bystander.run()
    )
    it('should listen to "File removed" and emit "coffee removed"', (done) ->
      bystander.on('watchset',()->
        byCoffeeScript.once('coffee removed',(file)->
          file.should.equal(HOTCOFFEE)
          done()
        )
        fs.unlink(HOTCOFFEE)
      )
      bystander.run()
    )
    it('should listen to "File changed" and emit "coffee changed"', (done) ->
      bystander.on('watchset',()->
        byCoffeeScript.once('coffee changed',(file)->
          file.should.equal(HOTCOFFEE)
          done()
        )
        fs.utimes(HOTCOFFEE, Date.now(), Date.now())
      )
      bystander.run()
    )
  )
)