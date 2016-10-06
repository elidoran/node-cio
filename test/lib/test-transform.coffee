net = require 'net'
assert = require 'assert'
thru = require 'through2'
buildCio = require '../../lib'

# no builder options yet...
cio = buildCio()

# use cio to make server transformer ...
# use cio to make client transformer ...
# ensure piping was done...
# then close out

buildTransform = ->
  transform =
    pipe: (socket) -> transform.pipedTo = socket

    on: ->
    once: ->
    emit: (event) -> if event is 'pipe' then transform.pipedFrom = arguments[1]
    end: ->

describe 'test transformer', ->

  describe 'with client and server', ->

    # make two fake transforms which record what pipes to them and what they pipe to
    serverTransform = buildTransform()
    clientTransform  = buildTransform()

    # remember these for assertions
    client = null
    serverConnection = null

    # use `cio` to create a server with a tranform (and an arbitrary port)
    server = cio.server transform:serverTransform, port:23456

    # remember the server's connection to the client
    server.on 'connection', (connection) -> serverConnection = connection

    # once the server is listening do the client stuffs
    server.on 'listening', ->

      # create a client via `cio` with its transform and the same port as the server
      client = cio.client transform:clientTransform, port:server.address().port

      # when it connects, go ahead and end :)
      client.on 'connect', -> client.end()

      # and we're then done with the server too
      server.close()

    # check to ensure this happened: socket.pipe(transform).pipe(socket)
    it 'should loop server\'s connection socket thru transform', ->

      assert.equal serverTransform.pipedFrom, serverConnection
      assert.equal serverTransform.pipedTo, serverConnection

    # check to ensure this happened: socket.pipe(transform).pipe(socket)
    it 'should loop client socket thru transform', ->

      assert.equal clientTransform.pipedFrom, client
      assert.equal clientTransform.pipedTo, client
