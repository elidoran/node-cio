net = require 'net'
assert = require 'assert'
thru = require 'through2'
buildCio = require '../../lib'
buildJsonifyListener = require '../../lib/jsonify'

# no builder options yet...
cio = buildCio()

class Thru extends require('stream').Transform
  constructor: ->
    super objectMode:true
  pipe: (socket) ->
    super socket
    @pipedTo = socket
  emit: (event, stream) ->
    super event, stream
    if event is 'pipe' then @pipedFrom = stream
  _transform: (data, encoding, next) ->
    @push data
    next()

buildFakeSocket = ->
  pipe: (stream) ->
    @pipedTo = stream
    return stream
  emit: (event, arg2) ->
    if event is 'pipe' then @pipedFrom = arg2
    else if event is 'jsonify' then @jsonify = arg2
  on: ->

describe 'test jsonify', ->

  describe 'listener', ->

    # remember the options because they are passed to the builder too
    # use a function so listener will call it to build the transform
    builderOptions = jsonify:true

    # build the listener (which remembers these options due to scope)
    listener = buildJsonifyListener builderOptions

    # pass a fake socket to the listener
    fakeSocket = buildFakeSocket()

    # call the listener as if a new socket connection has been made
    listener fakeSocket

    it 'should return a listener function', ->
      assert.equal (typeof listener), 'function'

    it 'should set `json` on socket', -> assert fakeSocket.json

    it 'should emit \'jsonify\' event', -> assert fakeSocket.jsonify

    it 'should pipe socket -> json.in', ->
      assert.equal fakeSocket.pipedTo, fakeSocket.json.in

    it 'should pipe json.out to socket', ->
      assert.equal fakeSocket.pipedFrom, fakeSocket.json.out



  describe 'listener with transform', ->

    fakeTransform = new Thru()

    # remember the options because they are passed to the builder too
    # use a function so listener will call it to build the transform
    builderOptions = jsonify:true, transform:fakeTransform

    # build the listener (which remembers these options due to scope)
    listener = buildJsonifyListener builderOptions

    # pass a fake socket to the listener
    fakeSocket = buildFakeSocket()

    # call the listener as if a new socket connection has been made
    listener fakeSocket

    it 'should return a listener function', ->
      assert.equal (typeof listener), 'function'

    it 'should set `json` on socket', -> assert fakeSocket.json

    # because a transform was supplied...
    it 'should not emit \'jsonify\' event', ->
      assert fakeSocket.jsonify is undefined

    it 'should pipe socket -> json.in', ->
      assert.equal fakeSocket.pipedTo, fakeSocket.json.in

    it 'should pipe json.in -> transform', ->
      assert.equal fakeTransform.pipedFrom, fakeSocket.json.in

    it 'should pipe transform -> json.out', ->
      assert.equal fakeTransform.pipedTo, fakeSocket.json.out

    it 'should pipe json.out -> socket', ->
      assert.equal fakeSocket.pipedFrom, fakeSocket.json.out

  describe 'with client and server', ->

    object   = hello: 'there'
    expected = hello: 'there'

    # make two fake transforms which record what pipes to them and what they pipe to
    serverTransform = new Thru()
    clientTransform  = new Thru()

    # remember these for assertions
    client = null
    serverConnection = null
    listening = false
    received = null

    # use `cio` to create a server with a tranform (and an arbitrary port)
    server = cio.server
      jsonify  : true
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
        jsonify  : true
        transform: clientTransform
        port     : server.address().port
        onConnect: ->
          clientTransform.write object
          # client.write JSON.stringify({hello:'there'}), 'utf8'
          client.json.in.on 'data', (data) -> console.log 'json.in data:',data.toString 'utf8'
          clientTransform.on 'data', (data) -> console.log 'transforms data:',data.toString 'utf8'
          client.json.out.on 'data', (data) -> console.log 'json.out data:',data.toString 'utf8'
          client.end()

      client.on 'data', (data) -> received = data

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


  #   it 'should set `json` on client socket', ->
  #     console.log 'client?',client?,hold.client?
  #     console.log 'serverConnection?',serverConnection?
  #     assert client.json
  #
  #   it 'should set `json` on server socket', -> assert serverConnection.json
  #
  #   # because a transform was supplied...
  #   it 'should not emit \'jsonify\' event', -> assert client.jsonify is undefined
  #   it 'should not emit \'jsonify\' event', -> assert serverConnection.jsonify is undefined
  #
  #   it 'should pipe client socket -> json.in', -> assert.equal client.pipedTo, fakeSocket.json.in
  #   it 'should pipe server socket -> json.in', -> assert.equal serverConnection.pipedTo, serverConnection.json.in
  #
  #   it 'should pipe client json.in -> transform', -> assert.equal clientTransform.pipedFrom, client.json.in
  #   it 'should pipe server json.in -> transform', -> assert.equal serverTransform.pipedFrom, serverConnection.json.in
  #
  #   it 'should pipe client transform -> json.out', -> assert.equal clientTransform.pipedTo, client.json.out
  #   it 'should pipe server transform -> json.out', -> assert.equal serverTransform.pipedTo, serverConnection.json.out
  #
  #   it 'should pipe client json.out -> socket', -> assert.equal client.pipedFrom, client.json.out
  #   it 'should pipe server json.out -> socket', -> assert.equal serverConnection.pipedFrom, serverConnection.json.out
