net = require 'net'
assert = require 'assert'
thru = require 'through2'
buildCio = require '../../lib'
buildTransformerListener = require '../../lib/transformer'

# no builder options yet...
cio = buildCio()

buildTransform = (name) ->
  transform =
    name: name
    pipe: (socket) ->
      transform.pipedTo = socket
    on: ->
    once: ->
    emit: (event,arg2) ->
      if event is 'pipe' then transform.pipedFrom = arg2
    end: ->

describe 'test transformer', ->

  describe 'listener', ->

    # use a fake transform object so we can verify it
    fakeTransform = buildTransform()

    # remember the options because they are passed to the builder too
    # use a function so listener will call it to build the transform
    builderOptions = transform:fakeTransform

    # build the listener (which remembers these options due to scope)
    listener = buildTransformerListener builderOptions

    # pass a fake socket to the listener
    fakeSocket =
      pipe: (stream) ->
        stream.pipedFrom = this
        return stream
      on: ->

    # call the listener as if a new socket connection has been made
    listener fakeSocket

    it 'should return a listener function', ->
      assert.equal (typeof listener), 'function'

    it 'should call the builder to return the fakeTransform', ->
      assert.strictEqual fakeSocket.transform, fakeTransform

    it 'should pipe socket -> transform -> socket', ->
      assert.equal fakeTransform.pipedFrom, fakeSocket
      assert.equal fakeTransform.pipedTo, fakeSocket



  describe 'listener with transform built from a function', ->

    # use a fake transform object so we can verify it
    fakeTransform = buildTransform()

    # remember the options because they are passed to the builder too
    # use a function so listener will call it to build the transform
    builderOptions = transform: (optionsArg) ->
      fakeTransform.options = optionsArg
      return fakeTransform

    # build the listener (which remembers these options due to scope)
    listener = buildTransformerListener builderOptions

    # pass a fake socket to the listener
    fakeSocket =
      pipe: (stream) ->
        stream.pipedFrom = this
        return stream
      on: (event) ->

    # call the listener as if a new socket connection has been made
    listener fakeSocket

    it 'should return a listener function', ->
      assert.equal (typeof listener), 'function'

    it 'should receive the builder options in the transform builder', ->
      assert.strictEqual fakeTransform.options, builderOptions

    it 'should build the fakeTransform and use it', ->
      assert.strictEqual fakeSocket.transform, fakeTransform

    it 'should pipe socket -> transform -> socket', ->
      assert.equal fakeTransform.pipedFrom, fakeSocket
      assert.equal fakeTransform.pipedTo, fakeSocket



  describe 'with client and server', ->

    # make two fake transforms which record what pipes to them and what they pipe to
    serverTransform = buildTransform 'server'
    clientTransform  = buildTransform 'client'

    # remember these for assertions
    client = null
    serverConnection = null
    listening = false

    # use `cio` to create a server with a tranform (and an arbitrary port)
    server = cio.server
      transform: serverTransform
      port     : 23456
      onConnect: (connection) ->
        serverConnection = connection
        serverConnection.on 'end', -> server.close()

    # once the server is listening do the client stuffs
    server.on 'listening', ->
      listening = true

      # create a client via `cio` with its transform and the same port as the server
      client = cio.client
        transform: clientTransform
        port     : server.address().port
        onConnect: -> client.end()

    before 'wait for server to listen', (done) -> server.listen done

    before 'wait for server to close', (done) -> server.on 'close', done

    it 'should listen', -> assert.equal listening, true

    # check to ensure this happened: socket.pipe(transform).pipe(socket)
    it 'should loop server\'s connection socket thru transform', ->

      assert.equal serverTransform.pipedFrom, serverConnection
      assert.equal serverTransform.pipedTo, serverConnection

    # check to ensure this happened: socket.pipe(transform).pipe(socket)
    it 'should loop client socket thru transform', ->
      assert.equal clientTransform.pipedFrom, client
      assert.equal clientTransform.pipedTo, client
