module.exports =  ->
  # only do this if the server is secure
  if not @isSecure then return

  # if they provided a validator function then use it, otherwise, always allow
  isClientAllowed = @isClientAllowed ? -> true

  # let's get the client name to check
  peer = @connection.getPeerCertificate()
  clientName = peer.subject.CN

  # check if they're allowed
  unless isClientAllowed clientName, peer

    # if they specified a function to 'reject' the client, use it
    if @rejectClient? then @rejectClient @serverClient, clientName, peer

    # otherwise emit an error event on the socket
    else
      # TODO:
      #   what about something like the below?
      #   allows doing something else for rejections...
      #     socket.emit 'reject', clientName
      # for now, just error:
      socket.emit 'error', 'Client Rejected: ' + clientName, peer

  return

module.exports.options = id:'cio/authenticate-client'
