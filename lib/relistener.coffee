module.exports = ->

  # alias
  server = @server

  # if they didn't specify a relisten function, then, we'll change listen()
  # to remember its args so we can reuse them.
  unless @relisten?
    # remember the args in this var
    listenArgs = null

    # remember the original function (let's just put it right on it...)
    server.originalListen = server.listen

    # replace `listen()` with our function
    server.listen = (args...) ->
      listenArgs = args

      # let's avoid adding the listening callback multiple times
      # so, if the last arg is a callback...
      if typeof listenArgs[listenArgs.length - 1] is 'function'

        # make a copy of the args array so we can change it
        # and remove the function at the same time
        listenArgs = listenArgs[...-1]

      # now make the real listen() call with their args
      server.originalListen args...

    # create our `relisten()` which calls the real listen() with the args we
    # remembered from them calling listen()
    relisten = -> server.originalListen listenArgs...

  retryDelay = @retryDelay ? 3000
  maxRetries = @maxRetries ? 3

  # start out with zero retries
  server.inUseRetryCount = 0

  # add listener which will *relisten* if the error is 'address in use'
  server.on 'error', (error) ->

    # if it's the error type we want to handle...
    if error.code is 'EADDRINUSE'

      # and we haven't done this too many times yet
      if server.inUseRetryCount < maxRetries

        # notify them
        console.error 'Address in use, retrying in', (retryDelay / 1000), 'seconds...'

        # remember we tried
        server.inUseRetryCount++

        # retry in a bit
        setTimeout (->
          # call listen() in the callback
          server.close ->
            server.emit 'relisten'
            relisten()
        ), retryDelay

        # # could mark we handled this error, for other error listeners...
        # error.handled = true

      # else, we've gone too far. give up.
      else
        console.error "Address in use. Exiting after #{server.inUseRetryCount} retries."
        server.close()

    # else, it's another kind of error, so, we don't do anything with that...
    return

  return

module.exports.options =
  id: 'cio/relistener'
  after: [ 'cio/createServer']
