fs = require 'fs'
corepath = require 'path'
assert = require 'assert'

buildCio = require '../../lib'

# no options yet...
cio = buildCio()

helperFile = (name) -> corepath.resolve __dirname, '..', 'helpers', name

SERVER_PORT = 23456

describe 'test cio', ->

  describe 'client and server', ->

    describe 'with defaults', ->

      # remember these for assertions
      client = null
      received = null
      listening = false
      connected = false
      closed = false

      # use `cio` to create a server with a tranform (and an arbitrary port)
      server = cio.server
        onConnect: (connection) ->
          serverConnection = connection
          serverConnection.on 'data', (data) -> received = data.toString 'utf8'
          serverConnection.on 'end', -> server.close()

      # once the server is listening do the client stuffs
      server.on 'listening', ->
        listening = true

        # create a client via `cio` with its transform and the same port as the server
        client = cio.client
          port     : server.address().port
          onConnect: ->
            connected = true
            client.end 'done', 'utf8'

      before 'wait for server to listen', (done) -> server.listen done

      before 'wait for server to close', (done) ->
        server.on 'close', ->
          closed = true
          done()

      it 'should listen', -> assert.equal listening, true

      it 'should connect', -> assert.equal connected, true

      it 'should receive', -> assert.equal received, 'done'

      it 'should close', -> assert.equal closed, true


    describe 'with security certs', ->

      certs = {}

      before 'generate certs', (done) ->
        # if certs already exist, we're done
        if fs.existsSync helperFile 'ca.cert.pem' then return done()

        # otherwise, run the script to generate them...
        # NOTE: expects openssl .. so, nix environments...?
        require(helperFile 'genscripts.js')(done)

      # remember these for assertions
      client    = null
      received  = null
      listening = false
      connected = false
      closed    = false

      # use `cio` to create a server with a tranform (and an arbitrary port)
      server = cio.server
        key : helperFile 'server.private.pem'
        cert: helperFile 'server.cert.pem'
        ca  : helperFile 'ca.cert.pem'
        onSecureConnect: (connection) ->
          serverConnection = connection
          serverConnection.on 'data', (data) -> received = data.toString 'utf8'
          serverConnection.on 'end', -> server.close()

      # once the server is listening do the client stuffs
      server.on 'listening', ->
        listening = true

        # create a client via `cio` with its transform and the same port as the server
        client = cio.client
          port: server.address().port
          key : helperFile 'client.private.pem'
          cert: helperFile 'client.cert.pem'
          ca  : helperFile 'ca.cert.pem'
          onConnect: ->
            connected = true
            client.end 'done', 'utf8'

      before 'wait for server to listen', (done) -> server.listen done

      before 'wait for server to close', (done) ->
        server.on 'close', ->
          closed = true
          done()

      it 'should listen', -> assert.equal listening, true

      it 'should connect', -> assert.equal connected, true

      it 'should receive', -> assert.equal received, 'done'

      it 'should close', -> assert.equal closed, true


    describe 'with address in use', ->

      describe 'and default relisten()', ->

        serverPort = SERVER_PORT

        # remember these for assertions
        client = null
        received = null
        listening = 0
        relistened = 0
        connected = 0
        closed = 0

        # let's create another server which uses the same port to cause EADDRINUSE
        otherServer = cio.server()
        otherServer.listen serverPort

        # use `cio` to create a server with a tranform (and an arbitrary port)
        server = cio.server
          onConnect: (connection) ->
            serverConnection = connection
            serverConnection.on 'data', (data) -> received = data.toString 'utf8'
            serverConnection.on 'end', -> server.close()
          retryDelay: 300
          maxRetries: 5
          # relisten: ->
          #   relistened++
          #   if relistened > 1 then otherServer.close()
          #   server.listen SERVER_PORT

        server.on 'relisten', ->
          relistened++
          if relistened > 3 then otherServer.close()

        # once the server is listening do the client stuffs
        server.on 'listening', ->
          listening++

          # create a client via `cio` with its transform and the same port as the server
          client = cio.client
            port     : server.address().port
            onConnect: ->
              connected++
              client.end 'done', 'utf8'

        before 'wait for server to listen', (done) ->
          # call done() when it successfully listens...
          server.listen serverPort, ->
            if server.listening then done()

        before 'wait for server to close', (done) ->
          server.on 'close', ->
            closed++
            done()

        it 'should listen once', -> assert.equal listening, 1

        it 'should connect once', -> assert.equal connected, 1

        it 'should receive', -> assert.equal received, 'done'

        it 'should close once', -> assert.equal closed, 1


      describe 'and specified relisten option', ->

        serverPort = 12345

        # remember these for assertions
        client = null
        received = null
        listening = 0
        relistened = 0
        connected = 0
        closed = 0

        # let's create another server which uses the same port to cause EADDRINUSE
        otherServer = cio.server()
        otherServer.listen serverPort

        # use `cio` to create a server with a tranform (and an arbitrary port)
        server = cio.server
          onConnect: (connection) ->
            serverConnection = connection
            serverConnection.on 'data', (data) -> received = data.toString 'utf8'
            serverConnection.on 'end', -> server.close()
          retryDelay: 300
          maxRetries: 5
          relisten: ->
            relistened++
            if relistened > 3 then otherServer.close()
            server.listen serverPort

        # once the server is listening do the client stuffs
        server.on 'listening', ->
          listening++

          # create a client via `cio` with its transform and the same port as the server
          client = cio.client
            port     : server.address().port
            onConnect: ->
              connected++
              client.end 'done', 'utf8'

        before 'wait for server to listen', (done) ->
          # call done() when it successfully listens...
          server.listen serverPort, ->
            if server.listening then done()

        before 'wait for server to close', (done) ->
          server.on 'close', ->
            closed++
            done()

        it 'should listen once', -> assert.equal listening, 1

        it 'should connect once', -> assert.equal connected, 1

        it 'should receive', -> assert.equal received, 'done'

        it 'should close once', -> assert.equal closed, 1
