module.exports = ->

  listen = @listen ? -> console.log 'Listening on',server.address()

  retryDelay = @retryDelay ? 3000
  maxRetries = @maxRetries ? 3

  # alias
  server = @server

  # start out with zero retries
  server.inUseRetryCount = 0

  # add listener which will *relisten* if the error is 'address in use'
  server.on 'error', (error) ->

    # if it's the error type we want to handle...
    if error.code is 'EADDRINUSE'

      # and we haven't done this too many times yet
      if server.inUseRetryCount < maxRetries

        # notify them
        console.error 'Address in use, retrying in 3 seconds...'

        # remember we tried
        server.inUseRetryCount++

        # retry in a bit
        setTimeout (->
          # call listen() in the callback
          server.close -> listen()
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
