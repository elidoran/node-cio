
module.exports = (options) ->

  {server, listen} = options

  listen ?= -> console.log 'Listening on',server.address()

  retryDelay = options.retryDelay ? 3000
  maxRetries = options.maxRetries ? 3

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

      # else, we've gone too far. give up.
      else
        console.error "Address in use. Exiting after #{server.inUseRetryCount} retries."
        server.close()

    # else, it's another kind of error, so, we don't do anything with that...
    return
