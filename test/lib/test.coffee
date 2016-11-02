fs = require 'fs'
corepath = require 'path'
assert = require 'assert'

buildCio = require '../../lib'

# help reference helper files
helperFile = (name) -> corepath.resolve __dirname, '..', 'helpers', name

describe 'test cio', ->

  describe 'errors', ->

    it 'should return an error because `key` string is an invalid file path', ->

      badCio = buildCio key: 'bad/path'

      assert badCio.error
      assert badCio.reason
      assert.equal badCio.error, 'Unable to read \'key\' from: ' + corepath.resolve('bad/path')

    it 'should return an error because `cert` string is an invalid file path', ->

      badCio = buildCio cert: 'bad/path'

      assert badCio.error
      assert badCio.reason
      assert.equal badCio.error, 'Unable to read \'cert\' from: ' + corepath.resolve('bad/path')

    it 'should return an error because `ca` string is an invalid file path', ->

      badCio = buildCio ca: 'bad/path'

      assert badCio.error
      assert badCio.reason
      assert.equal badCio.error, 'Unable to read \'ca\' from: ' + corepath.resolve('bad/path')

    ###
      TODO:
        allow aliases in builder function...
    ###

  describe 'client and server', ->

    describe 'with defaults', ->

      cio = buildCio()

      # remember these for assertions
      client = null
      server = null
      received = null
      listening = false
      connected = false
      closed = false

      before 'build server', ->

        # use `cio` to create a server with a tranform (and an arbitrary port)
        server = cio.server
          # retryDelay: 100
          onConnect: (connection) ->
            serverConnection = connection
            serverConnection.on 'data', (data) ->
              received = data.toString 'utf8'
            serverConnection.on 'end', ->
              server.close()

        server.on 'error', (error) -> console.log 'Server error:',error

        # once the server is listening do the client stuffs
        server.on 'listening', ->
          listening = true

          # create a client via `cio` with its transform and the same port as the server
          client = cio.client
            port     : server.address().port
            host     : 'localhost'
            onConnect: ->
              connected = true
              client.end 'done', 'utf8'

          client.on 'error', (error) -> console.log 'client error:',error

        server.on 'close', -> closed = true

      before 'wait for server to listen', (done) ->

        server.listen 1357, 'localhost', done

      before 'wait for server to close', (done) ->

        server.on 'close', done

      it 'should listen', -> assert.equal listening, true

      it 'should connect', -> assert.equal connected, true

      it 'should receive', -> assert.equal received, 'done'

      it 'should close', -> assert.equal closed, true


    describe 'with security certs', ->

      before 'must have certs', (done) ->
        # we'll need security certificate files.
        # if certs already exist, we're done
        if fs.existsSync helperFile 'ca.cert.pem' then return done()

        # NOTE: expects openssl .. so, nix environments...?
        require(helperFile 'genscripts.js')(done)

      describe 'in standard property names', ->

        cio = buildCio()

        # remember these for assertions
        client    = null
        server    = null
        received  = null
        listening = false
        connected = false
        closed    = false

        before 'build server', ->

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
            clientOptions =
              port: server.address().port
              host: 'localhost'
              key : helperFile 'client.private.pem'
              cert: helperFile 'client.cert.pem'
              ca  : helperFile 'ca.cert.pem'
              onConnect: ->
                connected = true
                client.end 'done', 'utf8'

            client = cio.client clientOptions


        before 'wait for server to listen', (done) ->
          server.listen 2468, 'localhost', done

        before 'wait for server to close', (done) ->
          server.on 'close', ->
            closed = true
            done()

        it 'should listen', -> assert.equal listening, true

        it 'should connect', -> assert.equal connected, true

        it 'should receive', -> assert.equal received, 'done'

        it 'should close', -> assert.equal closed, true


      describe 'in my property aliases', ->

        cio = buildCio()

        # remember these for assertions
        client    = null
        server    = null
        received  = null
        listening = false
        connected = false
        closed    = false

        before 'build server', ->

          # use `cio` to create a server with a tranform (and an arbitrary port)
          server = cio.server
            private: helperFile 'server.private.pem'
            public : helperFile 'server.cert.pem'
            root   : helperFile 'ca.cert.pem'
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
              host: 'localhost'
              key : helperFile 'client.private.pem'
              cert: helperFile 'client.cert.pem'
              ca  : helperFile 'ca.cert.pem'
              onConnect: ->
                connected = true
                client.end 'done', 'utf8'

        before 'wait for server to listen', (done) ->
          server.listen 3579, 'localhost', done

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

        cio = buildCio()

        serverPort = 4680

        # remember these for assertions
        client = null
        received = null
        listening = 0
        relistened = 0
        connected = 0
        closed = 0

        # let's create another server which uses the same port to cause EADDRINUSE
        otherServer = cio.server()

        otherServer.listen serverPort, 'localhost'

        # use `cio` to create a server with a tranform (and an arbitrary port)
        server = cio.server
          onConnect: (connection) ->
            serverConnection = connection
            serverConnection.on 'data', (data) -> received = data.toString 'utf8'
            serverConnection.on 'end', -> server.close()
          retryDelay: 100
          maxRetries: 5

        server.on 'relisten', ->
          relistened++
          if relistened > 3 then otherServer.close()

        # once the server is listening do the client stuffs
        server.on 'listening', ->
          listening++

          # create a client via `cio` with its transform and the same port as the server
          client = cio.client
            port     : server.address().port
            host     : 'localhost'
            onConnect: ->
              connected++
              client.end 'done', 'utf8'

        before 'wait for server to listen', (done) ->
          # call done() when it successfully listens...
          server.listen serverPort, 'localhost', ->
            # Note: node 0.12 and node 4 don't have server.listening ...
            if listening > 0 then done()

        before 'wait for server to close', (done) ->
          server.on 'close', ->
            closed++
            done()

        it 'should listen once', -> assert.equal listening, 1

        it 'should connect once', -> assert.equal connected, 1

        it 'should receive', -> assert.equal received, 'done'

        it 'should close once', -> assert.equal closed, 1


      describe 'and specified relisten option', ->

        cio = buildCio()

        serverPort = 6820

        # remember these for assertions
        client = null
        received = null
        listening = 0
        relistened = 0
        connected = 0
        closed = 0

        # let's create another server which uses the same port to cause EADDRINUSE
        otherServer = cio.server()
        otherServer.listen serverPort, 'localhost'

        # use `cio` to create a server with a tranform (and an arbitrary port)
        server = cio.server
          onConnect: (connection) ->
            serverConnection = connection
            serverConnection.on 'data', (data) -> received = data.toString 'utf8'
            serverConnection.on 'end', -> server.close()
          retryDelay: 100
          maxRetries: 5
          relisten: ->
            relistened++
            if relistened > 3 then otherServer.close()
            server.listen serverPort, 'localhost'

        # once the server is listening do the client stuffs
        server.on 'listening', ->
          listening++

          # create a client via `cio` with its transform and the same port as the server
          client = cio.client
            port     : server.address().port
            host     : 'localhost'
            onConnect: ->
              connected++
              client.end 'done', 'utf8'

        before 'wait for server to listen', (done) ->
          # call done() when it successfully listens...
          server.listen serverPort, 'localhost', ->
            # Note: node 0.12 and node 4 don't have server.listening ...
            if listening > 0 then done()

        before 'wait for server to close', (done) ->
          server.on 'close', ->
            closed++
            done()

        it 'should listen once', -> assert.equal listening, 1

        it 'should connect once', -> assert.equal connected, 1

        it 'should receive', -> assert.equal received, 'done'

        it 'should close once', -> assert.equal closed, 1
