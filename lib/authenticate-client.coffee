

module.exports = (options) ->

  # if they provided a validator function then use it, otherwise, always allow
  isClientAllowed = options.isClientAllowed ? -> true

  (socket) ->
    # NOTE:
    #  net.Server's 'connection' event provides the new socket to the listener
    #  net.Socket's 'connect' event's `this` *is* the socket
    socket ?= this 

    # let's get the client name to check
    peer = socket.getPeerCertificate()
    clientName = peer.subject.CN

    # check if they're allowed
    unless isClientAllowed clientName

      # if they specified a function to 'reject' the client, use it
      if options.rejectClient? then options.rejectClient socket, clientName

      # otherwise emit an error event on the socket
      else
        # TODO: what about something like the below done later (timeout/nextTick)?
        # allows doing something else for rejections...
        #   socket.emit 'reject', clientName
        socket.emit 'error', 'Client Rejected: ' + clientName

    return
