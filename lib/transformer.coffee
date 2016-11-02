
module.exports = (options) ->

  (socket) ->
    # NOTE:
    #  net.Server's 'connection' event provides the new socket to the listener
    #  net.Socket's 'connect' event's `this` *is* the socket
    socket ?= this 

    # if transform must be built, then build it...
    transform =
      if typeof options.transform is 'function' then options.transform options
      else options.transform

    # store the transform on the socket
    socket.transform = transform

    # pipe connection thru the transform
    socket.pipe(transform).pipe(socket)

    # handle common error response
    # NOTE: allow them to handle an error on their transform
    socket.on 'error', (error) ->
      console.error 'Connection error:',error.message